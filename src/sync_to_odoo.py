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


import json
import sqlite3
import logging
from odoo_client import OdooClient
from common import sanitize_datetime, safe_sql_execute
from pathlib import Path
from datetime import datetime
import os

log = logging.getLogger("odoo_sync")


def load_field_mapping(model_name, config_path="field_config.json"):
    try:
        current_dir = Path(__file__).parent.resolve()
        full_path = current_dir / config_path
        with open(full_path, "r") as f:
            mapping = json.load(f)
        return mapping.get(model_name, {})
    except Exception as e:
        log.debug(
            f"[ERROR] Failed to load field mapping for '{model_name}' at {full_path}: {e}"
        )
        try:
            files = os.listdir(current_dir)
            log.debug(f"[DEBUG] Contents of {current_dir}: {files}")
        except Exception as dir_err:
            log.debug(f"[ERROR] Failed to list contents of {current_dir}: {dir_err}")
        return {}


def get_local_records(
    table_name,
    model_name,
    account_id,
    db_path="app_settings.db",
    config_path="field_config.json",
):
    field_map = load_field_mapping(model_name, config_path)
    sqlite_fields = list(field_map.values())

    try:
        fields = ["id"] + sqlite_fields + ["status", "odoo_record_id"]
        query = f"SELECT {', '.join(fields)} FROM {table_name} WHERE account_id = ?"
        rows = safe_sql_execute(db_path, query, (account_id,), fetch=True, commit=False)
        records = (
            [dict(zip(fields, row)) for row in rows] if rows else []
        )
        return records
    except Exception as e:
        log.error(f"[ERROR] Failed to fetch local records from '{table_name}': {e}")
        return []



def fetch_odoo_field_info(client, model_name):
    try:
        return client.call(model_name, "fields_get", [], {"attributes": ["type"]})
    except Exception as e:
        log.error(f"[ERROR] Could not fetch field types for {model_name}: {e}")
        return {}


def parse_local_value(field_type, value):
    if field_type == "many2one":
        return int(value) if value else False
    elif field_type == "many2many":
        if isinstance(value, str):
            try:
                ids = [int(x.strip()) for x in value.split(",") if x.strip().isdigit()]
                return [(6, 0, ids)]
            except Exception:
                return [(6, 0, [])]
        elif isinstance(value, list):
            return [(6, 0, value)]
        elif isinstance(value, int):
            return [(6, 0, [value])]
        else:
            return [(6, 0, [])]
    elif field_type in ["datetime", "date"]:
        return sanitize_datetime(value)
    else:
        return value


def should_push_field(local_val, remote_val, local_ts, remote_ts):
    log.debug(
        f"[COMPARE] Value comparison: local='{local_val}' vs remote='{remote_val}' | "
        f"Timestamps: local_ts='{local_ts}', remote_ts='{remote_ts}'"
    )

    if local_val == remote_val:
        # log.debug("[COMPARE] No change in value — skipping sync.")
        return False

    if not remote_ts:
        # log.debug("[COMPARE] Remote timestamp missing — syncing.")
        return True

    if not local_ts:
        # log.debug("[COMPARE] Local timestamp missing — skipping sync.")
        return False

    if local_val is None and remote_val is False:
        log.debug("[COMPARE] Local is None, remote is False — syncing anyway.")
        return True

    try:
        local_dt = datetime.fromisoformat(local_ts)
        remote_dt = datetime.fromisoformat(remote_ts.replace("Z", "+00:00"))

        if local_dt >= remote_dt:
            log.debug(
                f"[COMPARE] Local record is newer — syncing. Local:{local_val} Remote:{remote_val}"
            )
            return True
        else:
            log.debug(
                f"[COMPARE] Remote record is newer — skipping sync. Local:{local_val} Remote:{remote_val}"
            )
            return False
    except Exception as e:
        log.warning(
            f"[COMPARE] Failed to parse timestamps — syncing by default. Error: {e}"
        )
        return True


def construct_changes(field_map, field_info, record, existing_data):
    changes = {}
    remote_write_date = existing_data.get("write_date")
    local_last_modified = record.get("last_modified")

    log.debug(f"[DEBUG] Starting construct_changes for record id={record['id']}")
    log.debug(f"[DEBUG] Comparing fields: {list(field_map.items())}")

    for odoo_field, sqlite_field in field_map.items():
        if odoo_field not in field_info:
            log.debug(f"[SKIP] Field '{odoo_field}' not found in field_info.")
            continue

        if not sqlite_field:
            log.warning(f"[SKIP] sqlite_field is None for '{odoo_field}' — skipping.")
            continue

        try:
            local_val = record.get(sqlite_field)
            remote_val = existing_data.get(odoo_field)
            field_type = field_info[odoo_field]["type"]

            log.debug(f"[DEBUG] Checking field: {odoo_field} ←→ {sqlite_field}")
            log.debug(f"[DEBUG] Local={local_val}, Remote={remote_val}, Type={field_type}")

            parsed_val = parse_local_value(field_type, local_val)

            if should_push_field(parsed_val, remote_val, local_last_modified, remote_write_date):
                changes[odoo_field] = parsed_val

        except Exception as e:
            log.error(f"[ERROR] Failed to compare field '{odoo_field}': {e}")

    return changes



def push_record_to_odoo(client, model_name, record, config_path="field_config.json"):
    field_map = load_field_mapping(model_name, config_path)
    field_info = fetch_odoo_field_info(client, model_name)

    for field in field_map.keys():
        if field not in field_info:
            log.warning(
                f"[WARN] Field '{field}' not found in Odoo model '{model_name}', skipping."
            )

    if record.get("odoo_record_id"):
        try:
            valid_fields = [f for f in field_map.keys() if f in field_info]
            if "write_date" in field_info:
                valid_fields.append("write_date")

            # log.debug(f"[READ] Reading fields from Odoo: {valid_fields}")
            existing = client.call(
                model_name,
                "read",
                [[record["odoo_record_id"]]],
                {"fields": valid_fields},
            )
            if not existing:
                log.warning(
                    f"[SKIP] No record found in Odoo for ID {record['odoo_record_id']}."
                )
                return None

            existing_data = existing[0]
            changes = construct_changes(field_map, field_info, record, existing_data)

            if changes:
                client.call(model_name, "write", [[record["odoo_record_id"]], changes])
                log.debug(
                    f"[UPDATE] {model_name} id={record['odoo_record_id']} updated with merged fields."
                )
                safe_sql_execute(
                    record["db_path"],
                    f"UPDATE {record['table_name']} SET status = '' WHERE id = ? AND account_id = ?",
                    (record["id"], record["account_id"])
                )
                log.debug(f"[SYNC] Reset status for {model_name} id={record['id']} after update.")

            # else:
            #    log.debug(f"[SKIP] No changes for {model_name} id={record['odoo_record_id']}.")
            return record["odoo_record_id"]

        except Exception as e:
            log.error(
                f"[ERROR] Failed to merge/update record to Odoo '{model_name}': {e}"
            )
            return None

    else:
        SKIP_FIELDS = {"last_update_status"}  # you can add others here later

        odoo_data = {}
        for odoo_field, sqlite_field in field_map.items():
            if odoo_field not in field_info or odoo_field in SKIP_FIELDS:
                continue

            raw_val = record.get(sqlite_field)
            parsed_val = parse_local_value(field_info[odoo_field]["type"], raw_val)
            odoo_data[odoo_field] = parsed_val

        try:
            new_id = client.call(model_name, "create", [odoo_data])
            log.debug(f"[CREATE] {model_name} new record created with id={new_id}.")

            safe_sql_execute(
                record["db_path"],
                f"UPDATE {record['table_name']} SET odoo_record_id = ?, status = '' WHERE id = ? AND account_id = ?",
                (new_id, record["id"], record["account_id"])
            )
            log.debug(f"[SYNC] Reset status for {model_name} id={record['id']} after creation.")


            return new_id

        except Exception as e:
            log.error(f"[ERROR] Failed to create record in Odoo '{model_name}': {e} , Record is below")
            log.error(json.dumps(record, indent=2))
            return None

def normalized_status(record):
    return (record.get("status") or "").strip().lower()

def sync_to_odoo(
    client,
    model_name,
    table_name,
    account_id,
    db_path="app_settings.db",
    config_path="field_config.json",
):
    all_records = get_local_records(
        table_name, model_name, account_id, db_path, config_path
    )

    local_records = [r for r in all_records if normalized_status(r) == "updated"]
    deleted_records = [r for r in all_records if normalized_status(r) == "deleted"]

    local_ids = {
        record["odoo_record_id"]
        for record in all_records
        if record.get("odoo_record_id") and normalized_status(record) != "deleted"
    }

    try:
        odoo_ids = set(client.call(model_name, "search", [[]]))
    except Exception as e:
        log.error(f"[ERROR] Failed to fetch existing Odoo IDs for {model_name}: {e}")
        odoo_ids = set()

    # Handle explicitly deleted records
    for record in deleted_records:
        try:
            if record.get("odoo_record_id"):
                client.call(model_name, "unlink", [[record["odoo_record_id"]]])
                log.debug(f"[DELETE] {model_name} id={record['odoo_record_id']} deleted from Odoo.")
        except Exception as e:
            if "does not exist or has been deleted" in str(e):
                log.warning(f"[SKIP] {model_name} id={record['odoo_record_id']} already deleted on Odoo.")
            else:
                log.error(f"[ERROR] Failed to delete {model_name} id={record.get('odoo_record_id')}: {e}")
                return  # Exit early — don’t delete locally

        # ✅ Always delete locally if we're here
        safe_sql_execute(
            db_path,
            f"DELETE FROM {table_name} WHERE id = ?",
            (record["id"],)
        )
        log.debug(f"[CLEANUP] Local record removed: {table_name} id={record['id']}")

    for record in local_records:
        record["db_path"] = db_path
        record["table_name"] = table_name
        record["account_id"] = account_id
        push_record_to_odoo(client, model_name, record, config_path)

    log.info(
        f"[SYNC] {model_name}: {len(local_records)} updated, {len(deleted_records)} deleted."
    )


def sync_all_to_odoo(
    client, account_id, db_path="app_settings.db", config_path="field_config.json"
):
    """ We do not support Project Creation , Deletion or Updation Thats why disabled this.
    models = {
        "project.project": "project_project_app",
        "project.task": "project_task_app",
        "account.analytic.line": "account_analytic_line_app",
        "mail.activity.type": "mail_activity_type_app",
        "mail.activity": "mail_activity_app",
        "res.users": "res_users_app",
    }
    """

    models = {
        "project.project": "project_project_app",
        "project.task": "project_task_app",
        "account.analytic.line": "account_analytic_line_app",
    }


    for model, table in models.items():
        log.info(f"[SYNC] Syncing from SQLite to Odoo: {model} -> {table}")
        sync_to_odoo(client, model, table, account_id, db_path, config_path)
