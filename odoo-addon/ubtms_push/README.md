# ubtms_push (Odoo Addon)

Optional companion addon for self-hosted Odoo instances (compatible with Odoo 14, 15, 16, 17, and 18).
Dispatches push notifications directly to the UBports Push Server when activities or tasks are assigned, without requiring an external relay bridge.

## Installation

1. Copy the `ubtms_push` directory to your Odoo custom addons directory.
2. Update the apps list in Odoo:
   * Activate Developer Mode.
   * Go to **Apps** -> **Update Apps List**.
3. Search for `Ubuntu Touch TimeManagement Push Notifications` and click **Install**.

## Usage

When users connect from the Ubuntu Touch app (`ubtms`), their device token is automatically registered to their user record.
* Creating an activity sends a push notification to the assigned user.
* Assigning a task sends a push notification to all assigned users.
