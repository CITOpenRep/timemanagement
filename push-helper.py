#!/usr/bin/python3
# -*- coding: utf-8 -*-
"""
Push helper for TimeManagement app.
Handles incoming push notifications and formats them for display.
"""

import sys
import json
import os
import sqlite3
from pathlib import Path
from datetime import datetime, timezone

# Database path for storing notifications
DB_DIR = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local" / "share" / "ubtms")) / "Databases"

def get_db_path():
    """Get the path to the app database."""
    if DB_DIR.exists():
        db_files = list(DB_DIR.glob("*.sqlite"))
        if db_files:
            return str(max(db_files, key=lambda p: p.stat().st_mtime))
    base_dir = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local" / "share" / "ubtms"))
    return str(base_dir / "timemanagement.db")

def store_notification(notif_type, message, payload):
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
        
        # Insert notification (account_id = 0 for push notifications)
        now_str = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        cursor.execute("""
            INSERT INTO notification (account_id, timestamp, message, type, payload, read_status, panel_invoked)
            VALUES (?, ?, ?, ?, ?, 0, 1)
        """, (0, now_str, message, notif_type, json.dumps(payload)))
        
        conn.commit()
        conn.close()
    except Exception:
        pass  # Silent failure - notification display is more important

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
    """
    if not record_id or record_id <= 0:
        return False

    extra = extra_data if isinstance(extra_data, dict) else {}
    target_type = str(extra.get("model") or notif_type).lower()
    if "update" in target_type:
        model = "project.update"
    elif "activity" in target_type:
        model = "mail.activity"
    elif "project" in target_type and "task" not in target_type:
        model = "project.project"
    else:
        model = "project.task"

    try:
        db_path = get_db_path()
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()

        # Resolve remote account ID
        account_id = extra.get("account_id")
        if not account_id or int(account_id) <= 0:
            cursor.execute("SELECT id FROM users WHERE is_default = 1 AND id > 0 LIMIT 1")
            row = cursor.fetchone()
            if not row:
                cursor.execute("SELECT id FROM users WHERE id > 0 ORDER BY id ASC LIMIT 1")
                row = cursor.fetchone()
            account_id = int(row[0]) if row else 1
        else:
            account_id = int(account_id)

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

            user_id = extra.get("user_id")
            if isinstance(user_id, (list, tuple)) and len(user_id) > 0:
                user_id = user_id[0]
            user_name = extra.get("assignee_name") or extra.get("user_name")
            if not user_name and isinstance(extra.get("user_id"), (list, tuple)) and len(extra.get("user_id")) > 1:
                user_name = extra.get("user_id")[1]

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
                if user_id and "user_id" in task_cols:
                    update_fields.append("user_id = ?")
                    params.append(int(user_id))
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
                if "description" in task_cols:
                    ins_cols.append("description")
                    ins_vals.append(task_desc)
                if "user_id" in task_cols:
                    ins_cols.append("user_id")
                    ins_vals.append(int(user_id) if user_id else None)
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

            # Ensure project placeholder exists
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

                if project_id:
                    update_fields.append("project_id = ?")
                    params.append(int(project_id))
                if update_date:
                    update_fields.append("date = ?")
                    params.append(str(update_date))
                if user_id:
                    update_fields.append("user_id = ?")
                    params.append(int(user_id))

                params.extend([record_id, account_id])
                sql = f"UPDATE project_update_app SET {', '.join(update_fields)} WHERE odoo_record_id = ? AND account_id = ?"
                cursor.execute(sql, params)
            else:
                cursor.execute("""
                    INSERT INTO project_update_app (
                        account_id, name, project_status, progress, user_id,
                        description, date, project_id, odoo_record_id, last_modified,
                        status, has_draft
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, '', 0)
                """, (
                    account_id,
                    update_name,
                    status_val,
                    progress_val,
                    int(user_id) if user_id else None,
                    update_desc,
                    str(update_date),
                    int(project_id) if project_id else -1,
                    record_id,
                    now_str
                ))

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

                if start_date:
                    update_fields.append("planned_start_date = ?")
                    params.append(str(start_date))
                if end_date:
                    update_fields.append("planned_end_date = ?")
                    params.append(str(end_date))
                if allocated_hours > 0:
                    update_fields.append("allocated_hours = ?")
                    params.append(allocated_hours)
                if user_id:
                    update_fields.append("user_id = ?")
                    params.append(int(user_id))

                params.extend([record_id, account_id])
                sql = f"UPDATE project_project_app SET {', '.join(update_fields)} WHERE odoo_record_id = ? AND account_id = ?"
                cursor.execute(sql, params)
            else:
                cursor.execute("""
                    INSERT INTO project_project_app (
                        name, account_id, planned_start_date, planned_end_date,
                        allocated_hours, description, last_modified, user_id, status, has_draft, odoo_record_id
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, '', 0, ?)
                """, (
                    proj_name,
                    account_id,
                    str(start_date) if start_date else None,
                    str(end_date) if end_date else None,
                    allocated_hours,
                    proj_desc,
                    now_str,
                    int(user_id) if user_id else None,
                    record_id
                ))

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
            due_date = extra.get("due_date") or extra.get("date_deadline")
            user_id = extra.get("user_id")
            if isinstance(user_id, (list, tuple)) and len(user_id) > 0:
                user_id = user_id[0]
            res_id = extra.get("res_id") or extra.get("resId")
            res_model = extra.get("res_model") or extra.get("resModel")

            if existing:
                local_id, has_draft = existing
                update_fields = ["last_modified = ?"]
                params = [now_str]

                if not has_draft:
                    update_fields.append("summary = ?")
                    params.append(act_summary)
                    if act_notes:
                        update_fields.append("notes = ?")
                        params.append(act_notes)
                if due_date:
                    update_fields.append("due_date = ?")
                    params.append(str(due_date))

                params.extend([record_id, account_id])
                sql = f"UPDATE mail_activity_app SET {', '.join(update_fields)} WHERE odoo_record_id = ? AND account_id = ?"
                cursor.execute(sql, params)
            else:
                cursor.execute("""
                    INSERT INTO mail_activity_app (
                        account_id, activity_type_id, summary, due_date, user_id,
                        notes, odoo_record_id, last_modified, resId, resModel, state, status, has_draft
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'today', '', 0)
                """, (
                    account_id,
                    int(act_type_id) if act_type_id else 1,
                    act_summary,
                    str(due_date) if due_date else None,
                    int(user_id) if user_id else None,
                    act_notes,
                    record_id,
                    now_str,
                    int(res_id) if res_id else None,
                    str(res_model) if res_model else ""
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
        
        # Determine notification type from summary
        notif_type = "Task"  # Default
        if "Activity" in summary:
            notif_type = "Activity"
        elif "Update" in summary:
            notif_type = "ProjectUpdate"
        elif "Project" in summary:
            notif_type = "Project"
        elif "Timesheet" in summary:
            notif_type = "Timesheet"

        # Check priority / urgency
        is_urgent = bool(
            card.get("urgent") or
            card.get("priority") in ("3", 3, "high", "urgent") or
            "urgent" in summary.lower() or
            "urgent" in body.lower()
        )

        # Extract record ID from actions query string or payload
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

        if not record_id:
            record_id = card.get("record_id") or card.get("id") or notif.get("data", {}).get("res_id")

        # Ensure app logo avatar is present
        if not card.get("icon"):
            card["icon"] = "assets/logo.png"

        # Ensure card defaults for proper banner display respecting working hours and priority
        card["popup"] = card.get("popup", True) and should_popup_notification(summary, body, is_urgent)
        card["persist"] = card.get("persist", True)

        # Build actions: exactly 1 action for standard interactive banner dispatch
        enhanced_actions = []
        if record_id:
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
            # Sound alert (path relative to XDG_DATA_DIRS or app package)
            sound_val = notif.get("sound")
            if not sound_val or sound_val is True:
                notif["sound"] = "sounds/lomiri/notifications/Positive.ogg"
            else:
                notif["sound"] = str(sound_val)

            # Haptic tactile vibration pattern
            vibrate_val = notif.get("vibrate")
            if not vibrate_val or vibrate_val is True:
                notif["vibrate"] = {
                    "pattern": [200, 100, 200],
                    "repeat": 1
                }
            elif isinstance(vibrate_val, dict):
                notif["vibrate"] = vibrate_val
        else:
            # Suppress audio and vibration during quiet hours schedule
            notif.pop("sound", None)
            notif.pop("vibrate", None)

        # Store in database for in-app display with record ID
        store_payload = {
            "summary": summary,
            "source": "push",
            "type": notif_type
        }
        if record_id:
            store_payload["odoo_record_id"] = record_id
            store_payload["id"] = record_id
            store_payload["is_odoo_id"] = True

        store_notification(notif_type, body, store_payload)

        # Pre-populate record in local SQLite database (Option 1)
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
