#!/usr/bin/python3
# -*- coding: utf-8 -*-
"""
Push helper for TimeManagement app.
Handles incoming push notifications and formats them for display.
"""

import sys
import json
import os
import re
import urllib.parse
import sqlite3
from pathlib import Path
from datetime import datetime, timezone

# Database path for storing notifications
DB_DIR = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local" / "share" / "ubtms")) / "Databases"

def get_db_path():
    """Get the path to the app database."""
    base_dirs = [
        Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local" / "share" / "ubtms")),
        Path.home() / ".clickable" / "home" / ".local" / "share" / "ubtms",
    ]
    my_db_hash = "8912ff6b21d680ad2a2832070dca24d0.sqlite"
    for b in base_dirs:
        target = b / "Databases" / my_db_hash
        if target.exists():
            return str(target)
    for b in base_dirs:
        db_dir = b / "Databases"
        if db_dir.exists():
            db_files = list(db_dir.glob("*.sqlite"))
            if db_files:
                return str(max(db_files, key=lambda p: p.stat().st_mtime))
    return str(base_dirs[0] / "timemanagement.db")

def resolve_account_id(cursor, extra):
    """
    Resolve target account ID in SQLite users table using:
    1. Direct account_id if already present.
    2. odoo_url and username (and database) matching users table.
    3. database and username matching users table.
    4. username matching users table.
    5. odoo_url matching link column.
    6. Default remote account (is_default = 1 and id > 0).
    7. First remote account (id > 0).
    8. Fallback to 1.
    """
    if isinstance(extra, dict):
        account_id = extra.get("account_id")
        if account_id and int(account_id) > 0:
            return int(account_id)

        odoo_url = (extra.get("odoo_url") or "").strip().rstrip("/")
        db_name = (extra.get("db") or "").strip()
        uname = (extra.get("username") or "").strip()

        # Prioritize URL + username combination to distinguish multiple users on the same server
        if odoo_url and uname:
            clean_host = re.sub(r"^https?://", "", odoo_url).strip("/")
            if db_name:
                cursor.execute("""
                    SELECT id FROM users 
                    WHERE (link = ? OR link = ? OR link LIKE ? OR link LIKE ?)
                      AND database = ? AND username = ?
                    ORDER BY id ASC LIMIT 1
                """, (odoo_url, f"{odoo_url}/", f"{odoo_url}%", f"%{clean_host}%", db_name, uname))
                row = cursor.fetchone()
                if row and row[0] is not None:
                    return int(row[0])

            cursor.execute("""
                SELECT id FROM users 
                WHERE (link = ? OR link = ? OR link LIKE ? OR link LIKE ?)
                  AND username = ?
                ORDER BY id ASC LIMIT 1
            """, (odoo_url, f"{odoo_url}/", f"{odoo_url}%", f"%{clean_host}%", uname))
            row = cursor.fetchone()
            if row and row[0] is not None:
                return int(row[0])

        if db_name and uname:
            cursor.execute("SELECT id FROM users WHERE database = ? AND username = ? ORDER BY id ASC LIMIT 1",
                           (db_name, uname))
            row = cursor.fetchone()
            if row and row[0] is not None:
                return int(row[0])

        if uname:
            cursor.execute("SELECT id FROM users WHERE username = ? AND id > 0 ORDER BY id ASC LIMIT 1",
                           (uname,))
            row = cursor.fetchone()
            if row and row[0] is not None:
                return int(row[0])

        if odoo_url:
            clean_host = re.sub(r"^https?://", "", odoo_url).strip("/")
            cursor.execute("""
                SELECT id FROM users 
                WHERE (link = ? OR link = ? OR link LIKE ? OR link LIKE ?) AND id > 0
                ORDER BY id ASC LIMIT 1
            """, (odoo_url, f"{odoo_url}/", f"{odoo_url}%", f"%{clean_host}%"))
            row = cursor.fetchone()
            if row and row[0] is not None:
                return int(row[0])

    cursor.execute("SELECT id FROM users WHERE is_default = 1 AND id > 0 LIMIT 1")
    row = cursor.fetchone()
    if row and row[0] is not None:
        return int(row[0])

    cursor.execute("SELECT id FROM users WHERE id > 0 ORDER BY id ASC LIMIT 1")
    row = cursor.fetchone()
    if row and row[0] is not None:
        return int(row[0])

    return 1

def store_notification(notif_type, message, payload, account_id=0):
    """Store notification in database for in-app display."""
    try:
        db_path = get_db_path()
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Ensure table exists
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS notification (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                account_id INTEGER,
                timestamp TEXT DEFAULT (datetime('now')),
                message TEXT NOT NULL,
                type TEXT CHECK(type IN ('Activity', 'Task', 'Project', 'ProjectUpdate', 'Timesheet', 'Sync')),
                payload TEXT NOT NULL,
                read_status INTEGER DEFAULT 0,
                panel_invoked INTEGER DEFAULT 0
            )
        """)

        # Upgrade path for existing databases created before panel_invoked existed.
        cursor.execute("PRAGMA table_info(notification)")
        columns = {row[1] for row in cursor.fetchall()}
        if "panel_invoked" not in columns:
            cursor.execute("ALTER TABLE notification ADD COLUMN panel_invoked INTEGER DEFAULT 0")
        
        # Check for duplicate unread notification with same type+message
        cursor.execute("""
            SELECT COUNT(*) FROM notification 
            WHERE message = ? AND type = ? AND read_status = 0
        """, (message, notif_type))
        count = cursor.fetchone()[0]
        
        if count > 0:
            # Duplicate unread notification exists, skip
            conn.close()
            return
        
        # Insert notification with associated account ID
        now_str = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        cursor.execute("""
            INSERT INTO notification (account_id, timestamp, message, type, payload, read_status, panel_invoked)
            VALUES (?, ?, ?, ?, ?, 0, 1)
        """, (account_id, now_str, message, notif_type, json.dumps(payload)))
        
        conn.commit()
        conn.close()
    except Exception:
        pass  # Silent failure - notification display is more important

def check_client_burst_flood(account_id, max_burst=5, window_sec=5.0, max_storage_burst=12):
    """
    Detect rapid notification flood on device (e.g. historical queue flush on account sync).
    Returns (is_silenced, should_suppress_storage).
    """
    import tempfile
    import time
    flood_file = Path(tempfile.gettempdir()) / f"ubtms_push_flood_{account_id}.json"
    now = time.time()
    timestamps = []
    try:
        if flood_file.exists():
            with open(flood_file, "r") as f:
                data = json.load(f)
                if isinstance(data, list):
                    timestamps = [t for t in data if isinstance(t, (int, float)) and now - t < window_sec]
    except Exception:
        timestamps = []

    timestamps.append(now)
    try:
        with open(flood_file, "w") as f:
            json.dump(timestamps[-50:], f)
    except Exception:
        pass

    count = len(timestamps)
    is_silenced = count > max_burst
    should_suppress_storage = count > max_storage_burst
    return is_silenced, should_suppress_storage

def is_duplicate_notification(notif_type, record_id, summary, body):
    """
    Check if an identical notification was recently received or is currently unread.
    Returns True if this is a duplicate.
    """
    try:
        db_path = get_db_path()
        if not Path(db_path).exists():
            return False
        conn = sqlite3.connect(db_path)
        cur = conn.cursor()

        # Check 1: Record ID matching unread notification in local database
        if record_id and int(record_id) > 0:
            cur.execute("""
                SELECT id FROM notification 
                WHERE type = ? AND read_status = 0 AND payload LIKE ?
                LIMIT 1
            """, (notif_type, f'%"odoo_record_id": {record_id}%'))
            if cur.fetchone():
                conn.close()
                return True

        # Check 2: Same type and message received recently (within 30 minutes)
        cur.execute("""
            SELECT id FROM notification 
            WHERE type = ? AND message = ? AND timestamp > datetime('now', '-30 minutes')
            LIMIT 1
        """, (notif_type, body))
        row = cur.fetchone()
        conn.close()
        return row is not None
    except Exception:
        return False

def get_unread_count():
    """Count total unread notifications in local database for launcher emblem badge."""
    try:
        db_path = get_db_path()
        if not Path(db_path).exists():
            return 1
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM notification WHERE read_status = 0")
        row = cursor.fetchone()
        conn.close()
        return int(row[0]) if row and row[0] is not None else 1
    except Exception:
        return 1

def should_popup_notification(summary="", body="", is_urgent=False):
    """
    Check if popup banners should be displayed based on user schedule settings.
    Respects:
    1. Master notification toggle (notifications_enabled)
    2. Working days (e.g. Mon-Fri)
    3. Working hours (active_start to active_end, supporting overnight schedules)
    4. User / system timezone
    5. Priority / urgency bypass (urgent items bypass quiet hours)
    """
    if is_urgent or "urgent" in summary.lower() or "urgent" in body.lower():
        return True

    try:
        db_path = get_db_path()
        if not Path(db_path).exists():
            return True

        src_dir = Path(__file__).resolve().parent / "src"
        if str(src_dir) not in sys.path:
            sys.path.insert(0, str(src_dir))

        from common import should_send_notification
        allowed, _ = should_send_notification(db_path)
        return bool(allowed)
    except Exception:
        # Fallback to direct SQLite check for master toggle
        try:
            db_path = get_db_path()
            conn = sqlite3.connect(db_path)
            cur = conn.cursor()
            cur.execute("SELECT value FROM settings WHERE key = 'notifications_enabled'")
            row = cur.fetchone()
            conn.close()
            if row and str(row[0]).strip().lower() == "false":
                return False
        except Exception:
            pass
        return True

def pre_populate_record(notif_type, record_id, summary, body, extra_data=None):
    """
    Pre-populate incoming record and immediate relations into SQLite.
    Respects Decision 1: Option A (upsert base record, preserve active local drafts).
    Ensures no required database or UI fields are missing.
    """
    if not record_id or record_id <= 0:
        return False

    extra = extra_data if isinstance(extra_data, dict) else {}
    target_type = str(extra.get("model") or notif_type).lower()
    if "update" in target_type:
        model = "project.update"
    elif "activity" in target_type:
        model = "mail.activity"
    elif "timesheet" in target_type or "analytic" in target_type:
        model = "account.analytic.line"
    elif "project" in target_type and "task" not in target_type:
        model = "project.project"
    else:
        model = "project.task"

    try:
        db_path = get_db_path()
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()

        # Resolve remote account ID accurately using connection metadata
        account_id = resolve_account_id(cursor, extra)
        now_str = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S")

        if model == "project.task":
            cursor.execute("PRAGMA table_info(project_task_app)")
            task_cols = {r[1] for r in cursor.fetchall()}
            if not task_cols:
                conn.close()
                return False

            task_name = extra.get("name") or extra.get("display_name") or summary or "New Task"
            task_desc = extra.get("description") or extra.get("notes") or body or ""

            project_id = extra.get("project_id")
            if isinstance(project_id, (list, tuple)) and len(project_id) > 0:
                project_id = project_id[0]
            project_name = extra.get("project_name")
            if not project_name and isinstance(extra.get("project_id"), (list, tuple)) and len(extra.get("project_id")) > 1:
                project_name = extra.get("project_id")[1]

            stage_id = extra.get("stage_id") or extra.get("state")
            if isinstance(stage_id, (list, tuple)) and len(stage_id) > 0:
                stage_id = stage_id[0]
            stage_name = extra.get("stage_name")
            if not stage_name and isinstance(extra.get("stage_id"), (list, tuple)) and len(extra.get("stage_id")) > 1:
                stage_name = extra.get("stage_id")[1]

            personal_stage = extra.get("personal_stage") or extra.get("personal_stage_type_id")
            if isinstance(personal_stage, (list, tuple)) and len(personal_stage) > 0:
                personal_stage = personal_stage[0]

            user_id = extra.get("user_id")
            if isinstance(user_id, (list, tuple)) and len(user_id) > 0:
                user_id = user_id[0]
            user_name = extra.get("assignee_name") or extra.get("user_name")
            if not user_name and isinstance(extra.get("user_id"), (list, tuple)) and len(extra.get("user_id")) > 1:
                user_name = extra.get("user_id")[1]

            creator_id = extra.get("create_uid")
            if isinstance(creator_id, (list, tuple)) and len(creator_id) > 0:
                creator_id = creator_id[0]
            creator_name = extra.get("assigner_name")
            if not creator_name and isinstance(extra.get("create_uid"), (list, tuple)) and len(extra.get("create_uid")) > 1:
                creator_name = extra.get("create_uid")[1]

            parent_id = extra.get("parent_id")
            if isinstance(parent_id, (list, tuple)) and len(parent_id) > 0:
                parent_id = parent_id[0]

            sub_project_id = extra.get("sub_project_id")
            if isinstance(sub_project_id, (list, tuple)) and len(sub_project_id) > 0:
                sub_project_id = sub_project_id[0]

            start_date = extra.get("start_date") or extra.get("planned_date_start")
            end_date = extra.get("end_date") or extra.get("planned_date_end")
            deadline = extra.get("deadline") or extra.get("date_deadline")
            allocated_hours = float(extra.get("allocated_hours") or extra.get("planned_hours") or extra.get("initial_planned_hours") or 0.0)
            priority = str(extra.get("priority", "0"))

            # Ensure placeholder foreign key rows exist so UI resolves names immediately
            try:
                if project_id and int(project_id) > 0 and project_name:
                    cursor.execute(
                        "SELECT id FROM project_project_app WHERE odoo_record_id = ? AND account_id = ?",
                        (int(project_id), account_id)
                    )
                    if not cursor.fetchone():
                        cursor.execute("""
                            INSERT INTO project_project_app (
                                name, account_id, odoo_record_id, last_modified, status, has_draft
                            ) VALUES (?, ?, ?, ?, '', 0)
                        """, (str(project_name), account_id, int(project_id), now_str))

                if stage_id and int(stage_id) > 0 and stage_name:
                    cursor.execute(
                        "SELECT id FROM project_task_type_app WHERE odoo_record_id = ? AND account_id = ?",
                        (int(stage_id), account_id)
                    )
                    if not cursor.fetchone():
                        cursor.execute("""
                            INSERT INTO project_task_type_app (
                                name, account_id, odoo_record_id
                            ) VALUES (?, ?, ?)
                        """, (str(stage_name), account_id, int(stage_id)))

                if user_id and int(user_id) > 0 and user_name:
                    cursor.execute(
                        "SELECT id FROM res_users_app WHERE odoo_record_id = ? AND account_id = ?",
                        (int(user_id), account_id)
                    )
                    if not cursor.fetchone():
                        cursor.execute("""
                            INSERT INTO res_users_app (
                                name, account_id, odoo_record_id, status
                            ) VALUES (?, ?, ?, '')
                        """, (str(user_name), account_id, int(user_id)))

                if creator_id and int(creator_id) > 0 and creator_name:
                    cursor.execute(
                        "SELECT id FROM res_users_app WHERE odoo_record_id = ? AND account_id = ?",
                        (int(creator_id), account_id)
                    )
                    if not cursor.fetchone():
                        cursor.execute("""
                            INSERT INTO res_users_app (
                                name, account_id, odoo_record_id, status
                            ) VALUES (?, ?, ?, '')
                        """, (str(creator_name), account_id, int(creator_id)))
            except Exception:
                pass

            cursor.execute(
                "SELECT id, has_draft, name, description FROM project_task_app WHERE odoo_record_id = ? AND account_id = ?",
                (record_id, account_id)
            )
            existing = cursor.fetchone()

            if existing:
                local_id, has_draft, cur_name, cur_desc = existing
                update_fields = ["last_modified = ?"]
                params = [now_str]

                if not has_draft:
                    if "name" in task_cols:
                        update_fields.append("name = ?")
                        params.append(task_name)
                    if task_desc and "description" in task_cols:
                        update_fields.append("description = ?")
                        params.append(task_desc)

                if project_id and "project_id" in task_cols:
                    update_fields.append("project_id = ?")
                    params.append(int(project_id))
                if sub_project_id and "sub_project_id" in task_cols:
                    update_fields.append("sub_project_id = ?")
                    params.append(int(sub_project_id))
                if parent_id and "parent_id" in task_cols:
                    update_fields.append("parent_id = ?")
                    params.append(int(parent_id))
                if stage_id and "state" in task_cols:
                    update_fields.append("state = ?")
                    params.append(int(stage_id))
                if personal_stage and "personal_stage" in task_cols:
                    update_fields.append("personal_stage = ?")
                    params.append(int(personal_stage))
                if user_id and "user_id" in task_cols:
                    update_fields.append("user_id = ?")
                    params.append(int(user_id))
                if creator_id and "create_uid" in task_cols:
                    update_fields.append("create_uid = ?")
                    params.append(int(creator_id))
                if start_date and "start_date" in task_cols:
                    update_fields.append("start_date = ?")
                    params.append(str(start_date))
                if end_date and "end_date" in task_cols:
                    update_fields.append("end_date = ?")
                    params.append(str(end_date))
                if deadline and "deadline" in task_cols:
                    update_fields.append("deadline = ?")
                    params.append(str(deadline))
                if allocated_hours > 0 and "initial_planned_hours" in task_cols:
                    update_fields.append("initial_planned_hours = ?")
                    params.append(allocated_hours)
                if priority and "priority" in task_cols:
                    update_fields.append("priority = ?")
                    params.append(priority)

                params.extend([record_id, account_id])
                sql = f"UPDATE project_task_app SET {', '.join(update_fields)} WHERE odoo_record_id = ? AND account_id = ?"
                cursor.execute(sql, params)
            else:
                ins_cols = ["account_id", "has_draft", "odoo_record_id", "last_modified"]
                ins_vals = [account_id, 0, record_id, now_str]

                if "name" in task_cols:
                    ins_cols.append("name")
                    ins_vals.append(task_name)
                if "project_id" in task_cols:
                    ins_cols.append("project_id")
                    ins_vals.append(int(project_id) if project_id else -1)
                if "sub_project_id" in task_cols:
                    ins_cols.append("sub_project_id")
                    ins_vals.append(int(sub_project_id) if sub_project_id else -1)
                if "parent_id" in task_cols:
                    ins_cols.append("parent_id")
                    ins_vals.append(int(parent_id) if parent_id else -1)
                if "start_date" in task_cols:
                    ins_cols.append("start_date")
                    ins_vals.append(str(start_date) if start_date else None)
                if "end_date" in task_cols:
                    ins_cols.append("end_date")
                    ins_vals.append(str(end_date) if end_date else None)
                if "deadline" in task_cols:
                    ins_cols.append("deadline")
                    ins_vals.append(str(deadline) if deadline else None)
                if "initial_planned_hours" in task_cols:
                    ins_cols.append("initial_planned_hours")
                    ins_vals.append(allocated_hours)
                if "priority" in task_cols:
                    ins_cols.append("priority")
                    ins_vals.append(priority)
                if "state" in task_cols:
                    ins_cols.append("state")
                    ins_vals.append(int(stage_id) if stage_id else 1)
                if "personal_stage" in task_cols:
                    ins_cols.append("personal_stage")
                    ins_vals.append(int(personal_stage) if personal_stage else None)
                if "description" in task_cols:
                    ins_cols.append("description")
                    ins_vals.append(task_desc)
                if "user_id" in task_cols:
                    ins_cols.append("user_id")
                    ins_vals.append(int(user_id) if user_id else None)
                if "create_uid" in task_cols:
                    ins_cols.append("create_uid")
                    ins_vals.append(int(creator_id) if creator_id else None)
                if "status" in task_cols:
                    ins_cols.append("status")
                    ins_vals.append("")

                placeholders = ", ".join(["?"] * len(ins_cols))
                sql = f"INSERT INTO project_task_app ({', '.join(ins_cols)}) VALUES ({placeholders})"
                cursor.execute(sql, ins_vals)

        elif model == "project.update":
            cursor.execute("PRAGMA table_info(project_update_app)")
            update_cols = {r[1] for r in cursor.fetchall()}
            if not update_cols:
                conn.close()
                return False

            update_name = extra.get("name") or summary or "Project Update"
            status_val = extra.get("project_status") or extra.get("status") or "on_track"
            progress_val = int(extra.get("progress") or 0)
            update_desc = extra.get("description") or body or ""
            update_date = extra.get("date") or now_str[:10]

            project_id = extra.get("project_id")
            if isinstance(project_id, (list, tuple)) and len(project_id) > 0:
                project_id = project_id[0]
            project_name = extra.get("project_name")
            if not project_name and isinstance(extra.get("project_id"), (list, tuple)) and len(extra.get("project_id")) > 1:
                project_name = extra.get("project_id")[1]

            user_id = extra.get("user_id")
            if isinstance(user_id, (list, tuple)) and len(user_id) > 0:
                user_id = user_id[0]

            creator_id = extra.get("create_uid") or user_id
            if isinstance(creator_id, (list, tuple)) and len(creator_id) > 0:
                creator_id = creator_id[0]
            creator_name = extra.get("assigner_name") or extra.get("user_name")
            if not creator_name and isinstance(extra.get("create_uid"), (list, tuple)) and len(extra.get("create_uid")) > 1:
                creator_name = extra.get("create_uid")[1]

            # Ensure project placeholder exists
            try:
                if project_id and int(project_id) > 0 and project_name:
                    cursor.execute(
                        "SELECT id FROM project_project_app WHERE odoo_record_id = ? AND account_id = ?",
                        (int(project_id), account_id)
                    )
                    if not cursor.fetchone():
                        cursor.execute("""
                            INSERT INTO project_project_app (
                                name, account_id, odoo_record_id, last_modified, status, has_draft
                            ) VALUES (?, ?, ?, ?, '', 0)
                        """, (str(project_name), account_id, int(project_id), now_str))

                if creator_id and int(creator_id) > 0 and creator_name:
                    cursor.execute(
                        "SELECT id FROM res_users_app WHERE odoo_record_id = ? AND account_id = ?",
                        (int(creator_id), account_id)
                    )
                    if not cursor.fetchone():
                        cursor.execute("""
                            INSERT INTO res_users_app (
                                name, account_id, odoo_record_id, status
                            ) VALUES (?, ?, ?, '')
                        """, (str(creator_name), account_id, int(creator_id)))
            except Exception:
                pass

            cursor.execute(
                "SELECT id, has_draft FROM project_update_app WHERE odoo_record_id = ? AND account_id = ?",
                (record_id, account_id)
            )
            existing = cursor.fetchone()

            if existing:
                local_id, has_draft = existing
                update_fields = ["last_modified = ?"]
                params = [now_str]

                if not has_draft:
                    update_fields.append("name = ?")
                    params.append(update_name)
                    if update_desc:
                        update_fields.append("description = ?")
                        params.append(update_desc)
                    update_fields.append("project_status = ?")
                    params.append(status_val)
                    update_fields.append("progress = ?")
                    params.append(progress_val)

                if project_id and "project_id" in update_cols:
                    update_fields.append("project_id = ?")
                    params.append(int(project_id))
                if update_date and "date" in update_cols:
                    update_fields.append("date = ?")
                    params.append(str(update_date))
                if user_id and "user_id" in update_cols:
                    update_fields.append("user_id = ?")
                    params.append(int(user_id))
                if creator_id and "create_uid" in update_cols:
                    update_fields.append("create_uid = ?")
                    params.append(int(creator_id))

                params.extend([record_id, account_id])
                sql = f"UPDATE project_update_app SET {', '.join(update_fields)} WHERE odoo_record_id = ? AND account_id = ?"
                cursor.execute(sql, params)
            else:
                ins_cols = ["account_id", "name", "project_status", "progress", "user_id",
                            "description", "date", "project_id", "odoo_record_id", "last_modified",
                            "status", "has_draft"]
                ins_vals = [
                    account_id, update_name, status_val, progress_val,
                    int(user_id) if user_id else None, update_desc, str(update_date),
                    int(project_id) if project_id else -1, record_id, now_str, '', 0
                ]
                if creator_id and "create_uid" in update_cols:
                    ins_cols.append("create_uid")
                    ins_vals.append(int(creator_id))

                placeholders = ", ".join(["?"] * len(ins_cols))
                cursor.execute(f"INSERT INTO project_update_app ({', '.join(ins_cols)}) VALUES ({placeholders})", ins_vals)

        elif model == "project.project":
            cursor.execute("PRAGMA table_info(project_project_app)")
            proj_cols = {r[1] for r in cursor.fetchall()}
            if not proj_cols:
                conn.close()
                return False

            proj_name = extra.get("name") or summary or "New Project"
            proj_desc = extra.get("description") or body or ""
            start_date = extra.get("start_date") or extra.get("date_start")
            end_date = extra.get("end_date") or extra.get("date")
            allocated_hours = float(extra.get("allocated_hours") or 0.0)
            user_id = extra.get("user_id")
            if isinstance(user_id, (list, tuple)) and len(user_id) > 0:
                user_id = user_id[0]

            parent_id = extra.get("parent_id")
            if isinstance(parent_id, (list, tuple)) and len(parent_id) > 0:
                parent_id = parent_id[0]

            color_pallet = extra.get("color_pallet") or extra.get("color") or "0"
            stage = extra.get("stage") or extra.get("stage_id")
            if isinstance(stage, (list, tuple)) and len(stage) > 0:
                stage = stage[0]
            stage_name = extra.get("stage_name")

            creator_id = extra.get("create_uid") or user_id
            if isinstance(creator_id, (list, tuple)) and len(creator_id) > 0:
                creator_id = creator_id[0]
            creator_name = extra.get("assigner_name") or extra.get("manager_name")
            if not creator_name and isinstance(extra.get("create_uid"), (list, tuple)) and len(extra.get("create_uid")) > 1:
                creator_name = extra.get("create_uid")[1]

            try:
                if stage and int(stage) > 0 and stage_name:
                    cursor.execute(
                        "SELECT id FROM project_project_stage_app WHERE odoo_record_id = ? AND account_id = ?",
                        (int(stage), account_id)
                    )
                    if not cursor.fetchone():
                        cursor.execute("""
                            INSERT INTO project_project_stage_app (
                                name, account_id, odoo_record_id, active
                            ) VALUES (?, ?, ?, 1)
                        """, (str(stage_name), account_id, int(stage)))

                if creator_id and int(creator_id) > 0 and creator_name:
                    cursor.execute(
                        "SELECT id FROM res_users_app WHERE odoo_record_id = ? AND account_id = ?",
                        (int(creator_id), account_id)
                    )
                    if not cursor.fetchone():
                        cursor.execute("""
                            INSERT INTO res_users_app (
                                name, account_id, odoo_record_id, status
                            ) VALUES (?, ?, ?, '')
                        """, (str(creator_name), account_id, int(creator_id)))
            except Exception:
                pass

            cursor.execute(
                "SELECT id, has_draft FROM project_project_app WHERE odoo_record_id = ? AND account_id = ?",
                (record_id, account_id)
            )
            existing = cursor.fetchone()

            if existing:
                local_id, has_draft = existing
                update_fields = ["last_modified = ?"]
                params = [now_str]

                if not has_draft:
                    update_fields.append("name = ?")
                    params.append(proj_name)
                    if proj_desc:
                        update_fields.append("description = ?")
                        params.append(proj_desc)

                if start_date and "planned_start_date" in proj_cols:
                    update_fields.append("planned_start_date = ?")
                    params.append(str(start_date))
                if end_date and "planned_end_date" in proj_cols:
                    update_fields.append("planned_end_date = ?")
                    params.append(str(end_date))
                if allocated_hours > 0 and "allocated_hours" in proj_cols:
                    update_fields.append("allocated_hours = ?")
                    params.append(allocated_hours)
                if parent_id and "parent_id" in proj_cols:
                    update_fields.append("parent_id = ?")
                    params.append(int(parent_id))
                if color_pallet and "color_pallet" in proj_cols:
                    update_fields.append("color_pallet = ?")
                    params.append(str(color_pallet))
                if stage and "stage" in proj_cols:
                    update_fields.append("stage = ?")
                    params.append(int(stage))
                if user_id and "user_id" in proj_cols:
                    update_fields.append("user_id = ?")
                    params.append(int(user_id))
                if creator_id and "create_uid" in proj_cols:
                    update_fields.append("create_uid = ?")
                    params.append(int(creator_id))

                params.extend([record_id, account_id])
                sql = f"UPDATE project_project_app SET {', '.join(update_fields)} WHERE odoo_record_id = ? AND account_id = ?"
                cursor.execute(sql, params)
            else:
                ins_cols = ["name", "account_id", "planned_start_date", "planned_end_date",
                            "allocated_hours", "description", "last_modified", "user_id",
                            "status", "has_draft", "odoo_record_id"]
                ins_vals = [
                    proj_name, account_id, str(start_date) if start_date else None,
                    str(end_date) if end_date else None, allocated_hours, proj_desc,
                    now_str, int(user_id) if user_id else None, '', 0, record_id
                ]
                if parent_id and "parent_id" in proj_cols:
                    ins_cols.append("parent_id")
                    ins_vals.append(int(parent_id))
                if color_pallet and "color_pallet" in proj_cols:
                    ins_cols.append("color_pallet")
                    ins_vals.append(str(color_pallet))
                if stage and "stage" in proj_cols:
                    ins_cols.append("stage")
                    ins_vals.append(int(stage))
                if creator_id and "create_uid" in proj_cols:
                    ins_cols.append("create_uid")
                    ins_vals.append(int(creator_id))

                placeholders = ", ".join(["?"] * len(ins_cols))
                cursor.execute(f"INSERT INTO project_project_app ({', '.join(ins_cols)}) VALUES ({placeholders})", ins_vals)

        elif model == "mail.activity":
            cursor.execute("PRAGMA table_info(mail_activity_app)")
            act_cols = {r[1] for r in cursor.fetchall()}
            if not act_cols:
                conn.close()
                return False

            cursor.execute(
                "SELECT id, has_draft FROM mail_activity_app WHERE odoo_record_id = ? AND account_id = ?",
                (record_id, account_id)
            )
            existing = cursor.fetchone()

            act_summary = extra.get("summary") or summary or "New Activity"
            act_notes = extra.get("notes") or extra.get("note") or body or ""
            act_type_id = extra.get("activity_type_id")
            if isinstance(act_type_id, (list, tuple)) and len(act_type_id) > 0:
                act_type_id = act_type_id[0]
            act_type_name = extra.get("activity_type_name")
            if not act_type_name and isinstance(extra.get("activity_type_id"), (list, tuple)) and len(extra.get("activity_type_id")) > 1:
                act_type_name = extra.get("activity_type_id")[1]

            due_date = extra.get("due_date") or extra.get("date_deadline")
            act_state = extra.get("state")
            if not act_state and due_date:
                today_str = datetime.now(timezone.utc).strftime("%Y-%m-%d")
                d_str = str(due_date)[:10]
                act_state = "overdue" if d_str < today_str else ("today" if d_str == today_str else "planned")
            if not act_state:
                act_state = "today"

            user_id = extra.get("user_id")
            if isinstance(user_id, (list, tuple)) and len(user_id) > 0:
                user_id = user_id[0]
            assignee_name = extra.get("assignee_name") or extra.get("user_name")
            if not assignee_name and isinstance(extra.get("user_id"), (list, tuple)) and len(extra.get("user_id")) > 1:
                assignee_name = extra.get("user_id")[1]

            creator_id = extra.get("create_uid")
            if isinstance(creator_id, (list, tuple)) and len(creator_id) > 0:
                creator_id = creator_id[0]
            creator_name = extra.get("assigner_name")
            if not creator_name and isinstance(extra.get("create_uid"), (list, tuple)) and len(extra.get("create_uid")) > 1:
                creator_name = extra.get("create_uid")[1]

            res_id = extra.get("res_id") or extra.get("resId")
            res_model = extra.get("res_model") or extra.get("resModel") or ""
            link_id = extra.get("link_id") or res_id

            task_id = extra.get("task_id") or (res_id if res_model == "project.task" else None)
            task_name = extra.get("task_name") or extra.get("res_name") or (f"Task #{task_id}" if task_id else "")

            project_id = extra.get("project_id") or (res_id if res_model == "project.project" else None)
            project_name = extra.get("project_name") or (extra.get("res_name") if res_model == "project.project" else "")
            parent_id = extra.get("parent_id")

            # Ensure assignee exists in res_users_app
            if user_id and int(user_id) > 0 and assignee_name:
                try:
                    cursor.execute(
                        "SELECT id FROM res_users_app WHERE odoo_record_id = ? AND account_id = ?",
                        (int(user_id), account_id)
                    )
                    if not cursor.fetchone():
                        cursor.execute("""
                            INSERT INTO res_users_app (
                                name, odoo_record_id, account_id, last_modified, status
                            ) VALUES (?, ?, ?, ?, '')
                        """, (str(assignee_name), int(user_id), account_id, now_str))
                except Exception:
                    pass

            # Ensure creator exists in res_users_app
            if creator_id and int(creator_id) > 0 and creator_name:
                try:
                    cursor.execute(
                        "SELECT id FROM res_users_app WHERE odoo_record_id = ? AND account_id = ?",
                        (int(creator_id), account_id)
                    )
                    if not cursor.fetchone():
                        cursor.execute("""
                            INSERT INTO res_users_app (
                                name, odoo_record_id, account_id, last_modified, status
                            ) VALUES (?, ?, ?, ?, '')
                        """, (str(creator_name), int(creator_id), account_id, now_str))
                except Exception:
                    pass

            # Ensure activity type exists in mail_activity_type_app
            if act_type_id and int(act_type_id) > 0 and act_type_name:
                try:
                    cursor.execute(
                        "SELECT id FROM mail_activity_type_app WHERE odoo_record_id = ? AND account_id = ?",
                        (int(act_type_id), account_id)
                    )
                    if not cursor.fetchone():
                        cursor.execute("""
                            INSERT INTO mail_activity_type_app (
                                name, odoo_record_id, account_id, status
                            ) VALUES (?, ?, ?, '')
                        """, (str(act_type_name), int(act_type_id), account_id))
                except Exception:
                    pass

            # Ensure project placeholder exists
            if project_id and int(project_id) > 0 and project_name:
                try:
                    cursor.execute(
                        "SELECT id FROM project_project_app WHERE odoo_record_id = ? AND account_id = ?",
                        (int(project_id), account_id)
                    )
                    if not cursor.fetchone():
                        cursor.execute("""
                            INSERT INTO project_project_app (
                                name, account_id, odoo_record_id, last_modified, status, has_draft
                            ) VALUES (?, ?, ?, ?, '', 0)
                        """, (str(project_name), account_id, int(project_id), now_str))
                except Exception:
                    pass

            # Ensure task placeholder exists
            if task_id and int(task_id) > 0:
                try:
                    cursor.execute(
                        "SELECT id FROM project_task_app WHERE odoo_record_id = ? AND account_id = ?",
                        (int(task_id), account_id)
                    )
                    if not cursor.fetchone():
                        cursor.execute("""
                            INSERT INTO project_task_app (
                                name, account_id, odoo_record_id, project_id, parent_id, last_modified, status, has_draft
                            ) VALUES (?, ?, ?, ?, ?, ?, '', 0)
                        """, (
                            str(task_name),
                            account_id,
                            int(task_id),
                            int(project_id) if project_id else -1,
                            int(parent_id) if parent_id else 0,
                            now_str
                        ))
                except Exception:
                    pass

            if existing:
                local_id, has_draft = existing
                upd_dict = {
                    "last_modified": now_str,
                }
                if not has_draft:
                    upd_dict["summary"] = act_summary
                    if act_notes:
                        upd_dict["notes"] = act_notes
                if due_date:
                    upd_dict["due_date"] = str(due_date)
                if act_state:
                    upd_dict["state"] = str(act_state)
                if user_id:
                    upd_dict["user_id"] = int(user_id)
                if creator_id:
                    upd_dict["create_uid"] = int(creator_id)
                if act_type_id:
                    upd_dict["activity_type_id"] = int(act_type_id)
                if link_id:
                    upd_dict["link_id"] = int(link_id)
                if res_id:
                    upd_dict["resId"] = int(res_id)
                if res_model:
                    upd_dict["resModel"] = str(res_model)
                if task_id:
                    upd_dict["task_id"] = int(task_id)
                if project_id:
                    upd_dict["project_id"] = int(project_id)

                valid_upd = {k: v for k, v in upd_dict.items() if k in act_cols}
                set_clause = ", ".join(f"{k} = ?" for k in valid_upd.keys())
                params = list(valid_upd.values()) + [record_id, account_id]
                cursor.execute(f"UPDATE mail_activity_app SET {set_clause} WHERE odoo_record_id = ? AND account_id = ?", params)
            else:
                ins_dict = {
                    "account_id": account_id,
                    "activity_type_id": int(act_type_id) if act_type_id else 1,
                    "summary": act_summary,
                    "due_date": str(due_date) if due_date else None,
                    "user_id": int(user_id) if user_id else None,
                    "create_uid": int(creator_id) if creator_id else None,
                    "notes": act_notes,
                    "odoo_record_id": record_id,
                    "last_modified": now_str,
                    "link_id": int(link_id) if link_id else None,
                    "task_id": int(task_id) if task_id else None,
                    "project_id": int(project_id) if project_id else None,
                    "resId": int(res_id) if res_id else None,
                    "resModel": str(res_model) if res_model else "",
                    "state": str(act_state),
                    "status": "",
                    "has_draft": 0
                }
                valid_ins = {k: v for k, v in ins_dict.items() if k in act_cols}
                cols_str = ", ".join(valid_ins.keys())
                placeholders = ", ".join(["?"] * len(valid_ins))
                cursor.execute(f"INSERT INTO mail_activity_app ({cols_str}) VALUES ({placeholders})", list(valid_ins.values()))

        elif model in ("account.analytic.line", "timesheet"):
            cursor.execute("PRAGMA table_info(account_analytic_line_app)")
            ts_cols = {r[1] for r in cursor.fetchall()}
            if not ts_cols:
                conn.close()
                return False

            ts_name = extra.get("name") or summary or "Timesheet"
            unit_amount = float(extra.get("unit_amount") or extra.get("hours") or 0.0)
            proj_id = extra.get("project_id")
            if isinstance(proj_id, (list, tuple)) and len(proj_id) > 0:
                proj_id = proj_id[0]
            task_id = extra.get("task_id")
            if isinstance(task_id, (list, tuple)) and len(task_id) > 0:
                task_id = task_id[0]
            sub_task_id = extra.get("sub_task_id")
            sub_proj_id = extra.get("sub_project_id")

            if not sub_proj_id and proj_id:
                try:
                    cursor.execute(
                        "SELECT parent_id FROM project_project_app WHERE odoo_record_id = ? AND account_id = ?",
                        (int(proj_id), account_id)
                    )
                    p_row = cursor.fetchone()
                    if p_row and p_row[0] and int(p_row[0]) > 0:
                        sub_proj_id = proj_id
                        proj_id = p_row[0]
                except Exception:
                    pass

            if not sub_task_id and task_id:
                try:
                    cursor.execute(
                        "SELECT parent_id, project_id, sub_project_id FROM project_task_app WHERE odoo_record_id = ? AND account_id = ?",
                        (int(task_id), account_id)
                    )
                    t_row = cursor.fetchone()
                    if t_row and t_row[0] and int(t_row[0]) > 0:
                        sub_task_id = task_id
                        task_id = t_row[0]
                    if not sub_proj_id and t_row and len(t_row) > 2 and t_row[2] and int(t_row[2]) > 0:
                        sub_proj_id = t_row[2]
                        if t_row[1] and int(t_row[1]) > 0:
                            proj_id = t_row[1]
                except Exception:
                    pass

            record_date = extra.get("record_date") or extra.get("date") or now_str[:10]
            user_id = extra.get("user_id")
            if isinstance(user_id, (list, tuple)) and len(user_id) > 0:
                user_id = user_id[0]

            cursor.execute(
                "SELECT id, has_draft FROM account_analytic_line_app WHERE odoo_record_id = ? AND account_id = ?",
                (record_id, account_id)
            )
            existing = cursor.fetchone()

            if existing:
                local_id, has_draft = existing
                upd_fields = ["last_modified = ?"]
                params = [now_str]
                if not has_draft:
                    upd_fields.append("name = ?")
                    params.append(ts_name)
                    upd_fields.append("unit_amount = ?")
                    params.append(unit_amount)
                if proj_id:
                    upd_fields.append("project_id = ?")
                    params.append(int(proj_id))
                if task_id:
                    upd_fields.append("task_id = ?")
                    params.append(int(task_id))
                if sub_task_id:
                    upd_fields.append("sub_task_id = ?")
                    params.append(int(sub_task_id))
                if sub_proj_id:
                    upd_fields.append("sub_project_id = ?")
                    params.append(int(sub_proj_id))
                if record_date:
                    upd_fields.append("record_date = ?")
                    params.append(str(record_date))
                if user_id:
                    upd_fields.append("user_id = ?")
                    params.append(int(user_id))

                params.extend([record_id, account_id])
                sql = f"UPDATE account_analytic_line_app SET {', '.join(upd_fields)} WHERE odoo_record_id = ? AND account_id = ?"
                cursor.execute(sql, params)
            else:
                cursor.execute("""
                    INSERT INTO account_analytic_line_app (
                        account_id, name, unit_amount, project_id, sub_project_id,
                        task_id, sub_task_id, record_date, user_id, status,
                        timer_type, has_draft, odoo_record_id, last_modified
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, '', 'manual', 0, ?, ?)
                """, (
                    account_id,
                    ts_name,
                    unit_amount,
                    int(proj_id) if proj_id else -1,
                    int(sub_proj_id) if sub_proj_id else -1,
                    int(task_id) if task_id else -1,
                    int(sub_task_id) if sub_task_id else -1,
                    str(record_date),
                    int(user_id) if user_id else None,
                    record_id,
                    now_str
                ))

        conn.commit()
        conn.close()
        return True
    except Exception:
        return False

def process_notification(input_data):
    """Process incoming notification and enhance if needed."""
    try:
        notification = json.loads(input_data)
        
        # Extract notification details
        notif = notification.get("notification", {})
        card = notif.get("card", {})
        summary = card.get("summary", "")
        body = card.get("body", "")
        actions = card.get("actions", [])
        
        # Extract extra record payload if available
        extra_record = None
        for candidate in (
            notification.get("data", {}).get("record") if isinstance(notification.get("data"), dict) else None,
            notif.get("data", {}).get("record") if isinstance(notif.get("data"), dict) else None,
            notification.get("record"),
            notif.get("record"),
            card.get("record"),
            notification.get("data") if isinstance(notification.get("data"), dict) and "record" not in notification.get("data") else None,
            notif.get("data") if isinstance(notif.get("data"), dict) and "record" not in notif.get("data") else None,
            card.get("data") if isinstance(card.get("data"), dict) else None,
        ):
            if isinstance(candidate, dict) and any(k in candidate for k in ("model", "res_model", "name", "summary", "record_id")):
                extra_record = candidate
                break

        # Determine notification type from extra_record, summary, or actions
        notif_type = None
        if extra_record:
            rec_model = extra_record.get("model") or extra_record.get("res_model") or ""
            if rec_model == "mail.activity":
                notif_type = "Activity"
            elif rec_model == "project.update":
                notif_type = "ProjectUpdate"
            elif rec_model == "project.project":
                notif_type = "Project"
            elif rec_model in ("account.analytic.line", "timesheet"):
                notif_type = "Timesheet"
            elif rec_model == "project.task":
                notif_type = "Task"

        if not notif_type:
            if "Activity" in summary:
                notif_type = "Activity"
            elif "Update" in summary:
                notif_type = "ProjectUpdate"
            elif "Project" in summary:
                notif_type = "Project"
            elif "Timesheet" in summary:
                notif_type = "Timesheet"
            else:
                notif_type = "Task"

        # Check priority / urgency
        is_urgent = bool(
            card.get("urgent") or
            card.get("priority") in ("3", 3, "high", "urgent") or
            (extra_record and str(extra_record.get("priority")) in ("3", "high", "urgent")) or
            "urgent" in summary.lower() or
            "urgent" in body.lower()
        )

        # Extract record ID from actions query string, extra_record, or card
        record_id = None
        for act in actions:
            if "id=" in act:
                try:
                    import urllib.parse
                    qs = urllib.parse.parse_qs(urllib.parse.urlparse(act).query)
                    if "id" in qs:
                        record_id = int(qs["id"][0])
                    if "type" in qs:
                        notif_type = qs["type"][0]
                    break
                except Exception:
                    pass

        if not record_id and extra_record:
            rec_id_val = extra_record.get("record_id") or extra_record.get("id") or extra_record.get("res_id")
            if rec_id_val:
                try:
                    record_id = int(rec_id_val)
                except (ValueError, TypeError):
                    pass

        if not record_id:
            record_id = card.get("record_id") or card.get("id") or notif.get("data", {}).get("res_id")

        # Resolve target account ID in SQLite
        db_path = get_db_path()
        account_id = 0
        try:
            conn = sqlite3.connect(db_path)
            cur = conn.cursor()
            account_id = resolve_account_id(cur, extra_record)
            conn.close()
        except Exception:
            account_id = 1

        # Ensure app logo avatar is present
        if not card.get("icon"):
            card["icon"] = "assets/logo.png"

        # Tag notification for Lomiri coalescing (replaces previous notification instead of stacking duplicates)
        if record_id:
            card["tag"] = f"{notif_type}_{record_id}"

        # Detect self-authored project updates to prevent self-notification
        is_self_action = False
        if notif_type == "ProjectUpdate" and isinstance(extra_record, dict):
            def _extract_id(val):
                if isinstance(val, (list, tuple)) and len(val) > 0:
                    return val[0]
                return val

            author_val = _extract_id(extra_record.get("user_id"))
            creator_val = _extract_id(extra_record.get("create_uid")) or author_val
            subscriber_uid = _extract_id(extra_record.get("account_user_id"))

            if subscriber_uid and creator_val:
                try:
                    if int(subscriber_uid) == int(creator_val):
                        is_self_action = True
                except (ValueError, TypeError):
                    pass

            if not is_self_action and account_id > 0:
                try:
                    conn = sqlite3.connect(db_path)
                    cur = conn.cursor()
                    cur.execute(
                        "SELECT odoo_record_id FROM res_users_app WHERE account_id = ? AND active = 1 LIMIT 1",
                        (account_id,)
                    )
                    user_row = cur.fetchone()
                    conn.close()
                    if user_row and user_row[0] and creator_val:
                        if int(user_row[0]) == int(creator_val):
                            is_self_action = True
                except Exception:
                    pass

        is_flooded, should_suppress_storage = check_client_burst_flood(account_id)
        if is_self_action:
            card["popup"] = False
            card["persist"] = False
        elif is_flooded:
            # ponytail: historical queue flush or rapid burst, silence popups and alerts
            card["popup"] = False
            card["persist"] = True
        else:
            # Suppress audible popup banner if this is a duplicate delivery
            is_dup = is_duplicate_notification(notif_type, record_id, summary, body)
            if is_dup:
                card["popup"] = False
            else:
                card["popup"] = card.get("popup", True) and should_popup_notification(summary, body, is_urgent)
            card["persist"] = card.get("persist", True)

        # Build actions: exactly 1 action for standard interactive banner dispatch
        enhanced_actions = []
        if record_id:
            orig_action = actions[0] if actions else ""
            if orig_action and orig_action.startswith("ubtms://notification"):
                deep_link = orig_action
            else:
                deep_link = f"ubtms://notification?type={notif_type}&id={record_id}&odoo_id=1"
            enhanced_actions.append(deep_link)
        elif actions:
            enhanced_actions.append(actions[0])
        else:
            enhanced_actions.append("appid://ubtms/ubtms/current-user-version")

        card["actions"] = enhanced_actions
        notif["card"] = card

        # Configure Sound and Haptic Vibration
        if card["popup"]:
            sound_val = notif.get("sound")
            if not sound_val or sound_val is True:
                notif["sound"] = "sounds/lomiri/notifications/Positive.ogg"
            else:
                notif["sound"] = str(sound_val)

            vibrate_val = notif.get("vibrate")
            if not vibrate_val or vibrate_val is True:
                notif["vibrate"] = {
                    "pattern": [200, 100, 200],
                    "repeat": 1
                }
            elif isinstance(vibrate_val, dict):
                notif["vibrate"] = vibrate_val
        else:
            notif.pop("sound", None)
            notif.pop("vibrate", None)

        # Store in database for in-app display with record ID and all rich metadata
        store_payload = {
            "summary": summary,
            "source": "push",
            "type": notif_type,
            "account_id": account_id
        }
        if record_id:
            store_payload["odoo_record_id"] = record_id
            store_payload["id"] = record_id
            store_payload["is_odoo_id"] = True

        if extra_record:
            if not extra_record.get("assigner_name"):
                extra_record["assigner_name"] = extra_record.get("user_name") or extra_record.get("manager_name") or ""
            for k in (
                "name", "project_name", "project_id", "assigner_name", "assigner_avatar",
                "due_date", "deadline", "priority", "stage_name", "activity_type_name",
                "user_name", "manager_name", "progress", "project_status", "unit_amount",
                "hours", "date"
            ):
                if k in extra_record and extra_record[k] is not None:
                    store_payload[k] = extra_record[k]

        if not is_self_action and not should_suppress_storage:
            store_notification(notif_type, body, store_payload, account_id=account_id)

        # Pre-populate record in local SQLite database (Option 1)
        if record_id:
            pre_populate_record(notif_type, record_id, summary, body, extra_record)

        # Update launcher badge emblem counter with total unread count
        unread_count = get_unread_count()
        notif["emblem-counter"] = {
            "count": unread_count,
            "visible": unread_count > 0
        }

        notification["notification"] = notif
        
        # Return formatted notification
        return json.dumps(notification)
    except (json.JSONDecodeError, KeyError):
        # Return original if parsing fails
        return input_data

def main():
    if len(sys.argv) < 3:
        sys.exit(1)
    
    input_file, output_file = sys.argv[1:3]
    
    try:
        # Read input notification
        with open(input_file, "r") as f:
            input_data = f.read()
        
        # Process notification
        output_data = process_notification(input_data)
        
        # Write to output file
        with open(output_file, "w") as f:
            f.write(output_data)
            
    except Exception:
        sys.exit(1)

if __name__ == "__main__":
    main()
