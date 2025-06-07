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

import sqlite3
import os


def initialize_app_settings_db(db_path="app_settings.db"):
    if not os.path.exists(db_path):
        print(f"Creating new database at {db_path}")
    else:
        print(f"Database already exists at {db_path}. Checking tables...")


def get_all_accounts(settings_db_path):
    conn = sqlite3.connect(settings_db_path)
    cur = conn.cursor()
    cur.execute("SELECT id, name, link, database, username, api_key FROM users")
    rows = cur.fetchall()
    conn.close()
    return [
        dict(zip(["id", "name", "link", "database", "username", "api_key"], row))
        for row in rows
    ]
