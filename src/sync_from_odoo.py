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
from datetime import timezone
from datetime import datetime
from common import sanitize_datetime, safe_sql_execute,add_notification
from pathlib import Path
import os
from bus import send

log = logging.getLogger("odoo_sync")


def get_record_display_name(record, model_name=None):
    """
    Get a human-readable display name for a record based on its model type.
    
    Args:
        record (dict): The record dictionary containing fields
        model_name (str): Optional model name to determine which fields to use
        
    Returns:
        str: A human-readable identifier string like "'Task Name' (id=123)"
    """
    record_id = record.get('id') or record.get('odoo_record_id') or 'unknown'
    
    # Try common name fields in order of preference
    name_fields = ['name', 'summary', 'display_name', 'title', 'subject']
    name = None
    
    for field in name_fields:
        if record.get(field):
            name = record.get(field)
            break
    
    # Build the display string
    if name:
        return f"'{name}' (id={record_id})"
    else:
        return f"id={record_id}"


def load_field_mapping(model_name, config_path="field_config.json"):
    """
    Load field mapping configuration for a specific Odoo model.
    
    Args:
        model_name (str): Name of the Odoo model to load mapping for
        config_path (str): Path to the field configuration JSON file
        
    Returns:
        dict: Field mapping dictionary where keys are Odoo field names 
              and values are SQLite field names. Returns empty dict on error.
    """
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
    """
    Determine if local record should be updated based on timestamps.
    Handles timezone normalization.
    """
    if not odoo_write_date:
        return False
    if not local_last_modified:
        return True
    try:
        # Normalize Odoo time (assume it's UTC, replace Z)
        odoo_dt = datetime.fromisoformat(odoo_write_date.replace("Z", "+00:00"))
        if odoo_dt.tzinfo is None:
            odoo_dt = odoo_dt.replace(tzinfo=timezone.utc)

        # Normalize local time (assume it's stored in UTC, or naive)
        local_dt = datetime.fromisoformat(local_last_modified.replace("Z", "+00:00"))
        if local_dt.tzinfo is None:
            local_dt = local_dt.replace(tzinfo=timezone.utc)

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
    account_name="",
):
    """
    Insert or replace a record in the local SQLite database.
    
    Args:
        table_name (str): Name of the SQLite table to insert into
        model_name (str): Name of the Odoo model for field mapping
        account_id (int): Account ID to associate with the record
        record (dict): Record data from Odoo
        db_path (str): Path to the SQLite database file
        config_path (str): Path to the field configuration JSON file
        
    Note:
        Handles data type conversion for SQLite compatibility and converts
        one2many/many2many fields to comma-separated strings. Adds notification
        on failure. Preserves local 'status' field if record has pending changes.
    """
    try:
        field_map = load_field_mapping(model_name, config_path)
        columns = []
        values = []
        record["account_id"] = account_id
        
        # Check if local record has pending changes (status = 'updated' or 'created')
        # If so, we should preserve certain local fields like 'favorites' and 'state' for activities
        odoo_record_id = record.get("id")
        existing_status = None
        existing_favorites = None
        existing_state = None  # For mail_activity_app - preserve done state
        if odoo_record_id:
            try:
                # For activities, also fetch the state field to preserve 'done' status
                if table_name == "mail_activity_app":
                    check_sql = f"SELECT status, favorites, state FROM {table_name} WHERE odoo_record_id = ? AND account_id = ?"
                else:
                    check_sql = f"SELECT status, favorites FROM {table_name} WHERE odoo_record_id = ? AND account_id = ?"
                result = safe_sql_execute(db_path, check_sql, (odoo_record_id, account_id), fetch=True, commit=False)
                if result and len(result) > 0:
                    existing_status = result[0][0]
                    existing_favorites = result[0][1]
                    if table_name == "mail_activity_app" and len(result[0]) > 2:
                        existing_state = result[0][2]
                    # DEBUG: Log activity sync decisions
                    if table_name == "mail_activity_app":
                        activity_name = record.get('summary') or '(no summary)'
                        log.info(f"[ACTIVITY_SYNC] Activity '{activity_name}' (odoo_id={odoo_record_id}): local_status={existing_status}, local_state={existing_state}, server_state={record.get('state')}")
            except Exception as e:
                log.debug(f"[DEBUG] Could not check existing status: {e}")
        
        for odoo_field, sqlite_field in field_map.items():
            val = record.get(odoo_field)

            # Convert one2many or many2many fields to comma-separated string of IDs
            # Also handles many2one fields which return [id, "name"] tuples
            if isinstance(val, list) and val:
                if all(isinstance(v, (int, int)) for v in val):
                    val = ",".join(str(v) for v in val)
                else:
                    # many2one field: [id, "name"] - extract just the ID
                    val = val[0]
                #     # Handles case like [[id, "name"], [id, "name"]] (Odoo returns tuples)
                #     val = ",".join(str(v[0]) if isinstance(v, (list, tuple)) else str(v) for v in val)

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
            
            # Preserve local favorites if there are pending changes
            if sqlite_field == "favorites" and existing_status in ("updated", "created"):
                val = existing_favorites
                log.debug(f"[PRESERVE] Keeping local favorites value: {val} (status={existing_status})")
            
            # Preserve local state for activities if there are pending changes (e.g., 'done' state)
            if sqlite_field == "state" and table_name == "mail_activity_app" and existing_status in ("updated", "created"):
                if existing_state:
                    val = existing_state
                    activity_name = record.get('summary') or '(no summary)'
                    log.info(f"[ACTIVITY_SYNC] Preserving local state='{val}' for activity '{activity_name}' (odoo_id={odoo_record_id}) - has pending changes (status={existing_status})")
            
            if sqlite_field == "account_id":
                continue  # Already manually handled
            columns.append(sqlite_field)
            values.append(val)

        # Finally, append account_id at the end
        columns.append("account_id")
        values.append(account_id)
        
        # Preserve status if there are pending changes
        if existing_status in ("updated", "created"):
            columns.append("status")
            values.append(existing_status)
            log.debug(f"[PRESERVE] Keeping local status: {existing_status}")

        placeholders = ", ".join(["?"] * len(columns))
        #log.debug(f"[INSERT] Final account_id for {table_name}: {account_id}")
        sql = f"INSERT OR REPLACE INTO {table_name} ({', '.join(columns)}) VALUES ({placeholders})"

        safe_sql_execute(db_path, sql, values)
    except Exception as e:
        display_name = get_record_display_name(record, model_name)
        error_msg = str(e)
        log.error(f"[ERROR] Failed to insert {model_name} record {display_name}: {error_msg}")
        
        # Provide additional context for common errors
        if "no such column" in error_msg.lower():
            log.error(f"[CONFIG] Database schema mismatch - local database may need migration or field_config.json update.")
        elif "constraint" in error_msg.lower():
            log.error(f"[CONFIG] Database constraint violation - check if required fields have valid values.")
        
        record_name = record.get('name') or record.get('summary') or f"Record #{record.get('id')}"
        acct_label = f" ({account_name})" if account_name else ""
        add_notification(
            db_path=db_path,
            account_id=account_id,
            notif_type="Sync",
            message=f"Failed to sync {model_name}: {record_name}{acct_label}",
            payload={"record_id": record.get("id"), "record_name": record_name, "error": error_msg, "account_name": account_name}
        )


def get_model_fields(client, model_name):
    """
    Retrieve all available fields for a specific Odoo model.
    
    Args:
        client (OdooClient): Authenticated Odoo client instance
        model_name (str): Name of the Odoo model
        
    Returns:
        list: List of field names available in the model. Returns empty list on error.
    """
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
        log.error(
            f"[ERROR] Failed to fetch fields for model '{model_name}': {e}. "
            f"Please check the model exists, is accessible, and your connection is active."
        )
        return []


def sync_model(
    client,
    model_name,
    table_name,
    account_id,
    db_path="app_settings.db",
    config_path="field_config.json",
    account_name="",
):
    """
    Synchronize a complete Odoo model with its corresponding SQLite table.
    
    Args:
        client (OdooClient): Authenticated Odoo client instance
        model_name (str): Name of the Odoo model to sync
        table_name (str): Name of the SQLite table to sync to
        account_id (int): Account ID for record association
        db_path (str): Path to the SQLite database file  
        config_path (str): Path to the field configuration JSON file
        
    Note:
        Performs complete sync including fetching records, updating local database,
        and removing orphaned records. Adds notification on failure.
    """
    log.info(f"[SYNC] Fetching '{model_name}' records from Odoo...")
    field_map = prepare_field_mapping(client, model_name, config_path)
    odoo_fields = list(field_map.keys())
    if not odoo_fields:
        log.warning(f"[WARN] No valid fields found for model '{model_name}'. Skipping sync.")
        return

    try:
        records = fetch_odoo_records(client, model_name, odoo_fields)
        log.info(f"[SYNC] Downloaded {len(records)} records for '{model_name}'.")
        fetched_odoo_ids = process_odoo_records(
            records, table_name, model_name, account_id, config_path, db_path
        )
        remove_orphaned_local_records(
            fetched_odoo_ids, table_name, model_name, account_id, db_path
        )

        log.info(f"[SYNC] Completed sync for '{model_name}' -> '{table_name}' ({len(fetched_odoo_ids)} records processed)")
    except Exception as e:
        log.error(f"[ERROR] Failed to sync model '{model_name}': {e}")
        
        # Only show notification for user-facing models, not system/technical models
        # System models like ir.model, ir.attachment are informational and not critical
        critical_models = [
            "project.project", "project.task", "account.analytic.line", 
            "mail.activity", "mail.activity.type", "res.users"
        ]
        
        if model_name in critical_models:
            # Build a contextual message with account name and brief error reason
            model_label = model_name.replace('.', ' ').title()
            error_str = str(e)
            # Extract a brief, user-friendly error reason
            if "timeout" in error_str.lower() or "timed out" in error_str.lower():
                error_brief = "Connection timed out"
            elif "connection" in error_str.lower() or "refused" in error_str.lower():
                error_brief = "Connection failed"
            elif "authentication" in error_str.lower() or "access denied" in error_str.lower() or "invalid api key" in error_str.lower():
                error_brief = "Authentication failed"
            elif "no such column" in error_str.lower():
                error_brief = "Database schema mismatch"
            elif "fault" in error_str.lower() or "xmlrpc" in error_str.lower():
                error_brief = "Server error"
            else:
                # Truncate raw error to keep notification readable
                error_brief = error_str[:80] + ("..." if len(error_str) > 80 else "")
            
            acct_label = f" on {account_name}" if account_name else ""
            add_notification(
                db_path=db_path,
                account_id=account_id,
                notif_type="Sync",
                message=f"Sync failed for {model_label}{acct_label}: {error_brief}",
                payload={"model": model_name, "error": error_str, "account_name": account_name}
            )


def prepare_field_mapping(client, model_name, config_path):
    """
    Prepare and validate field mapping for a model against available Odoo fields.
    
    Args:
        client (OdooClient): Authenticated Odoo client instance
        model_name (str): Name of the Odoo model
        config_path (str): Path to the field configuration JSON file
        
    Returns:
        dict: Validated field mapping with only fields that exist in the Odoo model
    """
    field_map = load_field_mapping(model_name, config_path)
    all_model_fields = get_model_fields(client, model_name)

    valid_field_map = {}
    missing_fields = []
    for field, sqlite_field in field_map.items():
        if field in all_model_fields:
            valid_field_map[field] = sqlite_field
        else:
            missing_fields.append(field)
    
    # If there are missing fields, provide helpful guidance in a single message
    if missing_fields:
        fields_str = ', '.join(missing_fields)
        log.warning(
            f"[CONFIG] Model '{model_name}' is missing {len(missing_fields)} field(s): {fields_str}. "
            f"Please configure these fields in your Odoo instance or install required modules, "
            f"or remove them from field_config.json if not needed."
        )
    
    return valid_field_map


def fetch_odoo_records(client, model_name, fields):
    """
    Fetch all records from an Odoo model with specified fields.
    
    Args:
        client (OdooClient): Authenticated Odoo client instance
        model_name (str): Name of the Odoo model to fetch from
        fields (list): List of field names to fetch
        
    Returns:
        list: List of record dictionaries from Odoo
        
    Note:
        Automatically includes 'id' field and 'write_date' if available in the model.
    """
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
    """
    Process fetched Odoo records and update local database based on timestamps.
    
    Args:
        records (list): List of record dictionaries from Odoo
        table_name (str): Name of the SQLite table
        model_name (str): Name of the Odoo model
        account_id (int): Account ID for record association
        config_path (str): Path to the field configuration JSON file
        db_path (str): Path to the SQLite database file
        
    Returns:
        set: Set of Odoo record IDs that were processed
        
    Note:
        Only updates local records if Odoo write_date is newer than local last_modified,
        or if last_modified column doesn't exist in the table.
    """
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
        #print(rec) #to view the record for debugging

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
                # For mail.activity, backfill resId if it's missing (migration for existing records)
                if table_name == "mail_activity_app":
                    res_model_id = rec.get("res_model_id")
                    if res_model_id and isinstance(res_model_id, list) and len(res_model_id) > 0:
                        model_id = res_model_id[0]
                        # Check if local record is missing resId
                        check_result = safe_sql_execute(
                            db_path,
                            "SELECT resId FROM mail_activity_app WHERE odoo_record_id = ? AND account_id = ?",
                            (odoo_id, account_id),
                            commit=False, fetch=True
                        )
                        if check_result and (check_result[0][0] is None or check_result[0][0] == 0 or check_result[0][0] == ''):
                            # Backfill the missing resId
                            safe_sql_execute(
                                db_path,
                                "UPDATE mail_activity_app SET resId = ? WHERE odoo_record_id = ? AND account_id = ?",
                                (model_id, odoo_id, account_id),
                                commit=True, fetch=False
                            )
                            log.info(f"[MIGRATION] Backfilled resId={model_id} for activity odoo_id={odoo_id}")
                
                log.debug(
                    f"[SKIP] {model_name} id={odoo_id} unchanged (local is newer or equal)."
                )
        else:
            insert_record(table_name, model_name, account_id, rec, db_path, config_path)
            #log.debug(f"[FORCE] {model_name} id={odoo_id} updated (no timestamp column).")

    return fetched_odoo_ids


def remove_orphaned_local_records(
    fetched_odoo_ids, table_name, model_name, account_id, db_path
):
    """
    Remove local records that no longer exist in Odoo.
    
    Args:
        fetched_odoo_ids (set): Set of Odoo record IDs that were fetched
        table_name (str): Name of the SQLite table
        model_name (str): Name of the Odoo model (for logging)
        account_id (int): Account ID to filter records
        db_path (str): Path to the SQLite database file
        
    Note:
        Deletes local records with odoo_record_id not in the fetched set,
        ensuring local database doesn't contain stale records.
        EXCEPTION: Records with status='updated' are preserved (pending local changes).
        EXCEPTION: For mail_activity_app, records with state='done' are preserved.
    """
    # Fetch all local records with odoo_record_id
    # For activities, also fetch state to preserve done activities
    if table_name == "mail_activity_app":
        rows = safe_sql_execute(
            db_path,
            f"SELECT id, odoo_record_id, status, state FROM {table_name} WHERE account_id = ? AND odoo_record_id IS NOT NULL",
            (account_id,),
            fetch=True,
            commit=False,
        )
    else:
        rows = safe_sql_execute(
            db_path,
            f"SELECT id, odoo_record_id, status FROM {table_name} WHERE account_id = ? AND odoo_record_id IS NOT NULL",
            (account_id,),
            fetch=True,
            commit=False,
        )

    for row in rows:
        local_id = row[0]
        odoo_id = row[1]
        status = row[2] if len(row) > 2 else None
        state = row[3] if len(row) > 3 else None  # Only for activities
        
        if odoo_id not in fetched_odoo_ids:
            # Skip deletion if record has pending local changes
            if status in ("updated", "created"):
                log.info(f"[SKIP_DELETE] {model_name}: local_id={local_id}, odoo_id={odoo_id} has pending local changes (status={status}) - keeping record")
                continue
            
            # Skip deletion for done activities - they were intentionally kept locally
            if table_name == "mail_activity_app" and state == "done":
                log.info(f"[SKIP_DELETE] Activity: local_id={local_id}, odoo_id={odoo_id} is marked as done - preserving for history")
                continue
                
            safe_sql_execute(
                db_path,
                f"DELETE FROM {table_name} WHERE id = ?",
                (local_id,),
                commit=True,
            )
            log.info(
                f"[DELETE] {model_name}: local_id={local_id}, odoo_id={odoo_id} removed - no longer exists on server."
            )


def sync_all_from_odoo(
    client, account_id, db_path="app_settings.db", config_path="field_config.json",
    account_name="",
):
    """
    Synchronize all configured Odoo models with their corresponding SQLite tables.
    
    Args:
        client (OdooClient): Authenticated Odoo client instance
        account_id (int): Account ID for record association
        db_path (str): Path to the SQLite database file
        config_path (str): Path to the field configuration JSON file
        
    Note:
        Syncs the following models:
        - project.project -> project_project_app
        - project.task -> project_task_app  
        - account.analytic.line -> account_analytic_line_app
        - mail.activity.type -> mail_activity_type_app
        - mail.activity -> mail_activity_app
        - res.users -> res_users_app
    """
    log.debug(f"Account id is {account_id}")

    models_to_sync = {
        "project.project": "project_project_app",
        "project.task": "project_task_app",
        "account.analytic.line": "account_analytic_line_app",
        "mail.activity.type": "mail_activity_type_app",
        "mail.activity": "mail_activity_app",
        "res.users": "res_users_app",
        "ir.model":"ir_model_app",
        "project.update":"project_update_app",
        "project.task.type":"project_task_type_app",
        "project.project.stage":"project_project_stage_app",
        "ir.attachment":"ir_attachment_app",
    }

    # Dont do this , too heavy
    """
    models_to_sync = {
        "ir.attachment":"ir_attachment_app",
    }
    """
    for model, table in models_to_sync.items():
        send("sync_message",f"Syncing from Server {model}")
        sync_model(client, model, table, account_id, db_path, config_path, account_name=account_name)



def sync_ondemand_tables_from_odoo(
    client, account_id, db_path="app_settings.db", config_path="field_config.json",
    account_name="",
):
    """
    Synchronize all configured Odoo models with their corresponding SQLite tables.

    Args:
        client (OdooClient): Authenticated Odoo client instance
        account_id (int): Account ID for record association
        db_path (str): Path to the SQLite database file
        config_path (str): Path to the field configuration JSON file

    Note:
        Syncs the following models:
        - project.project -> project_project_app
        - project.task -> project_task_app
        - account.analytic.line -> account_analytic_line_app
        - mail.activity.type -> mail_activity_type_app
        - mail.activity -> mail_activity_app
        - res.users -> res_users_app
    """
    log.debug(f"Account id is {account_id}")
    models_to_sync = {
        "ir.attachment":"ir_attachment_app",
    }

    for model, table in models_to_sync.items():
        sync_model(client, model, table, account_id, db_path, config_path, account_name=account_name)
