# -*- coding: utf-8 -*-
"""
End-to-end integration test suite for the confined push notification architecture.
Covers:
1. Odoo 17+ native WebPush registration, bridge decryption, and push-helper storage.
2. Odoo 14-16 legacy bridge registration, XML-RPC polling, and notification dispatch.
3. Push mode persistence and retrieval for settings UI.
"""

import os
import json
import sqlite3
import tempfile
import struct
from pathlib import Path
from unittest.mock import MagicMock, patch

from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.hkdf import HKDF
from cryptography.hazmat.primitives.serialization import Encoding, PublicFormat

# Set up test environment
import sys
bridge_dir = Path(__file__).resolve().parents[2] / "push-bridge"
if str(bridge_dir) not in sys.path:
    sys.path.insert(0, str(bridge_dir))

os.environ["BRIDGE_DB_PATH"] = ":memory:"
from app import app, b64_url_decode, get_db
from fastapi.testclient import TestClient
bridge_client = TestClient(app)

import importlib.util
push_helper_path = Path(__file__).resolve().parents[2] / "push-helper.py"
spec = importlib.util.spec_from_file_location("push_helper", str(push_helper_path))
push_helper_mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(push_helper_mod)

from odoo_client import OdooClient
from backend.sync import save_push_token, get_push_mode
from config import set_setting, get_setting


def test_e2e_odoo17_native_webpush_flow():
    """
    Test complete lifecycle for Odoo 17+ native WebPush.
    """
    test_token = "ubports_device_token_v17_user1"
    
    # 1. Device asks bridge for subscription endpoint and keys
    sub_res = bridge_client.get(f"/v1/subscription/{test_token}")
    assert sub_res.status_code == 200
    sub_data = sub_res.json()
    endpoint = sub_data["endpoint"]
    p256dh = b64_url_decode(sub_data["keys"]["p256dh"])
    auth = b64_url_decode(sub_data["keys"]["auth"])

    # 2. OdooClient connects to Odoo 17+ and registers the bridge endpoint
    with patch.object(OdooClient, "_login", return_value=1), \
         patch.object(OdooClient, "_get_model_proxy") as mock_proxy, \
         patch("urllib.request.urlopen") as mock_urlopen:

        mock_models = MagicMock()
        mock_proxy.return_value = mock_models

        def fake_execute_kw(db, uid, pwd, model, method, *args, **kwargs):
            if model == 'res.users' and method == 'register_ubports_token':
                raise Exception("Method register_ubports_token not found")
            if model == 'mail.partner.device' and method == 'get_web_push_vapid_public_key':
                return "server_vapid_key_xyz"
            if model == 'mail.partner.device' and method == 'register_devices':
                return True
            return False

        mock_models.execute_kw.side_effect = fake_execute_kw

        mock_resp = MagicMock()
        mock_resp.status = 200
        mock_resp.read.return_value = json.dumps(sub_data).encode("utf-8")
        mock_urlopen.return_value.__enter__.return_value = mock_resp

        client = OdooClient("https://odoo17.example.com", "prod", "user", "pass")
        with patch.object(client, "get_server_major_version", return_value=17):
            reg_result = client.register_push_device(test_token, bridge_url="https://bridge.local")
            assert reg_result == {"mode": "native", "success": True}

    # 3. Odoo triggers a notification -> encrypts with RFC 8188 and posts to bridge relay
    receiver_pub_key = ec.EllipticCurvePublicKey.from_encoded_point(ec.SECP256R1(), p256dh)
    sender_priv = ec.generate_private_key(ec.SECP256R1(), default_backend())
    sender_pub = sender_priv.public_key().public_bytes(Encoding.X962, PublicFormat.UncompressedPoint)

    salt = os.urandom(16)
    context = b"WebPush: info\x00" + p256dh + sender_pub
    key_info = b"Content-Encoding: aes128gcm\x00"
    nonce_info = b"Content-Encoding: nonce\x00"

    hkdf_auth = HKDF(algorithm=hashes.SHA256(), length=32, salt=auth, info=context, backend=default_backend())
    secret = hkdf_auth.derive(sender_priv.exchange(ec.ECDH(), receiver_pub_key))

    key = HKDF(algorithm=hashes.SHA256(), length=16, salt=salt, info=key_info, backend=default_backend()).derive(secret)
    nonce = HKDF(algorithm=hashes.SHA256(), length=12, salt=salt, info=nonce_info, backend=default_backend()).derive(secret)

    payload_json = json.dumps({
        "title": "Activity Assigned",
        "options": {
            "body": "Review timesheet entries",
            "data": {"model": "mail.activity", "res_id": 42}
        }
    })
    ciphertext = AESGCM(key).encrypt(nonce, payload_json.encode("utf-8") + b"\x02", None)
    header = struct.pack("!16sLB", salt, 4096, len(sender_pub)) + sender_pub
    encrypted_body = header + ciphertext

    with patch("requests.post") as mock_ubports_post:
        mock_ubports_post.return_value = MagicMock(status_code=201, text="OK")
        relay_res = bridge_client.post(
            f"/v1/relay/{test_token}",
            content=encrypted_body,
            headers={"Content-Encoding": "aes128gcm"}
        )
        assert relay_res.status_code == 201

        # Check bridge forwarded correct card to UBports with avatar and deep link
        assert mock_ubports_post.called
        forwarded_card = mock_ubports_post.call_args.kwargs["json"]["data"]["notification"]["card"]
        assert forwarded_card["summary"] == "Activity Assigned"
        assert forwarded_card["body"] == "Review timesheet entries"
        assert forwarded_card["icon"] == "assets/logo.png"
        assert "ubtms://notification?type=Activity&id=42&odoo_id=1" in forwarded_card["actions"]

    # 4. Device push-helper receives UBports notification and persists in app DB
    with tempfile.NamedTemporaryFile(suffix=".sqlite", delete=False) as tmp_db:
        tmp_db_path = tmp_db.name

    try:
        with patch.object(push_helper_mod, "get_db_path", return_value=tmp_db_path):
            input_notification = json.dumps({
                "notification": {
                    "card": forwarded_card
                }
            })
            processed_output = push_helper_mod.process_notification(input_notification)
            processed_data = json.loads(processed_output)

            assert processed_data["notification"]["card"]["summary"] == "Activity Assigned"
            assert processed_data["notification"]["card"]["popup"] is True
            assert processed_data["notification"]["card"]["icon"] == "assets/logo.png"
            assert "ubtms://notification?type=Activity&id=42&odoo_id=1" in processed_data["notification"]["card"]["actions"]

            # Verify SQLite record inserted for in-app notification bell with odoo_record_id
            conn = sqlite3.connect(tmp_db_path)
            cursor = conn.cursor()
            cursor.execute("SELECT type, message, read_status, panel_invoked, payload FROM notification")
            row = cursor.fetchone()
            conn.close()

            assert row is not None
            assert row[0] == "Activity"
            assert row[1] == "Review timesheet entries"
            assert row[2] == 0
            assert row[3] == 1
            stored_payload = json.loads(row[4])
            assert stored_payload["odoo_record_id"] == 42
            assert stored_payload["is_odoo_id"] is True
    finally:
        if os.path.exists(tmp_db_path):
            os.remove(tmp_db_path)


def test_e2e_odoo14_16_legacy_polling_flow():
    """
    Test complete lifecycle for Odoo 14-16 legacy bridge polling.
    """
    test_token = "ubports_device_token_v16_user2"

    # 1. Client detects Odoo 16 and registers legacy subscription on bridge
    with patch.object(OdooClient, "_login", return_value=2), \
         patch.object(OdooClient, "_get_model_proxy") as mock_proxy, \
         patch("urllib.request.urlopen") as mock_urlopen:

        mock_models = MagicMock()
        mock_models.execute_kw.side_effect = Exception("Native models not found")
        mock_proxy.return_value = mock_models
        mock_resp = MagicMock()
        mock_resp.status = 200
        mock_resp.read.return_value = json.dumps({"status": "registered", "mode": "legacy_bridge"}).encode("utf-8")
        mock_urlopen.return_value.__enter__.return_value = mock_resp

        client = OdooClient("https://odoo16.example.com", "db16", "user", "pass")
        with patch.object(client, "get_server_major_version", return_value=16):
            reg_result = client.register_push_device(test_token, bridge_url="https://bridge.local")
            assert reg_result == {"mode": "legacy_bridge", "success": True}

    # 2. Directly register on bridge to simulate live state
    reg_payload = {
        "ubports_token": test_token,
        "odoo_url": "https://odoo16.example.com",
        "db": "db16",
        "username": "user",
        "password": "pass",
        "uid": 2,
        "poll_interval": 300
    }
    bridge_client.post("/v1/legacy/register", json=reg_payload)

    # 3. Bridge polling worker runs
    with patch("xmlrpc.client.ServerProxy") as mock_xmlrpc, patch("requests.post") as mock_ubports_post:
        mock_ubports_post.return_value = MagicMock(status_code=201, text="OK")
        mock_models = MagicMock()
        mock_xmlrpc.return_value = mock_models

        # Seed initial state
        activities = [{"id": 200, "summary": "Old Activity", "date_deadline": "2026-11-01", "res_name": "Task 1"}]
        def fake_exec(db, uid, pwd, model, method, args, kwargs):
            if model == "mail.activity":
                return activities
            return []
        mock_models.execute_kw.side_effect = fake_exec
        bridge_client.post("/v1/legacy/poll")

        # New activity arrives in Odoo
        activities = [
            {"id": 201, "summary": "Urgent Review", "date_deadline": "2026-11-04", "res_name": "Bug 404"},
            {"id": 200, "summary": "Old Activity", "date_deadline": "2026-11-01", "res_name": "Task 1"}
        ]
        poll_res = bridge_client.post("/v1/legacy/poll")
        assert poll_res.status_code == 200
        assert poll_res.json()["notifications_sent"] >= 1

        # Verify UBports notification payload
        sent_data = mock_ubports_post.call_args.kwargs["json"]
        assert sent_data["token"] == test_token
        assert sent_data["data"]["notification"]["card"]["summary"] == "Urgent Review"
        assert "Bug 404" in sent_data["data"]["notification"]["card"]["body"]
        assert sent_data["data"]["notification"]["card"]["icon"] == "assets/logo.png"
        assert "ubtms://notification?type=Activity&id=201&odoo_id=1" in sent_data["data"]["notification"]["card"]["actions"]


def test_push_mode_settings_persistence():
    """
    Test push mode persistence in settings database.
    """
    with tempfile.NamedTemporaryFile(suffix=".sqlite", delete=False) as tmp_db:
        tmp_db_path = tmp_db.name

    try:
        set_setting(tmp_db_path, "push_mode", "native")
        set_setting(tmp_db_path, "push_mode_1", "native")
        assert get_push_mode(tmp_db_path, 1) == "native"

        set_setting(tmp_db_path, "push_mode_2", "legacy_bridge")
        assert get_push_mode(tmp_db_path, 2) == "legacy_bridge"

        set_setting(tmp_db_path, "push_mode_3", "direct_addon")
        assert get_push_mode(tmp_db_path, 3) == "direct_addon"
    finally:
        if os.path.exists(tmp_db_path):
            os.remove(tmp_db_path)


def test_direct_companion_addon_registration():
    """
    Test direct push token registration when ubtms_push addon is installed on Odoo.
    """
    with patch.object(OdooClient, "_login", return_value=1), \
         patch.object(OdooClient, "_get_model_proxy") as mock_proxy:

        mock_models = MagicMock()
        mock_proxy.return_value = mock_models
        # Mock res.users.register_ubports_token returning True
        mock_models.execute_kw.return_value = True

        client = OdooClient("https://odoo-selfhosted.example.com", "db", "user", "pass")
        result = client.register_push_device("direct_device_token_xyz")
        assert result == {"mode": "direct_addon", "success": True}

        # Check call on Odoo
        mock_models.execute_kw.assert_called_once_with(
            "db", 1, "pass",
            "res.users", "register_ubports_token",
            ["direct_device_token_xyz"]
        )


def test_push_helper_schedule_and_priority_enforcement():
    """
    Test that push-helper respects working hours, schedule settings, and priority overrides.
    """
    with tempfile.NamedTemporaryFile(suffix=".sqlite", delete=False) as tmp_db:
        tmp_db_path = tmp_db.name

    try:
        # Enable schedule: Mon-Fri, 09:00 - 18:00
        set_setting(tmp_db_path, "notifications_enabled", "true")
        set_setting(tmp_db_path, "notification_schedule_enabled", "true")
        set_setting(tmp_db_path, "notification_active_start", "09:00")
        set_setting(tmp_db_path, "notification_active_end", "18:00")
        set_setting(tmp_db_path, "notification_working_days", "1,2,3,4,5")

        with patch.object(push_helper_mod, "get_db_path", return_value=tmp_db_path):
            # Case 1: Outside working hours -> popup should be False
            with patch("common.is_within_active_hours", return_value=False):
                raw_notif = json.dumps({
                    "notification": {
                        "card": {
                            "summary": "Standard Task Update",
                            "body": "A normal routine update"
                        }
                    }
                })
                out = json.loads(push_helper_mod.process_notification(raw_notif))
                assert out["notification"]["card"]["popup"] is False

            # Case 2: Outside working hours but URGENT priority -> popup should be True (bypass)
            with patch("common.is_within_active_hours", return_value=False):
                urgent_notif = json.dumps({
                    "notification": {
                        "card": {
                            "summary": "Urgent Server Issue",
                            "body": "Production server requires immediate attention",
                            "urgent": True
                        }
                    }
                })
                out = json.loads(push_helper_mod.process_notification(urgent_notif))
                assert out["notification"]["card"]["popup"] is True

            # Case 3: Inside working hours -> popup should be True
            with patch("common.is_within_active_hours", return_value=True):
                normal_notif = json.dumps({
                    "notification": {
                        "card": {
                            "summary": "Regular Task Assigned",
                            "body": "Please review during your shift"
                        }
                    }
                })
                out = json.loads(push_helper_mod.process_notification(normal_notif))
                assert out["notification"]["card"]["popup"] is True
    finally:
        if os.path.exists(tmp_db_path):
            os.remove(tmp_db_path)


def test_push_helper_prepopulates_new_task():
    """
    Test Option 1: Data-bearing push pre-populates a new task into project_task_app in SQLite.
    """
    with tempfile.NamedTemporaryFile(suffix=".sqlite", delete=False) as f:
        tmp_db_path = f.name

    try:
        conn = sqlite3.connect(tmp_db_path)
        cur = conn.cursor()
        cur.execute("CREATE TABLE users (id INTEGER PRIMARY KEY, is_default INTEGER, name TEXT)")
        cur.execute("INSERT INTO users (id, is_default, name) VALUES (1, 1, 'Default User')")
        cur.execute("""
            CREATE TABLE project_task_app (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                account_id INTEGER,
                project_id INTEGER,
                deadline date,
                priority TEXT,
                state INTEGER,
                description TEXT,
                last_modified datetime,
                user_id INTEGER,
                status TEXT DEFAULT '',
                has_draft INTEGER DEFAULT 0,
                odoo_record_id INTEGER,
                UNIQUE (odoo_record_id, account_id)
            )
        """)
        conn.commit()
        conn.close()

        with patch.object(push_helper_mod, "get_db_path", return_value=tmp_db_path):
            push_payload = json.dumps({
                "notification": {
                    "card": {
                        "summary": "Implement Feature X",
                        "body": "Detailed requirements for feature X",
                        "actions": ["ubtms://notification?type=Task&id=105&odoo_id=1"]
                    }
                },
                "data": {
                    "record": {
                        "model": "project.task",
                        "record_id": 105,
                        "name": "Implement Feature X",
                        "description": "Detailed requirements for feature X",
                        "project_id": [42, "Mobile App"],
                        "stage_id": [2, "In Progress"],
                        "deadline": "2026-12-01",
                        "priority": "1"
                    }
                }
            })

            push_helper_mod.process_notification(push_payload)

            conn = sqlite3.connect(tmp_db_path)
            cur = conn.cursor()
            cur.execute("SELECT name, description, project_id, state, deadline, odoo_record_id, has_draft FROM project_task_app WHERE odoo_record_id = 105")
            row = cur.fetchone()
            conn.close()

            assert row is not None
            assert row[0] == "Implement Feature X"
            assert row[1] == "Detailed requirements for feature X"
            assert row[2] == 42
            assert row[3] == 2
            assert row[4] == "2026-12-01"
            assert row[5] == 105
            assert row[6] == 0
    finally:
        if os.path.exists(tmp_db_path):
            os.remove(tmp_db_path)


def test_push_helper_preserves_local_draft():
    """
    Test Decision 1 Option A: Existing record with has_draft=1 preserves user's title/desc edits.
    """
    with tempfile.NamedTemporaryFile(suffix=".sqlite", delete=False) as f:
        tmp_db_path = f.name

    try:
        conn = sqlite3.connect(tmp_db_path)
        cur = conn.cursor()
        cur.execute("CREATE TABLE users (id INTEGER PRIMARY KEY, is_default INTEGER, name TEXT)")
        cur.execute("INSERT INTO users (id, is_default, name) VALUES (1, 1, 'Default User')")
        cur.execute("""
            CREATE TABLE project_task_app (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                account_id INTEGER,
                project_id INTEGER,
                deadline date,
                priority TEXT,
                state INTEGER,
                description TEXT,
                last_modified datetime,
                user_id INTEGER,
                status TEXT DEFAULT '',
                has_draft INTEGER DEFAULT 0,
                odoo_record_id INTEGER,
                UNIQUE (odoo_record_id, account_id)
            )
        """)
        # Insert task with local draft in progress
        cur.execute("""
            INSERT INTO project_task_app (
                name, account_id, project_id, deadline, priority, state, description,
                last_modified, user_id, status, has_draft, odoo_record_id
            ) VALUES ('My Draft Task Title', 1, 10, '2026-11-20', '0', 1, 'My draft notes', '2026-11-01', 1, '', 1, 200)
        """)
        conn.commit()
        conn.close()

        with patch.object(push_helper_mod, "get_db_path", return_value=tmp_db_path):
            push_payload = json.dumps({
                "notification": {
                    "card": {
                        "summary": "Remote Updated Title",
                        "body": "Remote updated description",
                        "actions": ["ubtms://notification?type=Task&id=200&odoo_id=1"]
                    }
                },
                "data": {
                    "record": {
                        "model": "project.task",
                        "record_id": 200,
                        "name": "Remote Updated Title",
                        "description": "Remote updated description",
                        "project_id": 25,
                        "stage_id": 3
                    }
                }
            })

            push_helper_mod.process_notification(push_payload)

            conn = sqlite3.connect(tmp_db_path)
            cur = conn.cursor()
            cur.execute("SELECT name, description, project_id, state, has_draft FROM project_task_app WHERE odoo_record_id = 200")
            row = cur.fetchone()
            conn.close()

            assert row is not None
            # User's draft title and description must be preserved
            assert row[0] == "My Draft Task Title"
            assert row[1] == "My draft notes"
            # Metadata like project and state can still update
            assert row[2] == 25
            assert row[3] == 3
            # has_draft must remain 1
            assert row[4] == 1
    finally:
        if os.path.exists(tmp_db_path):
            os.remove(tmp_db_path)
