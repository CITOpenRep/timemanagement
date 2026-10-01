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

import json
import xmlrpc.client
import urllib3
from logger import setup_logger

log = setup_logger()

urllib3.disable_warnings()
http = urllib3.PoolManager(cert_reqs="CERT_NONE")


def check_server_reachability(url, timeout=3):
    """
    Check if the Odoo server is reachable using a lightweight HTTP request.
    Uses urllib3 PoolManager to ensure compatibility with Ubuntu Touch AppArmor sandbox rules.
    """
    try:
        normalized = (url or "").strip().rstrip("/")
        if not normalized:
            return False

        if "://" not in normalized:
            normalized = f"https://{normalized}"

        response = http.request("HEAD", normalized, timeout=timeout, redirect=True)
        return True
    except Exception as e:
        log.warning(f"[REACHABILITY] HTTP HEAD failed for {url}: {e}")
        try:
            response = http.request("GET", normalized, timeout=timeout, redirect=True)
            return True
        except Exception as e2:
            log.warning(f"[REACHABILITY] HTTP GET fallback also failed: {e2}")
            return False


def get_db_list(url):
    """
    Retrieve list of available databases from an Odoo server.
    """
    try:
        response = http.request(
            "POST",
            url.rstrip("/") + "/web/database/list",
            body="{}",
            headers={"Content-type": "application/json"},
        )
        if response.status == 200:
            data = json.loads(response.data)
            return data.get("result", [])
        return []
    except Exception as e:
        log.error(f"[Critical] No DB found {e}")
        return []


def fetch_databases(url):
    """
    Fetch available databases from an Odoo server and determine UI visibility options.
    """
    database_list = get_db_list(url)
    visibility_dict = {
        "menu_items": False,
        "text_field": False,
        "single_db": False,
    }

    if not database_list:
        visibility_dict["text_field"] = True
    elif len(database_list) == 1:
        visibility_dict["single_db"] = database_list[0]
    else:
        visibility_dict["menu_items"] = database_list

    return database_list


def login_odoo(selected_url, username, password, selected_db):
    """
    Authenticate user credentials against an Odoo server.
    """
    common = xmlrpc.client.ServerProxy(f"{selected_url}/xmlrpc/2/common")
    generated_uid = common.authenticate(selected_db, username, password, {})
    if generated_uid:
        models = xmlrpc.client.ServerProxy(f"{selected_url}/xmlrpc/2/object")
        user_name = models.execute_kw(
            selected_db,
            generated_uid,
            password,
            "res.users",
            "read",
            [generated_uid],
            {"fields": ["name"]},
        )
        return {
            "status": "pass",
            "name_of_user": user_name[0]["name"],
            "database": selected_db,
            "uid": generated_uid,
        }
    return {"result": "fail"}
