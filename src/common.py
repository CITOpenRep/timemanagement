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

from datetime import datetime
import json
import sqlite3
from pathlib import Path
from logger import setup_logger

import sqlite3
import time
import sqlite3
import time
import threading
from logger import setup_logger

log = setup_logger()

# Optional: Global lock if multithreaded write access is expected
db_lock = threading.Lock()


def safe_sql_execute(
    db_path,
    sql,
    values=(),
    retries=5,
    delay=0.2,
    commit=True,
    fetch=False,
    many=False,
):
    for attempt in range(retries):
        try:
            with db_lock:  # Ensures thread-safe access
                conn = sqlite3.connect(db_path, check_same_thread=False)
                cursor = conn.cursor()
                if many:
                    cursor.executemany(sql, values)
                else:
                    cursor.execute(sql, values)

                result = cursor.fetchall() if fetch else None

                if commit:
                    conn.commit()
                conn.close()
                return result

        except sqlite3.OperationalError as e:
            if "locked" in str(e).lower() and attempt < retries - 1:
                log.debug("database is locked, delaying")
                time.sleep(delay)
                continue
            raise e
        except Exception as e:
            raise e


def sanitize_datetime(value):
    try:
        if isinstance(value, str) and value.strip() and value != "0":
            # Try parsing to validate
            datetime.fromisoformat(value)
            return value
    except Exception:
        pass
    return None  # Invalid datetime replaced with NULL


def check_table_exists(db_path, table_name):
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
        tables = [row[0] for row in cursor.fetchall()]
        print(f"[DEBUG] Tables in DB: {tables}")
        conn.close()
        return table_name in tables
    except Exception as e:
        print(f"[ERROR] Failed to inspect DB: {e}")
        return False

    import json
    from datetime import datetime


def write_sync_report_to_db(db_path, account_id, status, message=""):

    log_output = log.json_handler.get_json_string()
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Ensure table exists
    cursor.execute(
        """
        CREATE TABLE IF NOT EXISTS sync_report (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            status TEXT,
            account_id INTEGER,
            timestamp TEXT,
            message TEXT
        )
    """
    )

    cursor.execute(
            "DELETE FROM sync_report WHERE account_id = ?",
            (account_id,)
        )

    # Insert report
    cursor.execute(
        """
        INSERT INTO sync_report (status, account_id, timestamp, message)
        VALUES (?, ?, ?, ?)
    """,
        (status, account_id, datetime.utcnow().isoformat() + "Z", log_output),
    )

    conn.commit()
    conn.close()
