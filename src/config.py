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
        cur.execute("SELECT id, name, link, database, username, api_key FROM users")
        rows = cur.fetchall()
        conn.close()
        return [
            dict(zip(["id", "name", "link", "database", "username", "api_key"], row))
            for row in rows
        ]
    except sqlite3.OperationalError as e:
        # Table doesn't exist yet - QML app hasn't been opened
        if "no such table" in str(e):
            return []
        raise
