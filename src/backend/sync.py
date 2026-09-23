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

from bus import send
from common import write_sync_report_to_db
from config import get_all_accounts, update_last_synced_at
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
