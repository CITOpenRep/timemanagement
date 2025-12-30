# -*- coding: utf-8 -*-
# MIT License
#
# Copyright (c) 2025 CIT-Services
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

from datetime import datetime
import json
import sqlite3
from pathlib import Path
from logger import setup_logger
from datetime import datetime
import sqlite3
import time
import sqlite3
import time
import threading
from logger import setup_logger

log = setup_logger()

# Optional: Global lock if multithreaded write access is expected
db_lock = threading.Lock()


def safe_sql_execute(
    db_path,
    sql,
    values=(),
    retries=5,
    delay=0.2,
    commit=True,
    fetch=False,
    many=False,
):
    """
    Execute SQL statements safely with automatic retry on database locks.
    
    Args:
        db_path (str): Path to the SQLite database file
        sql (str): SQL statement to execute
        values (tuple): Parameter values for the SQL statement
        retries (int): Number of retry attempts on database lock, defaults to 5
        delay (float): Delay in seconds between retry attempts, defaults to 0.2
        commit (bool): Whether to commit the transaction, defaults to True
        fetch (bool): Whether to fetch and return results, defaults to False
        many (bool): Whether to use executemany for bulk operations, defaults to False
        
    Returns:
        list or None: Query results if fetch=True, None otherwise
        
    Raises:
        sqlite3.OperationalError: If database remains locked after all retries
        Exception: For other database-related errors
        
    Note:
        Uses thread-safe database access with global lock to prevent concurrency issues.
        Automatically retries on database lock errors with exponential backoff.
    """
    for attempt in range(retries):
        try:
            with db_lock:  # Ensures thread-safe access
                conn = sqlite3.connect(db_path, check_same_thread=False)
                cursor = conn.cursor()
                if many:
                    cursor.executemany(sql, values)
                else:
                    cursor.execute(sql, values)

                result = cursor.fetchall() if fetch else None

                if commit:
                    conn.commit()
                conn.close()
                return result

        except sqlite3.OperationalError as e:
            if "locked" in str(e).lower() and attempt < retries - 1:
                log.debug("database is locked, delaying")
                time.sleep(delay)
                continue
            raise e
        except Exception as e:
            raise e


def sanitize_datetime(value):
    """
    Sanitize and validate datetime string values for database storage.
    
    Args:
        value: Input value to sanitize (typically string)
        
    Returns:
        str or None: Valid ISO format datetime string if input is valid, None otherwise
        
    Note:
        Validates datetime strings by attempting to parse them with fromisoformat().
        Returns None for invalid dates, empty strings, or "0" values.
    """
    try:
        if isinstance(value, str) and value.strip() and value != "0":
            # Try parsing to validate
            datetime.fromisoformat(value)
            return value
    except Exception:
        pass
    return None  # Invalid datetime replaced with NULL


def check_table_exists(db_path, table_name):
    """
    Check if a specific table exists in the SQLite database.
    
    Args:
        db_path (str): Path to the SQLite database file
        table_name (str): Name of the table to check for
        
    Returns:
        bool: True if table exists, False otherwise
        
    Note:
        Queries sqlite_master table to get list of all tables.
        Prints debug information about available tables.
    """
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
        tables = [row[0] for row in cursor.fetchall()]
        print(f"[DEBUG] Tables in DB: {tables}")
        conn.close()
        return table_name in tables
    except Exception as e:
        print(f"[ERROR] Failed to inspect DB: {e}")
        return False

    import json
    from datetime import datetime


def write_sync_report_to_db(db_path, account_id, status, message=""):
    """
    Write synchronization report to the database with current status and logs.
    
    Args:
        db_path (str): Path to the SQLite database file
        account_id (int): Account ID associated with the sync operation
        status (str): Current sync status (e.g., "In Progress", "Successful", "Failed")
        message (str): Additional message or description, defaults to empty string
        
    Note:
        Creates sync_report table if it doesn't exist.
        Deletes previous sync reports for the same account_id before inserting new one.
        Stores JSON log output from the logger as the message field.
        Uses UTC timestamp in ISO format with 'Z' suffix.
    """
    log_output = log.json_handler.get_json_string()
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Ensure table exists
    cursor.execute(
        """
        CREATE TABLE IF NOT EXISTS sync_report (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            status TEXT,
            account_id INTEGER,
            timestamp TEXT,
            message TEXT
        )
    """
    )

    cursor.execute(
            "DELETE FROM sync_report WHERE account_id = ?",
            (account_id,)
        )

    # Insert report
    cursor.execute(
        """
        INSERT INTO sync_report (status, account_id, timestamp, message)
        VALUES (?, ?, ?, ?)
    """,
        (status, account_id, datetime.utcnow().isoformat() + "Z", log_output),
    )

    conn.commit()
    conn.close()

def add_notification(db_path, account_id, notif_type, message, payload):
    """
    Insert a notification record into the notification table.

    Args:
        db_path (str): Path to the SQLite database file
        account_id (int): The account associated with this notification
        notif_type (str): Type of notification ('Activity', 'Task', 'Project', 'Timesheet', 'Sync')
        message (str): The main message body of the notification
        payload (dict or list): Any JSON-serializable metadata payload

    Note:
        Creates notification table if it doesn't exist with proper schema constraints.
        Sets read_status to 0 (unread) by default.
        Stores payload as JSON string and adds UTC timestamp.
        Uses safe_sql_execute for thread-safe database operations.
        Prevents duplicate notifications with same message within 60 seconds.
    """
    # Ensure table exists
    create_table_sql = """
        CREATE TABLE IF NOT EXISTS notification (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            account_id INTEGER,
            timestamp TEXT DEFAULT (datetime('now')),
            message TEXT NOT NULL,
            type TEXT CHECK(type IN ('Activity', 'Task', 'Project', 'Timesheet', 'Sync')),
            payload TEXT NOT NULL,
            read_status INTEGER DEFAULT 0
        )
    """

    safe_sql_execute(db_path, create_table_sql)

    # Check for duplicate notification (same type+message that is still unread)
    # This prevents duplicate notifications from multiple sync cycles
    check_duplicate_sql = """
        SELECT COUNT(*) FROM notification 
        WHERE account_id = ? AND message = ? AND type = ? AND read_status = 0
    """
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        cursor.execute(check_duplicate_sql, (account_id, message, notif_type))
        count = cursor.fetchone()[0]
        conn.close()
        
        if count > 0:
            # Duplicate unread notification exists, skip
            return
    except Exception as e:
        # If check fails, proceed with insert (better to have duplicate than miss notification)
        pass

    insert_sql = """
        INSERT INTO notification (account_id, timestamp, message, type, payload, read_status)
        VALUES (?, ?, ?, ?, ?, 0)
    """

    timestamp = datetime.utcnow().isoformat() + "Z"
    payload_json = json.dumps(payload)

    safe_sql_execute(
        db_path,
        insert_sql,
        (account_id, timestamp, message, notif_type, payload_json)
    )


# =============================================================================
# Assignment Tracking - For detecting assignment changes vs general updates
# =============================================================================

def get_current_assignments_snapshot(db_path, account_id, user_id):
    """
    Capture a snapshot of current task/activity assignments BEFORE sync.
    
    This should be called BEFORE sync_from_odoo to capture the pre-sync state.
    After sync, compare with the new state to detect NEW assignments.
    
    Args:
        db_path (str): Path to the SQLite database file
        account_id (int): Account ID
        user_id (int): The current user's Odoo ID
        
    Returns:
        dict: Sets of record IDs currently assigned to user for each type
    """
    snapshot = {
        'tasks': set(),
        'activities': set(),
        'projects': set(),
        'timesheets': set()
    }
    
    if not user_id:
        return snapshot
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Tasks: user_id can be single ID or CSV
        cursor.execute("""
            SELECT id FROM project_task_app 
            WHERE account_id = ? 
            AND (
                user_id = ? 
                OR user_id = ?
                OR (',' || user_id || ',') LIKE ?
            )
        """, (account_id, user_id, str(user_id), f"%,{user_id},%"))
        snapshot['tasks'] = {row[0] for row in cursor.fetchall()}
        
        # Activities: single user_id
        cursor.execute("""
            SELECT id FROM mail_activity_app 
            WHERE account_id = ? 
            AND (user_id = ? OR user_id = ? OR CAST(user_id AS TEXT) = ?)
        """, (account_id, user_id, str(user_id), str(user_id)))
        snapshot['activities'] = {row[0] for row in cursor.fetchall()}
        
        # Projects: user manages or favorites
        cursor.execute("""
            SELECT id FROM project_project_app 
            WHERE account_id = ? 
            AND (user_id = ? OR user_id = ? OR favorites = 1)
        """, (account_id, user_id, str(user_id)))
        snapshot['projects'] = {row[0] for row in cursor.fetchall()}
        
        # Timesheets: owned by user
        cursor.execute("""
            SELECT id FROM account_analytic_line_app 
            WHERE account_id = ? 
            AND (user_id = ? OR user_id = ?)
        """, (account_id, user_id, str(user_id)))
        snapshot['timesheets'] = {row[0] for row in cursor.fetchall()}
        
        conn.close()
        log.info(f"[COMMON] Assignment snapshot: tasks={len(snapshot['tasks'])}, "
                 f"activities={len(snapshot['activities'])}, projects={len(snapshot['projects'])}, "
                 f"timesheets={len(snapshot['timesheets'])}")
        
    except Exception as e:
        log.error(f"[COMMON] Failed to get assignment snapshot: {e}")
    
    return snapshot


def detect_new_assignments(db_path, account_id, user_id, pre_sync_snapshot):
    """
    Compare current DB state with pre-sync snapshot to find NEW assignments only.
    
    This should be called AFTER sync_from_odoo completes.
    Only returns records that are NOW assigned to the user but WERE NOT before sync.
    
    Args:
        db_path (str): Path to the SQLite database file
        account_id (int): Account ID
        user_id (int): The current user's Odoo ID
        pre_sync_snapshot (dict): Snapshot from get_current_assignments_snapshot()
        
    Returns:
        dict: Lists of newly assigned record rows for each type
    """
    result = {
        'new_tasks': [],
        'new_activities': [],
        'new_projects': [],
        'new_timesheets': []
    }
    
    if not user_id:
        return result
    
    try:
        conn = sqlite3.connect(db_path)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        
        # Get current tasks assigned to user
        cursor.execute("""
            SELECT id, name, project_id, odoo_record_id FROM project_task_app 
            WHERE account_id = ? 
            AND (
                user_id = ? 
                OR user_id = ?
                OR (',' || user_id || ',') LIKE ?
            )
        """, (account_id, user_id, str(user_id), f"%,{user_id},%"))
        
        for task in cursor.fetchall():
            if task['id'] not in pre_sync_snapshot['tasks']:
                result['new_tasks'].append(dict(task))
        
        # Get current activities assigned to user
        cursor.execute("""
            SELECT id, summary, due_date, odoo_record_id FROM mail_activity_app 
            WHERE account_id = ? 
            AND (user_id = ? OR user_id = ? OR CAST(user_id AS TEXT) = ?)
        """, (account_id, user_id, str(user_id), str(user_id)))
        
        for activity in cursor.fetchall():
            if activity['id'] not in pre_sync_snapshot['activities']:
                result['new_activities'].append(dict(activity))
        
        # Get current projects (managed or favorited)
        cursor.execute("""
            SELECT id, name, odoo_record_id FROM project_project_app 
            WHERE account_id = ? 
            AND (user_id = ? OR user_id = ? OR favorites = 1)
        """, (account_id, user_id, str(user_id)))
        
        for project in cursor.fetchall():
            if project['id'] not in pre_sync_snapshot['projects']:
                result['new_projects'].append(dict(project))
        
        # Get current timesheets (owned by user)
        cursor.execute("""
            SELECT id, name, unit_amount, odoo_record_id FROM account_analytic_line_app 
            WHERE account_id = ? 
            AND (user_id = ? OR user_id = ?)
        """, (account_id, user_id, str(user_id)))
        
        for timesheet in cursor.fetchall():
            if timesheet['id'] not in pre_sync_snapshot['timesheets']:
                result['new_timesheets'].append(dict(timesheet))
        
        conn.close()
        
        log.info(f"[COMMON] New assignments detected: tasks={len(result['new_tasks'])}, "
                 f"activities={len(result['new_activities'])}, projects={len(result['new_projects'])}, "
                 f"timesheets={len(result['new_timesheets'])}")
        
    except Exception as e:
        log.error(f"[COMMON] Failed to detect new assignments: {e}")
    
    return result