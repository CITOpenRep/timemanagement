# Refactor Phase 1: Architecture Contract

Status: Active

## Purpose

This document freezes the migration contract before large file moves begin. The contract is intentionally strict to keep refactor chunks mergeable, reviewable, and behavior-safe.

Core rule for all migration chunks:

- Move first.
- Keep behavior unchanged.
- Keep old entry paths as compatibility wrappers until explicit removal gates pass.

## Target Tree

### QML

- qml/TSApp.qml remains app entrypoint.
- qml/app/ remains shell/bootstrap only.
- qml/app/navigation/ stores route definitions, menu model, and navigation coordination.
- qml/features/<feature>/pages/ stores feature pages.
- qml/features/<feature>/components/ stores feature-owned components.
- qml/shared/components/ stores reusable cross-feature components.
- qml/shared/richtext/ stores shared rich-text stack.
- qml/legacy/ stores quarantined, non-primary artifacts.

### JS Models

- models/core/ contains shared low-level modules:
  - database.js
  - dbinit.js
  - utils.js
  - constants.js
  - global.js
- models/features/ contains feature model modules:
  - accounts.js
  - tasks.js
  - timesheets.js
  - projects.js
  - activities.js
  - notifications.js
  - draft_manager.js
- models/services/ contains service modules:
  - timer_service.js

### Python

- src/ubtms/ is the source-of-truth package.
- src/ubtms/core/ contains config/logging/shared helpers.
- src/ubtms/integrations/ contains Odoo client integration.
- src/ubtms/sync/ contains sync-in and sync-out flows.
- src/ubtms/backend/ contains pyotherside-facing backend API.
- src/ubtms/daemon/ contains daemon/runtime modules.

Compatibility wrappers remain at:

- src/backend.py
- src/daemon.py
- src/cli.py

## Naming Rules

- QML pages use PascalCase and Page suffix where applicable.
- Feature list/editor split uses ListPage and EditorPage.
- Feature directory names are lowercase plurals where practical:
  - tasks
  - timesheets
  - projects
  - activities
  - updates
- Shared components use intent-based names, not feature names.
- JS module files are lowercase and pluralized by domain in models/features.

Canonical rename mapping is frozen in:

- docs/refactor/phase-1-naming-map.md

## Wrapper Policy

### QML wrapper policy

Old top-level page paths remain importable during migration. Wrapper files must:

- Instantiate or forward to the new page path only.
- Contain no business logic.
- Contain no data-loading logic.
- Keep existing external properties/signals expected by callers.

### JS wrapper policy

Legacy flat model paths remain importable during migration. Wrapper files must:

- Preserve existing exported function names.
- Forward to new module locations.
- Avoid behavior changes.

### Python wrapper policy

Entry modules remain importable during migration:

- backend
- daemon
- cli

They must re-export from package modules and preserve current call surface used by QML bridge and scripts.

## Routing Contract

- Route and menu definitions must live in qml/app/navigation/.
- App shell may consume route definitions but should not hardcode route registry data.
- During transition, existing pageNum compatibility stays intact.
- Deep-link routing and menu routing must share the same route mapping source.

## Import Contract During Migration

- No new feature code should import from deprecated flat roots once a layered path exists.
- Old imports may stay only in wrappers or untouched legacy code until feature chunk migration.
- New moves must be path-stable: update internal imports in same chunk.

## Chunk Acceptance Gates

Each migration chunk is mergeable only if all are true:

1. App starts successfully.
2. Smoke checklist in docs/refactor/phase-1-smoke-checklist.md passes.
3. Legacy wrappers for moved files are thin wrappers only.
4. No unexpected route regressions in drawer/deep-link navigation.
5. No new imports introduced to deprecated module paths for already-migrated layers.

## Wrapper Removal Gates

A wrapper family can be removed only when all are true:

1. Grep shows zero references to old paths.
2. Smoke checklist passes after removal.
3. One additional follow-up check confirms no runtime route/import fallback is used.

## Non-Goals for Phase 1

- No broad runtime refactors.
- No behavior changes to business logic.
- No pyotherside module rename.
- No asset churn.
