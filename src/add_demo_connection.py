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
from datetime import datetime


def add_odoo_account(
    db_path="app_settings.db",
    name="Onestein Demo",
    url="https://demo16.onestein.eu/",
    database="project_demo",
    username="admin",
    api_key=None,
    connectwith_id=None,
):
    if not os.path.exists(db_path):
        print(f"Database {db_path} does not exist. Please initialize it first.")
        return

    with sqlite3.connect(db_path) as conn:
        cursor = conn.cursor()

        # Insert account into users table
        cursor.execute(
            """
            INSERT INTO users (name, link, last_modified, database, connectwith_id, api_key, username)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """,
            (
                name,
                url,
                datetime.now().isoformat(),
                database,
                connectwith_id,
                api_key,
                username,
            ),
        )

        conn.commit()
        conn.close()
        print("✅ Odoo account added successfully.")


if __name__ == "__main__":
    add_odoo_account()
