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


def test_push_helper_prepopulates_task_with_relational_placeholders():
    """
    Test that task push pre-populates allocated hours and creates placeholder rows
    in project_project_app and project_task_type_app.
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
                initial_planned_hours FLOAT,
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
        cur.execute("""
            CREATE TABLE project_project_app (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                account_id INTEGER,
                last_modified datetime,
                status TEXT DEFAULT '',
                has_draft INTEGER DEFAULT 0,
                odoo_record_id INTEGER,
                UNIQUE (odoo_record_id, account_id)
            )
        """)
        cur.execute("""
            CREATE TABLE project_task_type_app (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                account_id INTEGER,
                odoo_record_id INTEGER
            )
        """)
        conn.commit()
        conn.close()

        with patch.object(push_helper_mod, "get_db_path", return_value=tmp_db_path):
            push_payload = json.dumps({
                "notification": {
                    "card": {
                        "summary": "Assigned: Notification Test",
                        "body": "Project: 26-00018 - Test Project 2",
                        "actions": ["ubtms://notification?type=Task&id=1523&odoo_id=1"]
                    }
                },
                "data": {
                    "record": {
                        "model": "project.task",
                        "record_id": 1523,
                        "name": "Notification Test",
                        "project_id": 59,
                        "project_name": "26-00018 - Test Project 2",
                        "stage_id": 1,
                        "stage_name": "Analysis",
                        "allocated_hours": 4.5,
                        "priority": "1"
                    }
                }
            })

            push_helper_mod.process_notification(push_payload)

            conn = sqlite3.connect(tmp_db_path)
            cur = conn.cursor()
            cur.execute("SELECT name, project_id, state, initial_planned_hours FROM project_task_app WHERE odoo_record_id = 1523")
            task_row = cur.fetchone()
            assert task_row is not None
            assert task_row[0] == "Notification Test"
            assert task_row[1] == 59
            assert task_row[2] == 1
            assert task_row[3] == 4.5

            cur.execute("SELECT name, odoo_record_id FROM project_project_app WHERE odoo_record_id = 59")
            proj_row = cur.fetchone()
            assert proj_row is not None
            assert proj_row[0] == "26-00018 - Test Project 2"

            cur.execute("SELECT name, odoo_record_id FROM project_task_type_app WHERE odoo_record_id = 1")
            stage_row = cur.fetchone()
            assert stage_row is not None
            assert stage_row[0] == "Analysis"

            conn.close()
    finally:
        if os.path.exists(tmp_db_path):
            os.remove(tmp_db_path)


def test_push_helper_prepopulates_project_update():
    """
    Test pre-population of project.update into project_update_app.
    """
    with tempfile.NamedTemporaryFile(suffix=".sqlite", delete=False) as f:
        tmp_db_path = f.name

    try:
        conn = sqlite3.connect(tmp_db_path)
        cur = conn.cursor()
        cur.execute("CREATE TABLE users (id INTEGER PRIMARY KEY, is_default INTEGER, name TEXT)")
        cur.execute("INSERT INTO users (id, is_default, name) VALUES (1, 1, 'Default User')")
        cur.execute("""
            CREATE TABLE project_update_app (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                account_id INTEGER,
                name TEXT,
                project_status TEXT,
                progress INTEGER,
                user_id INTEGER,
                description TEXT,
                date TEXT,
                project_id INTEGER,
                odoo_record_id INTEGER,
                last_modified datetime,
                status TEXT DEFAULT '',
                has_draft INTEGER DEFAULT 0
            )
        """)
        cur.execute("""
            CREATE TABLE project_project_app (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                account_id INTEGER,
                last_modified datetime,
                status TEXT DEFAULT '',
                has_draft INTEGER DEFAULT 0,
                odoo_record_id INTEGER
            )
        """)
        conn.commit()
        conn.close()

        with patch.object(push_helper_mod, "get_db_path", return_value=tmp_db_path):
            push_payload = json.dumps({
                "notification": {
                    "card": {
                        "summary": "Update: CIT Operations",
                        "body": "Nov 2nd team meeting (on_track)",
                        "actions": ["ubtms://notification?type=ProjectUpdate&id=71&odoo_id=1"]
                    }
                },
                "data": {
                    "record": {
                        "model": "project.update",
                        "record_id": 71,
                        "name": "Nov 2nd team meeting",
                        "project_id": 60,
                        "project_name": "CIT Operations",
                        "project_status": "on_track",
                        "progress": 75,
                        "date": "2026-11-02",
                        "description": "Discussed roadmap and timeline"
                    }
                }
            })

            push_helper_mod.process_notification(push_payload)

            conn = sqlite3.connect(tmp_db_path)
            cur = conn.cursor()
            cur.execute("SELECT name, project_status, progress, project_id FROM project_update_app WHERE odoo_record_id = 71")
            row = cur.fetchone()
            assert row is not None
            assert row[0] == "Nov 2nd team meeting"
            assert row[1] == "on_track"
            assert row[2] == 75
            assert row[3] == 60

            cur.execute("SELECT name, odoo_record_id FROM project_project_app WHERE odoo_record_id = 60")
            proj_row = cur.fetchone()
            assert proj_row is not None
            assert proj_row[0] == "CIT Operations"

            conn.close()
    finally:
        if os.path.exists(tmp_db_path):
            os.remove(tmp_db_path)


def test_push_helper_prepopulates_activity_with_full_connection_and_assignee():
    """
    Test that mail.activity push notifications pre-populate activity record
    and all relational placeholders (assignee in res_users_app, activity type in mail_activity_type_app,
    task in project_task_app, project in project_project_app).
    """
    with tempfile.NamedTemporaryFile(suffix=".sqlite", delete=False) as f:
        tmp_db_path = f.name

    try:
        conn = sqlite3.connect(tmp_db_path)
        cur = conn.cursor()
        cur.execute("CREATE TABLE users (id INTEGER PRIMARY KEY, is_default INTEGER, name TEXT)")
        cur.execute("INSERT INTO users (id, is_default, name) VALUES (1, 1, 'Default User')")
        cur.execute("""
            CREATE TABLE mail_activity_app (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                account_id INTEGER,
                activity_type_id INTEGER,
                summary TEXT,
                due_date DATE,
                user_id INTEGER,
                notes TEXT,
                odoo_record_id INTEGER,
                last_modified datetime,
                link_id INTEGER,
                project_id INTEGER,
                task_id INTEGER,
                resId INTEGER,
                resModel TEXT,
                state TEXT,
                status TEXT DEFAULT '',
                has_draft INTEGER DEFAULT 0,
                UNIQUE (odoo_record_id, account_id)
            )
        """)
        cur.execute("""
            CREATE TABLE res_users_app (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT,
                odoo_record_id INTEGER,
                account_id INTEGER,
                last_modified datetime,
                status TEXT DEFAULT '',
                UNIQUE (odoo_record_id, account_id)
            )
        """)
        cur.execute("""
            CREATE TABLE mail_activity_type_app (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT,
                odoo_record_id INTEGER,
                account_id INTEGER,
                status TEXT DEFAULT '',
                UNIQUE (odoo_record_id, account_id)
            )
        """)
        cur.execute("""
            CREATE TABLE project_task_app (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                account_id INTEGER,
                odoo_record_id INTEGER,
                project_id INTEGER,
                parent_id INTEGER,
                last_modified datetime,
                status TEXT DEFAULT '',
                has_draft INTEGER DEFAULT 0,
                UNIQUE (odoo_record_id, account_id)
            )
        """)
        cur.execute("""
            CREATE TABLE project_project_app (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT,
                account_id INTEGER,
                odoo_record_id INTEGER,
                last_modified datetime,
                status TEXT DEFAULT '',
                has_draft INTEGER DEFAULT 0,
                UNIQUE (odoo_record_id, account_id)
            )
        """)
        conn.commit()
        conn.close()

        push_helper_path = os.path.join(os.path.dirname(__file__), "..", "..", "push-helper.py")
        spec = importlib.util.spec_from_file_location("push_helper", push_helper_path)
        push_helper_mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(push_helper_mod)

        with patch.object(push_helper_mod, "get_db_path", return_value=tmp_db_path):
            push_payload = json.dumps({
                "notification": {
                    "card": {
                        "summary": "Notify1",
                        "body": "Due: 2026-11-09 - Notification Test",
                        "actions": ["ubtms://notification?type=Activity&id=455&odoo_id=1"]
                    },
                    "data": {
                        "model": "mail.activity",
                        "record_id": 455,
                        "summary": "Notify1",
                        "due_date": "2026-11-09",
                        "res_id": 1523,
                        "res_model": "project.task",
                        "res_name": "Notification Test",
                        "link_id": 1523,
                        "task_id": 1523,
                        "task_name": "Notification Test",
                        "parent_id": None,
                        "project_id": 59,
                        "project_name": "26-00018 - Test Project 2 [Parent]",
                        "user_id": 177,
                        "assignee_name": "Suraj Yadav",
                        "activity_type_id": 4,
                        "activity_type_name": "To-Do",
                        "notes": "Activity description notes"
                    }
                }
            })

            push_helper_mod.process_notification(push_payload)

            conn = sqlite3.connect(tmp_db_path)
            cur = conn.cursor()
            cur.execute("SELECT summary, due_date, user_id, activity_type_id, link_id, task_id, project_id, resModel FROM mail_activity_app WHERE odoo_record_id = 455")
            row = cur.fetchone()
            assert row is not None
            assert row[0] == "Notify1"
            assert row[1] == "2026-11-09"
            assert row[2] == 177
            assert row[3] == 4
            assert row[4] == 1523
            assert row[5] == 1523
            assert row[6] == 59
            assert row[7] == "project.task"

            # Check assignee placeholder
            cur.execute("SELECT name, odoo_record_id FROM res_users_app WHERE odoo_record_id = 177")
            user_row = cur.fetchone()
            assert user_row is not None
            assert user_row[0] == "Suraj Yadav"

            # Check activity type placeholder
            cur.execute("SELECT name, odoo_record_id FROM mail_activity_type_app WHERE odoo_record_id = 4")
            type_row = cur.fetchone()
            assert type_row is not None
            assert type_row[0] == "To-Do"

            # Check task placeholder
            cur.execute("SELECT name, odoo_record_id, project_id FROM project_task_app WHERE odoo_record_id = 1523")
            task_row = cur.fetchone()
            assert task_row is not None
            assert task_row[0] == "Notification Test"
            assert task_row[2] == 59

            # Check project placeholder
            cur.execute("SELECT name, odoo_record_id FROM project_project_app WHERE odoo_record_id = 59")
            proj_row = cur.fetchone()
            assert proj_row is not None
            assert proj_row[0] == "26-00018 - Test Project 2 [Parent]"

            conn.close()
    finally:
        if os.path.exists(tmp_db_path):
            os.remove(tmp_db_path)


def test_notification_payload_contains_all_required_fields_and_account_id():
    """
    Verify that incoming notifications store all rich fields in notification.payload
    and correctly associate the resolved account_id in the notification table and SQLite tables.
    """
    with tempfile.NamedTemporaryFile(suffix=".sqlite", delete=False) as tmp_db:
        tmp_db_path = tmp_db.name

    try:
        conn = sqlite3.connect(tmp_db_path)
        cur = conn.cursor()

        # Schema with users table containing multiple accounts
        cur.execute("""
            CREATE TABLE users (
                id INTEGER PRIMARY KEY,
                name TEXT,
                link TEXT,
                database TEXT,
                username TEXT,
                is_default INTEGER DEFAULT 0
            )
        """)
        cur.execute("INSERT INTO users (id, name, link, database, username, is_default) VALUES (1, 'Local', '', '', '', 0)")
        cur.execute("INSERT INTO users (id, name, link, database, username, is_default) VALUES (2, 'Remote Company A', 'https://odoo-a.example.com', 'db_a', 'admin_a', 1)")
        cur.execute("INSERT INTO users (id, name, link, database, username, is_default) VALUES (3, 'Remote Company B', 'https://odoo-b.example.com', 'db_b', 'admin_b', 0)")

        cur.execute("""
            CREATE TABLE notification (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                account_id INTEGER,
                timestamp TEXT,
                message TEXT,
                type TEXT,
                payload TEXT,
                read_status INTEGER DEFAULT 0,
                panel_invoked INTEGER DEFAULT 0
            )
        """)
        cur.execute("""
            CREATE TABLE project_task_app (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT,
                account_id INTEGER,
                project_id INTEGER,
                sub_project_id INTEGER,
                parent_id INTEGER,
                start_date date,
                end_date date,
                deadline date,
                initial_planned_hours FLOAT,
                priority TEXT,
                state INTEGER,
                personal_stage INTEGER,
                description TEXT,
                last_modified datetime,
                user_id INTEGER,
                create_uid INTEGER,
                status TEXT DEFAULT '',
                has_draft INTEGER DEFAULT 0,
                odoo_record_id INTEGER
            )
        """)
        cur.execute("CREATE TABLE project_project_app (id INTEGER PRIMARY KEY, name TEXT, account_id INTEGER, odoo_record_id INTEGER, last_modified datetime, status TEXT, has_draft INTEGER)")
        cur.execute("CREATE TABLE project_task_type_app (id INTEGER PRIMARY KEY, name TEXT, account_id INTEGER, odoo_record_id INTEGER)")
        cur.execute("CREATE TABLE res_users_app (id INTEGER PRIMARY KEY, name TEXT, account_id INTEGER, odoo_record_id INTEGER, status TEXT)")
        conn.commit()
        conn.close()

        with patch.object(push_helper_mod, "get_db_path", return_value=tmp_db_path):
            push_input = {
                "notification": {
                    "card": {
                        "summary": "Assigned: Design System Overhaul",
                        "body": "Project: Core UI",
                        "popup": True
                    }
                },
                "data": {
                    "record": {
                        "model": "project.task",
                        "record_id": 8801,
                        "name": "Design System Overhaul",
                        "project_id": 44,
                        "project_name": "Core UI",
                        "parent_id": 12,
                        "stage_id": 3,
                        "stage_name": "In Progress",
                        "personal_stage": 101,
                        "user_id": 20,
                        "assignee_name": "John Doe",
                        "create_uid": 15,
                        "assigner_name": "Jane Lead",
                        "assigner_avatar": "iVBORw0KGgoAAAANSUhEUg==",
                        "deadline": "2026-11-20",
                        "start_date": "2026-11-10",
                        "end_date": "2026-11-25",
                        "allocated_hours": 16.5,
                        "priority": "2",
                        "description": "Rebuild design token architecture",
                        "odoo_url": "https://odoo-b.example.com",
                        "db": "db_b",
                        "username": "admin_b",
                        "account_user_id": 20
                    }
                }
            }

            push_helper_mod.process_notification(json.dumps(push_input))

            conn = sqlite3.connect(tmp_db_path)
            cur = conn.cursor()

            # Verify notification row
            cur.execute("SELECT account_id, type, payload FROM notification WHERE type = 'Task'")
            notif_row = cur.fetchone()
            assert notif_row is not None
            # Must match Account ID 3 (odoo-b.example.com)
            assert notif_row[0] == 3

            parsed_payload = json.loads(notif_row[2])
            assert parsed_payload["name"] == "Design System Overhaul"
            assert parsed_payload["project_name"] == "Core UI"
            assert parsed_payload["assigner_name"] == "Jane Lead"
            assert parsed_payload["assigner_avatar"] == "iVBORw0KGgoAAAANSUhEUg=="
            assert parsed_payload["stage_name"] == "In Progress"
            assert parsed_payload["deadline"] == "2026-11-20"
            assert parsed_payload["priority"] == "2"
            assert parsed_payload["account_id"] == 3
            assert parsed_payload["odoo_record_id"] == 8801

            # Verify project_task_app populated row
            cur.execute("""
                SELECT name, account_id, project_id, parent_id, state, personal_stage,
                       user_id, create_uid, deadline, start_date, end_date, initial_planned_hours,
                       priority, description, odoo_record_id
                FROM project_task_app WHERE odoo_record_id = 8801
            """)
            task_row = cur.fetchone()
            assert task_row is not None
            assert task_row[0] == "Design System Overhaul"
            assert task_row[1] == 3
            assert task_row[2] == 44
            assert task_row[3] == 12
            assert task_row[4] == 3
            assert task_row[5] == 101
            assert task_row[6] == 20
            assert task_row[7] == 15
            assert task_row[8] == "2026-11-20"
            assert task_row[9] == "2026-11-10"
            assert task_row[10] == "2026-11-25"
            assert task_row[11] == 16.5
            assert task_row[12] == "2"
            assert task_row[13] == "Rebuild design token architecture"
            assert task_row[14] == 8801

            conn.close()
    finally:
        if os.path.exists(tmp_db_path):
            os.remove(tmp_db_path)
