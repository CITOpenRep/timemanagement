---
title: Troubleshooting
sidebar_label: Troubleshooting
---

# Troubleshooting

Use this page as the first stop for common issues until dedicated support runbooks are added.

## Build and startup

Check these first:

- `clickable --version` returns successfully
- Docker is available when your build flow depends on it
- `clickable desktop` runs from the repository root

## Sync-related issues

If sync behavior is failing:

- review account and endpoint settings
- inspect Python sync modules under `src/`
- review daemon-related code paths such as `src/daemon.py` and `src/daemon_bootstrap.py`

## Database notes

The repository references a local application database path under:

```text
~/.clickable/home/.local/share/ubtms/Databases
```

## When to escalate

Open a GitHub issue when:

- the app no longer starts on desktop
- device installation fails consistently
- sync behavior regresses after an upgrade
- a feature-specific screen breaks in one of the known QML feature areas
