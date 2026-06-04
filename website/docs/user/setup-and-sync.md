title: Setup and Sync
sidebar_label: Setup and Sync
---

# Setup and Sync

TimeManagement includes Python backend services and sync-related modules that support account-driven workflows.

## Setup areas to expect

Users and maintainers should expect setup work around:

- account configuration
- remote service credentials
- background daemon behavior
- field mapping and synchronization

## Relevant code areas

The current implementation spreads sync responsibilities across the Python backend:

- `src/odoo_client.py`
- `src/sync_from_odoo.py`
- `src/sync_to_odoo.py`
- `src/tool_field_sync.py`
- `src/config.py`

## Documentation expectations

As the product documentation expands, this page should become the stable entry point for:

- account onboarding
- sync prerequisites
- remote system troubleshooting
- known limits and operational notes

For now, pair this page with [Troubleshooting](./troubleshooting.md) and the technical architecture docs.
