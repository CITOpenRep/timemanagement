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
import hashlib
import mimetypes
import os
from pathlib import Path

from common import check_table_exists
from logger import setup_logger

log = setup_logger()


def is_file_present(file_path):
    """
    Check if a file exists at the specified path.
    """
    file = Path(file_path)
    if file.exists() and file.is_file():
        log.info(f"[INFO] File exists: {file_path}")
        return True
    else:
        log.error(f"[ERROR] File NOT found: {file_path}")
        return False


def resolve_qml_db_path(app_id="ubtms"):
    """
    Resolve and find the QML application database path across different environments.
    """
    db_paths = []
    user_home = Path.home()
    db_paths.append(user_home / ".local" / "share" / app_id / "Databases")

    # Clickable sandbox, e.g., /home/user/.clickable/home/
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
                    log.critical("SQlite file found , but do not see a table")

    log.debug("[ERROR] No QML DB found.")
    return None


def resolve_settings_db_path(db_name="myDatabase", app_id="ubtms"):
    """
    Finds a specific QML database by its name (hash).
    """
    db_hash = hashlib.md5(db_name.encode()).hexdigest()
    target_filename = f"{db_hash}.sqlite"

    user_home = Path.home()
    db_paths = [
        user_home / ".local" / "share" / app_id / "Databases",
        user_home / ".clickable" / "home" / ".local" / "share" / app_id / "Databases",
    ]

    for db_dir in db_paths:
        target = db_dir / target_filename
        if target.exists():
            return str(target)
    return None


def _app_data_dir():
    return Path.home() / ".local/share"


def _safe_ext_for(mime):
    ext = mimetypes.guess_extension(mime or "")
    return ext or ""


def _export_path_for(suggested_name, mime):
    """
    Build the canonical output path used for exported attachments.
    Keeps name normalization and mime-based extension logic in one place.
    """
    base = _app_data_dir() / "ubtms" / "tmp"
    base.mkdir(parents=True, exist_ok=True)

    name = (suggested_name or "attachment").strip().replace("/", "_")
    root, ext = os.path.splitext(name)
    if not ext:
        ext = _safe_ext_for(mime)
    return base / f"{root}{ext}"


def get_existing_attachment_path(suggested_name, mime):
    """
    Return absolute file path (str) if an attachment is already present on disk,
    else None.
    """
    out = _export_path_for(suggested_name, mime)
    return str(out) if out.exists() and out.is_file() else None


def is_already_downloaded(suggested_name, mime):
    try:
        out = _export_path_for(suggested_name, mime)
        return is_file_present(out)
    except Exception as e:
        log.exception("is_already_downloaded error: %s", e)
        return False


def ensure_export_file_from_base64(suggested_name, b64_data, mime):
    try:
        out = _export_path_for(suggested_name, mime)
        with open(out, "wb") as f:
            f.write(base64.b64decode(b64_data))
        return str(out)
    except Exception as e:
        log.error("ensure_export_file_from_base64 error: %s", e)
        return None
