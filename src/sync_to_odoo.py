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
from common import sanitize_datetime, safe_sql_execute,add_notification
from pathlib import Path
from datetime import datetime
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
    odoo_id = record.get('odoo_record_id')
    
    # Try common name fields in order of preference
    name_fields = ['name', 'summary', 'display_name', 'title', 'subject']
    name = None
    
    for field in name_fields:
        if record.get(field):
            name = record.get(field)
            break
    
    # Build the display string
    if name and odoo_id:
        return f"'{name}' (local_id={record_id}, odoo_id={odoo_id})"
    elif name:
        return f"'{name}' (id={record_id})"
    elif odoo_id:
        return f"id={record_id}, odoo_id={odoo_id}"
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
              
    Note:
        Reads from JSON configuration file in the same directory as the script.
        Lists directory contents on error for debugging purposes.
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
        try:
            files = os.listdir(current_dir)
            log.debug(f"[DEBUG] Contents of {current_dir}: {files}")
        except Exception as dir_err:
            log.debug(f"[ERROR] Failed to list contents of {current_dir}: {dir_err}")
        return {}


def get_res_model_id(db_path, account_id, res_model):
    """
    Look up the Odoo model ID (res_model_id) from the ir_model_app table.
    
    Args:
        db_path (str): Path to SQLite database file
        account_id: Account ID to filter by
        res_model (str): The technical model name (e.g., "project.task", "sale.order")
        
    Returns:
        int or None: The odoo_record_id from ir_model_app if found, None otherwise
    """
    if not res_model:
        return None
    
    try:
        # Ensure account_id is an integer (it might be a float like 3.0)
        account_id_int = int(account_id) if account_id is not None else None
        
        query = "SELECT odoo_record_id FROM ir_model_app WHERE account_id = ? AND technical_name = ?"
        rows = safe_sql_execute(db_path, query, (account_id_int, res_model), fetch=True, commit=False)
        
        if rows and len(rows) > 0:
            log.debug(f"[ACTIVITY] Found res_model_id={rows[0][0]} for model '{res_model}' in account {account_id_int}")
            return rows[0][0]
        
        # Debug: List available models in this account
        debug_query = "SELECT technical_name, odoo_record_id FROM ir_model_app WHERE account_id = ? LIMIT 20"
        debug_rows = safe_sql_execute(db_path, debug_query, (account_id_int,), fetch=True, commit=False)
        if debug_rows:
            available_models = [row[0] for row in debug_rows if row[0]]
            log.debug(f"[DEBUG] Available models in account {account_id_int}: {available_models[:10]}...")
        else:
            log.warning(f"[WARN] No ir.model records found for account {account_id_int}. Run sync from Odoo first.")
        
        return None
    except Exception as e:
        log.warning(f"[WARN] Failed to look up res_model_id for '{res_model}': {e}")
        return None


def cleanup_corrupted_activities(db_path, account_id):
    """
    Remove corrupted/orphaned activity records that cannot be synced to Odoo.
    
    Corrupted activities are those with:
    - NULL or empty resModel (not linked to any document type)
    - NULL, empty, or <= 0 link_id (not linked to a specific document)
    - No odoo_record_id (never synced) - we only clean up local-only records
    
    Args:
        db_path (str): Path to SQLite database file
        account_id: Account ID to filter by
        
    Returns:
        int: Number of records cleaned up
    """
    try:
        account_id_int = int(account_id) if account_id is not None else None
        
        # First, count how many corrupted records exist
        count_query = """
            SELECT COUNT(*) FROM mail_activity_app 
            WHERE account_id = ? 
            AND odoo_record_id IS NULL
            AND (
                resModel IS NULL 
                OR resModel = '' 
                OR link_id IS NULL 
                OR link_id <= 0
            )
        """
        count_result = safe_sql_execute(db_path, count_query, (account_id_int,), fetch=True, commit=False)
        corrupted_count = count_result[0][0] if count_result else 0
        
        if corrupted_count == 0:
            log.debug(f"[CLEANUP] No corrupted activities found for account {account_id_int}")
            return 0
        
        # Get details of corrupted records for logging
        detail_query = """
            SELECT id, summary, resModel, link_id FROM mail_activity_app 
            WHERE account_id = ? 
            AND odoo_record_id IS NULL
            AND (
                resModel IS NULL 
                OR resModel = '' 
                OR link_id IS NULL 
                OR link_id <= 0
            )
        """
        corrupted_records = safe_sql_execute(db_path, detail_query, (account_id_int,), fetch=True, commit=False)
        
        for record in corrupted_records:
            summary = record[1] or '(no summary)'
            res_model = record[2] or '(not linked to any model)'
            link_id = record[3]
            link_issue = "not linked to any document" if not link_id or link_id <= 0 else f"linked to {res_model} id={link_id}"
            log.warning(f"[CLEANUP] Removing corrupted activity: '{summary}' (id={record[0]}) - Issue: {link_issue}")
        
        # Delete the corrupted records
        delete_query = """
            DELETE FROM mail_activity_app 
            WHERE account_id = ? 
            AND odoo_record_id IS NULL
            AND (
                resModel IS NULL 
                OR resModel = '' 
                OR link_id IS NULL 
                OR link_id <= 0
            )
        """
        safe_sql_execute(db_path, delete_query, (account_id_int,))
        
        log.info(f"[CLEANUP] Removed {corrupted_count} corrupted activity records for account {account_id_int}")
        return corrupted_count
        
    except Exception as e:
        log.error(f"[ERROR] Failed to cleanup corrupted activities: {e}")
        return 0


def get_local_records(
    table_name,
    model_name,
    account_id,
    db_path="app_settings.db",
    config_path="field_config.json",
):
    """
    Retrieve local records from SQLite database for a specific table and account.
    
    Args:
        table_name (str): Name of the SQLite table to query
        model_name (str): Name of the Odoo model (for field mapping)
        account_id: Account ID to filter records by
        db_path (str): Path to SQLite database file
        config_path (str): Path to field configuration JSON file
        
    Returns:
        list: List of records (dictionaries) from the local SQLite table
               Returns empty list on error
               
    Note:
        Joins the 'id' field, mapped fields from field_config, 'status', and 'odoo_record_id'.
        Filters records by account_id.
    """
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
        add_notification(
            db_path=db_path,
            account_id=account_id,
            notif_type="Sync",
            message=f"Failed to fetch local records from '{table_name}'",
            payload={}
        )
        return []



def fetch_odoo_field_info(client, model_name):
    """
    Fetch field information from an Odoo model.
    
    Args:
        client: OdooClient instance for making API calls
        model_name (str): Name of the Odoo model to fetch field info for
        
    Returns:
        dict: Dictionary containing field information with field types.
              Returns empty dict on error.
              
    Note:
        Uses the fields_get method to retrieve field attributes,
        specifically the 'type' attribute for each field.
    """
    try:
        return client.call(model_name, "fields_get", [], {"attributes": ["type"]})
    except Exception as e:
        log.error(
            f"[ERROR] Could not fetch field types for model '{model_name}': {e}. "
            f"Please verify the model exists, you have access rights, and required modules are installed."
        )
        return {}


def parse_local_value(field_type, value):
    """
    Parse and convert local SQLite values to Odoo-compatible format.
    
    Args:
        field_type (str): The Odoo field type (e.g., 'many2one', 'many2many', 'datetime')
        value: The raw value from SQLite database
        
    Returns:
        Converted value appropriate for the Odoo field type.
        - many2one: Returns int or False
        - many2many: Returns list in format [(6, 0, [ids])]
        - datetime/date: Returns sanitized datetime string
        - other: Returns original value
        
    Note:
        Handles various input formats for many2many fields including
        comma-separated strings, lists, and single integers.
    """
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
    elif field_type == "selection":
        # Odoo selection fields expect the selection key (usually a string).
        # Convert numeric local values to string keys to avoid ValueError on create/write.
        try:
            if value is None:
                return None
            # Preserve existing string values
            if isinstance(value, str):
                return value
            # Convert ints/floats to string representation
            if isinstance(value, (int, float)):
                return str(int(value))
            # Fallback to string conversion
            return str(value)
        except Exception:
            return str(value)
    else:
        return value


def should_push_field(local_val, remote_val, local_ts, remote_ts):
    """
    Determine if a field should be synchronized based on value and timestamp comparison.
    
    Args:
        local_val: Value from local SQLite database
        remote_val: Value from remote Odoo instance
        local_ts (str): Local record's last modified timestamp
        remote_ts (str): Remote record's write_date timestamp
        
    Returns:
        bool: True if the field should be pushed to Odoo, False otherwise
        
    Logic:
        - Skip if values are identical
        - Push if remote timestamp is missing
        - Skip if local timestamp is missing
        - Handle None vs False comparison specially
        - Compare timestamps to determine which is newer
        - Default to pushing on timestamp parsing errors
    """
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


def sync_project_favorite(client, record, db_path):
    """
    Sync project favorite status to Odoo by manipulating favorite_user_ids.
    
    In Odoo, is_favorite is a computed field based on whether the current user
    is in the favorite_user_ids many2many field. To toggle favorite, we need
    to add/remove the current user from favorite_user_ids.
    
    Args:
        client: OdooClient instance for making API calls
        record (dict): Local project record containing 'favorites' and 'odoo_record_id'
        db_path (str): Path to SQLite database file
        
    Returns:
        bool: True if sync successful, False otherwise
    """
    try:
        odoo_record_id = record.get("odoo_record_id")
        local_favorite = record.get("favorites")
        
        if not odoo_record_id:
            log.debug("[SKIP] No odoo_record_id for project favorite sync")
            return False
        
        # Convert local favorite value to boolean
        is_local_favorite = bool(local_favorite) if local_favorite is not None else False
        
        # Read current state from Odoo
        existing = client.call(
            "project.project",
            "read",
            [[odoo_record_id]],
            {"fields": ["is_favorite", "favorite_user_ids"]},
        )
        
        if not existing:
            project_name = record.get('name') or '(unknown project)'
            log.warning(f"[SKIP] Project '{project_name}' (odoo_id={odoo_record_id}) not found in Odoo")
            return False
        
        existing_data = existing[0]
        remote_is_favorite = existing_data.get("is_favorite", False)
        project_name = record.get('name') or existing_data.get('name') or '(unknown project)'
        
        log.debug(f"[FAVORITE] Project '{project_name}' (odoo_id={odoo_record_id}): local_favorite={is_local_favorite}, remote_favorite={remote_is_favorite}")
        
        # Only sync if there's a difference
        if is_local_favorite == remote_is_favorite:
            log.debug(f"[SKIP] Favorite status already in sync for project '{project_name}' (odoo_id={odoo_record_id})")
            return True
        
        # Get current user ID from the client
        current_user_id = client.uid
        
        if is_local_favorite:
            # Add current user to favorite_user_ids using (4, id) command
            client.call(
                "project.project",
                "write",
                [[odoo_record_id], {"favorite_user_ids": [(4, current_user_id)]}]
            )
            log.info(f"[FAVORITE] Added project '{project_name}' (odoo_id={odoo_record_id}) to favorites")
        else:
            # Remove current user from favorite_user_ids using (3, id) command
            client.call(
                "project.project",
                "write",
                [[odoo_record_id], {"favorite_user_ids": [(3, current_user_id)]}]
            )
            log.info(f"[FAVORITE] Removed project '{project_name}' (odoo_id={odoo_record_id}) from favorites")
        
        return True
        
    except Exception as e:
        project_name = record.get('name') or '(unknown project)'
        log.error(f"[ERROR] Failed to sync favorite for project '{project_name}' (odoo_id={record.get('odoo_record_id')}): {e}")
        return False


def construct_changes(field_map, field_info, record, existing_data):
    """
    Construct a dictionary of changes to be applied to an Odoo record.
    
    Args:
        field_map (dict): Mapping of Odoo field names to SQLite field names
        field_info (dict): Field type information from Odoo
        record (dict): Local record data from SQLite
        existing_data (dict): Existing record data from Odoo
        
    Returns:
        dict: Dictionary of field changes where keys are Odoo field names
              and values are the new values to be set
              
    Note:
        Compares each mapped field between local and remote data,
        using timestamps to determine if changes should be applied.
        Skips fields not found in field_info or with missing sqlite_field mapping.
    """
    # Fields that should not be pushed to Odoo (computed/readonly fields)
    SKIP_FIELDS = {"last_update_status", "is_favorite"}
    
    changes = {}
    remote_write_date = existing_data.get("write_date")
    local_last_modified = record.get("last_modified")

    log.debug(f"[DEBUG] Starting construct_changes for record id={record['id']}")
    log.debug(f"[DEBUG] Comparing fields: {list(field_map.items())}")

    for odoo_field, sqlite_field in field_map.items():
        if odoo_field not in field_info:
            log.debug(f"[SKIP] Field '{odoo_field}' not found in field_info.")
            continue

        if odoo_field in SKIP_FIELDS:
            log.debug(f"[SKIP] Field '{odoo_field}' is in SKIP_FIELDS (computed/readonly).")
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


            # Normalize selection comparisons: ensure both sides are strings for fair comparison

            try:
                if field_type == "selection":
                    remote_norm = None if remote_val is None or remote_val is False else str(remote_val)
                    parsed_norm = None if parsed_val is None or parsed_val is False else str(parsed_val)
                    log.debug(f"[COMPARE_SELECTION] Field {odoo_field} local='{parsed_norm}' remote='{remote_norm}'")
                    if should_push_field(parsed_norm, remote_norm, local_last_modified, remote_write_date):
                        changes[odoo_field] = parsed_val
                else:
                    if should_push_field(parsed_val, remote_val, local_last_modified, remote_write_date):
                        changes[odoo_field] = parsed_val
            except Exception as e:
                log.error(f"[ERROR] Selection normalization failed for {odoo_field}: {e}")

        except Exception as e:
            log.error(f"[ERROR] Failed to compare field '{odoo_field}': {e}")

    return changes



def push_record_to_odoo(client, model_name, record, config_path="field_config.json"):
    """
    Push a single record from SQLite to Odoo, either creating or updating.
    
    Args:
        client: OdooClient instance for making API calls
        model_name (str): Name of the Odoo model to push to
        record (dict): Record data from SQLite including metadata
        config_path (str): Path to field configuration JSON file
        
    Returns:
        int or None: Odoo record ID if successful, None if failed
        
    Behavior:
        - If record has odoo_record_id: Updates existing Odoo record
        - If no odoo_record_id: Creates new Odoo record
        - Updates local SQLite record with new status and Odoo ID
        - Skips fields not found in Odoo model or marked as SKIP_FIELDS
        
    Note:
        Automatically resets the record status to empty string after successful sync.
    """
    field_map = load_field_mapping(model_name, config_path)
    field_info = fetch_odoo_field_info(client, model_name)

    missing_fields = []
    for field in field_map.keys():
        if field not in field_info:
            missing_fields.append(field)
    
    if missing_fields:
        fields_str = ', '.join(missing_fields)
        log.warning(
            f"[CONFIG] Model '{model_name}' is missing {len(missing_fields)} field(s): {fields_str}. "
            f"Please configure these fields in your Odoo instance or update field_config.json."
        )

    if record.get("odoo_record_id"):
        try:
            # XXXX Special Case: Mark mail.activity as done XXXXX
            if model_name == "mail.activity" and record.get("state") == "done":
                activity_name = record.get('summary') or '(no summary)'
                log.info(f"[ACTIVITY_SYNC_TO] Marking activity as done: '{activity_name}' (local_id={record['id']}, odoo_id={record['odoo_record_id']})")
                try:
                    client.call("mail.activity", "action_done", [[record["odoo_record_id"]]])
                    log.info(f"[ACTIVITY_SYNC_TO] Activity '{activity_name}' (odoo_id={record['odoo_record_id']}) marked as done on server.")

                    # Keep the record locally with status cleared (not pending sync)
                    # This allows the Done filter to show completed activities
                    safe_sql_execute(
                        record["db_path"],
                        f"UPDATE {record['table_name']} SET status = '' WHERE id = ? AND account_id = ?",
                        (record["id"], record["account_id"])
                    )
                    log.info(f"[ACTIVITY_SYNC_TO] Kept local activity '{activity_name}' (id={record['id']}) with state=done")

                    return record["odoo_record_id"]
                except Exception as e:
                    log.error(f"[ERROR] Failed to mark activity '{activity_name}' (odoo_id={record['odoo_record_id']}) as done: {e}")
                    return None

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
                display_name = get_record_display_name(record, model_name)
                log.warning(
                    f"[SKIP] Record {display_name} not found in Odoo - may have been deleted on server."
                )
                return None

            existing_data = existing[0]
            changes = construct_changes(field_map, field_info, record, existing_data)


            # Sanitize date fields for project.task to avoid Odoo validation errors

            try:
                if model_name == "project.task":
                    # Odoo field names used in mapping
                    start_key = None
                    end_key = None
                    # common mapping names used in field_config.json
                    if "planned_date_start" in field_map:
                        start_key = "planned_date_start"
                    if "planned_date_end" in field_map:
                        end_key = "planned_date_end"

                    if start_key and end_key:
                        # Prefer changed values, fallback to existing remote values
                        start_val = changes.get(start_key, existing_data.get(start_key))
                        end_val = changes.get(end_key, existing_data.get(end_key))

                        if start_val and end_val:
                            try:
                                # Normalize date strings
                                s_dt = datetime.fromisoformat(start_val)
                                e_dt = datetime.fromisoformat(end_val.replace("Z", "+00:00") if end_val.endswith("Z") else end_val)
                                if e_dt < s_dt:
                                    # Fix by setting end to start to satisfy validation
                                    changes[end_key] = start_val
                                    log.debug(f"[SANITIZE] Adjusted {end_key} to match {start_key} for record id={record['id']}")
                            except Exception:
                                # If parsing fails, remove end date from changes to avoid invalid input
                                if end_key in changes:
                                    del changes[end_key]
                                    log.debug(f"[SANITIZE] Removed invalid {end_key} from changes for record id={record['id']}")
            except Exception as e:
                log.debug(f"[SANITIZE] Date sanitization skipped due to error: {e}")


            if changes:
                client.call(model_name, "write", [[record["odoo_record_id"]], changes])
                display_name = get_record_display_name(record, model_name)
                log.info(
                    f"[UPDATE] {model_name}: {display_name} updated with fields: {list(changes.keys())}"
                )
                # Atomic status reset: only clear if status is still 'updated' to prevent race conditions
                # where user makes changes during sync and those changes would be lost
                safe_sql_execute(
                    record["db_path"],
                    f"UPDATE {record['table_name']} SET status = '' WHERE id = ? AND account_id = ? AND status = 'updated'",
                    (record["id"], record["account_id"])
                )
                log.debug(f"[SYNC] Reset status for {model_name} id={record['id']} after update.")

            # Handle favorites sync for project.project (is_favorite is computed in Odoo)
            if model_name == "project.project":
                sync_project_favorite(client, record, record.get("db_path", "app_settings.db"))

            # else:
            #    log.debug(f"[SKIP] No changes for {model_name} id={record['odoo_record_id']}.")
            return record["odoo_record_id"]

        except Exception as e:
            display_name = get_record_display_name(record, model_name)
            log.error(
                f"[ERROR] Failed to update {model_name} record {display_name}: {e}"
            )
            return None

    else:
        SKIP_FIELDS = {"last_update_status", "is_favorite"}  # is_favorite is computed field in Odoo

        odoo_data = {}
        for odoo_field, sqlite_field in field_map.items():
            if odoo_field not in field_info or odoo_field in SKIP_FIELDS:
                continue

            raw_val = record.get(sqlite_field)
            parsed_val = parse_local_value(field_info[odoo_field]["type"], raw_val)
            odoo_data[odoo_field] = parsed_val

        try:
            # Sanitize dates for create as well (project.task)

            if model_name == "project.task":
                start_key = "planned_date_start" if "planned_date_start" in field_map else None
                end_key = "planned_date_end" if "planned_date_end" in field_map else None
                if start_key and end_key:
                    start_val = odoo_data.get(start_key)
                    end_val = odoo_data.get(end_key)
                    if start_val and end_val:
                        try:
                            s_dt = datetime.fromisoformat(start_val)
                            e_dt = datetime.fromisoformat(end_val.replace("Z","+00:00") if isinstance(end_val, str) and end_val.endswith("Z") else end_val)
                            if e_dt < s_dt:
                                odoo_data[end_key] = start_val
                                log.debug(f"[SANITIZE] Adjusted create {end_key} to match {start_key}")
                        except Exception:
                            # If parsing fails, drop end date from payload
                            if end_key in odoo_data:
                                del odoo_data[end_key]
                                log.debug(f"[SANITIZE] Removed invalid create {end_key} from payload")

            # Special handling for mail.activity: res_model_id lookup and validation
            if model_name == "mail.activity":
                res_model = odoo_data.get("res_model")
                res_id = odoo_data.get("res_id")
                activity_summary = record.get('summary') or '(no summary)'
                
                # Validate res_model and res_id are set
                if not res_model or not res_id or res_id <= 0:
                    log.error(
                        f"[ERROR] Activity '{activity_summary}' (id={record.get('id')}) cannot be synced - not linked to any document. "
                        f"res_model={res_model or '(empty)'}, res_id={res_id or '(empty)'}. "
                        f"Activities must be linked to a Task, Project, or other document. Please edit or delete this activity in the app."
                    )
                    return None
                
                # Look up res_model_id from ir_model_app table
                res_model_id = get_res_model_id(record["db_path"], record["account_id"], res_model)
                if not res_model_id:
                    log.error(
                        f"[ERROR] Activity '{activity_summary}' (id={record.get('id')}) references unknown model '{res_model}'. "
                        f"Model not found in local database - please sync FROM Odoo first to download model information, then try syncing TO Odoo again."
                    )
                    return None
                
                # Add res_model_id to the Odoo data
                odoo_data["res_model_id"] = res_model_id
                log.debug(f"[ACTIVITY] Resolved res_model_id={res_model_id} for res_model='{res_model}'")

            new_id = client.call(model_name, "create", [odoo_data])
            display_name = get_record_display_name(record, model_name)
            log.info(f"[CREATE] {model_name}: {display_name} created successfully (new odoo_id={new_id})")

            # Atomic status reset: only clear if status is still 'updated' to prevent race conditions
            # where user makes changes during sync and those changes would be lost
            safe_sql_execute(
                record["db_path"],
                f"UPDATE {record['table_name']} SET odoo_record_id = ?, status = '' WHERE id = ? AND account_id = ? AND status = 'updated'",
                (new_id, record["id"], record["account_id"])
            )
            log.debug(f"[SYNC] Reset status for {model_name} id={record['id']} after creation.")


            return new_id

        except Exception as e:
            display_name = get_record_display_name(record, model_name)
            log.error(f"[ERROR] Failed to create {model_name} record {display_name}: {e}")
            # Log key fields for debugging
            key_fields = {k: v for k, v in record.items() if k in ['name', 'summary', 'display_name', 'id', 'odoo_record_id', 'res_model', 'res_id', 'project_id', 'task_id']}
            if key_fields:
                log.error(f"[ERROR]   → Key fields: {key_fields}")
            return None

def normalized_status(record):
    """
    Normalize a record's status field for consistent comparison.
    
    Args:
        record (dict): Record dictionary containing status field
        
    Returns:
        str: Normalized status string (stripped and lowercase)
             Returns empty string if status is None or missing
    """
    return (record.get("status") or "").strip().lower()

def sync_to_odoo(
    client,
    model_name,
    table_name,
    account_id,
    db_path="app_settings.db",
    config_path="field_config.json",
):
    """
    Synchronize records from SQLite to Odoo for a specific model and account.
    
    Args:
        client: OdooClient instance for making API calls
        model_name (str): Name of the Odoo model to sync to
        table_name (str): Name of the SQLite table to sync from
        account_id: Account ID to filter records by
        db_path (str): Path to SQLite database file
        config_path (str): Path to field configuration JSON file
        
    Behavior:
        - Processes records with status 'updated' for creation/modification
        - Processes records with status 'deleted' for deletion
        - Handles both local and remote deletions
        - Updates record status after successful operations
        - Logs comprehensive sync statistics
        - For mail.activity: automatically cleans up corrupted/orphaned records
        
    Note:
        Records marked as 'deleted' are removed from both Odoo and local SQLite.
        Handles cases where Odoo records are already deleted remotely.
    """
    # Special handling for mail.activity: cleanup corrupted records before sync
    if model_name == "mail.activity":
        cleanup_corrupted_activities(db_path, account_id)
    
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
        display_name = get_record_display_name(record, model_name)
        try:
            if record.get("odoo_record_id"):
                client.call(model_name, "unlink", [[record["odoo_record_id"]]])
                log.info(f"[DELETE] {model_name}: {display_name} deleted from Odoo")
        except Exception as e:
            if "does not exist or has been deleted" in str(e):
                log.warning(f"[SKIP] {model_name}: {display_name} was already deleted on Odoo")
            else:
                log.error(f"[ERROR] Failed to delete {model_name}: {display_name} - {e}")
                return  # Exit early — don't delete locally

        # Always delete locally if we're here
        safe_sql_execute(
            db_path,
            f"DELETE FROM {table_name} WHERE id = ?",
            (record["id"],)
        )
        log.debug(f"[CLEANUP] Local record removed: {display_name}")

    for record in local_records:
        record["db_path"] = db_path
        record["table_name"] = table_name
        record["account_id"] = account_id
        try:
            push_record_to_odoo(client, model_name, record, config_path)
        except Exception as e:
            display_name = get_record_display_name(record, model_name)
            log.error(f"[ERROR] Failed to sync {model_name}: {display_name} - {e}")
            # Create user-friendly notification message
            record_name = record.get('name') or record.get('summary') or f"Record #{record.get('id')}"
            add_notification(
                db_path=db_path,
                account_id=account_id,
                notif_type="Sync",
                message=f"Failed to sync {model_name}: {record_name}",
                payload={"record_id": record.get("id"), "record_name": record_name}
            )

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
        "mail.activity": "mail_activity_app",
        "project.update":"project_update_app",
    }


    for model, table in models.items():
        send("sync_message",f"Syncing to Server {model}")
        sync_to_odoo(client, model, table, account_id, db_path, config_path)
