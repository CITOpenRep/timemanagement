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
import re
from typing import Optional, Dict, Any
from pathlib import Path

from fastapi import FastAPI, Request, HTTPException, Response, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import requests
import xmlrpc.client
import asyncio
from datetime import datetime, timezone, timedelta

from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.hkdf import HKDF
from cryptography.hazmat.primitives.serialization import Encoding, PublicFormat

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("push-bridge")

app = FastAPI(title="ubtms-push-bridge", version="1.0.0")

DEFAULT_DB_PATH = str(Path(__file__).resolve().parent / "subscriptions.db")
DB_PATH = os.getenv("BRIDGE_DB_PATH", DEFAULT_DB_PATH)
UBPORTS_PUSH_URL = os.getenv("UBPORTS_PUSH_URL", "https://push.ubports.com/notify")
DEFAULT_APP_ID = os.getenv("UBPORTS_APP_ID", "ubtms_ubtms")
BRIDGE_PUBLIC_URL = os.getenv("BRIDGE_PUBLIC_URL", "")

MAX_BODY_SIZE = 64 * 1024
TOKEN_REGEX = re.compile(r"^[a-zA-Z0-9_\-\:\.+=]{1,256}$")

def validate_ubports_token(token: str) -> str:
    if not token or not TOKEN_REGEX.match(token):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid UBports token format"
        )
    return token


@app.middleware("http")
async def security_middleware(request: Request, call_next):
    content_length = request.headers.get("content-length")
    if content_length:
        try:
            if int(content_length) > MAX_BODY_SIZE:
                return JSONResponse(
                    status_code=status.HTTP_413_CONTENT_TOO_LARGE,
                    content={"detail": "Payload too large. Maximum allowed size is 64 KB."}
                )
        except ValueError:
            return JSONResponse(
                status_code=status.HTTP_400_BAD_REQUEST,
                content={"detail": "Invalid Content-Length header"}
            )

    if request.method in ("POST", "PUT", "PATCH"):
        total_size = 0
        chunks = []
        async for chunk in request.stream():
            total_size += len(chunk)
            if total_size > MAX_BODY_SIZE:
                return JSONResponse(
                    status_code=status.HTTP_413_CONTENT_TOO_LARGE,
                    content={"detail": "Payload too large. Maximum allowed size is 64 KB."}
                )
            chunks.append(chunk)
        request._body = b"".join(chunks)

    response = await call_next(request)

    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    response.headers["Content-Security-Policy"] = "default-src 'none'; frame-ancestors 'none'"
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"

    return response


_mem_conn = None

def clean_and_truncate_text(text: Any, max_len: int = 500) -> str:
    if not text or not isinstance(text, str):
        return ""
    cleaned = re.sub(r"<[^>]+>", " ", text)
    cleaned = " ".join(cleaned.split())
    if len(cleaned) > max_len:
        return cleaned[:max_len] + "..."
    return cleaned

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
                    last_task_id INTEGER DEFAULT 0,
                    last_project_id INTEGER DEFAULT 0,
                    last_project_update_id INTEGER DEFAULT 0,
                    is_active INTEGER DEFAULT 1,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    UNIQUE(ubports_token, odoo_url, db, uid)
                )
                """
            )
            _mem_conn.commit()
        return _mem_conn

    db_dir = os.path.dirname(DB_PATH)
    if db_dir and not os.path.exists(db_dir):
        try:
            os.makedirs(db_dir, exist_ok=True)
        except Exception:
            pass

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
            last_task_id INTEGER DEFAULT 0,
            last_project_id INTEGER DEFAULT 0,
            last_project_update_id INTEGER DEFAULT 0,
            is_active INTEGER DEFAULT 1,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(ubports_token, odoo_url, db, uid)
        )
        """
    )
    cursor = conn.cursor()
    cursor.execute("PRAGMA table_info(legacy_subscriptions)")
    existing_cols = {row[1] for row in cursor.fetchall()}
    if "last_task_id" not in existing_cols:
        conn.execute("ALTER TABLE legacy_subscriptions ADD COLUMN last_task_id INTEGER DEFAULT 0")
    if "last_project_id" not in existing_cols:
        conn.execute("ALTER TABLE legacy_subscriptions ADD COLUMN last_project_id INTEGER DEFAULT 0")
    if "last_project_update_id" not in existing_cols:
        conn.execute("ALTER TABLE legacy_subscriptions ADD COLUMN last_project_update_id INTEGER DEFAULT 0")
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
    validate_ubports_token(ubports_token)

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

    if BRIDGE_PUBLIC_URL:
        base_url = BRIDGE_PUBLIC_URL
    else:
        proto = request.headers.get("x-forwarded-proto") or request.url.scheme
        host = request.headers.get("x-forwarded-host") or request.headers.get("host") or request.url.netloc
        base_url = f"{proto}://{host}".rstrip("/")

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
    validate_ubports_token(ubports_token)

    body_bytes = await request.body()
    if len(body_bytes) > MAX_BODY_SIZE:
        raise HTTPException(
            status_code=status.HTTP_413_CONTENT_TOO_LARGE,
            detail="Payload too large. Maximum allowed size is 64 KB."
        )
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
    else:
        actions.append(f"appid://{pkg_name}/ubtms/current-user-version")

    record_data = {
        "model": res_model or ("mail.activity" if nav_type == "Activity" else "project.task"),
        "record_id": res_id,
        "name": notification_title,
        "summary": notification_title,
        "description": notification_body,
        "notes": notification_body
    }
    if isinstance(extra_data, dict):
        record_data.update(extra_data)

    # Format payload for UBports Push Server
    expire_on = (datetime.now(timezone.utc) + timedelta(hours=24)).strftime("%Y-%m-%dT%H:%M:%SZ")
    ubports_payload = {
        "appid": DEFAULT_APP_ID,
        "token": ubports_token,
        "expire_on": expire_on,
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
            },
            "record": record_data
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


_sent_cache: Dict[str, float] = {}

def is_recent_duplicate(token: str, model: str, record_id: int, ttl_seconds: int = 3600) -> bool:
    """Check and record dispatch key in TTL cache to prevent duplicate dispatches."""
    import time
    key = f"{token}:{model}:{record_id}"
    now = time.time()
    if len(_sent_cache) > 2000:
        expired = [k for k, ts in _sent_cache.items() if now - ts > ttl_seconds]
        for k in expired:
            _sent_cache.pop(k, None)

    last_sent = _sent_cache.get(key)
    if last_sent and (now - last_sent) < ttl_seconds:
        return True
    _sent_cache[key] = now
    return False


def send_ubports_notification(ubports_token: str, title: str, body: str, deep_link: Optional[str] = None, record: Optional[dict] = None) -> bool:
    """Helper to send a formatted card to UBports Push Server with avatar icon and deep link."""
    if record and record.get("record_id") and record.get("model"):
        if is_recent_duplicate(ubports_token, str(record["model"]), int(record["record_id"])):
            logger.info("Deduplication: skipped already-dispatched %s #%s to token %s...", record["model"], record["record_id"], ubports_token[:8])
            return True

    actions = []
    pkg_name = DEFAULT_APP_ID.split("_")[0]
    if deep_link:
        actions.append(deep_link)
    else:
        actions.append(f"appid://{pkg_name}/ubtms/current-user-version")

    data_payload = {
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
    if record:
        data_payload["record"] = record

    expire_on = (datetime.now(timezone.utc) + timedelta(hours=24)).strftime("%Y-%m-%dT%H:%M:%SZ")
    payload = {
        "appid": DEFAULT_APP_ID,
        "token": ubports_token,
        "expire_on": expire_on,
        "data": data_payload
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
    Polls an Odoo instance via XML-RPC for newly assigned activities, tasks, projects, and updates.
    Returns number of notifications sent.
    """
    odoo_url = sub_dict["odoo_url"].rstrip("/")
    db = sub_dict["db"]
    uid = sub_dict["uid"]
    password = sub_dict["password"]
    token = sub_dict["ubports_token"]
    last_act_id = sub_dict.get("last_activity_id") or 0
    last_task_id = sub_dict.get("last_task_id") or 0
    last_proj_id = sub_dict.get("last_project_id") or 0
    last_update_id = sub_dict.get("last_project_update_id") or 0

    sent_count = 0
    try:
        models = xmlrpc.client.ServerProxy(f"{odoo_url}/xmlrpc/2/object", allow_none=True)

        # Resolve partner_id for user (needed for follower checks)
        partner_id = None
        try:
            u_info = models.execute_kw(db, uid, password, "res.users", "read", [[uid]], {"fields": ["partner_id"]})
            if u_info and isinstance(u_info, list) and len(u_info) > 0:
                p_val = u_info[0].get("partner_id")
                if isinstance(p_val, (list, tuple)) and len(p_val) > 0:
                    partner_id = p_val[0]
        except Exception:
            pass

        # 1. Poll mail.activity for newly assigned activities or activities on user's tasks
        max_seen_act_id = last_act_id
        try:
            user_task_ids = []
            try:
                user_task_ids = models.execute_kw(
                    db, uid, password,
                    "project.task", "search",
                    [[("user_ids", "in", [uid])]],
                    {"order": "id desc", "limit": 100}
                ) or []
            except Exception:
                pass

            if user_task_ids:
                act_domain = ["|", ("user_id", "=", uid), "&", ("res_model", "=", "project.task"), ("res_id", "in", user_task_ids)]
            else:
                act_domain = [("user_id", "=", uid)]

            act_fields = [
                "id", "summary", "date_deadline", "res_name", "res_model", "res_id", "res_model_id", "note",
                "user_id", "create_uid", "activity_type_id"
            ]
            activities = models.execute_kw(
                db, uid, password,
                "mail.activity", "search_read",
                [act_domain],
                {"fields": act_fields, "order": "id desc", "limit": 10}
            )
            for act in activities:
                act_id = act.get("id", 0)
                if act_id > last_act_id:
                    if last_act_id != 0:
                        summary = act.get("summary") or "Odoo Activity"
                        res_name = act.get("res_name") or ""
                        body = f"Due: {act.get('date_deadline') or 'Today'} - {res_name}"
                        deep_link = f"ubtms://notification?type=Activity&id={act_id}&odoo_id=1"

                        user_tuple = act.get("user_id")
                        assignee_id = user_tuple[0] if isinstance(user_tuple, (list, tuple)) and len(user_tuple) > 0 else (user_tuple or uid)
                        assignee_name = user_tuple[1] if isinstance(user_tuple, (list, tuple)) and len(user_tuple) > 1 else ""

                        act_type_tuple = act.get("activity_type_id")
                        act_type_id = act_type_tuple[0] if isinstance(act_type_tuple, (list, tuple)) and len(act_type_tuple) > 0 else (act_type_tuple or 1)
                        act_type_name = act_type_tuple[1] if isinstance(act_type_tuple, (list, tuple)) and len(act_type_tuple) > 1 else ""

                        create_tuple = act.get("create_uid")
                        creator_id = create_tuple[0] if isinstance(create_tuple, (list, tuple)) and len(create_tuple) > 0 else (create_tuple or uid)

                        res_model = act.get("res_model") or ""
                        res_id = act.get("res_id") or 0

                        res_model_id_tuple = act.get("res_model_id")
                        res_model_id = res_model_id_tuple[0] if isinstance(res_model_id_tuple, (list, tuple)) and len(res_model_id_tuple) > 0 else (res_model_id_tuple or 0)

                        task_id = None
                        task_name = None
                        project_id = None
                        project_name = None
                        parent_id = None

                        if res_model == "project.task" and res_id:
                            task_id = res_id
                            task_name = res_name
                            try:
                                t_info = models.execute_kw(db, uid, password, "project.task", "read", [[res_id]], {"fields": ["name", "project_id", "parent_id"]})
                                if t_info and isinstance(t_info, list) and len(t_info) > 0:
                                    task_name = t_info[0].get("name") or res_name
                                    p_tuple = t_info[0].get("project_id")
                                    if isinstance(p_tuple, (list, tuple)) and len(p_tuple) > 0:
                                        project_id = p_tuple[0]
                                        if len(p_tuple) > 1:
                                            project_name = p_tuple[1]
                                    pr_tuple = t_info[0].get("parent_id")
                                    if isinstance(pr_tuple, (list, tuple)) and len(pr_tuple) > 0:
                                        parent_id = pr_tuple[0]
                            except Exception:
                                pass
                        elif res_model == "project.project" and res_id:
                            project_id = res_id
                            project_name = res_name
                            try:
                                p_info = models.execute_kw(db, uid, password, "project.project", "read", [[res_id]], {"fields": ["name", "parent_id"]})
                                if p_info and isinstance(p_info, list) and len(p_info) > 0:
                                    project_name = p_info[0].get("name") or res_name
                                    pr_tuple = p_info[0].get("parent_id")
                                    if isinstance(pr_tuple, (list, tuple)) and len(pr_tuple) > 0:
                                        parent_id = pr_tuple[0]
                            except Exception:
                                pass

                        record = {
                            "model": "mail.activity",
                            "record_id": act_id,
                            "summary": summary,
                            "due_date": act.get("date_deadline"),
                            "res_id": res_id,
                            "res_model": res_model,
                            "res_name": res_name,
                            "res_model_id": res_model_id,
                            "link_id": res_id,
                            "task_id": task_id,
                            "task_name": task_name,
                            "parent_id": parent_id,
                            "project_id": project_id,
                            "project_name": project_name,
                            "user_id": assignee_id,
                            "assignee_name": assignee_name,
                            "create_uid": creator_id,
                            "activity_type_id": act_type_id,
                            "activity_type_name": act_type_name,
                            "notes": clean_and_truncate_text(act.get("note") or body, 500)
                        }
                        if send_ubports_notification(token, summary, body, deep_link=deep_link, record=record):
                            sent_count += 1
                    if act_id > max_seen_act_id:
                        max_seen_act_id = act_id
        except Exception as e:
            logger.warning("Error polling activities for UID %d: %s", uid, e)

        # 2. Poll project.task for newly assigned tasks
        max_seen_task_id = last_task_id
        try:
            task_domain = [("user_ids", "in", [uid])]
            task_fields = ["id", "name", "project_id", "parent_id", "stage_id", "personal_stage_type_id", "date_deadline", "planned_date_start", "planned_date_end", "priority", "description"]
            try:
                tasks = models.execute_kw(
                    db, uid, password,
                    "project.task", "search_read",
                    [task_domain],
                    {"fields": task_fields + ["allocated_hours"], "order": "id desc", "limit": 10}
                )
            except Exception:
                try:
                    tasks = models.execute_kw(
                        db, uid, password,
                        "project.task", "search_read",
                        [task_domain],
                        {"fields": task_fields + ["planned_hours"], "order": "id desc", "limit": 10}
                    )
                except Exception:
                    tasks = models.execute_kw(
                        db, uid, password,
                        "project.task", "search_read",
                        [[("user_id", "=", uid)]],
                        {"fields": ["id", "name", "project_id", "stage_id", "date_deadline", "description"], "order": "id desc", "limit": 10}
                    )

            for task in tasks:
                task_id = task.get("id", 0)
                if task_id > last_task_id:
                    if last_task_id != 0:
                        task_name = task.get("name") or "New Task"
                        project_tuple = task.get("project_id")
                        proj_id = project_tuple[0] if isinstance(project_tuple, (list, tuple)) and len(project_tuple) > 0 else (project_tuple or -1)
                        proj_name = project_tuple[1] if isinstance(project_tuple, (list, tuple)) and len(project_tuple) > 1 else ""
                        stage_tuple = task.get("stage_id")
                        stage_id = stage_tuple[0] if isinstance(stage_tuple, (list, tuple)) and len(stage_tuple) > 0 else (stage_tuple or 1)
                        stage_name = stage_tuple[1] if isinstance(stage_tuple, (list, tuple)) and len(stage_tuple) > 1 else ""
                        hours = float(task.get("allocated_hours") or task.get("planned_hours") or 0.0)

                        summary = f"Assigned: {task_name}"
                        body = f"Project: {proj_name}" if proj_name else f"Task #{task_id}"
                        deep_link = f"ubtms://notification?type=Task&id={task_id}&odoo_id=1"
                        record = {
                            "model": "project.task",
                            "record_id": task_id,
                            "name": task_name,
                            "project_id": proj_id,
                            "project_name": proj_name,
                            "stage_id": stage_id,
                            "stage_name": stage_name,
                            "user_id": uid,
                            "deadline": task.get("date_deadline"),
                            "start_date": task.get("planned_date_start"),
                            "end_date": task.get("planned_date_end"),
                            "allocated_hours": hours,
                            "initial_planned_hours": hours,
                            "priority": str(task.get("priority", "0")),
                            "description": clean_and_truncate_text(task.get("description"), 500)
                        }
                        if send_ubports_notification(token, summary, body, deep_link=deep_link, record=record):
                            sent_count += 1
                    if task_id > max_seen_task_id:
                        max_seen_task_id = task_id
        except Exception as e:
            logger.warning("Error polling tasks for UID %d: %s", uid, e)

        # 3. Poll project.update for new project updates
        max_seen_update_id = last_update_id
        try:
            update_domain = ["|", ("message_partner_ids", "in", [partner_id]), ("project_id.user_id", "=", uid)] if partner_id else [("user_id", "!=", uid)]
            updates = models.execute_kw(
                db, uid, password,
                "project.update", "search_read",
                [update_domain],
                {"fields": ["id", "name", "status", "progress", "project_id", "user_id", "date", "description"], "order": "id desc", "limit": 10}
            )
            for up in updates:
                update_id = up.get("id", 0)
                if update_id > last_update_id:
                    if last_update_id != 0:
                        update_name = up.get("name") or "Project Update"
                        project_tuple = up.get("project_id")
                        proj_id = project_tuple[0] if isinstance(project_tuple, (list, tuple)) and len(project_tuple) > 0 else (project_tuple or -1)
                        proj_name = project_tuple[1] if isinstance(project_tuple, (list, tuple)) and len(project_tuple) > 1 else ""
                        status_val = up.get("status") or "on_track"

                        summary = f"Update: {proj_name}" if proj_name else f"Update: {update_name}"
                        body = f"{update_name} ({status_val})"
                        deep_link = f"ubtms://notification?type=ProjectUpdate&id={update_id}&account_id=0&odoo_id=1"
                        record = {
                            "model": "project.update",
                            "record_id": update_id,
                            "name": update_name,
                            "project_id": proj_id,
                            "project_name": proj_name,
                            "project_status": status_val,
                            "progress": up.get("progress") or 0,
                            "user_id": uid,
                            "date": up.get("date"),
                            "description": clean_and_truncate_text(up.get("description"), 500)
                        }
                        if send_ubports_notification(token, summary, body, deep_link=deep_link, record=record):
                            sent_count += 1
                    if update_id > max_seen_update_id:
                        max_seen_update_id = update_id
        except Exception as e:
            logger.warning("Error polling project updates for UID %d: %s", uid, e)

        # 4. Poll project.project for new projects
        max_seen_proj_id = last_proj_id
        try:
            proj_domain = ["|", ("user_id", "=", uid), ("message_partner_ids", "in", [partner_id])] if partner_id else [("user_id", "=", uid)]
            projects = models.execute_kw(
                db, uid, password,
                "project.project", "search_read",
                [proj_domain],
                {"fields": ["id", "name", "user_id", "date_start", "date", "allocated_hours", "description"], "order": "id desc", "limit": 10}
            )
            for p in projects:
                proj_id = p.get("id", 0)
                if proj_id > last_proj_id:
                    if last_proj_id != 0:
                        proj_name = p.get("name") or "New Project"
                        summary = f"Project: {proj_name}"
                        body = "New project available"
                        deep_link = f"ubtms://notification?type=Project&id={proj_id}&odoo_id=1"
                        record = {
                            "model": "project.project",
                            "record_id": proj_id,
                            "name": proj_name,
                            "user_id": uid,
                            "start_date": p.get("date_start"),
                            "end_date": p.get("date"),
                            "allocated_hours": float(p.get("allocated_hours") or 0.0),
                            "description": clean_and_truncate_text(p.get("description"), 500)
                        }
                        if send_ubports_notification(token, summary, body, deep_link=deep_link, record=record):
                            sent_count += 1
                    if proj_id > max_seen_proj_id:
                        max_seen_proj_id = proj_id
        except Exception as e:
            logger.warning("Error polling projects for UID %d: %s", uid, e)

        conn = get_db()
        cursor = conn.cursor()
        cursor.execute(
            """
            UPDATE legacy_subscriptions
            SET last_polled_at = CURRENT_TIMESTAMP,
                last_activity_id = ?,
                last_task_id = ?,
                last_project_id = ?,
                last_project_update_id = ?
            WHERE id = ?
            """,
            (max_seen_act_id, max_seen_task_id, max_seen_proj_id, max_seen_update_id, sub_id)
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
    validate_ubports_token(req.ubports_token)
    if not (req.odoo_url.startswith("http://") or req.odoo_url.startswith("https://")):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid Odoo URL: must start with http:// or https://"
        )

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
    validate_ubports_token(req.ubports_token)

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
    validate_ubports_token(ubports_token)

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
        SELECT id, ubports_token, odoo_url, db, username, password, uid, last_activity_id, last_task_id, last_project_id, last_project_update_id
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
            "last_activity_id": r[7],
            "last_task_id": r[8] if len(r) > 8 else 0,
            "last_project_id": r[9] if len(r) > 9 else 0,
            "last_project_update_id": r[10] if len(r) > 10 else 0
        }
        total_notifications += poll_single_legacy_subscription(r[0], sub_dict)

    return {
        "status": "success",
        "accounts_polled": total_polled,
        "notifications_sent": total_notifications
    }


def background_poll_worker():
    """Periodically polls legacy Odoo accounts for new activities."""
    import time
    while True:
        try:
            time.sleep(15)
            trigger_legacy_poll()
        except Exception as e:
            logger.error("Background poll error: %s", e)


@app.on_event("startup")
def start_poll_worker():
    import threading
    t = threading.Thread(target=background_poll_worker, daemon=True)
    t.start()
    logger.info("Started background legacy polling worker (interval=15s)")

