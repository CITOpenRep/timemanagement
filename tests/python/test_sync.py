# -*- coding: utf-8 -*-
import sys
import pytest
import backend

sync_module = sys.modules["backend.sync"]


class TestSyncLockAndConcurrency:
    def test_sync_background_skips_when_already_in_progress(self, monkeypatch):
        monkeypatch.setattr(sync_module, "sync_in_progress", True)

        result = sync_module.sync_background("test.sqlite", 1)

        assert result is False

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


