# -*- coding: utf-8 -*-
from unittest.mock import MagicMock

import pytest
from backend import auth


class TestCheckServerReachability:
    def test_empty_or_none_url_returns_false(self):
        assert auth.check_server_reachability("") is False
        assert auth.check_server_reachability(None) is False
        assert auth.check_server_reachability("   ") is False

    def test_head_success_returns_true(self, monkeypatch):
        mock_response = MagicMock(status=200)
        monkeypatch.setattr(auth.http, "request", MagicMock(return_value=mock_response))

        result = auth.check_server_reachability("example.com")
        assert result is True

    def test_head_fails_get_succeeds_returns_true(self, monkeypatch):
        def mock_request(method, url, timeout, redirect):
            if method == "HEAD":
                raise RuntimeError("HEAD not supported")
            return MagicMock(status=200)

        monkeypatch.setattr(auth.http, "request", mock_request)

        result = auth.check_server_reachability("https://example.com")
        assert result is True

    def test_both_head_and_get_fail_returns_false(self, monkeypatch):
        def mock_request(method, url, timeout, redirect):
            raise ConnectionError("Host unreachable")

        monkeypatch.setattr(auth.http, "request", mock_request)

        result = auth.check_server_reachability("https://unreachable.local")
        assert result is False


class TestGetDbList:
    def test_successful_response(self, monkeypatch):
        mock_response = MagicMock(
            status=200,
            data=b'{"result": ["production", "staging"]}',
        )
        monkeypatch.setattr(auth.http, "request", MagicMock(return_value=mock_response))

        databases = auth.get_db_list("https://demo.odoo.com")
        assert databases == ["production", "staging"]

    def test_non_200_returns_empty_list(self, monkeypatch):
        mock_response = MagicMock(status=500, data=b"Internal Error")
        monkeypatch.setattr(auth.http, "request", MagicMock(return_value=mock_response))

        databases = auth.get_db_list("https://demo.odoo.com")
        assert databases == []

    def test_network_exception_returns_empty_list(self, monkeypatch):
        def mock_request(*args, **kwargs):
            raise ConnectionError("Network down")

        monkeypatch.setattr(auth.http, "request", mock_request)

        databases = auth.get_db_list("https://demo.odoo.com")
        assert databases == []


class TestFetchDatabases:
    def test_forwards_databases(self, monkeypatch):
        monkeypatch.setattr(auth, "get_db_list", lambda url: ["db1", "db2"])

        result = auth.fetch_databases("https://demo.odoo.com")
        assert result == ["db1", "db2"]

    def test_returns_empty_when_no_dbs(self, monkeypatch):
        monkeypatch.setattr(auth, "get_db_list", lambda url: [])

        result = auth.fetch_databases("https://demo.odoo.com")
        assert result == []


class TestLoginOdoo:
    def test_successful_login(self, monkeypatch):
        mock_common = MagicMock()
        mock_common.authenticate.return_value = 42

        mock_models = MagicMock()
        mock_models.execute_kw.return_value = [{"name": "Jane Doe"}]

        def mock_server_proxy(url):
            if "common" in url:
                return mock_common
            return mock_models

        monkeypatch.setattr(auth.xmlrpc.client, "ServerProxy", mock_server_proxy)

        response = auth.login_odoo("https://demo.odoo.com", "jane", "secret", "demo_db")
        assert response == {
            "status": "pass",
            "name_of_user": "Jane Doe",
            "database": "demo_db",
            "uid": 42,
        }

    def test_failed_authentication(self, monkeypatch):
        mock_common = MagicMock()
        mock_common.authenticate.return_value = False

        monkeypatch.setattr(auth.xmlrpc.client, "ServerProxy", lambda url: mock_common)

        response = auth.login_odoo("https://demo.odoo.com", "wrong", "wrong", "demo_db")
        assert response == {"result": "fail"}
