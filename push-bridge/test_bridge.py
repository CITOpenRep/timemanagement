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


if __name__ == "__main__":
    test_health()
    test_subscription_creation()
    with patch("requests.post") as mock_p:
        mock_p.return_value = MagicMock(status_code=201, text="OK")
        test_relay_encrypted_webpush()
    print("All push bridge tests passed!")
