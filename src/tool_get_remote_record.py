# -*- coding: utf-8 -*-
# MIT License (see top for full terms)

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


def fetch_record_by_id(model_name, record_id, models, db, uid, password):
    """Fetch all fields of a record with given ID."""
    return models.execute_kw(
        db,
        uid,
        password,
        model_name,
        'read',
        [[record_id]],
        {'fields': []}
    )[0]


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

    # Model menu
    model_options = [
        "project.project",
        "project.task",
        "account.analytic.line",
        "res.users",
        "mail.activity",
        "mail.activity.type"
    ]

    print("\nAvailable models:")
    for i, model in enumerate(model_options):
        print(f"{i + 1}. {model}")

    model_index = int(input("Select a model: ")) - 1
    model_name = model_options[model_index]

    # Record ID
    record_id = int(input(f"Enter Odoo record ID for model '{model_name}': "))

    # Fetch and display record
    try:
        record = fetch_record_by_id(model_name, record_id, models, selected["database"], uid, selected["api_key"])
        print("\n Record Details:")
        for k, v in record.items():
            print(f"{k}: {v}")
    except Exception as e:
        print(f"❌ Error: {e}")


if __name__ == "__main__":
    main()
