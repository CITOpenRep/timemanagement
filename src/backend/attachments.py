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

import base64
import os
import shutil
import sqlite3
from pathlib import Path
from urllib.parse import unquote

from bus import send
from config import get_all_accounts
from logger import setup_logger
from odoo_client import OdooClient
from sync_from_odoo import sync_ondemand_tables_from_odoo

from .auth import check_server_reachability
from .storage import _app_data_dir, _export_path_for, resolve_qml_db_path

log = setup_logger()


def attachment_ondemand_download(settings_db, account_id, remote_record_id):
    accounts = get_all_accounts(settings_db)
    selected = None
    for acc in accounts:
        if acc.get("id") == account_id:
            selected = acc
            break

    if not selected:
        return {
            "success": False,
            "error": "Account not found",
        }

    try:
        client = OdooClient(
            selected["link"],
            selected["database"],
            selected["username"],
            selected["api_key"],
        )
        result = client.ondemanddownload(
            remote_record_id,
            selected["username"],
            selected["api_key"],
            False,
        )
        if isinstance(result, dict):
            result["success"] = True
        return result
    except Exception as e:
        log.exception(
            "[ATTACHMENT] Failed to download attachment %s for account %s",
            remote_record_id,
            account_id,
        )
        return {
            "success": False,
            "error": str(e),
        }


def attachment_upload(settings_db, account_id, filepath, res_type, res_id):
    try:
        filepath = unquote(filepath)
        send("ondemand_upload_message", "Initiating upload...")
        log.debug(f"[SYNC] Starting attachment_upload to {account_id} : {filepath} , {res_type} ,{res_id}")
        accounts = get_all_accounts(settings_db)
        selected = None
        for acc in accounts:
            if acc.get("id") == account_id:
                selected = acc
                break

        is_local_account = (account_id == 0) or (selected and selected.get("id") == 0) or (selected and not selected.get("link"))

        if not selected and not is_local_account:
            send("ondemand_upload_message", "Error: Account not found")
            send("ondemand_upload_completed", False)
            return None

        send("ondemand_upload_message", "Checking file...")
        if not os.path.exists(filepath):
            send("ondemand_upload_message", "Error: File does not exist")
            send("ondemand_upload_completed", False)
            return None

        # 25 MB limit to prevent memory exhaustion and large payload failures
        file_size = os.path.getsize(filepath)
        if file_size > 25 * 1024 * 1024:
            send("ondemand_upload_message", "Error: File exceeds 25MB limit")
            send("ondemand_upload_completed", False)
            return None

        filename = os.path.basename(filepath)
        EXT_TO_MIME = {
            ".jpg": "image/jpeg",
            ".jpeg": "image/jpeg",
            ".png": "image/png",
            ".gif": "image/gif",
            ".pdf": "application/pdf",
            ".txt": "text/plain",
            ".csv": "text/csv",
            ".mp3": "audio/mpeg",
            ".mp4": "video/mp4",
            ".zip": "application/zip",
        }
        send("ondemand_upload_message", "Reading file...")
        ext = os.path.splitext(filename)[1].lower()
        mimetype = EXT_TO_MIME.get(ext, "application/octet-stream")

        # Handle Local Account attachment save
        if is_local_account:
            send("ondemand_upload_message", "Saving attachment locally...")
            dest_path = _export_path_for(filename, mimetype)
            if Path(filepath).resolve() != Path(dest_path).resolve():
                shutil.copy2(filepath, dest_path)

            db_path = settings_db or resolve_qml_db_path()
            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()

            cursor.execute("SELECT COALESCE(MAX(odoo_record_id), 0) + 1 FROM ir_attachment_app WHERE account_id = 0")
            row = cursor.fetchone()
            next_local_record_id = row[0] if (row and row[0] is not None and row[0] > 0) else 1

            cursor.execute("""
                INSERT INTO ir_attachment_app (
                    account_id, name, res_model, res_id, file_path, local_url, url,
                    file_size, mimetype, odoo_record_id, last_modified, status
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, datetime('now'), 'local')
            """, (
                0,
                filename,
                res_type,
                res_id,
                str(dest_path),
                f"file://{dest_path}",
                f"file://{dest_path}",
                file_size,
                mimetype,
                next_local_record_id,
            ))

            cursor.execute("""
                INSERT OR REPLACE INTO attachment_download_app (account_id, record_id, file_name, downloaded)
                VALUES (0, ?, ?, 1)
            """, (next_local_record_id, filename))

            conn.commit()
            conn.close()

            send("ondemand_upload_message", "Attachment saved successfully")
            send("ondemand_upload_completed", True)
            return next_local_record_id

        # Remote Odoo Account upload
        send("ondemand_upload_message", "Checking server connection...")
        if not check_server_reachability(selected["link"]):
            send("ondemand_upload_message", "Error: No internet connection or server unreachable")
            send("ondemand_upload_completed", False)
            return None

        with open(filepath, "rb") as f:
            file_bytes = f.read()

        client = OdooClient(
            selected["link"],
            selected["database"],
            selected["username"],
            selected["api_key"],
        )

        vals = {
            "name": filename,
            "type": "binary",
            "res_model": res_type,
            "res_id": res_id,
            "datas": base64.b64encode(file_bytes).decode("utf-8"),
            "mimetype": mimetype,
        }
        send("ondemand_upload_message", "Uploading file to server...")
        attachment_id = client.call("ir.attachment", "create", [vals])
        if not attachment_id or attachment_id <= 0:
            send("ondemand_upload_message", "Error: Server failed to save attachment")
            send("ondemand_upload_completed", False)
            return None

        send("ondemand_upload_message", "Syncing to local device...")
        sync_ondemand_tables_from_odoo(client, selected["id"], settings_db, account_name=selected.get("name", ""))
        send("ondemand_upload_completed", True)
        return attachment_id

    except Exception as e:
        error_msg = str(e)
        log.exception(f"[ATTACHMENT] Failed to upload attachment: {error_msg}")

        friendly_error = "Upload failed"
        if "connection" in error_msg.lower() or "refused" in error_msg.lower():
            friendly_error = "Connection failed: Check network/server"
        elif "timeout" in error_msg.lower():
            friendly_error = "Request timed out"
        elif "authentication" in error_msg.lower() or "access denied" in error_msg.lower() or "uid" in error_msg.lower():
            friendly_error = "Authentication failed: Check credentials"
        elif "xmlrpc" in error_msg.lower() or "fault" in error_msg.lower():
            friendly_error = f"Server error: {error_msg[:60]}"
        else:
            friendly_error = f"Error: {error_msg[:60]}"

        send("ondemand_upload_message", friendly_error)
        send("ondemand_upload_completed", False)
        return None


def attachment_delete(settings_db, account_id, remote_record_id):
    log.debug(f"[SYNC] Starting attachment_delete for account {account_id}, attachment {remote_record_id}")
    accounts = get_all_accounts(settings_db)
    selected = None
    for acc in accounts:
        if acc.get("id") == account_id:
            selected = acc
            break

    is_local_account = (account_id == 0) or (selected and selected.get("id") == 0) or (selected and not selected.get("link"))

    if is_local_account:
        try:
            db_path = settings_db or resolve_qml_db_path()
            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()

            cursor.execute(
                "DELETE FROM ir_attachment_app WHERE account_id = 0 AND (odoo_record_id = ? OR id = ?)",
                (remote_record_id, remote_record_id),
            )
            cursor.execute(
                "DELETE FROM attachment_download_app WHERE account_id = 0 AND record_id = ?",
                (remote_record_id,),
            )
            conn.commit()
            conn.close()

            cleanup_orphan_attachment_files(settings_db)
            return {"success": True}
        except Exception as e:
            log.exception(f"[ATTACHMENT] Failed to delete local attachment {remote_record_id}: {e}")
            return {"success": False, "error": str(e)}

    if not selected:
        return {"success": False, "error": "Account not found"}

    try:
        if not check_server_reachability(selected["link"]):
            return {"success": False, "error": "No internet connection or server unreachable"}

        client = OdooClient(
            selected["link"],
            selected["database"],
            selected["username"],
            selected["api_key"],
        )
        res = client.call("ir.attachment", "unlink", [[remote_record_id]])
        if not res:
            log.warning(f"Unlink returned false or empty response for attachment {remote_record_id}")
            return {"success": False, "error": "Server failed to delete attachment"}

        sync_ondemand_tables_from_odoo(client, selected["id"], settings_db, account_name=selected.get("name", ""))
        return {"success": True}
    except Exception as e:
        error_msg = str(e)
        log.exception(f"[ATTACHMENT] Failed to delete attachment {remote_record_id} for account {account_id}")

        friendly_error = "Delete failed"
        if "connection" in error_msg.lower() or "refused" in error_msg.lower():
            friendly_error = "Connection failed: Check network/server"
        elif "timeout" in error_msg.lower():
            friendly_error = "Request timed out"
        elif "authentication" in error_msg.lower() or "access denied" in error_msg.lower() or "uid" in error_msg.lower():
            friendly_error = "Authentication failed: Check credentials"
        elif "xmlrpc" in error_msg.lower() or "fault" in error_msg.lower():
            friendly_error = f"Server error: {error_msg[:60]}"
        else:
            friendly_error = f"Error: {error_msg[:60]}"

        return {"success": False, "error": friendly_error}


def cleanup_orphan_attachment_files(settings_db=None):
    """
    Removes cached temporary/exported attachment files from disk that are no longer referenced
    by any active attachment record in the database.
    """
    try:
        tmp_dir = _app_data_dir() / "ubtms" / "tmp"
        if not tmp_dir.exists():
            return {"success": True, "deleted_count": 0}

        db_path = settings_db or resolve_qml_db_path()
        if not db_path or not Path(db_path).exists():
            return {"success": False, "error": "Database not found"}

        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()

        active_filenames = set()
        try:
            cursor.execute("SELECT file_name FROM attachment_download_app WHERE downloaded = 1")
            for row in cursor.fetchall():
                if row[0]:
                    active_filenames.add(str(row[0]).strip().replace("/", "_"))
        except Exception:
            pass

        try:
            cursor.execute("SELECT name FROM ir_attachment_app")
            for row in cursor.fetchall():
                if row[0]:
                    active_filenames.add(str(row[0]).strip().replace("/", "_"))
        except Exception:
            pass

        conn.close()

        deleted_count = 0
        for file in tmp_dir.iterdir():
            if file.is_file():
                if file.name not in active_filenames and file.stem not in active_filenames:
                    try:
                        file.unlink()
                        deleted_count += 1
                        log.info(f"[ATTACHMENT] Cleaned up orphan file on disk: {file.name}")
                    except Exception as err:
                        log.warning(f"[ATTACHMENT] Could not delete {file.name}: {err}")

        return {"success": True, "deleted_count": deleted_count}
    except Exception as e:
        log.exception(f"[ATTACHMENT] Error cleaning orphan attachment files: {e}")
        return {"success": False, "error": str(e)}
