# -*- coding: utf-8 -*-
import inspect
import pytest
import backend


def test_qml_exposed_functions_present():
    required_qml_calls = [
        "resolve_qml_db_path",
        "attachment_upload",
        "attachment_delete",
        "get_existing_attachment_path",
        "attachment_ondemand_download",
        "ensure_export_file_from_base64",
        "list_installed_models",
        "list_available_models",
        "download_voice_model",
        "cancel_voice_model_download",
        "pause_voice_model_download",
        "get_device_total_ram_mb",
        "get_paused_voice_models",
        "get_model_download_status",
        "delete_voice_model",
        "cleanup_orphan_attachment_files",
        "start_sync_in_background",
        "login_odoo",
        "sync",
        "sync_background",
        "check_server_reachability",
        "fetch_databases",
        "get_db_list",
        "is_file_present",
        "resolve_settings_db_path",
        "run_voice_recognition",
        "stop_voice_recognition",
    ]

    for func_name in required_qml_calls:
        assert hasattr(backend, func_name), f"backend is missing required function: {func_name}"
        assert callable(getattr(backend, func_name)), f"backend.{func_name} is not callable"


def test_all_exports_exist():
    for name in backend.__all__:
        assert hasattr(backend, name), f"backend.__all__ exports '{name}' but attribute is missing"


def test_submodules_importable():
    from backend import storage, auth, attachments, sync, voice

    assert storage is not None
    assert auth is not None
    assert attachments is not None
    assert sync is not None
    assert voice is not None


def test_facade_routing():
    # Calling through backend facade routes to the underlying submodule implementation
    assert backend.is_file_present is backend.storage.is_file_present
    assert backend.check_server_reachability is backend.auth.check_server_reachability
    assert backend.attachment_upload is backend.attachments.attachment_upload
    assert backend.sync is backend.sync_mod.sync if hasattr(backend, "sync_mod") else callable(backend.sync)
    assert backend.stop_voice_recognition is backend.voice.stop_voice_recognition
