# Refactor Phase 1: Frozen Naming Map

Status: Frozen for migration start

This mapping is fixed before large moves begin.

## QML Page Rename Map

| Legacy path | New page name | Target path |
| --- | --- | --- |
| qml/Task_Page.qml | TaskListPage.qml | qml/features/tasks/pages/TaskListPage.qml |
| qml/Tasks.qml | TaskEditorPage.qml | qml/features/tasks/pages/TaskEditorPage.qml |
| qml/MyTasks.qml | MyTasksPage.qml | qml/features/tasks/pages/MyTasksPage.qml |
| qml/Timesheet_Page.qml | TimesheetListPage.qml | qml/features/timesheets/pages/TimesheetListPage.qml |
| qml/Timesheet.qml | TimesheetEditorPage.qml | qml/features/timesheets/pages/TimesheetEditorPage.qml |
| qml/Project_Page.qml | ProjectListPage.qml | qml/features/projects/pages/ProjectListPage.qml |
| qml/Projects.qml | ProjectEditorPage.qml | qml/features/projects/pages/ProjectEditorPage.qml |
| qml/Activity_Page.qml | ActivityListPage.qml | qml/features/activities/pages/ActivityListPage.qml |
| qml/Activities.qml | ActivityEditorPage.qml | qml/features/activities/pages/ActivityEditorPage.qml |
| qml/Updates_Page.qml | UpdateListPage.qml | qml/features/updates/pages/UpdateListPage.qml |
| qml/Updates.qml | UpdateEditorPage.qml | qml/features/updates/pages/UpdateEditorPage.qml |
| qml/Aboutus.qml | AboutPage.qml | qml/app/pages/AboutPage.qml |
| qml/Splash.qml | SplashPage.qml | qml/app/pages/SplashPage.qml |
| qml/Menu.qml | MenuPage.qml | qml/app/navigation/MenuPage.qml |
| qml/Dashboard.qml | DashboardPage.qml | qml/features/dashboard/pages/DashboardPage.qml |
| qml/Dashboard2.qml | Dashboard2.qml | qml/features/dashboard/pages/Dashboard2.qml |

## Legacy Dashboard Quarantine Plan

- qml/Dashboard3.qml -> qml/legacy/dashboard/Dashboard3.qml
- qml/Charts1.qml -> qml/legacy/dashboard/Charts1.qml
- qml/Charts2.qml -> qml/legacy/dashboard/Charts2.qml

Keep with active dashboard flow until usage is refactored:

- qml/Charts3.qml
- qml/Charts4.qml

## Compatibility Wrapper Rule

For each moved page above:

- Keep the original legacy file path.
- Convert it into a thin wrapper that forwards to the target path.
- Do not add new logic inside wrapper files.

## Change Control Rule

- Do not modify this map within the same chunk that performs broad moves.
- If a rename must change, update this map in a separate guardrail patch first.
