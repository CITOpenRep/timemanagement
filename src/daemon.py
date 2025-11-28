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
import json
import sqlite3
import argparse
import traceback
import signal
from pathlib import Path
from datetime import datetime, timedelta, timezone
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
MANIFEST_PATH = "/opt/click.ubuntu.com/ubtms/current/manifest.json"
PID_FILE = Path.home() / ".daemon.pid"
HEARTBEAT_FILE = Path.home() / ".daemon_heartbeat"

def get_app_version():
    """Get app version from manifest.json dynamically."""
    try:
        # Try installed path first
        if Path(MANIFEST_PATH).exists():
            with open(MANIFEST_PATH, 'r') as f:
                manifest = json.load(f)
                return manifest.get('version', '1.1.10')
        # Fallback to development path
        dev_manifest = Path(__file__).parent.parent / "manifest.json.in"
        if dev_manifest.exists():
            with open(dev_manifest, 'r') as f:
                content = f.read()
                # Parse version from manifest.json.in
                import re
                match = re.search(r'"version":\s*"([^"]+)"', content)
                if match:
                    return match.group(1)
    except Exception as e:
        log.error(f"[DAEMON] Failed to read app version: {e}")
    return '1.1.10'  # Fallback version

APP_VERSION = get_app_version()

class NotificationDaemon:
    """Background service for syncing and sending notifications."""
    
    def __init__(self):
        self.app_db = self._get_app_db_path()
        # Use the main app database for settings/users as well, since QML creates them there
        self.settings_db = self.app_db
        self.last_check_time = {} # Store last check timestamp per account
        self.notification_interface = None
        self.running = True
        self.loop = None
        self._write_pid_file()
        self._setup_signal_handlers()
        self._init_dbus()
    
    def _write_pid_file(self):
        """Write current PID to file for process management."""
        try:
            PID_FILE.write_text(str(os.getpid()))
            log.info(f"[DAEMON] PID file written: {PID_FILE}")
        except Exception as e:
            log.error(f"[DAEMON] Failed to write PID file: {e}")
    
    def _cleanup_pid_file(self):
        """Remove PID file on shutdown."""
        try:
            if PID_FILE.exists():
                PID_FILE.unlink()
        except Exception as e:
            log.error(f"[DAEMON] Failed to remove PID file: {e}")
    
    def _setup_signal_handlers(self):
        """Setup signal handlers for graceful shutdown."""
        signal.signal(signal.SIGTERM, self._handle_shutdown)
        signal.signal(signal.SIGINT, self._handle_shutdown)
        signal.signal(signal.SIGHUP, self._handle_reload)
    
    def _handle_shutdown(self, signum, frame):
        """Handle shutdown signals gracefully."""
        log.info(f"[DAEMON] Received signal {signum}, shutting down...")
        self.running = False
        self._cleanup_pid_file()
        if self.loop:
            self.loop.quit()
    
    def _handle_reload(self, signum, frame):
        """Handle reload signal (SIGHUP) to re-read configuration."""
        log.info("[DAEMON] Received SIGHUP, reloading configuration...")
        # Force immediate sync on next cycle
        self.last_check_time.clear()
    
    def _update_heartbeat(self):
        """Update heartbeat file to indicate daemon is alive."""
        try:
            HEARTBEAT_FILE.write_text(datetime.now(timezone.utc).isoformat())
        except Exception as e:
            log.error(f"[DAEMON] Failed to update heartbeat: {e}")
        
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
        # Auto-detect DBus session if not set (Robustness fix)
        if "DBUS_SESSION_BUS_ADDRESS" not in os.environ:
            try:
                uid = os.getuid()
                bus_path = f"/run/user/{uid}/bus"
                if os.path.exists(bus_path):
                    os.environ["DBUS_SESSION_BUS_ADDRESS"] = f"unix:path={bus_path}"
                    log.info(f"[DAEMON] Auto-detected DBus address: {os.environ['DBUS_SESSION_BUS_ADDRESS']}")
                else:
                    log.warning(f"[DAEMON] Could not find DBus socket at {bus_path}")
            except Exception as e:
                log.error(f"[DAEMON] Error trying to auto-detect DBus: {e}")

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
            
            # 1. Badge via Postal - use unread notification count instead of total tasks
            try:
                postal_path = "/com/lomiri/Postal/ubtms"
                postal = self.bus.get_object('com.lomiri.Postal', postal_path)
                postal_iface = dbus.Interface(postal, 'com.lomiri.Postal')
                
                # Use unread notification count for badge (more meaningful)
                unread_count = self.get_unread_notification_count()
                
                postal_iface.SetCounter("ubtms_ubtms", unread_count, True)
                log.info(f"[DAEMON] Badge updated to {unread_count} unread notifications")
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
                
                json_str = json.dumps(msg)
                
                # Use dynamic version from manifest
                app_id_with_version = f"ubtms_ubtms_{APP_VERSION}"
                postal_iface.Post(app_id_with_version, json_str)
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
    
    def get_current_user_id(self, account_id, username):
        """Get the Odoo user ID for the current account login."""
        try:
            conn = sqlite3.connect(self.app_db)
            cursor = conn.cursor()
            # Match login from config with login in res_users_app
            cursor.execute(
                "SELECT odoo_record_id FROM res_users_app WHERE account_id = ? AND login = ?",
                (account_id, username)
            )
            result = cursor.fetchone()
            conn.close()
            if result:
                return result[0]
            return None
        except Exception as e:
            log.error(f"[DAEMON] Failed to get current user ID: {e}")
            return None

    def check_for_updates(self, account_id, account_name, username):
        """Check for new tasks, activities, and projects since last check."""
        
        # Initialize last check time if not set (default to now, so we only catch future updates)
        # Use Odoo-compatible format (YYYY-MM-DD HH:MM:SS)
        # We subtract 5 minutes to catch items synced in the current cycle (or just before daemon start)
        if account_id not in self.last_check_time:
            start_time = datetime.now(timezone.utc) - timedelta(minutes=5)
            self.last_check_time[account_id] = start_time.strftime("%Y-%m-%d %H:%M:%S")
            # Don't return here! Proceed to check updates using this slightly backdated timestamp.
            # This ensures we catch the tasks that were just synced in the current cycle.
            # return 

        last_check = self.last_check_time[account_id]
        current_user_id = self.get_current_user_id(account_id, username)
        
        log.info(f"[DAEMON] Checking updates for {account_name} since {last_check} (User ID: {current_user_id})")
        
        try:
            conn = sqlite3.connect(self.app_db)
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            
            # 1. New/Updated Tasks Assigned to User
            # user_id in project_task_app is a CSV string of IDs (Many2many)
            if current_user_id:
                user_id_pattern = f"%,{current_user_id},%"
                # Handle single ID, start of list, end of list, or middle of list
                # Or just wrap the field in commas and search
                cursor.execute(
                    """
                    SELECT name, project_id FROM project_task_app 
                    WHERE account_id = ? 
                    AND (',' || user_id || ',') LIKE ?
                    AND last_modified > ?
                    """,
                    (account_id, user_id_pattern, last_check)
                )
                new_tasks = cursor.fetchall()
                if new_tasks:
                    log.info(f"[DAEMON] Found {len(new_tasks)} new tasks for user {current_user_id}")
                
                for task in new_tasks:
                    # Send system notification
                    self.send_notification(
                        "Task Update",
                        f"Task '{task['name']}' has been updated or assigned to you."
                    )
                    # Persist notification to database for frontend display
                    add_notification(
                        self.app_db,
                        account_id,
                        "Task",
                        f"Task '{task['name']}' has been updated or assigned to you.",
                        {"task_name": task['name'], "project_id": task.get('project_id')}
                    )

            # 2. New/Updated Activities Assigned to User
            # user_id in mail_activity_app is a single ID (Many2one)
            if current_user_id:
                cursor.execute(
                    """
                    SELECT summary, due_date FROM mail_activity_app 
                    WHERE account_id = ? 
                    AND user_id = ? 
                    AND last_modified > ?
                    """,
                    (account_id, current_user_id, last_check)
                )
                new_activities = cursor.fetchall()
                for activity in new_activities:
                    summary = activity['summary'] or "New Activity"
                    # Send system notification
                    self.send_notification(
                        "Activity Assigned",
                        f"{summary} (Due: {activity['due_date']})"
                    )
                    # Persist notification to database for frontend display
                    add_notification(
                        self.app_db,
                        account_id,
                        "Activity",
                        f"{summary} (Due: {activity['due_date']})",
                        {"summary": summary, "due_date": activity['due_date']}
                    )

            # 3. Project Updates (General)
            # Maybe filter by favorites or membership if possible, for now notify all project updates
            cursor.execute(
                """
                SELECT name FROM project_project_app 
                WHERE account_id = ? 
                AND last_modified > ?
                """,
                (account_id, last_check)
            )
            new_projects = cursor.fetchall()
            for project in new_projects:
                # Send system notification
                self.send_notification(
                    "Project Update",
                    f"Project '{project['name']}' has been updated."
                )
                # Persist notification to database for frontend display
                add_notification(
                    self.app_db,
                    account_id,
                    "Project",
                    f"Project '{project['name']}' has been updated.",
                    {"project_name": project['name']}
                )

            # 4. Timesheet Updates
            cursor.execute(
                """
                SELECT name, unit_amount FROM account_analytic_line_app 
                WHERE account_id = ? 
                AND last_modified > ?
                """,
                (account_id, last_check)
            )
            new_timesheets = cursor.fetchall()
            for timesheet in new_timesheets:
                ts_name = timesheet['name'] or "Timesheet Entry"
                # Send system notification
                self.send_notification(
                    "Timesheet Update",
                    f"Timesheet '{ts_name}' ({timesheet['unit_amount']}h) has been updated."
                )
                # Persist notification to database for frontend display
                add_notification(
                    self.app_db,
                    account_id,
                    "Timesheet",
                    f"Timesheet '{ts_name}' ({timesheet['unit_amount']}h) has been updated.",
                    {"timesheet_name": ts_name, "hours": timesheet['unit_amount']}
                )

            conn.close()
            
            # Update last check time
            self.last_check_time[account_id] = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S")
            
        except Exception as e:
            log.error(f"[DAEMON] Failed to check for updates: {e}")
    
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
            
            # Sync data from Odoo with timeout handling
            import signal
            
            def timeout_handler(signum, frame):
                raise TimeoutError("Sync operation timed out")
            
            # Set timeout for sync operation (2 minutes max)
            old_handler = signal.signal(signal.SIGALRM, timeout_handler)
            signal.alarm(120)  # 2 minute timeout
            
            try:
                sync_all_from_odoo(client, account_id, self.settings_db)
            finally:
                signal.alarm(0)  # Cancel the alarm
                signal.signal(signal.SIGALRM, old_handler)
            
            # Check for new tasks and notify
            self.check_for_updates(account_id, account_name, account_user)
            
            log.info(f"[DAEMON] Sync completed for {account_name}")
            
        except TimeoutError as e:
            log.error(f"[DAEMON] Sync timed out for {account_name}: {e}")
            # Still try to check for updates with existing data
            try:
                self.check_for_updates(account_id, account_name, account_user)
            except Exception as e2:
                log.error(f"[DAEMON] Failed to check updates after timeout: {e2}")
        except Exception as e:
            log.error(f"[DAEMON] Error syncing account {account_name}: {e}")
            # Still try to check for updates with existing data
            try:
                self.check_for_updates(account_id, account_name, account_user)
            except Exception as e2:
                log.error(f"[DAEMON] Failed to check updates after error: {e2}")
    
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
        """Main daemon loop with robust keep-alive mechanism."""
        log.info(f"[DAEMON] Starting TimeManagement background daemon")
        log.info(f"[DAEMON] App Version: {APP_VERSION}")
        log.info(f"[DAEMON] Sync interval: {SYNC_INTERVAL_MINUTES} minutes")
        log.info(f"[DAEMON] Settings DB: {self.settings_db}")
        log.info(f"[DAEMON] App DB: {self.app_db}")
        log.info(f"[DAEMON] PID: {os.getpid()}")
        
        # Update heartbeat on start
        self._update_heartbeat()
        
        # Initial sync with exception handling
        try:
            self.sync_all_accounts()
        except Exception as e:
            log.error(f"[DAEMON] Initial sync failed: {e}")
        
        # Schedule periodic sync using GLib
        GLib.timeout_add_seconds(
            SYNC_INTERVAL_MINUTES * 60,
            self._periodic_sync
        )
        
        # Schedule heartbeat update every 30 seconds
        GLib.timeout_add_seconds(30, self._heartbeat_callback)
        
        # Run main loop with restart capability
        self.loop = GLib.MainLoop()
        while self.running:
            try:
                self.loop.run()
            except KeyboardInterrupt:
                log.info("[DAEMON] Shutting down daemon (KeyboardInterrupt)")
                self.running = False
            except Exception as e:
                log.error(f"[DAEMON] Main loop error: {e}")
                log.error(f"[DAEMON] Traceback: {traceback.format_exc()}")
                if self.running:
                    log.info("[DAEMON] Restarting main loop in 5 seconds...")
                    time.sleep(5)
                    self.loop = GLib.MainLoop()
        
        # Cleanup on exit
        self._cleanup_pid_file()
        log.info("[DAEMON] Daemon stopped")
    
    def _heartbeat_callback(self):
        """Callback for periodic heartbeat update."""
        if self.running:
            self._update_heartbeat()
        return self.running  # Continue timer if still running
    
    def _periodic_sync(self):
        """Callback for periodic sync."""
        try:
            log.info(f"[DAEMON] Periodic sync triggered at {datetime.now()}")
            self.sync_all_accounts()
        except Exception as e:
            log.error(f"[DAEMON] Periodic sync failed: {e}")
        return True  # Always continue the timer
    
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
    
    def get_unread_notification_count(self):
        """Get count of unread notifications for badge display."""
        try:
            conn = sqlite3.connect(self.app_db)
            cursor = conn.cursor()
            cursor.execute("SELECT COUNT(*) FROM notification WHERE read_status = 0")
            count = cursor.fetchone()[0]
            conn.close()
            return count
        except Exception as e:
            log.error(f"[DAEMON] Failed to get unread notification count: {e}")
            return 0


def check_already_running():
    """Check if daemon is already running to prevent duplicates."""
    if PID_FILE.exists():
        try:
            old_pid = int(PID_FILE.read_text().strip())
            # Check if process is still running
            os.kill(old_pid, 0)
            return True, old_pid
        except (ProcessLookupError, ValueError):
            # Process not running, clean up stale PID file
            PID_FILE.unlink()
        except PermissionError:
            # Process running but we can't signal it
            return True, old_pid
    return False, None


def main():
    """Entry point for daemon."""
    parser = argparse.ArgumentParser(description="TimeManagement background sync daemon")
    parser.add_argument("--test", action="store_true", help="Send test notification on startup")
    parser.add_argument("--force", action="store_true", help="Force start even if already running")
    parser.add_argument("--status", action="store_true", help="Check if daemon is running")
    args = parser.parse_args()
    
    # Status check
    if args.status:
        is_running, pid = check_already_running()
        if is_running:
            print(f"Daemon is running (PID: {pid})")
            # Check heartbeat age
            if HEARTBEAT_FILE.exists():
                try:
                    last_beat = datetime.fromisoformat(HEARTBEAT_FILE.read_text().strip())
                    age = (datetime.now(timezone.utc) - last_beat).total_seconds()
                    print(f"Last heartbeat: {age:.0f} seconds ago")
                except:
                    print("Heartbeat file unreadable")
            sys.exit(0)
        else:
            print("Daemon is not running")
            sys.exit(1)
    
    # Check for existing instance
    if not args.force:
        is_running, pid = check_already_running()
        if is_running:
            log.info(f"[DAEMON] Daemon already running with PID {pid}")
            sys.exit(0)

    # Retry loop for daemon startup
    max_retries = 10
    retry_delay = 30  # seconds
    
    for attempt in range(max_retries):
        try:
            daemon = NotificationDaemon()
            
            if args.test:
                log.info("[DAEMON] Test mode: Sending test notification...")
                daemon.send_notification("Test Notification", "This is a test notification from the daemon")
                log.info("[DAEMON] Test notification sent successfully")
                
            daemon.run()
            break  # If run() completes normally, exit loop
            
        except Exception as e:
            log.error(f"[DAEMON] Fatal error (attempt {attempt + 1}/{max_retries}): {e}")
            log.error(f"[DAEMON] Traceback: {traceback.format_exc()}")
            
            if attempt < max_retries - 1:
                log.info(f"[DAEMON] Restarting in {retry_delay} seconds...")
                time.sleep(retry_delay)
                # Increase delay for next retry (exponential backoff capped at 5 min)
                retry_delay = min(retry_delay * 2, 300)
            else:
                log.error("[DAEMON] Max retries exceeded, daemon stopping")
                sys.exit(1)


if __name__ == "__main__":
    main()
