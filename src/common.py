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
import time
import threading
import base64
import os
from pathlib import Path
from logger import setup_logger

log = setup_logger()

# Avatar cache directory
AVATAR_CACHE_DIR = Path.home() / ".cache" / "ubtms" / "avatars"

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


def get_user_info_by_odoo_id(db_path, account_id, odoo_user_id):
    """
    Look up user information (name, avatar) by their Odoo user ID.

    Args:
        db_path (str): Path to the SQLite database file
        account_id (int): The account ID
        odoo_user_id (int or str): The Odoo user ID (odoo_record_id in res_users_app)

    Returns:
        dict: User info with keys 'name', 'avatar_128', 'avatar_path', 'odoo_record_id', or None if not found
              avatar_path is the file path to the cached avatar image (for system notifications)
    """
    if not odoo_user_id:
        return None
    
    try:
        conn = sqlite3.connect(db_path)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT name, avatar_128, odoo_record_id, login, job_title 
            FROM res_users_app 
            WHERE account_id = ? AND odoo_record_id = ?
        """, (account_id, int(odoo_user_id)))
        
        row = cursor.fetchone()
        conn.close()
        
        if row:
            avatar_path = None
            avatar_128 = row['avatar_128']
            
            # If avatar exists, save to cache and get file path
            if avatar_128:
                avatar_path = save_avatar_to_cache(account_id, row['odoo_record_id'], avatar_128)
            
            return {
                'name': row['name'],
                'avatar_128': avatar_128,
                'avatar_path': avatar_path,
                'odoo_record_id': row['odoo_record_id'],
                'login': row['login'],
                'job_title': row['job_title']
            }
        return None
    except Exception as e:
        log.warning(f"[COMMON] Failed to get user info for odoo_id={odoo_user_id}: {e}")
        return None


def save_avatar_to_cache(account_id, user_id, avatar_base64):
    """
    Save a base64-encoded avatar image to the cache directory.
    
    Args:
        account_id (int): The account ID
        user_id (int): The user's Odoo record ID
        avatar_base64 (str): Base64-encoded image data
        
    Returns:
        str: File path to the saved avatar, or None on error
    """
    if not avatar_base64:
        return None
    
    try:
        # Ensure cache directory exists
        AVATAR_CACHE_DIR.mkdir(parents=True, exist_ok=True)
        
        # Create unique filename based on account and user
        filename = f"avatar_{account_id}_{user_id}.png"
        filepath = AVATAR_CACHE_DIR / filename
        
        # Decode and save the image
        image_data = base64.b64decode(avatar_base64)
        with open(filepath, 'wb') as f:
            f.write(image_data)
        
        return str(filepath)
    except Exception as e:
        log.warning(f"[COMMON] Failed to save avatar to cache: {e}")
        return None


def get_cached_avatar_path(account_id, user_id):
    """
    Get the path to a cached avatar if it exists.
    
    Args:
        account_id (int): The account ID
        user_id (int): The user's Odoo record ID
        
    Returns:
        str: File path to the cached avatar, or None if not cached
    """
    try:
        filename = f"avatar_{account_id}_{user_id}.png"
        filepath = AVATAR_CACHE_DIR / filename
        
        if filepath.exists():
            return str(filepath)
        return None
    except Exception as e:
        return None


# =============================================================================
# Assignment Tracking - For detecting assignment changes vs general updates
# =============================================================================

def get_current_assignments_snapshot(db_path, account_id, user_id):
    """
    Capture a snapshot of current task/activity assignments BEFORE sync.
    
    This should be called BEFORE sync_from_odoo to capture the pre-sync state.
    After sync, compare with the new state to detect NEW assignments.
    
    IMPORTANT: We use odoo_record_id (not local id) because INSERT OR REPLACE
    changes the local auto-increment id on every sync, but odoo_record_id is stable.
    
    Args:
        db_path (str): Path to the SQLite database file
        account_id (int): Account ID
        user_id (int): The current user's Odoo ID
        
    Returns:
        dict: Sets of odoo_record_ids currently assigned to user for each type
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
        # Use odoo_record_id for stable comparison across syncs
        cursor.execute("""
            SELECT odoo_record_id FROM project_task_app 
            WHERE account_id = ? 
            AND odoo_record_id IS NOT NULL
            AND (
                user_id = ? 
                OR user_id = ?
                OR (',' || user_id || ',') LIKE ?
            )
        """, (account_id, user_id, str(user_id), f"%,{user_id},%"))
        snapshot['tasks'] = {row[0] for row in cursor.fetchall() if row[0]}
        
        # Activities: single user_id
        cursor.execute("""
            SELECT odoo_record_id FROM mail_activity_app 
            WHERE account_id = ? 
            AND odoo_record_id IS NOT NULL
            AND (user_id = ? OR user_id = ? OR CAST(user_id AS TEXT) = ?)
        """, (account_id, user_id, str(user_id), str(user_id)))
        snapshot['activities'] = {row[0] for row in cursor.fetchall() if row[0]}
        
        # Projects: user manages or favorites
        cursor.execute("""
            SELECT odoo_record_id FROM project_project_app 
            WHERE account_id = ? 
            AND odoo_record_id IS NOT NULL
            AND (user_id = ? OR user_id = ? OR favorites = 1)
        """, (account_id, user_id, str(user_id)))
        snapshot['projects'] = {row[0] for row in cursor.fetchall() if row[0]}
        
        # Timesheets: owned by user
        cursor.execute("""
            SELECT odoo_record_id FROM account_analytic_line_app 
            WHERE account_id = ? 
            AND odoo_record_id IS NOT NULL
            AND (user_id = ? OR user_id = ?)
        """, (account_id, user_id, str(user_id)))
        snapshot['timesheets'] = {row[0] for row in cursor.fetchall() if row[0]}
        
        conn.close()
        log.info(f"[COMMON] Assignment snapshot (by odoo_record_id): tasks={len(snapshot['tasks'])}, "
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
    
    IMPORTANT: Compares by odoo_record_id (not local id) since INSERT OR REPLACE
    changes local id on every sync, but odoo_record_id is stable.
    
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
        
        # Get current tasks assigned to user - compare by odoo_record_id
        cursor.execute("""
            SELECT id, name, project_id, odoo_record_id, create_uid FROM project_task_app 
            WHERE account_id = ? 
            AND odoo_record_id IS NOT NULL
            AND (
                user_id = ? 
                OR user_id = ?
                OR (',' || user_id || ',') LIKE ?
            )
        """, (account_id, user_id, str(user_id), f"%,{user_id},%"))
        
        for task in cursor.fetchall():
            odoo_id = task['odoo_record_id']
            if odoo_id and odoo_id not in pre_sync_snapshot['tasks']:
                result['new_tasks'].append(dict(task))
        
        # Get current activities assigned to user
        cursor.execute("""
            SELECT id, summary, due_date, odoo_record_id, create_uid FROM mail_activity_app 
            WHERE account_id = ? 
            AND odoo_record_id IS NOT NULL
            AND (user_id = ? OR user_id = ? OR CAST(user_id AS TEXT) = ?)
        """, (account_id, user_id, str(user_id), str(user_id)))
        
        for activity in cursor.fetchall():
            odoo_id = activity['odoo_record_id']
            if odoo_id and odoo_id not in pre_sync_snapshot['activities']:
                result['new_activities'].append(dict(activity))
        
        # Get current projects (managed or favorited)
        cursor.execute("""
            SELECT id, name, odoo_record_id FROM project_project_app 
            WHERE account_id = ? 
            AND odoo_record_id IS NOT NULL
            AND (user_id = ? OR user_id = ? OR favorites = 1)
        """, (account_id, user_id, str(user_id)))
        
        for project in cursor.fetchall():
            odoo_id = project['odoo_record_id']
            if odoo_id and odoo_id not in pre_sync_snapshot['projects']:
                result['new_projects'].append(dict(project))
        
        # Get current timesheets (owned by user)
        cursor.execute("""
            SELECT id, name, unit_amount, odoo_record_id FROM account_analytic_line_app 
            WHERE account_id = ? 
            AND odoo_record_id IS NOT NULL
            AND (user_id = ? OR user_id = ?)
        """, (account_id, user_id, str(user_id)))
        
        for timesheet in cursor.fetchall():
            odoo_id = timesheet['odoo_record_id']
            if odoo_id and odoo_id not in pre_sync_snapshot['timesheets']:
                result['new_timesheets'].append(dict(timesheet))
        
        conn.close()
        
        log.info(f"[COMMON] New assignments detected (by odoo_record_id): tasks={len(result['new_tasks'])}, "
                 f"activities={len(result['new_activities'])}, projects={len(result['new_projects'])}, "
                 f"timesheets={len(result['new_timesheets'])}")
        
    except Exception as e:
        log.error(f"[COMMON] Failed to detect new assignments: {e}")
    
    return result


# =============================================================================
# TIMEZONE AND NOTIFICATION SCHEDULE UTILITIES
# =============================================================================

def get_available_timezones():
    """
    Get a list of common timezones for user selection.
    
    Returns:
        list: List of timezone strings (e.g., "America/New_York", "Europe/London")
    """
    # Common timezones organized by region
    common_timezones = [
        # UTC
        "UTC",
        # Americas
        "America/New_York",
        "America/Chicago",
        "America/Denver",
        "America/Los_Angeles",
        "America/Toronto",
        "America/Vancouver",
        "America/Mexico_City",
        "America/Sao_Paulo",
        "America/Buenos_Aires",
        # Europe
        "Europe/London",
        "Europe/Paris",
        "Europe/Berlin",
        "Europe/Madrid",
        "Europe/Rome",
        "Europe/Amsterdam",
        "Europe/Brussels",
        "Europe/Vienna",
        "Europe/Warsaw",
        "Europe/Moscow",
        # Asia
        "Asia/Dubai",
        "Asia/Kolkata",
        "Asia/Mumbai",
        "Asia/Bangkok",
        "Asia/Singapore",
        "Asia/Hong_Kong",
        "Asia/Shanghai",
        "Asia/Tokyo",
        "Asia/Seoul",
        "Asia/Jakarta",
        # Oceania
        "Australia/Sydney",
        "Australia/Melbourne",
        "Australia/Perth",
        "Pacific/Auckland",
        # Africa
        "Africa/Cairo",
        "Africa/Johannesburg",
        "Africa/Lagos",
        "Africa/Nairobi",
    ]
    return common_timezones


def get_system_timezone():
    """
    Get the system's current timezone.
    
    Returns:
        str: Timezone name (e.g., "America/New_York") or "UTC" if detection fails
    """
    import os
    import subprocess
    
    try:
        # Primary method: Use timedatectl (most reliable on Ubuntu Touch/Linux)
        # This correctly detects the timezone even when /etc/timezone is wrong
        try:
            result = subprocess.run(
                ['timedatectl', 'show', '--value', '-p', 'Timezone'],
                capture_output=True, text=True, timeout=5
            )
            if result.returncode == 0 and result.stdout.strip():
                tz = result.stdout.strip()
                if tz and tz != "n/a":
                    log.debug(f"[COMMON] Timezone from timedatectl: {tz}")
                    return tz
        except (FileNotFoundError, subprocess.TimeoutExpired):
            pass  # timedatectl not available, try other methods
        
        # Secondary: Try to read from /etc/localtime symlink
        if os.path.islink('/etc/localtime'):
            link_target = os.readlink('/etc/localtime')
            # Extract timezone from path like /usr/share/zoneinfo/America/New_York
            if 'zoneinfo' in link_target:
                parts = link_target.split('zoneinfo/')
                if len(parts) > 1:
                    return parts[1]
        
        # Tertiary: Try to read from /etc/timezone (may be outdated on Ubuntu Touch)
        if os.path.exists('/etc/timezone'):
            with open('/etc/timezone', 'r') as f:
                tz = f.read().strip()
                # Skip if it's just "Etc/UTC" as this is often a default/wrong value
                if tz and tz not in ("Etc/UTC", "UTC"):
                    return tz
        
        # Fallback: try using Python's time module
        import time
        tz_name = time.tzname[0]
        if tz_name:
            return tz_name
            
    except Exception as e:
        log.warning(f"[COMMON] Failed to detect system timezone: {e}")
    
    return "UTC"


def get_current_time_in_timezone(timezone_str):
    """
    Get the current time in a specific timezone.
    
    Args:
        timezone_str: Timezone string (e.g., "America/New_York", "Europe/London")
        
    Returns:
        datetime: Current time in the specified timezone, or UTC if timezone is invalid
    """
    from datetime import timezone as tz
    
    try:
        # Try using zoneinfo (Python 3.9+)
        try:
            from zoneinfo import ZoneInfo
            now = datetime.now(ZoneInfo(timezone_str))
            return now
        except ImportError:
            pass
        
        # Fallback: try using pytz if available
        try:
            import pytz
            tz_obj = pytz.timezone(timezone_str)
            now = datetime.now(tz_obj)
            return now
        except ImportError:
            pass
        
        # Last fallback: use UTC
        log.warning(f"[COMMON] No timezone library available, using UTC")
        return datetime.now(tz.utc)
        
    except Exception as e:
        log.error(f"[COMMON] Failed to get time in timezone {timezone_str}: {e}")
        return datetime.now(tz.utc)


def parse_time_string(time_str):
    """
    Parse a time string in HH:MM format to hours and minutes.
    
    Args:
        time_str: Time string in "HH:MM" format
        
    Returns:
        tuple: (hour, minute) as integers, or (0, 0) if parsing fails
    """
    try:
        parts = time_str.strip().split(':')
        if len(parts) >= 2:
            hour = int(parts[0])
            minute = int(parts[1])
            # Validate ranges
            if 0 <= hour <= 23 and 0 <= minute <= 59:
                return (hour, minute)
    except Exception as e:
        log.warning(f"[COMMON] Failed to parse time string '{time_str}': {e}")
    
    return (0, 0)


def is_within_active_hours(timezone_str, active_start, active_end):
    """
    Check if the current time is within the user's active notification hours.
    
    This function supports schedules that wrap around midnight.
    For example, active_start="22:00" and active_end="06:00" means 
    notifications are allowed from 10 PM to 6 AM.
    
    Args:
        timezone_str: User's timezone (e.g., "America/New_York") or empty for system default
        active_start: Start time of active hours in "HH:MM" format
        active_end: End time of active hours in "HH:MM" format
        
    Returns:
        bool: True if current time is within active hours, False otherwise
    """
    try:
        # Get effective timezone
        effective_tz = timezone_str if timezone_str else get_system_timezone()
        
        # Get current time in user's timezone
        current_time = get_current_time_in_timezone(effective_tz)
        current_hour = current_time.hour
        current_minute = current_time.minute
        
        # Parse start and end times
        start_hour, start_minute = parse_time_string(active_start)
        end_hour, end_minute = parse_time_string(active_end)
        
        # Convert to minutes since midnight for easier comparison
        current_mins = current_hour * 60 + current_minute
        start_mins = start_hour * 60 + start_minute
        end_mins = end_hour * 60 + end_minute
        
        # Handle normal case (start < end) and overnight case (start > end)
        if start_mins <= end_mins:
            # Normal case: e.g., 09:00 to 18:00
            is_active = start_mins <= current_mins <= end_mins
        else:
            # Overnight case: e.g., 22:00 to 06:00
            # Active if current time is after start OR before end
            is_active = current_mins >= start_mins or current_mins <= end_mins
        
        log.debug(f"[COMMON] Active hours check: tz={effective_tz}, current={current_hour:02d}:{current_minute:02d}, "
                  f"range={active_start}-{active_end}, is_active={is_active}")
        
        return is_active
        
    except Exception as e:
        log.error(f"[COMMON] Failed to check active hours: {e}")
        # On error, default to allowing notifications
        return True


def get_notification_schedule_settings(db_path):
    """
    Get all notification schedule settings from the database.
    
    Args:
        db_path: Path to the SQLite database
        
    Returns:
        dict: Settings with keys:
            - notifications_enabled (bool): Master notification toggle
            - schedule_enabled (bool): Whether notification scheduling is enabled
            - timezone (str): User's preferred timezone
            - active_start (str): Start of active hours in HH:MM format
            - active_end (str): End of active hours in HH:MM format
            - working_days (list[int]): List of working day numbers (0=Sun,1=Mon,...,6=Sat)
    """
    from config import get_setting, DEFAULT_SETTINGS
    
    try:
        notifications_enabled = get_setting(db_path, "notifications_enabled",
                                            DEFAULT_SETTINGS.get("notifications_enabled", "true"))
        schedule_enabled = get_setting(db_path, "notification_schedule_enabled", 
                                        DEFAULT_SETTINGS.get("notification_schedule_enabled", "false"))
        timezone = get_setting(db_path, "notification_timezone", 
                               DEFAULT_SETTINGS.get("notification_timezone", ""))
        active_start = get_setting(db_path, "notification_active_start", 
                                   DEFAULT_SETTINGS.get("notification_active_start", "09:00"))
        active_end = get_setting(db_path, "notification_active_end", 
                                 DEFAULT_SETTINGS.get("notification_active_end", "18:00"))
        working_days_str = get_setting(db_path, "notification_working_days",
                                       DEFAULT_SETTINGS.get("notification_working_days", "1,2,3,4,5"))
        
        # Parse working days CSV string to list of ints
        try:
            working_days = [int(d.strip()) for d in working_days_str.split(",") if d.strip()]
        except (ValueError, AttributeError):
            working_days = [1, 2, 3, 4, 5]  # Default Mon-Fri
        
        return {
            "notifications_enabled": notifications_enabled.lower() == "true",
            "schedule_enabled": schedule_enabled.lower() == "true",
            "timezone": timezone,
            "active_start": active_start,
            "active_end": active_end,
            "working_days": working_days
        }
    except Exception as e:
        log.error(f"[COMMON] Failed to get notification schedule settings: {e}")
        return {
            "notifications_enabled": True,
            "schedule_enabled": False,
            "timezone": "",
            "active_start": "09:00",
            "active_end": "18:00",
            "working_days": [1, 2, 3, 4, 5]
        }


def should_send_notification(db_path):
    """
    Determine if a notification should be sent based on current schedule settings.
    
    This is the main function that the daemon should call before sending any notification.
    It checks:
    1. Whether notifications are enabled (master toggle)
    2. If scheduling is enabled, whether the current day is a working day
    3. If scheduling is enabled, whether the current time falls within active hours
    
    Args:
        db_path: Path to the SQLite database
        
    Returns:
        tuple: (should_send: bool, reason: str)
            - should_send: True if notification should be sent
            - reason: Human-readable explanation for the decision
    """
    try:
        settings = get_notification_schedule_settings(db_path)
        
        # Check master notification toggle first
        if not settings["notifications_enabled"]:
            return (False, "Notifications are disabled by user")
        
        # If scheduling is disabled, always send notifications
        if not settings["schedule_enabled"]:
            return (True, "Notification scheduling is disabled")
        
        # Get effective timezone and current time for day-of-week check
        effective_tz = settings["timezone"] if settings["timezone"] else get_system_timezone()
        current_time = get_current_time_in_timezone(effective_tz)
        
        # Check if today is a working day
        # Python weekday(): Mon=0..Sun=6 -> We store as 0=Sun,1=Mon,...,6=Sat
        # Convert Python weekday to our format: (py_weekday + 1) % 7 maps Mon=1,Tue=2,...,Sun=0
        py_weekday = current_time.weekday()  # Mon=0, Tue=1, ..., Sun=6
        our_day = (py_weekday + 1) % 7       # Sun=0, Mon=1, ..., Sat=6
        
        if our_day not in settings["working_days"]:
            day_names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            working_day_names = [day_names[d] for d in sorted(settings["working_days"]) if 0 <= d <= 6]
            return (False, f"Today is {day_names[our_day]}, not a working day. "
                          f"Working days: {', '.join(working_day_names)}")
        
        # Check if current time is within active hours
        is_active = is_within_active_hours(
            settings["timezone"],
            settings["active_start"],
            settings["active_end"]
        )
        
        if is_active:
            return (True, f"Current time is within active hours ({settings['active_start']}-{settings['active_end']})")
        else:
            return (False, f"Outside active hours. Current time: {current_time.strftime('%H:%M')} ({effective_tz}), "
                          f"Active: {settings['active_start']}-{settings['active_end']}")
        
    except Exception as e:
        log.error(f"[COMMON] Error checking notification schedule: {e}")
        # On error, default to sending notifications
        return (True, f"Error checking schedule: {e}")