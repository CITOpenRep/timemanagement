# -*- coding: utf-8 -*-
# MIT License
#
# Copyright (c) 2025 CIT-Services

import json
import sqlite3
import threading
from datetime import datetime, timedelta, timezone

from bus import send
from common import (
    add_notification,
    clear_sync_notifications,
    db_lock,
    ensure_sync_schema,
    invalidate_cached_model_schema,
    open_db_connection,
    safe_sql_execute,
)
from config import get_account_sync_settings, get_all_accounts
from logger import setup_logger
from odoo_client import OdooClient
from sync_from_odoo import resolve_timesheet_hierarchy
from sync_to_odoo import (
    _get_cached_field_info,
    cleanup_corrupted_activities,
    get_local_records,
    get_record_display_name,
    load_field_mapping,
    push_record_to_odoo,
)

log = setup_logger()

MODEL_PRIORITY = {
    "project.project": 1,
    "project.task": 2,
    "project.update": 3,
    "mail.activity": 4,
    "account.analytic.line": 5,
}

MODEL_TABLES = {
    "project.project": "project_project_app",
    "project.task": "project_task_app",
    "project.update": "project_update_app",
    "mail.activity": "mail_activity_app",
    "account.analytic.line": "account_analytic_line_app",
}

BACKOFF_SCHEDULE_SECONDS = (5, 15, 60, 300, 900)
MAX_PERMANENT_RETRIES = 3
MAX_TRANSIENT_RETRIES = 10

_client_pool_lock = threading.Lock()
_client_pool = {}

_queue_flush_lock = threading.Lock()
_worker_lock = threading.Lock()
_worker_event = threading.Event()
_worker_thread = None
_worker_db_path = None
_retry_timer = None


def _utc_now_str():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _parse_utc(ts_str):
    if not ts_str:
        return None
    dt = datetime.fromisoformat(str(ts_str).strip().replace("Z", "+00:00"))
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt


def _timestamps_equal(ts_a, ts_b):
    if not ts_a or not ts_b:
        return False
    try:
        return _parse_utc(ts_a) == _parse_utc(ts_b)
    except Exception:
        return str(ts_a).strip() == str(ts_b).strip()


def _is_transient_error(err_str):
    if not err_str:
        return True
    lower = err_str.lower()
    permanent_markers = (
        "validationerror",
        "accesserror",
        "access denied",
        "authentication failed",
        "invalid username or password",
        "invalid api key",
        "missingerror",
        "does not exist",
        "has been deleted",
        "constraint",
        "not linked to any document",
        "unknown model",
        "required field",
    )
    if any(m in lower for m in permanent_markers):
        return False
    transient_markers = (
        "timed out",
        "timeout",
        "connection",
        "refused",
        "temporarily",
        "reset by peer",
        "broken pipe",
        "remotedisconnected",
        "name resolution",
        "network is unreachable",
        "502",
        "503",
        "504",
    )
    return any(m in lower for m in transient_markers)


def _get_or_create_client(account):
    """Reuse an authenticated OdooClient for rapid outbox flushes."""
    key = (
        account.get("id"),
        account.get("link"),
        account.get("database"),
        account.get("username"),
        account.get("api_key"),
    )
    with _client_pool_lock:
        client = _client_pool.get(key)
        if client is not None and getattr(client, "uid", None):
            return client

    client = OdooClient(
        account["link"],
        account["database"],
        account["username"],
        account["api_key"],
    )
    with _client_pool_lock:
        _client_pool[key] = client
    return client


def invalidate_cached_client(account_id=None):
    with _client_pool_lock:
        if account_id is None:
            _client_pool.clear()
        else:
            stale = [k for k in _client_pool if k[0] == account_id]
            for k in stale:
                _client_pool.pop(k, None)


def recover_stuck_queue_items(db_path, account_id=None):
    """Reset any queue jobs left in 'in_flight' state (e.g. after app crash/kill) back to 'pending'."""
    try:
        ensure_sync_schema(db_path)
        if account_id is not None:
            safe_sql_execute(
                db_path,
                "UPDATE sync_queue SET status = 'pending', updated_at = datetime('now') WHERE status = 'in_flight' AND account_id = ?",
                (account_id,),
            )
        else:
            safe_sql_execute(
                db_path,
                "UPDATE sync_queue SET status = 'pending', updated_at = datetime('now') WHERE status = 'in_flight'",
            )
    except Exception as e:
        log.debug(f"[QUEUE] Failed to recover in_flight items: {e}")


def hydrate_queue_from_dirty_tables(db_path, account_id=None):
    """
    Ensure any row with status IN ('updated', 'created', 'deleted') that lacks a
    sync_queue row gets queued cleanly (backward compatibility fallback).
    """
    try:
        ensure_sync_schema(db_path)
        with db_lock:
            conn = open_db_connection(db_path)
            try:
                cur = conn.cursor()
                for model_name, table_name in MODEL_TABLES.items():
                    cur.execute(
                        "SELECT name FROM sqlite_master WHERE type='table' AND name = ?",
                        (table_name,),
                    )
                    if not cur.fetchone():
                        continue

                    cur.execute(f"PRAGMA table_info({table_name})")
                    cols = {r[1] for r in cur.fetchall()}
                    base_col = "base_write_date" if "base_write_date" in cols else "NULL AS base_write_date"
                    seq_col = "COALESCE(mutation_seq, 0)" if "mutation_seq" in cols else "0"

                    where = "LOWER(TRIM(COALESCE(status, ''))) IN ('updated', 'created', 'deleted') AND account_id > 0"
                    params = []
                    if account_id is not None:
                        where += " AND account_id = ?"
                        params.append(account_id)

                    cur.execute(
                        f"SELECT id, account_id, odoo_record_id, status, {base_col}, {seq_col} FROM {table_name} WHERE {where}",
                        params,
                    )
                    for row in cur.fetchall():
                        local_id, acct_id, odoo_id, st, base_wd, seq = row
                        norm_st = (st or "").strip().lower()
                        op = "delete" if norm_st == "deleted" else "upsert"
                        if op == "delete" and (not odoo_id or int(odoo_id) <= 0):
                            cur.execute(f"DELETE FROM {table_name} WHERE id = ?", (local_id,))
                            continue
                        cur.execute(
                            "SELECT id FROM sync_queue WHERE account_id = ? AND model_name = ? AND local_id = ?",
                            (acct_id, model_name, local_id),
                        )
                        if cur.fetchone():
                            continue
                        cur.execute(
                            """
                            INSERT INTO sync_queue (
                                account_id, model_name, table_name, local_id, odoo_record_id,
                                operation, dirty_fields, base_write_date, queued_seq,
                                status, retry_count, created_at, updated_at
                            ) VALUES (?, ?, ?, ?, ?, ?, NULL, ?, ?, 'pending', 0, datetime('now'), datetime('now'))
                            """,
                            (acct_id, model_name, table_name, local_id, odoo_id, op, base_wd, seq),
                        )
                conn.commit()
            finally:
                conn.close()
    except Exception as e:
        log.debug(f"[QUEUE] Hydrate dirty tables skipped: {e}")


def get_sync_queue_summary(db_path, account_id=-1):
    """Return counts of pending, in_flight, failed, and conflict queue items."""
    summary = {"pending": 0, "in_flight": 0, "failed": 0, "conflict": 0, "total": 0}
    try:
        ensure_sync_schema(db_path)
        sql = "SELECT status, COUNT(*) FROM sync_queue"
        params = ()
        if account_id is not None and int(account_id) >= 0:
            sql += " WHERE account_id = ?"
            params = (int(account_id),)
        sql += " GROUP BY status"
        rows = safe_sql_execute(db_path, sql, params, fetch=True, commit=False) or []
        for st, cnt in rows:
            if st in summary:
                summary[st] = int(cnt)
            summary["total"] += int(cnt)
    except Exception as e:
        log.debug(f"[QUEUE] Summary query failed: {e}")
    return summary


def _backfill_parent_odoo_id(conn, account_id, parent_model, local_id, new_odoo_id):
    """
    When a locally-created parent project or task is assigned its Odoo ID,
    update any unsynced child records and attachments that referenced its local_id.
    """
    if not local_id or not new_odoo_id or int(local_id) == int(new_odoo_id):
        return

    cur = conn.cursor()
    parent_table = MODEL_TABLES[parent_model]

    # Guard against colliding with an unrelated synced record whose odoo_record_id == local_id
    cur.execute(
        f"SELECT 1 FROM {parent_table} WHERE account_id = ? AND odoo_record_id = ? LIMIT 1",
        (account_id, local_id),
    )
    if cur.fetchone():
        return

    if parent_model == "project.task":
        cur.execute(
            "UPDATE project_task_app SET parent_id = ? WHERE account_id = ? AND parent_id = ? AND odoo_record_id IS NULL",
            (new_odoo_id, account_id, local_id),
        )
        cur.execute(
            "UPDATE mail_activity_app SET task_id = ?, link_id = ?, resId = ? WHERE account_id = ? AND resModel = 'project.task' AND (link_id = ? OR task_id = ?) AND odoo_record_id IS NULL",
            (new_odoo_id, new_odoo_id, new_odoo_id, account_id, local_id, local_id),
        )
        cur.execute(
            "UPDATE account_analytic_line_app SET task_id = ? WHERE account_id = ? AND task_id = ? AND odoo_record_id IS NULL",
            (new_odoo_id, account_id, local_id),
        )
        cur.execute(
            "UPDATE account_analytic_line_app SET sub_task_id = ? WHERE account_id = ? AND sub_task_id = ? AND odoo_record_id IS NULL",
            (new_odoo_id, account_id, local_id),
        )
        cur.execute(
            "UPDATE ir_attachment_app SET res_id = ? WHERE account_id = ? AND res_model = 'project.task' AND res_id = ? AND odoo_record_id IS NULL",
            (new_odoo_id, account_id, local_id),
        )
    elif parent_model == "project.project":
        cur.execute(
            "UPDATE project_project_app SET parent_id = ? WHERE account_id = ? AND parent_id = ? AND odoo_record_id IS NULL",
            (new_odoo_id, account_id, local_id),
        )
        cur.execute(
            "UPDATE project_task_app SET project_id = ? WHERE account_id = ? AND project_id = ? AND odoo_record_id IS NULL",
            (new_odoo_id, account_id, local_id),
        )
        cur.execute(
            "UPDATE project_task_app SET sub_project_id = ? WHERE account_id = ? AND sub_project_id = ? AND odoo_record_id IS NULL",
            (new_odoo_id, account_id, local_id),
        )
        cur.execute(
            "UPDATE project_update_app SET project_id = ? WHERE account_id = ? AND project_id = ? AND odoo_record_id IS NULL",
            (new_odoo_id, account_id, local_id),
        )
        cur.execute(
            "UPDATE mail_activity_app SET project_id = ?, link_id = ?, resId = ? WHERE account_id = ? AND resModel = 'project.project' AND (link_id = ? OR project_id = ?) AND odoo_record_id IS NULL",
            (new_odoo_id, new_odoo_id, new_odoo_id, account_id, local_id, local_id),
        )
        cur.execute(
            "UPDATE account_analytic_line_app SET project_id = ? WHERE account_id = ? AND project_id = ? AND odoo_record_id IS NULL",
            (new_odoo_id, account_id, local_id),
        )
        cur.execute(
            "UPDATE account_analytic_line_app SET sub_project_id = ? WHERE account_id = ? AND sub_project_id = ? AND odoo_record_id IS NULL",
            (new_odoo_id, account_id, local_id),
        )
        cur.execute(
            "UPDATE ir_attachment_app SET res_id = ? WHERE account_id = ? AND res_model = 'project.project' AND res_id = ? AND odoo_record_id IS NULL",
            (new_odoo_id, account_id, local_id),
        )


def _find_blocking_parent(db_path, account_id, model_name, record):
    """
    Check if this record depends on an unsynced local parent still in sync_queue.
    Returns parent queue status ('pending'|'in_flight'|'failed'|'conflict') or None.
    """
    checks = []
    if model_name == "project.project":
        if record.get("parent_id"):
            checks.append(("project.project", record["parent_id"]))
    elif model_name == "project.task":
        if record.get("sub_project_id"):
            checks.append(("project.project", record["sub_project_id"]))
        elif record.get("project_id"):
            checks.append(("project.project", record["project_id"]))
        if record.get("parent_id"):
            checks.append(("project.task", record["parent_id"]))
    elif model_name == "project.update":
        if record.get("project_id"):
            checks.append(("project.project", record["project_id"]))
    elif model_name == "mail.activity":
        res_model = record.get("resModel")
        link_id = record.get("link_id")
        if res_model in ("project.task", "project.project") and link_id:
            checks.append((res_model, link_id))
    elif model_name == "account.analytic.line":
        for fk_col in ("sub_project_id", "project_id"):
            if record.get(fk_col):
                checks.append(("project.project", record[fk_col]))
                break
        for fk_col in ("sub_task_id", "task_id"):
            if record.get(fk_col):
                checks.append(("project.task", record[fk_col]))
                break

    if not checks:
        return None

    with db_lock:
        conn = open_db_connection(db_path)
        try:
            cur = conn.cursor()
            for parent_model, fk_val in checks:
                try:
                    fk_int = int(fk_val)
                except (TypeError, ValueError):
                    continue
                if fk_int <= 0 or (parent_model == model_name and fk_int == record.get("id")):
                    continue

                parent_table = MODEL_TABLES[parent_model]
                cur.execute(
                    f"SELECT 1 FROM {parent_table} WHERE account_id = ? AND odoo_record_id = ? LIMIT 1",
                    (account_id, fk_int),
                )
                if cur.fetchone():
                    continue

                cur.execute(
                    "SELECT status FROM sync_queue WHERE account_id = ? AND model_name = ? AND local_id = ? AND odoo_record_id IS NULL LIMIT 1",
                    (account_id, parent_model, fk_int),
                )
                parent_row = cur.fetchone()
                if parent_row:
                    return parent_row[0]
        finally:
            conn.close()
    return None


def _merge_concurrent_remote_fields(
    conn,
    table_name,
    model_name,
    account_id,
    local_id,
    remote_record,
    pushed_fields,
    config_path,
):
    """
    When Odoo was modified concurrently before our push, merge all fields that were
    NOT written by our push (both untouched remote edits and fields where remote LWW won)
    into the local SQLite row so local state matches Odoo immediately.
    """
    if not remote_record:
        return
    try:
        field_map = load_field_mapping(model_name, config_path)
        pushed_set = set(pushed_fields or [])
        cur = conn.cursor()
        cur.execute(f"PRAGMA table_info({table_name})")
        table_cols = {r[1] for r in cur.fetchall()}

        updates = {}
        for odoo_field, sqlite_field in field_map.items():
            if not sqlite_field or sqlite_field not in table_cols:
                continue
            if sqlite_field in ("account_id", "odoo_record_id", "last_modified"):
                continue
            if odoo_field in pushed_set or sqlite_field in pushed_set:
                continue
            if model_name == "account.analytic.line":
                if sqlite_field == "project_id" and "sub_project_id" in pushed_set:
                    continue
                if sqlite_field == "task_id" and "sub_task_id" in pushed_set:
                    continue
            if odoo_field not in remote_record:
                continue
            val = remote_record.get(odoo_field)
            if isinstance(val, list) and val:
                if all(isinstance(v, int) for v in val):
                    val = ",".join(str(v) for v in val)
                else:
                    val = val[0]
            if isinstance(val, bool):
                val = int(val)
            if not isinstance(val, (int, float, str, type(None))):
                val = str(val)
            updates[sqlite_field] = val

        if model_name == "account.analytic.line" and ("project_id" in updates or "task_id" in updates):
            parent_proj_id, sub_proj_to_set, parent_task_id, sub_task_to_set = resolve_timesheet_hierarchy(
                None, account_id, remote_record.get("project_id"), remote_record.get("task_id"), connection=conn
            )
            if "project_id" in updates and parent_proj_id is not None:
                updates["project_id"] = parent_proj_id
                if "sub_project_id" in table_cols and "sub_project_id" not in pushed_set:
                    updates["sub_project_id"] = sub_proj_to_set
            if "task_id" in updates and parent_task_id is not None:
                updates["task_id"] = parent_task_id
                if "sub_task_id" in table_cols and "sub_task_id" not in pushed_set:
                    updates["sub_task_id"] = sub_task_to_set

        if updates:
            set_clause = ", ".join(f"{col} = ?" for col in updates.keys())
            cur.execute(
                f"UPDATE {table_name} SET {set_clause} WHERE id = ? AND account_id = ?",
                list(updates.values()) + [local_id, account_id],
            )
    except Exception as e:
        log.debug(f"[QUEUE] Non-dirty remote merge skipped for {model_name}#{local_id}: {e}")


def _finalize_queue_success(
    db_path,
    account_id,
    model_name,
    table_name,
    local_id,
    queued_seq,
    pushed_id,
    dirty_fields,
    old_base_write_date,
    sync_context,
    config_path,
):
    """Atomically apply Odoo ID, base_write_date, parent backfill, and clear status if no mid-flight edit occurred."""
    with db_lock:
        conn = open_db_connection(db_path)
        try:
            cur = conn.cursor()
            cur.execute(f"PRAGMA table_info({table_name})")
            cols = {r[1] for r in cur.fetchall()}

            seq_expr = "COALESCE(mutation_seq, 0)" if "mutation_seq" in cols else "0"
            cur.execute(
                f"SELECT {seq_expr}, odoo_record_id FROM {table_name} WHERE id = ? AND account_id = ? LIMIT 1",
                (local_id, account_id),
            )
            row = cur.fetchone()
            if not row:
                cur.execute(
                    "DELETE FROM sync_queue WHERE account_id = ? AND model_name = ? AND local_id = ?",
                    (account_id, model_name, local_id),
                )
                conn.commit()
                return False

            current_seq, existing_odoo_id = row
            new_odoo_id = sync_context.get("new_odoo_id") or existing_odoo_id or pushed_id
            resolved_author_id = sync_context.get("resolved_author_id")
            new_write_date = sync_context.get("new_write_date") or sync_context.get("remote_write_date")

            set_parts = []
            params = []

            if sync_context.get("new_odoo_id") and not existing_odoo_id:
                set_parts.append("odoo_record_id = ?")
                params.append(sync_context["new_odoo_id"])
            if resolved_author_id is not None and "user_id" in cols:
                set_parts.append("user_id = ?")
                params.append(resolved_author_id)
            if new_write_date and "base_write_date" in cols:
                set_parts.append("base_write_date = ?")
                params.append(str(new_write_date))

            has_midflight_edit = current_seq > queued_seq
            if not has_midflight_edit:
                set_parts.append("status = ''")

            if set_parts:
                cur.execute(
                    f"UPDATE {table_name} SET {', '.join(set_parts)} WHERE id = ? AND account_id = ?",
                    params + [local_id, account_id],
                )

            if (
                sync_context.get("remote_record")
                and old_base_write_date
                and sync_context.get("remote_write_date")
                and not _timestamps_equal(old_base_write_date, sync_context["remote_write_date"])
                and not has_midflight_edit
            ):
                _merge_concurrent_remote_fields(
                    conn,
                    table_name,
                    model_name,
                    account_id,
                    local_id,
                    sync_context["remote_record"],
                    sync_context.get("pushed_fields", []),
                    config_path,
                )

            if sync_context.get("new_odoo_id") and not existing_odoo_id and model_name in ("project.project", "project.task"):
                _backfill_parent_odoo_id(conn, account_id, model_name, local_id, sync_context["new_odoo_id"])

            if has_midflight_edit:
                cur.execute(
                    "UPDATE sync_queue SET odoo_record_id = COALESCE(?, odoo_record_id), status = 'pending', base_write_date = COALESCE(?, base_write_date), updated_at = datetime('now') WHERE account_id = ? AND model_name = ? AND local_id = ?",
                    (new_odoo_id, new_write_date, account_id, model_name, local_id),
                )
            else:
                cur.execute(
                    "DELETE FROM sync_queue WHERE account_id = ? AND model_name = ? AND local_id = ?",
                    (account_id, model_name, local_id),
                )

            conn.commit()
            return has_midflight_edit
        finally:
            conn.close()


def _mark_queue_conflict(db_path, account_id, model_name, local_id, message):
    safe_sql_execute(
        db_path,
        "UPDATE sync_queue SET status = 'conflict', next_retry_at = NULL, last_error = ?, updated_at = datetime('now') WHERE account_id = ? AND model_name = ? AND local_id = ?",
        (str(message)[:500], account_id, model_name, local_id),
    )


def _mark_queue_retry_or_failed(db_path, account_id, model_name, local_id, current_retry_count, err_str):
    next_retry_count = int(current_retry_count or 0) + 1
    is_transient = _is_transient_error(err_str)
    max_attempts = MAX_TRANSIENT_RETRIES if is_transient else MAX_PERMANENT_RETRIES

    if next_retry_count >= max_attempts:
        safe_sql_execute(
            db_path,
            "UPDATE sync_queue SET status = 'failed', retry_count = ?, next_retry_at = NULL, last_error = ?, updated_at = datetime('now') WHERE account_id = ? AND model_name = ? AND local_id = ?",
            (next_retry_count, str(err_str)[:500], account_id, model_name, local_id),
        )
        return None, True

    idx = min(next_retry_count - 1, len(BACKOFF_SCHEDULE_SECONDS) - 1)
    delay_sec = BACKOFF_SCHEDULE_SECONDS[idx]
    next_at = (datetime.now(timezone.utc) + timedelta(seconds=delay_sec)).strftime("%Y-%m-%dT%H:%M:%SZ")
    safe_sql_execute(
        db_path,
        "UPDATE sync_queue SET status = 'pending', retry_count = ?, next_retry_at = ?, last_error = ?, updated_at = datetime('now') WHERE account_id = ? AND model_name = ? AND local_id = ?",
        (next_retry_count, next_at, str(err_str)[:500], account_id, model_name, local_id),
    )
    return delay_sec, False


def _has_queued_local_parent(db_path, account_id, model_name, link_id):
    if model_name != "mail.activity":
        return False
    rows = safe_sql_execute(
        db_path,
        "SELECT 1 FROM sync_queue WHERE account_id = ? AND model_name IN ('project.task', 'project.project') AND local_id = ? AND odoo_record_id IS NULL LIMIT 1",
        (account_id, link_id),
        fetch=True,
        commit=False,
    )
    return bool(rows)


def _process_single_queue_item(db_path, account_id, queue_item, client, config_path="field_config.json"):
    """
    Execute one pending queue item against Odoo.
    Returns (outcome, extra_delay_or_flag):
      outcome in ('pushed', 'deferred', 'conflict', 'failed', 'retry_scheduled', 'skipped')
    """
    model_name = queue_item["model_name"]
    table_name = queue_item["table_name"]
    local_id = queue_item["local_id"]
    operation = queue_item["operation"]
    queued_seq = queue_item["queued_seq"] or 0
    retry_count = queue_item["retry_count"] or 0
    base_write_date = queue_item["base_write_date"]

    # Mark in_flight before touching network
    safe_sql_execute(
        db_path,
        "UPDATE sync_queue SET status = 'in_flight', updated_at = datetime('now') WHERE id = ?",
        (queue_item["id"],),
    )

    records = get_local_records(
        table_name,
        model_name,
        account_id,
        db_path,
        config_path,
        record_ids=[local_id],
    )
    if not records:
        safe_sql_execute(db_path, "DELETE FROM sync_queue WHERE id = ?", (queue_item["id"],))
        return "skipped", None

    record = records[0]
    record["db_path"] = db_path
    record["table_name"] = table_name
    record["account_id"] = account_id
    if base_write_date and not record.get("base_write_date"):
        record["base_write_date"] = base_write_date

    local_status = (record.get("status") or "").strip().lower()

    # Never push running/paused/draft timers until finalized
    if operation != "delete" and local_status in ("active", "draft", "saved", ""):
        safe_sql_execute(db_path, "DELETE FROM sync_queue WHERE id = ?", (queue_item["id"],))
        return "skipped", None

    # Delete operation
    if operation == "delete" or local_status == "deleted":
        odoo_id = record.get("odoo_record_id") or queue_item.get("odoo_record_id")
        try:
            if odoo_id:
                client.call(model_name, "unlink", [[int(odoo_id)]])
                log.info(f"[QUEUE] Deleted {model_name} odoo_id={odoo_id} (local_id={local_id})")
        except Exception as del_err:
            err_lower = str(del_err).lower()
            if "does not exist" not in err_lower and "has been deleted" not in err_lower:
                delay_sec, is_permanent = _mark_queue_retry_or_failed(
                    db_path, account_id, model_name, local_id, retry_count, str(del_err)
                )
                return ("failed" if is_permanent else "retry_scheduled"), delay_sec

        safe_sql_execute(db_path, f"DELETE FROM {table_name} WHERE id = ?", (local_id,))
        safe_sql_execute(db_path, "DELETE FROM sync_queue WHERE id = ?", (queue_item["id"],))
        return "pushed", None

    # Check if child depends on an unsynced local parent
    blocking_status = _find_blocking_parent(db_path, account_id, model_name, record)
    if blocking_status in ("pending", "in_flight"):
        safe_sql_execute(
            db_path,
            "UPDATE sync_queue SET status = 'pending', updated_at = datetime('now') WHERE id = ?",
            (queue_item["id"],),
        )
        return "deferred", None
    if blocking_status in ("failed", "conflict"):
        err_msg = f"Waiting on parent record ({blocking_status})"
        _mark_queue_retry_or_failed(db_path, account_id, model_name, local_id, retry_count, err_msg)
        return "deferred", None

    dirty_fields = None
    base_values = None
    if queue_item.get("dirty_fields"):
        try:
            parsed = json.loads(queue_item["dirty_fields"])
            if isinstance(parsed, list):
                dirty_fields = parsed
            elif isinstance(parsed, dict):
                if isinstance(parsed.get("fields"), list):
                    dirty_fields = parsed["fields"]
                if isinstance(parsed.get("base"), dict):
                    base_values = parsed["base"]
        except Exception:
            dirty_fields = None

    if operation == "favorite" and dirty_fields is None:
        dirty_fields = ["favorites"]

    field_info = _get_cached_field_info(client, model_name, db_path=db_path, account_id=account_id)
    sync_context = {}
    pushed_id = push_record_to_odoo(
        client,
        model_name,
        record,
        config_path,
        field_info=field_info,
        dirty_fields=dirty_fields,
        sync_context=sync_context,
        base_values=base_values,
    )

    # Retry once cleanly if Odoo schema changed since cache
    if pushed_id is None and sync_context.get("error") and "invalid field" in sync_context["error"].lower():
        invalidate_cached_model_schema(db_path, account_id, model_name)
        field_info = _get_cached_field_info(client, model_name, db_path=db_path, account_id=account_id, force_refresh=True)
        sync_context = {}
        pushed_id = push_record_to_odoo(
            client,
            model_name,
            record,
            config_path,
            field_info=field_info,
            dirty_fields=dirty_fields,
            sync_context=sync_context,
            base_values=base_values,
        )

    if sync_context.get("status") == "conflict_deleted":
        display = get_record_display_name(record, model_name)
        _mark_queue_conflict(db_path, account_id, model_name, local_id, f"{display} was deleted on Odoo; local edits kept")
        add_notification(
            db_path=db_path,
            account_id=account_id,
            notif_type="Sync",
            message=f"{display} was deleted on Odoo. Your local edits were kept.",
            payload={"model": model_name, "record_id": local_id, "conflict": "deleted_remotely"},
        )
        return "conflict", None

    if pushed_id is not None:
        has_more = _finalize_queue_success(
            db_path=db_path,
            account_id=account_id,
            model_name=model_name,
            table_name=table_name,
            local_id=local_id,
            queued_seq=queued_seq,
            pushed_id=pushed_id,
            dirty_fields=dirty_fields,
            old_base_write_date=base_write_date,
            sync_context=sync_context,
            config_path=config_path,
        )
        clear_sync_notifications(db_path, account_id, model_name)
        return ("pushed_and_requeued" if has_more else "pushed"), None

    err_str = sync_context.get("error") or f"Failed to sync {model_name}"
    delay_sec, is_permanent = _mark_queue_retry_or_failed(
        db_path, account_id, model_name, local_id, retry_count, err_str
    )
    if is_permanent:
        rec_name = record.get("name") or record.get("summary") or f"Record #{local_id}"
        add_notification(
            db_path=db_path,
            account_id=account_id,
            notif_type="Sync",
            message=f"Failed to sync {model_name}: {rec_name}",
            payload={"record_id": local_id, "record_name": rec_name, "error": err_str},
        )
        return "failed", None
    return "retry_scheduled", delay_sec


def flush_sync_queue(
    db_path,
    account_id=None,
    client=None,
    config_path="field_config.json",
    ignore_backoff=False,
):
    """
    Drain all ready pending sync_queue jobs in dependency order.
    Returns summary dict: {pushed, deferred, conflict, failed, min_retry_delay}.
    """
    stats = {"pushed": 0, "deferred": 0, "conflict": 0, "failed": 0, "min_retry_delay": None}
    if not db_path:
        return stats

    with _queue_flush_lock:
        ensure_sync_schema(db_path)
        recover_stuck_queue_items(db_path, account_id=account_id)
        hydrate_queue_from_dirty_tables(db_path, account_id=account_id)

        accounts = {acc["id"]: acc for acc in get_all_accounts(db_path) if acc.get("id") and acc.get("id") > 0}
        now_str = _utc_now_str()

        # Up to 3 passes resolve parent->child creations (e.g. Project -> Task -> Subtask -> Timesheet)
        for _pass in range(3):
            with db_lock:
                conn = open_db_connection(db_path)
                try:
                    cur = conn.cursor()
                    if ignore_backoff:
                        sql = """
                            SELECT id, account_id, model_name, table_name, local_id, odoo_record_id,
                                   operation, dirty_fields, base_write_date, queued_seq, retry_count
                            FROM sync_queue
                            WHERE status = 'pending'
                        """
                        params = []
                    else:
                        sql = """
                            SELECT id, account_id, model_name, table_name, local_id, odoo_record_id,
                                   operation, dirty_fields, base_write_date, queued_seq, retry_count
                            FROM sync_queue
                            WHERE status = 'pending'
                              AND (next_retry_at IS NULL OR next_retry_at <= ?)
                        """
                        params = [now_str]
                    if account_id is not None:
                        sql += " AND account_id = ?"
                        params.append(account_id)
                    cur.execute(sql, params)
                    rows = cur.fetchall()
                finally:
                    conn.close()

            if not rows:
                break

            items = []
            for r in rows:
                items.append({
                    "id": r[0],
                    "account_id": r[1],
                    "model_name": r[2],
                    "table_name": r[3],
                    "local_id": r[4],
                    "odoo_record_id": r[5],
                    "operation": r[6],
                    "dirty_fields": r[7],
                    "base_write_date": r[8],
                    "queued_seq": r[9],
                    "retry_count": r[10],
                })

            items.sort(key=lambda x: (x["account_id"], MODEL_PRIORITY.get(x["model_name"], 99), x["id"]))

            made_progress = False
            for item in items:
                acct_id = item["account_id"]
                settings = get_account_sync_settings(db_path, acct_id)
                if settings.get("sync_direction") == "download_only":
                    continue

                acct = accounts.get(acct_id)
                if not acct or not acct.get("link") or not acct.get("api_key"):
                    safe_sql_execute(db_path, "DELETE FROM sync_queue WHERE id = ?", (item["id"],))
                    continue

                use_client = client if (client is not None and (account_id is None or acct_id == account_id)) else None
                if use_client is None:
                    try:
                        use_client = _get_or_create_client(acct)
                    except Exception as conn_err:
                        invalidate_cached_client(acct_id)
                        delay_sec, _ = _mark_queue_retry_or_failed(
                            db_path, acct_id, item["model_name"], item["local_id"], item["retry_count"], str(conn_err)
                        )
                        if delay_sec is not None:
                            if stats["min_retry_delay"] is None or delay_sec < stats["min_retry_delay"]:
                                stats["min_retry_delay"] = delay_sec
                        continue

                outcome, detail = _process_single_queue_item(db_path, acct_id, item, use_client, config_path=config_path)
                if outcome in ("pushed", "pushed_and_requeued"):
                    stats["pushed"] += 1
                    made_progress = True
                elif outcome == "deferred":
                    stats["deferred"] += 1
                elif outcome == "conflict":
                    stats["conflict"] += 1
                elif outcome == "failed":
                    invalidate_cached_client(acct_id)
                    stats["failed"] += 1
                elif outcome == "retry_scheduled":
                    invalidate_cached_client(acct_id)
                    if detail is not None:
                        if stats["min_retry_delay"] is None or detail < stats["min_retry_delay"]:
                            stats["min_retry_delay"] = detail

            if not made_progress:
                break

    if stats["pushed"] > 0:
        send("queue_synced", {"account_id": account_id or -1, "pushed": stats["pushed"]})

    return stats


def _schedule_retry_wake(delay_sec):
    global _retry_timer
    if delay_sec is None or delay_sec <= 0:
        return
    with _worker_lock:
        if _retry_timer is not None:
            _retry_timer.cancel()
        _retry_timer = threading.Timer(float(delay_sec), lambda: _worker_event.set())
        _retry_timer.daemon = True
        _retry_timer.start()


def _queue_worker_loop():
    while True:
        _worker_event.wait()
        _worker_event.clear()
        with _worker_lock:
            db_path = _worker_db_path
        if not db_path:
            continue
        try:
            stats = flush_sync_queue(db_path)
            if stats.get("min_retry_delay"):
                _schedule_retry_wake(stats["min_retry_delay"])
        except Exception as e:
            log.error(f"[QUEUE] Worker flush error: {e}")


def wake_sync_queue(settings_db=None, account_id=-1):
    """
    Non-blocking trigger called from QML when local mutations are saved.
    Starts the persistent outbox worker thread if needed and wakes it immediately.
    """
    global _worker_thread, _worker_db_path

    if not settings_db:
        from .storage import resolve_qml_db_path
        settings_db = resolve_qml_db_path("ubtms") or "app_settings.db"

    with _worker_lock:
        _worker_db_path = settings_db
        if _worker_thread is None or not _worker_thread.is_alive():
            _worker_thread = threading.Thread(target=_queue_worker_loop, daemon=True)
            _worker_thread.start()

    _worker_event.set()
    return True
