#!/usr/bin/env python3
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

"""
Background daemon for TimeManagement app.
Periodically syncs with Odoo and triggers notifications for new tasks/updates.
"""

import sys
import os
import time
import sqlite3
from pathlib import Path
from datetime import datetime
import logging
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib
import dbus

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(__file__))

from config import get_all_accounts
from odoo_client import OdooClient
from sync_from_odoo import sync_all_from_odoo
from common import add_notification
from logger import setup_logger

log = setup_logger()

# Configuration
SYNC_INTERVAL_MINUTES = 15
APP_ID = "ubtms_ubtms"

class NotificationDaemon:
    """Background service for syncing and sending notifications."""
    
    def __init__(self):
        self.settings_db = self._get_settings_db_path()
        self.app_db = self._get_app_db_path()
        self.last_task_count = {}
        self.notification_interface = None
        self._init_dbus()
        
    def _get_settings_db_path(self):
        """Get path to app settings database."""
        script_dir = Path(__file__).parent
        return str(script_dir / "app_settings.db")
    
    def _get_app_db_path(self):
        """Get path to main app database."""
        # Try to find the QML-created database
        user_home = Path.home()
        db_dir = user_home / ".local" / "share" / "ubtms" / "Databases"
        
        if db_dir.exists():
            # Find most recent .sqlite file
            db_files = list(db_dir.glob("*.sqlite"))
            if db_files:
                return str(max(db_files, key=lambda p: p.stat().st_mtime))
        
        log.warning("[DAEMON] Could not find app database, using fallback")
        return str(user_home / ".local" / "share" / "ubtms" / "timemanagement.db")
    
    def _init_dbus(self):
        """Initialize DBus connection for sending notifications."""
        try:
            DBusGMainLoop(set_as_default=True)
            bus = dbus.SessionBus()
            
            # Get Lomiri Postal service for notifications
            postal_service = bus.get_object(
                'com.lomiri.Postal',
                f'/com/lomiri/Postal/{self._make_path(APP_ID)}'
            )
            self.notification_interface = dbus.Interface(
                postal_service,
                'com.lomiri.Postal'
            )
            log.info("[DAEMON] DBus notification interface initialized")
        except Exception as e:
            log.error(f"[DAEMON] Failed to initialize DBus: {e}")
            self.notification_interface = None
    
    def _make_path(self, app_id):
        """Convert app_id to DBus path format."""
        pkg = app_id.split('_')[0]
        path = ""
        for c in pkg:
            if c in ['+', '.', '-', ':', '~', '_']:
                path += f"_{ord(c):02x}"
            else:
                path += c
        return path
    
    def send_notification(self, title, message):
        """Send a system notification via DBus."""
        if not self.notification_interface:
            log.warning("[DAEMON] Notification interface not available")
            return
        
        try:
            import json
            notification = {
                "notification": {
                    "card": {
                        "summary": title,
                        "body": message,
                        "popup": True,
                        "persist": True,
                        "icon": "/opt/click.ubuntu.com/ubtms/current/icon.png",
                        "actions": [f"appid://ubtms/ubtms/current-user-version"]
                    },
                    "sound": True,
                    "vibrate": True
                }
            }
            
            notification_json = json.dumps(notification)
            self.notification_interface.Post(APP_ID, notification_json)
            log.info(f"[DAEMON] Notification sent: {title}")
        except Exception as e:
            log.error(f"[DAEMON] Failed to send notification: {e}")
    
    def get_task_count(self, account_id):
        """Get current task count for an account from database."""
        try:
            conn = sqlite3.connect(self.app_db)
            cursor = conn.cursor()
            cursor.execute(
                "SELECT COUNT(*) FROM project_task_app WHERE account_id = ?",
                (account_id,)
            )
            count = cursor.fetchone()[0]
            conn.close()
            return count
        except Exception as e:
            log.error(f"[DAEMON] Failed to get task count: {e}")
            return 0
    
    def check_for_new_tasks(self, account_id, account_name):
        """Check if there are new tasks and notify if so."""
        current_count = self.get_task_count(account_id)
        previous_count = self.last_task_count.get(account_id, current_count)
        
        if current_count > previous_count:
            new_tasks = current_count - previous_count
            self.send_notification(
                "New Tasks",
                f"{new_tasks} new task(s) in {account_name}"
            )
        
        self.last_task_count[account_id] = current_count
    
    def sync_account(self, account):
        """Sync a single account and check for updates."""
        account_id = account["id"]
        account_name = account.get("name", "Unknown")
        
        try:
            log.info(f"[DAEMON] Syncing account: {account_name} (ID: {account_id})")
            
            # Create Odoo client
            client = OdooClient(
                url=account["url"],
                database=account["database"],
                username=account["username"],
                password=account["password"]
            )
            
            # Authenticate
            if not client.authenticate():
                log.error(f"[DAEMON] Failed to authenticate account {account_name}")
                return
            
            # Sync data from Odoo
            sync_all_from_odoo(client, account_id, self.settings_db)
            
            # Check for new tasks and notify
            self.check_for_new_tasks(account_id, account_name)
            
            log.info(f"[DAEMON] Sync completed for {account_name}")
            
        except Exception as e:
            log.error(f"[DAEMON] Error syncing account {account_name}: {e}")
    
    def sync_all_accounts(self):
        """Sync all configured accounts."""
        try:
            accounts = get_all_accounts(self.settings_db)
            
            if not accounts:
                log.info("[DAEMON] No accounts configured")
                return
            
            log.info(f"[DAEMON] Starting sync for {len(accounts)} account(s)")
            
            for account in accounts:
                self.sync_account(account)
            
            log.info("[DAEMON] All accounts synced")
            
        except Exception as e:
            log.error(f"[DAEMON] Error in sync_all_accounts: {e}")
    
    def run(self):
        """Main daemon loop."""
        log.info(f"[DAEMON] Starting TimeManagement background daemon")
        log.info(f"[DAEMON] Sync interval: {SYNC_INTERVAL_MINUTES} minutes")
        log.info(f"[DAEMON] Settings DB: {self.settings_db}")
        log.info(f"[DAEMON] App DB: {self.app_db}")
        
        # Initial sync
        self.sync_all_accounts()
        
        # Schedule periodic sync using GLib
        GLib.timeout_add_seconds(
            SYNC_INTERVAL_MINUTES * 60,
            self._periodic_sync
        )
        
        # Run main loop
        loop = GLib.MainLoop()
        try:
            loop.run()
        except KeyboardInterrupt:
            log.info("[DAEMON] Shutting down daemon")
            loop.quit()
    
    def _periodic_sync(self):
        """Callback for periodic sync."""
        log.info(f"[DAEMON] Periodic sync triggered at {datetime.now()}")
        self.sync_all_accounts()
        return True  # Continue the timer


def main():
    """Entry point for daemon."""
    try:
        daemon = NotificationDaemon()
        daemon.run()
    except Exception as e:
        log.error(f"[DAEMON] Fatal error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
