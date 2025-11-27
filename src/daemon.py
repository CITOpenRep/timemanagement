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
SYNC_INTERVAL_MINUTES = 1
APP_ID = "ubtms_ubtms"

class NotificationDaemon:
    """Background service for syncing and sending notifications."""
    
    def __init__(self):
        self.app_db = self._get_app_db_path()
        # Use the main app database for settings/users as well, since QML creates them there
        self.settings_db = self.app_db
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
            self.bus = dbus.SessionBus()
            
            # Use standard notifications interface
            notify_service = self.bus.get_object(
                'org.freedesktop.Notifications',
                '/org/freedesktop/Notifications'
            )
            self.notification_interface = dbus.Interface(
                notify_service,
                'org.freedesktop.Notifications'
            )
            log.info("[DAEMON] DBus notification interface initialized (org.freedesktop.Notifications)")
        except Exception as e:
            log.error(f"[DAEMON] Failed to initialize DBus: {e}")
            self.notification_interface = None
    
    def _make_path(self, app_id):
        """Convert app_id to DBus path format."""
        # This method is no longer used but kept for reference if needed
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
            # app_name, replaces_id, app_icon, summary, body, actions, hints, timeout
            icon_path = "/opt/click.ubuntu.com/ubtms/current/assets/logo.png"
            
            # Hybrid approach:
            # 1. Send Badge via Postal (Persistent badge)
            # 2. Send Popup via Postal (Persistent popup via helper)
            
            # 1. Badge via Postal
            try:
                postal_path = "/com/lomiri/Postal/ubtms"
                postal = self.bus.get_object('com.lomiri.Postal', postal_path)
                postal_iface = dbus.Interface(postal, 'com.lomiri.Postal')
                
                # Calculate total tasks across all accounts for badge
                total_tasks = self.get_total_task_count()
                
                postal_iface.SetCounter("ubtms_ubtms", total_tasks, True)
                log.info(f"[DAEMON] Badge updated to {total_tasks}")
            except Exception as e:
                log.error(f"[DAEMON] Failed to update badge: {e}")

            # 2. Popup via Postal (using push helper)
            try:
                postal_path = "/com/lomiri/Postal/ubtms"
                postal = self.bus.get_object('com.lomiri.Postal', postal_path)
                postal_iface = dbus.Interface(postal, 'com.lomiri.Postal')
                
                # Construct JSON message for Postal
                msg = {
                    "message": message,
                    "notification": {
                        "card": {
                            "summary": title,
                            "body": message,
                            "popup": True,
                            "persist": True,
                            "icon": "/opt/click.ubuntu.com/ubtms/current/assets/logo.png",
                            "actions": ["appid://ubtms/ubtms/current-user-version"]
                        },
                        "sound": True,
                        "vibrate": True
                    }
                }
                
                import json
                json_str = json.dumps(msg)
                
                # Use the exact ID that matches the desktop file
                postal_iface.Post("ubtms_ubtms_1.1.10", json_str)
                log.info(f"[DAEMON] Notification sent via Postal: {title}")
                
            except Exception as e:
                log.error(f"[DAEMON] Failed to send Postal notification: {e}")
                # Fallback to Standard Notifications if Postal fails
                hints = {
                    "urgency": dbus.Byte(2),
                    "resident": dbus.Boolean(True),
                    "desktop-entry": "ubtms_ubtms_1.1.10"
                }
                self.notification_interface.Notify(
                    "Time Management", 0, icon_path, title, message, [], hints, 0
                )
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
    
    def get_total_task_count(self):
        """Get total task count across all accounts."""
        try:
            conn = sqlite3.connect(self.app_db)
            cursor = conn.cursor()
            # Assuming we want to count all tasks for now
            cursor.execute("SELECT COUNT(*) FROM project_task_app")
            count = cursor.fetchone()[0]
            conn.close()
            return count
        except Exception as e:
            log.error(f"[DAEMON] Failed to get total task count: {e}")
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
        
        # Map config keys to OdooClient expected keys
        # config.py returns: id, name, link, database, username, api_key
        account_url = account.get("link")
        account_db = account.get("database")
        account_user = account.get("username")
        account_pass = account.get("api_key")

        # Skip local account or accounts without URL
        if not account_url or account_name == "Local Account":
            log.info(f"[DAEMON] Skipping local/invalid account: {account_name}")
            return

        try:
            log.info(f"[DAEMON] Syncing account: {account_name} (ID: {account_id})")
            
            # Create Odoo client (authenticates automatically)
            client = OdooClient(
                url=account_url,
                db=account_db,
                username=account_user,
                password=account_pass
            )
            
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
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--test", action="store_true", help="Send test notification on startup")
    args = parser.parse_args()

    try:
        daemon = NotificationDaemon()
        
        if args.test:
            log.info("[DAEMON] Test mode: Sending test notification...")
            daemon.send_notification("Test Notification", "This is a test notification from the daemon")
            log.info("[DAEMON] Test notification sent successfully")
            # We can exit after test or continue. Let's continue to test the loop too if needed, 
            # but usually test is just for notification.
            # For now, let's just run the daemon normally after test.
            
        daemon.run()
    except Exception as e:
        log.error(f"[DAEMON] Fatal error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
