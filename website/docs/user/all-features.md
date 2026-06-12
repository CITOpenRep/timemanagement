---
title: Feature Catalog
sidebar_label: All Features
---

# Feature Catalog

This page provides a comprehensive catalog of all features in the TimeManagement application. Use the links under each module to navigate to their respective functional guides or technical implementation details.

---

## 1. Activities Module

The Activities module helps users schedule, manage, and track follow-up tasks and actions.

### Features
*   Search activities.
*   Sort activities by latest updated (descending).
*   Mark activities or tasks as Completed.
*   Display Days Remaining (shows "Overdue" status if past due).
*   "Read More" truncation for long Notes.
*   Tabs to filter by Open / Closed / All.
*   Add a remark before completing an activity [Upcoming].
*   Attach files/documents to Activities [Upcoming].
*   Create follow-up activities directly from the same screen.
*   Shortcut to create an activity directly from a Project or Task detail page.
*   Swipe left to enter Edit mode.
*   Swipe left to Cancel/Delete an activity.
*   Cancel confirmation prompt before deletion [Upcoming].
*   **Tabbed View Filters:** Quickly filter activities by schedule/state: **Today**, **This Week**, **This Month**, **Later**, **Overdue**, **All**, and **Done**.
*   **Reschedule Activity:** Easily modify due dates through swipe actions or the detailed view date picker.

### Form Fields
*   **Required Fields:** Instance, Activity Type, Assignee, Summary (single line), Notes (multi-line), Due Date, Linked Entity (Project/Task/Contact).
*   **Default Values:** Date defaults to Today.

### Technical Architecture Map (For Contributors)

| Layer | Path / Files | Implementation Details |
| :--- | :--- | :--- |
| **Frontend UI** | `qml/features/activities/pages/Activity_Page.qml`<br/>`qml/components/cards/ActivityDetailsCard.qml` | Renders list views, handles tab clicks (Today/Week/Month/etc.), triggers date pickers, and binds swipe interactions. |
| **Logic & State** | `models/activity.js` | JavaScript backend model containing `getFilteredActivities()`, `updateActivityDate()`, `markAsDone()`, and `createFollowupActivity()`. |
| **Database Schema** | SQLite table: `mail_activity_app` | Stores activity properties: `summary`, `due_date`, `notes`, `state` (planned/done), `user_id`, and `resModel`/`resId` (linkage to tasks or projects). |
| **Backend & Sync** | `src/daemon.py` | Syncs local activity states bidirectionally with Odoo's `mail.activity` via XML-RPC. |

:::tip Functional Guide
Learn how to use activities in the [Activities User Manual](../functional/user-manual/activities.md).
:::

:::info Technical Reference
For schema definitions and sync sequence flows, see the [Activities Module Technical Reference](../technical/activities.md).
:::

---

## 2. Projects Module

The Projects module organizes high-level work items and links them to instances.

### Features
*   View sub-projects with collapsible/next pane view.
*   Search action with enhanced search (includes sub-projects).
*   Sort projects by latest updated.
*   Swipe right to add to Favorites.
*   Filter projects based on their respective Stages in Odoo (Kanban mapping).
*   Filter project list to exclude the "Done" stage.
*   View all project updates in one place (sorted by date).
*   Link from the project screen to a filtered list of updates related to that specific project.
*   Role-based access controls for project creation.
*   Display hours spent on projects.
*   Project progress indicator bar.
*   Show only relevant underlying projects based on the user's current context.
*   Quick "+ button" for new entry.
*   Create a task directly from the project detailed view.
*   Create Task button for quicker task creation.
*   Logical arrangement of current options (View Tasks, Create Activity).

### Form Fields
*   **Required Fields:** Instance, Parent Project, From/To Date, Description (Rich text), User entered by, Allocated Hours, Color selector, Favorite Star.
*   **Mandatory Fields:** Assignee.
*   **Default Values:** Instance (based on settings), Date range (This week).

### Overview Page Fields
*   Favorite indicator, Instance, Start & End Dates, Number of Sub-projects, View details link, Remaining days and proximity to deadlines.
*   Project progress bar.

### Technical Architecture Map (For Contributors)

| Layer | Path / Files | Implementation Details |
| :--- | :--- | :--- |
| **Frontend UI** | `qml/features/projects/` | Projects directory pages, sub-project panels, progress bars, and detail cards. |
| **Logic & State** | `models/project.js` | Exposes SQLite queries for listing, detail loading, and favorite toggles. |
| **Database Schema** | SQLite table: `project_project_app` | Stores project metadata, parent-child project relationships, and color palette indicators. |
| **Backend & Sync** | `src/sync_to_odoo.py` | Pulls remote projects and publishes locally created project entries. |

:::tip Functional Guide
For details on updates and lists, read the [Projects User Manual](../functional/user-manual/projects.md) and the [Project Updates Guide](../functional/user-manual/project-updates.md).
:::

:::info Technical Reference
Understand the query mappings in the [Projects Module Technical Reference](../technical/projects.md).
:::

---

## 3. Tasks Module

The Tasks module manages task execution, tracking, and parent-child hierarchies.

### Features
*   View sub-tasks with expand/collapse hierarchy.
*   Search button.
*   Sort by latest updated.
*   Tabs to organize by time frame: Today / Week / Month / Later.
*   Filter by Open tasks (default), and filter by Assignee.
*   Swipe to Favorite, Swipe to Delete, Swipe to View/Edit.
*   Context menu for quick task creation.
*   Smart play button to start timer for the task.
*   Progress tracking bar.
*   Show Days Remaining and calculated proximity to deadlines.
*   Task color inherited from the parent project.
*   Description "Read More" button.
*   Multiple assignees for tasks.
*   View "My Tasks" via personal stages.
*   Task stage management based on state (In-progress or completed) – UI & Backend.
*   Display only relevant subtasks to reduce clutter.
*   Delete confirmation prompt.
*   Reschedule button for tasks and activities.
*   **Tabbed Date Filters:** Segment task lists using tabs: **Today**, **Week**, **Month**, and **Later**.
*   **Reschedule Task:** A quick reschedule button updates task deadline ranges in the database.
*   **Two-Fold Stage System:**
    *   *Global Kanban Stages:* Standard workflow stages (e.g. To Do, In Progress, Done) synced with Odoo's global project configuration.
    *   *Personal Stages ("My Tasks"):* Custom, user-specific stages to organize personal work progress independently.
*   **Priority Stars:** High-priority tasks display visual star badges (0 to 3 levels) mapped to the Odoo priority schema.

### Form Fields
*   **Required Fields:** Instance, Parent Project/Subproject/Parent Task, Period (Today/This Week/Next Week/This Month/Next Month), Date (auto-fill), Description (multi-line), Assignee, Hours (HH), Favorite Star.
*   **Mandatory Fields:** Task Name.
*   **Default Values:** Instance, Date range (This week), Time (1 hour or configurable from settings).
*   **Limits:** 24-hour limit for daily time registration (timesheets); estimate limits.

### Overview List Fields
*   Task Name, Stage, Instance, Project, Sub-project, Parent task, Deadline, Assignee, Favorite, Hours, Dates (start & end), Number of Subtasks, Details link.

### Technical Architecture Map (For Contributors)

| Layer | Path / Files | Implementation Details |
| :--- | :--- | :--- |
| **Frontend UI** | `qml/features/tasks/pages/Tasks.qml`<br/>`qml/features/tasks/pages/MyTasksPage.qml`<br/>`qml/features/tasks/components/TaskDetailsCard.qml`<br/>`qml/features/tasks/components/TaskDateRangeDialog.qml` | Manages list layouts, swipe menus, personal stage popup triggers, and date rescheduling selectors. |
| **Logic & State** | `models/task.js` | Implements database CRUD functions including `saveOrUpdateTask()`, `updateTaskPersonalStage()`, and `setTaskPriority()`. Handles multiple assignee arrays. |
| **Database Schema** | SQLite tables: `project_task_app`<br/>`project_task_type_app` | `project_task_app` tracks fields like `stage_id` and `personal_stage`. `project_task_type_app` stores global stages and personal stages (where `is_global = '[]'`). |
| **Backend & Sync** | `src/sync_to_odoo.py` / `src/backend.py` | Daemon handlers for pushing task deadlines and D-Bus interfaces for task mutations. |

:::tip Functional Guide
Explore detailed task manuals in the [All Tasks Guide](../functional/user-manual/all-tasks.md) and [My Tasks Guide](../functional/user-manual/my-tasks.md).
:::

:::info Technical Reference
See sequence diagrams and DBUS interfaces in the [Tasks Module Technical Reference](../technical/tasks.md).
:::

---

## 4. Timesheets Module

The Timesheets module handles work hour registration, automated timers, and logging.

### Tracking & Logging
*   Swipe up from the home screen to create a Timesheet.
*   Add via "+" button on the timesheet list.
*   Smart play button to start timer (available in task list, project list, and form views).
*   Timer continues running in the background.
*   Only one timer can be active at a time.
*   Time Spent entry (manual or auto via timer).
*   Time format: 00:00 HH:MM.
*   Pop-up to add description/notes immediately after recording time.
*   Search option for timesheets.
*   Optional default project selection.
*   **Eisenhower Priority Matrix:** Classify timesheet tasks to support urgent vs. important sorting on dashboard quadrants.
*   **Decimal Formats:** Time spent is saved in standard decimal format (e.g. 1.5 equals 1 hour 30 minutes).

### Form Fields
*   **Required Fields:** Instance (Odoo or Local), Project, Subproject, Task, Sub Tasks, Date, Description (multi-line), Priority (Eisenhower Matrix).
*   **Mandatory Fields:** Project.
*   **Default Values:** Date (Today), User, Time.
*   **Edit Fields:** User (entered by), Eisenhower Priority, Project Color.

### Overview Fields
*   Description, Date, Hours Spent, User, Project, Task, Instance, Eisenhower Priority.

### Gestures
*   Leading swipe (left to right) for Delete.
*   Trailing swipe for Edit / Delete.
*   Delete confirmation prompt.

### Technical Architecture Map (For Contributors)

| Layer | Path / Files | Implementation Details |
| :--- | :--- | :--- |
| **Frontend UI** | `qml/features/timesheets/` | Logs, timesheet input forms, and overlay timers. |
| **Logic & State** | `models/timesheet.js`<br/>`models/timer_service.js` | Coordinates active timers, local storage timer persistence, and stopwatch actions. |
| **Database Schema** | SQLite table: `account_analytic_line_app` | Stores logged duration `unit_amount`, date, linked task/project, description, and sync status. |
| **Backend & Sync** | `src/sync_to_odoo.py` | Sync worker identifying local timesheets marked as "dirty" to sync remotely via XML-RPC. |

:::tip Functional Guide
Read how to log timesheets in the [Timesheets User Manual](../functional/user-manual/timesheets.md).
:::

:::info Technical Reference
Review timer persistence rules in the [Timesheets Module Technical Reference](../technical/timesheets.md).
:::

---

## 5. Dashboard

The Dashboard provides visual analytics, charts, and priority management.

### Features
*   Eisenhower Matrix (with tooltip/info icon).
*   Project-wise time spent chart (Top 10 projects).
*   Activity menu in the FAB (Floating Action Button).
*   Radio button for Eisenhower Priority selection.
*   Task-wise time spent chart (Top 10 tasks).
*   Filters: This Week (default), Month, Year.
*   Default filter: Show only My Timesheets, My tasks.
*   Export dashboard data to CSV.
*   Swipe left/right to switch/paging between charts.
*   Set default chart in settings/user profile.
*   Summary of activities and tasks completed based on user.

### Technical Architecture Map (For Contributors)

| Layer | Path / Files | Implementation Details |
| :--- | :--- | :--- |
| **Frontend UI** | `qml/features/dashboard/pages/Dashboard.qml` | Eisenhower grid, chart selectors, swipe container pagination. |
| **Logic & State** | `models/Main.js` | Performs LocalStorage SQLite query projections (e.g. Top 10 project SUM groupings and Urgency status counts). |

:::tip Functional Guide
For details on matrix items and chart reports, see the [Dashboard User Manual](../functional/user-manual/dashboard.md).
:::

:::info Technical Reference
Check metrics queries in the [Dashboard Module Technical Reference](../technical/dashboard.md).
:::

---

## 6. Sync & Account Settings

This module configures Odoo/Local accounts, manual/auto synchronization, and conflict resolution.

### Syncing
*   Sync on account creation.
*   Manual Sync button.
*   Integration with Multi-instance Odoo.
*   Syncing notification popup and scheduler.
*   Notify user if automatic sync fails.
*   Error logs.
*   Success/failed message once sync is initiated.
*   Status synchronization with instances, moving tasks to correct Kanban stages.
*   Conflict resolution based on timestamps with user prompts for manual resolution.
*   Integration with non-Odoo instances (e.g., Nextcloud).

### Account Management
*   Add/Delete accounts.
*   Allow only unique account names across instances.
*   Account creation interface transitions to View Mode after saving.
*   Set Default Project.
*   Set default Report/Dashboard view.

### Mandatory Fields
*   Name, URL, DB (Auto-fetched), Username, Password.

### Technical Architecture Map (For Contributors)

| Layer | Path / Files | Implementation Details |
| :--- | :--- | :--- |
| **Frontend UI** | `qml/features/settings/` | Account list editor, URL inputs, and synchronization status indicator bars. |
| **Logic & State** | `models/accounts.js`<br/>`models/dbinit.js` | Manages credentials, tokens, session checks, and database table creation. |
| **Backend & Sync** | `src/daemon.py`<br/>`src/backend.py` | Implements network sync routines, connection testing, and multi-threaded sync managers. |

:::tip Functional Guide
Read how to configure Odoo instances in the [Settings User Manual](../functional/user-manual/settings.md).
:::

:::info Technical Reference
Review the sync routines in the [Sync Settings Technical Reference](../technical/sync-settings.md).
:::

---

## 7. General UI/UX & Navigation

Layout guidelines, theme configuration, and content hub integrations.

### Navigation & Layout
*   UT Hamburger menu (styled like Dekko app with left pane separation).
*   Support swipe/touch gestures.
*   Full-screen on mobile.
*   Context menu or swipe actions for quick Timesheet/Task/Activity creation.
*   Transactional menu clearly separated from settings.
*   Click-through (drill-down) navigation (e.g., Projects → Tasks → Timesheets).
*   Faster, more intuitive drill-down navigation.
*   Convergence support (Responsive design for desktop mode/Multi-Pane support).
*   Slider from left edge to open navigation menu.
*   Menu divided into main activities and Admin Section.

### Design & Theming
*   Lomiri style icons.
*   Dark theme toggle inside the application.
*   Ubuntu OS multi-theme support.
*   Suru design philosophy implementation.
*   Upgrade from Lomiri to QQC2-Suru-Style.
*   Intuitive UI with standard UT gestures, readable fonts, and consistent grid layouts.
*   Implement new theme based on design consultant.

### Content Hub & Attachments
*   Attach files using Content Hub to make them available on the Odoo server.
*   On-demand download of attachments from server to device (UI & Backend).
*   Adding attachments from the app.
*   Enhanced attachment screen: List view, disabled download button if local, "Open with" integration.
*   Download CSVs from any list view.

### General App Features
*   Read More truncation for long descriptions across the app.
*   Expand button (+) to maximize description boxes.
*   Alerts when the app is closed.
*   Touch and keyboard/mouse inputs supported.
*   Overview tab: "Task For Today".
*   Favorites for Tasks and Projects (segregated in list view).
*   Filter entries based on Instance across Projects, Tasks, Timesheets, and Activities.
*   Language translation using Weblate.
*   Auto-save for entire form views.
*   Motivational Project Activation.
*   Create local account stages for Projects and Tasks.
*   App pinning to Homescreen.
*   Snap install support.

### Technical Architecture Map (For Contributors)

| Layer | Path / Files | Implementation Details |
| :--- | :--- | :--- |
| **Frontend UI** | `qml/TSApp.qml`<br/>`qml/app/` | Root app window layout, page routing, and theme switching context. |
| **Logic & Utilities** | `models/utils.js`<br/>`models/global.js` | Shared QML helpers (date formatting, color generation, navigation history). |

:::tip Functional Guide
For navigation guidelines, refer to the [Introduction Guide](../functional/user-manual/introduction.md) and the [Kebab Menu Navigation Guide](../functional/user-manual/kebab-menu.md).
:::

:::info Technical Reference
For details on layout convergence, check the [UI-UX Navigation Technical Reference](../technical/ui-ux-navigation.md).
:::

---

## 8. Notifications

Automated and smart push notifications for time and work management.

### Features
*   Push notifications for new activities, task assignments, project updates, and timesheet conflicts.
*   Smart Notifications: Tasks/Activities notifications delivered only during defined working hours.
*   Integration with Ubuntu Touch Notification Server for activities.

### Technical Architecture Map (For Contributors)

| Layer | Path / Files | Implementation Details |
| :--- | :--- | :--- |
| **Logic** | `models/notifications.js` | Orchestrates scheduler timers and trigger thresholds. |
| **Daemon** | `qml-notify-module/` | Native notifications interface bindings. |

:::info Technical Reference
See details in the [Notifications Technical Reference](../technical/notifications.md).
:::

---

## 9. Onboarding

First-launch interactive guidance for new users.

### Features
*   Onboard new users to introduce app features.
*   Skip button to bypass onboarding.
*   Progress indicator (dots or progress bar).
*   "Get Started" option.
*   Onboarding persistence (completed/skipped state).

### Technical Architecture Map (For Contributors)

| Layer | Path / Files | Implementation Details |
| :--- | :--- | :--- |
| **Frontend UI** | `qml/features/settings/Onboarding.qml` (or similar tutorial slides) | Renders onboarding screens and skip selectors. |

:::tip Functional Guide
Review first-launch instructions in the [Introduction Guide](../functional/user-manual/introduction.md).
:::

:::info Technical Reference
Check properties in the [Onboarding Technical Reference](../technical/onboarding.md).
:::

---

## 10. Profiles

User profile and work/personal scope switching.

### Features
*   Switch between Work and Personal profiles.
*   Toggle or dropdown to switch modes.
*   **Relational Account Isolation:** Multi-account database isolation prevents cross-profile data leakage.

### Technical Architecture Map (For Contributors)

| Layer | Path / Files | Implementation Details |
| :--- | :--- | :--- |
| **Frontend UI** | `qml/features/settings/Profiles.qml` | Renders user picker list and switches active context. |
| **Logic & State** | `models/accounts.js` | Session validation and active instance token switching. |
| **Database Schema** | SQLite relational mapping | Enforces `user_id = (SELECT value FROM app_settings WHERE key = 'active_user_id')` to filter Task and Timesheet replica tables. |

:::tip Functional Guide
Review profile configurations in the [Settings User Manual](../functional/user-manual/settings.md).
:::

:::info Technical Reference
For details on context isolation, read the [Profiles Technical Reference](../technical/profiles.md).
:::
