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

import sys
from pathlib import Path

# Add project root and voice_to_text/lib to sys.path
root_dir = Path(__file__).resolve().parents[2]
if str(root_dir) not in sys.path:
    sys.path.insert(0, str(root_dir))

voice_lib = root_dir / "voice_to_text" / "lib"
if voice_lib.exists() and str(voice_lib) not in sys.path:
    sys.path.insert(0, str(voice_lib))

from logger import setup_logger
log = setup_logger()

from .attachments import (
    attachment_delete,
    attachment_ondemand_download,
    attachment_upload,
    cleanup_orphan_attachment_files,
)
from .auth import (
    check_server_reachability,
    fetch_databases,
    get_db_list,
    http,
    login_odoo,
)
from .storage import (
    _app_data_dir,
    _export_path_for,
    _safe_ext_for,
    ensure_export_file_from_base64,
    get_existing_attachment_path,
    is_already_downloaded,
    is_file_present,
    resolve_qml_db_path,
    resolve_settings_db_path,
)
from .sync import (
    start_sync_in_background,
    sync,
    sync_background,
    sync_in_progress,
    sync_lock,
)
from .voice import (
    cancel_voice_model_download,
    delete_voice_model,
    download_status,
    download_voice_model,
    get_device_total_ram_mb,
    get_installed_voice_models,
    get_model_download_status,
    get_paused_voice_models,
    get_voice_models_dir,
    is_valid_vosk_model,
    list_available_models,
    list_installed_models,
    pause_voice_model_download,
    run_voice_recognition,
    stop_voice_recognition,
)

__all__ = [
    # Logger and HTTP
    "log",
    "http",
    # Auth
    "check_server_reachability",
    "fetch_databases",
    "login_odoo",
    "get_db_list",
    # Storage
    "is_file_present",
    "resolve_qml_db_path",
    "resolve_settings_db_path",
    "_app_data_dir",
    "_safe_ext_for",
    "_export_path_for",
    "get_existing_attachment_path",
    "is_already_downloaded",
    "ensure_export_file_from_base64",
    # Attachments
    "attachment_ondemand_download",
    "attachment_upload",
    "attachment_delete",
    "cleanup_orphan_attachment_files",
    # Sync
    "sync",
    "sync_background",
    "start_sync_in_background",
    "sync_lock",
    "sync_in_progress",
    # Voice
    "stop_voice_recognition",
    "get_voice_models_dir",
    "is_valid_vosk_model",
    "list_installed_models",
    "get_installed_voice_models",
    "get_device_total_ram_mb",
    "get_paused_voice_models",
    "list_available_models",
    "get_model_download_status",
    "cancel_voice_model_download",
    "pause_voice_model_download",
    "download_voice_model",
    "delete_voice_model",
    "run_voice_recognition",
    "download_status",
]
