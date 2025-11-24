#!/usr/bin/env python3
"""
Quick test to send a notification from Python via DBus
Run this on device to test if daemon would work
"""

import dbus
from dbus.mainloop.glib import DBusGMainLoop
import json

# Initialize DBus
DBusGMainLoop(set_as_default=True)
bus = dbus.SessionBus()

def send_test_notification():
    """Send a test notification using DBus Postal interface"""
    try:
        # Get Postal interface
        postal = bus.get_object('com.lomiri.Postal', '/com/lomiri/Postal/ubtms')
        postal_iface = dbus.Interface(postal, 'com.lomiri.Postal')
        
        # Build notification JSON
        notification_data = {
            "notification": {
                "card": {
                    "summary": "Daemon Test",
                    "body": "This notification was sent from Python daemon test!",
                    "icon": "/opt/click.ubuntu.com/ubtms/current/icon.png",
                    "actions": ["appid://ubtms/ubtms/current-user-version"],
                    "popup": True,
                    "persist": True
                },
                "sound": True,
                "vibrate": True
            }
        }
        
        # Post notification
        print("[TEST DAEMON] Sending notification via DBus...")
        postal_iface.Post("ubtms_ubtms", json.dumps(notification_data))
        print("[TEST DAEMON] Notification sent successfully!")
        return True
        
    except Exception as e:
        print(f"[TEST DAEMON] Error sending notification: {e}")
        return False

if __name__ == '__main__':
    print("[TEST DAEMON] Starting notification test...")
    result = send_test_notification()
    if result:
        print("[TEST DAEMON] ✅ Test successful - notifications will work from daemon")
    else:
        print("[TEST DAEMON] ❌ Test failed - check DBus permissions")
