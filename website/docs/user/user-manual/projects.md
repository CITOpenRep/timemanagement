# Projects

The **Projects** module is used to create, organize, monitor, and manage all project-related activities within the Time Management App.

Projects help users:
* Group related tasks and activities.
* Track project timelines and allocated effort.
* Monitor progress and status.
* Manage assignments and ownership.
* Organize work efficiently across teams or departments.

The Projects section acts as a centralized workspace for all ongoing and completed projects.

---

## Accessing the Projects Module
To open the **Projects** section:
1. Click the **Menu (☰)** icon from the top-left corner.
2. Select **Projects** from the sidebar navigation.

---

## Projects Screen Overview
The Projects screen contains the following components:
1. Header Section
2. Projects List
3. Project Information Panel
4. Search and Filter Options
5. Quick Action Buttons

---

### Header Section
Located at the top of the Projects screen.

**Features:**
* **Search Icon**: Used to search projects quickly.
* **Grid/List View Icon**: Switch between available project display layouts.
* **Add Icon**: Create a new project.
* **Save Icon**: Save newly created or edited project details.

---

### Projects List Panel
The left-side panel displays all available projects.

Each project item provides a quick summary including: Project Name, Instance Name, Current Status, Planned Hours, Start Date, End Date, and Overdue Indicator (if applicable).

**Example Statuses:** To Do, In Progress, Completed, On Hold.

**Additional Indicators:**
* **Star Icon**: Marks favorite or important projects.
* **Overdue Label**: Highlights projects that exceeded their planned completion date.

---

### Project Information Panel
Clicking on any project from the project overview list will display detailed information about the selected project.

---

## Creating a New Project
To create a project:
1. Open the **Projects** module.
2. Click the **➕ Add Icon**.
3. Fill in the required project information.
4. Click the **✔ Save Button**.

The project will then appear in the Projects List.

### Project Creation Fields
* **Account**: Defines which connected account or environment the project belongs to, ensuring data is stored in the correct server. Displays the currently active account and can be changed via dropdown.
* **Parent Project**: Used to create sub-projects under a larger project to improve hierarchy and structure (e.g., Website Migration -> UI Design).
* **Assignee**: Defines the user responsible for the project, clarifying ownership.
* **Project Name**: The primary title of the project (e.g., Mobile App Development, Website Redesign).
* **Description**: Detailed information including objectives, scope of work, and expected outcomes.
* **Allocated Hours**: Estimated time planned for the project (e.g., `01:00` = 1 Hour) to help with workload planning.
* **Color Indicator**: Allows assigning a color to make projects easier to identify.

### Planned Dates Section
Defines the expected project timeline.
* **Date Range**: Provides quick date selection presets (Today, This Week, This Month, Custom Range).
* **Start Date**: Defines when the project is expected to begin.
* **End Date**: Defines the planned completion date. *Note: If the current date exceeds the End Date and the project is incomplete, the system may display an **Overdue** indicator.*

### Attachments Section
Allows users to upload and manage project-related files.

**How to Upload:** Click the **Upload Icon**, select a file, and wait for completion.
**Benefits:** Keeps files centralized, improves collaboration, and syncs automatically with the server and vice versa.

---

## Viewing and Editing Project Details
Selecting a project from the Projects List displays its details in the right-side panel. Users can review project status, timeline, allocated hours, description, assigned user, and attachments.

To edit an existing project:
1. Select the project from the list.
2. Click on the edit icon from the top right.
3. Update the required fields.
4. Click the **✔ Save Button**.

---

## Project Status Management
Projects move through different statuses during their lifecycle.

| Status | Description |
| --- | --- |
| To Do | Project has not started |
| In Progress | Work is currently ongoing |
| Completed | Project work is finished |
| On Hold | Temporarily paused |

---

## Searching and Favoriting Projects
* **Searching**: Click the **Search Icon** and enter the Project Name. Matching projects are displayed instantly.
* **Favorites**: Projects can be marked as favorites using the **Star Icon** for faster access and easier navigation.

---

## Project Overview Swipe Actions
From the Projects List overview, swipe any project item to the **left** to reveal three action icons:
1. **View**: Opens the detailed page of the selected project.
2. **Start**: Starts the project timer, records time automatically, and creates a timesheet entry.
3. **Pause**: Stops the active timer and pauses time tracking.

---

## Filter Projects by Stage
The **Filter by Stage** feature allows users to quickly view projects based on their current status.

**Accessing the Filter:**
1. Navigate to the **Projects** module.
2. Click the **Floating Action Button (FAB)** at the bottom-right corner.
3. A filter panel titled **“Filter by Stage”** will appear displaying available options (Open Projects, All Stages, To Do, In Progress, Done, Cancelled).

**How it Works:**
When a stage is selected, the Projects List refreshes automatically to display only matching projects (e.g., selecting **In Progress** will display only projects currently under active development). By default, all stages will be displayed when opening a project list overview. Users can change or clear the filter by opening the panel again and selecting **All Stages**.