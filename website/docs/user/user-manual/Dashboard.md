# Dashboard

## Introduction
The **Dashboard** is the main screen of the Time Management App. It provides a quick overview of tasks, projects, and time distribution based on priority.

This screen enables users to:
* Identify tasks requiring immediate attention.
* Organize work efficiently.
* Monitor time spent across activities and projects.

---

## Dashboard Overview
The Dashboard consists of the following key sections:
1. Header (Top Bar)
2. Unsaved Drafts Alert (New)
3. Priority Matrix
4. Navigation Tabs (Overview, Projects, Tasks) (New)
5. Quick Action Button

---

## Header Section
Located at the top of the screen.

### Features:
* **Menu Icon (☰):** Opens the side navigation menu.
* **Account Name:** Displays the active user account.
* **Add Icon (Clock with +):** Used to quickly create a new timesheet entry.
* **Notification Icon (🔔):** Displays alerts and updates.
* **Info Icon (ⓘ):** Provides additional information or warnings.

---

## Unsaved Drafts Alert
Upon launching the app, if there is unsubmitted work, an **Unsaved Drafts Found** popup may appear.
* Notifies the user of unsubmitted work from a previous session (e.g., Timesheets, Project Updates).
* Prompts the user to open the respective forms to restore their changes.

---

## Priority Matrix
The Priority Matrix categorizes tasks based on urgency and importance. It is organized visually with **URGENT** and **NOT URGENT** on the top axis, and **IMPORTANT** and **NOT IMPORTANT** on the side axis.

### Categories:
* **Do First (Urgent & Important):** Tasks that require immediate attention (Red tile).
* **Do Next (Not Urgent & Important):** Important tasks that can be scheduled (Blue tile).
* **Do Later (Urgent & Not Important):** Tasks that can be postponed or delegated (Green tile).
* **Don’t Do (Not Urgent & Not Important):** Tasks that are unnecessary (Grey tile).

### Time Display:
Each category displays total time spent (e.g., `0H`), helping users evaluate productivity and time allocation.

---

## Navigation Tabs
Below the Priority Matrix, the dashboard is divided into three primary tabs: **Overview**, **Projects**, and **Tasks**.

### 1. Overview Tab
Displays visual charts for time tracking.
* **Most Time-Consuming Projects (Donut Chart):** Visual representation of time distribution across projects. Larger segments indicate higher time usage.
* **Project-wise Time Spent (Bar Chart):** Displays time spent per project. The axes allow visual comparison of effort across projects. Includes a **"Show next 10 ↓"** button at the bottom to load more data.

### 2. Projects Tab
Displays detailed information about user projects, along with a master total of hours logged across all projects.

* **Search Bar:** Enables quick project lookup ("Search projects…").
* **Sorting Options:**
    * **Most Time:** Sort by highest time spent.
    * **Tasks:** Sort by number of tasks.
    * **A–Z:** Alphabetical sorting.
* **Project List:** Displays individual projects with their specific task counts, total time spent, and a visual progress indicator.

**Project Details View:**
Tapping on a specific project in the list navigates to a detailed view for that project, which includes:
* A summary header displaying the `TOTAL` time, `AVERAGE` time, total `TASKS`, and the `TOP TASK`.
* A specific bar chart breaking down time spent by individual tasks within that project.
* A list of individual tasks showing their percentage of project time, total hours, and a navigation arrow for further details.
* A **"Show all X tasks ↓"** button at the bottom to expand the list.

### 3. Tasks Tab
A dedicated tab for managing and viewing individual tasks.

---

## Quick Action Button
A floating action button (cyan circle with a menu icon) located at the bottom-right corner of the screen.

### Functions:
* Add a new task.
* Create a timesheet entry.
* Log activity.