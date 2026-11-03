# -*- coding: utf-8 -*-
"""
Lightweight Push Bridge for Ubuntu Touch (ubtms)
Translates Odoo RFC 8188 WebPush notifications to UBports Push Server.
"""

import os
import json
import base64
import struct
import sqlite3
import logging
from typing import Optional, Dict, Any
from pathlib import Path

from fastapi import FastAPI, Request, HTTPException, Response, status
from fastapi.responses import JSONResponse
import requests

from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.hkdf import HKDF
from cryptography.hazmat.primitives.serialization import Encoding, PublicFormat

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("push-bridge")

app = FastAPI(title="ubtms-push-bridge", version="1.0.0")

DB_PATH = os.getenv("BRIDGE_DB_PATH", "subscriptions.db")
UBPORTS_PUSH_URL = os.getenv("UBPORTS_PUSH_URL", "https://push.ubports.com/notify")
DEFAULT_APP_ID = os.getenv("UBPORTS_APP_ID", "ubtms_ubtms")
BRIDGE_PUBLIC_URL = os.getenv("BRIDGE_PUBLIC_URL", "")


_mem_conn = None

def get_db():
    global _mem_conn
    if DB_PATH == ":memory:":
        if _mem_conn is None:
            _mem_conn = sqlite3.connect(":memory:", check_same_thread=False)
            _mem_conn.execute(
                """
                CREATE TABLE IF NOT EXISTS subscriptions (
                    ubports_token TEXT PRIMARY KEY,
                    p256dh TEXT NOT NULL,
                    auth TEXT NOT NULL,
                    private_key_pem TEXT NOT NULL,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
                """
            )
            _mem_conn.commit()
        return _mem_conn

    conn = sqlite3.connect(DB_PATH)
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS subscriptions (
            ubports_token TEXT PRIMARY KEY,
            p256dh TEXT NOT NULL,
            auth TEXT NOT NULL,
            private_key_pem TEXT NOT NULL,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
        """
    )
    conn.commit()
    return conn


def b64_url_encode(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode("ascii").rstrip("=")


def b64_url_decode(data: str) -> bytes:
    padding = "=" * ((4 - len(data) % 4) % 4)
    return base64.urlsafe_b64decode(data + padding)


def generate_subscription_keys():
    private_key = ec.generate_private_key(ec.SECP256R1(), default_backend())
    public_key = private_key.public_key()
    
    pub_bytes = public_key.public_bytes(Encoding.X962, PublicFormat.UncompressedPoint)
    auth_bytes = os.urandom(16)
    
    priv_pem = private_key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption()
    ).decode("ascii")

    return {
        "p256dh": b64_url_encode(pub_bytes),
        "auth": b64_url_encode(auth_bytes),
        "private_key_pem": priv_pem
    }


def decrypt_rfc8188_payload(encrypted_body: bytes, sub_keys: Dict[str, str]) -> bytes:
    """Decrypts RFC 8188 aes128gcm WebPush payload sent by Odoo."""
    if len(encrypted_body) < 21:
        raise ValueError("Encrypted payload too short")

    salt, record_size, key_len = struct.unpack("!16sLB", encrypted_body[:21])
    sender_pub_bytes = encrypted_body[21:21 + key_len]
    ciphertext = encrypted_body[21 + key_len:]

    receiver_priv_key = serialization.load_pem_private_key(
        sub_keys["private_key_pem"].encode("ascii"),
        password=None,
        backend=default_backend()
    )
    receiver_pub_bytes = b64_url_decode(sub_keys["p256dh"])
    auth_secret = b64_url_decode(sub_keys["auth"])

    sender_pub_key = ec.EllipticCurvePublicKey.from_encoded_point(ec.SECP256R1(), sender_pub_bytes)
    shared_secret = receiver_priv_key.exchange(ec.ECDH(), sender_pub_key)

    context = b"WebPush: info\x00" + receiver_pub_bytes + sender_pub_bytes
    key_info = b"Content-Encoding: aes128gcm\x00"
    nonce_info = b"Content-Encoding: nonce\x00"

    hkdf_auth = HKDF(
        algorithm=hashes.SHA256(),
        length=32,
        salt=auth_secret,
        info=context,
        backend=default_backend()
    )
    secret = hkdf_auth.derive(shared_secret)

    hkdf_key = HKDF(
        algorithm=hashes.SHA256(),
        length=16,
        salt=salt,
        info=key_info,
        backend=default_backend()
    )
    hkdf_nonce = HKDF(
        algorithm=hashes.SHA256(),
        length=12,
        salt=salt,
        info=nonce_info,
        backend=default_backend()
    )

    key = hkdf_key.derive(secret)
    nonce = hkdf_nonce.derive(secret)

    aesgcm = AESGCM(key)
    decrypted_raw = aesgcm.decrypt(nonce, ciphertext, None)
    return decrypted_raw.rstrip(b"\x02\x01")


@app.get("/health")
def health_check():
    return {"status": "ok", "service": "ubtms-push-bridge"}


@app.get("/v1/subscription/{ubports_token}")
def get_or_create_subscription(ubports_token: str, request: Request):
    """
    Returns the VAPID WebPush subscription endpoint and keys for the given UBports device token.
    Called by the Ubuntu Touch app during Odoo login.
    """
    if not ubports_token:
        raise HTTPException(status_code=400, detail="Missing UBports token")

    conn = get_db()
    cursor = conn.cursor()
    cursor.execute(
        "SELECT p256dh, auth, private_key_pem FROM subscriptions WHERE ubports_token = ?",
        (ubports_token,)
    )
    row = cursor.fetchone()

    if row:
        p256dh, auth, _ = row
    else:
        new_keys = generate_subscription_keys()
        cursor.execute(
            """
            INSERT OR REPLACE INTO subscriptions (ubports_token, p256dh, auth, private_key_pem)
            VALUES (?, ?, ?, ?)
            """,
            (ubports_token, new_keys["p256dh"], new_keys["auth"], new_keys["private_key_pem"])
        )
        conn.commit()
        p256dh = new_keys["p256dh"]
        auth = new_keys["auth"]
    if conn is not _mem_conn:
        conn.close()

    base_url = BRIDGE_PUBLIC_URL or str(request.base_url).rstrip("/")
    relay_endpoint = f"{base_url}/v1/relay/{ubports_token}"

    return {
        "endpoint": relay_endpoint,
        "keys": {
            "p256dh": p256dh,
            "auth": auth
        }
    }


@app.post("/v1/relay/{ubports_token}")
async def relay_odoo_notification(ubports_token: str, request: Request):
    """
    Receives WebPush notifications from Odoo and forwards them to UBports Push Server.
    """
    if not ubports_token:
        raise HTTPException(status_code=400, detail="Missing UBports token")

    body_bytes = await request.body()
    content_encoding = request.headers.get("content-encoding", "").lower()

    notification_title = "Odoo Notification"
    notification_body = ""

    if content_encoding == "aes128gcm":
        conn = get_db()
        cursor = conn.cursor()
        cursor.execute(
            "SELECT p256dh, auth, private_key_pem FROM subscriptions WHERE ubports_token = ?",
            (ubports_token,)
        )
        row = cursor.fetchone()
        if conn is not _mem_conn:
            conn.close()

        if not row:
            logger.warning("Subscription not found for token %s", ubports_token[:10])
            raise HTTPException(status_code=404, detail="Device subscription not found")

        sub_keys = {
            "p256dh": row[0],
            "auth": row[1],
            "private_key_pem": row[2]
        }

        try:
            decrypted = decrypt_rfc8188_payload(body_bytes, sub_keys)
            data = json.loads(decrypted.decode("utf-8"))
            notification_title = data.get("title") or notification_title
            options = data.get("options", {})
            notification_body = options.get("body") or data.get("body") or ""
        except Exception as e:
            logger.error("Failed to decrypt WebPush payload: %s", e)
            raise HTTPException(status_code=400, detail=f"Decryption error: {str(e)}")
    else:
        # Fallback for plain JSON payloads
        try:
            data = json.loads(body_bytes.decode("utf-8"))
            notification_title = data.get("title") or data.get("summary") or notification_title
            options = data.get("options", {})
            notification_body = options.get("body") or data.get("body") or ""
        except Exception:
            notification_body = body_bytes.decode("utf-8", errors="ignore")

    # Format payload for UBports Push Server
    ubports_payload = {
        "appid": DEFAULT_APP_ID,
        "token": ubports_token,
        "data": {
            "notification": {
                "card": {
                    "summary": notification_title,
                    "body": notification_body,
                    "popup": True,
                    "persist": True
                }
            }
        }
    }

    try:
        resp = requests.post(
            UBPORTS_PUSH_URL,
            json=ubports_payload,
            headers={"Content-Type": "application/json"},
            timeout=10
        )
        logger.info(
            "Forwarded to UBports for token %s... Status: %d",
            ubports_token[:8],
            resp.status_code
        )

        if resp.status_code in (404, 410):
            # Target device token is unregistered on UBports; tell Odoo so it cleans up device table
            return JSONResponse(
                status_code=410,
                content={"error": "Device unregistered on UBports"}
            )
        elif resp.status_code >= 400:
            return JSONResponse(
                status_code=502,
                content={"error": f"UBports Push Server error: {resp.text}"}
            )

        return Response(status_code=status.HTTP_201_CREATED)
    except requests.RequestException as e:
        logger.error("Failed to reach UBports push server: %s", e)
        return JSONResponse(
            status_code=503,
            content={"error": "Failed to reach UBports server"}
        )
