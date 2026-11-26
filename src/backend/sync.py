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
from config import get_account_sync_settings, get_all_accounts, update_last_synced_at, get_setting, set_setting
from logger import setup_logger
from odoo_client import OdooClient
from sync_from_odoo import sync_all_from_odoo
from sync_to_odoo import sync_all_to_odoo
from .sync_queue import flush_sync_queue, get_sync_queue_summary, wake_sync_queue

log = setup_logger()

sync_lock = threading.Lock()
sync_in_progress = False
_push_reg_lock = threading.Lock()
_push_reg_in_progress = False
_current_push_token = None
_pending_push_request = None


def sync(settings_db, account_id, sync_mode="auto"):
    """
    Perform synchronous bidirectional sync between local database and Odoo.
    Pushes pending local mutations first, then pulls changes from Odoo.
    """
    send("progress", 0)
    write_sync_report_to_db(
        settings_db, account_id, "In Progress", "Sync job triggered"
    )
    accounts = get_all_accounts(settings_db)
    selected = next(
        (acc for acc in accounts if acc["id"] == account_id or str(acc["id"]) == str(account_id)),
        None,
    )
    if not selected:
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

    sync_direction = get_account_sync_settings(settings_db, selected["id"]).get("sync_direction", "both")

    send("progress", 20)
    if sync_direction != "download_only":
        log.debug("Flushing queued local changes to odoo")
        flush_sync_queue(settings_db, account_id=selected["id"], client=client, ignore_backoff=True)
        sync_all_to_odoo(client, selected["id"], settings_db)

    send("progress", 50)
    if sync_direction != "upload_only":
        log.debug("Syncing from odoo from server: " + selected["link"])
        sync_all_from_odoo(
            client,
            selected["id"],
            settings_db,
            account_name=selected.get("name", ""),
            sync_mode=sync_mode,
        )

    write_sync_report_to_db(
        settings_db, account_id, "Successful", "Sync completed successfully"
    )
    send("progress", 100)
    return True


def sync_background(settings_db, account_id, sync_mode="auto"):
    """
    Perform asynchronous bidirectional sync in a background thread.
    Pushes queued local changes first so local edits reach Odoo immediately,
    then pulls delta or full updates depending on sync_mode.
    """
    global sync_in_progress

    with sync_lock:
        if sync_in_progress:
            # ponytail: active sync is already in flight; return True so UI tracks progress
            log.debug(f"[SYNC] Already in progress. Attaching to existing sync for account {account_id}.")
            return True
        sync_in_progress = True

    def do_sync():
        global sync_in_progress
        try:
            send("sync_progress", 0)
            log.debug(f"[SYNC] Starting background sync (mode={sync_mode}) to {settings_db}...")
            write_sync_report_to_db(
                settings_db, account_id, "In Progress", "Sync job triggered"
            )
            try:
                target_acc_id = int(account_id)
            except (ValueError, TypeError):
                target_acc_id = account_id
            accounts = get_all_accounts(settings_db)
            selected = next(
                (acc for acc in accounts if acc["id"] == target_acc_id or str(acc["id"]) == str(account_id)),
                None
            )
            send("sync_progress", 20)

            if not selected:
                write_sync_report_to_db(settings_db, account_id, "Failed", "Account not found")
                send("sync_completed", False)
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

            sync_direction = get_account_sync_settings(settings_db, account_id).get("sync_direction", "both")

            send("sync_progress", 35)
            if sync_direction != "download_only":
                log.debug("Syncing queued local changes to odoo first")
                flush_sync_queue(settings_db, account_id=account_id, client=client, ignore_backoff=True)
                sync_all_to_odoo(client, account_id, settings_db)

            send("sync_progress", 60)
            if sync_direction != "upload_only":
                log.debug("Syncing from odoo: ID Is " + selected["link"])
                sync_all_from_odoo(
                    client,
                    account_id,
                    settings_db,
                    account_name=selected.get("name", ""),
                    sync_mode=sync_mode,
                )
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


def start_sync_in_background(settings_db, account_id, sync_mode=None):
    """
    Start a background synchronization process.
    """
    if sync_mode is None:
        return sync_background(settings_db, account_id)
    return sync_background(settings_db, account_id, sync_mode=sync_mode)


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
            if acc.get("id") and acc.get("id") != 0 and acc.get("link") and not str(acc.get("link", "")).startswith("local") and acc.get("api_key"):
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


def save_push_token_background(settings_db=None, token=""):
    """
    Non-blocking wrapper around save_push_token so startup/account saves never
    block PyOtherSide's single worker thread on subprocess or network I/O.
    """
    global _push_reg_in_progress, _current_push_token, _pending_push_request

    # Normalize arguments (mirrors save_push_token)
    if not token and settings_db and isinstance(settings_db, str) and "/" not in settings_db and not settings_db.endswith(".sqlite") and not settings_db.endswith(".db"):
        token = settings_db
        settings_db = None

    if not settings_db:
        from .storage import resolve_qml_db_path
        settings_db = resolve_qml_db_path("ubtms") or "app_settings.db"

    # Persist non-empty token immediately so it is never lost even if network registration is delayed or in-progress
    if token:
        try:
            set_setting(settings_db, "push_token", token)
            log.info(f"[PUSH] Persisted push token to settings: {token[:8]}...")
        except Exception as e:
            log.warning(f"[PUSH] Failed to persist push token to settings immediately: {e}")

    with _push_reg_lock:
        if _push_reg_in_progress:
            # If a new non-empty token was provided and it differs from what is currently being registered,
            # schedule it as pending so the running worker registers it before completing.
            if token and token != _current_push_token:
                log.debug(f"[PUSH] Push registration in progress with different token, scheduling pending update for: {token[:8]}...")
                _pending_push_request = (settings_db, token)
            else:
                log.debug("[PUSH] Push registration already in progress, skipping duplicate request.")
            return True
        _push_reg_in_progress = True
        _current_push_token = token
        _pending_push_request = None

    def do_register():
        global _push_reg_in_progress, _current_push_token, _pending_push_request
        target_db = settings_db
        target_tok = token
        while True:
            try:
                save_push_token(target_db, target_tok)
            except Exception as e:
                log.warning(f"[PUSH] Background push registration failed: {e}")

            with _push_reg_lock:
                if _pending_push_request is not None:
                    target_db, target_tok = _pending_push_request
                    _pending_push_request = None
                    _current_push_token = target_tok
                else:
                    _push_reg_in_progress = False
                    _current_push_token = None
                    break

    threading.Thread(target=do_register, daemon=True).start()
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

