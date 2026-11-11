# -*- coding: utf-8 -*-
import sys
import pytest
import backend

sync_module = sys.modules["backend.sync"]


class TestSyncLockAndConcurrency:
    def test_sync_background_skips_when_already_in_progress(self, monkeypatch):
        monkeypatch.setattr(sync_module, "sync_in_progress", True)

        result = sync_module.sync_background("test.sqlite", 1)

        # ponytail: should return True so QML attaches to active sync rather than failing
        assert result is True

    def test_start_sync_in_background_alias(self, monkeypatch):
        called = []

        def mock_sync_bg(db, acc_id):
            called.append((db, acc_id))
            return True

        monkeypatch.setattr(sync_module, "sync_background", mock_sync_bg)

        result = sync_module.start_sync_in_background("test.sqlite", 42)

        assert result is True
        assert called == [("test.sqlite", 42)]


class TestOdooSyncActiveUsersContext:
    def test_fetch_odoo_records_res_users_includes_inactive_context(self, monkeypatch):
        import sync_from_odoo
        from unittest.mock import MagicMock

        mock_client = MagicMock()
        mock_client.db = "testdb"
        mock_client.uid = 1
        mock_client.password = "secret"
        monkeypatch.setattr(sync_from_odoo, "get_model_fields", lambda client, model: ["id", "name", "active", "write_date"])

        mock_client.models.execute_kw.return_value = [{"id": 1, "name": "Inactive User", "active": False}]

        records = sync_from_odoo.fetch_odoo_records(mock_client, "res.users", ["id", "name", "active"])

        assert len(records) == 1
        called_args, called_kwargs = mock_client.models.execute_kw.call_args
        # execute_kw signature: (db, uid, pwd, model, method, args, kwargs)
        assert called_args[3] == "res.users"
        assert called_args[4] == "search_read"
        read_options = called_args[6]
        assert read_options.get("context") == {"active_test": False}

    def test_fetch_odoo_records_other_models_exclude_inactive_context(self, monkeypatch):
        import sync_from_odoo
        from unittest.mock import MagicMock

        mock_client = MagicMock()
        mock_client.db = "testdb"
        mock_client.uid = 1
        mock_client.password = "secret"
        monkeypatch.setattr(sync_from_odoo, "get_model_fields", lambda client, model: ["id", "name", "write_date"])

        mock_client.models.execute_kw.return_value = [{"id": 1, "name": "Task 1"}]

        records = sync_from_odoo.fetch_odoo_records(mock_client, "project.task", ["id", "name"])

        assert len(records) == 1
        called_args, called_kwargs = mock_client.models.execute_kw.call_args
        assert called_args[3] == "project.task"
        assert called_args[4] == "search_read"
        read_options = called_args[6]
        assert "context" not in read_options

    def test_fetch_batched_res_users_passes_inactive_context(self, monkeypatch):
        import sync_from_odoo
        from unittest.mock import MagicMock

        mock_client = MagicMock()
        mock_client.db = "testdb"
        mock_client.uid = 1
        mock_client.password = "secret"

        def mock_execute_kw(db, uid, pwd, model, method, args, *extra_args):
            if method == "search":
                # Check search_options kwargs
                assert extra_args[0].get("context") == {"active_test": False}
                return [101]
            if method == "read":
                assert extra_args[0].get("context") == {"active_test": False}
                return [{"id": 101, "name": "Archived User", "active": False}]
            return []

        mock_client.models.execute_kw.side_effect = mock_execute_kw

        records = sync_from_odoo._fetch_odoo_records_batched(mock_client, "res.users", ["id", "name", "active"], batch_size=1)
        assert len(records) == 1
        assert records[0]["id"] == 101


class TestTimesheetNestedMappingSyncToOdoo:
    def test_push_record_to_odoo_timesheet_creates_with_subproject_and_subtask(self, monkeypatch):
        import sync_to_odoo
        from unittest.mock import MagicMock

        mock_client = MagicMock()
        mock_client.call.return_value = 999

        field_map = {
            "project_id": "project_id",
            "task_id": "task_id",
            "name": "name",
            "unit_amount": "unit_amount",
            "date": "record_date",
            "id": "odoo_record_id"
        }
        field_info = {
            "project_id": {"type": "many2one"},
            "task_id": {"type": "many2one"},
            "name": {"type": "char"},
            "unit_amount": {"type": "float"},
            "date": {"type": "date"},
            "id": {"type": "integer"}
        }
        monkeypatch.setattr(sync_to_odoo, "load_field_mapping", lambda model, path: field_map)
        monkeypatch.setattr(sync_to_odoo, "fetch_odoo_field_info", lambda client, model: field_info)
        monkeypatch.setattr(sync_to_odoo, "safe_sql_execute", lambda *args, **kwargs: None)

        record = {
            "id": 12,
            "account_id": 1,
            "project_id": 59,
            "sub_project_id": 60,
            "task_id": 100,
            "sub_task_id": 101,
            "name": "Nested timesheet work",
            "unit_amount": 1.5,
            "record_date": "2026-11-11",
            "table_name": "account_analytic_line_app",
            "db_path": ":memory:",
            "odoo_record_id": None
        }

        created_id = sync_to_odoo.push_record_to_odoo(mock_client, "account.analytic.line", record)
        assert created_id == 999

        mock_client.call.assert_called_once()
        call_model, call_method, call_args = mock_client.call.call_args[0]
        assert call_model == "account.analytic.line"
        assert call_method == "create"
        payload = call_args[0]
        # Child project and child task IDs must be sent to Odoo
        assert payload["project_id"] == 60
        assert payload["task_id"] == 101
        assert payload["name"] == "Nested timesheet work"

    def test_push_record_to_odoo_timesheet_creates_with_parent_project_only(self, monkeypatch):
        import sync_to_odoo
        from unittest.mock import MagicMock

        mock_client = MagicMock()
        mock_client.call.return_value = 888

        field_map = {
            "project_id": "project_id",
            "task_id": "task_id",
            "name": "name",
            "id": "odoo_record_id"
        }
        field_info = {
            "project_id": {"type": "many2one"},
            "task_id": {"type": "many2one"},
            "name": {"type": "char"},
            "id": {"type": "integer"}
        }
        monkeypatch.setattr(sync_to_odoo, "load_field_mapping", lambda model, path: field_map)
        monkeypatch.setattr(sync_to_odoo, "fetch_odoo_field_info", lambda client, model: field_info)
        monkeypatch.setattr(sync_to_odoo, "safe_sql_execute", lambda *args, **kwargs: None)

        record = {
            "id": 13,
            "account_id": 1,
            "project_id": 59,
            "sub_project_id": None,
            "task_id": 100,
            "sub_task_id": None,
            "name": "Top-level work",
            "table_name": "account_analytic_line_app",
            "db_path": ":memory:",
            "odoo_record_id": None
        }

        created_id = sync_to_odoo.push_record_to_odoo(mock_client, "account.analytic.line", record)
        assert created_id == 888

        call_model, call_method, call_args = mock_client.call.call_args[0]
        payload = call_args[0]
        assert payload["project_id"] == 59
        assert payload["task_id"] == 100

    def test_construct_changes_timesheet_detects_subproject_and_subtask_updates(self):
        import sync_to_odoo

        field_map = {
            "project_id": "project_id",
            "task_id": "task_id",
            "name": "name"
        }
        field_info = {
            "project_id": {"type": "many2one"},
            "task_id": {"type": "many2one"},
            "name": {"type": "char"}
        }
        record = {
            "id": 14,
            "project_id": 59,
            "sub_project_id": 60,
            "task_id": 100,
            "sub_task_id": 101,
            "name": "Updated name",
            "last_modified": "2026-11-11T14:00:00Z"
        }
        existing_data = {
            "project_id": [59, "Old Parent"],
            "task_id": [100, "Old Task"],
            "name": "Old name",
            "write_date": "2026-11-11T13:00:00Z"
        }

        changes = sync_to_odoo.construct_changes(field_map, field_info, record, existing_data, model_name="account.analytic.line")
        assert changes["project_id"] == 60
        assert changes["task_id"] == 101
        assert changes["name"] == "Updated name"

    def test_construct_changes_timesheet_skips_when_ids_match_remote(self):
        import sync_to_odoo

        field_map = {
            "project_id": "project_id",
            "task_id": "task_id",
            "name": "name"
        }
        field_info = {
            "project_id": {"type": "many2one"},
            "task_id": {"type": "many2one"},
            "name": {"type": "char"}
        }
        record = {
            "id": 15,
            "project_id": 59,
            "sub_project_id": 60,
            "task_id": 100,
            "sub_task_id": 101,
            "name": "Same name",
            "last_modified": "2026-11-11T14:00:00Z"
        }
        existing_data = {
            "project_id": [60, "Subproject Name"],
            "task_id": [101, "Subtask Name"],
            "name": "Same name",
            "write_date": "2026-11-11T13:00:00Z"
        }

        changes = sync_to_odoo.construct_changes(field_map, field_info, record, existing_data, model_name="account.analytic.line")
        assert changes == {}


class TestTimesheetNestedMappingSyncFromOdoo:
    def test_insert_record_timesheet_decomposes_child_project_and_subtask(self, tmp_path):
        import sqlite3
        import sync_from_odoo

        db_path = str(tmp_path / "test_nested.db")
        conn = sqlite3.connect(db_path)
        cur = conn.cursor()

        cur.execute("""
            CREATE TABLE project_project_app (
                id INTEGER PRIMARY KEY,
                account_id INTEGER,
                name TEXT,
                parent_id INTEGER,
                odoo_record_id INTEGER
            )
        """)
        cur.execute("""
            CREATE TABLE project_task_app (
                id INTEGER PRIMARY KEY,
                account_id INTEGER,
                name TEXT,
                project_id INTEGER,
                sub_project_id INTEGER,
                parent_id INTEGER,
                odoo_record_id INTEGER
            )
        """)
        cur.execute("""
            CREATE TABLE account_analytic_line_app (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                account_id INTEGER,
                project_id INTEGER,
                sub_project_id INTEGER,
                task_id INTEGER,
                sub_task_id INTEGER,
                name TEXT,
                unit_amount FLOAT,
                last_modified datetime,
                record_date datetime,
                user_id INTEGER,
                status TEXT DEFAULT '',
                odoo_record_id INTEGER,
                UNIQUE (odoo_record_id, account_id)
            )
        """)

        # Insert parent project 59 and subproject 60
        cur.execute("INSERT INTO project_project_app (id, account_id, name, parent_id, odoo_record_id) VALUES (1, 1, 'Parent Proj', NULL, 59)")
        cur.execute("INSERT INTO project_project_app (id, account_id, name, parent_id, odoo_record_id) VALUES (2, 1, 'Child Proj', 59, 60)")

        # Insert parent task 100 and subtask 101
        cur.execute("INSERT INTO project_task_app (id, account_id, name, project_id, sub_project_id, parent_id, odoo_record_id) VALUES (1, 1, 'Parent Task', 60, NULL, NULL, 100)")
        cur.execute("INSERT INTO project_task_app (id, account_id, name, project_id, sub_project_id, parent_id, odoo_record_id) VALUES (2, 1, 'Sub Task', 60, NULL, 100, 101)")
        conn.commit()

        odoo_record = {
            "id": 505,
            "project_id": [60, "Child Proj"],
            "task_id": [101, "Sub Task"],
            "name": "Nested task log",
            "unit_amount": 2.0,
            "date": "2026-11-11",
            "write_date": "2026-11-11T12:00:00"
        }

        sync_from_odoo.insert_record(
            "account_analytic_line_app",
            "account.analytic.line",
            account_id=1,
            record=odoo_record,
            db_path=db_path,
            connection=conn
        )
        conn.commit()

        cur.execute("SELECT project_id, sub_project_id, task_id, sub_task_id, name, odoo_record_id FROM account_analytic_line_app WHERE odoo_record_id = 505")
        row = cur.fetchone()
        assert row is not None
        assert row[0] == 59   # project_id resolved to Parent Project
        assert row[1] == 60   # sub_project_id resolved to Child Project
        assert row[2] == 100  # task_id resolved to Parent Task
        assert row[3] == 101  # sub_task_id resolved to Child Task
        assert row[4] == "Nested task log"
        assert row[5] == 505

        conn.close()

    def test_insert_record_timesheet_top_level_project_and_task(self, tmp_path):
        import sqlite3
        import sync_from_odoo

        db_path = str(tmp_path / "test_toplevel.db")
        conn = sqlite3.connect(db_path)
        cur = conn.cursor()

        cur.execute("""
            CREATE TABLE project_project_app (
                id INTEGER PRIMARY KEY,
                account_id INTEGER,
                name TEXT,
                parent_id INTEGER,
                odoo_record_id INTEGER
            )
        """)
        cur.execute("""
            CREATE TABLE project_task_app (
                id INTEGER PRIMARY KEY,
                account_id INTEGER,
                name TEXT,
                project_id INTEGER,
                sub_project_id INTEGER,
                parent_id INTEGER,
                odoo_record_id INTEGER
            )
        """)
        cur.execute("""
            CREATE TABLE account_analytic_line_app (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                account_id INTEGER,
                project_id INTEGER,
                sub_project_id INTEGER,
                task_id INTEGER,
                sub_task_id INTEGER,
                name TEXT,
                unit_amount FLOAT,
                last_modified datetime,
                record_date datetime,
                user_id INTEGER,
                status TEXT DEFAULT '',
                odoo_record_id INTEGER,
                UNIQUE (odoo_record_id, account_id)
            )
        """)

        cur.execute("INSERT INTO project_project_app (id, account_id, name, parent_id, odoo_record_id) VALUES (1, 1, 'Top Proj', NULL, 59)")
        cur.execute("INSERT INTO project_task_app (id, account_id, name, project_id, sub_project_id, parent_id, odoo_record_id) VALUES (1, 1, 'Top Task', 59, NULL, NULL, 100)")
        conn.commit()

        odoo_record = {
            "id": 506,
            "project_id": [59, "Top Proj"],
            "task_id": [100, "Top Task"],
            "name": "Top level log",
            "unit_amount": 1.0,
            "date": "2026-11-11",
            "write_date": "2026-11-11T12:00:00"
        }

        sync_from_odoo.insert_record(
            "account_analytic_line_app",
            "account.analytic.line",
            account_id=1,
            record=odoo_record,
            db_path=db_path,
            connection=conn
        )
        conn.commit()

        cur.execute("SELECT project_id, sub_project_id, task_id, sub_task_id FROM account_analytic_line_app WHERE odoo_record_id = 506")
        row = cur.fetchone()
        assert row is not None
        assert row[0] == 59
        assert row[1] is None
        assert row[2] == 100
        assert row[3] is None

        conn.close()



