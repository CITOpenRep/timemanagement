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

import threading
import json
import urllib.request

from bus import send
from common import write_sync_report_to_db
from config import get_all_accounts, update_last_synced_at, get_setting, set_setting
from logger import setup_logger
from odoo_client import OdooClient
from sync_from_odoo import sync_all_from_odoo
from sync_to_odoo import sync_all_to_odoo

log = setup_logger()

sync_lock = threading.Lock()
sync_in_progress = False


def sync(settings_db, account_id):
    """
    Perform synchronous bidirectional sync between local database and Odoo.
    """
    send("progress", 0)
    write_sync_report_to_db(
        settings_db, account_id, "In Progress", "Sync job triggered"
    )
    accounts = get_all_accounts(settings_db)
    selected = accounts[account_id]
    client = OdooClient(
        selected["link"],
        selected["database"],
        selected["username"],
        selected["api_key"],
    )

    # Automatically register device push token with Odoo (native or legacy bridge)
    push_token = get_setting(settings_db, "push_token", "")
    if push_token:
        bridge_url = get_setting(settings_db, "push_bridge_url") or "https://ubtms-push-bridge.onrender.com"
        try:
            reg_res = client.register_push_device(push_token, bridge_url=bridge_url)
            if isinstance(reg_res, dict):
                mode = reg_res.get("mode", "none")
                set_setting(settings_db, f"push_mode_{account_id}", mode)
                set_setting(settings_db, "push_mode", mode)
        except Exception as e:
            log.debug(f"[PUSH] Push device registration skipped: {e}")

    send("progress", 20)
    log.debug("Syncing from odoo from server: " + selected["link"])
    sync_all_from_odoo(client, selected["id"], settings_db, account_name=selected.get("name", ""))

    log.debug("Syncing to odoo")
    send("progress", 50)
    sync_all_to_odoo(client, selected["id"], settings_db)

    write_sync_report_to_db(
        settings_db, account_id, "Successful", "Sync completed successfully"
    )
    send("progress", 100)
    return True


def sync_background(settings_db, account_id):
    """
    Perform asynchronous bidirectional sync in a background thread.
    """
    global sync_in_progress

    with sync_lock:
        if sync_in_progress:
            log.debug("[SYNC] Already in progress. Ignoring new request.")
            return False
        sync_in_progress = True

    def do_sync():
        global sync_in_progress
        try:
            send("sync_progress", 0)
            log.debug(f"[SYNC] Starting background sync to {settings_db}...")
            write_sync_report_to_db(
                settings_db, account_id, "In Progress", "Sync job triggered"
            )
            accounts = get_all_accounts(settings_db)
            selected = next((acc for acc in accounts if acc["id"] == account_id), None)
            send("sync_progress", 20)

            if not selected:
                write_sync_report_to_db(settings_db, account_id, "Failed", "Account not found")
                return

            log.debug(f"[SYNC] Found account: {selected['name']} (ID: {selected['id']})")

            send("sync_progress", 25)
            client = OdooClient(
                selected["link"],
                selected["database"],
                selected["username"],
                selected["api_key"],
            )

            # Automatically register device push token with Odoo (native or legacy bridge)
            push_token = get_setting(settings_db, "push_token", "")
            if push_token:
                bridge_url = get_setting(settings_db, "push_bridge_url") or "https://ubtms-push-bridge.onrender.com"
                try:
                    reg_res = client.register_push_device(push_token, bridge_url=bridge_url)
                    if isinstance(reg_res, dict):
                        mode = reg_res.get("mode", "none")
                        set_setting(settings_db, f"push_mode_{account_id}", mode)
                        set_setting(settings_db, "push_mode", mode)
                except Exception as e:
                    log.debug(f"[PUSH] Push device registration skipped: {e}")

            send("sync_progress", 30)
            log.debug("Syncing from odoo: ID Is " + selected["link"])
            sync_all_from_odoo(client, account_id, settings_db, account_name=selected.get("name", ""))
            send("sync_progress", 50)
            log.debug("Syncing to odoo")
            sync_all_to_odoo(client, account_id, settings_db)
            send("sync_progress", 90)

            log.debug("[SYNC] Background sync completed.")
            write_sync_report_to_db(
                settings_db,
                account_id,
                "Successful",
                "Sync completed successfully",
            )
            update_last_synced_at(settings_db, account_id)
            send("sync_progress", 100)
            send("sync_completed", True)
        except Exception as e:
            log.exception(f"[SYNC] Error during background sync: {e}")
            write_sync_report_to_db(settings_db, account_id, "Failed", str(e))
            send("sync_completed", False)
        finally:
            with sync_lock:
                sync_in_progress = False

    thread = threading.Thread(target=do_sync)
    thread.start()
    return True


def start_sync_in_background(settings_db, account_id):
    """
    Start a background synchronization process.
    """
    return sync_background(settings_db, account_id)


def cleanup_legacy_daemon():
    """
    Safely clean up any leftover artifacts from the decommissioned background daemon.
    """
    import os
    import subprocess

    home = os.path.expanduser("~")
    try:
        subprocess.run(["systemctl", "--user", "stop", "ubtms-daemon"], capture_output=True, timeout=2)
        subprocess.run(["systemctl", "--user", "disable", "ubtms-daemon"], capture_output=True, timeout=2)
    except Exception:
        pass

    try:
        subprocess.run(["pkill", "-f", "python3.*daemon.py"], capture_output=True, timeout=2)
    except Exception:
        pass

    stale_files = [
        os.path.join(home, ".daemon.pid"),
        os.path.join(home, ".daemon_heartbeat"),
        os.path.join(home, "daemon.log"),
        os.path.join(home, ".ubtms_needs_setup"),
        os.path.join(home, ".config", "systemd", "user", "ubtms-daemon.service"),
        os.path.join(home, ".config", "autostart", "ubtms-daemon.desktop"),
    ]
    for path in stale_files:
        try:
            if os.path.isfile(path) or os.path.islink(path):
                os.remove(path)
        except Exception:
            pass


def save_push_token(settings_db=None, token=""):
    """
    Save UBports push token to settings and attempt registration on all remote accounts.
    """
    cleanup_legacy_daemon()
    # Allow calling as save_push_token(token) or save_push_token(settings_db, token)
    if not token and settings_db and isinstance(settings_db, str) and "/" not in settings_db and not settings_db.endswith(".sqlite") and not settings_db.endswith(".db"):
        token = settings_db
        settings_db = None

    if not settings_db:
        from .storage import resolve_qml_db_path
        settings_db = resolve_qml_db_path("ubtms") or "app_settings.db"

    if not token:
        token = get_setting(settings_db, "push_token", "")

    if not token:
        return False

    set_setting(settings_db, "push_token", token)
    log.info(f"[PUSH] Saved push token to settings: {token[:8]}...")

    bridge_url = get_setting(settings_db, "push_bridge_url") or "https://ubtms-push-bridge.onrender.com"
    try:
        accounts = get_all_accounts(settings_db)
        for acc in accounts:
            if not acc.get("is_local") and acc.get("link"):
                try:
                    c = OdooClient(
                        acc["link"],
                        acc["database"],
                        acc["username"],
                        acc["api_key"]
                    )
                    reg_res = c.register_push_device(token, bridge_url=bridge_url)
                    if isinstance(reg_res, dict):
                        mode = reg_res.get("mode", "none")
                        set_setting(settings_db, f"push_mode_{acc['id']}", mode)
                        if mode != "none":
                            set_setting(settings_db, "push_mode", mode)
                    else:
                        set_setting(settings_db, f"push_mode_{acc['id']}", "none")
                except Exception as ex:
                    log.debug(f"[PUSH] Account registration attempt skipped: {ex}")
                    set_setting(settings_db, f"push_mode_{acc['id']}", "none")
    except Exception as e:
        log.warning(f"[PUSH] Error broadcasting push token to accounts: {e}")
    return True


def get_push_mode(settings_db=None, account_id=-1):
    """
    Get active push mode ('native', 'legacy_bridge', or 'none').
    """
    if not settings_db:
        from .storage import resolve_qml_db_path
        settings_db = resolve_qml_db_path("ubtms") or "app_settings.db"

    if account_id > 0:
        mode = get_setting(settings_db, f"push_mode_{account_id}", "")
        if mode:
            return mode

    return get_setting(settings_db, "push_mode", "none")


def unregister_account_push(settings_db=None, account_id=-1, account_data=None):
    """
    Unregister an account from push bridge and clear push mode settings.
    """
    if not settings_db:
        from .storage import resolve_qml_db_path
        settings_db = resolve_qml_db_path("ubtms") or "app_settings.db"

    token = get_setting(settings_db, "push_token", "")
    bridge_url = get_setting(settings_db, "push_bridge_url") or "https://ubtms-push-bridge.onrender.com"

    acc = account_data
    if not acc and account_id > 0:
        try:
            accounts = get_all_accounts(settings_db)
            for a in accounts:
                if a.get("id") == account_id:
                    acc = a
                    break
        except Exception:
            pass

    if not acc or not token:
        if account_id > 0:
            set_setting(settings_db, f"push_mode_{account_id}", "none")
        return False

    link = acc.get("link")
    database = acc.get("database")
    username = acc.get("username")
    api_key = acc.get("api_key")

    if link and database and username and api_key:
        try:
            import urllib.request
            c = OdooClient(link, database, username, api_key)
            unreg_url = f"{bridge_url.rstrip('/')}/v1/legacy/unregister"
            payload = json.dumps({
                "ubports_token": token,
                "odoo_url": c.url,
                "db": c.db,
                "uid": c.uid
            }).encode("utf-8")
            req = urllib.request.Request(
                unreg_url,
                data=payload,
                headers={"Content-Type": "application/json", "User-Agent": "ubtms/1.3.4"}
            )
            with urllib.request.urlopen(req, timeout=5) as resp:
                log.info(f"[PUSH] Unregistered account {account_id} (UID {c.uid}) from bridge: {resp.status}")
        except Exception as e:
            log.debug(f"[PUSH] Bridge unregister attempt failed for account {account_id}: {e}")

    if account_id > 0:
        set_setting(settings_db, f"push_mode_{account_id}", "none")
    return True

