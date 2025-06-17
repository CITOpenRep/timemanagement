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
from config import get_all_accounts


def fetch_fields(model_name, models, db, uid, password):
    """Fetch field metadata for a given model."""
    return models.execute_kw(
        db,
        uid,
        password,
        model_name,
        "fields_get",
        [],
        {"attributes": ["string", "type"]},
    )


def main():
    # Select account
    settings_db = "/home/gokul/.clickable/home/.local/share/ubtms/Databases/8912ff6b21d680ad2a2832070dca24d0.sqlite"
    accounts = get_all_accounts(settings_db)
    print("Available accounts:")
    for i, acct in enumerate(accounts):
        print(f"{i + 1}. {acct['name']} ({acct['link']})")

    selected_index = int(input("Select account: ")) - 1
    selected = accounts[selected_index]

    # Authenticate
    common = xmlrpc.client.ServerProxy(f"{selected['link']}/xmlrpc/2/common")
    uid = common.authenticate(
        selected["database"], selected["username"], selected["api_key"], {}
    )

    if not uid:
        print("❌ Authentication failed.")
        return

    models = xmlrpc.client.ServerProxy(f"{selected['link']}/xmlrpc/2/object")

    # Fetch fields
    fields_data = {}
    for model in ["project.project", "project.task","account.analytic.line","res.users","mail.activity"]:
        print(f"Fetching fields for {model}...")
        fields_data[model] = fetch_fields(
            model, models, selected["database"], uid, selected["api_key"]
        )

    # Save to JSON
    with open("odoo_config/all_odoo_fields.json", "w") as f:
        json.dump(fields_data, f, indent=4)

    print("✅ Field metadata saved to odoo_fields.json")


if __name__ == "__main__":
    main()
