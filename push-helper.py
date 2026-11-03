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
