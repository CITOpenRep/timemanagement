#!/usr/bin/python3
# -*- coding: utf-8 -*-
"""
Push helper for TimeManagement app.
Handles incoming push notifications and formats them for display.
"""

import sys
import json
import sqlite3
from pathlib import Path
from datetime import datetime

# Database path for storing notifications
DB_DIR = Path.home() / ".local" / "share" / "ubtms" / "Databases"

def get_db_path():
    """Get the path to the app database."""
    if DB_DIR.exists():
        db_files = list(DB_DIR.glob("*.sqlite"))
        if db_files:
            return str(max(db_files, key=lambda p: p.stat().st_mtime))
    return str(Path.home() / ".local" / "share" / "ubtms" / "timemanagement.db")

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
                type TEXT CHECK(type IN ('Activity', 'Task', 'Project', 'Timesheet', 'Sync')),
                payload TEXT NOT NULL,
                read_status INTEGER DEFAULT 0
            )
        """)
        
        # Insert notification (account_id = 0 for push notifications)
        cursor.execute("""
            INSERT INTO notification (account_id, timestamp, message, type, payload, read_status)
            VALUES (?, ?, ?, ?, ?, 0)
        """, (0, datetime.utcnow().isoformat() + "Z", message, notif_type, json.dumps(payload)))
        
        conn.commit()
        conn.close()
    except Exception:
        pass  # Silent failure - notification display is more important

def process_notification(input_data):
    """Process incoming notification and enhance if needed."""
    try:
        notification = json.loads(input_data)
        
        # Extract notification details
        notif = notification.get("notification", {})
        card = notif.get("card", {})
        summary = card.get("summary", "")
        body = card.get("body", "")
        
        # Determine notification type from summary
        notif_type = "Task"  # Default
        if "Activity" in summary:
            notif_type = "Activity"
        elif "Project" in summary:
            notif_type = "Project"
        elif "Timesheet" in summary:
            notif_type = "Timesheet"
        
        # Store in database for in-app display
        store_notification(notif_type, body, {"summary": summary, "source": "push"})
        
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
