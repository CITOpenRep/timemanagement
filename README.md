# TimeManagement

TimeManagement is a desktop and Ubuntu Touch project for task, timesheet, dashboard, and sync-oriented workflows.

## Key Features

- **Task Management:** Create, track, and manage your tasks with powerful filters and intuitive search capabilities.
- **Timesheets & Activity Tracking:** Log hours, categorize activities, and manage your timesheets efficiently.
- **Interactive Dashboard:** Gain insights into your productivity with interactive charts, visualizations, and statistics.
- **Odoo Sync Integration:** Seamlessly synchronize tasks, timesheets, and projects with an Odoo/CURQ backend instance (supporting offline caching and background synchronization).
- **Confined Push Notifications:** Native push notification delivery via UBports Push Server without background polling daemons, preserving battery and complying with standard AppArmor confinement.
- **Ubuntu Touch & Desktop Support:** Built with QML (Qt) and Python, optimized for Ubuntu Touch mobile devices (deployed via Clickable) and desktop environments.

## Push Notifications Architecture

The app uses the native Ubuntu Touch push notification infrastructure without requiring unconfined AppArmor permissions or local phone daemons:

* **Odoo 17+ (Native WebPush)**: Automatically registers with Odoo `mail.partner.device` and relays notifications through `push-bridge/` to the UBports Push Server.
* **Odoo 14–16 (Cloud Poller)**: Automatically registers with the bridge poller to monitor activities server-side and dispatch notifications to the phone.
* **Self-Hosted Addon (`odoo-addon/ubtms_push`)**: Optional direct Odoo module for on-premise deployments that dispatches pushes straight to UBports without an external bridge.

## Documentation Website

The documentation website has been migrated to its own dedicated repository:

- **Repository:** [CITOpenRep/TimeManagement_Docs](https://github.com/CITOpenRep/TimeManagement_Docs)
- **New Published URL:** [https://citopenrep.github.io/TimeManagement_Docs/](https://citopenrep.github.io/TimeManagement_Docs/)


The documentation website hosts:
- Product-facing overview content
- User guides and sync configuration manuals
- Technical architecture and codebase layout specifications
- Contributor guides, localization policies, and versioning rules

To contribute to or develop the documentation website, please clone the [TimeManagement_Docs](https://github.com/CITOpenRep/TimeManagement_Docs) repository and follow the instructions in its README.

## App build and run

For the current application workflow:

```bash
clickable desktop
clickable install
```

## Existing source docs

The legacy Markdown docs in `docs/` remain available during the migration into the Docusaurus site.

## Repository references

- [Technical file organization](docs/TECHNICAL-FILE-ORGANIZATION.md)
- [Pull request guidelines](docs/PR-GUIDELINES.md)
