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


from config import get_all_accounts, initialize_app_settings_db
from odoo_client import OdooClient
from sync_from_odoo import sync_all_from_odoo
from sync_to_odoo import sync_all_to_odoo
from logger import setup_logger

log = setup_logger()
import os
from pathlib import Path
import platform
import urllib3
import json
import xmlrpc.client
from common import check_table_exists, write_sync_report_to_db
import threading

sync_lock = threading.Lock()
sync_in_progress = False  # Global flag

urllib3.disable_warnings()

http = urllib3.PoolManager(cert_reqs="CERT_NONE")


def is_file_present(file_path):
    file = Path(file_path)
    if file.exists() and file.is_file():
        log.error(f"[INFO] File exists: {file_path}")
        return True
    else:
        log.error(f"[ERROR] File NOT found: {file_path}")
        return False


def resolve_qml_db_path(app_id="ubtms"):

    db_paths = []
    current_dir = Path(__file__).parent.resolve()

    # Real user home, e.g., /home/gokul
    user_home = Path.home()
    db_paths.append(user_home / ".local" / "share" / app_id / "Databases")

    # Clickable sandbox, e.g., /home/gokul/.clickable/home/
    clickable_home = user_home / ".clickable" / "home"
    db_paths.append(clickable_home / ".local" / "share" / app_id / "Databases")

    for db_dir in db_paths:
        log.debug(f"[DEBUG] Checking DB path: {db_dir}")
        if not db_dir.exists():
            continue

        sqlite_files = list(db_dir.glob("*.sqlite"))
        if sqlite_files:
            latest = max(sqlite_files, key=lambda f: f.stat().st_mtime)
            log.debug(f"[INFO] Found QML DB: {latest}")
            if is_file_present(latest):
                log.debug(f"file is present {latest}")
                if check_table_exists(latest, "project_project_app"):
                    log.debug(
                        f"project_project_app present,confirms that {latest} app db"
                    )
                    return str(latest)
                else:
                    log.critical(f"SQlite file found , but do not see a table")

    log.debug("[ERROR] No QML DB found.")
    return None


def fetch_databases(url):
    """Get and identify the database while on the create account page."""
    database_list = get_db_list(url)
    visibility_dict = {
        "menu_items": False,
        "text_field": False,
        "single_db": False,
    }

    if not database_list:
        visibility_dict["text_field"] = True
    elif len(database_list) == 1:
        visibility_dict["single_db"] = database_list[0]
    else:
        visibility_dict["menu_items"] = database_list

    return database_list


def login_odoo(selected_url, username, password, selected_db):
    """To check whether login is successful or not."""
    common = xmlrpc.client.ServerProxy("{}/xmlrpc/2/common".format(selected_url))
    generated_uid = common.authenticate(selected_db, username, password, {})
    if generated_uid:
        models = xmlrpc.client.ServerProxy(
            "{}/xmlrpc/2/object".format(selected_url),
        )
        user_name = models.execute_kw(
            selected_db,
            generated_uid,
            password,
            "res.users",
            "read",
            [generated_uid],
            {"fields": ["name"]},
        )
        return {
            "status": "pass",
            "name_of_user": user_name[0]["name"],
            "database": selected_db,
            "uid": generated_uid,
        }
    return {"result": "fail"}


def get_db_list(url):
    """To fetch database list from Odoo."""
    try:
        response = http.request(
            "POST",
            url + "/web/database/list",
            body="{}",
            headers={"Content-type": "application/json"},
        )
        if response.status == 200:
            data = json.loads(response.data)
            return data["result"]
        else:
            return []
    except Exception as e:
        log.error(f"[Critical] No DB found {e}")
        return []
    return []


def sync(settings_db, account_id):
    write_sync_report_to_db(
        settings_db, account_id, "In Progress", "Sync job triggered"
    )
    # initialize_app_settings_db(settings_db) done by js
    accounts = get_all_accounts(settings_db)
    selected = accounts[account_id]
    client = OdooClient(
        selected["link"],
        selected["database"],
        selected["username"],
        selected["api_key"],
    )
    log.debug("Syncing from oddo from server" + selected["link"])
    sync_all_from_odoo(client, selected["id"], settings_db)

    log.debug("Syncing to odoo")
    sync_all_to_odoo(client, selected["id"], settings_db)

    write_sync_report_to_db(
        settings_db, account_id, "Successful", "Sync completed successfully"
    )
    return True


def sync_background(settings_db, account_id):
    global sync_in_progress

    with sync_lock:
        if sync_in_progress:
            log.debug("[SYNC] Already in progress. Ignoring new request.")
            return False
        sync_in_progress = True

    def do_sync():
        global sync_in_progress
        try:
            log.debug(f"[SYNC] Starting background sync to {settings_db}...")
            write_sync_report_to_db(
                settings_db, account_id, "In Progress", "Sync job triggered"
            )
            # initialize_app_settings_db(settings_db) , done by js
            accounts = get_all_accounts(settings_db)
            selected = next((acc for acc in accounts if acc["id"] == account_id), None)

            if not selected:
                write_sync_report_to_db(settings_db, account_id, "Failed", "Account not found")
                return

            # Proceed with syncing using `account`
            log.debug(f"[SYNC] Found account: {selected['name']} (ID: {selected['id']})")


            client = OdooClient(
                selected["link"],
                selected["database"],
                selected["username"],
                selected["api_key"],
            )
            log.debug("Syncing from oddo : ID Is " + selected["link"])
            sync_all_from_odoo(client, account_id, settings_db)

            log.debug("Syncing to odoo")
            sync_all_to_odoo(client, account_id, settings_db)

            log.debug("[SYNC] Background sync completed.")
            write_sync_report_to_db(
                settings_db,
                account_id,
                "Successful",
                "Sync completed successfully",
            )
        except Exception as e:
            log.exception(f"[SYNC] Error during background sync: {e}")
            write_sync_report_to_db(settings_db, account_id, "Failed", str(e))
        finally:
            with sync_lock:
                sync_in_progress = False

    thread = threading.Thread(target=do_sync)
    thread.start()
    return True  # Return immediately so QML doesn’t wait


def start_sync_in_background(settings_db, account_id):
    return sync_background(settings_db, account_id)
