# -*- coding: utf-8 -*-
from pathlib import Path

import pytest
from backend import voice


class TestVoiceModelsDir:
    def test_respects_xdg_data_home(self, tmp_path, monkeypatch):
        monkeypatch.setenv("XDG_DATA_HOME", str(tmp_path))
        models_dir = voice.get_voice_models_dir()

        assert models_dir == tmp_path / "ubtms" / "voice_models"
        assert models_dir.is_dir()

    def test_falls_back_to_home(self, tmp_path, monkeypatch):
        monkeypatch.delenv("XDG_DATA_HOME", raising=False)
        monkeypatch.setattr(Path, "home", lambda: tmp_path)
        models_dir = voice.get_voice_models_dir()

        assert models_dir == tmp_path / ".local" / "share" / "ubtms" / "voice_models"
        assert models_dir.is_dir()


class TestIsValidVoskModel:
    def test_non_directory_returns_false(self, tmp_path):
        sample_file = tmp_path / "regular_file.txt"
        sample_file.write_text("text")

        assert voice.is_valid_vosk_model(sample_file) is False

    def test_empty_directory_returns_false(self, tmp_path):
        empty_dir = tmp_path / "empty_model"
        empty_dir.mkdir()

        assert voice.is_valid_vosk_model(empty_dir) is False

    def test_am_and_graph_structure_returns_true(self, tmp_path):
        model_dir = tmp_path / "valid_vosk_am_graph"
        (model_dir / "am").mkdir(parents=True)
        (model_dir / "graph").mkdir(parents=True)

        assert voice.is_valid_vosk_model(model_dir) is True

    def test_flat_final_mdl_and_hclg_returns_true(self, tmp_path):
        model_dir = tmp_path / "valid_vosk_flat"
        model_dir.mkdir(parents=True)
        (model_dir / "final.mdl").write_bytes(b"model data")
        (model_dir / "HCLG.fst").write_bytes(b"fst data")

        assert voice.is_valid_vosk_model(model_dir) is True


class TestDeviceRam:
    def test_returns_positive_integer_on_linux(self):
        ram_mb = voice.get_device_total_ram_mb()
        assert isinstance(ram_mb, int)
        assert ram_mb > 0


class TestModelDownloadStatus:
    def test_returns_status_dictionary(self):
        status = voice.get_model_download_status()
        assert isinstance(status, dict)
        assert "in_progress" in status
        assert "progress" in status
        assert "message" in status
        assert "error" in status


class TestVoiceSignals:
    def test_stop_voice_recognition(self):
        result = voice.stop_voice_recognition()
        assert result is True


class TestVoiceModelsOverviewAndCache:
    def test_get_voice_models_overview_returns_expected_keys(self, tmp_path, monkeypatch):
        monkeypatch.setenv("XDG_DATA_HOME", str(tmp_path))
        model_dir = voice.get_voice_models_dir() / "vosk-model-small-en-us-0.15"
        (model_dir / "am").mkdir(parents=True)
        (model_dir / "graph").mkdir(parents=True)
        (model_dir / "am" / "final.mdl").write_bytes(b"0" * 1024)

        overview = voice.get_voice_models_overview()

        assert isinstance(overview, dict)
        assert isinstance(overview["installed"], list)
        assert len(overview["installed"]) == 1
        assert overview["installed"][0]["m_name"] == "English (US, Small)"
        assert isinstance(overview["available"], list)
        assert len(overview["available"]) > 0
        assert isinstance(overview["device_ram_mb"], int) and overview["device_ram_mb"] > 0
        assert isinstance(overview["paused"], list)
        assert isinstance(overview["download_status"], dict)

    def test_delete_voice_model_invalidates_size_cache(self, tmp_path, monkeypatch):
        monkeypatch.setenv("XDG_DATA_HOME", str(tmp_path))
        model_dir = voice.get_voice_models_dir() / "test-custom-model"
        (model_dir / "am").mkdir(parents=True)
        (model_dir / "graph").mkdir(parents=True)
        (model_dir / "am" / "weights.bin").write_bytes(b"1" * 2048)

        models = voice.list_installed_models()
        assert any(m["m_path"] == str(model_dir) for m in models)
        assert str(model_dir) in voice._model_size_cache

        res = voice.delete_voice_model(str(model_dir))
        assert res["status"] == "success"
        assert str(model_dir) not in voice._model_size_cache
