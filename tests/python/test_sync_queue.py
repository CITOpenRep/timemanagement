# -*- coding: utf-8 -*-
import json
import sqlite3
import sys
from datetime import datetime, timedelta, timezone
from unittest.mock import MagicMock

import pytest


def _setup_test_db(db_path, account_id=10):
    from common import ensure_sync_schema

    conn = sqlite3.connect(db_path)
    cur = conn.cursor()
    cur.execute(
        """
        CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            link TEXT NOT NULL,
            last_modified datetime,
            database TEXT NOT NULL,
            connectwith_id INTEGER,
            api_key TEXT,
            username TEXT NOT NULL,
            is_default INTEGER DEFAULT 0,
            sync_interval_minutes INTEGER DEFAULT NULL,
            sync_direction TEXT DEFAULT NULL,
            autosync_enabled INTEGER DEFAULT NULL,
            last_synced_at TEXT DEFAULT NULL
        )
        """
    )
    cur.execute(
        "INSERT INTO users (id, name, link, database, username, api_key) VALUES (0, 'Local', 'local://', 'local', 'local_user', NULL)"
    )
    cur.execute(
        "INSERT INTO users (id, name, link, database, username, api_key) VALUES (?, 'Work', 'https://odoo.example.com', 'prod', 'suraj', 'secret_key')",
        (account_id,),
    )
    cur.execute("CREATE TABLE app_settings (key TEXT PRIMARY KEY, value TEXT)")
    cur.execute(
        """
        CREATE TABLE notification (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            account_id INTEGER,
            timestamp TEXT DEFAULT (datetime('now')),
            message TEXT NOT NULL,
            type TEXT,
            payload TEXT NOT NULL,
            read_status INTEGER DEFAULT 0,
            panel_invoked INTEGER DEFAULT 0
        )
        """
    )
    cur.execute(
        """
        CREATE TABLE project_project_app (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            account_id INTEGER,
            parent_id INTEGER,
            planned_start_date date,
            planned_end_date date,
            allocated_hours FLOAT,
            remaining_hours FLOAT,
            favorites INTEGER,
            last_update_status TEXT,
            description TEXT,
            last_modified datetime,
            color_pallet TEXT,
            stage INTEGER,
            status TEXT DEFAULT '',
            has_draft INTEGER DEFAULT 0,
            odoo_record_id INTEGER,
            user_id INTEGER,
            create_uid INTEGER,
            UNIQUE (odoo_record_id, account_id)
        )
        """
    )
    cur.execute(
        """
        CREATE TABLE project_task_app (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            account_id INTEGER,
            project_id INTEGER,
            sub_project_id INTEGER,
            parent_id INTEGER,
            start_date date,
            end_date date,
            deadline date,
            initial_planned_hours FLOAT,
            priority TEXT,
            state INTEGER,
            personal_stage INTEGER,
            description TEXT,
            last_modified datetime,
            user_id INTEGER,
            create_uid INTEGER,
            status TEXT DEFAULT '',
            has_draft INTEGER DEFAULT 0,
            odoo_record_id INTEGER,
            UNIQUE (odoo_record_id, account_id)
        )
        """
    )
    cur.execute(
        """
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
            quadrant_id INTEGER,
            record_date datetime,
            user_id INTEGER,
            status TEXT DEFAULT '',
            timer_type TEXT DEFAULT 'manual',
            has_draft INTEGER DEFAULT 0,
            odoo_record_id INTEGER,
            UNIQUE (odoo_record_id, account_id)
        )
        """
    )
    cur.execute(
        """
        CREATE TABLE mail_activity_app (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            account_id INTEGER,
            activity_type_id INTEGER,
            summary TEXT,
            due_date DATE,
            user_id INTEGER,
            create_uid INTEGER,
            notes TEXT,
            odoo_record_id INTEGER,
            last_modified datetime,
            link_id INTEGER,
            project_id INTEGER,
            task_id INTEGER,
            resId INTEGER,
            resModel TEXT,
            state TEXT,
            status TEXT DEFAULT '',
            has_draft INTEGER DEFAULT 0,
            UNIQUE (odoo_record_id, account_id)
        )
        """
    )
    cur.execute(
        """
        CREATE TABLE project_update_app (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            account_id INTEGER,
            name TEXT,
            project_status TEXT,
            progress INTEGER,
            user_id INTEGER,
            description TEXT,
            date TEXT,
            project_id INTEGER,
            odoo_record_id INTEGER,
            last_modified datetime,
            status TEXT DEFAULT '',
            has_draft INTEGER DEFAULT 0,
            create_uid INTEGER,
            UNIQUE (odoo_record_id, account_id)
        )
        """
    )
    cur.execute(
        """
        CREATE TABLE ir_attachment_app (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            account_id INTEGER,
            name TEXT,
            description TEXT,
            res_model TEXT,
            res_id INTEGER,
            store_fname TEXT,
            file_path TEXT,
            file_size INTEGER,
            checksum TEXT,
            mimetype TEXT,
            access_token TEXT,
            url TEXT,
            image_width INTEGER,
            image_height INTEGER,
            local_url TEXT,
            odoo_record_id INTEGER,
            last_modified datetime,
            status TEXT DEFAULT '',
            UNIQUE (odoo_record_id, account_id)
        )
        """
    )
    cur.execute(
        """
        CREATE TABLE ir_model_app (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            account_id INTEGER,
            name TEXT,
            technical_name TEXT,
            status TEXT DEFAULT '',
            odoo_record_id INTEGER,
            UNIQUE (odoo_record_id, account_id)
        )
        """
    )
    cur.execute("INSERT INTO ir_model_app (account_id, name, technical_name, odoo_record_id) VALUES (?, 'Project', 'project.project', 100)", (account_id,))
    cur.execute("INSERT INTO ir_model_app (account_id, name, technical_name, odoo_record_id) VALUES (?, 'Task', 'project.task', 101)", (account_id,))
    cur.execute(
        """
        CREATE TABLE res_users_app (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            account_id INTEGER,
            name TEXT,
            login TEXT,
            email TEXT,
            work_email TEXT,
            mobile_phone TEXT,
            job_title TEXT,
            company_id INTEGER,
            share INTEGER,
            active INTEGER,
            avatar_128 TEXT,
            status TEXT DEFAULT '',
            odoo_record_id INTEGER,
            UNIQUE (odoo_record_id, account_id)
        )
        """
    )
    cur.execute(
        """
        CREATE TABLE mail_activity_type_app (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            account_id INTEGER,
            name TEXT,
            status TEXT DEFAULT '',
            odoo_record_id INTEGER,
            UNIQUE (odoo_record_id, account_id)
        )
        """
    )
    cur.execute(
        """
        CREATE TABLE project_task_type_app (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            account_id INTEGER,
            odoo_record_id INTEGER,
            name TEXT,
            description TEXT,
            sequence INTEGER DEFAULT 0,
            fold INTEGER DEFAULT 0,
            legend_blocked TEXT,
            legend_done TEXT,
            legend_normal TEXT,
            auto_validation_kanban_state INTEGER DEFAULT 0,
            mail_template_id INTEGER,
            sms_template_id INTEGER,
            rating_template_id INTEGER,
            user_id INTEGER,
            active INTEGER DEFAULT 1,
            create_date DATETIME,
            write_date DATETIME,
            __last_update DATETIME,
            is_global INTEGER DEFAULT 1,
            status TEXT DEFAULT '',
            favorites INTEGER DEFAULT 0,
            has_draft INTEGER DEFAULT 0,
            UNIQUE (odoo_record_id, account_id)
        )
        """
    )
    cur.execute(
        """
        CREATE TABLE project_project_stage_app (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            account_id INTEGER,
            odoo_record_id INTEGER,
            name TEXT,
            sequence INTEGER DEFAULT 0,
            fold INTEGER DEFAULT 0,
            mail_template_id INTEGER,
            sms_template_id INTEGER,
            active INTEGER DEFAULT 1,
            create_date DATETIME,
            write_date DATETIME,
            __last_update DATETIME,
            status TEXT DEFAULT '',
            favorites INTEGER DEFAULT 0,
            has_draft INTEGER DEFAULT 0,
            UNIQUE (odoo_record_id, account_id)
        )
        """
    )
    conn.commit()
    conn.close()
    ensure_sync_schema(db_path)


def _task_field_info():
    return {
        "name": {"type": "char", "string": "Name"},
        "project_id": {"type": "many2one", "string": "Project"},
        "display_project_id": {"type": "many2one", "string": "Display Project"},
        "parent_id": {"type": "many2one", "string": "Parent Task"},
        "planned_date_start": {"type": "datetime", "string": "Start"},
        "planned_date_end": {"type": "datetime", "string": "End"},
        "date_deadline": {"type": "date", "string": "Deadline"},
        "planned_hours": {"type": "float", "string": "Planned Hours"},
        "stage_id": {"type": "many2one", "string": "Stage"},
        "personal_stage_type_id": {"type": "many2one", "string": "Personal Stage"},
        "priority": {"type": "selection", "string": "Priority"},
        "description": {"type": "html", "string": "Description"},
        "write_date": {"type": "datetime", "string": "Last Updated"},
        "user_ids": {"type": "many2many", "string": "Assignees"},
        "create_uid": {"type": "many2one", "string": "Created by"},
        "id": {"type": "integer", "string": "ID"},
    }


def test_schema_cache_avoids_repeat_fields_get(tmp_path):
    import sync_from_odoo
    from common import invalidate_cached_model_schema

    db_path = str(tmp_path / "schema_cache.db")
    _setup_test_db(db_path, account_id=10)
    invalidate_cached_model_schema(db_path)

    client = MagicMock()
    client.db = "prod"
    client.uid = 5
    client.password = "secret"
    fields_get_calls = 0

    def fake_exec(db, uid, pwd, model, method, args, kwargs=None):
        nonlocal fields_get_calls
        if method == "fields_get":
            fields_get_calls += 1
            return _task_field_info()
        if method == "search":
            return []
        if method == "search_read":
            return []
        return []

    client.models.execute_kw.side_effect = fake_exec

    sync_from_odoo.sync_model(client, "project.task", "project_task_app", 10, db_path=db_path, run_orphan_check=False)
    sync_from_odoo.sync_model(client, "project.task", "project_task_app", 10, db_path=db_path, run_orphan_check=False)

    assert fields_get_calls == 1


def test_two_tier_pull_fast_vs_full_and_queue_protection(tmp_path):
    import sync_from_odoo
    from common import invalidate_cached_model_schema

    db_path = str(tmp_path / "two_tier.db")
    _setup_test_db(db_path, account_id=10)
    invalidate_cached_model_schema(db_path)

    # Seed two tasks:
    # - 101 synced previously, deleted on Odoo -> should be orphaned on full sync
    # - 102 synced previously, has pending queue entry -> MUST NOT be orphaned on full sync
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()
    cur.execute(
        "INSERT INTO project_task_app (id, name, account_id, odoo_record_id, last_modified, status) VALUES (1, 'Remotely Deleted', 10, 101, '2026-11-20 10:00:00', '')"
    )
    cur.execute(
        "INSERT INTO project_task_app (id, name, account_id, odoo_record_id, last_modified, status) VALUES (2, 'Locally Edited', 10, 102, '2026-11-26 10:00:00', 'updated')"
    )
    cur.execute(
        "INSERT INTO sync_queue (account_id, model_name, table_name, local_id, odoo_record_id, operation, status) VALUES (10, 'project.task', 'project_task_app', 2, 102, 'upsert', 'pending')"
    )
    conn.commit()
    conn.close()

    client = MagicMock()
    client.db = "prod"
    client.uid = 5
    client.password = "secret"

    recorded_calls = []

    def fake_exec(db, uid, pwd, model, method, args, kwargs=None):
        recorded_calls.append((model, method, args))
        if method == "fields_get":
            return _task_field_info()
        if method == "search":
            return []  # 101 and 102 absent on server
        if method == "search_read":
            return []
        return []

    client.models.execute_kw.side_effect = fake_exec

    # 1. First 'auto' sync -> resolves 'full' because last_full_sync is missing
    sync_from_odoo.sync_all_from_odoo(client, 10, db_path=db_path, sync_mode="auto")
    full_models = {c[0] for c in recorded_calls}
    assert "ir.model" in full_models
    assert "project.task.type" in full_models
    assert any(c[1] == "search" for c in recorded_calls)

    # 101 should be removed, 102 protected
    conn = sqlite3.connect(db_path)
    remaining = [r[0] for r in conn.execute("SELECT odoo_record_id FROM project_task_app").fetchall()]
    conn.close()
    assert remaining == [102]

    # 2. Second 'auto' sync within 6h -> resolves 'fast': 6 active models (incl. ir.attachment), 0 search(), 0 fields_get()
    recorded_calls.clear()
    sync_from_odoo.sync_all_from_odoo(client, 10, db_path=db_path, sync_mode="auto")

    fast_models = {c[0] for c in recorded_calls}
    assert fast_models == {
        "project.project",
        "project.task",
        "account.analytic.line",
        "mail.activity",
        "project.update",
        "ir.attachment",
    }
    assert all(c[1] == "search_read" for c in recorded_calls)
    assert len(recorded_calls) == 6


def test_disjoint_concurrent_edits_merge_cleanly(tmp_path):
    from backend.sync_queue import flush_sync_queue, invalidate_cached_client
    from common import invalidate_cached_model_schema, save_cached_model_schema

    db_path = str(tmp_path / "disjoint.db")
    _setup_test_db(db_path, account_id=10)
    invalidate_cached_model_schema(db_path)
    invalidate_cached_client()
    save_cached_model_schema(db_path, 10, "project.task", _task_field_info())

    # Baseline at 10:00 -> stage=1, description='Old'
    # User offline at 10:02 edited ONLY description='Local New Desc' (stage still 1 locally)
    # Meanwhile colleague on Odoo at 10:05 changed stage=2, description='Old'
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()
    cur.execute(
        """
        INSERT INTO project_task_app
        (id, name, account_id, state, description, last_modified, base_write_date, status, mutation_seq, odoo_record_id)
        VALUES (1, 'Shared Task', 10, 1, 'Local New Desc', '2026-11-26T10:02:00Z', '2026-11-26 10:00:00', 'updated', 1, 500)
        """
    )
    cur.execute(
        """
        INSERT INTO sync_queue
        (account_id, model_name, table_name, local_id, odoo_record_id, operation, dirty_fields, base_write_date, queued_seq, status)
        VALUES (10, 'project.task', 'project_task_app', 1, 500, 'upsert', ?, '2026-11-26 10:00:00', 1, 'pending')
        """,
        (json.dumps({"fields": ["description"], "base": {"description": "Old"}}),),
    )
    conn.commit()
    conn.close()

    mock_client = MagicMock()
    mock_client.uid = 5
    written_payloads = []
    read_calls = 0

    def fake_call(model, method, args, kwargs=None):
        nonlocal read_calls
        if method == "read":
            read_calls += 1
            if read_calls == 1:
                return [{
                    "id": 500,
                    "name": "Shared Task",
                    "stage_id": [2, "In Progress"],
                    "description": "Old",
                    "write_date": "2026-11-26 10:05:00",
                }]
            return [{"id": 500, "write_date": "2026-11-26 10:07:00"}]
        if method == "write":
            written_payloads.append(args[1])
            return True
        return None

    mock_client.call.side_effect = fake_call

    stats = flush_sync_queue(db_path, account_id=10, client=mock_client)
    assert stats["pushed"] == 1
    assert len(written_payloads) == 1
    # ONLY description pushed; remote stage_id=2 was NOT overwritten by stale local stage 1
    assert written_payloads[0] == {"description": "Local New Desc"}

    conn = sqlite3.connect(db_path)
    row = conn.execute("SELECT state, description, base_write_date, status FROM project_task_app WHERE id = 1").fetchone()
    q_count = conn.execute("SELECT COUNT(*) FROM sync_queue").fetchone()[0]
    conn.close()

    assert row[0] == 2  # Merged remote stage_id=2 locally
    assert row[1] == "Local New Desc"
    assert row[2] == "2026-11-26 10:07:00"
    assert row[3] == ""
    assert q_count == 0


def test_same_field_concurrent_conflict_uses_lww(tmp_path):
    from backend.sync_queue import flush_sync_queue, invalidate_cached_client
    from common import invalidate_cached_model_schema, save_cached_model_schema

    db_path = str(tmp_path / "same_field_lww.db")
    _setup_test_db(db_path, account_id=10)
    invalidate_cached_model_schema(db_path)
    invalidate_cached_client()
    save_cached_model_schema(db_path, 10, "project.task", _task_field_info())

    # Baseline was description='Old'; local changed to 'Local V1' at 10:02;
    # remote changed SAME field to 'Remote Newer V2' at 10:05 -> remote LWW wins!
    conn = sqlite3.connect(db_path)
    conn.execute(
        """
        INSERT INTO project_task_app
        (id, name, account_id, description, last_modified, base_write_date, status, mutation_seq, odoo_record_id)
        VALUES (1, 'Conflict Task', 10, 'Local V1', '2026-11-26T10:02:00Z', '2026-11-26 10:00:00', 'updated', 1, 505)
        """
    )
    conn.execute(
        """
        INSERT INTO sync_queue
        (account_id, model_name, table_name, local_id, odoo_record_id, operation, dirty_fields, base_write_date, queued_seq, status)
        VALUES (10, 'project.task', 'project_task_app', 1, 505, 'upsert', ?, '2026-11-26 10:00:00', 1, 'pending')
        """,
        (json.dumps({"fields": ["description"], "base": {"description": "Old"}}),),
    )
    conn.commit()
    conn.close()

    mock_client = MagicMock()
    written = []

    def fake_call(model, method, args, kwargs=None):
        if method == "read":
            return [{
                "id": 505,
                "name": "Conflict Task",
                "description": "Remote Newer V2",
                "write_date": "2026-11-26 10:05:00",
            }]
        if method == "write":
            written.append(args[1])
            return True
        return None

    mock_client.call.side_effect = fake_call
    stats = flush_sync_queue(db_path, account_id=10, client=mock_client)
    assert stats["pushed"] == 1
    assert written == []  # Did not overwrite newer remote edit on the same field

    conn = sqlite3.connect(db_path)
    desc, status = conn.execute("SELECT description, status FROM project_task_app WHERE id = 1").fetchone()
    conn.close()
    assert desc == "Remote Newer V2"
    assert status == ""


def test_base_write_date_protects_against_clock_skew(tmp_path):
    from backend.sync_queue import flush_sync_queue, invalidate_cached_client
    from common import invalidate_cached_model_schema, save_cached_model_schema

    db_path = str(tmp_path / "clock_skew.db")
    _setup_test_db(db_path, account_id=10)
    invalidate_cached_model_schema(db_path)
    invalidate_cached_client()
    save_cached_model_schema(db_path, 10, "project.task", _task_field_info())

    # Device clock is 1 hour BEHIND server write_date (09:00 vs 10:00),
    # BUT base_write_date == remote write_date (no concurrent remote edit!).
    conn = sqlite3.connect(db_path)
    conn.execute(
        """
        INSERT INTO project_task_app
        (id, name, account_id, priority, last_modified, base_write_date, status, mutation_seq, odoo_record_id)
        VALUES (1, 'Skew Task', 10, '3', '2026-11-26T09:00:00Z', '2026-11-26 10:00:00', 'updated', 1, 501)
        """
    )
    conn.execute(
        """
        INSERT INTO sync_queue
        (account_id, model_name, table_name, local_id, odoo_record_id, operation, dirty_fields, base_write_date, queued_seq, status)
        VALUES (10, 'project.task', 'project_task_app', 1, 501, 'upsert', ?, '2026-11-26 10:00:00', 1, 'pending')
        """,
        (json.dumps(["priority"]),),
    )
    conn.commit()
    conn.close()

    mock_client = MagicMock()
    written = []

    def fake_call(model, method, args, kwargs=None):
        if method == "read":
            return [{"id": 501, "priority": "0", "write_date": "2026-11-26 10:00:00"}]
        if method == "write":
            written.append(args[1])
            return True
        return None

    mock_client.call.side_effect = fake_call
    stats = flush_sync_queue(db_path, account_id=10, client=mock_client)

    assert stats["pushed"] == 1
    assert written == [{"priority": "3"}]


def test_midflight_edit_race_preserves_pending_status(tmp_path):
    from backend.sync_queue import flush_sync_queue, invalidate_cached_client
    from common import invalidate_cached_model_schema, save_cached_model_schema

    db_path = str(tmp_path / "midflight.db")
    _setup_test_db(db_path, account_id=10)
    invalidate_cached_model_schema(db_path)
    invalidate_cached_client()
    save_cached_model_schema(db_path, 10, "project.task", _task_field_info())

    conn = sqlite3.connect(db_path)
    conn.execute(
        "INSERT INTO project_task_app (id, name, account_id, last_modified, base_write_date, status, mutation_seq, odoo_record_id) VALUES (1, 'V1', 10, '2026-11-26T10:01:00Z', '2026-11-26 10:00:00', 'updated', 1, 502)"
    )
    conn.execute(
        "INSERT INTO sync_queue (account_id, model_name, table_name, local_id, odoo_record_id, operation, dirty_fields, base_write_date, queued_seq, status) VALUES (10, 'project.task', 'project_task_app', 1, 502, 'upsert', ?, '2026-11-26 10:00:00', 1, 'pending')",
        (json.dumps(["name"]),),
    )
    conn.commit()
    conn.close()

    mock_client = MagicMock()
    simulated_midflight_done = False

    def fake_call(model, method, args, kwargs=None):
        nonlocal simulated_midflight_done
        if method == "read":
            return [{"id": 502, "name": "V0", "write_date": "2026-11-26 10:00:00"}]
        if method == "write":
            if not simulated_midflight_done:
                simulated_midflight_done = True
                # Simulate user editing to V2 while push V1 is in flight!
                c2 = sqlite3.connect(db_path)
                c2.execute("UPDATE project_task_app SET name = 'V2', status = 'updated', mutation_seq = 2 WHERE id = 1")
                c2.execute("UPDATE sync_queue SET queued_seq = 2, status = 'pending' WHERE local_id = 1")
                c2.commit()
                c2.close()
            return True
        return None

    mock_client.call.side_effect = fake_call

    # Note: flush_sync_queue runs up to 3 passes; pass 1 runs V1 (sees mutation_seq=2 > queued_seq=1, preserves status='updated'),
    # pass 2 immediately picks up V2 if needed or leaves queue pending for next wake.
    flush_sync_queue(db_path, account_id=10, client=mock_client)

    conn = sqlite3.connect(db_path)
    task_row = conn.execute("SELECT name, status, mutation_seq FROM project_task_app WHERE id = 1").fetchone()
    conn.close()
    assert task_row[0] == "V2"
    # Either V2 also finished in pass 2 (name='V2', status='') OR V2 remained pending; V1 NEVER cleared V2 silently
    write_names = [call.args[2][1]["name"] for call in mock_client.call.call_args_list if call.args[1] == "write"]
    assert "V1" in write_names
    assert "V2" in write_names
    assert task_row[1] == ""


def test_offline_parent_child_dependency_and_backfill(tmp_path):
    from backend.sync_queue import flush_sync_queue, invalidate_cached_client
    from common import invalidate_cached_model_schema, save_cached_model_schema

    db_path = str(tmp_path / "parent_child.db")
    _setup_test_db(db_path, account_id=10)
    invalidate_cached_model_schema(db_path)
    invalidate_cached_client()
    save_cached_model_schema(db_path, 10, "project.task", _task_field_info())
    save_cached_model_schema(db_path, 10, "account.analytic.line", {
        "project_id": {"type": "many2one"},
        "task_id": {"type": "many2one"},
        "name": {"type": "char"},
        "unit_amount": {"type": "float"},
        "date": {"type": "date"},
        "id": {"type": "integer"},
    })
    save_cached_model_schema(db_path, 10, "mail.activity", {
        "activity_type_id": {"type": "many2one"},
        "summary": {"type": "char"},
        "date_deadline": {"type": "date"},
        "user_id": {"type": "many2one"},
        "note": {"type": "html"},
        "res_id": {"type": "integer"},
        "res_model": {"type": "char"},
        "res_model_id": {"type": "many2one"},
        "id": {"type": "integer"},
    })

    conn = sqlite3.connect(db_path)
    # Unsynced task local_id=77 under synced project 15
    conn.execute("INSERT INTO project_task_app (id, name, account_id, project_id, status, mutation_seq, odoo_record_id) VALUES (77, 'Offline Task', 10, 15, 'updated', 1, NULL)")
    # Unsynced timesheet + activity + attachment referencing local task_id=77
    conn.execute("INSERT INTO account_analytic_line_app (id, account_id, project_id, task_id, name, unit_amount, record_date, status, mutation_seq, odoo_record_id) VALUES (88, 10, 15, 77, 'Log on offline task', 1.25, '2026-11-26', 'updated', 1, NULL)")
    conn.execute("INSERT INTO mail_activity_app (id, account_id, activity_type_id, summary, due_date, user_id, notes, resModel, resId, task_id, link_id, state, status, mutation_seq, odoo_record_id) VALUES (99, 10, 1, 'Call client', '2026-11-26', 5, 'Notes', 'project.task', 77, 77, 77, 'planned', 'updated', 1, NULL)")
    conn.execute("INSERT INTO ir_attachment_app (id, account_id, name, res_model, res_id, odoo_record_id) VALUES (1, 10, 'photo.jpg', 'project.task', 77, NULL)")

    # Intentionally enqueue child items BEFORE parent item to verify dependency deferral + priority sorting
    conn.execute("INSERT INTO sync_queue (account_id, model_name, table_name, local_id, operation, queued_seq, status) VALUES (10, 'account.analytic.line', 'account_analytic_line_app', 88, 'upsert', 1, 'pending')")
    conn.execute("INSERT INTO sync_queue (account_id, model_name, table_name, local_id, operation, queued_seq, status) VALUES (10, 'mail.activity', 'mail_activity_app', 99, 'upsert', 1, 'pending')")
    conn.execute("INSERT INTO sync_queue (account_id, model_name, table_name, local_id, operation, queued_seq, status) VALUES (10, 'project.task', 'project_task_app', 77, 'upsert', 1, 'pending')")
    conn.commit()
    conn.close()

    mock_client = MagicMock()
    mock_client.uid = 5
    created_calls = []

    def fake_call(model, method, args, kwargs=None):
        if method == "create":
            payload = args[0]
            created_calls.append((model, payload))
            if model == "project.task":
                return 9001
            if model == "mail.activity":
                return 9002
            if model == "account.analytic.line":
                return 9003
        if method == "read":
            return [{"id": args[0][0], "write_date": "2026-11-26 11:00:00"}]
        return None

    mock_client.call.side_effect = fake_call

    stats = flush_sync_queue(db_path, account_id=10, client=mock_client)
    assert stats["pushed"] == 3
    assert [c[0] for c in created_calls] == ["project.task", "mail.activity", "account.analytic.line"]
    # Children MUST receive backfilled Odoo task ID 9001, NOT local ID 77!
    assert created_calls[1][1]["res_id"] == 9001
    assert created_calls[2][1]["task_id"] == 9001

    conn = sqlite3.connect(db_path)
    att_res_id = conn.execute("SELECT res_id FROM ir_attachment_app WHERE id = 1").fetchone()[0]
    act_link = conn.execute("SELECT link_id, task_id, odoo_record_id FROM mail_activity_app WHERE id = 99").fetchone()
    ts_task = conn.execute("SELECT task_id, odoo_record_id FROM account_analytic_line_app WHERE id = 88").fetchone()
    conn.close()

    assert att_res_id == 9001
    assert act_link == (9001, 9001, 9002)
    assert ts_task == (9001, 9003)


def test_remote_delete_conflict_preserves_local_edits(tmp_path):
    from backend.sync_queue import flush_sync_queue, get_sync_queue_summary, invalidate_cached_client
    from common import invalidate_cached_model_schema, save_cached_model_schema

    db_path = str(tmp_path / "conflict_deleted.db")
    _setup_test_db(db_path, account_id=10)
    invalidate_cached_model_schema(db_path)
    invalidate_cached_client()
    save_cached_model_schema(db_path, 10, "project.task", _task_field_info())

    conn = sqlite3.connect(db_path)
    conn.execute(
        "INSERT INTO project_task_app (id, name, account_id, description, last_modified, status, mutation_seq, odoo_record_id) VALUES (1, 'Important Local Work', 10, 'Detailed notes', '2026-11-26T10:00:00Z', 'updated', 1, 777)"
    )
    conn.execute(
        "INSERT INTO sync_queue (account_id, model_name, table_name, local_id, odoo_record_id, operation, dirty_fields, queued_seq, status) VALUES (10, 'project.task', 'project_task_app', 1, 777, 'upsert', ?, 1, 'pending')",
        (json.dumps(["description"]),),
    )
    conn.commit()
    conn.close()

    mock_client = MagicMock()
    mock_client.call.return_value = []  # Deleted on Odoo

    stats = flush_sync_queue(db_path, account_id=10, client=mock_client)
    assert stats["conflict"] == 1
    assert get_sync_queue_summary(db_path, 10)["conflict"] == 1

    conn = sqlite3.connect(db_path)
    task = conn.execute("SELECT description, status FROM project_task_app WHERE id = 1").fetchone()
    notif = conn.execute("SELECT type, message FROM notification").fetchall()
    conn.close()

    assert task == ("Detailed notes", "updated")
    assert len(notif) == 1
    assert notif[0][0] == "Sync"
    assert "deleted on Odoo" in notif[0][1]


def test_crash_recovery_backoff_and_timer_protection(tmp_path):
    from backend.sync_queue import flush_sync_queue, invalidate_cached_client
    from common import invalidate_cached_model_schema, save_cached_model_schema

    db_path = str(tmp_path / "recovery_backoff.db")
    _setup_test_db(db_path, account_id=10)
    invalidate_cached_model_schema(db_path)
    invalidate_cached_client()
    save_cached_model_schema(db_path, 10, "account.analytic.line", {
        "name": {"type": "char"},
        "unit_amount": {"type": "float"},
        "date": {"type": "date"},
        "id": {"type": "integer"},
    })

    conn = sqlite3.connect(db_path)
    # Row 1: Crashed mid-flight ('in_flight' status in sync_queue) -> must recover & push
    conn.execute("INSERT INTO account_analytic_line_app (id, account_id, name, unit_amount, record_date, status, mutation_seq, odoo_record_id) VALUES (1, 10, 'Recovered', 1.0, '2026-11-26', 'updated', 1, NULL)")
    conn.execute("INSERT INTO sync_queue (account_id, model_name, table_name, local_id, operation, queued_seq, status) VALUES (10, 'account.analytic.line', 'account_analytic_line_app', 1, 'upsert', 1, 'in_flight')")
    # Row 2: Active running timer -> MUST NEVER be pushed even if hydrated/queued
    conn.execute("INSERT INTO account_analytic_line_app (id, account_id, name, unit_amount, record_date, status, mutation_seq, odoo_record_id) VALUES (2, 10, 'Live Timer', 0.2, '2026-11-26', 'active', 1, NULL)")
    conn.execute("INSERT INTO sync_queue (account_id, model_name, table_name, local_id, operation, queued_seq, status) VALUES (10, 'account.analytic.line', 'account_analytic_line_app', 2, 'upsert', 1, 'pending')")
    conn.commit()
    conn.close()

    # Transient failure first -> sets backoff
    failing_client = MagicMock()
    failing_client.call.side_effect = TimeoutError("Connection timed out")
    stats1 = flush_sync_queue(db_path, account_id=10, client=failing_client)
    assert stats1["pushed"] == 0
    assert stats1["min_retry_delay"] == 5

    # Normal flush inside backoff window skips Row 1; ignore_backoff=True pushes immediately
    ok_client = MagicMock()
    ok_client.call.side_effect = lambda m, meth, a, kw=None: 7001 if meth == "create" else [{"id": 7001, "write_date": "2026-11-26 12:00:00"}]

    stats_skipped = flush_sync_queue(db_path, account_id=10, client=ok_client, ignore_backoff=False)
    assert stats_skipped["pushed"] == 0

    stats_forced = flush_sync_queue(db_path, account_id=10, client=ok_client, ignore_backoff=True)
    assert stats_forced["pushed"] == 1

    conn = sqlite3.connect(db_path)
    timer_status = conn.execute("SELECT status, odoo_record_id FROM account_analytic_line_app WHERE id = 2").fetchone()
    conn.close()
    assert timer_status == ("active", None)


def test_fast_sync_fetches_missing_lookup_references_on_demand_and_respects_6h_window(tmp_path):
    import sync_from_odoo
    from common import invalidate_cached_model_schema, save_cached_model_schema

    db_path = str(tmp_path / "lookup_miss.db")
    _setup_test_db(db_path, account_id=10)
    invalidate_cached_model_schema(db_path)

    # Cache schemas so fast sync + on-demand lookup require 0 fields_get calls
    save_cached_model_schema(db_path, 10, "project.task", _task_field_info())
    save_cached_model_schema(db_path, 10, "project.project", {"id": {"type": "integer"}, "name": {"type": "char"}, "write_date": {"type": "datetime"}})
    save_cached_model_schema(db_path, 10, "account.analytic.line", {"id": {"type": "integer"}, "name": {"type": "char"}, "write_date": {"type": "datetime"}})
    save_cached_model_schema(db_path, 10, "mail.activity", {"id": {"type": "integer"}, "summary": {"type": "char"}, "write_date": {"type": "datetime"}})
    save_cached_model_schema(db_path, 10, "project.update", {"id": {"type": "integer"}, "name": {"type": "char"}, "write_date": {"type": "datetime"}})
    save_cached_model_schema(db_path, 10, "ir.attachment", {
        "id": {"type": "integer"},
        "name": {"type": "char"},
        "res_model": {"type": "char"},
        "res_id": {"type": "integer"},
        "write_date": {"type": "datetime"},
    })
    save_cached_model_schema(db_path, 10, "res.users", {"id": {"type": "integer"}, "name": {"type": "char"}, "login": {"type": "char"}, "active": {"type": "boolean"}})
    save_cached_model_schema(db_path, 10, "project.task.type", {"id": {"type": "integer"}, "name": {"type": "char"}, "write_date": {"type": "datetime"}})

    conn = sqlite3.connect(db_path)
    # Pre-seed user 5 locally, while user 77 and stage 88 do NOT exist locally yet.
    conn.execute("INSERT INTO res_users_app (account_id, odoo_record_id, name, login, active) VALUES (10, 5, 'Suraj', 'suraj', 1)")
    now_utc = datetime.now(timezone.utc)
    five_hours_ago = (now_utc - timedelta(hours=5)).strftime("%Y-%m-%dT%H:%M:%SZ")
    six_hours_ago = (now_utc - timedelta(hours=6, minutes=1)).strftime("%Y-%m-%dT%H:%M:%SZ")
    conn.execute("INSERT OR REPLACE INTO app_settings (key, value) VALUES ('last_full_sync_10', ?)", (five_hours_ago,))
    conn.commit()
    conn.close()

    assert sync_from_odoo.resolve_effective_sync_mode(db_path, 10, "auto") == "fast"
    conn = sqlite3.connect(db_path)
    conn.execute("INSERT OR REPLACE INTO app_settings (key, value) VALUES ('last_full_sync_10', ?)", (six_hours_ago,))
    conn.commit()
    conn.close()
    assert sync_from_odoo.resolve_effective_sync_mode(db_path, 10, "auto") == "full"

    calls = []

    def fake_exec(db, uid, pwd, model, method, args, kwargs=None):
        calls.append((model, method, args, kwargs))
        if model == "project.task" and method == "search_read":
            return [{
                "id": 901,
                "name": "Task With New Stage & User",
                "stage_id": [88, "UAT"],
                "user_ids": [5, 77],
                "create_uid": [5, "Suraj"],
                "write_date": "2026-11-26 12:30:00",
            }]
        if model == "ir.attachment" and method == "search_read":
            return [{
                "id": 3001,
                "name": "screenshot.png",
                "res_model": "project.task",
                "res_id": 901,
                "write_date": "2026-11-26 12:30:05",
            }]
        if model == "res.users" and method == "search_read":
            return [{"id": 77, "name": "Priya", "login": "priya", "active": True}]
        if model == "project.task.type" and method == "search_read":
            return [{"id": 88, "name": "UAT", "write_date": "2026-11-26 12:25:00"}]
        return []

    client = MagicMock()
    client.db = "prod"
    client.uid = 5
    client.password = "secret"
    client.models.execute_kw.side_effect = fake_exec

    sync_from_odoo.sync_all_from_odoo(client, 10, db_path=db_path, sync_mode="fast")

    lookup_calls = [c for c in calls if c[0] in ("res.users", "project.task.type")]
    assert len(lookup_calls) == 2

    user_call = next(c for c in lookup_calls if c[0] == "res.users")
    assert user_call[2] == [[("id", "in", [77])]]  # 5 was already local
    assert user_call[3].get("context") == {"active_test": False}

    stage_call = next(c for c in lookup_calls if c[0] == "project.task.type")
    assert stage_call[2] == [[("id", "in", [88])]]

    conn = sqlite3.connect(db_path)
    user_row = conn.execute("SELECT name FROM res_users_app WHERE account_id = 10 AND odoo_record_id = 77").fetchone()
    stage_row = conn.execute("SELECT name FROM project_task_type_app WHERE account_id = 10 AND odoo_record_id = 88").fetchone()
    att_row = conn.execute("SELECT name, res_id FROM ir_attachment_app WHERE account_id = 10 AND odoo_record_id = 3001").fetchone()
    conn.close()

    assert user_row == ("Priya",)
    assert stage_row == ("UAT",)
    assert att_row == ("screenshot.png", 901)

    # Subsequent fast sync referencing already-fetched user 77 and stage 88 fires 0 lookup calls
    calls.clear()
    sync_from_odoo.sync_all_from_odoo(client, 10, db_path=db_path, sync_mode="fast")
    assert [c for c in calls if c[0] in ("res.users", "project.task.type")] == []


def test_queue_item_state_events_and_active_item_hydration(tmp_path, monkeypatch):
    from backend import sync_queue
    from common import invalidate_cached_model_schema, save_cached_model_schema

    db_path = str(tmp_path / "queue_events.db")
    _setup_test_db(db_path, account_id=10)
    invalidate_cached_model_schema(db_path)
    sync_queue.invalidate_cached_client()
    save_cached_model_schema(db_path, 10, "project.task", _task_field_info())

    emitted = []
    monkeypatch.setattr(sync_queue, "send", lambda evt, payload: emitted.append((evt, payload)) or True)

    conn = sqlite3.connect(db_path)
    # Row 1: mid-flight edit race -> in_flight -> pending
    conn.execute(
        "INSERT INTO project_task_app (id, name, account_id, description, last_modified, base_write_date, status, mutation_seq, odoo_record_id) "
        "VALUES (1, 'Race Task', 10, 'Edit 1', '2026-11-26T10:00:00Z', '2026-11-26 09:00:00', 'updated', 1, 901)"
    )
    conn.execute(
        "INSERT INTO sync_queue (account_id, model_name, table_name, local_id, odoo_record_id, operation, dirty_fields, base_write_date, queued_seq, status) "
        "VALUES (10, 'project.task', 'project_task_app', 1, 901, 'upsert', ?, '2026-11-26 09:00:00', 1, 'pending')",
        (json.dumps(["description"]),),
    )
    # Row 2: stuck in_flight recovery test
    conn.execute(
        "INSERT INTO project_task_app (id, name, account_id, description, last_modified, status, mutation_seq, odoo_record_id) "
        "VALUES (2, 'Stuck Task', 10, 'D', '2026-11-26T10:00:00Z', 'updated', 1, 902)"
    )
    conn.execute(
        "INSERT INTO sync_queue (account_id, model_name, table_name, local_id, odoo_record_id, operation, dirty_fields, queued_seq, status) "
        "VALUES (10, 'project.task', 'project_task_app', 2, 902, 'upsert', ?, 1, 'in_flight')",
        (json.dumps(["description"]),),
    )
    conn.commit()
    conn.close()

    sync_queue.recover_stuck_queue_items(db_path, account_id=10)
    assert ("queue_item_state", {"account_id": 10, "model_name": "project.task", "local_id": 2, "state": "pending"}) in emitted

    emitted.clear()

    write_hits = {"901": 0}

    def race_call(model, method, args, kwargs=None):
        target_id = args[0][0]
        if method == "read":
            return [{"id": target_id, "write_date": "2026-11-26 09:00:00", "description": "Old"}]
        if method == "write":
            if target_id == 901:
                write_hits["901"] += 1
                if write_hits["901"] == 1:
                    c2 = sqlite3.connect(db_path)
                    c2.execute("UPDATE project_task_app SET mutation_seq = 2, description = 'Edit 2' WHERE id = 1")
                    c2.execute("UPDATE sync_queue SET queued_seq = 2 WHERE account_id = 10 AND model_name = 'project.task' AND local_id = 1")
                    c2.commit()
                    c2.close()
            return True
        return True

    ok_client = MagicMock()
    ok_client.uid = 5
    ok_client.call.side_effect = race_call

    sync_queue.flush_sync_queue(db_path, account_id=10, client=ok_client)

    states_1 = [p["state"] for e, p in emitted if e == "queue_item_state" and p["local_id"] == 1]
    states_2 = [p["state"] for e, p in emitted if e == "queue_item_state" and p["local_id"] == 2]
    # Pass 1 hits mid-flight edit -> requeued as 'pending'; pass 2 finishes -> 'synced'
    assert states_1 == ["in_flight", "pending", "in_flight", "synced"]
    assert states_2 == ["in_flight", "synced"]
    assert any(e == "queue_synced" for e, _ in emitted)
    assert sync_queue.get_sync_queue_items(db_path, account_id=10) == []

    # Re-queue Row 1 to test transient backoff retry -> remote-delete conflict events + hydration
    conn = sqlite3.connect(db_path)
    conn.execute("UPDATE project_task_app SET status = 'updated', mutation_seq = 3 WHERE id = 1")
    conn.execute(
        "INSERT INTO sync_queue (account_id, model_name, table_name, local_id, odoo_record_id, operation, dirty_fields, base_write_date, queued_seq, status) "
        "VALUES (10, 'project.task', 'project_task_app', 1, 901, 'upsert', ?, '2026-11-26 09:00:00', 3, 'pending')",
        (json.dumps(["description"]),),
    )
    conn.commit()
    conn.close()

    assert sync_queue.get_sync_queue_items(db_path, account_id=10)[0]["state"] == "pending"

    # Transient error -> pending with error & next_retry_at; remote delete -> conflict
    emitted.clear()
    err_client = MagicMock()
    err_client.uid = 5
    err_client.call.side_effect = TimeoutError("Connection timed out")
    sync_queue.flush_sync_queue(db_path, account_id=10, client=err_client, ignore_backoff=True)
    retry_evts = [p for e, p in emitted if e == "queue_item_state" and p["local_id"] == 1]
    assert [p["state"] for p in retry_evts] == ["in_flight", "pending"]
    assert "timed out" in retry_evts[-1]["error"].lower()
    assert retry_evts[-1].get("next_retry_at")

    emitted.clear()
    deleted_client = MagicMock()
    deleted_client.uid = 5
    deleted_client.call.side_effect = lambda m, meth, a, kw=None: [] if meth == "read" else True
    sync_queue.flush_sync_queue(db_path, account_id=10, client=deleted_client, ignore_backoff=True)
    conflict_evts = [p for e, p in emitted if e == "queue_item_state" and p["local_id"] == 1]
    assert [p["state"] for p in conflict_evts] == ["in_flight", "conflict"]
    assert sync_queue.get_sync_queue_items(db_path, account_id=10)[0]["state"] == "conflict"
