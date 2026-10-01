# -*- coding: utf-8 -*-
import sys
import pytest
import backend

sync_module = sys.modules["backend.sync"]


class TestSyncLockAndConcurrency:
    def test_sync_background_skips_when_already_in_progress(self, monkeypatch):
        monkeypatch.setattr(sync_module, "sync_in_progress", True)

        result = sync_module.sync_background("test.sqlite", 1)

        assert result is False

    def test_start_sync_in_background_alias(self, monkeypatch):
        called = []

        def mock_sync_bg(db, acc_id):
            called.append((db, acc_id))
            return True

        monkeypatch.setattr(sync_module, "sync_background", mock_sync_bg)

        result = sync_module.start_sync_in_background("test.sqlite", 42)

        assert result is True
        assert called == [("test.sqlite", 42)]
