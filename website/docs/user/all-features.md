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

### Form Fields
*   **Required Fields:** Instance, Activity Type, Assignee, Summary (single line), Notes (multi-line), Due Date, Linked Entity (Project/Task/Contact).
*   **Default Values:** Date defaults to Today.

### Documentation References
*   **[Functional Guide](../user/overview.md)** | **[Technical Docs](../technical/activities.md)**

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

### Documentation References
*   **[Functional Guide](../user/overview.md)** | **[Technical Docs](../technical/projects.md)**

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

### Form Fields
*   **Required Fields:** Instance, Parent Project/Subproject/Parent Task, Period (Today/This Week/Next Week/This Month/Next Month), Date (auto-fill), Description (multi-line), Assignee, Hours (HH), Favorite Star.
*   **Mandatory Fields:** Task Name.
*   **Default Values:** Instance, Date range (This week), Time (1 hour or configurable from settings).
*   **Limits:** 24-hour limit for daily time registration (timesheets); estimate limits.

### Overview List Fields
*   Task Name, Stage, Instance, Project, Sub-project, Parent task, Deadline, Assignee, Favorite, Hours, Dates (start & end), Number of Subtasks, Details link.

### Documentation References
*   **[Functional Guide](../user/overview.md)** | **[Technical Docs](../technical/tasks.md)**

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

### Documentation References
*   **[Functional Guide](../user/overview.md)** | **[Technical Docs](../technical/timesheets.md)**

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

### Documentation References
*   **[Functional Guide](../user/overview.md)** | **[Technical Docs](../technical/dashboard.md)**

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

### Documentation References
*   **[Functional Guide](../user/setup-and-sync.md)** | **[Technical Docs](../technical/sync-settings.md)**

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

### Documentation References
*   **[Functional Guide](../user/install-and-run.md)** | **[Technical Docs](../technical/ui-ux-navigation.md)**

---

## 8. Notifications

Automated and smart push notifications for time and work management.

### Features
*   Push notifications for new activities, task assignments, project updates, and timesheet conflicts.
*   Smart Notifications: Tasks/Activities notifications delivered only during defined working hours.
*   Integration with Ubuntu Touch Notification Server for activities.

### Documentation References
*   **[Functional Guide](../user/overview.md)** | **[Technical Docs](../technical/notifications.md)**

---

## 9. Onboarding

First-launch interactive guidance for new users.

### Features
*   Onboard new users to introduce app features.
*   Skip button to bypass onboarding.
*   Progress indicator (dots or progress bar).
*   "Get Started" option.
*   Onboarding persistence (completed/skipped state).

### Documentation References
*   **[Functional Guide](../user/overview.md)** | **[Technical Docs](../technical/onboarding.md)**

---

## 10. Profiles

User profile and work/personal scope switching.

### Features
*   Switch between Work and Personal profiles.
*   Toggle or dropdown to switch modes.

### Documentation References
*   **[Functional Guide](../user/setup-and-sync.md)** | **[Technical Docs](../technical/profiles.md)**
