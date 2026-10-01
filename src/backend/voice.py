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

import ctypes
import multiprocessing
import os
import shutil
import signal
import sys
import threading
import time
import zipfile
from pathlib import Path

import urllib3
from bus import send
from config import get_setting, set_setting
from logger import setup_logger

from .storage import resolve_qml_db_path, resolve_settings_db_path

log = setup_logger()

root_dir = Path(__file__).resolve().parents[2]
if str(root_dir) not in sys.path:
    sys.path.insert(0, str(root_dir))

voice_lib = root_dir / "voice_to_text" / "lib"
if voice_lib.exists() and str(voice_lib) not in sys.path:
    sys.path.insert(0, str(voice_lib))

urllib3.disable_warnings()
http = urllib3.PoolManager(cert_reqs="CERT_NONE")

download_status = {
    "in_progress": False,
    "progress": 0,
    "message": "",
    "error": "",
}

_voice_stop_event = threading.Event()
_voice_download_cancel_event = threading.Event()
_voice_download_action = None


def stop_voice_recognition():
    """Signals the voice recognition thread to stop recording."""
    log.info("[VOICE] stop_voice_recognition called")
    _voice_stop_event.set()
    return True


def get_voice_models_dir():
    """
    Returns the writable directory for voice models.
    On Ubuntu Touch: ~/.local/share/ubtms/voice_models
    """
    data_home = os.environ.get("XDG_DATA_HOME")
    if data_home:
        base_dir = Path(data_home) / "ubtms"
    else:
        base_dir = Path.home() / ".local" / "share" / "ubtms"

    models_dir = base_dir / "voice_models"
    models_dir.mkdir(parents=True, exist_ok=True)
    return models_dir


def is_valid_vosk_model(model_path):
    """
    Check whether a directory contains a supported Vosk model layout.
    """
    try:
        path = Path(model_path)
        if not path.is_dir():
            return False

        has_am_graph = (path / "am").is_dir() and (path / "graph").is_dir()
        has_flat_model = (path / "final.mdl").is_file() and (
            (path / "HCLG.fst").is_file() or (path / "HCLr.fst").is_file()
        )
        return has_am_graph or has_flat_model
    except Exception as e:
        log.warning(f"[VOICE] Error validating model {model_path}: {e}")
        return False


def list_available_models():
    """
    Returns a list of models available for download.
    """
    models = [
        {"id": "vosk-model-small-en-us-0.15", "name": "English (US, Small)", "size": "40M", "url": "https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip"},
        {"id": "vosk-model-en-us-0.22", "name": "English (US)", "size": "1.8G", "url": "https://alphacephei.com/vosk/models/vosk-model-en-us-0.22.zip"},
        {"id": "vosk-model-en-us-0.22-lgraph", "name": "English (US, LGraph)", "size": "128M", "url": "https://alphacephei.com/vosk/models/vosk-model-en-us-0.22-lgraph.zip"},
        {"id": "vosk-model-en-us-0.42-gigaspeech", "name": "English (US, Gigaspeech)", "size": "2.3G", "url": "https://alphacephei.com/vosk/models/vosk-model-en-us-0.42-gigaspeech.zip"},
        {"id": "vosk-model-en-us-daanzu-20200905", "name": "English (US, Daanzu)", "size": "1.0G", "url": "https://alphacephei.com/vosk/models/vosk-model-en-us-daanzu-20200905.zip"},
        {"id": "vosk-model-en-us-daanzu-20200905-lgraph", "name": "English (US, Daanzu LGraph)", "size": "129M", "url": "https://alphacephei.com/vosk/models/vosk-model-en-us-daanzu-20200905-lgraph.zip"},
        {"id": "vosk-model-en-us-librispeech-0.2", "name": "English (US, Librispeech)", "size": "845M", "url": "https://alphacephei.com/vosk/models/vosk-model-en-us-librispeech-0.2.zip"},
        {"id": "vosk-model-small-en-us-zamia-0.5", "name": "English (US, Zamia Small)", "size": "49M", "url": "https://alphacephei.com/vosk/models/vosk-model-small-en-us-zamia-0.5.zip"},
        {"id": "vosk-model-en-us-aspire-0.2", "name": "English (US, Aspire)", "size": "1.4G", "url": "https://alphacephei.com/vosk/models/vosk-model-en-us-aspire-0.2.zip"},
        {"id": "vosk-model-en-us-0.21", "name": "English (US, 0.21)", "size": "1.6G", "url": "https://alphacephei.com/vosk/models/vosk-model-en-us-0.21.zip"},
        {"id": "vosk-model-en-in-0.5", "name": "English (Indian)", "size": "1G", "url": "https://alphacephei.com/vosk/models/vosk-model-en-in-0.5.zip"},
        {"id": "vosk-model-small-en-in-0.4", "name": "English (Indian, Small)", "size": "36M", "url": "https://alphacephei.com/vosk/models/vosk-model-small-en-in-0.4.zip"},
        {"id": "vosk-model-small-cn-0.22", "name": "Chinese (Small)", "size": "42M", "url": "https://alphacephei.com/vosk/models/vosk-model-small-cn-0.22.zip"},
        {"id": "vosk-model-cn-0.22", "name": "Chinese", "size": "1.3G", "url": "https://alphacephei.com/vosk/models/vosk-model-cn-0.22.zip"},
        {"id": "vosk-model-cn-kaldi-multicn-0.15", "name": "Chinese (Multi-cn)", "size": "1.5G", "url": "https://alphacephei.com/vosk/models/vosk-model-cn-kaldi-multicn-0.15.zip"},
        {"id": "vosk-model-ru-0.42", "name": "Russian", "size": "1.8G", "url": "https://alphacephei.com/vosk/models/vosk-model-ru-0.42.zip"},
        {"id": "vosk-model-small-ru-0.22", "name": "Russian (Small)", "size": "45M", "url": "https://alphacephei.com/vosk/models/vosk-model-small-ru-0.22.zip"},
        {"id": "vosk-model-ru-0.22", "name": "Russian (0.22)", "size": "1.5G", "url": "https://alphacephei.com/vosk/models/vosk-model-ru-0.22.zip"},
        {"id": "vosk-model-ru-0.10", "name": "Russian (0.10)", "size": "2.5G", "url": "https://alphacephei.com/vosk/models/vosk-model-ru-0.10.zip"},
        {"id": "vosk-model-small-fr-0.22", "name": "French (Small)", "size": "41M", "url": "https://alphacephei.com/vosk/models/vosk-model-small-fr-0.22.zip"},
        {"id": "vosk-model-fr-0.22", "name": "French", "size": "1.4G", "url": "https://alphacephei.com/vosk/models/vosk-model-fr-0.22.zip"},
        {"id": "vosk-model-small-fr-pguyot-0.3", "name": "French (pguyot Small)", "size": "39M", "url": "https://alphacephei.com/vosk/models/vosk-model-small-fr-pguyot-0.3.zip"},
        {"id": "vosk-model-fr-0.6-linto-2.2.0", "name": "French (Linto)", "size": "1.5G", "url": "https://alphacephei.com/vosk/models/vosk-model-fr-0.6-linto-2.2.0.zip"},
        {"id": "vosk-model-de-0.21", "name": "German", "size": "1.9G", "url": "https://alphacephei.com/vosk/models/vosk-model-de-0.21.zip"},
        {"id": "vosk-model-de-tuda-0.6-900k", "name": "German (Tuda)", "size": "4.4G", "url": "https://alphacephei.com/vosk/models/vosk-model-de-tuda-0.6-900k.zip"},
        {"id": "vosk-model-small-de-0.15", "name": "German (Small)", "size": "45M", "url": "https://alphacephei.com/vosk/models/vosk-model-small-de-0.15.zip"},
        {"id": "vosk-model-small-de-zamia-0.3", "name": "German (Zamia Small)", "size": "49M", "url": "https://alphacephei.com/vosk/models/vosk-model-small-de-zamia-0.3.zip"},
        {"id": "vosk-model-es-0.42", "name": "Spanish", "size": "1.4G", "url": "https://alphacephei.com/vosk/models/vosk-model-es-0.42.zip"},
        {"id": "vosk-model-small-es-0.42", "name": "Spanish (Small)", "size": "39M", "url": "https://alphacephei.com/vosk/models/vosk-model-small-es-0.42.zip"},
        {"id": "vosk-model-pt-fb-v0.1.1-20220516_2113", "name": "Portuguese", "size": "1.6G", "url": "https://alphacephei.com/vosk/models/vosk-model-pt-fb-v0.1.1-20220516_2113.zip"},
        {"id": "vosk-model-small-pt-0.3", "name": "Portuguese (Small)", "size": "31M", "url": "https://alphacephei.com/vosk/models/vosk-model-small-pt-0.3.zip"},
        {"id": "vosk-model-small-tr-0.3", "name": "Turkish (Small)", "size": "35M", "url": "https://alphacephei.com/vosk/models/vosk-model-small-tr-0.3.zip"},
        {"id": "vosk-model-small-vn-0.4", "name": "Vietnamese (Small)", "size": "32M", "url": "https://alphacephei.com/vosk/models/vosk-model-small-vn-0.4.zip"},
        {"id": "vosk-model-vn-0.4", "name": "Vietnamese", "size": "1.4G", "url": "https://alphacephei.com/vosk/models/vosk-model-vn-0.4.zip"},
        {"id": "vosk-model-it-0.22", "name": "Italian", "size": "1.2G", "url": "https://alphacephei.com/vosk/models/vosk-model-it-0.22.zip"},
        {"id": "vosk-model-small-it-0.22", "name": "Italian (Small)", "size": "48M", "url": "https://alphacephei.com/vosk/models/vosk-model-small-it-0.22.zip"},
        {"id": "vosk-model-small-nl-0.22", "name": "Dutch (Small)", "size": "39M", "url": "https://alphacephei.com/vosk/models/vosk-model-small-nl-0.22.zip"},
        {"id": "vosk-model-nl-spraakherkenning-0.6", "name": "Dutch", "size": "860M", "url": "https://alphacephei.com/vosk/models/vosk-model-nl-spraakherkenning-0.6.zip"},
        {"id": "vosk-model-nl-spraakherkenning-0.6-lgraph", "name": "Dutch (LGraph)", "size": "100M", "url": "https://alphacephei.com/vosk/models/vosk-model-nl-spraakherkenning-0.6-lgraph.zip"},
        {"id": "vosk-model-small-ca-0.4", "name": "Catalan (Small)", "size": "42M", "url": "https://alphacephei.com/vosk/models/vosk-model-small-ca-0.4.zip"},
        {"id": "vosk-model-small-fa-0.4", "name": "Persian (Small)", "size": "47M", "url": "https://alphacephei.com/vosk/models/vosk-model-small-fa-0.4.zip"},
        {"id": "vosk-model-small-fa-0.5", "name": "Persian (Small, 0.5)", "size": "60M", "url": "https://alphacephei.com/vosk/models/vosk-model-small-fa-0.5.zip"},
        {"id": "vosk-model-fa-0.5", "name": "Persian", "size": "1.0G", "url": "https://alphacephei.com/vosk/models/vosk-model-fa-0.5.zip"},
        {"id": "vosk-model-small-uk-v3-nano", "name": "Ukrainian (Nano)", "size": "73M", "url": "https://alphacephei.com/vosk/models/vosk-model-small-uk-v3-nano.zip"},
        {"id": "vosk-model-small-uk-v3-small", "name": "Ukrainian (Small)", "size": "133M", "url": "https://alphacephei.com/vosk/models/vosk-model-small-uk-v3-small.zip"},
        {"id": "vosk-model-uk-v3-lgraph", "name": "Ukrainian (LGraph)", "size": "335M", "url": "https://alphacephei.com/vosk/models/vosk-model-uk-v3-lgraph.zip"},
        {"id": "vosk-model-uk-v3", "name": "Ukrainian", "size": "343M", "url": "https://alphacephei.com/vosk/models/vosk-model-uk-v3.zip"},
        {"id": "vosk-model-small-kz-0.15", "name": "Kazakh (Small)", "size": "42M", "url": "https://alphacephei.com/vosk/models/vosk-model-small-kz-0.15.zip"},
        {"id": "vosk-model-kz-0.15", "name": "Kazakh", "size": "374M", "url": "https://alphacephei.com/vosk/models/vosk-model-kz-0.15.zip"},
        {"id": "vosk-model-small-sv-rhasspy-0.15", "name": "Swedish (Small)", "size": "260M", "url": "https://alphacephei.com/vosk/models/vosk-model-small-sv-rhasspy-0.15.zip"},
        {"id": "vosk-model-small-ja-0.22", "name": "Japanese (Small)", "size": "48M", "url": "https://alphacephei.com/vosk/models/vosk-model-small-ja-0.22.zip"},
        {"id": "vosk-model-ja-0.22", "name": "Japanese", "size": "1.0G", "url": "https://alphacephei.com/vosk/models/vosk-model-ja-0.22.zip"},
        {"id": "vosk-model-small-eo-0.42", "name": "Esperanto (Small)", "size": "42M", "url": "https://alphacephei.com/vosk/models/vosk-model-small-eo-0.42.zip"},
        {"id": "vosk-model-el-gr-0.7", "name": "Greek", "size": "1.4G", "url": "https://alphacephei.com/vosk/models/vosk-model-el-gr-0.7.zip"},
        {"id": "vosk-model-small-hi-0.22", "name": "Hindi (Small)", "size": "42M", "url": "https://alphacephei.com/vosk/models/vosk-model-small-hi-0.22.zip"},
        {"id": "vosk-model-hi-0.22", "name": "Hindi", "size": "1.5G", "url": "https://alphacephei.com/vosk/models/vosk-model-hi-0.22.zip"},
        {"id": "vosk-model-small-cs-0.4-rhasspy", "name": "Czech (Small)", "size": "44M", "url": "https://alphacephei.com/vosk/models/vosk-model-small-cs-0.4-rhasspy.zip"},
        {"id": "vosk-model-small-pl-0.22", "name": "Polish (Small)", "size": "51M", "url": "https://alphacephei.com/vosk/models/vosk-model-small-pl-0.22.zip"},
        {"id": "vosk-model-small-uz-0.22", "name": "Uzbek (Small)", "size": "51M", "url": "https://alphacephei.com/vosk/models/vosk-model-small-uz-0.22.zip"},
        {"id": "vosk-model-small-ko-0.22", "name": "Korean (Small)", "size": "70M", "url": "https://alphacephei.com/vosk/models/vosk-model-small-ko-0.22.zip"},
        {"id": "vosk-model-small-tg-0.22", "name": "Tajik (Small)", "size": "37M", "url": "https://alphacephei.com/vosk/models/vosk-model-small-tg-0.22.zip"},
        {"id": "vosk-model-tg-0.22", "name": "Tajik", "size": "342M", "url": "https://alphacephei.com/vosk/models/vosk-model-tg-0.22.zip"},
        {"id": "vosk-model-small-gu-0.42", "name": "Gujarati (Small)", "size": "44M", "url": "https://alphacephei.com/vosk/models/vosk-model-small-gu-0.42.zip"},
        {"id": "vosk-model-small-te-0.42", "name": "Telugu (Small)", "size": "44M", "url": "https://alphacephei.com/vosk/models/vosk-model-small-te-0.42.zip"},
        {"id": "vosk-model-small-ka-0.42", "name": "Georgian (Small)", "size": "45M", "url": "https://alphacephei.com/vosk/models/vosk-model-small-ka-0.42.zip"},
        {"id": "vosk-model-ka-0.42", "name": "Georgian", "size": "700M", "url": "https://alphacephei.com/vosk/models/vosk-model-ka-0.42.zip"},
    ]
    models.sort(key=lambda x: x["name"].lower())
    return models


def list_installed_models():
    app_models_dir = root_dir / "voice_to_text"
    user_models_dir = get_voice_models_dir()

    search_paths = [
        (app_models_dir, "App"),
        (user_models_dir, "User"),
        (Path.home() / ".clickable" / "home" / ".local" / "share" / "ubtms" / "voice_models", "Clickable"),
    ]

    models = []
    seen_names = set()
    available_models = list_available_models()
    known_names = {m["id"]: m["name"] for m in available_models if "id" in m}
    known_names["model"] = "Indian English"

    for root_dir_to_scan, source_label in search_paths:
        if not root_dir_to_scan.exists():
            continue

        for item in root_dir_to_scan.iterdir():
            if item.is_dir() and item.name not in seen_names:
                if not is_valid_vosk_model(item):
                    continue

                if item.name in known_names:
                    model_name = known_names[item.name]
                else:
                    model_name = item.name
                    readme_path = item / "README"
                    if readme_path.exists():
                        try:
                            with open(readme_path, "r", encoding="utf-8") as f:
                                first_line = f.readline().strip()
                            if first_line:
                                clean_name = first_line
                                for phrase in [
                                    "for mobile Vosk applications",
                                    "for Android and iOS",
                                    "Vosk mobile model",
                                    "Vosk model",
                                    "Vosk",
                                    "model",
                                ]:
                                    clean_name = clean_name.replace(phrase, "").strip()
                                if clean_name:
                                    model_name = clean_name
                        except Exception as e:
                            log.error(f"[VOICE] Error reading README for {item.name}: {e}")

                display_name = f"{model_name} (Default)" if source_label == "App" else model_name

                total_size = 0
                try:
                    for f in item.rglob("*"):
                        if f.is_file():
                            total_size += f.stat().st_size
                    model_size = f"{total_size / (1024 * 1024):.1f} MB"
                except Exception:
                    model_size = "Unknown"

                try:
                    rel_path = item.relative_to(root_dir) if source_label == "App" else item
                    models.append({
                        "m_name": display_name,
                        "m_path": str(rel_path),
                        "m_size": model_size,
                        "m_source": source_label,
                    })
                except ValueError:
                    models.append({
                        "m_name": display_name,
                        "m_path": str(item),
                        "m_size": model_size,
                        "m_source": source_label,
                    })

                seen_names.add(item.name)

    models.sort(key=lambda x: x["m_name"].lower())
    log.info(f"[VOICE] Found {len(models)} installed models")
    return models


def get_installed_voice_models():
    models_dir = get_voice_models_dir()
    if not models_dir.exists():
        return []
    installed = [d.name for d in models_dir.iterdir() if d.is_dir()]
    log.info(f"[VOICE] Found {len(installed)} installed models")
    return installed


def get_device_total_ram_mb():
    try:
        with open("/proc/meminfo", "r") as f:
            for line in f:
                if line.startswith("MemTotal:"):
                    return int(line.split()[1]) // 1024
    except Exception:
        pass

    try:
        pagesize = os.sysconf("SC_PAGE_SIZE")
        pages = os.sysconf("SC_PHYS_PAGES")
        return (pagesize * pages) // (1024 * 1024)
    except Exception:
        pass
    return 2048


def get_paused_voice_models():
    models_dir = get_voice_models_dir()
    if not models_dir.exists():
        return []
    return [f.name.replace(".zip.tmp", "") for f in models_dir.glob("*.zip.tmp")]


def get_model_download_status():
    return download_status


def cancel_voice_model_download():
    global download_status, _voice_download_action
    _voice_download_action = "cancel"
    _voice_download_cancel_event.set()
    download_status["in_progress"] = False
    download_status["is_paused"] = False
    download_status["message"] = "Download cancelled"

    models_dir = get_voice_models_dir()
    if models_dir.exists():
        for f in models_dir.glob("*.zip.tmp"):
            try:
                f.unlink()
            except Exception:
                pass

    return {"status": "cancelled"}


def pause_voice_model_download():
    global download_status, _voice_download_action
    _voice_download_action = "pause"
    _voice_download_cancel_event.set()
    download_status["in_progress"] = False
    download_status["is_paused"] = True
    download_status["message"] = "Download paused"
    return {"status": "paused"}


def download_voice_model(model_id, url):
    global download_status
    _voice_download_cancel_event.clear()
    if download_status["in_progress"]:
        return {"status": "error", "message": "Download already in progress"}

    download_status = {
        "in_progress": True,
        "progress": download_status.get("progress", 0),
        "message": "Starting download...",
        "error": "",
        "model_id": model_id,
        "is_paused": False,
    }

    def do_download():
        temp_zip = None
        temp_extract_dir = None
        try:
            models_dir = get_voice_models_dir()
            target_path = models_dir / model_id

            if target_path.exists():
                download_status["in_progress"] = False
                download_status["message"] = "Model already installed"
                download_status["progress"] = 100
                return

            temp_zip = models_dir / f"{model_id}.zip.tmp"
            existing_size = temp_zip.stat().st_size if temp_zip.exists() else 0

            headers = {}
            if existing_size > 0:
                headers["Range"] = f"bytes={existing_size}-"
                log.info(f"[VOICE] Resuming {model_id} from {existing_size} bytes")
                download_status["message"] = "Resuming..."
            else:
                log.info(f"[VOICE] Downloading model from {url}")
                download_status["message"] = "Downloading..."

            response = http.request(
                "GET",
                url,
                headers=headers,
                preload_content=False,
                timeout=urllib3.Timeout(connect=5.0, read=10.0),
            )
            if response.status not in (200, 206, 416):
                raise Exception(f"Server returned status {response.status}")

            if response.status == 200 and existing_size > 0:
                log.info("[VOICE] Server ignored Range, restarting download")
                existing_size = 0
                temp_zip.unlink()

            content_length = response.getheader("Content-Length")
            total_size = (int(content_length) + existing_size) if content_length else None

            if total_size and existing_size == 0:
                try:
                    _, _, free = shutil.disk_usage(str(models_dir))
                    free_mb = free / (1024 * 1024)
                    required_mb = (total_size * 2.5) / (1024 * 1024)
                    if free < total_size * 2.5:
                        raise Exception(f"Insufficient storage. Have {free_mb:.1f} MB, need at least {required_mb:.1f} MB available.")
                except Exception as disk_err:
                    if isinstance(disk_err, Exception) and "Insufficient storage" in str(disk_err):
                        raise disk_err
                    log.warning(f"[VOICE] Could not check disk space: {disk_err}")

            downloaded = existing_size
            mode = "ab" if existing_size > 0 else "wb"
            with open(temp_zip, mode) as f:
                for chunk in response.stream(1024 * 64):
                    if _voice_download_cancel_event.is_set():
                        action = _voice_download_action
                        if action == "pause":
                            raise Exception("PAUSED_BY_USER")
                        else:
                            raise Exception("CANCELLED_BY_USER")
                    f.write(chunk)
                    downloaded += len(chunk)
                    if total_size:
                        progress = int((downloaded / total_size) * 80)
                        download_status["progress"] = progress
                        send("download_progress", progress)

            download_status["message"] = "Extracting..."
            send("download_message", "Extracting...")
            download_status["progress"] = 85
            send("download_progress", 85)

            temp_extract_dir = models_dir / f"{model_id}.extract.tmp"
            if temp_extract_dir.exists():
                shutil.rmtree(temp_extract_dir)
            temp_extract_dir.mkdir(parents=True, exist_ok=True)

            with zipfile.ZipFile(temp_zip) as z:
                z.extractall(temp_extract_dir)

            model_folder = None
            for root_walk, dirs, files in os.walk(temp_extract_dir):
                if "am" in dirs and "graph" in dirs:
                    model_folder = Path(root_walk)
                    break

            if not model_folder:
                subdirs = [d for d in temp_extract_dir.iterdir() if d.is_dir()]
                model_folder = subdirs[0] if len(subdirs) == 1 else temp_extract_dir

            if target_path.exists():
                shutil.rmtree(target_path)
            shutil.move(str(model_folder), str(target_path))

            download_status["progress"] = 100
            download_status["message"] = "Installation complete"
            download_status["in_progress"] = False
            send("download_progress", 100)
            send("download_completed", True)
            log.info(f"[VOICE] Successfully installed model {model_id}")

        except Exception as e:
            err_str = str(e)
            log.exception(f"[VOICE] Download interrupted: {err_str}")
            download_status["in_progress"] = False

            if err_str == "PAUSED_BY_USER":
                download_status["is_paused"] = True
                download_status["message"] = "Paused"
            elif err_str == "CANCELLED_BY_USER":
                download_status["is_paused"] = False
                download_status["message"] = "Cancelled"
                if temp_zip and temp_zip.exists():
                    try:
                        temp_zip.unlink()
                    except Exception:
                        pass
            else:
                download_status["error"] = err_str
                download_status["message"] = "Failed"
                download_status["is_paused"] = True
                send("download_error", err_str)

        finally:
            if temp_extract_dir and temp_extract_dir.exists():
                try:
                    shutil.rmtree(temp_extract_dir)
                except Exception:
                    pass

    threading.Thread(target=do_download, daemon=True).start()
    return {"status": "started"}


def delete_voice_model(model_path):
    try:
        path = Path(model_path)
        user_models_dir = get_voice_models_dir()
        clickable_models_dir = (
            Path.home() / ".clickable" / "home" /
            ".local" / "share" / "ubtms" / "voice_models"
        )

        if not path.is_absolute():
            potential_path = user_models_dir / model_path
            if potential_path.exists():
                path = potential_path
            else:
                potential_path = clickable_models_dir / model_path
                if potential_path.exists():
                    path = potential_path
                else:
                    potential_path = root_dir / model_path
                    if potential_path.exists():
                        path = potential_path

        if not path.exists():
            return {"status": "error", "message": "Model path not found"}

        resolved_path = path.resolve()
        resolved_user_dir = user_models_dir.resolve()
        resolved_clickable_dir = clickable_models_dir.resolve()

        if (
            resolved_user_dir in resolved_path.parents
            or resolved_clickable_dir in resolved_path.parents
        ):
            if resolved_path.is_dir():
                shutil.rmtree(resolved_path)
            else:
                resolved_path.unlink()
            log.info(f"[VOICE] Deleted user model: {model_path}")
            return {"status": "success"}

        app_models_dir = (root_dir / "voice_to_text").resolve()
        if app_models_dir in resolved_path.parents or resolved_path == app_models_dir:
            log.warning(f"[VOICE] Attempted to delete bundled model: {model_path}")
            return {"status": "error", "message": "Cannot delete bundled system models"}

        return {"status": "error", "message": "Permission denied"}
    except Exception as e:
        log.exception(f"[VOICE] Failed to delete model {model_path}: {e}")
        return {"status": "error", "message": str(e)}


def _subprocess_recognize(model_path, pipe, timeout):
    def sigterm_handler(signum, frame):
        raise SystemExit(0)
    signal.signal(signal.SIGTERM, sigterm_handler)

    try:
        from voice_to_text.voice2text import recognize_from_mic

        class PipeStopEvent:
            def is_set(self):
                if pipe.poll():
                    msg = pipe.recv()
                    if msg == "stop":
                        return True
                return False

        def _partial(txt):
            pipe.send(("partial", txt))

        def _status(txt):
            pipe.send(("status", txt))

        text, err = recognize_from_mic(
            verbose=False,
            stop_event=PipeStopEvent(),
            timeout=timeout,
            partial_callback=_partial,
            status_callback=_status,
            model_path=model_path,
        )
        pipe.send(("final", text, err))
    except Exception as e:
        pipe.send(("final", None, f"Subprocess Error: {e}"))


def run_voice_recognition():
    def do_recognition():
        try:
            log.info("[VOICE] Starting offline voice recognition thread")

            db_path = resolve_settings_db_path("myDatabase") or resolve_qml_db_path()

            low_mem_mode = True
            if db_path:
                try:
                    low_mem_mode = get_setting(db_path, "voice_low_memory_mode", "true") == "true"
                except Exception as e:
                    log.warning(f"[VOICE] Could not read low memory setting: {e}")

            active_model_rel_path = ""
            if db_path:
                active_model_rel_path = get_setting(db_path, "active_voice_model", "")

            model_path = None
            if active_model_rel_path:
                if not os.path.isabs(active_model_rel_path):
                    model_path = root_dir / active_model_rel_path
                else:
                    model_path = Path(active_model_rel_path)

            if not model_path or not model_path.exists():
                installed_models = list_installed_models()
                if installed_models:
                    active_model_rel_path = installed_models[0]["m_path"]
                    if not os.path.isabs(active_model_rel_path):
                        model_path = root_dir / active_model_rel_path
                    else:
                        model_path = Path(active_model_rel_path)

                    if db_path:
                        try:
                            set_setting(db_path, "active_voice_model", active_model_rel_path)
                        except Exception as e:
                            log.warning(f"[VOICE] Could not auto-save active model to db: {e}")
                else:
                    log.error("[VOICE] No language model downloaded")
                    send("voice_recognition_error", "No language model downloaded. Please download one in Voice Model Settings.")
                    return

            if model_path and model_path.exists():
                rescore_path = model_path / "rescore"
                rescore_disabled_path = model_path / "rescore.disabled"
                rnnlm_path = model_path / "rnnlm"
                rnnlm_disabled_path = model_path / "rnnlm.disabled"

                if low_mem_mode:
                    if rescore_path.exists() and rescore_path.is_dir():
                        try:
                            rescore_path.rename(rescore_disabled_path)
                            log.info("[VOICE] Disabled rescore folder for low memory mode")
                        except Exception as e:
                            log.warning(f"[VOICE] Could not rename rescore folder: {e}")
                    if rnnlm_path.exists() and rnnlm_path.is_dir():
                        try:
                            rnnlm_path.rename(rnnlm_disabled_path)
                            log.info("[VOICE] Disabled rnnlm folder for low memory mode")
                        except Exception as e:
                            log.warning(f"[VOICE] Could not rename rnnlm folder: {e}")
                else:
                    if rescore_disabled_path.exists() and rescore_disabled_path.is_dir():
                        try:
                            rescore_disabled_path.rename(rescore_path)
                            log.info("[VOICE] Re-enabled rescore folder")
                        except Exception as e:
                            log.warning(f"[VOICE] Could not restore rescore folder: {e}")
                    if rnnlm_disabled_path.exists() and rnnlm_disabled_path.is_dir():
                        try:
                            rnnlm_disabled_path.rename(rnnlm_path)
                            log.info("[VOICE] Re-enabled rnnlm folder")
                        except Exception as e:
                            log.warning(f"[VOICE] Could not restore rnnlm folder: {e}")

                try:
                    hclg_path = model_path / "graph" / "HCLG.fst"
                    if hclg_path.exists():
                        hclg_size = hclg_path.stat().st_size
                        limit = 1.8 * 1024 * 1024 * 1024 if low_mem_mode else 1.0 * 1024 * 1024 * 1024
                        if hclg_size > limit:
                            size_mb = hclg_size / (1024 * 1024)
                            if not low_mem_mode:
                                err_msg = f"The selected model's search graph ({size_mb:.0f} MB) is too large to run with rescoring enabled. Please enable 'Low Memory Mode' in voice settings to run it."
                            else:
                                err_msg = f"The selected model's search graph ({size_mb:.0f} MB) is too large even for Low Memory Mode. Please switch to the LGraph or Small version in settings."
                            log.error(f"[VOICE] {err_msg}")
                            send("voice_recognition_error", err_msg)
                            return
                except Exception as e:
                    log.warning(f"[VOICE] Could not check model graph size: {e}")

            base_voice_path = Path(__file__).resolve().parents[2] / "voice_to_text"
            lib_path = base_voice_path / "lib"

            atomic_lib = lib_path / "libatomic.so.1"
            if atomic_lib.exists():
                try:
                    ctypes.CDLL(str(atomic_lib))
                    log.info(f"[VOICE] Pre-loaded {atomic_lib}")
                except Exception as e:
                    log.warning(f"[VOICE] Could not pre-load libatomic: {e}")

            env_path = str(lib_path)
            if "LD_LIBRARY_PATH" in os.environ:
                os.environ["LD_LIBRARY_PATH"] = f"{env_path}:{os.environ['LD_LIBRARY_PATH']}"
            else:
                os.environ["LD_LIBRARY_PATH"] = env_path

            from voice_to_text.voice2text import list_microphones

            _voice_stop_event.clear()
            log.info(f"[VOICE] mics: {list_microphones()}")

            parent_conn, child_conn = multiprocessing.Pipe()
            ctx = multiprocessing.get_context("spawn")
            p = ctx.Process(target=_subprocess_recognize, args=(str(model_path), child_conn, 30))
            p.start()

            received_final = False
            stop_sent_time = None
            while p.is_alive():
                if _voice_stop_event.is_set():
                    parent_conn.send("stop")
                    _voice_stop_event.clear()
                    if stop_sent_time is None:
                        stop_sent_time = time.time()

                if stop_sent_time is not None and (time.time() - stop_sent_time > 5.0):
                    log.warning("[VOICE] Watchdog triggered: Process failed to stop cleanly. Terminating.")
                    p.terminate()
                    break

                if parent_conn.poll(0.5):
                    msg = parent_conn.recv()
                    if msg[0] == "partial":
                        send("voice_recognition_partial", msg[1])
                    elif msg[0] == "status":
                        send("voice_recognition_status", msg[1])
                    elif msg[0] == "final":
                        received_final = True
                        text, error = msg[1], msg[2]
                        if text:
                            log.info(f"[VOICE] Recognized text: {text}")
                            send("voice_recognition_result", text)
                        else:
                            log.warning(f"[VOICE] Recognition failed: {error or 'No speech detected'}")
                            send("voice_recognition_error", error or "No speech detected")
                        break

            p.join(timeout=1)
            if p.is_alive():
                p.terminate()
                p.join()

            if not received_final:
                exit_code = p.exitcode
                if exit_code is not None and exit_code != 0:
                    err_msg = f"Voice recognition crashed unexpectedly (possibly Out of Memory). Exit code: {exit_code}"
                    log.error(f"[VOICE] {err_msg}")
                    send("voice_recognition_error", err_msg)

        except Exception as e:
            log.exception(f"[VOICE] Error during voice recognition: {e}")
            send("voice_recognition_error", f"System Error: {str(e)}")

    thread = threading.Thread(target=do_recognition)
    thread.daemon = True
    thread.start()
    return True
