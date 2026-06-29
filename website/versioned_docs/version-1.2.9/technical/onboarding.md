---
title: Onboarding Technical Reference
sidebar_label: Onboarding
---

# Onboarding Technical Reference

This page describes the onboarding flow sequence presented during the first execution of the application, including persistence state flags and quick skip triggers.

## Codebase Map

| Layer | Path | Purpose |
|---|---|---|
| **Flow Coordinator** | `qml/TSApp.qml` | Detects onboarding status and renders overlay |
| **Onboarding UI** | `qml/features/settings/Onboarding.qml` | Carousel slider, guides, and initial config form |
| **State Storage** | `models/database.js` | Database initialization setting verification |

## Onboarding Execution Flow

```mermaid
graph TD
    A[Launch Application] --> B{Query app_settings: first_launch_done?}
    B -->|0 / NULL| C[Render Onboarding.qml Overlay]
    B -->|1| D[Directly Load Dashboard.qml]
    C -->|Skip / Finish| E[Update app_settings SET first_launch_done = 1]
    E --> D
```

## Settings Schema Flag

The onboarding state persists in `app_settings`:

```sql
SELECT value FROM app_settings WHERE key = 'first_launch_done';
```

* If `value` is not `1`, the application locks general navigation and redirects the active viewport to the onboarding carousel.
* Completing the onboarding screens automatically updates this key to `1` so subsequent launches bypass the sequence.
* Users can manually reset this setting via the System Settings page to re-trigger onboarding.
