# -*- coding: utf-8 -*-
# MIT License
#
# Copyright (c) 2025 CIT-Services
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import xmlrpc.client
import logging
import base64
import socket
import json
import os
import urllib.request
from urllib.parse import urlparse, urljoin
from bus import send

# Default timeout for XML-RPC calls (60 seconds)
DEFAULT_TIMEOUT = 60


class HttpTimeoutTransport(xmlrpc.client.Transport):
    """Custom transport with timeout support for plain HTTP XML-RPC calls."""

    def __init__(self, timeout=DEFAULT_TIMEOUT, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.timeout = timeout

    def make_connection(self, host):
        conn = super().make_connection(host)
        conn.timeout = self.timeout
        return conn


class TimeoutTransport(xmlrpc.client.SafeTransport):
    """Custom transport with timeout support for HTTPS XML-RPC calls."""
    
    def __init__(self, timeout=DEFAULT_TIMEOUT, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.timeout = timeout
    
    def make_connection(self, host):
        conn = super().make_connection(host)
        conn.timeout = self.timeout
        return conn


class OdooClient:
    """
    A client to interact with the Odoo XML-RPC API.
    """

    def __init__(self, url, db, username, password):
        """
        Initialize the Odoo client.

        Args:
            url (str): The base URL of the Odoo instance (e.g. https://my.odoo.com).
            db (str): The Odoo database name.
            username (str): The username (usually email).
            password (str): The user’s password or API key.
        """
        self.url = self._normalize_url(url)
        self.db = db
        self.username = username
        self.password = password
        self.uid = self._login()
        self.models = self._get_model_proxy()

    def _normalize_url(self, url):
        """Normalize server URL to a safe XML-RPC base URL."""
        normalized = (url or "").strip().rstrip("/")
        if not normalized:
            return normalized

        # If there is no scheme separator, treat this as a bare host (optionally with port)
        # and prepend HTTPS so that XML-RPC calls get a proper absolute URL.
        if "://" not in normalized:
            return f"https://{normalized}"

        parsed = urlparse(normalized)
        if not parsed.scheme:
            # Most Odoo deployments require HTTPS and XML-RPC does not follow redirects.
            normalized = f"https://{normalized}"

        return normalized

    def search(self, model, domain):
            return self.models.execute_kw(
                self.db, self.uid, self.password,
                model, 'search', [domain]
            )

    def read(self, model, ids, fields=None):
        return self.models.execute_kw(
            self.db, self.uid, self.password,
            model, 'read', [ids], {"fields": fields or []}
        )

    def _login(self):
        """
        Authenticate and return the user ID.

        Returns:
            int: UID if authentication is successful, otherwise raises an exception.
        """
        try:
            transport = self._create_transport()
            common = xmlrpc.client.ServerProxy(
                f"{self.url}/xmlrpc/2/common",
                transport=transport
            )
            uid = common.authenticate(self.db, self.username, self.password, {})
            if not uid:
                send("sync_message",f"Authentication failed for server")
                raise ValueError(
                    f"Authentication failed for user '{self.username}' on database '{self.db}'"
                )
            return uid
        except xmlrpc.client.ProtocolError as e:
            # Handle HTTP redirects by retrying on resolved HTTPS or Location target.
            redirect_target = None
            if e.errcode in (301, 302, 307, 308):
                if self.url.startswith("http://"):
                    redirect_target = self.url.replace("http://", "https://", 1)

                location_header = None
                try:
                    if hasattr(e, "headers") and e.headers is not None:
                        location_header = e.headers.get("Location")
                except Exception:
                    location_header = None

                if location_header:
                    parsed = urlparse(location_header)
                    try:
                        # If Location is absolute, preserve its full path; otherwise resolve relative to current base URL.
                        if parsed.scheme and parsed.netloc:
                            redirect_target = parsed.geturl()
                        else:
                            redirect_target = urljoin(self.url.rstrip("/") + "/", location_header)
                    except Exception:
                        # Fallback: ignore malformed Location and keep any previously computed redirect_target
                        pass

            if redirect_target:
                self.url = redirect_target.rstrip("/")
                try:
                    transport = self._create_transport()
                    common = xmlrpc.client.ServerProxy(
                        f"{self.url}/xmlrpc/2/common",
                        transport=transport
                    )
                    uid = common.authenticate(self.db, self.username, self.password, {})
                    if uid:
                        return uid
                except Exception:
                    pass

            send("sync_error", "Login to server failed")
            raise ConnectionError(f"Login failed: {e}")
        except socket.timeout:
            send("sync_error", "Connection timed out - server not responding")
            raise ConnectionError("Login timed out - check network connection")
        except Exception as e:
            send("sync_error",f"Login to server failed")
            raise ConnectionError(f"Login failed: {e}")

    def _create_transport(self):
        """
        Select an appropriate XML-RPC transport with timeout based on the URL scheme.

        Uses a plain HTTP transport for 'http://' URLs and a SafeTransport-based
        transport for 'https://' URLs (or when no scheme is specified).
        """
        parsed = urlparse(self.url or "")
        scheme = (parsed.scheme or "").lower()
        if scheme == "http":
            return HttpTimeoutTransport(timeout=DEFAULT_TIMEOUT)
        # Default to HTTPS-safe transport.
        return TimeoutTransport(timeout=DEFAULT_TIMEOUT)

    def _get_model_proxy(self):
        """
        Get a model proxy to call object methods.

        Returns:
            ServerProxy: A proxy for calling model methods.
        """
        try:
            transport = TimeoutTransport(timeout=DEFAULT_TIMEOUT)
            return xmlrpc.client.ServerProxy(
                f"{self.url}/xmlrpc/2/object",
                transport=transport,
                allow_none=True
            )
        except Exception as e:
            raise ConnectionError(f"Failed to create model proxy: {e}")

    def ondemanddownload(self, record_id, username, password, decode=True):
           """
           Download a single ir.attachment on demand using the provided credentials.

           Args:
               record_id (int): ir.attachment ID to download.
               username (str): Odoo login (email).
               password (str): Odoo password (or API key).
               decode (bool): If True, return raw bytes; otherwise return base64 string.

           Returns:
               dict: {
                   'id': int,
                   'name': str|None,
                   'mimetype': str|None,
                   'type': 'binary'|'url'|None,
                   'url': str|None,          # for type == 'url'
                   'data': bytes|str|None    # bytes if decode=True & binary; base64 if decode=False
               }

           Raises:
               ValueError: if the record is missing or has no data.
               RuntimeError: on XML-RPC errors.
           """
           # Authenticate with the provided username/password (fresh uid for this call)
           try:
               common = xmlrpc.client.ServerProxy(f"{self.url}/xmlrpc/2/common")
               uid = common.authenticate(self.db, username, password, {})
               if not uid:
                   raise ValueError(
                       f"Authentication failed for user '{username}' on database '{self.db}'"
                   )
           except Exception as e:
               raise RuntimeError(f"On-demand login failed: {e}")

           # Read the attachment with full base64 (bin_size=False)
           fields = ['name', 'mimetype', 'type', 'datas', 'url']
           try:
               recs = self.models.execute_kw(
                   self.db, uid, password,
                   'ir.attachment', 'read',
                   [[record_id]],
                   {'fields': fields, 'context': {'bin_size': False}}
               )
           except Exception as e:
               raise RuntimeError(f"Failed to read ir.attachment({record_id}): {e}")

           if not recs:
               raise ValueError(f"Attachment {record_id} not found")

           att = recs[0]
           att_type = att.get('type')
           result = {
               'id': record_id,
               'name': att.get('name'),
               'mimetype': att.get('mimetype'),
               'type': att_type,
               'url': att.get('url') if att_type == 'url' else None,
               'data': None
           }

           if att_type == 'binary':
               datas_b64 = att.get('datas')
               if not datas_b64:
                   raise ValueError(f"Attachment {record_id} has no binary data")
               result['data'] = base64.b64decode(datas_b64) if decode else datas_b64
               return result

           if att_type == 'url':
               if not result['url']:
                   raise ValueError(f"Attachment {record_id} is a URL type but has no URL")
               return result

           raise ValueError(f"Attachment {record_id} has unsupported type: {att_type}")

    def call(self, model, method, args=None, kwargs=None):
        """
        Call a method on a given model.

        Args:
            model (str): The Odoo model name (e.g. 'res.partner').
            method (str): The method name to call (e.g. 'search_read').
            args (list): Positional arguments for the method.
            kwargs (dict): Keyword arguments for the method.

        Returns:
            Any: The result of the method call.
        """
        args = args or []
        kwargs = kwargs or {}
        try:
            return self.models.execute_kw(
                self.db, self.uid, self.password, model, method, args, kwargs
            )
        except Exception as e:
            raise RuntimeError(f"Failed calling '{method}' on '{model}': {e}")

    def get_server_version(self):
        """
        Query Odoo server version using common.version().
        """
        try:
            transport = self._create_transport()
            common = xmlrpc.client.ServerProxy(
                f"{self.url}/xmlrpc/2/common",
                transport=transport
            )
            return common.version()
        except Exception as e:
            logging.debug(f"[VERSION] Could not retrieve server version: {e}")
            return {}

    def get_server_major_version(self):
        """
        Extract integer major version of Odoo server (e.g. 14, 15, 16, 17, 18).
        """
        version_data = self.get_server_version()
        version_info = version_data.get("server_version_info")
        if version_info and len(version_info) > 0 and isinstance(version_info[0], int):
            return version_info[0]

        version_str = str(version_data.get("server_version", ""))
        if version_str:
            import re
            match = re.match(r"^(\d+)", version_str)
            if match:
                return int(match.group(1))

        return 0

    def register_push_device(self, ubports_token, bridge_url=None):
        """
        Register this device with Odoo for push notifications.
        - For Odoo 17+: uses native WebPush via mail.partner.device.
        - For Odoo 14-16: registers with the Push Bridge legacy poller.
        """
        if not ubports_token:
            return False

        if not bridge_url:
            bridge_url = os.getenv(
                "UBTMS_PUSH_BRIDGE_URL",
                "https://renounce-antsy-grunt.ngrok-free.dev"
            )

        major_version = self.get_server_major_version()
        logging.info(f"[PUSH] Target Odoo major version: {major_version}")

        # Check if direct companion addon ubtms_push is installed on Odoo
        try:
            direct_ok = self.models.execute_kw(
                self.db, self.uid, self.password,
                'res.users', 'register_ubports_token', [ubports_token]
            )
            if direct_ok is True:
                logging.info(f"[PUSH] Registered direct companion addon push for UID {self.uid}")
                return {"mode": "direct_addon", "success": True}
        except Exception:
            pass

        # Attempt native Odoo 17+ WebPush if version >= 17 or unknown
        if major_version >= 17 or major_version == 0:
            try:
                vapid_key = self.models.execute_kw(
                    self.db, self.uid, self.password,
                    'mail.partner.device', 'get_web_push_vapid_public_key', []
                )
                if vapid_key:
                    sub_url = f"{bridge_url.rstrip('/')}/v1/subscription/{ubports_token}"
                    req = urllib.request.Request(
                        sub_url,
                        headers={"User-Agent": "ubtms/1.3.4"}
                    )
                    with urllib.request.urlopen(req, timeout=5) as resp:
                        if resp.status == 200:
                            sub_data = json.loads(resp.read().decode("utf-8"))
                            endpoint = sub_data.get("endpoint")
                            keys = sub_data.get("keys")
                            if endpoint and keys:
                                self.models.execute_kw(
                                    self.db, self.uid, self.password,
                                    'mail.partner.device', 'register_devices', [],
                                    {
                                        'endpoint': endpoint,
                                        'keys': keys,
                                        'vapid_public_key': vapid_key,
                                    }
                                )
                                logging.info(f"[PUSH] Registered native push device on Odoo for UID {self.uid}")
                                return {"mode": "native", "success": True}
            except Exception as e:
                logging.info(f"[PUSH] Native WebPush unavailable: {e}")

        # Fallback for Odoo 14-16: Register account with Bridge-side polling worker
        try:
            legacy_url = f"{bridge_url.rstrip('/')}/v1/legacy/register"
            payload = json.dumps({
                "ubports_token": ubports_token,
                "odoo_url": self.url,
                "db": self.db,
                "username": self.username,
                "password": self.password,
                "uid": self.uid
            }).encode("utf-8")
            req = urllib.request.Request(
                legacy_url,
                data=payload,
                headers={
                    "Content-Type": "application/json",
                    "User-Agent": "ubtms/1.3.4"
                }
            )
            with urllib.request.urlopen(req, timeout=5) as resp:
                if resp.status in (200, 201):
                    logging.info(f"[PUSH] Registered legacy bridge poller for Odoo {major_version} (UID {self.uid})")
                    return {"mode": "legacy_bridge", "success": True}
        except Exception as e:
            logging.warning(f"[PUSH] Legacy bridge poller registration failed: {e}")

        return {"mode": "none", "success": False}
