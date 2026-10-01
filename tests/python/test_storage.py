# -*- coding: utf-8 -*-
import base64
import hashlib
from pathlib import Path

import pytest
from backend import storage


class TestSafeExtFor:
    def test_known_mime_png(self):
        assert storage._safe_ext_for("image/png") == ".png"

    def test_known_mime_pdf(self):
        assert storage._safe_ext_for("application/pdf") == ".pdf"

    def test_known_mime_json(self):
        assert storage._safe_ext_for("application/json") == ".json"

    def test_unknown_mime(self):
        assert storage._safe_ext_for("application/x-custom-unknown") == ""

    def test_empty_mime(self):
        assert storage._safe_ext_for("") == ""

    def test_none_mime(self):
        assert storage._safe_ext_for(None) == ""


class TestExportPathFor:
    def test_with_explicit_extension(self, tmp_path, monkeypatch):
        monkeypatch.setattr(storage, "_app_data_dir", lambda: tmp_path)
        out = storage._export_path_for("document.pdf", "application/pdf")

        assert out.name == "document.pdf"
        assert out.parent == tmp_path / "ubtms" / "tmp"
        assert out.parent.is_dir()

    def test_without_extension_inferred_from_mime(self, tmp_path, monkeypatch):
        monkeypatch.setattr(storage, "_app_data_dir", lambda: tmp_path)
        out = storage._export_path_for("avatar", "image/png")

        assert out.name == "avatar.png"

    def test_empty_or_none_name_defaults_to_attachment(self, tmp_path, monkeypatch):
        monkeypatch.setattr(storage, "_app_data_dir", lambda: tmp_path)
        out = storage._export_path_for(None, "application/pdf")

        assert out.name == "attachment.pdf"

    def test_sanitizes_slashes_and_whitespace(self, tmp_path, monkeypatch):
        monkeypatch.setattr(storage, "_app_data_dir", lambda: tmp_path)
        out = storage._export_path_for("  nested/path/to/notes.txt  ", "text/plain")

        assert out.name == "nested_path_to_notes.txt"


class TestIsFilePresent:
    def test_file_exists(self, tmp_path):
        sample = tmp_path / "sample.txt"
        sample.write_text("content")

        assert storage.is_file_present(sample) is True

    def test_file_missing(self, tmp_path):
        sample = tmp_path / "missing.txt"

        assert storage.is_file_present(sample) is False

    def test_directory_returns_false(self, tmp_path):
        sample_dir = tmp_path / "sub_dir"
        sample_dir.mkdir()

        assert storage.is_file_present(sample_dir) is False


class TestExistingAttachmentPath:
    def test_returns_path_when_present(self, tmp_path, monkeypatch):
        monkeypatch.setattr(storage, "_app_data_dir", lambda: tmp_path)
        export_file = tmp_path / "ubtms" / "tmp" / "invoice.pdf"
        export_file.parent.mkdir(parents=True, exist_ok=True)
        export_file.write_text("pdf content")

        result = storage.get_existing_attachment_path("invoice.pdf", "application/pdf")

        assert result == str(export_file)

    def test_returns_none_when_missing(self, tmp_path, monkeypatch):
        monkeypatch.setattr(storage, "_app_data_dir", lambda: tmp_path)

        result = storage.get_existing_attachment_path("absent.pdf", "application/pdf")

        assert result is None


class TestIsAlreadyDownloaded:
    def test_true_when_file_exists(self, tmp_path, monkeypatch):
        monkeypatch.setattr(storage, "_app_data_dir", lambda: tmp_path)
        export_file = tmp_path / "ubtms" / "tmp" / "image.png"
        export_file.parent.mkdir(parents=True, exist_ok=True)
        export_file.write_bytes(b"image bytes")

        assert storage.is_already_downloaded("image.png", "image/png") is True

    def test_false_when_file_does_not_exist(self, tmp_path, monkeypatch):
        monkeypatch.setattr(storage, "_app_data_dir", lambda: tmp_path)

        assert storage.is_already_downloaded("image.png", "image/png") is False

    def test_handles_exception_gracefully(self, monkeypatch):
        def raise_error(*args, **kwargs):
            raise RuntimeError("Unexpected failure")

        monkeypatch.setattr(storage, "_export_path_for", raise_error)

        assert storage.is_already_downloaded("file.txt", "text/plain") is False


class TestEnsureExportFileFromBase64:
    def test_successful_decode_and_write(self, tmp_path, monkeypatch):
        monkeypatch.setattr(storage, "_app_data_dir", lambda: tmp_path)
        raw_payload = b"ubtms test attachment payload"
        b64_payload = base64.b64encode(raw_payload).decode("utf-8")

        result_path = storage.ensure_export_file_from_base64("data.bin", b64_payload, "application/octet-stream")

        assert result_path is not None
        saved_file = Path(result_path)
        assert saved_file.exists()
        assert saved_file.read_bytes() == raw_payload

    def test_invalid_base64_returns_none(self, tmp_path, monkeypatch):
        monkeypatch.setattr(storage, "_app_data_dir", lambda: tmp_path)

        result = storage.ensure_export_file_from_base64("bad.bin", "!!!not_valid_b64!!!", "text/plain")

        assert result is None


class TestResolveSettingsDbPath:
    def test_resolves_when_file_exists(self, tmp_path, monkeypatch):
        monkeypatch.setattr(Path, "home", lambda: tmp_path)
        db_name = "testSettingsDb"
        db_hash = hashlib.md5(db_name.encode()).hexdigest()
        db_dir = tmp_path / ".local" / "share" / "ubtms" / "Databases"
        db_dir.mkdir(parents=True, exist_ok=True)
        target_db = db_dir / f"{db_hash}.sqlite"
        target_db.write_text("sqlite stub")

        resolved = storage.resolve_settings_db_path(db_name=db_name, app_id="ubtms")

        assert resolved == str(target_db)

    def test_returns_none_when_not_found(self, tmp_path, monkeypatch):
        monkeypatch.setattr(Path, "home", lambda: tmp_path)

        resolved = storage.resolve_settings_db_path(db_name="absentDb", app_id="ubtms")

        assert resolved is None


class TestResolveQmlDbPath:
    def test_returns_latest_valid_db(self, tmp_path, monkeypatch):
        monkeypatch.setattr(Path, "home", lambda: tmp_path)
        db_dir = tmp_path / ".local" / "share" / "ubtms" / "Databases"
        db_dir.mkdir(parents=True, exist_ok=True)

        db1 = db_dir / "db1.sqlite"
        db1.write_text("older db")
        db2 = db_dir / "db2.sqlite"
        db2.write_text("newer db")

        # Ensure db2 has later mtime
        db1_stat = db1.stat()
        import os
        os.utime(db2, (db1_stat.st_atime + 10, db1_stat.st_mtime + 10))

        monkeypatch.setattr(storage, "check_table_exists", lambda path, table: table == "project_project_app")

        resolved = storage.resolve_qml_db_path(app_id="ubtms")

        assert resolved == str(db2)

    def test_returns_none_when_table_missing(self, tmp_path, monkeypatch):
        monkeypatch.setattr(Path, "home", lambda: tmp_path)
        db_dir = tmp_path / ".local" / "share" / "ubtms" / "Databases"
        db_dir.mkdir(parents=True, exist_ok=True)
        db = db_dir / "empty.sqlite"
        db.write_text("empty")

        monkeypatch.setattr(storage, "check_table_exists", lambda path, table: False)

        resolved = storage.resolve_qml_db_path(app_id="ubtms")

        assert resolved is None

    def test_returns_none_when_no_directory_exists(self, tmp_path, monkeypatch):
        monkeypatch.setattr(Path, "home", lambda: tmp_path)

        resolved = storage.resolve_qml_db_path(app_id="ubtms")

        assert resolved is None
