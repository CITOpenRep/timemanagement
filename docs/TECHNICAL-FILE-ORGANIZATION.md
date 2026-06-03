# Technical File Organization

This document explains how files are currently stored in the `timemanagement` project and how new files should be placed going forward.

Its goal is to make the repository easier to navigate, reduce misplaced files, and keep imports, packaging, and maintenance predictable.

## 1. Storage Principles

The repository is organized by responsibility:

- `qml/` contains the UI layer.
- `models/` contains JavaScript data and state helpers used by QML.
- `src/` contains Python backend, sync, daemon, and utility logic.
- `assets/` contains package-level branding assets.
- `docs/` contains project documentation.
- `scripts/` contains local maintenance and validation scripts.

Within each area, files should be grouped by feature first and by technical role second.

## 2. Current Repository Layout

### Root-Level Infrastructure

The repository root contains build, packaging, and launcher files such as:

- `CMakeLists.txt`
- `clickable.yaml`
- `manifest.json.in`
- `ubtms.desktop.in`
- AppArmor and push-helper configuration files
- helper entrypoints such as `start-daemon.sh` and `push-helper.py`

These should remain at the root unless the build system is changed.

### QML UI Layer

`qml/` is the main frontend tree. It is already split into several stable areas:

- `qml/app/`
  - application shell, startup, navigation, drawer, and top-level pages
- `qml/components/`
  - reusable shared UI components
- `qml/features/`
  - feature-specific pages, feature widgets, and feature-local JavaScript
- `qml/images/`
  - runtime image assets used directly by the QML UI

#### `qml/app/`

Use this folder for application-wide UI infrastructure:

- `qml/app/AppLayout.qml`
- `qml/app/GlobalWidgets.qml`
- `qml/app/StartupManager.qml`
- `qml/app/SystemIntegrationManager.qml`
- `qml/app/navigation/`
- `qml/app/pages/`

Files belong here when they are part of the overall app shell rather than a specific business feature.

Examples:

- splash screen
- about page
- navigation controller
- route definitions

#### `qml/components/`

Use `qml/components/` for reusable building blocks shared across multiple features.

Current subgroups include:

- `base/` for low-level reusable primitives
- `cards/` for reusable content cards
- `dialogs/` for shared dialogs and popups
- `feedback/` for notifications, loading states, and status UI
- `navigation/` for shared navigation widgets
- `pickers/` for date/time and selection pickers
- `richtext/` for rich-text editing and preview components
- `selectors/` for entity selection controls
- `system/` for bridge/system-level UI helpers
- `visualization/` for charts and visual widgets
- `workflow/` for multi-step or form-support flows

Rule:

- If a QML file is used by more than one feature, it should normally live under `qml/components/`.

Examples:

- `qml/components/richtext/ReadMorePage.qml`
- `qml/components/base/UbuntuShape.qml`
- `qml/components/dialogs/CreateUpdateDialog.qml`
- `qml/components/system/ModelDownloadTimerWidget.qml`

#### `qml/features/`

Use `qml/features/` for business-domain functionality.

Current feature folders are:

- `activities/`
- `dashboard/`
- `projects/`
- `settings/`
- `tasks/`
- `timesheets/`
- `updates/`

Each feature should keep its own files close together. The current pattern is:

- `pages/` for top-level screens
- `components/` for feature-local widgets
- `js/` for feature-local JavaScript helpers
- `charts/` where a feature owns custom chart QML

Rule:

- If a file is only used inside one feature, keep it inside that feature instead of placing it in `qml/components/`.

Examples:

- `qml/features/tasks/pages/Tasks.qml`
- `qml/features/tasks/components/TaskList.qml`
- `qml/features/dashboard/js/chartUtils.js`

#### `qml/images/`

Use `qml/images/` for images loaded by the QML interface at runtime.

This includes:

- icons
- logos used in pages
- PNG/SVG assets referenced by `Image { source: ... }`

Example:

- `qml/images/logo.png`

Rule:

- If an asset is referenced by QML during app runtime, prefer `qml/images/`.

### JavaScript Model Layer

`models/` contains shared JavaScript modules imported by QML.

Examples:

- `models/Main.js`
- `models/global.js`
- `models/task.js`
- `models/timesheet.js`
- `models/database.js`

Rule:

- Shared app state, data access helpers, and cross-feature JS modules belong in `models/`.
- Feature-specific JS should stay inside `qml/features/<feature>/js/` unless it becomes broadly shared.

Important note:

- QML files imported from `qml/` often reference `models/` through relative imports.
- When moving a QML file, its `import "../../../models/..."` style paths must be rechecked carefully.

### Python Backend Layer

`src/` contains Python code for:

- backend bridging
- Odoo/CURQ sync
- daemon logic
- configuration
- logging
- helper tools

Examples:

- `src/backend.py`
- `src/daemon.py`
- `src/odoo_client.py`
- `src/sync_from_odoo.py`
- `src/sync_to_odoo.py`

Rule:

- App runtime Python belongs in `src/`.
- Development-only helper scripts should go in `scripts/` instead of `src/` unless they are intentionally shipped with the app.

### Assets

`assets/` contains package-level or source-branding assets that are not primarily organized as QML runtime UI images.

Examples:

- `assets/logo.svg`
- `assets/logo.png`
- generated logo variants

Rule:

- Keep original branding/source artwork in `assets/`.
- Keep QML-consumed UI copies in `qml/images/` when they are used directly by the frontend.

### Documentation

`docs/` stores project documentation such as:

- contribution process
- architecture notes
- technical conventions
- future refactor notes

Rule:

- Add technical repository conventions here instead of only describing them in PRs or commit messages.

### Scripts

`scripts/` contains maintenance utilities for developers.

Examples:

- unused-code checks
- refactor checks
- validation helpers

Rule:

- Scripts that are for developer workflow and not shipped app behavior should live here.

## 3. Where New Files Should Go

Use the following placement rules when adding new files.

### New QML Page

- App-wide page: `qml/app/pages/`
- Feature page: `qml/features/<feature>/pages/`
- Shared workflow/editor page used across features: `qml/components/<group>/`

### New Reusable QML Component

- Put it in the most specific shared subgroup under `qml/components/`
- If no subgroup fits, create one only when there is a clear category with more than one likely component

### New Feature-Specific QML Component

- Put it under `qml/features/<feature>/components/`

### New JavaScript Helper

- Shared across features: `models/`
- Used only by one feature: `qml/features/<feature>/js/`

### New Image or Icon

- Used directly by QML: `qml/images/`
- Source artwork or packaging asset: `assets/`

### New Python Module

- Runtime/backend logic: `src/`
- Developer utility or validation script: `scripts/`

### New Documentation

- Project/process/architecture/reference docs: `docs/`

## 4. Current State Summary

The repository is already mostly organized around a good long-term structure:

- shared UI lives under `qml/components/`
- business screens live under `qml/features/`
- app shell code lives under `qml/app/`
- shared JS models live under `models/`
- backend Python lives under `src/`

Recent cleanup also moved previously loose QML files into more relevant locations:

- `ReadMorePage.qml` into `qml/components/richtext/`
- `UbuntuShape.qml` into `qml/components/base/`
- `release_notes.txt` into `qml/app/pages/`
- runtime `logo.png` into `qml/images/`

This direction should be preserved for future work.

## 5. Known Conventions and Exceptions

- `qml/components/qmldir` and similar `qmldir` files must be updated when shared components are added or moved.
- Relative imports in QML are sensitive to file moves, especially imports from `models/`.
- Some assets may exist in both `assets/` and `qml/images/` for different purposes:
  - `assets/` as source/package artwork
  - `qml/images/` as runtime UI assets
- Top-level build and packaging files should not be moved casually because `CMakeLists.txt`, Clickable, and packaging metadata depend on them.

## 6. Recommended Rule of Thumb

Before creating a new file, ask:

1. Is this app-wide, feature-specific, or shared?
2. Is this runtime UI, shared model logic, backend code, documentation, or developer tooling?
3. Will another feature reuse this file soon?

If the answer is clear, the correct folder is usually clear as well.

When in doubt:

- prefer `qml/features/<feature>/...` for feature-owned code
- promote to `qml/components/...` only after reuse is real
- keep shared non-UI logic in `models/`
- keep backend/runtime Python in `src/`
