# -*- coding: utf-8 -*-
"""
Tests for Push Bridge subscription and RFC 8188 WebPush relaying.
"""

import os
import json
import struct
from unittest.mock import patch, MagicMock
from fastapi.testclient import TestClient

from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.hkdf import HKDF
from cryptography.hazmat.primitives.serialization import Encoding, PublicFormat

# Set test db before importing app
os.environ["BRIDGE_DB_PATH"] = ":memory:"
from app import app, b64_url_decode

client = TestClient(app)


def test_health():
    res = client.get("/health")
    assert res.status_code == 200
    assert res.json()["status"] == "ok"


def test_subscription_creation():
    token = "test_device_token_12345"
    res = client.get(f"/v1/subscription/{token}")
    assert res.status_code == 200
    data = res.json()
    assert "endpoint" in data
    assert f"/v1/relay/{token}" in data["endpoint"]
    assert "keys" in data
    assert "p256dh" in data["keys"]
    assert "auth" in data["keys"]


@patch("requests.post")
def test_relay_encrypted_webpush(mock_post):
    mock_post.return_value = MagicMock(status_code=201, text="OK")

    token = "test_device_token_abcde"
    sub_res = client.get(f"/v1/subscription/{token}")
    sub_data = sub_res.json()

    p256dh = b64_url_decode(sub_data["keys"]["p256dh"])
    auth = b64_url_decode(sub_data["keys"]["auth"])

    # Simulate Odoo encrypting a notification
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

    payload_json = json.dumps({"title": "Activity Assigned", "options": {"body": "Review Odoo PR"}})
    ciphertext = AESGCM(key).encrypt(nonce, payload_json.encode("utf-8") + b"\x02", None)

    header = struct.pack("!16sLB", salt, 4096, len(sender_pub)) + sender_pub
    encrypted_body = header + ciphertext

    # Post to bridge relay
    relay_res = client.post(
        f"/v1/relay/{token}",
        content=encrypted_body,
        headers={"Content-Encoding": "aes128gcm"}
    )
    assert relay_res.status_code == 201

    # Verify mock call to UBports
    assert mock_post.called
    sent_payload = mock_post.call_args.kwargs["json"]
    assert sent_payload["token"] == token
    assert sent_payload["data"]["notification"]["card"]["summary"] == "Activity Assigned"
    assert sent_payload["data"]["notification"]["card"]["body"] == "Review Odoo PR"
    assert sent_payload["data"]["notification"]["card"]["icon"] == "assets/logo.png"


def test_legacy_lifecycle_and_polling():
    token = "test_legacy_device_token_999"
    # 1. Register legacy account
    reg_payload = {
        "ubports_token": token,
        "odoo_url": "https://odoo15.example.com",
        "db": "production",
        "username": "employee@example.com",
        "password": "secret_password",
        "uid": 42,
        "poll_interval": 300
    }
    reg_res = client.post("/v1/legacy/register", json=reg_payload)
    assert reg_res.status_code == 200
    assert reg_res.json()["status"] == "registered"
    assert reg_res.json()["mode"] == "legacy_bridge"

    # 2. Check list
    list_res = client.get(f"/v1/legacy/subscriptions/{token}")
    assert list_res.status_code == 200
    subs = list_res.json()["subscriptions"]
    assert len(subs) == 1
    assert subs[0]["uid"] == 42
    assert subs[0]["db"] == "production"

    # 3. Simulate polling with mock Odoo XML-RPC
    with patch("xmlrpc.client.ServerProxy") as mock_xmlrpc, patch("requests.post") as mock_ubports:
        mock_ubports.return_value = MagicMock(status_code=201, text="OK")
        mock_models = MagicMock()
        mock_xmlrpc.return_value = mock_models

        activities_data = [
            {"id": 101, "summary": "Initial Activity", "date_deadline": "2026-11-03", "res_name": "Project Alpha"}
        ]
        tasks_data = [
            {"id": 201, "name": "Initial Task", "project_id": [1, "Alpha"], "stage_id": [1, "Todo"], "date_deadline": False, "description": ""}
        ]
        projects_data = [
            {"id": 301, "name": "Initial Project", "user_id": [42, "User 42"], "date_start": "2026-11-01", "date": "2026-12-01", "allocated_hours": 10.0, "description": ""}
        ]
        updates_data = [
            {"id": 401, "name": "Initial Update", "status": "on_track", "progress": 10, "project_id": [1, "Alpha"], "user_id": [42, "User 42"], "date": "2026-11-01", "description": ""}
        ]

        def fake_execute_kw(db, uid, pwd, model, method, args, kwargs):
            if uid != 42:
                return []
            if model == "res.users":
                return [{"id": 42, "partner_id": [142, "User 42"]}]
            if model == "mail.activity":
                return activities_data
            if model == "project.task":
                if method == "search":
                    return [t["id"] for t in tasks_data]
                return tasks_data
            if model == "project.project":
                return projects_data
            if model == "project.update":
                return updates_data
            return []

        mock_models.execute_kw.side_effect = fake_execute_kw

        # First poll: seeds initial state (act_id=101, task_id=201, proj_id=301, update_id=401)
        poll_res = client.post("/v1/legacy/poll")
        assert poll_res.status_code == 200
        assert poll_res.json()["accounts_polled"] >= 1
        assert poll_res.json()["notifications_sent"] == 0

        # Second poll: new records arrive across all models
        activities_data = [
            {"id": 102, "summary": "New Legacy Activity", "date_deadline": "2026-11-04", "res_name": "Project Beta"},
            {"id": 101, "summary": "Initial Activity", "date_deadline": "2026-11-03", "res_name": "Project Alpha"}
        ]
        tasks_data = [
            {"id": 202, "name": "New Legacy Task", "project_id": [1, "Alpha"], "stage_id": [1, "Todo"], "date_deadline": False, "description": ""},
            {"id": 201, "name": "Initial Task", "project_id": [1, "Alpha"], "stage_id": [1, "Todo"], "date_deadline": False, "description": ""}
        ]
        projects_data = [
            {"id": 302, "name": "New Legacy Project", "user_id": [42, "User 42"], "date_start": "2026-11-01", "date": "2026-12-01", "allocated_hours": 20.0, "description": ""},
            {"id": 301, "name": "Initial Project", "user_id": [42, "User 42"], "date_start": "2026-11-01", "date": "2026-12-01", "allocated_hours": 10.0, "description": ""}
        ]
        updates_data = [
            {"id": 402, "name": "New Project Update", "status": "on_track", "progress": 25, "project_id": [1, "Alpha"], "user_id": [42, "User 42"], "date": "2026-11-04", "description": ""},
            {"id": 401, "name": "Initial Update", "status": "on_track", "progress": 10, "project_id": [1, "Alpha"], "user_id": [42, "User 42"], "date": "2026-11-01", "description": ""}
        ]

        poll_res2 = client.post("/v1/legacy/poll")
        assert poll_res2.status_code == 200
        assert poll_res2.json()["notifications_sent"] == 4

        # Check UBports payload
        assert mock_ubports.called
        assert mock_ubports.call_count == 4

    # 4. Unregister
    unreg_res = client.post("/v1/legacy/unregister", json={
        "ubports_token": token,
        "odoo_url": "https://odoo15.example.com",
        "db": "production",
        "uid": 42
    })
    assert unreg_res.status_code == 200
    assert unreg_res.json()["status"] == "unregistered"

    list_after = client.get(f"/v1/legacy/subscriptions/{token}")
    assert len(list_after.json()["subscriptions"]) == 0


def test_token_validation():
    # Invalid characters
    res = client.get("/v1/subscription/bad token with spaces")
    assert res.status_code in (400, 404)

    res = client.get("/v1/subscription/bad$token")
    assert res.status_code == 400

    # Path traversal attempt
    res = client.get("/v1/subscription/../../etc/passwd")
    assert res.status_code in (400, 404)

    # Oversized token (> 256 chars)
    res = client.get(f"/v1/subscription/{'a' * 300}")
    assert res.status_code == 400


def test_security_headers_and_body_limits():
    # Security headers on responses
    res = client.get("/health")
    assert res.status_code == 200
    assert res.headers.get("x-content-type-options") == "nosniff"
    assert res.headers.get("x-frame-options") == "DENY"
    assert res.headers.get("referrer-policy") == "strict-origin-when-cross-origin"
    assert "default-src 'none'" in res.headers.get("content-security-policy", "")
    assert "max-age=31536000" in res.headers.get("strict-transport-security", "")

    # Reject oversized payload (> 64 KB)
    oversized_data = b"x" * (65 * 1024)
    res_large = client.post(
        "/v1/relay/valid_device_token_123",
        content=oversized_data,
        headers={"Content-Type": "application/octet-stream"}
    )
    assert res_large.status_code == 413


if __name__ == "__main__":
    test_health()
    test_subscription_creation()
    with patch("requests.post") as mock_p:
        mock_p.return_value = MagicMock(status_code=201, text="OK")
        test_relay_encrypted_webpush()
    test_legacy_lifecycle_and_polling()
    print("All push bridge tests (native + legacy) passed!")
