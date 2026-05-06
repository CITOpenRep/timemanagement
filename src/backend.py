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


from config import get_all_accounts, initialize_app_settings_db, update_last_synced_at, get_setting
from odoo_client import OdooClient
from sync_from_odoo import sync_all_from_odoo,sync_ondemand_tables_from_odoo
from sync_to_odoo import sync_all_to_odoo
from logger import setup_logger
from bus import send

log = setup_logger()
import os
import sys
from pathlib import Path
import ctypes

# Add root directory and voice_to_text/lib to sys.path
root_dir = Path(__file__).parent.parent.resolve()
if str(root_dir) not in sys.path:
    sys.path.insert(0, str(root_dir))

voice_lib = root_dir / "voice_to_text" / "lib"
if voice_lib.exists() and str(voice_lib) not in sys.path:
    sys.path.insert(0, str(voice_lib))

import platform
import urllib3
import json
import xmlrpc.client
from common import check_table_exists, write_sync_report_to_db
import threading
import base64
import mimetypes

sync_lock = threading.Lock()
sync_in_progress = False  # Global flag

urllib3.disable_warnings()

http = urllib3.PoolManager(cert_reqs="CERT_NONE")

# Voice model download state
download_status = {
    "in_progress": False,
    "progress": 0,
    "message": "",
    "error": ""
}


def is_file_present(file_path):
    """
    Check if a file exists at the specified path.
    
    Args:
        file_path (str): Path to the file to check
        
    Returns:
        bool: True if file exists and is a file, False otherwise
        
    Note:
        Logs information about file existence status.
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
    
    Args:
        app_id (str): Application identifier, defaults to "ubtms"
        
    Returns:
        str or None: Path to the SQLite database file if found, None otherwise
        
    Note:
        Searches for SQLite files in standard user directories and clickable sandbox.
        Validates the database by checking for required tables like 'project_project_app'.
        Returns the most recently modified valid database file.
    """
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
    """
    Fetch available databases from an Odoo server and determine UI visibility options.
    
    Args:
        url (str): Odoo server URL
        
    Returns:
        list: List of available database names
        
    Note:
        Also sets visibility dictionary for UI components based on database count:
        - text_field: True if no databases found
        - single_db: Database name if only one database
        - menu_items: List of databases if multiple found
    """
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
    """
    Authenticate user credentials against an Odoo server.
    
    Args:
        selected_url (str): Odoo server URL
        username (str): Username for authentication
        password (str): Password for authentication  
        selected_db (str): Database name to authenticate against
        
    Returns:
        dict: Authentication result containing:
            - status: "pass" if successful, "fail" if failed
            - name_of_user: Full name of authenticated user
            - database: Database name used
            - uid: User ID from Odoo
            
    Note:
        Uses Odoo's XML-RPC API for authentication and fetches user details on success.
    """
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
    """
    Retrieve list of available databases from an Odoo server.
    
    Args:
        url (str): Odoo server URL
        
    Returns:
        list: List of database names available on the server. Returns empty list on error.
        
    Note:
        Makes HTTP POST request to /web/database/list endpoint.
        Handles connection errors gracefully.
    """
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

import os, base64, mimetypes
from pathlib import Path

def _app_data_dir():
    # adjust to your app-id if you want a subdir
    return Path.home() / ".local/share"

def _safe_ext_for(mime):
    ext = mimetypes.guess_extension(mime or "")
    return ext or ""

# --- ADD BELOW EXISTING HELPERS ---

def _export_path_for(suggested_name, mime):
    """
    Build the canonical output path we use for exported attachments.
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
        print("ensure_export_file_from_base64 error:", e)
        return None


def attachment_ondemand_download(settings_db,account_id, remote_record_id):
    accounts = get_all_accounts(settings_db)
    selected = None
    for acc in accounts:
        if acc.get("id") == account_id:
            selected = acc
            break

    if not selected:
        return None

    client = OdooClient(
        selected["link"],
        selected["database"],
        selected["username"],
        selected["api_key"],
    )
    return client.ondemanddownload(remote_record_id,selected["username"],selected["api_key"],False)

def attachment_upload(settings_db,account_id, filepath,res_type,res_id):
    send("ondemand_upload_message","Initiating upload")
    log.debug(f"[SYNC] Starting attachment_upload  to {account_id} : {filepath} , {res_type} ,{res_id}")
    accounts = get_all_accounts(settings_db)
    selected = None
    for acc in accounts:
        if acc.get("id") == account_id:
            selected = acc
            break

    if not selected:
        return None
    send("ondemand_upload_message","Finding Account")
    filename = os.path.basename(filepath)
    EXT_TO_MIME = {
        '.jpg': 'image/jpeg',
        '.jpeg': 'image/jpeg',
        '.png': 'image/png',
        '.gif': 'image/gif',
        '.pdf': 'application/pdf',
        '.txt': 'text/plain',
        '.csv': 'text/csv',
        '.mp3': 'audio/mpeg',
        '.mp4': 'video/mp4',
        '.zip': 'application/zip'
        # add more extensions as needed
    }
    send("ondemand_upload_message","Reading file ...")
    ext = os.path.splitext(filename)[1].lower()  # get extension including dot
    mimetype = EXT_TO_MIME.get(ext, 'application/octet-stream')

    file_bytes=None
    # Read file content as binary
    with open(filepath, 'rb') as f:
       file_bytes = f.read()

    client = OdooClient(
        selected["link"],
        selected["database"],
        selected["username"],
        selected["api_key"],
    )

    # Attach a file to the newly created partner
    vals = {
        'name': filename,
        'type': 'binary',
        'res_model':res_type,
        'res_id':res_id,
        'datas': base64.b64encode(file_bytes).decode('utf-8'),
        'mimetype': mimetype
    }
    send("ondemand_upload_message","Uploading file .. ")
    attachment_id = client.call('ir.attachment', 'create', [vals])
    if attachment_id <=0:
        send("ondemand_upload_completed",False)
    send("ondemand_upload_message","Syncing to local device .. ")
    sync_ondemand_tables_from_odoo(client, selected["id"], settings_db, account_name=selected.get("name", ""))
    send("ondemand_upload_completed",True)
    return attachment_id

def sync(settings_db, account_id):
    """
    Perform synchronous bidirectional sync between local database and Odoo.
    
    Args:
        settings_db (str): Path to the settings database file
        account_id (int): Account ID to sync
        
    Returns:
        bool: True if sync completed successfully
        
    Note:
        Performs complete sync including:
        1. Sync from Odoo to local database
        2. Sync from local database to Odoo
        Updates sync report in database with progress and results.
    """
    send("progress",0)
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
    send("progress",20)
    log.debug("Syncing from oddo from server" + selected["link"])
    sync_all_from_odoo(client, selected["id"], settings_db, account_name=selected.get("name", ""))

    log.debug("Syncing to odoo")
    send("progress",50)
    sync_all_to_odoo(client, selected["id"], settings_db)

    write_sync_report_to_db(
        settings_db, account_id, "Successful", "Sync completed successfully"
    )
    send("progress",100)
    return True


def sync_background(settings_db, account_id):
    """
    Perform asynchronous bidirectional sync in a background thread.
    
    Args:
        settings_db (str): Path to the settings database file
        account_id (int): Account ID to sync
        
    Returns:
        bool: True if sync thread started successfully, False if sync already in progress
        
    Note:
        Uses global sync_lock to prevent concurrent sync operations.
        Runs sync in separate thread to avoid blocking UI.
        Updates sync report with progress and handles errors gracefully.
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
            send("sync_progress",0)
            log.debug(f"[SYNC] Starting background sync to {settings_db}...")
            write_sync_report_to_db(
                settings_db, account_id, "In Progress", "Sync job triggered"
            )
            # initialize_app_settings_db(settings_db) , done by js
            accounts = get_all_accounts(settings_db)
            selected = next((acc for acc in accounts if acc["id"] == account_id), None)
            send("sync_progress",20)

            if not selected:
                write_sync_report_to_db(settings_db, account_id, "Failed", "Account not found")
                return

            # Proceed with syncing using `account`
            log.debug(f"[SYNC] Found account: {selected['name']} (ID: {selected['id']})")

            send("sync_progress",25)
            client = OdooClient(
                selected["link"],
                selected["database"],
                selected["username"],
                selected["api_key"],
            )
            send("sync_progress",30)
            log.debug("Syncing from oddo : ID Is " + selected["link"])
            sync_all_from_odoo(client, account_id, settings_db, account_name=selected.get("name", ""))
            send("sync_progress",50)
            log.debug("Syncing to odoo")
            sync_all_to_odoo(client, account_id, settings_db)
            send("sync_progress",90)

            log.debug("[SYNC] Background sync completed.")
            write_sync_report_to_db(
                settings_db,
                account_id,
                "Successful",
                "Sync completed successfully",
            )
            # Record successful sync timestamp for per-account interval tracking
            update_last_synced_at(settings_db, account_id)
            send("sync_progress",100)
            send("sync_completed",True)
        except Exception as e:
            log.exception(f"[SYNC] Error during background sync: {e}")
            write_sync_report_to_db(settings_db, account_id, "Failed", str(e))
            send("sync_completed",False)
        finally:
            with sync_lock:
                sync_in_progress = False

    thread = threading.Thread(target=do_sync)
    thread.start()
    return True  # Return immediately so QML doesn’t wait


def start_sync_in_background(settings_db, account_id):
    """
    Start a background synchronization process.
    
    Args:
        settings_db (str): Path to the settings database file
        account_id (int): Account ID to sync
        
    Returns:
        bool: Result from sync_background function
        
    Note:
        Wrapper function for sync_background to provide a cleaner interface.
    """
    return sync_background(settings_db, account_id)



# Voice to Text STarts Here
_voice_stop_event = threading.Event()

def stop_voice_recognition():
    """Signals the voice recognition thread to stop recording."""
    log.info("[VOICE] stop_voice_recognition called")
    _voice_stop_event.set()
    return True

def get_voice_models_dir():
    """
    Returns the writable directory for voice models.
    On Ubuntu Touch, this is in ~/.local/share/ubtms/voice_models
    """
    data_home = os.environ.get('XDG_DATA_HOME')
    if data_home:
        base_dir = Path(data_home) / "ubtms"
    else:
        base_dir = Path.home() / ".local" / "share" / "ubtms"
    
    models_dir = base_dir / "voice_models"
    models_dir.mkdir(parents=True, exist_ok=True)
    return models_dir


def list_installed_models():
    """
    Scans for installed Vosk models in both the app directory and writable data directory.
    Returns a list of dictionaries with model names, paths, and sizes.
    """
    # 1. App directory models (Read-only on device)
    app_models_dir = root_dir / "voice_to_text"
    
    # 2. User data directory models (Writable)
    user_models_dir = get_voice_models_dir()
    
    search_paths = [
        (app_models_dir, "App"),
        (user_models_dir, "User")
    ]
    
    models = []
    seen_paths = set()
    
    for root_dir_to_scan, source_label in search_paths:
        if not root_dir_to_scan.exists():
            continue
            
        # Standard Vosk models are directories containing 'am' and 'graph' subdirectories
        for item in root_dir_to_scan.iterdir():
            if item.is_dir() and item not in seen_paths:
                am_dir = item / "am"
                graph_dir = item / "graph"
                
                if am_dir.exists() and graph_dir.exists():
                    # Map known model IDs to friendly names
                    known_names = {
                        "vosk-model-small-en-in-0.4": "Indian English",
                        "vosk-model-small-en-us-0.15": "US English",
                        "vosk-model-small-hi-0.22": "Hindi",
                        "vosk-model-small-de-0.15": "German",
                        "vosk-model-small-fr-0.22": "French",
                        "vosk-model-small-es-0.42": "Spanish",
                        "model": "Indian English" # The bundled one is usually named 'model'
                    }
                    
                    if item.name in known_names:
                        model_name = known_names[item.name]
                    else:
                        # Fallback to cleaning README or using folder name
                        model_name = item.name
                        readme_path = item / "README"
                        if readme_path.exists():
                            try:
                                with open(readme_path, 'r') as f:
                                    first_line = f.readline().strip()
                                    if first_line:
                                        clean_name = first_line
                                        noise_phrases = [
                                            "for mobile Vosk applications",
                                            "for Android and iOS",
                                            "Vosk mobile model",
                                            "Vosk model",
                                            "Vosk",
                                            "model"
                                        ]
                                        for phrase in noise_phrases:
                                            clean_name = clean_name.replace(phrase, "").strip()
                                        
                                        if clean_name:
                                            model_name = clean_name
                            except Exception as e:
                                log.error(f"[VOICE] Error reading README for {item.name}: {e}")

                    # Add (Default) suffix for bundled models
                    display_name = model_name
                    if source_label == "App":
                        display_name = f"{model_name} (Default)"

                    # Calculate directory size
                    total_size = 0
                    try:
                        for f in item.rglob('*'):
                            if f.is_file():
                                total_size += f.stat().st_size
                        size_mb = total_size / (1024 * 1024)
                        model_size = f"{size_mb:.1f} MB"
                    except Exception:
                        model_size = "Unknown"

                    try:
                        if source_label == "App":
                            rel_path = item.relative_to(root_dir)
                        else:
                            rel_path = item
                            
                        models.append({
                            "m_name": display_name,
                            "m_path": str(rel_path),
                            "m_size": model_size,
                            "m_source": source_label
                        })
                    except ValueError:
                        models.append({
                            "m_name": display_name,
                            "m_path": str(item),
                            "m_size": model_size,
                            "m_source": source_label
                        })
                    seen_paths.add(item)
    
    log.info(f"[VOICE] Found {len(models)} installed models")
    return models


def list_available_models():
    """
    Returns a list of models available for download.
    """
    return [
        {"id": "vosk-model-small-en-in-0.4", "name": "Indian English (Small)", "size": "36 MB", "url": "https://alphacephei.com/vosk/models/vosk-model-small-en-in-0.4.zip"},
        {"id": "vosk-model-small-en-us-0.15", "name": "US English (Small)", "size": "40 MB", "url": "https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip"},
        {"id": "vosk-model-small-hi-0.22", "name": "Hindi (Small)", "size": "42 MB", "url": "https://alphacephei.com/vosk/models/vosk-model-small-hi-0.22.zip"},
        {"id": "vosk-model-small-de-0.15", "name": "German (Small)", "size": "45 MB", "url": "https://alphacephei.com/vosk/models/vosk-model-small-de-0.15.zip"},
        {"id": "vosk-model-small-fr-0.22", "name": "French (Small)", "size": "41 MB", "url": "https://alphacephei.com/vosk/models/vosk-model-small-fr-0.22.zip"},
        {"id": "vosk-model-small-es-0.42", "name": "Spanish (Small)", "size": "39 MB", "url": "https://alphacephei.com/vosk/models/vosk-model-small-es-0.42.zip"},
    ]


def get_model_download_status():
    """Returns the current download status for UI polling."""
    return download_status


def download_voice_model(model_id, url):
    """
    Initiates a background thread to download and extract a voice model.
    """
    global download_status
    if download_status["in_progress"]:
        return {"status": "error", "message": "Download already in progress"}
    
    download_status = {
        "in_progress": True,
        "progress": 0,
        "message": "Starting download...",
        "error": "",
        "model_id": model_id
    }
    
    def do_download():
        import zipfile
        import io
        try:
            models_dir = get_voice_models_dir()
            target_path = models_dir / model_id
            
            if target_path.exists():
                download_status["in_progress"] = False
                download_status["message"] = "Model already installed"
                download_status["progress"] = 100
                return

            log.info(f"[VOICE] Downloading model from {url}")
            download_status["message"] = "Downloading..."
            
            # Using urllib3 for download
            response = http.request('GET', url, preload_content=False)
            content_length = response.getheader('Content-Length')
            total_size = int(content_length) if content_length else None
            
            buffer = io.BytesIO()
            downloaded = 0
            
            for chunk in response.stream(1024 * 64):
                buffer.write(chunk)
                downloaded += len(chunk)
                if total_size:
                    progress = int((downloaded / total_size) * 80) # 80% for download
                    download_status["progress"] = progress
                    send("download_progress", progress)
            
            download_status["message"] = "Extracting..."
            send("download_message", "Extracting...")
            download_status["progress"] = 85
            send("download_progress", 85)
            
            with zipfile.ZipFile(buffer) as z:
                # Vosk zips usually contain a single top-level folder
                z.extractall(models_dir)
                
            download_status["progress"] = 100
            download_status["message"] = "Installation complete"
            download_status["in_progress"] = False
            send("download_progress", 100)
            send("download_completed", True)
            log.info(f"[VOICE] Successfully installed model {model_id}")
            
        except Exception as e:
            log.error(f"[VOICE] Download failed: {e}")
            download_status["in_progress"] = False
            download_status["error"] = str(e)
            download_status["message"] = "Failed"
            send("download_error", str(e))

    threading.Thread(target=do_download, daemon=True).start()
    return {"status": "started"}


def run_voice_recognition():
    """
    Runs voice recognition in a background thread to avoid blocking the UI.
    Uses the offline Vosk engine.
    """
    def do_recognition():
        try:
            log.info("[VOICE] Starting offline voice recognition thread")
            
            # Fetch the active model path from settings
            db_path = resolve_qml_db_path()
            active_model_rel_path = ""
            if db_path:
                active_model_rel_path = get_setting(db_path, "active_voice_model", "")
            
            # Resolve relative path if necessary
            root_dir = Path(__file__).parent.parent.resolve()
            if not active_model_rel_path:
                log.error("[VOICE] No voice model configured")
                send("voice_recognition_error", "No voice model configured. Please download one in Settings.")
                return

            if not os.path.isabs(active_model_rel_path):
                model_path = root_dir / active_model_rel_path
            else:
                model_path = Path(active_model_rel_path)

            if not model_path.exists():
                log.error(f"[VOICE] Model path does not exist: {model_path}")
                send("voice_recognition_error", "Selected voice model not found. Please check your settings.")
                return

            # Paths to search for bundled libraries
            base_voice_path = Path(__file__).parent.parent / "voice_to_text"
            lib_path = base_voice_path / "lib"
            
            # Pre-load libatomic if it exists in our bundle (fixes arm64 dependency issue)
            atomic_lib = lib_path / "libatomic.so.1"
            if atomic_lib.exists():
                try:
                    ctypes.CDLL(str(atomic_lib))
                    log.info(f"[VOICE] Pre-loaded {atomic_lib}")
                except Exception as e:
                    log.warning(f"[VOICE] Could not pre-load libatomic: {e}")
            
            # Add bundled libs to environment for nested dependencies
            env_path = str(lib_path)
            if "LD_LIBRARY_PATH" in os.environ:
                os.environ["LD_LIBRARY_PATH"] = f"{env_path}:{os.environ['LD_LIBRARY_PATH']}"
            else:
                os.environ["LD_LIBRARY_PATH"] = env_path
            
            from voice_to_text.voice2text import recognize_from_mic, list_microphones
            
            # Reset the stop event
            _voice_stop_event.clear()
            
            # Log available mics for debug
            log.info(f"[VOICE] mics: {list_microphones()}")
            
            def handle_partial(txt):
                if txt:
                    send("voice_recognition_partial", txt)
            
            text, error = recognize_from_mic(stop_event=_voice_stop_event, partial_callback=handle_partial, model_path=str(model_path))
            if text:
                log.info(f"[VOICE] Recognized text: {text}")
                send("voice_recognition_result", text)
            else:
                log.warning(f"[VOICE] Recognition failed: {error or 'No speech detected'}")
                send("voice_recognition_error", error or "No speech detected")
        except Exception as e:
            log.exception(f"[VOICE] Error during voice recognition: {e}")
            send("voice_recognition_error", f"System Error: {str(e)}")

    thread = threading.Thread(target=do_recognition)
    thread.daemon = True
    thread.start()
    return True
