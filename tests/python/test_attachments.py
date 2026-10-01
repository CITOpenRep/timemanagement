# -*- coding: utf-8 -*-
from unittest.mock import MagicMock

import pytest
from backend import attachments


class TestAttachmentOndemandDownload:
    def test_account_not_found(self, monkeypatch):
        monkeypatch.setattr(attachments, "get_all_accounts", lambda db: [])

        result = attachments.attachment_ondemand_download("fake_db.sqlite", 999, 123)

        assert result == {"success": False, "error": "Account not found"}

    def test_successful_download(self, monkeypatch):
        fake_account = {
            "id": 1,
            "link": "https://odoo.example.com",
            "database": "demo",
            "username": "user",
            "api_key": "key",
        }
        monkeypatch.setattr(attachments, "get_all_accounts", lambda db: [fake_account])

        mock_client = MagicMock()
        mock_client.ondemanddownload.return_value = {"file_path": "/tmp/test.pdf"}
        monkeypatch.setattr(attachments, "OdooClient", lambda *args, **kwargs: mock_client)

        result = attachments.attachment_ondemand_download("fake_db.sqlite", 1, 123)

        assert result["success"] is True
        assert result["file_path"] == "/tmp/test.pdf"

    def test_handles_client_exception(self, monkeypatch):
        fake_account = {
            "id": 1,
            "link": "https://odoo.example.com",
            "database": "demo",
            "username": "user",
            "api_key": "key",
        }
        monkeypatch.setattr(attachments, "get_all_accounts", lambda db: [fake_account])

        def raise_download_error(*args, **kwargs):
            raise ConnectionError("Server refused connection")

        monkeypatch.setattr(attachments, "OdooClient", raise_download_error)

        result = attachments.attachment_ondemand_download("fake_db.sqlite", 1, 123)

        assert result["success"] is False
        assert "Server refused connection" in result["error"]
