#!/usr/bin/env python3
"""
CLI utility to send manual push notifications to the connected Ubuntu Touch device.
"""

import sys
import argparse
import requests
from datetime import datetime, timezone, timedelta

DEFAULT_TOKEN = "dWJ0bXNfdWJ0bXM6OnV0dFRuWnpDTXczZXRlUTFORjFmTHNyTmpqUjlEekt0ejhhNllnPT0="
UBPORTS_PUSH_URL = "https://push.ubports.com/notify"

def main():
    parser = argparse.ArgumentParser(description="Send a manual push notification to Ubuntu Touch")
    parser.add_argument("--title", "-t", default="Manual Test Notification", help="Notification title")
    parser.add_argument("--body", "-b", default="This is a test notification sent manually.", help="Notification body")
    parser.add_argument("--type", choices=["Task", "Activity", "Project", "Timesheet"], default="Task", help="Record type")
    parser.add_argument("--id", type=int, default=1, help="Odoo record ID to redirect to")
    parser.add_argument("--token", default=DEFAULT_TOKEN, help="UBports device push token")
    parser.add_argument("--urgent", action="store_true", help="Bypass quiet hours schedule")

    args = parser.parse_args()

    expire_on = (datetime.now(timezone.utc) + timedelta(hours=24)).strftime("%Y-%m-%dT%H:%M:%SZ")

    payload = {
        "appid": "ubtms_ubtms",
        "token": args.token,
        "expire_on": expire_on,
        "data": {
            "notification": {
                "card": {
                    "summary": args.title,
                    "body": args.body,
                    "icon": "assets/logo.png",
                    "popup": True,
                    "persist": True,
                    "urgent": args.urgent,
                    "actions": [
                        f"ubtms://notification?type={args.type}&id={args.id}&odoo_id=1",
                        "appid://ubtms/ubtms/current-user-version"
                    ]
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

    print(f"Sending push notification to {args.token[:12]}...")
    print(f"Title: {args.title}")
    print(f"Body:  {args.body}")
    print(f"Route: ubtms://notification?type={args.type}&id={args.id}&odoo_id=1")

    try:
        resp = requests.post(UBPORTS_PUSH_URL, json=payload, timeout=10)
        if resp.status_code in (200, 201):
            print(f"Success! (HTTP {resp.status_code}) Notification delivered to phone.")
        else:
            print(f"Error (HTTP {resp.status_code}): {resp.text}")
    except Exception as e:
        print(f"Failed to connect to UBports Push Server: {e}")

if __name__ == "__main__":
    main()
