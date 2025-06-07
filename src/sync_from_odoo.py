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
from xmlrpc.client import ServerProxy
from odoo_client import OdooClient
import logging
from datetime import datetime
from common import sanitize_datetime, safe_sql_execute
from pathlib import Path

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
        # List all files in the directory
        try:
            files = os.listdir(current_dir)
            log.debug(f"[DEBUG] Contents of {current_dir}: {files}")
        except Exception as dir_err:
            log.debug(f"[ERROR] Failed to list contents of {current_dir}: {dir_err}")
        return {}


def should_update_local(odoo_write_date: str, local_last_modified: str) -> bool:
    if not odoo_write_date:
        return False
    if not local_last_modified:
        return True
    try:
        odoo_dt = datetime.fromisoformat(odoo_write_date.replace("Z", "+00:00"))
        local_dt = datetime.fromisoformat(local_last_modified)
        return odoo_dt > local_dt
    except Exception as e:
        log.warning(f"[WARN] Failed to compare timestamps: {e}")
        return True


def insert_record(
    table_name,
    model_name,
    account_id,
    record,
    db_path="app_settings.db",
    config_path="field_config.json",
):
    try:
        field_map = load_field_mapping(model_name, config_path)
        columns = []
        values = []
        record["account_id"] = account_id
        for odoo_field, sqlite_field in field_map.items():
            val = record.get(odoo_field)

            # Flatten one2many or many2many to first element
            if isinstance(val, list) and val and isinstance(val[0], (int, float)):
                val = val[0]

            # Convert boolean to integer (SQLite doesn't support bool)
            if isinstance(val, bool):
                val = int(val)

            # Ensure datetime is stored in ISO format if it's a datetime object
            if isinstance(val, datetime):
                val = val.isoformat()

            # Convert None or unexpected types to safe defaults
            if val is None:
                val = None
            elif isinstance(val, (int, float, str)):
                pass  # allowed types
            else:
                try:
                    val = str(val)  # fallback (for fields like selection or state)
                except Exception as e:
                    log.warning(f"[WARN] Unable to convert field {odoo_field}: {e}")
                    val = None
            if sqlite_field == "account_id":
                continue  # Already manually handled
            columns.append(sqlite_field)
            values.append(val)

        # Finally, append account_id at the end
        columns.append("account_id")
        values.append(account_id)

        placeholders = ", ".join(["?"] * len(columns))
        log.debug(f"[INSERT] Final account_id for {table_name}: {account_id}")
        sql = f"INSERT OR REPLACE INTO {table_name} ({', '.join(columns)}) VALUES ({placeholders})"

        safe_sql_execute(db_path, sql, values)
    except Exception as e:
        log.debug(f"[ERROR] Failed to insert record into '{table_name}': {e}")
        exit(1)  # for testing


def get_model_fields(client, model_name):
    try:
        return client.models.execute_kw(
            client.db,
            client.uid,
            client.password,
            model_name,
            "fields_get",
            [],
            {"attributes": ["string", "type"]},
        ).keys()
    except Exception as e:
        log.debug(f"[ERROR] Failed to fetch fields for model '{model_name}': {e}")
        return []


def sync_model(
    client,
    model_name,
    table_name,
    account_id,
    db_path="app_settings.db",
    config_path="field_config.json",
):
    log.debug(f"[INFO] Fetching '{model_name}' records from Odoo...")
    field_map = prepare_field_mapping(client, model_name, config_path)
    odoo_fields = list(field_map.keys())
    if not odoo_fields:
        log.debug(f"No valid fields found for model '{model_name}'. Skipping.")
        return

    try:
        records = fetch_odoo_records(client, model_name, odoo_fields)
        log.debug(f"[INFO] {len(records)} records fetched for model '{model_name}'.")
        # conn = sqlite3.connect(db_path)
        # cur = conn.cursor()

        fetched_odoo_ids = process_odoo_records(
            records, table_name, model_name, account_id, config_path, db_path
        )
        remove_orphaned_local_records(
            fetched_odoo_ids, table_name, model_name, account_id, db_path
        )

        # conn.commit()
        # conn.close()
        log.debug(f"Synced '{model_name}' to table '{table_name}' with deletion check.")
    except Exception as e:
        log.debug(f"[ERROR] Failed to sync model '{model_name}': {e}")


def prepare_field_mapping(client, model_name, config_path):
    field_map = load_field_mapping(model_name, config_path)
    all_model_fields = get_model_fields(client, model_name)

    valid_field_map = {}
    for field, sqlite_field in field_map.items():
        if field in all_model_fields:
            valid_field_map[field] = sqlite_field
        else:
            log.warning(
                f"[WARN] Field '{field}' not found in Odoo model '{model_name}', skipping."
            )
    return valid_field_map


def fetch_odoo_records(client, model_name, fields):
    # Ensure we include 'id' (safe for all), but 'write_date' only if it's valid
    model_fields = get_model_fields(client, model_name)
    safe_fields = list(fields)
    log.debug(f"[FETCH] {model_name} fetching fields: {safe_fields}")

    if "id" not in safe_fields:
        safe_fields.append("id")
    if "write_date" in model_fields and "write_date" not in safe_fields:
        safe_fields.append("write_date")

    return client.models.execute_kw(
        client.db,
        client.uid,
        client.password,
        model_name,
        "search_read",
        [[]],
        {"fields": safe_fields},
    )


def process_odoo_records(
    records, table_name, model_name, account_id, config_path, db_path
):
    fetched_odoo_ids = set()

    # Check once if 'last_modified' column exists in the table using PRAGMA
    pragma_result = safe_sql_execute(
        db_path, f"PRAGMA table_info({table_name})", commit=False, fetch=True
    )
    columns = [row[1] for row in pragma_result]
    has_last_modified = "last_modified" in columns

    for rec in records:
        odoo_id = rec["id"]
        fetched_odoo_ids.add(odoo_id)

        if has_last_modified:
            # Read last_modified from local DB
            row = safe_sql_execute(
                db_path,
                f"SELECT last_modified FROM {table_name} WHERE odoo_record_id = ? AND account_id = ?",
                (odoo_id, account_id),
                commit=False,
                fetch=True,
            )
            local_last_modified = row[0][0] if row else None
            odoo_write_date = rec.get("write_date")

            if should_update_local(odoo_write_date, local_last_modified):
                insert_record(
                    table_name, model_name, account_id, rec, db_path, config_path
                )
            else:
                log.debug(
                    f"[SKIP] {model_name} id={odoo_id} unchanged (local is newer or equal)."
                )
        else:
            insert_record(table_name, model_name, account_id, rec, db_path, config_path)
            log.debug(
                f"[FORCE] {model_name} id={odoo_id} updated (no timestamp column)."
            )

    return fetched_odoo_ids


def remove_orphaned_local_records(
    fetched_odoo_ids, table_name, model_name, account_id, db_path
):
    # Fetch all local records with odoo_record_id
    rows = safe_sql_execute(
        db_path,
        f"SELECT id, odoo_record_id FROM {table_name} WHERE account_id = ? AND odoo_record_id IS NOT NULL",
        (account_id,),
        fetch=True,
        commit=False,
    )

    for local_id, odoo_id in rows:
        if odoo_id not in fetched_odoo_ids:
            safe_sql_execute(
                db_path,
                f"DELETE FROM {table_name} WHERE id = ?",
                (local_id,),
                commit=True,
            )
            log.debug(
                f"[DELETE] {model_name} local id={local_id} (odoo_id={odoo_id}) removed; not found in Odoo."
            )


def sync_all_from_odoo(
    client, account_id, db_path="app_settings.db", config_path="field_config.json"
):
    log.debug(f"Account id is {account_id}")

    models_to_sync = {
        "project.project": "project_project_app",
        "project.task": "project_task_app",
        "account.analytic.line": "account_analytic_line_app",
        "mail.activity.type": "mail_activity_type_app",
        "mail.activity": "mail_activity_app",
        "res.users": "res_users_app",
    }

    # Dont do this , for testing indiviudal model
    """
    models_to_sync = {
        "project.task": "project_task_app",
    }
    """
    for model, table in models_to_sync.items():
        sync_model(client, model, table, account_id, db_path, config_path)
