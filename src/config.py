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

import sqlite3
import os


def initialize_app_settings_db(db_path="app_settings.db"):
    """
    Initialize the application settings database by checking if it exists.

    Args:
        db_path (str): Path to the SQLite database file, defaults to "app_settings.db"

    Note:
        Currently only checks for database existence and prints status messages.
        Does not create tables or perform actual initialization.
        If database doesn't exist, prints creation message.
        If database exists, prints confirmation message.
    """
    if not os.path.exists(db_path):
        print(f"Creating new database at {db_path}")
    else:
        print(f"Database already exists at {db_path}. Checking tables...")


# Default AutoSync settings
DEFAULT_SETTINGS = {
    "autosync_enabled": "true",
    "sync_interval_minutes": "15",
    "sync_direction": "both",  # "both", "download_only", "upload_only"
    # Notification settings
    "notifications_enabled": "true",  # Master notification toggle
    # Notification Schedule settings
    "notification_schedule_enabled": "false",  # Enable/disable scheduled notifications
    "notification_timezone": "",  # User's preferred timezone (empty = system default)
    "notification_active_start": "09:00",  # Start of active hours (HH:MM format)
    "notification_active_end": "18:00",  # End of active hours (HH:MM format)
    "notification_working_days": "1,2,3,4,5",  # Working days (0=Sun,1=Mon,...,6=Sat) - CSV
}


def get_setting(db_path, key, default=None):
    """
    Retrieve a setting value from the app_settings table.

    Args:
        db_path (str): Path to the SQLite database file
        key (str): The setting key to retrieve
        default: Default value if setting doesn't exist

    Returns:
        str: The setting value, or default if not found
    """
    if default is None:
        default = DEFAULT_SETTINGS.get(key)
    try:
        conn = sqlite3.connect(db_path)
        cur = conn.cursor()
        cur.execute("SELECT value FROM app_settings WHERE key = ?", (key,))
        row = cur.fetchone()
        conn.close()
        if row:
            return row[0]
        return default
    except sqlite3.OperationalError as e:
        # Table doesn't exist yet
        if "no such table" in str(e):
            return default
        raise


def set_setting(db_path, key, value):
    """
    Save a setting value to the app_settings table.

    Args:
        db_path (str): Path to the SQLite database file
        key (str): The setting key to save
        value (str): The setting value to save

    Returns:
        bool: True if successful, False otherwise
    """
    try:
        conn = sqlite3.connect(db_path)
        cur = conn.cursor()
        # Create table if it doesn't exist
        cur.execute(
            "CREATE TABLE IF NOT EXISTS app_settings (key TEXT PRIMARY KEY, value TEXT)"
        )
        cur.execute(
            "INSERT OR REPLACE INTO app_settings (key, value) VALUES (?, ?)",
            (key, str(value)),
        )
        conn.commit()
        conn.close()
        return True
    except Exception:
        return False


def get_all_accounts(settings_db_path):
    """
    Retrieve all user accounts from the settings database.

    Args:
        settings_db_path (str): Path to the settings SQLite database file

    Returns:
        list: List of dictionaries containing account information with keys:
            - id: Account ID
            - name: Account name
            - link: Odoo server URL
            - database: Database name
            - username: Username for authentication
            - api_key: API key for authentication

    Note:
        Queries the 'users' table and returns all accounts as a list of dictionaries.
        Each dictionary contains all account fields for easy access.
        Returns empty list if the database or table doesn't exist yet.
    """
    try:
        conn = sqlite3.connect(settings_db_path)
        cur = conn.cursor()
        cur.execute(
            "SELECT id, name, link, database, username, api_key, "
            "sync_interval_minutes, sync_direction, autosync_enabled, last_synced_at "
            "FROM users"
        )
        rows = cur.fetchall()
        conn.close()
        columns = [
            "id", "name", "link", "database", "username", "api_key",
            "sync_interval_minutes", "sync_direction", "autosync_enabled", "last_synced_at"
        ]
        return [dict(zip(columns, row)) for row in rows]
    except sqlite3.OperationalError as e:
        # Table doesn't exist yet - QML app hasn't been opened
        if "no such table" in str(e):
            return []
        raise


def get_account_sync_settings(db_path, account_id):
    """
    Get the resolved sync settings for a specific account.

    Per-account values override global settings. If the per-account value is
    NULL, the global default from app_settings is used.

    Args:
        db_path (str): Path to the SQLite database file
        account_id (int): Account ID

    Returns:
        dict: Resolved settings with keys:
            - autosync_enabled (bool)
            - sync_interval_minutes (int)
            - sync_direction (str)
            - last_synced_at (str or None): ISO timestamp of last sync
    """
    # Read global defaults
    global_enabled = get_setting(db_path, "autosync_enabled", "true")
    global_interval = get_setting(db_path, "sync_interval_minutes", "15")
    global_direction = get_setting(db_path, "sync_direction", "both")

    try:
        conn = sqlite3.connect(db_path)
        cur = conn.cursor()
        cur.execute(
            "SELECT sync_interval_minutes, sync_direction, autosync_enabled, last_synced_at "
            "FROM users WHERE id = ?",
            (account_id,),
        )
        row = cur.fetchone()
        conn.close()

        if row:
            acct_interval, acct_direction, acct_enabled, last_synced = row

            # Per-account overrides (NULL means use global)
            resolved_interval = acct_interval if acct_interval is not None else int(global_interval)
            resolved_direction = acct_direction if acct_direction is not None else global_direction
            if acct_enabled is not None:
                resolved_enabled = bool(acct_enabled)
            else:
                resolved_enabled = global_enabled.lower() == "true"

            return {
                "autosync_enabled": resolved_enabled,
                "sync_interval_minutes": max(1, int(resolved_interval)),
                "sync_direction": resolved_direction,
                "last_synced_at": last_synced,
            }
    except sqlite3.OperationalError as e:
        if "no such column" in str(e) or "no such table" in str(e):
            pass  # Columns not yet migrated
        else:
            raise

    # Fallback to global settings
    return {
        "autosync_enabled": global_enabled.lower() == "true",
        "sync_interval_minutes": max(1, int(global_interval)),
        "sync_direction": global_direction,
        "last_synced_at": None,
    }


def update_last_synced_at(db_path, account_id):
    """
    Update the last_synced_at timestamp for an account to the current UTC time.

    Args:
        db_path (str): Path to the SQLite database file
        account_id (int): Account ID

    Returns:
        bool: True if successful, False otherwise
    """
    try:
        conn = sqlite3.connect(db_path)
        cur = conn.cursor()
        cur.execute(
            "UPDATE users SET last_synced_at = datetime('now') WHERE id = ?",
            (account_id,),
        )
        conn.commit()
        conn.close()
        return True
    except Exception:
        return False
