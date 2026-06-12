---
title: Repository Organization
sidebar_label: Repository Organization
---

# Repository Organization

This page is the Docusaurus migration of the repository organization guidance.

## Storage principles

The repository is organized by responsibility:

- `qml/` contains the UI layer
- `models/` contains JavaScript data and state helpers used by QML
- `src/` contains Python backend, sync, daemon, and utility logic
- `assets/` contains package-level branding assets
- `docs/` contains source documentation
- `scripts/` contains local maintenance and validation scripts

Within each area, files should be grouped by feature first and by technical role second.

## QML UI layer

The `qml/` tree is already split into stable areas:

- `qml/app/` for shell, startup, navigation, and app-level pages
- `qml/components/` for shared UI building blocks
- `qml/features/` for business-domain features with local pages and components
- `qml/images/` for runtime UI image assets

## JavaScript model layer

The `models/` directory contains reusable JavaScript modules imported by QML.

Use `models/` for cross-feature helpers and shared app state. Keep feature-specific JavaScript inside feature folders unless it becomes broadly shared.

## Python backend layer

The `src/` directory contains runtime Python for:

- backend bridging
- daemon logic
- remote sync behavior
- configuration and logging
- helper tools that ship with the app

## Documentation note

The original longer source for this guidance remains in the repository during migration:

- [Technical File Organization Source](https://github.com/CITOpenRep/timemanagement/blob/main/docs/TECHNICAL-FILE-ORGANIZATION.md)
