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

# Early check for required dependencies with helpful error messages
MISSING_DEPS = []
SETUP_INSTRUCTIONS = """
===============================================
MISSING DEPENDENCIES FOR PUSH NOTIFICATIONS
===============================================

The TimeManagement background daemon requires additional
Python packages that are not installed on this device.

To fix this, connect to your device and run:

  adb shell
  sudo apt update
  sudo apt install python3-dbus python3-gi gir1.2-glib-2.0

Then restart the app or reboot the device.
===============================================
"""

try:
    from dbus.mainloop.glib import DBusGMainLoop
    import dbus
except ImportError as e:
    MISSING_DEPS.append(f"python3-dbus ({e})")

try:
    from gi.repository import GLib
except ImportError as e:
    MISSING_DEPS.append(f"python3-gi / gir1.2-glib-2.0 ({e})")

if MISSING_DEPS:
    # Write error to log file before crashing
    log_file = Path.home() / "daemon.log"
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    error_msg = f"{timestamp} [DAEMON] FATAL: Missing dependencies: {', '.join(MISSING_DEPS)}\n"
    error_msg += f"{timestamp} [DAEMON] {SETUP_INSTRUCTIONS}\n"
    
    try:
        with open(log_file, 'a') as f:
            f.write(error_msg)
    except:
        pass
    
    print(error_msg, file=sys.stderr)
    
    # Create a marker file so the app knows setup is needed
    setup_needed_file = Path.home() / ".ubtms_needs_setup"
    try:
        setup_needed_file.write_text('\n'.join(MISSING_DEPS))
    except:
        pass
    
    sys.exit(1)

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(__file__))

from config import get_all_accounts, get_setting, DEFAULT_SETTINGS
from odoo_client import OdooClient
from sync_from_odoo import sync_all_from_odoo
from sync_to_odoo import sync_all_to_odoo
from common import add_notification, get_current_assignments_snapshot, detect_new_assignments
from logger import setup_logger

log = setup_logger()

# Immediate startup verification - write directly to confirm daemon started
log.info("[DAEMON] ========================================")
log.info("[DAEMON] Module loaded and logger initialized")
log.info(f"[DAEMON] Script location: {__file__}")
log.info(f"[DAEMON] Home directory: {Path.home()}")

# Remove the setup needed marker since dependencies are OK
setup_needed_file = Path.home() / ".ubtms_needs_setup"
if setup_needed_file.exists():
    try:
        setup_needed_file.unlink()
    except:
        pass

# Global exception handler to prevent silent crashes
def global_exception_handler(exc_type, exc_value, exc_traceback):
    """Log any uncaught exceptions before crashing."""
    if issubclass(exc_type, KeyboardInterrupt):
        sys.__excepthook__(exc_type, exc_value, exc_traceback)
        return
    log.error(f"[DAEMON] UNCAUGHT EXCEPTION: {exc_type.__name__}: {exc_value}")
    log.error(f"[DAEMON] Traceback: {''.join(traceback.format_tb(exc_traceback))}")

sys.excepthook = global_exception_handler

# Configuration
# Default sync interval (can be overridden by database settings)
DEFAULT_SYNC_INTERVAL_MINUTES = 15
APP_ID = "ubtms_ubtms"
# Dynamically determine paths from this script's location
APP_ROOT = Path(__file__).resolve().parent.parent
MANIFEST_PATH = str(APP_ROOT / "manifest.json")
PID_FILE = Path.home() / ".daemon.pid"
HEARTBEAT_FILE = Path.home() / ".daemon_heartbeat"
LAST_CHECK_FILE = Path.home() / ".daemon_last_check.json"

def get_app_version():
    """Get app version from manifest.json dynamically."""
    try:
        # Try installed path first
        if Path(MANIFEST_PATH).exists():
            with open(MANIFEST_PATH, 'r') as f:
                manifest = json.load(f)
                return manifest.get('version', '1.2.2')
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
    return '1.2.2'  # Fallback version

APP_VERSION = get_app_version()

class NotificationDaemon:
    """Background service for syncing and sending notifications."""
    
    def __init__(self):
        self.app_db = self._get_app_db_path()
        # Use the main app database for settings/users as well, since QML creates them there
        self.settings_db = self.app_db
        self.last_check_time = self._load_last_check_times()  # Load persisted timestamps
        self.notification_interface = None
        self.running = True
        self.loop = None
        self.wakelock_cookie = None  # For suspend inhibition
        self.sync_timer_id = None  # Track GLib timer for dynamic interval changes
        self.current_sync_interval = DEFAULT_SYNC_INTERVAL_MINUTES  # Track current interval
        self.started_version = APP_VERSION  # Track version at startup for auto-restart
        self._write_pid_file()
        self._setup_signal_handlers()
        self._protect_from_oom()  # Lower OOM priority to survive memory pressure
        self._init_dbus()
        self._request_wakelock()  # Request wakelock to survive device sleep
        self._setup_suspend_handler()  # Handle sleep/wake events
    
    def _get_sync_settings(self):
        """
        Read AutoSync settings from the database.
        
        Returns:
            dict: Settings with keys:
                - autosync_enabled (bool): Whether AutoSync is enabled
                - sync_interval_minutes (int): Sync interval in minutes
                - sync_direction (str): "both", "download_only", or "upload_only"
        """
        try:
            autosync_enabled = get_setting(self.app_db, "autosync_enabled", "true")
            sync_interval = get_setting(self.app_db, "sync_interval_minutes", "15")
            sync_direction = get_setting(self.app_db, "sync_direction", "both")
            
            return {
                "autosync_enabled": autosync_enabled.lower() == "true",
                "sync_interval_minutes": max(1, int(sync_interval)),  # Minimum 1 minute
                "sync_direction": sync_direction
            }
        except Exception as e:
            log.error(f"[DAEMON] Failed to read sync settings: {e}")
            # Return safe defaults
            return {
                "autosync_enabled": True,
                "sync_interval_minutes": DEFAULT_SYNC_INTERVAL_MINUTES,
                "sync_direction": "both"
            }
    
    def _check_version_and_restart(self):
        """
        Check if app version has changed and restart daemon if needed.
        
        This allows the daemon to pick up code changes after an app update
        without requiring a device reboot.
        
        Returns:
            bool: True if restart is needed (will not return if restarting)
        """
        try:
            current_version = get_app_version()
            if current_version != self.started_version:
                log.info(f"[DAEMON] Version changed: {self.started_version} -> {current_version}")
                log.info("[DAEMON] Restarting daemon to load new code...")
                
                # Save state before restart
                self._save_last_check_times()
                self._release_wakelock()
                self._cleanup_pid_file()
                
                # Restart the daemon process
                # os.execv replaces current process with new one
                python_exe = sys.executable
                script_path = os.path.abspath(__file__)
                log.info(f"[DAEMON] Executing: {python_exe} {script_path}")
                
                # Flush logs before restart
                import logging
                for handler in logging.root.handlers:
                    handler.flush()
                
                os.execv(python_exe, [python_exe, script_path])
                # This line is never reached - execv replaces the process
                
            return False
        except Exception as e:
            log.error(f"[DAEMON] Version check failed: {e}")
            return False
    
    def _load_last_check_times(self):
        """Load persisted last check timestamps from file."""
        try:
            if LAST_CHECK_FILE.exists():
                with open(LAST_CHECK_FILE, 'r') as f:
                    data = json.load(f)
                    log.info(f"[DAEMON] Loaded last check times: {data}")
                    return data
        except Exception as e:
            log.error(f"[DAEMON] Failed to load last check times: {e}")
        return {}
    
    def _save_last_check_times(self):
        """Persist last check timestamps to file."""
        try:
            with open(LAST_CHECK_FILE, 'w') as f:
                json.dump(self.last_check_time, f)
        except Exception as e:
            log.error(f"[DAEMON] Failed to save last check times: {e}")
    
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
        # Ignore SIGTERM to prevent being killed by app lifecycle
        # Only respond to SIGINT (Ctrl+C) for intentional shutdown
        signal.signal(signal.SIGTERM, self._handle_sigterm_ignore)
        signal.signal(signal.SIGINT, self._handle_shutdown)
        signal.signal(signal.SIGHUP, self._handle_reload)
    
    def _handle_sigterm_ignore(self, signum, frame):
        """Ignore SIGTERM to stay alive when app closes."""
        log.info(f"[DAEMON] Ignoring SIGTERM (signal {signum}) - daemon will continue running")
        # Do NOT shutdown - just log and continue
    
    def _handle_shutdown(self, signum, frame):
        """Handle shutdown signals gracefully (only SIGINT)."""
        log.info(f"[DAEMON] Received signal {signum}, shutting down...")
        self.running = False
        self._release_wakelock()  # Release wakelock before exiting
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
    
    def _cleanup_memory(self):
        """Force garbage collection to reduce memory footprint."""
        import gc
        gc.collect()
        log.debug("[DAEMON] Memory cleanup completed")
        
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
    
    def _init_dbus(self, max_retries=5, retry_delay=2):
        """Initialize DBus connection for sending notifications.
        
        Args:
            max_retries: Number of times to retry if service unavailable
            retry_delay: Seconds to wait between retries
        """
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

        for attempt in range(max_retries):
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
                return  # Success!
            except Exception as e:
                if attempt < max_retries - 1:
                    log.warning(f"[DAEMON] DBus init attempt {attempt + 1}/{max_retries} failed: {e}")
                    log.info(f"[DAEMON] Retrying in {retry_delay} seconds...")
                    time.sleep(retry_delay)
                else:
                    log.error(f"[DAEMON] Failed to initialize DBus after {max_retries} attempts: {e}")
                    self.notification_interface = None
    
    def _request_wakelock(self):
        """Request a wakelock from repowerd to prevent the daemon from being killed during device sleep."""
        try:
            # Connect to system bus for repowerd
            system_bus = dbus.SystemBus()
            repowerd = system_bus.get_object('com.lomiri.Repowerd', '/com/lomiri/Repowerd')
            repowerd_iface = dbus.Interface(repowerd, 'com.lomiri.Repowerd')
            
            # Request system state: state=1 means "active" (prevent suspend)
            # MUST use dbus.Int32(1) - Python int causes "Invalid state" error
            self.wakelock_cookie = repowerd_iface.requestSysState("ubtms-daemon", dbus.Int32(1))
            log.info(f"[DAEMON] Wakelock acquired (state=1): {self.wakelock_cookie}")
            
            # Also schedule periodic wakeups to ensure we get CPU time
            self._schedule_wakeup()
        except Exception as e:
            log.warning(f"[DAEMON] Failed to acquire wakelock (daemon may be killed during sleep): {e}")
            self.wakelock_cookie = None
    
    def _schedule_wakeup(self):
        """Schedule a wakeup in 90 seconds to ensure periodic sync even during deep sleep."""
        try:
            system_bus = dbus.SystemBus()
            repowerd = system_bus.get_object('com.lomiri.Repowerd', '/com/lomiri/Repowerd')
            repowerd_iface = dbus.Interface(repowerd, 'com.lomiri.Repowerd')
            
            # Schedule wakeup 90 seconds from now (before next sync at 60s interval with buffer)
            wakeup_time = int(time.time()) + 90
            cookie = repowerd_iface.requestWakeup("ubtms-sync", dbus.UInt64(wakeup_time))
            log.info(f"[DAEMON] Scheduled wakeup at {wakeup_time} (cookie: {cookie})")
        except Exception as e:
            log.warning(f"[DAEMON] Failed to schedule wakeup: {e}")
    
    def _release_wakelock(self):
        """Release the wakelock when shutting down."""
        if self.wakelock_cookie:
            try:
                system_bus = dbus.SystemBus()
                repowerd = system_bus.get_object('com.lomiri.Repowerd', '/com/lomiri/Repowerd')
                repowerd_iface = dbus.Interface(repowerd, 'com.lomiri.Repowerd')
                repowerd_iface.clearSysState(self.wakelock_cookie)
                log.info(f"[DAEMON] Wakelock released: {self.wakelock_cookie}")
                self.wakelock_cookie = None
            except Exception as e:
                log.error(f"[DAEMON] Failed to release wakelock: {e}")
    
    def _protect_from_oom(self):
        """Lower OOM score to make the daemon less likely to be killed under memory pressure.
        
        The OOM killer uses oom_score_adj to prioritize which processes to kill.
        Range is -1000 (never kill) to 1000 (kill first). Default is 0.
        We use -500 which significantly lowers our kill priority.
        """
        try:
            oom_adj_path = f'/proc/{os.getpid()}/oom_score_adj'
            with open(oom_adj_path, 'w') as f:
                f.write('-500')
            log.info("[DAEMON] OOM protection enabled (oom_score_adj=-500)")
        except PermissionError:
            log.warning("[DAEMON] Cannot set OOM score - insufficient permissions (needs root)")
        except Exception as e:
            log.warning(f"[DAEMON] Failed to set OOM protection: {e}")
    
    def _setup_suspend_handler(self):
        """Register to receive PrepareForSleep signals from logind to handle system suspend/resume."""
        try:
            system_bus = dbus.SystemBus()
            
            # Connect to logind's PrepareForSleep signal
            system_bus.add_signal_receiver(
                self._handle_sleep_signal,
                signal_name='PrepareForSleep',
                dbus_interface='org.freedesktop.login1.Manager',
                bus_name='org.freedesktop.login1'
            )
            log.info("[DAEMON] Suspend/resume handler registered with logind")
        except Exception as e:
            log.warning(f"[DAEMON] Failed to register suspend handler: {e}")
    
    def _handle_sleep_signal(self, sleeping):
        """Handle PrepareForSleep signal from logind.
        
        Args:
            sleeping: True when system is going to sleep, False when waking up
        """
        if sleeping:
            log.info("[DAEMON] System preparing to sleep - saving state")
            self._save_last_check_times()
            self._update_heartbeat()
        else:
            log.info("[DAEMON] System waking up - refreshing wakelocks and scheduling sync")
            # Re-acquire wakelock after wake
            self._request_wakelock()
            # Schedule immediate sync after short delay
            GLib.timeout_add_seconds(5, self._sync_after_wake)
    
    def _sync_after_wake(self):
        """Perform sync after system wakes from sleep."""
        log.info("[DAEMON] Post-wake sync starting")
        try:
            self.sync_all_accounts()
        except Exception as e:
            log.error(f"[DAEMON] Post-wake sync failed: {e}")
        return False  # Don't repeat - one-shot callback
    
    def send_notification(self, title, message, nav_type=None, record_id=None, account_id=None):
        """Send a system notification via DBus with optional deep link navigation."""
        # Retry DBus initialization if not available
        if not self.notification_interface:
            log.info("[DAEMON] Notification interface not available, attempting re-initialization...")
            self._init_dbus()
            if not self.notification_interface:
                log.warning("[DAEMON] DBus re-initialization failed, skipping notification")
                return
            log.info("[DAEMON] DBus re-initialized successfully!")
        
        try:
            # Type-specific icon mapping
            icon_map = {
                "Task": str(APP_ROOT / "qml" / "images" / "task.svg"),
                "Activity": str(APP_ROOT / "qml" / "images" / "activity.svg"),
                "Project": str(APP_ROOT / "qml" / "images" / "project.svg"),
                "Timesheet": str(APP_ROOT / "qml" / "images" / "timesheet.svg"),
            }
            # Select icon based on notification type, fallback to logo
            icon_path = icon_map.get(nav_type, str(APP_ROOT / "assets" / "logo.png"))
            log.info(f"[DAEMON] Using icon for type '{nav_type}': {icon_path}")
            
            # Construct deep link URI for navigation (if navigation params provided)
            # Use odoo_id=1 flag to indicate this is an odoo_record_id (stable across syncs)
            if nav_type and record_id and record_id > 0:
                action_uri = f"ubtms://navigate?type={nav_type}&id={record_id}&account_id={account_id or 0}&odoo_id=1"
            else:
                # Format: appid://package-name/hook-name/current-user-version
                action_uri = "appid://ubtms/ubtms/current-user-version"
            
            log.info(f"[DAEMON] Notification action URI: {action_uri}")
            
            # 1. Update Badge via Postal
            try:
                # Postal path is based on package name (before underscore)
                # For ubtms_ubtms, the package is "ubtms", so path is /com/lomiri/Postal/ubtms
                postal_path = "/com/lomiri/Postal/ubtms"
                postal = self.bus.get_object('com.lomiri.Postal', postal_path)
                postal_iface = dbus.Interface(postal, 'com.lomiri.Postal')
                
                # Use unread notification count for badge (more meaningful)
                unread_count = self.get_unread_notification_count()
                
                postal_iface.SetCounter("ubtms_ubtms", unread_count, True)
                log.info(f"[DAEMON] Badge updated to {unread_count} unread notifications")
            except Exception as e:
                log.error(f"[DAEMON] Failed to update badge: {e}")

            # 2. Send notification popup via Postal Post method
            # This simulates receiving a push notification locally
            notification_sent = False
            try:
                postal_path = "/com/lomiri/Postal/ubtms"
                postal = self.bus.get_object('com.lomiri.Postal', postal_path)
                postal_iface = dbus.Interface(postal, 'com.lomiri.Postal')
                
                # Construct JSON message for Postal
                # Include navigation data so the app can navigate to the correct record
                message_data = {
                    "text": message,
                    "type": nav_type or "",
                    "id": record_id or -1,
                    "account_id": account_id or 0
                }
                
                # Use raw path (not file:// URI) - matches C++ NotificationHelper behavior
                icon_file = str(APP_ROOT / "assets" / "logo.png")
                
                # Ubuntu Touch Postal notification format
                # Note: vibrate can be true (use default) or an object with pattern
                msg = {
                    "message": message_data,
                    "notification": {
                        "tag": f"{nav_type or 'update'}_{record_id or 0}_{int(time.time())}",
                        "card": {
                            "summary": title,
                            "body": message,
                            "popup": True,
                            "persist": True,
                            "icon": icon_file,
                            "actions": [action_uri]
                        },
                        "sound": True,
                        "vibrate": True
                    }
                }
                
                json_str = json.dumps(msg)
                log.info(f"[DAEMON] Postal JSON payload: {json_str}")
                
                # Use dynamic version from manifest
                app_id_with_version = f"ubtms_ubtms_{APP_VERSION}"
                log.info(f"[DAEMON] Calling Postal.Post with app_id={app_id_with_version}")
                
                # Call Post and check for errors
                try:
                    result = postal_iface.Post(app_id_with_version, json_str)
                    log.info(f"[DAEMON] Postal.Post result: {result}")
                except dbus.exceptions.DBusException as dbus_err:
                    log.error(f"[DAEMON] DBus exception from Postal.Post: {dbus_err}")
                    raise
                    
                log.info(f"[DAEMON] Notification sent via Postal: {title}")
                notification_sent = True
                
            except Exception as e:
                log.warning(f"[DAEMON] Postal notification failed: {e}")
            
            # 3. Fallback to Standard Freedesktop Notifications if Postal didn't work
            if not notification_sent:
                try:
                    hints = {
                        "urgency": dbus.Byte(2),  # Critical urgency
                        "desktop-entry": dbus.String("ubtms_ubtms"),
                        "x-canonical-snap-decisions": dbus.String("true"),
                        "x-canonical-private-button-tint": dbus.Boolean(True),
                    }
                    # Add action for clickable notification
                    actions = ["default", "Open", action_uri, "View"]
                    
                    notification_id = self.notification_interface.Notify(
                        "Time Management",  # App name
                        0,  # Replace ID (0 = new notification)
                        icon_path,  # Icon path
                        title,  # Summary
                        message,  # Body
                        actions,  # Actions
                        hints,  # Hints
                        -1  # Timeout (-1 = default)
                    )
                    log.info(f"[DAEMON] Notification sent via freedesktop (ID: {notification_id}): {title}")
                except Exception as fallback_error:
                    log.error(f"[DAEMON] Freedesktop notification also failed: {fallback_error}")
                    
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

    def check_for_new_assignments(self, account_id, account_name, current_user_id, pre_sync_snapshot):
        """
        Check for NEW assignments only by comparing pre-sync and post-sync state.
        
        This method only sends notifications when:
        - Tasks: User was NEWLY assigned (not in pre-sync snapshot, now assigned)
        - Activities: User was NEWLY assigned
        - Projects: User became manager or favorited (not previously)
        - Timesheets: New timesheet entries for this user
        
        This prevents notification spam from:
        - Daemon restarts (existing assignments don't trigger notifications)
        - General updates to records (only assignment changes matter)
        
        Args:
            account_id: Account ID
            account_name: Account name for logging
            current_user_id: The Odoo user ID for this account
            pre_sync_snapshot: Snapshot from get_current_assignments_snapshot() taken BEFORE sync
        """
        if not current_user_id:
            log.warning(f"[DAEMON] No user ID for {account_name}, skipping assignment check")
            return
        
        log.info(f"[DAEMON] Checking for new assignments for {account_name} (User ID: {current_user_id})")
        
        # Detect new assignments by comparing current DB state with pre-sync snapshot
        new_assignments = detect_new_assignments(
            self.app_db, account_id, current_user_id, pre_sync_snapshot
        )
        
        # =================================================================
        # 1. TASKS: Notify only for NEW assignments
        # =================================================================
        for task in new_assignments['new_tasks']:
            task_id = task.get('id')
            task_name = task.get('name', 'Unknown Task')
            project_id = task.get('project_id')
            odoo_record_id = task.get('odoo_record_id')
            
            # Use odoo_record_id for navigation (stable across syncs, unlike local id)
            self.send_notification(
                "Task Assigned",
                f"You've been assigned to task '{task_name}'.",
                nav_type="Task",
                record_id=odoo_record_id,  # Use odoo_record_id for stable navigation
                account_id=account_id
            )
            add_notification(
                self.app_db,
                account_id,
                "Task",
                f"You've been assigned to task '{task_name}'.",
                {"task_name": task_name, "project_id": project_id, "id": task_id, "odoo_record_id": odoo_record_id, "is_new_assignment": True}
            )
        
        if new_assignments['new_tasks']:
            log.info(f"[DAEMON] Notified {len(new_assignments['new_tasks'])} NEW task assignments")
        
        # =================================================================
        # 2. ACTIVITIES: Notify only for NEW assignments
        # =================================================================
        for activity in new_assignments['new_activities']:
            activity_id = activity.get('id')
            summary = activity.get('summary') or "New Activity"
            due_date = activity.get('due_date', 'No date')
            odoo_record_id = activity.get('odoo_record_id')
            
            # Use odoo_record_id for navigation (stable across syncs, unlike local id)
            self.send_notification(
                "Activity Assigned",
                f"New activity: {summary} (Due: {due_date})",
                nav_type="Activity",
                record_id=odoo_record_id,  # Use odoo_record_id for stable navigation
                account_id=account_id
            )
            add_notification(
                self.app_db,
                account_id,
                "Activity",
                f"New activity: {summary} (Due: {due_date})",
                {"summary": summary, "due_date": due_date, "id": activity_id, "odoo_record_id": odoo_record_id, "is_new_assignment": True}
            )
        
        if new_assignments['new_activities']:
            log.info(f"[DAEMON] Notified {len(new_assignments['new_activities'])} NEW activity assignments")
        
        # =================================================================
        # 3. PROJECTS: Notify for newly managed/favorited projects
        # =================================================================
        for project in new_assignments['new_projects']:
            local_project_id = project.get('id')
            project_name = project.get('name', 'Unknown Project')
            odoo_record_id = project.get('odoo_record_id')
            
            # Use odoo_record_id for navigation (stable across syncs, unlike local id)
            self.send_notification(
                "Project Added",
                f"You now have access to project '{project_name}'.",
                nav_type="Project",
                record_id=odoo_record_id,  # Use odoo_record_id for stable navigation
                account_id=account_id
            )
            add_notification(
                self.app_db,
                account_id,
                "Project",
                f"You now have access to project '{project_name}'.",
                {"project_name": project_name, "id": local_project_id, "odoo_record_id": odoo_record_id, "is_new_assignment": True}
            )
        
        if new_assignments['new_projects']:
            log.info(f"[DAEMON] Notified {len(new_assignments['new_projects'])} NEW project assignments")
        
        # =================================================================
        # 4. TIMESHEETS: Notify for new timesheet entries
        # =================================================================
        for timesheet in new_assignments['new_timesheets']:
            timesheet_id = timesheet.get('id')
            ts_name = timesheet.get('name') or "Timesheet Entry"
            hours = timesheet.get('unit_amount', 0)
            odoo_record_id = timesheet.get('odoo_record_id')
            
            # Use odoo_record_id for navigation (stable across syncs, unlike local id)
            self.send_notification(
                "Timesheet Added",
                f"New timesheet '{ts_name}' ({hours}h) synced.",
                nav_type="Timesheet",
                record_id=odoo_record_id,  # Use odoo_record_id for stable navigation
                account_id=account_id
            )
            add_notification(
                self.app_db,
                account_id,
                "Timesheet",
                f"New timesheet '{ts_name}' ({hours}h) synced.",
                {"timesheet_name": ts_name, "hours": hours, "id": timesheet_id, "odoo_record_id": odoo_record_id, "is_new_assignment": True}
            )
        
        if new_assignments['new_timesheets']:
            log.info(f"[DAEMON] Notified {len(new_assignments['new_timesheets'])} NEW timesheet entries")
        
        # Summary log
        total_new = (len(new_assignments['new_tasks']) + len(new_assignments['new_activities']) + 
                     len(new_assignments['new_projects']) + len(new_assignments['new_timesheets']))
        if total_new == 0:
            log.info(f"[DAEMON] No new assignments detected for {account_name}")
        else:
            log.info(f"[DAEMON] Total {total_new} new assignment notifications sent for {account_name}")

    def sync_account(self, account, sync_direction="both"):
        """Sync a single account and check for updates.
        
        Args:
            account: Account dictionary with connection details
            sync_direction: "both", "download_only", or "upload_only"
        """
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

        # Get current user ID for assignment tracking
        current_user_id = self.get_current_user_id(account_id, account_user)
        
        # CRITICAL: Capture assignment snapshot BEFORE sync
        # This allows us to detect NEW assignments by comparing pre/post sync state
        pre_sync_snapshot = get_current_assignments_snapshot(self.app_db, account_id, current_user_id)
        log.info(f"[DAEMON] Pre-sync snapshot captured for {account_name}")

        try:
            log.info(f"[DAEMON] Syncing account: {account_name} (ID: {account_id}) [direction: {sync_direction}]")
            
            # Update heartbeat before creating client
            self._update_heartbeat()
            
            # Create Odoo client (authenticates automatically)
            client = OdooClient(
                url=account_url,
                db=account_db,
                username=account_user,
                password=account_pass
            )
            log.info(f"[DAEMON] OdooClient created for {account_name}")
            
            # Update heartbeat after client creation
            self._update_heartbeat()
            
            # UPLOAD FIRST: Sync local changes to Odoo (prevents overwrites)
            if sync_direction in ("both", "upload_only"):
                try:
                    log.info(f"[DAEMON] Starting sync_all_to_odoo for {account_name}")
                    self._update_heartbeat()
                    
                    sync_all_to_odoo(client, account_id, self.settings_db)
                    
                    self._update_heartbeat()
                    log.info(f"[DAEMON] sync_all_to_odoo completed for {account_name}")
                    
                    # Clean up memory after upload sync
                    self._cleanup_memory()
                    
                except Exception as upload_error:
                    log.error(f"[DAEMON] sync_all_to_odoo failed: {upload_error}")
                    log.error(f"[DAEMON] Upload sync error traceback: {traceback.format_exc()}")
                    # Continue with download sync
            
            # DOWNLOAD: Sync data from Odoo to device
            if sync_direction in ("both", "download_only"):
                try:
                    log.info(f"[DAEMON] Starting sync_all_from_odoo for {account_name}")
                    self._update_heartbeat()
                    
                    sync_all_from_odoo(client, account_id, self.settings_db)
                    
                    self._update_heartbeat()
                    log.info(f"[DAEMON] sync_all_from_odoo completed for {account_name}")
                    
                    # Clean up memory after download sync
                    self._cleanup_memory()
                    
                except Exception as sync_error:
                    log.error(f"[DAEMON] sync_all_from_odoo failed: {sync_error}")
                    log.error(f"[DAEMON] Sync error traceback: {traceback.format_exc()}")
                    # Continue with notification check using existing data
            
            # Update heartbeat after sync
            self._update_heartbeat()
            
            # Check for NEW assignments only (compare post-sync with pre-sync snapshot)
            log.info(f"[DAEMON] Checking for new assignments for {account_name}")
            self.check_for_new_assignments(account_id, account_name, current_user_id, pre_sync_snapshot)
            
            log.info(f"[DAEMON] Sync completed for {account_name}")
            
            # Final memory cleanup after account processing
            self._cleanup_memory()
            
        except Exception as e:
            log.error(f"[DAEMON] Error syncing account {account_name}: {e}")
            log.error(f"[DAEMON] Error traceback: {traceback.format_exc()}")
            # On sync error, we still have the pre_sync_snapshot, so we can check for any
            # assignments that might have been partially synced
            try:
                self.check_for_new_assignments(account_id, account_name, current_user_id, pre_sync_snapshot)
            except Exception as e2:
                log.error(f"[DAEMON] Failed to check assignments after error: {e2}")
    
    def sync_all_accounts(self):
        """Sync all configured accounts using current settings."""
        try:
            # Read current sync settings from database
            settings = self._get_sync_settings()
            sync_direction = settings["sync_direction"]
            
            log.info(f"[DAEMON] Sync settings: enabled={settings['autosync_enabled']}, "
                     f"interval={settings['sync_interval_minutes']}min, direction={sync_direction}")
            
            accounts = get_all_accounts(self.settings_db)
            
            if not accounts:
                log.info("[DAEMON] No accounts configured")
                return
            
            log.info(f"[DAEMON] Starting sync for {len(accounts)} account(s)")
            
            for account in accounts:
                self.sync_account(account, sync_direction=sync_direction)
                # Update heartbeat between accounts
                self._update_heartbeat()
            
            log.info("[DAEMON] All accounts synced")
            
        except Exception as e:
            log.error(f"[DAEMON] Error in sync_all_accounts: {e}")
    
    def _schedule_sync_timer(self, interval_minutes):
        """Schedule the sync timer with the given interval."""
        # Remove existing timer if any
        if self.sync_timer_id:
            GLib.source_remove(self.sync_timer_id)
            self.sync_timer_id = None
        
        # Schedule new timer
        self.current_sync_interval = interval_minutes
        self.sync_timer_id = GLib.timeout_add_seconds(
            interval_minutes * 60,
            self._periodic_sync
        )
        log.info(f"[DAEMON] Sync timer scheduled: every {interval_minutes} minutes")
    
    def run(self):
        """Main daemon loop with robust keep-alive mechanism."""
        # Read initial settings
        settings = self._get_sync_settings()
        initial_interval = settings["sync_interval_minutes"]
        
        log.info(f"[DAEMON] Starting TimeManagement background daemon")
        log.info(f"[DAEMON] App Version: {APP_VERSION}")
        log.info(f"[DAEMON] AutoSync enabled: {settings['autosync_enabled']}")
        log.info(f"[DAEMON] Sync interval: {initial_interval} minutes")
        log.info(f"[DAEMON] Sync direction: {settings['sync_direction']}")
        log.info(f"[DAEMON] Settings DB: {self.settings_db}")
        log.info(f"[DAEMON] App DB: {self.app_db}")
        log.info(f"[DAEMON] PID: {os.getpid()}")
        
        # Update heartbeat on start
        self._update_heartbeat()
        
        # Initial sync with exception handling (if AutoSync is enabled)
        if settings["autosync_enabled"]:
            try:
                self.sync_all_accounts()
            except Exception as e:
                log.error(f"[DAEMON] Initial sync failed: {e}")
        else:
            log.info("[DAEMON] AutoSync disabled, skipping initial sync")
        
        # Schedule periodic sync using GLib with dynamic interval
        self._schedule_sync_timer(initial_interval)
        
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
        self._release_wakelock()
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
            # Check if app was updated and restart if needed
            self._check_version_and_restart()
            
            # Read current settings on each sync cycle
            settings = self._get_sync_settings()
            
            log.info(f"[DAEMON] Periodic sync triggered at {datetime.now()}")
            
            # Check if AutoSync is still enabled
            if not settings["autosync_enabled"]:
                log.info("[DAEMON] AutoSync is disabled, skipping sync")
                # Keep the timer running so we can resume when re-enabled
                return True
            
            # Check if interval changed and reschedule if needed
            new_interval = settings["sync_interval_minutes"]
            if new_interval != self.current_sync_interval:
                log.info(f"[DAEMON] Sync interval changed: {self.current_sync_interval} -> {new_interval} minutes")
                # Reschedule timer with new interval (will take effect after this sync)
                self._schedule_sync_timer(new_interval)
                # Return False to cancel current timer (new one is already scheduled)
                return False
            
            # Reschedule wakeup for next sync cycle
            self._schedule_wakeup()
            # Refresh wakelock to ensure it's still active
            self._request_wakelock()
            self.sync_all_accounts()
            log.info("[DAEMON] Periodic sync completed successfully")
        except Exception as e:
            log.error(f"[DAEMON] Periodic sync failed: {e}")
            log.error(f"[DAEMON] Periodic sync traceback: {traceback.format_exc()}")
        return True  # Continue the timer
    
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
            os.kill(old_pid, 0)  # Check if process exists
            return True, old_pid
        except (ProcessLookupError, ValueError):
            PID_FILE.unlink(missing_ok=True)
        except PermissionError:
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
