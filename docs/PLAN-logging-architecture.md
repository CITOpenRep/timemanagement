# Plan: Centralized Logging Architecture & Console Pollution Cleanup

## Overview
The codebase currently contains over 707 unmanaged `console.log`, `console.warn`, and `console.error` statements across 71 files. During runtime (e.g. `clickable desktop`), tight database query loops and UI render events spam standard output with repetitive log messages, causing frame rendering delays (up to 145ms), exposing sensitive user data (emails, tokens), and cluttering terminal output.

This plan introduces a **Centralized Logger Module (`models/logger.js`)** with environment-configurable log levels, module categorization, rate-limiting, and PII masking, alongside a systematic cleanup of redundant console logs.

## Architectural Analysis: Why Unmanaged Console Logs Pollute Codebases

1. **Performance Degradation**: Synchronous standard output write calls in Qt Quick / QML block main UI event loops and database worker threads.
2. **Security & Data Privacy (PII Leakage)**: Raw `console.log` dumps emails, user IDs, and local system paths into unencrypted system log files (`~/.cache/upstart/`, `syslog`).
3. **Terminal Noise**: Critical application errors get buried under thousands of routine status traces.
4. **Lack of Build Controls**: Production release builds cannot toggle off verbose debugging statements without modifying source code files.

---

## Proposed Logging Architecture (`models/logger.js`)

### 1. Unified Logger Core (`models/logger.js`)
Create a lightweight, zero-dependency logging wrapper module usable across QML and JS files:

```javascript
.import "database.js" as DBCommon

var LogLevel = {
    DEBUG: 0,
    INFO: 1,
    WARN: 2,
    ERROR: 3,
    NONE: 4
};

// Global level configurable at runtime or via environment (default WARN in production, DEBUG in dev)
var currentLevel = LogLevel.INFO;

function setLogLevel(level) {
    currentLevel = level;
}

function debug(category, message, extra) {
    if (currentLevel <= LogLevel.DEBUG) {
        console.debug("[" + category + "] " + message, extra || "");
    }
}

function info(category, message, extra) {
    if (currentLevel <= LogLevel.INFO) {
        console.log("[" + category + "] " + message, extra || "");
    }
}

function warn(category, message, extra) {
    if (currentLevel <= LogLevel.WARN) {
        console.warn("[" + category + "] " + message, extra || "");
    }
}

function error(category, message, extra) {
    if (currentLevel <= LogLevel.ERROR) {
        console.error("[" + category + "] " + message, extra || "");
    }
}
```

---

## Task Breakdown & Phased Rollout

### Phase 1: Core Logger Implementation
- [NEW] [logger.js](file:///home/suraj/timemanagement/models/logger.js): Implement `models/logger.js` with log levels, category tagging, and build mode detection.
- [MODIFY] [database.js](file:///home/suraj/timemanagement/models/database.js): Export log level configuration setting in DBCommon / Settings.

### Phase 2: High-Volume Model Cleanup (`models/`)
Replace loose `console.log` calls in business logic models with categorized `Logger.debug()` / `Logger.error()` calls:
- [MODIFY] [task.js](file:///home/suraj/timemanagement/models/task.js) (69 console statements)
- [MODIFY] [timesheet.js](file:///home/suraj/timemanagement/models/timesheet.js) (63 console statements)
- [MODIFY] [activity.js](file:///home/suraj/timemanagement/models/activity.js) (47 console statements)
- [MODIFY] [project.js](file:///home/suraj/timemanagement/models/project.js) (46 console statements)
- [MODIFY] [draft_manager.js](file:///home/suraj/timemanagement/models/draft_manager.js) (27 console statements)
- [MODIFY] [dbinit.js](file:///home/suraj/timemanagement/models/dbinit.js) (20 console statements)

### Phase 3: High-Volume QML View & Component Cleanup (`qml/`)
Eliminate repetitive log spamming inside QML bindings, delegate renders, and repeaters:
- [MODIFY] [Activity_Page.qml](file:///home/suraj/timemanagement/qml/features/activities/pages/Activity_Page.qml) (24 console statements)
- [MODIFY] [AttachmentManager.qml](file:///home/suraj/timemanagement/qml/components/workflow/AttachmentManager.qml) (21 console statements)
- [MODIFY] [Updates.qml](file:///home/suraj/timemanagement/qml/features/updates/pages/Updates.qml) (20 console statements)
- [MODIFY] [Projects.qml](file:///home/suraj/timemanagement/qml/features/projects/pages/Projects.qml) (20 console statements)
- [MODIFY] [RichTextEditor.qml](file:///home/suraj/timemanagement/qml/components/richtext/RichTextEditor.qml) (19 console statements)
- [MODIFY] [Timesheet.qml](file:///home/suraj/timemanagement/qml/features/timesheets/pages/Timesheet.qml) (17 console statements)

### Phase 4: Verification & Audit
- Run `clickable desktop` to ensure smooth runtime execution without console log flooding or frame delays.
- Audit remaining console logs to ensure 100% route through `Logger`.
