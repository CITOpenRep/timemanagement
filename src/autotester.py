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

import shutil
import time
from pathlib import Path
from abc import ABC, abstractmethod
from sync_from_odoo import sync_all_from_odoo
from sync_to_odoo import sync_all_to_odoo
from odoo_client import OdooClient
from config import get_all_accounts

import sqlite3
from datetime import datetime

def get_timestamp():
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")

def execute_sql(db_path, sql, values=(), fetch=False):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print(f"[SQL] Executing:\n  {sql}\n  [VALUES] {values}")
    cursor.execute(sql, values)

    result = cursor.fetchall() if fetch else None
    print(f"***************[SQL] Rows affected: {cursor.rowcount}*******************")

    conn.commit()
    conn.close()

    return result

# ... [keep all your import and helper function sections unchanged]

class TestCaseBase(ABC):
    def __init__(self, temp_db_path, account_index, account_id):
        self.temp_db_path = temp_db_path
        self.account_index = account_index
        self.account_id = account_id
        self.data = {}
        self.client = self.get_client()
        self.result = {"status": "Not Run", "message": ""}

    def mark_success(self, message=""):
        self.result["status"] = "Passed"
        self.result["message"] = message

    def mark_failure(self, message=""):
        self.result["status"] = "Failed"
        self.result["message"] = message

    def get_client(self):
        accounts = get_all_accounts(self.temp_db_path)
        selected = accounts[self.account_index]
        return OdooClient(
            selected["link"],
            selected["database"],
            selected["username"],
            selected["api_key"]
        )

    def verify_project_exists(self, name):
        ids = self.client.search("project.project", [["name", "=", name]])
        return bool(ids)

    def verify_task_exists(self, task_name):
        ids = self.client.search("project.task", [["name", "=", task_name]])
        return bool(ids)

    def sync_push(self):
        sync_all_to_odoo(self.client, self.account_id, self.temp_db_path)

    def sync_pull(self):
        sync_all_from_odoo(self.client, self.account_id, self.temp_db_path)

    @abstractmethod
    def run(self):
        pass

    @abstractmethod
    def check(self):
        pass


# --- Test Cases (corrected with closing parens and proper field access)

class CreateProjectTest(TestCaseBase):
    def __init__(self, *args):
        super().__init__(*args)
        self.data = {"name": "ProjectA"}

    def run(self):
        ts = get_timestamp()
        execute_sql(
            self.temp_db_path,
            "INSERT INTO project_project_app (name, account_id, last_modified, status, last_update_status) VALUES (?, ?, ?, ?, ?)",
            (self.data["name"], self.account_id, ts, "updated", "to_define")
        )
        print(f"[TEST] Created project '{self.data['name']}'")
        self.sync_push()

    def check(self):
        if self.verify_project_exists(self.data["name"]):
            self.mark_success(f"[PASS] Project '{self.data['name']}' exists in Odoo.")
        else:
            self.mark_failure(f"[FAIL] Project '{self.data['name']}' not found in Odoo!")


class UpdateProjectTest(TestCaseBase):
    def __init__(self, *args):
        super().__init__(*args)
        self.data = {"old_name": "ProjectA", "new_name": "ProjectB"}

    def run(self):
        ts = get_timestamp()
        execute_sql(
            self.temp_db_path,
            "UPDATE project_project_app SET name = ?, last_modified = ?, status = 'updated' WHERE name = ?",
            (self.data["new_name"], ts, self.data["old_name"])
        )
        print(f"[TEST] Renamed project '{self.data['old_name']}' → '{self.data['new_name']}'")
        self.sync_push()

    def check(self):
        if self.verify_project_exists(self.data["new_name"]):
            self.mark_success(f"[PASS] Project '{self.data['new_name']}' exists in Odoo.")
        else:
            self.mark_failure(f"[FAIL] Project '{self.data['new_name']}' not found in Odoo!")


class DeleteProjectTest(TestCaseBase):
    def __init__(self, *args):
        super().__init__(*args)
        self.data = {"name": "ProjectB"}

    def run(self):
        ts = get_timestamp()
        execute_sql(
            self.temp_db_path,
            "UPDATE project_project_app SET status = 'deleted', last_modified = ? WHERE name = ?",
            (ts, self.data["name"])
        )
        print(f"[TEST] Marked project '{self.data['name']}' for deletion")
        self.sync_push()

    def check(self):
        if not self.verify_project_exists(self.data["name"]):
            self.mark_success(f"[PASS] Project '{self.data['name']}' is deleted from Odoo.")
        else:
            self.mark_failure(f"[FAIL] Project '{self.data['name']}' still exists in Odoo!")


class CreateTask(TestCaseBase):
    def __init__(self, *args):
        super().__init__(*args)
        self.data = {"name": "ProjectA", "task_name": "TaskForProject"}

    def run(self):
        ts = get_timestamp()
        """row = execute_sql(
            self.temp_db_path,
            "SELECT odoo_record_id FROM project_project_app WHERE name = ?",
            (self.data["name"],),
            fetch=True
        )
        if not row or not row[0][0]:
            print(f"[ERROR] Odoo project ID not found for '{self.data['name']}'")
            return

        odoo_project_id = int(row[0][0])
        """
        execute_sql(
            self.temp_db_path,
            "INSERT INTO project_task_app (name, project_id, account_id, last_modified, status) VALUES (?, ?, ?, ?, ?)",
            (self.data["task_name"], 0, self.account_id, ts, "updated")
        )
        print(f"[TEST] Created task '{self.data['task_name']}' under project '{self.data['name']}'")
        self.sync_push()

    def check(self):
        if self.verify_task_exists(self.data["task_name"]):
            self.mark_success(f"[PASS] Task '{self.data['task_name']}' exists in Odoo.")
        else:
            self.mark_failure(f"[FAIL] Task '{self.data['task_name']}' not found in Odoo!")


class DeleteTask(TestCaseBase):
    def __init__(self, *args):
        super().__init__(*args)
        self.data = {"task_name": "TaskForProject"}

    def run(self):
        ts = get_timestamp()
        row = execute_sql(
            self.temp_db_path,
            "SELECT id FROM project_task_app WHERE name = ?",
            (self.data["task_name"],),
            fetch=True
        )
        if not row:
            print(f"[ERROR] Task '{self.data['task_name']}' not found.")
            return

        execute_sql(
            self.temp_db_path,
            "UPDATE project_task_app SET status = 'deleted', last_modified = ? WHERE name = ?",
            (ts, self.data["task_name"])
        )
        print(f"[TEST] Marked task '{self.data['task_name']}' for deletion")
        self.sync_push()

    def check(self):
        if not self.verify_task_exists(self.data["task_name"]):
            self.mark_success(f"[PASS] Task '{self.data['task_name']}' is deleted from Odoo.")
        else:
            self.mark_failure(f"[FAIL] Task '{self.data['task_name']}' still exists in Odoo!")


# --- Runner with summary

class OdooTestRunner:
    def __init__(self):
        self.original_db = self.get_original_db_path()
        self.temp_db_path = "test_data/temp_app.db"
        self.account_index = 0
        self.account_id = 1

    def get_original_db_path(self, db_filename="8912ff6b21d680ad2a2832070dca24d0.sqlite"):
        base_path = Path.home() / ".clickable" / "home" / ".local" / "share" / "ubtms" / "Databases"
        full_path = base_path / db_filename
        if not full_path.exists():
            raise FileNotFoundError(f"Database not found: {full_path}")
        return str(full_path)

    def setup_temp_db(self):
        shutil.copyfile(self.original_db, self.temp_db_path)
        print(f"[SETUP] Copied original DB to temp: {self.temp_db_path}")

    def run_all_tests(self):
        self.setup_temp_db()
        """
        test_sequence = [
            CreateProjectTest,
            CreateTask,
            DeleteTask,
            UpdateProjectTest,
            DeleteProjectTest,
        ]
        """
        test_sequence = [
            CreateTask,
            DeleteTask,
        ]
        test_instances = []
        for test_cls in test_sequence:
            test = test_cls(self.temp_db_path, self.account_index, self.account_id)
            try:
                test.run()
                test.check()
            except Exception as e:
                test.mark_failure(str(e))
            test_instances.append((test_cls.__name__, test.result))

        print("\n=== TEST SUMMARY ===")
        for name, result in test_instances:
            print(f"{name}: {result['status']} - {result['message']}")


if __name__ == "__main__":
    runner = OdooTestRunner()
    runner.run_all_tests()
