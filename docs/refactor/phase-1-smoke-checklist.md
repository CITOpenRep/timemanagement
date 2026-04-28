# Refactor Smoke Checklist

Run this checklist after each migration chunk.

## App Startup And Layout

- App launches on desktop.
- 1-column startup works.
- 2-column startup works.
- 3-column startup works.

## Navigation

- Drawer navigation opens every top-level page.
- Menu navigation opens every top-level page.
- Deep-link navigation works for:
  - Task
  - Activity
  - ProjectUpdate
  - Project
  - Timesheet

## Data Refresh And Account Switching

- Account switch triggers visible-page refresh.
- Dashboard refresh still works.
- Timesheet list and editor refresh still work.
- Task list and editor refresh still work.
- Activity list and editor refresh still work.
- Project list and editor refresh still work.
- Update list and editor refresh still work.

## CRUD Flows

- Task create/edit/view works.
- Timesheet create/edit/view works.
- Project create/edit/view works.
- Activity create/edit/view works.
- Update create/edit/view works.

## Drafts, Settings, And Notifications

- Unsaved draft restore flow works.
- Theme/settings pages work.
- Notification badge still updates.
- Daemon startup and notification initialization still work.

## Python Import Smoke

Run:

- python3 -c "import sys; sys.path.insert(0, 'src'); import backend; print('ok backend')"
- python3 -c "import sys; sys.path.insert(0, 'src'); import daemon; print('ok daemon')"
- python3 -c "import sys; sys.path.insert(0, 'src'); import cli; print('ok cli')"

When package migration begins, add:

- python3 -c "import sys; sys.path.insert(0, 'src'); import ubtms; print('ok ubtms')"

## Reference Audit Gates

Before removing wrappers, confirm:

- grep shows zero references to old wrapper paths.
- no new imports were added to deprecated paths in migrated layers.
