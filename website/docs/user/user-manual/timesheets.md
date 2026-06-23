# Timesheet

The **Timesheet** module is used to record, manage, and monitor the time spent on projects, tasks, and daily work activities within the Time Management App.

This module helps users:
* Track daily working hours.
* Record effort spent on tasks and projects.
* Maintain accurate work logs to improve productivity tracking.
* Support reporting and billing processes.
* Monitor time utilization across teams and projects.

---

## Accessing the Timesheet Module
To open the **Timesheet** section:
1. Click the **Menu (☰)** icon from the top-left corner.
2. Select **Timesheet** from the sidebar navigation.

---

## Timesheet Screen Overview
The screen is divided into the following sections:
1. Header Section (Add Icon, Back Navigation, Search Icon).
2. Timesheet Filter Tabs.
3. Timesheet Overview Panel.
4. Timesheet Details Panel.
5. Swipe Actions.
6. Floating Action Button (FAB).

### Timesheet Filter Tabs
* **All**: Displays all timesheet entries.
* **Active**: Displays currently active or ongoing timesheets.
* **Draft**: Displays saved draft timesheets awaiting completion.

### Timesheet Overview Panel
Displays records in a list format, summarizing: Timesheet Title, Project Name, Task Info, Logged Hours, Entry Date, Assigned User, and Priority.

---

## Creating a New Timesheet Entry
Click the **➕ Add Icon** or tap the **Floating Action Button (FAB)** and select **Create**. Fill in the information and click the **✔ Save Button**.

### Timesheet Creation Fields
* **Account, Project, Subproject, Task, Subtask**: Link the entry to specific organizational and work items to support accurate reporting.
* **Priority**: Importance level (Important/Urgent (1), Important/Not Urgent (2), Urgent/Not Important (3), Not Urgent/Not Important (4)).
* **Time Tracking Mode**:
    * **Manual**: Users manually enter working hours.
    * **Automated**: The system timer automatically tracks time.
* **Timer**: Features Start, Pause, and Stop buttons. Updates automatically while running and adds duration to the entry.
* **Date**: Working date for chronological tracking.
* **Description**: Detailed info about work completed, updates, resolved issues, and meetings attended.

---

## Viewing and Editing Timesheets
Select a timesheet from the overview list to display complete information in the Details Panel. To edit, open the entry in edit mode, update fields, and click Save.

---

## Timesheet Status Management
* **Active**: Currently ongoing or recently updated.
* **Draft**: Saved temporarily before final submission.
* **Completed**: Finished and finalized entries ready for synchronization.

---

## Automated Timer Save as Draft Process
When using **Automated** tracking, clicking the **Stop Button** automatically opens the **Add Description to Timesheet** dialog box.

**Dialog Box Actions:**
* Displays total tracked time and allows users to enter work details.
* **Save as Draft Button**: Saves the tracked duration and description in **Draft** status. It is not finalized, but becomes visible under the Draft tab for future editing.
* **Cancel Button**: Closes the dialog without saving and discards the timer data.

### Completing a Draft Timesheet
Draft entries can be finalized directly from the overview screen:
1. Open the **Draft** tab.
2. Swipe the required entry toward the left.
3. Tap the **✔ Mark as Done** icon.

A success message appears: *"Timesheet is now ready to be synced to Odoo."* The entry moves from the Draft tab to the All tab, changes to **Completed** status, and becomes available for Odoo synchronization.

---

## Timesheet Swipe Actions

**Right Swipe Action (Delete):**
* Reveals the **Delete** option to quickly remove unwanted or incorrect entries.

**Left Swipe Actions (Quick Controls):**
* **Edit**: Opens the timesheet in edit mode.
* **Start Timer**: Begins automated time tracking directly from the list; the entry may appear under the Active tab while running.
* **Mark as Done**: Finalizes a draft timesheet for synchronization.