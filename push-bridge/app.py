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
from pydantic import BaseModel
import requests
import xmlrpc.client
import asyncio
from datetime import datetime

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
            _mem_conn.execute(
                """
                CREATE TABLE IF NOT EXISTS legacy_subscriptions (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    ubports_token TEXT NOT NULL,
                    odoo_url TEXT NOT NULL,
                    db TEXT NOT NULL,
                    username TEXT NOT NULL,
                    password TEXT NOT NULL,
                    uid INTEGER NOT NULL,
                    poll_interval INTEGER DEFAULT 300,
                    last_polled_at TEXT,
                    last_activity_id INTEGER DEFAULT 0,
                    is_active INTEGER DEFAULT 1,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    UNIQUE(ubports_token, odoo_url, db, uid)
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
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS legacy_subscriptions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ubports_token TEXT NOT NULL,
            odoo_url TEXT NOT NULL,
            db TEXT NOT NULL,
            username TEXT NOT NULL,
            password TEXT NOT NULL,
            uid INTEGER NOT NULL,
            poll_interval INTEGER DEFAULT 300,
            last_polled_at TEXT,
            last_activity_id INTEGER DEFAULT 0,
            is_active INTEGER DEFAULT 1,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(ubports_token, odoo_url, db, uid)
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
            payload = json.loads(decrypted.decode("utf-8"))
        except Exception as e:
            logger.error("Failed to decrypt WebPush payload: %s", e)
            raise HTTPException(status_code=400, detail=f"Decryption error: {str(e)}")
    else:
        # Fallback for plain JSON payloads
        try:
            payload = json.loads(body_bytes.decode("utf-8"))
        except Exception:
            payload = {"body": body_bytes.decode("utf-8", errors="ignore")}

    # Extract title, body, and possible record data for deep linking
    notification_title = payload.get("title") or payload.get("summary") or "Odoo Notification"
    options = payload.get("options", {}) if isinstance(payload.get("options"), dict) else {}
    notification_body = options.get("body") or payload.get("body") or ""
    extra_data = options.get("data", {}) if isinstance(options.get("data"), dict) else {}
    if not extra_data and isinstance(payload.get("data"), dict):
        extra_data = payload.get("data")

    res_model = str(extra_data.get("model") or "")
    res_id = extra_data.get("res_id") or extra_data.get("id")

    nav_type = "Task"
    if "activity" in res_model.lower() or "Activity" in notification_title:
        nav_type = "Activity"
    elif "project" in res_model.lower() or "Project" in notification_title:
        nav_type = "Project"
    elif "timesheet" in res_model.lower() or "Timesheet" in notification_title:
        nav_type = "Timesheet"

    actions = []
    pkg_name = DEFAULT_APP_ID.split("_")[0]
    if res_id:
        actions.append(f"ubtms://notification?type={nav_type}&id={res_id}&odoo_id=1")
    actions.append(f"appid://{pkg_name}/ubtms/current-user-version")

    # Format payload for UBports Push Server
    ubports_payload = {
        "appid": DEFAULT_APP_ID,
        "token": ubports_token,
        "data": {
            "notification": {
                "card": {
                    "summary": notification_title,
                    "body": notification_body,
                    "icon": "assets/logo.png",
                    "popup": True,
                    "persist": True,
                    "actions": actions
                },
                "sound": "sounds/lomiri/notifications/Positive.ogg",
                "vibrate": {
                    "pattern": [200, 100, 200],
                    "repeat": 1
                },
                "emblem-counter": {
                    "count": 1,
                    "visible": True
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


class LegacyRegisterRequest(BaseModel):
    ubports_token: str
    odoo_url: str
    db: str
    username: str
    password: str
    uid: int
    poll_interval: Optional[int] = 300


class LegacyUnregisterRequest(BaseModel):
    ubports_token: str
    odoo_url: str
    db: str
    uid: int


def send_ubports_notification(ubports_token: str, title: str, body: str, deep_link: Optional[str] = None) -> bool:
    """Helper to send a formatted card to UBports Push Server with avatar icon and deep link."""
    actions = []
    pkg_name = DEFAULT_APP_ID.split("_")[0]
    if deep_link:
        actions.append(deep_link)
    actions.append(f"appid://{pkg_name}/ubtms/current-user-version")

    payload = {
        "appid": DEFAULT_APP_ID,
        "token": ubports_token,
        "data": {
            "notification": {
                "card": {
                    "summary": title,
                    "body": body,
                    "icon": "assets/logo.png",
                    "popup": True,
                    "persist": True,
                    "actions": actions
                },
                "sound": "sounds/lomiri/notifications/Positive.ogg",
                "vibrate": {
                    "pattern": [200, 100, 200],
                    "repeat": 1
                },
                "emblem-counter": {
                    "count": 1,
                    "visible": True
                }
            }
        }
    }
    try:
        resp = requests.post(
            UBPORTS_PUSH_URL,
            json=payload,
            headers={"Content-Type": "application/json"},
            timeout=10
        )
        return resp.status_code in (200, 201)
    except Exception as e:
        logger.error("Failed sending UBports notification: %s", e)
        return False


def poll_single_legacy_subscription(sub_id: int, sub_dict: Dict[str, Any]) -> int:
    """
    Polls an Odoo 14-16 instance via XML-RPC for newly assigned activities.
    Returns number of notifications sent.
    """
    odoo_url = sub_dict["odoo_url"].rstrip("/")
    db = sub_dict["db"]
    uid = sub_dict["uid"]
    password = sub_dict["password"]
    token = sub_dict["ubports_token"]
    last_act_id = sub_dict.get("last_activity_id") or 0

    sent_count = 0
    try:
        models = xmlrpc.client.ServerProxy(f"{odoo_url}/xmlrpc/2/object", allow_none=True)
        domain = [("user_id", "=", uid)]
        activities = models.execute_kw(
            db, uid, password,
            "mail.activity", "search_read",
            [domain],
            {"fields": ["id", "summary", "date_deadline", "res_name", "res_model", "res_id"], "order": "id desc", "limit": 10}
        )

        max_seen_id = last_act_id
        for act in activities:
            act_id = act.get("id", 0)
            if act_id > last_act_id:
                if last_act_id != 0:
                    summary = act.get("summary") or "Odoo Activity"
                    body = f"Due: {act.get('date_deadline') or 'Today'} - {act.get('res_name') or ''}"
                    deep_link = f"ubtms://notification?type=Activity&id={act_id}&odoo_id=1"
                    if send_ubports_notification(token, summary, body, deep_link=deep_link):
                        sent_count += 1
                if act_id > max_seen_id:
                    max_seen_id = act_id

        conn = get_db()
        cursor = conn.cursor()
        cursor.execute(
            """
            UPDATE legacy_subscriptions
            SET last_polled_at = CURRENT_TIMESTAMP,
                last_activity_id = ?
            WHERE id = ?
            """,
            (max_seen_id, sub_id)
        )
        conn.commit()
        if conn is not _mem_conn:
            conn.close()

    except Exception as e:
        logger.warning("Error polling Odoo instance %s for UID %d: %s", odoo_url, uid, e)

    return sent_count


@app.post("/v1/legacy/register")
def register_legacy_odoo(req: LegacyRegisterRequest):
    """
    Registers an Odoo 14-16 account for bridge-side polling.
    """
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute(
        """
        INSERT INTO legacy_subscriptions (
            ubports_token, odoo_url, db, username, password, uid, poll_interval, is_active
        ) VALUES (?, ?, ?, ?, ?, ?, ?, 1)
        ON CONFLICT(ubports_token, odoo_url, db, uid) DO UPDATE SET
            password = excluded.password,
            poll_interval = excluded.poll_interval,
            is_active = 1,
            updated_at = CURRENT_TIMESTAMP
        """,
        (
            req.ubports_token, req.odoo_url, req.db,
            req.username, req.password, req.uid, req.poll_interval
        )
    )
    conn.commit()
    if conn is not _mem_conn:
        conn.close()

    logger.info("Registered legacy polling for UID %d at %s", req.uid, req.odoo_url)
    return {"status": "registered", "mode": "legacy_bridge", "poll_interval": req.poll_interval}


@app.post("/v1/legacy/unregister")
def unregister_legacy_odoo(req: LegacyUnregisterRequest):
    """
    Unregisters or deactivates legacy polling for an account.
    """
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute(
        """
        DELETE FROM legacy_subscriptions
        WHERE ubports_token = ? AND odoo_url = ? AND db = ? AND uid = ?
        """,
        (req.ubports_token, req.odoo_url, req.db, req.uid)
    )
    conn.commit()
    if conn is not _mem_conn:
        conn.close()

    return {"status": "unregistered"}


@app.get("/v1/legacy/subscriptions/{ubports_token}")
def list_legacy_subscriptions(ubports_token: str):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute(
        """
        SELECT id, odoo_url, db, username, uid, poll_interval, last_polled_at, is_active
        FROM legacy_subscriptions
        WHERE ubports_token = ?
        """,
        (ubports_token,)
    )
    rows = cursor.fetchall()
    if conn is not _mem_conn:
        conn.close()

    result = []
    for r in rows:
        result.append({
            "id": r[0],
            "odoo_url": r[1],
            "db": r[2],
            "username": r[3],
            "uid": r[4],
            "poll_interval": r[5],
            "last_polled_at": r[6],
            "is_active": bool(r[7])
        })
    return {"subscriptions": result}


@app.post("/v1/legacy/poll")
def trigger_legacy_poll():
    """
    Triggers an immediate poll across all active legacy subscriptions.
    """
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute(
        """
        SELECT id, ubports_token, odoo_url, db, username, password, uid, last_activity_id
        FROM legacy_subscriptions
        WHERE is_active = 1
        """
    )
    rows = cursor.fetchall()
    if conn is not _mem_conn:
        conn.close()

    total_polled = len(rows)
    total_notifications = 0

    for r in rows:
        sub_dict = {
            "ubports_token": r[1],
            "odoo_url": r[2],
            "db": r[3],
            "username": r[4],
            "password": r[5],
            "uid": r[6],
            "last_activity_id": r[7]
        }
        total_notifications += poll_single_legacy_subscription(r[0], sub_dict)

    return {
        "status": "success",
        "accounts_polled": total_polled,
        "notifications_sent": total_notifications
    }
