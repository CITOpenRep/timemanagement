---
title: Functional Documentation
sidebar_label: User Manual
---

# UT Time Management App Documentation

# Time Management App – Functional Documentation (v1.2.7)

# 1. Dashboard

## 1.1 Introduction

The **Dashboard** is the main screen of the Time Management App. It provides a quick overview of tasks, projects, and time distribution based on priority.

This screen enables users to:

- Identify tasks requiring immediate attention
- Organize work efficiently
- Monitor time spent across activities and projects

---

## 1.2 Dashboard Overview

The Dashboard consists of the following sections:

1. Header (Top Bar)
2. Priority Matrix
3. Charts
4. Projects Section
5. Quick Action Button

---

## 1.2.1 Header Section

Located at the top of the screen.

### Features:

- **Account Name**: Displays the active user account
- **Menu Icon (☰)**: Opens the side navigation menu
- **Notification Icon (🔔)**: Displays alerts and updates
- **Add Icon (➕)**: Used to create a new timesheet entry
- **Kebab Menu Icon (⋮)**: Opens the overflow menu with additional navigation options

---

## 1.2.2 Priority Matrix

The Priority Matrix categorizes tasks based on **urgency** and **importance**.

### Categories:

**Do First (Urgent & Important)**

- Tasks that require immediate attention

**Do Next (Not Urgent & Important)**

- Important tasks that can be scheduled

**Do Later (Urgent & Not Important)**

- Tasks that can be postponed or delegated

**Don’t Do (Not Urgent & Not Important)**

- Tasks that are unnecessary

### Time Display:

Each category displays total time spent (e.g., `0H`), helping users evaluate productivity and time allocation.

---

## 1.2.3 Charts

**Most Time-Consuming Projects (Donut Chart)**

- Visual representation of time distribution across projects
- Larger segments indicate higher time usage

**Project-wise Time Spent (Bar Chart)**

- Displays time spent per project
- X-axis: Project names
- Y-axis: Time (in hours)
- Bars allow visual comparison of effort across projects

---

## 1.2.4 Projects Section

Displays detailed information about user projects.

### Features:

- **Total Time Spent** (e.g., `0.0 h`)
- **Progress Indicator**: Visual bar showing time utilization
- **Search Bar ("Search projects…")**: Enables quick project lookup

### Sorting and Filtering Options:

- **Most Time**: Sort by highest time spent
- **Tasks**: Sort by number of tasks
- **A–Z**: Alphabetical sorting

---

## 1.2.5 Quick Action Button

A floating action button located at the bottom-right corner.

### Functions:

- Add a new task
- Create a timesheet entry
- Log activity

---

## 2. Kebab Menu (Overflow Menu)

The Kebab Menu (⋮) is located in the **top-right corner of the Header Section** and provides quick access to key navigation items.

### Purpose:

- Offers an alternative navigation method to the sidebar
- Improves usability on smaller screens and compact layouts
- Enables quick access without opening the full menu

### Menu Items:

The following options are available in the Kebab Menu:

- Dashboard
- Timesheet
- Activities
- My Tasks
- All Tasks
- Projects
- Project Updates
- About Us
- Settings

---

## 3. About Us

The **About Us** section provides essential information about the Time Management application, including its purpose, version details, and key capabilities. It can be accessible from the **Main Navigation Menu**

This section helps users understand:

- What the application does
- Who it is intended for
- The main features and benefits
- System and integration information

## 

## 4. Settings

The **Settings** section allows users to configure the application according to their preferences and manage system-level features such as connected accounts, notifications, synchronization, and appearance.

This section is especially useful for first-time users to personalize their experience and ensure the app works seamlessly with external systems.

---

## 4.1 Accessing Settings

To open **Settings**:

1. Click on the **Menu (☰)** icon in the top-left corner
2. Select **Settings** from the sidebar navigation

The Settings screen is divided into multiple configurable sections.

---

## 4.2 Settings Overview

The Settings module includes the following options:

1. Connected Accounts
2. Notifications
3. Background Sync
4. Theme Settings

Each option is explained in detail below.

---

## 4.3 Connected Accounts

The **Connected Accounts** section allows users to link and manage multiple environments or instances (such as local, test, or production systems).

### Purpose:

- Enable integration with different servers or environments
- Allow switching between multiple accounts
- Manage synchronization across systems

### Key Elements:

- **Account List**: Displays all configured accounts
- **Account Type Indicator**: Shows whether it is Local or Server Instance
- **Instance URL**: Displays the connected server link
- **Status Indicator**:
    - *In Progress*: Sync or connection is ongoing
    - *Successful*: Connection is active and working
- **Sync Icon (🔄)**: Manually refresh or sync the account
- **Checkbox Selector**: Activate or select a specific account
- **Add Button (➕)**: Add a new account

---

### 

## 4.3.1 Adding a New Account

**Click on the (➕) icon to a**dd a new account

### Sections in “Create Account” Screen:

1. Account Details
2. Server Connection
3. Credentials
4. Sync Preferences

Each section must be completed carefully to ensure a successful connection.

---

### 4.3.1.1 Account Details

This section defines how the account will appear inside the application.

### Fields:

- **Account Name**
    - Enter a recognizable name (e.g., *Work Account*, *Test Server*)
    - This name helps identify the account when switching between multiple accounts

---

### 4.3.1.2 Server Connection

This section is used to connect the app to your server.

### Fields:

- **URL**
    - Enter the server URL. Example: [https://tma.onestein.eu/](https://tma.onestein.eu/)

 **Fetch Databases Button**

After entering the URL, click **Fetch Databases**.

---

### 4.3.1.3 Fetch Databases

Clicking **Fetch Databases** initiates a process to retrieve available databases from the provided server.

### System Behavior:

- The app connects to the server
- A new screen or dialog opens
- A list of available databases is displayed

### User Actions Required:

On the database selection screen:

- Review the list of available databases
- Select the appropriate database
- If required, manually enter the **Database Name**

### Notes:

- If no databases appear:
    - Verify the server URL
    - Check internet connectivity
    - Ensure the server is accessible
- If multiple databases are listed:
    - Choose the correct one based on your environment

Once selected, confirm and return to the account setup screen.

---

### 4.3.1.4 Database Name

After fetching databases:

- The selected database name will be auto-filled or manually entered
- Ensure the correct database is selected before proceeding

---

### 4.3.1.5 Credentials

This section is used to authenticate your account.

### Fields:

- **Username**
    - Enter your login username
- **Connect With**
    - **Connect With Password or API Key**
- **Password**
    - Enter your account password
    - Use the visibility toggle (👁) to view or hide the password

---

### 4.3.1.6 Sync Preferences

This section allows you to control how data synchronization works.

### Options:

- **Custom Sync Settings (Toggle Switch)**
    
    When enabled:
    
    - You can define custom sync behavior
    
    When disabled:
    
    - The system uses default settings:
        - Sync Interval: ~15 minutes
        - Direction: Two-way sync (data is both sent and received)

---

### 4.3.1.7 Completing Account Setup

After filling all required fields:

1. Click the **✔ (Save/Confirm)** button at the top-right corner
2. The system will:
    - Validate credentials
    - Establish connection
    - Add the account to the Connected Accounts list

---

### 4.3.1.8 Post-Setup Behavior

Once the account is successfully created:

- It appears under **Connected Accounts**
- You can:
    - Activate it using the checkbox
    - Sync it manually using the 🔄 icon
- Initial synchronization may begin automatically

---

### 4.3.2 Switching Between Accounts

- Use the **checkbox** next to an account to activate it
- Only one account should be active at a time
- The active account determines where your data is synced and stored

---

### 4.3.3 Syncing an Account

- Click the **Sync (🔄)** icon next to an account
- The system will:
    - Fetch latest data
    - Update tasks, projects,  timesheets etc..
- Status will update automatically (e.g., *In Progress → Successful*)

### 4.3.4 Managing Accounts (Swipe Actions)

The **Connected Accounts** list supports quick actions using swipe gestures, allowing users to efficiently manage accounts without opening additional screens.

### Purpose:

- Provide faster access to common actions
- Improve usability, especially on touch devices
- Reduce navigation steps

### Available Actions:

**Swipe Right (→): Edit Account**

- Swipe an account item to the **right**
- This reveals the **Edit** option
- Use this to:
    - Update instance URL
    - Modify login credentials
    - Change account configuration

---

**Swipe Left (←): View & Delete Options**

- Swipe an account item to the **left**
- This reveals two action icons:
1. **View** 
    - Opens account details
    - Displays configuration and connection information
2. **Delete** 
    - Removes the account from the app
    

## 4.4 Notifications

The **Notifications** section controls how and when the application alerts you.

### 4.4.1 Push Notifications

The **Push Notifications** section allows you to control whether the application can send alerts directly to your device.

### Key Option:

- **Enable Notifications (Toggle Switch)**
    - **ON**: The app will send real-time notifications for updates such as task changes, project updates, and activity logs
    - **OFF**: All push notifications will be disabled

### When to Enable:

- If you want to stay informed about updates instantly
- If you rely on reminders for task or project updates, activity etc

### When to Disable:

- If you prefer fewer interruptions
- If you only check updates manually within the app

---

### 4.4.2 Notification Schedule

The **Notification Schedule** feature allows you to control *when* notifications are delivered, ensuring they only arrive during your preferred working hours.

This is especially useful for maintaining work-life balance and avoiding notifications outside office hours.

---

### 4.4.2.1 Enable Schedule

- **Enable Schedule (Toggle Switch)**
    - **ON**: Notifications will only be sent during configured days and hours
    - **OFF**: Notifications can be sent at any time

---

### 4.4.2.2 Timezone

- Select your **Timezone** to ensure notifications are aligned with your local time
- Default value is usually set to **System Default**

---

### 4.4.2.3 Working Days

- Monday (Mon)
- Tuesday (Tue)
- Wednesday (Wed)
- Thursday (Thu)
- Friday (Fri)
- Saturday (Sat)
- Sunday (Sun)

### How it works:

- Only selected days will allow notifications
- Unselected days will block all notifications

---

### 4.4.2.4 Working Hours

### Fields:

- **From**: Start time (e.g., 09:00)
- **To**: End time (e.g., 18:00)

### Behavior:

- Notifications will only be sent within the selected time range
- Notifications outside this range will be suppressed

---

### 4.4.2.5 Example Configuration

**Scenario: Standard Work Schedule**

- Enable Notifications: ON
- Enable Schedule: ON
- Working Days: Monday to Friday
- Working Hours: 09:00 to 18:00

**Result:**

You will only receive notifications during office hours on weekdays.

---

## 

## 4.5 Background Sync

The **Background Sync** feature ensures your data stays updated automatically.

### Features:

- Enable automatic synchronization
- Set sync frequency
- Sync tasks, timesheets, projects,  projects updates etc.. in the background

### Benefits:

- Reduces manual effort
- Keeps data consistent across devices and accounts
- Ensures real-time updates

---

## 4.5.1 Background Sync Settings Overview

The **Background Sync Settings** screen allows you to configure how and when your data is synchronized with the server.

This feature works in the background without requiring manual intervention, ensuring that your application always reflects the most up-to-date information.

---

## 4.5.2 Key Configuration Options

### 1. Enable AutoSync (Toggle Switch)

- **ON**:
    - Automatic synchronization is enabled
    - The app will sync data at defined intervals
- **OFF**:
    - Background sync is disabled
    - Data must be synced manually (if applicable)

---

### 2. Sync Interval

Defines how often the application performs automatic synchronization.

### Example Options:

- 5 minutes *(Recommended)*
- 15 minutes *(Recommended)*
- 30 minutes or more

### Recommendation:

- Use **5–15 minutes** for active users
- Use longer intervals to conserve battery and data usage

---

### 3. Sync Direction

### Available Options:

- **Both (Up & Down)** *(Default)*
    - Uploads local changes to the server
    - Downloads updates from the server
- **Upload Only (Up)**
    - Sends local data to the server
    - Does not fetch updates
- **Download Only (Down)**
    - Retrieves updates from the server
    - Does not upload local changes

---

### 4. Restart Background Daemon

This option allows you to restart the background synchronization service.

### When to Use:

- If sync appears stuck or not updating
- After changing sync settings
- After reconnecting an account

## 4.5.3 How Background Sync Works

When AutoSync is enabled:

1. The app runs a background service
2. At each interval:
    - Connects to the configured account/server
    - Uploads new or modified data (tasks, timesheets, etc.)
    - Downloads updates from the server
3. Updates are applied automatically without user action

---

---

## 4.5.4 Best Practices

- Keep **AutoSync enabled** for a seamless experience
- Use a **15-minute interval** for balanced performance and battery usage
- Keep **Sync Direction = Both** unless you have a specific need
- Restart the daemon if syncing issues occur

---

## 4.6 Theme Settings

The **Theme Settings** section allows users to customize the visual appearance of the application.

### Benefits:

- Improves readability
- Enhances user comfort during extended usage
- Supports accessibility preferences

---

## 4.6.1 Theme Settings Overview

The **Theme Settings** screen provides a simple and user-friendly interface to select your preferred application theme.

Users can instantly switch between available themes, and the changes are applied across the entire application without requiring a restart.

---

## 4.6.2 Available Theme Options

### 1. Light Theme

- Bright and clean interface
- Uses light backgrounds with dark text
- Suitable for well-lit environments and daytime use

---

### 2. Dark Theme

- Dark background with lighter text
- Reduces screen brightness and glare

---

## 4.6.3 How to Change the Theme

Follow these steps to update your theme:

1. Select **Theme Settings**
2. Choose one of the available options:
    - Light Theme
    - Dark Theme
3. The selected theme will be applied immediately

---

## 4.6.4 Selection Indicator

- The currently selected theme is marked with a **check indicator (✔)**
- Only one theme can be active at a time

---

## 4.6.5 System Behavior

- Theme changes are applied **instantly** across all screens
- No restart or refresh is required
- The selected theme is **saved automatically** and persists across sessions

---

## 

# 5. Projects

The **Projects** module is used to create, organize, monitor, and manage all project-related activities within the Time Management App.

Projects help users:

- Group related tasks and activities
- Track project timelines and allocated effort
- Monitor progress and status
- Manage assignments and ownership
- Organize work efficiently across teams or departments

The Projects section acts as a centralized workspace for all ongoing and completed projects.

---

# 5.1 Accessing the Projects Module

To open the **Projects** section:

1. Click the **Menu (☰)** icon from the top-left corner
2. Select **Projects** from the sidebar navigation

---

# 5.2 Projects Screen Overview

The Projects screen contains the following components:

1. Header Section
2. Projects List
3. Project Information Panel
4. Search and Filter Options
5. Quick Action Buttons

---

# 5.2.1 Header Section

Located at the top of the Projects screen.

### Features:

- **Search Icon** 
Used to search projects quickly
- **Grid/List View Icon**
Switch between available project display layouts
- **Add Icon** 
Create a new project
- **Save Icon** 
Save newly created or edited project details

---

# 5.2.2 Projects List Panel

The left-side panel displays all available projects.

Each project item provides a quick summary including:

- Project Name
- Instance Name
- Current Status
- Planned Hours
- Start Date
- End Date
- Overdue Indicator (if applicable)

### Example Statuses:

- To Do
- In Progress
- Completed
- On Hold

### Additional Indicators:

- **Star Icon** 
Marks favorite or important projects
- **Overdue Label**
Highlights projects that exceeded their planned completion date

---

# 5.2.3 Project Information Panel

On clicking on any pf the project from the project overview list, will displays detailed information about the selected project.

---

# 5.3 Creating a New Project

To create a project:

1. Open the **Projects** module
2. Click the **➕ Add Icon**
3. Fill in the required project information
4. Click the **✔ Save Button**

The project will then appear in the Projects List.

---

# 5.3.1 Project Creation Fields

The following fields are available while creating or editing a project.

---

## 1. Account

Defines which connected account or environment the project belongs to.

### Purpose:

- Ensures project data is stored in the correct server/account
- Useful when multiple accounts are configured

### Behavior:

- Displays the currently active account
- Can be changed using the dropdown selector

---

## 2. Parent Project

Used to create sub-projects under a larger project.

### Purpose:

- Organize complex projects into smaller sections
- Improve project hierarchy and structure

### Example:

Main Project:

- Website Migration

Sub Projects:

- UI Design
- Backend Setup
- Testing

### Behavior:

- Tap or click **“Tap to select”**
- Choose an existing parent project

---

## 3. Assignee

Defines the user responsible for the project.

### Purpose:

- Clarifies ownership
- Helps track accountability

### Behavior:

- Select a user from the available list

---

## 4. Project Name

The primary title of the project.

### Guidelines:

- Use clear and descriptive names
- Keep names unique when possible

### Example:

- Mobile App Development
- CURQ Documentation
- Website Redesign

---

## 5. Description

Used to provide detailed information about the project.

### Recommended Information:

- Project objectives
- Scope of work
- Important notes
- Expected outcomes

### 

---

## 6. Allocated Hours

Defines the estimated time planned for the project.

### Purpose:

- Helps with workload planning
- Enables comparison between planned vs actual effort

### Example:

`01:00` = 1 Hour

### Behavior:

- Accepts hour and minute values
- Used in project tracking and reporting

---

## 7. Color Indicator

Allows assigning a color to the project.

### Purpose:

- Improve visual organization
- Make projects easier to identify

### Behavior:

- Click the color selector
- Choose a preferred project color

The selected color may appear in project lists, charts, and calendars.

---

# 5.3.2 Planned Dates Section

The Planned Dates section defines the expected project timeline.

---

## Date Range

Provides quick date selection presets.

### Example Options:

- Today
- This Week
- This Month
- Custom Range

### Purpose:

- Simplifies date selection
- Speeds up project planning

---

## Start Date

Defines when the project is expected to begin.

### Behavior:

- Selected using the date picker
- Used for scheduling and reporting

---

## End Date

Defines the planned completion date.

### Behavior:

- Used to monitor deadlines
- Helps identify overdue projects

### Important Note:

If the current date exceeds the End Date and the project is incomplete, the system may display an **Overdue** indicator.

---

# 5.3.3 Attachments Section

The Attachments section allows users to upload and manage project-related files.

### 

### How to Upload:

1. Click the **Upload Icon**
2. Select a file from your device
3. Wait for upload completion

### Benefits:

- Keeps all project-related files centralized
- Improves collaboration and accessibility
- The attached file will get synced to server automatically and vic versa

---

# 5.4 Viewing Project Details

Selecting a project from the Projects List displays its details in the right-side panel.

Users can review:

- Project status
- Timeline
- Allocated hours
- Description
- Assigned user
- Attachments

---

# 5.5 Editing a Project

To edit an existing project:

1. Select the project from the list
2. Click on the edit icon from the top right
3. Update the required fields
4. Click the **✔ Save Button**

### 

---

# 5.6 Project Status Management

Projects move through different statuses during their lifecycle.

### Common Statuses:

| Status | Description |
| --- | --- |
| To Do | Project has not started |
| In Progress | Work is currently ongoing |
| Completed | Project work is finished |
| On Hold | Temporarily paused |

### Benefits:

- Helps monitor project progress
- Improves reporting and planning
- Enables workload tracking

---

# 5.7 Searching Projects

The Projects module includes a search feature for quickly locating projects.

### Search Capabilities:

Users can search using Project Name

### How to Search:

1. Click the **Search Icon** 
2. Enter search text
3. Matching projects are displayed instantly

---

# 5.8 Project Favorites

Projects can be marked as favorites using the **Star Icon**

### Benefits:

- Faster access to important projects
- Improved productivity
- Easier navigation

### Behavior:

- Tap the star icon to mark/unmark a project as favorite

---

# 

# 5.9 Project Overview Swipe Actions

From the Projects List overview, swipe any project item to the **left** to reveal three action icons:

- **View**
- **Start**
- **Pause**

### Available Actions:

### 1. View

Clicking the **View** icon opens the detailed page of the selected project, where users can review and manage complete project information.

### 2. Start

Clicking the **Start** icon starts the project timer.

Once started, the application begins recording time automatically and creates a timesheet entry for the corresponding project.

### 3. Pause

Clicking the **Pause** icon stops the active timer and pauses time tracking for the project.

### Benefits:

- Quick access to project actions
- Faster time tracking
- Improved productivity and workflow management
- Reduced navigation effort

# 5.10 Filter Projects by Stage

The **Filter by Stage** feature allows users to quickly view projects based on their current status or progress stage.

This feature is accessible through the **Floating Action Button (FAB)** located at the bottom-right corner of the Projects screen.

---

# 5.10.1 Accessing the Filter Menu

To open the project stage filter:

1. Navigate to the **Projects** module
2. Click the **Floating Action Button (FAB)** at the bottom-right corner
3. A filter panel titled **“Filter by Stage”** will appear

The filter panel displays available project stages and filtering options.

---

# 5.10.2 Available Filter Options

For example, users can filter projects using the following stages:

| Filter Option | Description |
| --- | --- |
| Open Projects | Displays all active and ongoing projects |
| All Stages | Displays projects from every status |
| To Do | Displays projects that have not started |
| In Progress | Displays projects currently being worked on |
| Done | Displays completed projects |
| Cancelled | Displays cancelled or closed projects |

---

# 5.10.3 How Filtering Works

When a stage is selected:

- The Projects List refreshes automatically
- Only projects matching the selected stage are displayed
- Filtering helps users focus on specific project categories
- By default, all stages will be displayed when opening a project list overview

### Example:

Selecting **In Progress** will display only projects currently under active development or execution.

---

---

# 5.10.4 Clearing or Changing Filters

Users can change the applied filter at any time by:

1. Opening the **Filter by Stage** panel again
2. Selecting a different stage

To display all projects again:

- Select **All Stages**

---

# 

# 6. Tasks

The **Tasks** module helps users create, organize, assign, and track individual or all work items within the Time Management App.

Tasks are the core working units of the application and can be linked to projects, assignees, stages, priorities, and planned schedules.

This module enables users to:

- Create and manage daily work items
- Assign responsibilities to team members
- Track deadlines and overdue tasks
- Organize tasks by stage and priority
- Monitor workload efficiently
- Improve productivity and planning

---

# 6.1 Accessing the Tasks Module

To open the **Tasks** section:

1. Click the **Menu (☰)** icon from the top-left corner
2. Select **All Tasks** from the sidebar navigation

The Tasks screen will open and display all available tasks.

---

# 6.2 Tasks Screen Overview

The Tasks screen is divided into two main sections:

1. Tasks Overview Panel
2. Task Details Panel or create new task page

---

---

# 6.2.1 Tasks Overview Panel

Each task card provides a quick summary including:

- Task Name
- Related Project Name
- Task Stage
- Priority Indicator
- Planned Hours
- Start Date
- End Date
- Overdue Status

### Example Task Stages:

- Analysis
- Design
- Development
- Testing
- Completed

### Overdue Indicator:

If a task exceeds its planned end date and is not completed, the system displays an **Overdue** label in red.

### Date Tabs:

Tasks can be filtered using quick date categories:

- Today
- This Week
- This Month
- Later
- Done
- All

### Benefits:

- Helps users focus on current work
- Simplifies workload management
- Improves task visibility

---

# 6.2.3 Task Details Panel or creating a new task

To create a new task, click on the + icon, the new task entry form will open.

Inorder to view the task details of already created task, just click on the corresponding task, it will displays detailed information about the selected task.

Users can:

- Create new tasks
- Edit existing tasks
- Assign users
- Set priorities
- Define stages
- Add descriptions
- Configure dates and planned hours
- Upload attachments

---

# 6.3 Creating a New Task

To create a task:

1. Open the **All Tasks** module
2. Click the **➕ Add Icon** from the top-right corner
3. Fill in the required task details
4. Click the **✔ Save Button**

The task will then appear in the Tasks Overview list.

---

# 6.3.1 Task Creation Fields

The following fields are available while creating or editing a task.

---

## 1. Account

Defines which connected account or environment the task belongs to.

### Purpose:

- Ensures task data is stored in the correct server/account
- Useful when multiple accounts are configured

### Behavior:

- Displays the active account
- Can be changed using the dropdown selector

---

## 2. Project

Used to associate the task with a specific project.

### Purpose:

- Organizes tasks under projects
- Enables project-based tracking and reporting

### Behavior:

- Tap or click **“Tap to select”**
- Select an available project from the list

---

## 3. Subproject

Allows linking the task to a subproject if applicable.

### Purpose:

- Improves task organization
- Supports hierarchical project management

### Behavior:

- Optional field
- Available only when subprojects exist

---

## 4. Parent Task

Used to create child tasks under a larger task.

### Purpose:

- Break large tasks into smaller manageable items
- Improve task structure and workflow

### Behavior:

- Select an existing parent task if required

---

## 5. Assignees

Defines the users responsible for the task.

### Purpose:

- Clarifies ownership
- Enables collaboration
- Helps monitor accountability

### Behavior:

- Click **Select Assignees**
- Choose one or multiple users from the list
- To unselect the assignees, click on the cross icon

---

## 6. Task Name

The primary title of the task.

### Guidelines:

- Use short and descriptive names
- Clearly define the work item

### 

---

## 7. Priority

Defines the importance level of the task.

### Purpose:

- Helps identify urgent work
- Improves planning and scheduling

### Behavior:

- Priority is selected using the star rating system
- More highlighted stars indicate higher priority

### Example:

- ★☆☆ = Low Priority
- ★★☆ = Medium Priority
- ★★★ = High Priority

---

## 8. Initial Stage

Defines the current workflow stage of the task.

### Example Stages:

- Analysis
- Design
- Development
- Testing
- Completed

### Purpose:

- Tracks progress of work
- Improves workflow management

### Behavior:

- Select a stage from the dropdown menu

---

## 9. Description

Used to provide detailed information about the task.

### Recommended Information:

- Objectives
- Scope of work
- Technical notes
- Important instructions

### Benefits:

- Improves communication
- Reduces misunderstandings
- Provides implementation clarity

---

## 10. Planned Hours

Defines the estimated time required for the task.

### Purpose:

- Helps with effort estimation
- Enables planned vs actual time comparison

### Example:

`01:00` = 1 Hour

### Behavior:

- Supports hour and minute input
- Plus (+) and minus (-) buttons help adjust time quickly

---

# 6.3.2 Planned Dates Section

The Planned Dates section defines the expected task schedule.

---

## Date Range

Provides quick scheduling presets.

### Example Options:

- Today
- This Week
- This Month
- Custom Range

### Purpose:

- Speeds up date selection
- Simplifies task planning

---

## Start Date

Defines when the task is expected to begin.

### Behavior:

- Selected using the date picker
- Used for scheduling and reporting

---

## End Date

Defines the planned completion date.

### Behavior:

- Used for deadline tracking
- Helps identify overdue tasks

### Note:

If the current date exceeds the End Date and the task is incomplete, the system displays an **Overdue** indicator.

---

# 6.3.3 Deadline Section

The Deadline section allows users to define a final expected completion date for the task.

### Purpose:

- Improves schedule tracking
- Helps prioritize urgent work
- Enables deadline monitoring

### Behavior:

- Click the **Select** button
- Choose a deadline date from the date picker

---

# 6.3.4 Attachments Section

The Attachments section allows users to upload files related to the task.

### 

### How to Upload:

1. Click the **Upload Icon**
2. Select a file from your device
3. Wait for upload completion

### Benefits:

- Centralizes task-related files
- Improves collaboration
- Ensures files are available across synced devices

---

# 6.4 Viewing Task Details

Selecting a task from the Tasks Overview Panel displays its complete information in the Task Details Panel.

Users can review:

- Task status
- Assigned users
- Planned hours
- Timeline
- Priority
- Description
- Attachments

---

# 6.5 Editing a Task

To edit an existing task:

1. Select the task from the task list and clck on edit icon or from the task overview, swipe the corresponding task to the left, amd click on edit icon
2. Update the required fields
3. Click the **✔ Save Button**

### 

---

# 6.6 Task Stage Management

Tasks move through different stages during their lifecycle.

### Common Stages:

| Stage | Description |
| --- | --- |
| Analysis | Requirement analysis and planning |
| Design | UI/UX or technical design phase |
| Development | Active implementation work |
| Testing | Quality assurance and validation |
| Completed | Task is fully finished |

### Benefits:

- Improves workflow tracking
- Helps monitor progress
- Enables better reporting

---

# 6.7 Searching Tasks

The Tasks module includes a search feature for quickly locating tasks.

### Search Capabilities:

Users can search using: Task Name

### How to Search:

1. Click the **Search Icon**
2. Enter search text
3. Matching tasks are displayed instantly

---

# 6.8 Filtering Tasks by Assignee

The application supports filtering tasks based on assigned users.

### Purpose:

- Helps managers review team workload
- Enables users to focus on assigned work
- Simplifies task tracking

---

# 6.8.1 Accessing the Assignee Filter

To filter tasks by assignee:

1. Open the **All Tasks** module
2. Click the **Assignee Filter Icon** from the top bar
3. The **Filter by Assignees** popup window appears
4. By deafult, the logged in user name will be selected

---

# 

---

## 

---

## Selected Users

Displays users currently selected for filtering.

### Purpose:

- Shows active filter criteria
- Helps users review selected assignees

---

## Available Users

Displays all available team members.

### Behavior:

- Select users using the checkbox
- Multiple users can be selected simultaneously

---

## Apply Filter

Applies the selected assignee filter.

### Result:

- Only tasks assigned to selected users are displayed

---

## Clear Filter

Removes all applied assignee filters.

### 

---

# 6.9 Task Status Indicators

The Tasks module includes visual indicators to help users quickly understand task conditions.

### Indicators Include:

| Indicator | Meaning |
| --- | --- |
| Red Overdue Text | Task deadline exceeded |
| Star Rating | Task priority level |
| Stage Label | Current workflow stage |
| Planned Hours | Estimated effort |

### Benefits:

- Faster decision-making
- Better workload visibility
- Improved task prioritization

---

# 

# 6.10 Floating Action Button (FAB)

The **Floating Action Button (FAB)** is located at the bottom-right corner of the Tasks Overview screen.

The FAB provides quick access to frequently used actions, allowing users to create and manage tasks more efficiently.

---

## 6.10.1 Accessing the FAB Menu

To open the FAB menu:

1. Navigate to the **All Tasks** module
2. Locate the **Floating Action Button (FAB)** at the bottom-right corner of the screen
3. Click or tap the FAB icon

A quick action menu will appear with available options.

---

## 6.10.2 Creating a New Task Using the FAB

The FAB allows users to quickly create a new task without navigating through additional menus.

### Steps:

1. Open the **All Tasks** screen
2. Click the **Floating Action Button (FAB)**
3. Select **Task** from the menu options
4. A new task entry form will open
5. Fill in the required task information
6. Click the **✔ Save Button** to create the task

---

## 6.10.3 Benefits of Using the FAB

### Quick Access

- Reduces navigation steps
- Allows faster task creation

# 6.11 Task Swipe Actions

The Tasks module supports swipe gestures for quick task management directly from the task overview list.

These gestures help users perform common actions without opening the full task details screen, improving productivity and reducing navigation effort.

---

# 6.11.1 Swipe Right Actions (Reschedule & Delete)

When a user swipes a task item to the **right**, additional quick action icons become visible.

### Available Actions:

| Action | Description |
| --- | --- |
| Reschedule Icon | Used to quickly change the planned task dates |
| Delete Icon | Removes the selected task |

---

## Reschedule Task

Clicking the **Reschedule** icon opens the **Reschedule Task** dialog window.

This feature allows users to quickly update the task schedule using predefined options or custom date ranges.

### Quick Reschedule Options

The following shortcut options are available:

- **Tomorrow**
    - Moves the task schedule to the next day
- **Next Week**
    - Reschedules the task to the following week
- **Next Month**
    - Moves the task schedule to the next month

These options are useful for quickly postponing work without manually selecting dates.

---

## Custom Date Range

Users can also manually configure a custom task schedule.

### Fields:

| Field | Description |
| --- | --- |
| Start Date | Defines the new task start date |
| End Date | Defines the new task completion date |
| Duration | Automatically displays total duration between selected dates |

### Buttons:

| Button | Purpose |
| --- | --- |
| Cancel | Closes the dialog without saving changes |
| Apply | Saves and applies the new schedule |

### Benefits:

- Quickly adjust project timelines
- Improve workload planning
- Simplify schedule management

---

## Delete Task

Clicking the **Delete** icon removes the task from the system.

### 

---

# 6.11.2 Swipe Left Actions (View, Edit, Start & Pause)

When a user swipes a task item to the **left**, four quick action icons are displayed.

### Available Actions:

| Action | Description |
| --- | --- |
| View | Opens detailed task information |
| Edit | Opens the task edit screen |
| Start | Starts the task timer |
| Pause | Stops or pauses the running task timer |

---

## View Task

The **View** action opens the complete task details page.

Users can review:

- Task description
- Assignees
- Priority
- Planned hours
- Attachments
- Dates and deadlines
- Current stage and progress

---

## Edit Task

The **Edit** action opens the task editing screen.

Users can modify:

- Task name
- Project assignment
- Priority
- Planned hours
- Stages
- Dates
- Assignees
- Attachments

After making changes:

1. Click the **✔ Save Button**
2. Updated information is saved automatically

---

## Start Task Timer

The **Start** action begins time tracking for the selected task.

### System Behavior:

- A timer starts automatically
- A timesheet entry may be created
- The task becomes active

### Benefits:

- Accurate time tracking
- Improved productivity monitoring
- Easier reporting

---

## Pause Task Timer

The **Pause** action stops or pauses the active timer.

### System Behavior:

- Time tracking is temporarily stopped
- Users can restart tracking anytime

### Benefits:

- Prevents incorrect time logging
- Supports interruption handling
- Improves timesheet accuracy

---

# 

# 7. My Tasks

The **My Tasks** module is a personalized workspace that displays tasks assigned specifically to the logged-in user.

This section helps users:

- Focus on their assigned work
- Monitor upcoming and overdue tasks
- Track daily and weekly workload
- Start and pause task timers quickly
- Manage priorities efficiently
- Improve personal productivity and task organization

Unlike the **All Tasks** module, which displays tasks for all users, the **My Tasks** module only shows tasks relevant to the current user.

---

# 7.1 Accessing the My Tasks Module

To open the **My Tasks** section:

1. Click the **Menu (☰)** icon from the top-left corner
2. Select **My Tasks** from the sidebar navigation

The My Tasks screen will display all tasks assigned to the logged-in user.

---

# 7.2 My Tasks Screen Overview

The My Tasks screen contains the following sections:

1. Header Section
2. Task Category Tabs
3. My Tasks Overview Panel
4. Task Information Area
5. Quick Action Button (FAB)

---

# 7.2.1 Header Section

Located at the top of the My Tasks screen.

### Features:

- **Filter Icon**
Used to filter tasks based on criteria such as closed or completed tasks
- **Help Icon**
Provides quick guidance or support information
- **Search Icon**
Allows users to search tasks instantly
- **Grid/List View Icon**
Switch between different task display layouts
- **Add Icon (➕)**
Used to create a new task

---

# 7.2.2 Task Category Tabs

The My Tasks module provides quick-access tabs to organize tasks based on timeline and completion status.

### Available Tabs:

| Tab | Description |
| --- | --- |
| Inbox | Newly assigned or pending tasks |
| Today | Tasks planned for the current day |
| This Week | Tasks scheduled within the current week |
| This Month | Tasks planned for the current month |
| Later | Tasks planned for future dates |
| Done | Completed tasks |
| Cancelled | Cancelled or closed tasks |
| All | Displays all assigned tasks |

### Benefits:

- Helps users focus on immediate priorities
- Simplifies workload planning
- Improves task visibility and navigation

---

# 7.2.3 My Tasks Overview Panel

The task overview panel displays all assigned task cards in a structured list format.

Each task card includes:

- Task Name
- Related Project Name
- Task Stage
- Priority Rating
- Planned Hours
- Start Date
- End Date
- Overdue Status

### 

### Priority Indicator:

Task priority is represented using star ratings.

| Priority | Example |
| --- | --- |
| Low | ★☆☆ |
| Medium | ★★☆ |
| High | ★★★ |

### Overdue Indicator:

If a task exceeds its planned end date and is still incomplete, the system displays the overdue duration in red.

### 

---

# 7.2.4 Task Information Display

Each task item provides detailed scheduling and planning information.

### Information Displayed:

- **Planned Hours**
    - Displays estimated work duration
- **Start Date**
    - Indicates when the task is scheduled to begin
- **End Date**
    - Indicates planned completion date
- **Stage Name**
    - Displays the current workflow stage

### Purpose:

- Helps users track deadlines
- Improves schedule awareness
- Enables better task planning

---

# 7.2.5 Floating Action Button (FAB)

The Floating Action Button is located at the bottom-right corner of the My Tasks screen.

### Functions:

- Create a new task
- Access quick task actions
- Improve navigation efficiency

### Benefits:

- Faster task creation
- Reduced navigation effort
- Improved user productivity

---

# 7.3 Viewing Task Details

To view detailed information about a task:

1. Open the **My Tasks** module
2. Click on the required task card
3. The detailed task view screen will open

---

# 7.4 Creating a New Task from My Tasks

Users can create tasks directly from the My Tasks module.

### Steps:

1. Open the **My Tasks** screen
2. Click the **➕ Add Icon** or Floating Action Button
3. Enter required task information
4. Click the **✔ Save Button**

The task will automatically appear in the appropriate category tab.

---

# 7.5 Editing an Existing Task

To edit a task:

1. Open the task details screen
2. Click the **Edit Icon**
3. Update the required fields
4. Click the **✔ Save Button**

### 

---

# 7.6 Task Timer Management

The My Tasks module supports built-in time tracking.

Users can start and pause timers directly from the task overview screen.

---

# 7.6.1 Starting a Task Timer

To start tracking time:

1. Swipe the task item to the left
2. Click the **Start Icon**

### System Behavior:

- Task timer starts automatically
- Active work duration begins recording
- A timesheet entry may be created automatically

### Benefits:

- Accurate time tracking
- Improved productivity reporting
- Simplified timesheet management

---

# 7.6.2 Pausing a Task Timer

To pause active tracking:

1. Swipe the task item to the left
2. Click the **Pause Icon**

### System Behavior:

- Active timer stops temporarily
- Time tracking pauses until resumed

### Benefits:

- Prevents incorrect time logging
- Supports interruptions during work
- Improves reporting accuracy

---

# 7.7 Swipe Actions in My Tasks

The My Tasks module supports quick swipe gestures for faster task management.

These actions reduce navigation steps and improve usability.

---

# 7.7.1 Swipe Left Actions

When a task item is swiped to the **left**, quick action icons become visible.

### Available Actions:

| Action | Description |
| --- | --- |
| View | Opens complete task details |
| Edit | Opens task editing screen |
| Start | Starts task timer |
| Pause | Pauses active task timer |

---

# 7.7.2 Swipe Right Actions

When a task item is swiped to the **right**, additional management actions become available.

### Available Actions:

| Action | Description |
| --- | --- |
| Reschedule | Change planned task dates quickly |
| Delete | Remove the task from the system |

---

# 7.8 Rescheduling Tasks

The Reschedule feature allows users to quickly postpone or update task schedules.

### Quick Options:

- Tomorrow
- Next Week
- Next Month

### Custom Scheduling:

Users can manually select:

- Start Date
- End Date
- Duration

### Benefits:

- Improves schedule management
- Simplifies workload adjustment
- Helps manage delays efficiently

---

# 7.9 Searching Tasks in My Tasks

The My Tasks module includes a built-in search feature.

### How to Search:

1. Click the **Search Icon**
2. Enter the task name or keyword
3. Matching tasks appear instantly

### Benefits:

- Quickly locate assigned work
- Reduce navigation time
- Improve task accessibility

---

# 7.10 Task Status Indicators

Visual indicators help users quickly identify task conditions and priorities.

### Indicators Include:

| Indicator | Meaning |
| --- | --- |
| Red Overdue Text | Task deadline exceeded |
| Star Rating | Task priority level |
| Stage Label | Current workflow stage |
| Planned Hours | Estimated effort |

### Benefits:

- Faster decision-making
- Improved workload visibility
- Better task prioritization

---

# 

## 8. Project Updates

The Project Updates module is used to create, track, monitor, and communicate the latest progress of projects within the Time Management App.

This module helps teams and stakeholders:

- Share current project progress
- Monitor project health and status
- Communicate blockers or risks
- Maintain historical update records
- Improve project visibility across teams

Project Updates act as progress checkpoints and provide a centralized place to document project activities, achievements, delays, and important notes.

---

## 8.1 Accessing the Project Updates Module

To open the Project Updates section:

1. Click the **Menu (☰)** icon from the top-left corner
2. Select **Project Updates** from the sidebar navigation

The Project Updates screen will open and display all available project updates.

---

## 8.2 Project Updates Screen Overview

The Project Updates screen is divided into the following sections:

- Header Section
- Status Filter Tabs
- Project Updates List Panel
- Project Update Details Panel
- Quick Action Icons

---

## 8.2.1 Header Section

Located at the top of the Project Updates screen.

### Features:

| Feature | Description |
| --- | --- |
| Add Icon (➕) | Create a new project update |
| Search Icon | Search project updates quickly |
| Back Navigation | Return to previous screens if applicable |

---

## 8.2.2 Status Filter Tabs

The Project Updates module provides quick filters to organize updates based on project status.

### Available Filters:

| Filter | Description |
| --- | --- |
| All | Displays all project updates |
| On Track | Displays updates for healthy progressing projects |
| At Risk | Displays projects with identified risks or possible delays |
| Off Track | Displays projects facing major issues or delays |
| On Hold | Displays temporarily paused projects |

### Benefits:

- Quickly identify project health
- Improve project monitoring
- Simplify stakeholder reporting
- Focus on critical updates

---

## 8.2.3 Project Updates List Panel

It displays all available project updates in list format.

Each update card provides a quick summary including:

- Update Title
- Created By User
- Update Date
- Related Project Name
- Project Status
- Progress Indicator
- Details Button

### Example Status Labels:

| Status | Meaning |
| --- | --- |
| on_track | Project progressing as planned |
| at_risk | Potential issues identified |
| off_track | Major delays or blockers |
| on_hold | Work temporarily paused |

### Progress Indicator

Each project update displays a visual progress bar representing overall completion percentage.

Purpose:

- Quickly understand project completion level
- Monitor ongoing progress visually
- Improve reporting clarity

---

## 

---

# 8.3 Creating a New Project Update

To create a new project update:

1. Open the **Project Updates** module
2. Click the **➕ Add Icon**
3. Fill in the required update information
4. Click the **✔ Save Button**

The update will then appear in the Project Updates list.

---

# 8.3.1 Project Update Fields

The following fields are available while creating or editing a project update.

---

## 1. Account

Defines which connected account or environment the update belongs to.

### Purpose:

- Ensures updates are stored in the correct account/server
- Useful when multiple accounts are configured

### Behavior:

- Displays the currently active account
- Can be changed using the dropdown selector

---

## 2. Project

Used to associate the update with a specific project.

### Purpose:

- Organizes updates under projects
- Enables project-based progress tracking
- Maintains project history

### Behavior:

- Click or tap **“Tap to select”**
- Choose a project from the available list

---

## 3. Update Title

Defines the main subject or heading of the project update.

### Guidelines:

- Keep titles short and meaningful
- Clearly summarize the update

### Example:

- Sprint Progress Update
- UI Development Completed
- Testing Delayed Due to API Issue

---

## 4. Project Status

Defines the current health or condition of the project.

### Available Statuses:

| Status | Description |
| --- | --- |
| On Track | Project progressing normally |
| At Risk | Potential delay or issue identified |
| Off Track | Major blockers or delays impacting progress |
| On Hold | Project temporarily paused |

### Purpose:

- Helps management assess project condition
- Improves reporting visibility
- Enables faster decision-making

---

## 5. Progress

Defines the current completion percentage of the project.

### Behavior:

- Configured using the progress slider
- Percentage value is displayed dynamically

### Example:

- 10% → Initial phase started
- 50% → Midway completed
- 100% → Fully completed

### Benefits:

- Quick visual understanding of progress
- Better project monitoring
- Easier stakeholder communication

---

## 6. Description

Used to provide detailed project update information.

### Recommended Information:

- Completed activities
- Current progress
- Upcoming work
- Risks or blockers
- Dependencies
- Important notes

### Benefits:

- Improves communication
- Maintains project history
- Provides transparency across teams

---

# 8.4 Saving a Project Update

After entering all required details:

1. Review the entered information
2. Click the **✔ Save Button** located at the top-right corner

### System Behavior:

- The update is validated
- Information is saved automatically
- The new update appears in the Project Updates list
- Progress and status become visible to users

---

# 8.5 Viewing Project Update Details

Users can review complete update information directly from the Project Updates overview list.

### Steps:

1. Open the **Project Updates** module
2. Locate the required update
3. Click the **Details** button

### Result:

The selected project update opens in the detailed view screen.

Users can review:

- Update title
- Related project
- Project status
- Progress percentage
- Full description
- Created by information
- Update date

---

# 8.6 Rich Text Editor in Project Update Details

When the **Details** button is clicked, the project update description opens in a **Rich Text Editor**.

The Rich Text Editor allows users to view and manage formatted update content professionally.

---

## 8.6.1 Purpose of the Rich Text Editor

The editor is designed to:

- Improve readability of project updates
- Support structured documentation
- Enable formatted communication
- Maintain professional update records

---

## 8.6.2 Rich Text Formatting Features

The editor may support the following formatting options:

| Feature | Purpose |
| --- | --- |
| Bold Text | Highlight important information |
| Italic Text | Add emphasis |
| Underline | Mark key details |
| Bullet Lists | Organize information clearly |
| Numbered Lists | Display step-by-step updates |
| Headings | Structure long content |
| Text Alignment | Improve readability |
| Hyperlinks | Add reference links if required |

---

---

# 8.7 Editing a Project Update

To modify an existing project update:

1. Open the Project Updates module
2. Select the required update and click on edit icon
3. Update the required fields
4. Click the ✔ Save Button

### 

---

# 8.8 Searching Project Updates

The Project Updates module includes a search feature for quickly locating updates.

### 

### How to Search:

1. Click the Search Icon
2. Enter search text
3. Matching updates are displayed instantly

### 

---

# 8.9 Project Update Status Indicators

Visual status labels help users quickly identify project conditions.

| Indicator | Meaning |
| --- | --- |
| Green (On Track) | Healthy project progress |
| Orange (At Risk) | Warning or possible delay |
| Red (Off Track) | Critical issue or delay |
| Gray (On Hold) | Temporarily paused project |

### 

# 8.10 Project Update Swipe Actions

The Project Updates module supports swipe gestures for quick update management directly from the project updates overview list.

These swipe actions help users perform common operations quickly without opening the full update details screen, improving productivity and reducing navigation effort.

---

## 8.10.1 Swipe Right Action (Delete)

When a user swipes a project update item to the right, a **Delete Icon** becomes visible.

### Available Action:

| Action | Description |
| --- | --- |
| Delete | Removes the selected project update |

### Delete Project Update

Clicking the **Delete Icon** removes the selected project update from the system.

### System Behavior:

- The selected update is removed from the Project Updates list
- Associated update information will no longer be visible
- The list refreshes automatically after deletion

### 

---

## 8.10.2 Swipe Left Action (Edit)

When a user swipes a project update item to the left, an **Edit Icon** becomes visible.

### Available Action:

| Action | Description |
| --- | --- |
| Edit | Opens the project update editing screen |

### Edit Project Update

Clicking the **Edit Icon** opens the selected project update in edit mode.

Users can modify:

- Update Title
- Project Status
- Progress Percentage
- Description
- Related Project Information

### Steps:

1. Swipe the update item to the left
2. Click the **Edit Icon**
3. Update the required information
4. Click the **✔ Save Button**

### System Behavior:

- Changes are validated automatically
- Updated information is saved instantly
- The Project Updates list refreshes automatically

### 

# 9. Activities

The **Activities** module is used to create, manage, track, and monitor daily activities within the Time Management App.

Activities help users:

- Organize day-to-day work efficiently
- Track meetings, follow-ups, and personal work items
- Maintain activity history
- Monitor overdue activities
- Improve productivity and work planning
- Link activities with projects, tasks, and subprojects

The Activities module acts as a centralized workspace for managing all ongoing and planned activities.

---

# 9.1 Accessing the Activities Module

To open the **Activities** section:

1. Click the **Menu (☰)** icon from the top-left corner
2. Select **Activities** from the sidebar navigation

The Activities screen will display all available activities.

---

# 9.2 Activities Screen Overview

The Activities screen is divided into the following sections:

1. Header Section
2. Activity Filter Tabs
3. Activities Overview Panel
4. Activity Details Panel
5. Quick Action Icons

---

# 9.2.1 Header Section

Located at the top of the Activities screen.

### Features:

| Feature | Description |
| --- | --- |
| Assignee Filter Icon | Filter activities based on assigned users |
| Add Icon (➕) | Create a new activity |
| Search Icon | Search activities quickly |
| Back Navigation | Return to the previous screen |

---

# 9.2.2 Activity Filter Tabs

The Activities module provides quick-access filters to organize activities based on date and completion status.

### Available Tabs:

| Tab | Description |
| --- | --- |
| Today | Displays activities planned for the current day |
| This Week | Displays activities planned within the current week |
| This Month | Displays activities scheduled within the current month |
| Later | Displays future activities |
| OverDue | Displays overdue activities |
| All | Displays all activities |
| Done | Displays completed activities |

### 

---

# 9.2.3 Activities Overview Panel

The Activities Overview Panel displays all activities in a structured list format.

Each activity card provides a quick summary including:

- Activity Name
- Activity Notes or Description
- Assigned User
- Activity Type
- Planned Date
- Overdue Status

### Activity Types:

Example activity types include:

- Meeting
- To-Do
- Follow-Up
- Reminder
- Call

### Overdue Indicator:

If an activity exceeds its planned date and is not completed, the system displays an **Overdue** label in red.

### 

---

# 9.2.4 Activity Details Panel

Selecting an activity from the Activities Overview Panel opens the Activity Details Page.

Users can:

- View activity details
- Create new activities
- Edit existing activities
- Assign users
- Link projects and tasks
- Add notes and summaries
- Configure dates
- Define activity types

---

# 9.3 Creating a New Activity

To create a new activity:

1. Open the **Activities** module
2. Click the **➕ Add Icon** from the top-right corner
3. Fill in the required activity information
4. Click the **✔ Save Button**

The activity will then appear in the Activities Overview list.

---

# 9.3.1 Activity Creation Fields

The following fields are available while creating or editing an activity.

---

## 1. Account

Defines which connected account or environment the activity belongs to.

### Purpose:

- Ensures activity data is stored in the correct account/server
- Useful when multiple accounts are configured

### Behavior:

- Displays the active account
- Can be changed using the dropdown selector

---

## 2. Project

Used to associate the activity with a specific project.

### Purpose:

- Organizes activities under projects
- Enables project-based activity tracking

### Behavior:

- Click or tap **“Tap to select”**
- Select a project from the available list

---

## 3. Subproject

Allows linking the activity to a subproject if applicable.

### Purpose:

- Improves activity organization
- Supports structured project management

### Behavior:

- Optional field
- Available only when subprojects exist

---

## 4. Task

Used to associate the activity with a specific task.

### Purpose:

- Helps track work performed for a task
- Enables activity-to-task mapping

### Behavior:

- Select a task from the available list

---

## 5. Subtask

Allows linking the activity to a subtask.

### Purpose:

- Supports detailed work tracking
- Improves task hierarchy management

### Behavior:

- Optional field
- Displayed when subtasks are available

---

## 6. Assignee

Defines the user responsible for the activity.

### Purpose:

- Clarifies ownership
- Helps track accountability

### Behavior:

- Select a user from the available list

---

## 7. Connected To

Defines whether the activity is connected to a project or a task.

### Available Options:

| Option | Description |
| --- | --- |
| Project | Activity is linked to a project |
| Task | Activity is linked to a task |

### Purpose:

- Improves activity categorization
- Helps maintain proper work relationships

---

## 8. Summary

Defines the primary title or summary of the activity.

### 

### Example:

- Client Meeting
- Testing Discussion
- Follow-up Call
- Documentation Review

---

## 9. Notes

Used to provide additional information related to the activity.

### Recommended Information:

- Discussion points
- Meeting outcomes
- Important reminders
- Follow-up actions
- Additional comments

### 

---

## 10. Activity Type

Defines the category or type of activity.

### Example Types:

- Meeting
- To-Do
- Reminder
- Call
- Discussion

### Purpose:

- Improves activity organization
- Enables easier filtering and reporting

### Behavior:

- Select the required type from the available list

---

## 11. Date

Defines the planned activity date.

### Purpose:

- Helps schedule activities properly
- Enables overdue tracking

### Behavior:

- Select a predefined date range or custom date
- Selected date appears in the activity overview list

---

# 9.4 Viewing Activity Details

To view activity details:

1. Open the **Activities** module
2. Select the required activity from the overview list
3. The Activity Details Panel will display complete information

Users can review:

- Summary
- Notes
- Project information
- Task details
- Assigned user
- Activity type
- Scheduled date
- Status information

---

# 9.5 Editing an Activity

To edit an existing activity:

1. Select the activity from the Activities list
2. Click the **Edit Icon** or use swipe actions towards left
3. Update the required fields
4. Click the **✔ Save Button**

### System Behavior:

- Updated information is validated automatically
- Changes are saved instantly
- The activity list refreshes automatically

---

# 9.6 Searching Activities

The Activities module includes a search feature for quickly locating activities.

### 

### How to Search:

1. Click the **Search Icon**
2. Enter search text
3. Matching activities are displayed instantly

### 

---

# 

---

# 9.7 Activity Swipe Actions

The Activities module supports swipe gestures for quick activity management directly from the Activities Overview list.

These gestures help users perform common actions quickly without opening the complete activity details screen.

---

# 

# 9.7.1 Swipe Right Action (Delete)

When a user swipes an activity item to the **right**, a **Delete Icon** becomes visible.

### Available Action:

| Action | Description |
| --- | --- |
| Delete | Removes the selected activity |

### Delete Activity

Clicking the **Delete Icon** removes the selected activity from the system.

### System Behavior:

- The selected activity is removed from the Activities list
- Associated information will no longer be visible
- The overview list refreshes automatically after deletion

---

# 9.7.2 Swipe Left Actions (Edit, Mark as Done, Follow-Up)

When a user swipes an activity item to the **left**, three action icons become visible.

### Available Actions:

| Action | Description |
| --- | --- |
| Edit | Opens the activity editing screen |
| Mark as Done | Marks the selected activity as completed |
| Follow-Up | Creates a new follow-up activity using the same activity content |

---

## Edit Activity

Clicking the **Edit Icon** opens the selected activity in edit mode.

Users can modify:

- Summary
- Notes
- Project Information
- Task Information
- Assignee
- Activity Type
- Date

### Steps:

1. Swipe the activity item to the left
2. Click the **Edit Icon**
3. Update the required information
4. Click the **✔ Save Button**

### 

---

## Mark Activity as Done

Clicking the **Done Icon (✔)** marks the selected activity as completed.

### Steps:

1. Swipe the activity item to the left
2. Click the **Done Icon**

### System Behavior:

- The activity status changes to **Completed**
- The activity is updated instantly
- The Activities list refreshes automatically

### 

---

## Create Follow-Up Activity

Clicking the **Follow-Up Icon** creates a new activity using the same content as the selected activity.

### System Behavior:

- A new activity form opens automatically
- Existing activity details are prefilled
- Users can modify details before saving
- The original activity remains unchanged

### Prefilled Information Includes:

- Summary
- Notes
- Project Information
- Task Information
- Assignee
- Activity Type

### Steps:

1. Swipe the activity item to the left
2. Click the **Follow-Up Icon**
3. Update any required information
4. Select the new activity date if needed
5. Click the **✔ Save Button**

### 

# 

# 10. Timesheet

The **Timesheet** module is used to record, manage, and monitor the time spent on projects, tasks, and daily work activities within the Time Management App.

This module helps users:

- Track daily working hours
- Record effort spent on tasks and projects
- Maintain accurate work logs
- Improve productivity tracking
- Support reporting and billing processes
- Monitor time utilization across teams and projects

The Timesheet module serves as the central area for managing all work-hour entries.

---

# 10.1 Accessing the Timesheet Module

To open the **Timesheet** section:

1. Click the **Menu (☰)** icon from the top-left corner
2. Select **Timesheet** from the sidebar navigation

The Timesheet screen will display all available timesheet entries.

---

# 10.2 Timesheet Screen Overview

The Timesheet screen is divided into the following sections:

1. Header Section
2. Timesheet Filter Tabs
3. Timesheet Overview Panel
4. Timesheet Details Panel
5. Swipe Actions
6. Floating Action Button (FAB)

---

# 10.2.1 Header Section

Located at the top of the Timesheet screen.

### Features:

| Feature | Description |
| --- | --- |
| Add Icon (➕) | Create a new timesheet entry |
| Back Navigation | Return to the previous screen |
| Search Icon | Search existing timesheet entries |

---

# 10.2.2 Timesheet Filter Tabs

The Timesheet module provides filters to organize timesheet entries based on their current status.

### Available Tabs:

| Tab | Description |
| --- | --- |
| All | Displays all timesheet entries |
| Active | Displays currently active or ongoing timesheets |
| Draft | Displays saved draft timesheets awaiting completion |

### Purpose:

- Helps users quickly identify required entries
- Simplifies time tracking management
- Improves navigation through large numbers of records

---

# 10.2.3 Timesheet Overview Panel

The Timesheet Overview Panel displays all timesheet records in a list format.

Each timesheet item provides a quick summary including:

- Timesheet Title
- Project Name
- Task or Subtask Information
- Logged Hours
- Entry Date
- Assigned User
- Priority Information

### 

---

# 10.2.4 Timesheet Details Panel

Selecting a timesheet entry from the overview list opens the Timesheet Details Panel.

Users can:

- Create new timesheet entries
- Edit existing entries
- Log working hours
- Select projects and tasks
- Configure priorities
- Add descriptions and notes
- Manage manual or automated time tracking

---

# 10.2.5 Swipe Actions

The Timesheet module supports swipe gestures for faster task management directly from the overview list.

Users can perform actions by swiping a timesheet entry either to the left or right.

---

## Right Swipe Action – Delete

Swiping a timesheet entry from **left to right** reveals the **Delete** option.

### Purpose:

- Quickly remove unwanted or incorrect entries
- Simplify timesheet cleanup

### How to Use:

1. Locate the required timesheet entry
2. Swipe the entry toward the right
3. Tap the **Delete** button

### 

---

## Left Swipe Actions – Quick Controls

Swiping a timesheet entry from **right to left** displays three quick action icons:

| Icon | Description |
| --- | --- |
| Edit | Opens the selected timesheet in edit mode |
| Start Timer | Starts or resumes automated time tracking |
| Mark as Done | Marks the draft timesheet as completed and ready for synchronization |

---

## Edit Action

The **Edit** action allows users to quickly modify an existing timesheet entry without opening additional menus.

### 

---

## Start Timer Action

The **Start Timer** action begins automated time tracking directly from the timesheet list.

### System Behavior:

- The timer starts immediately
- Active tracking is updated in real time
- Recorded duration is automatically attached to the selected timesheet
- The entry may appear under the **Active** tab while running

---

## Mark as Done Action

The **Mark as Done** action is used to finalize a draft timesheet entry.

### How to Use:

1. Open the **Draft** tab
2. Swipe the required entry toward the left
3. Tap the **✔ Mark as Done** icon

### System Behavior:

- A confirmation popup message appears:

**Success:** *Timesheet is now ready to be synced to Odoo.*

- The entry is removed from the **Draft** tab
- The entry remains visible under the **All** tab
- The timesheet status changes from **Draft** to **Completed**
- The entry becomes available for synchronization with Odoo

---

# 10.2.6 Floating Action Button (FAB)

A **Floating Action Button (FAB)** is available at the bottom-right corner of the Timesheet screen.

The FAB provides quick access to timesheet creation features.

---

## FAB Behavior

### Default State

- A circular action icon is displayed at the bottom-right corner of the screen

### On Click

When the FAB icon is tapped:

- A **Create** button expands above the FAB

### Create Button Action

Clicking the **Create** button opens the **New Timesheet Entry Form**.

---

# 10.3 Creating a New Timesheet Entry

To create a new timesheet entry:

1. Open the **Timesheet** module
2. Click the **➕ Add Icon** or **Create Button**
3. Fill in the required information
4. Click the **✔ Save Button**

The timesheet entry will then appear in the Timesheet Overview list.

---

# 10.3.1 Timesheet Creation Fields

The following fields are available while creating or editing a timesheet entry.

---

## 1. Account

Defines which account or workspace the timesheet belongs to.

### Purpose:

- Ensures data is stored under the correct environment
- Supports multiple account configurations

### Behavior:

- Displays the currently selected account
- Can be changed using the dropdown selector

---

## 2. Project

Used to associate the timesheet entry with a project.

### Purpose:

- Tracks time against specific projects
- Supports project-based reporting

### Behavior:

1. Click or tap **Tap to Select**
2. Select the required project from the list

---

## 3. Subproject

Allows linking the timesheet entry to a subproject.

### Purpose:

- Improves project organization
- Supports detailed work tracking

### Behavior:

- Optional field
- Available only when subprojects exist

---

## 4. Task

Used to associate the entry with a specific task.

### Purpose:

- Tracks effort spent on tasks
- Improves task-level reporting

### Behavior:

- Select a task from the available list

---

## 5. Subtask

Allows linking the entry to a subtask.

### Purpose:

- Supports detailed time allocation
- Enhances work breakdown tracking

### Behavior:

- Optional field
- Displayed only when subtasks are available

---

## 6. Priority

Defines the importance and urgency level of the work item.

### Available Priority Levels:

| Priority | Description |
| --- | --- |
| Important, Urgent (1) | High-priority work requiring immediate attention |
| Important, Not Urgent (2) | Important work that can be planned |
| Urgent, Not Important (3) | Time-sensitive work with lower business impact |
| Not Urent, Not Important (4) | Low-priority work |

### Purpose:

- Helps users categorize work effectively
- Supports better task management and planning

---

## 7. Time Tracking Mode

Defines how time will be recorded.

### Available Options:

| Option | Description |
| --- | --- |
| Manual | Users manually enter working hours |
| Automated | The system timer automatically tracks time |

### Purpose:

- Provides flexibility in time recording
- Supports both quick entry and live tracking workflows

---

## 8. Timer

The timer is used when **Automated** tracking is enabled.

### Features:

- Start tracking work time
- Pause ongoing tracking
- Stop and save tracked duration

### System Behavior:

- The timer updates automatically while running
- Recorded duration is added to the timesheet entry

---

## 9. Date

Defines the working date for the timesheet entry.

### Purpose:

- Helps organize timesheet records chronologically
- Supports reporting and attendance tracking

### Behavior:

- Users can select predefined date options or a custom date
- Selected date appears in the timesheet overview list

---

## 10. Description

Used to provide detailed information about the work completed.

### Recommended Information:

- Work performed
- Development updates
- Testing activities
- Meetings attended
- Task completion details
- Issues resolved

### Purpose:

- Improves reporting clarity
- Helps managers and team members understand completed work
- Supports audit and billing requirements

---

# 10.4 Viewing Timesheet Details

To view timesheet details:

1. Open the **Timesheet** module
2. Select the required timesheet entry from the overview list
3. The Timesheet Details Panel will display complete information

---

# 10.5 Editing a Timesheet Entry

To edit an existing timesheet entry:

1. Select the required timesheet entry
2. Open the entry in edit mode
3. Update the required fields
4. Click the **✔ Save Button**

### System Behavior:

- Updated information is validated automatically
- Changes are saved instantly
- The overview list refreshes automatically

---

# 10.6 Searching Timesheet Entries

The Timesheet module includes a search feature for quickly locating entries.

### How to Search:

1. Open the Timesheet module
2. Click the **Search Icon**
3. Enter search text
4. Matching timesheet entries are displayed instantly

### 

---

# 10.7 Timesheet Status Management

Timesheet entries can exist in different states depending on their progress.

### Available Statuses:

| Status | Description |
| --- | --- |
| Active | Currently ongoing or recently updated entries |
| Draft | Entries saved temporarily before final submission |
| Completed | Finished and finalized entries ready for synchronization |

### Purpose:

- Helps users monitor work progress
- Supports structured approval workflows
- Improves reporting accuracy

---

# 10.8 Automated Timer Save as Draft Process

When using the **Automated** time tracking option, the system provides a simplified workflow for saving tracked work entries.

After starting the timer and allowing it to run for a few seconds or longer, stopping the timer will automatically open the **Add Description to Timesheet** dialog box.

This dialog allows users to:

- Review the recorded time
- Enter work descriptions or notes
- Save the entry as a draft
- Cancel the operation if needed

This feature helps users quickly capture ongoing work without immediately finalizing the timesheet entry.

---

# 10.8.1 Opening the Automated Timer Dialog

The dialog box appears automatically when:

1. The user selects **Automated** time tracking
2. Starts the timer
3. Allows the timer to run
4. Clicks the **Stop Button**

Once stopped, the system opens the **Add Description to Timesheet** popup window.

---

# 10.8.2 Add Description to Timesheet Dialog

The dialog box contains the following sections:

| Section | Description |
| --- | --- |
| Time Recorded | Displays the total tracked duration |
| Description/Notes | Allows users to enter work details |
| Save as Draft Button | Saves the entry in Draft status |
| Cancel Button | Closes the dialog without saving |

---

# 10.8.3 Save as Draft

Clicking the **Save as Draft** button stores the timesheet entry in **Draft** status.

### System Behavior:

- The tracked duration is saved
- Entered descriptions are stored
- The timesheet is not finalized
- Users can edit the entry later
- The entry becomes visible under the **Draft** tab

---

# 10.8.4 Draft Timesheet Visibility

All draft timesheet entries are displayed under the **Draft** filter tab.

### To View Draft Timesheets:

1. Open the **Timesheet** module
2. Select the **Draft** tab
3. View all saved draft entries

### Users Can:

- Continue editing draft entries
- Add missing project or task information
- Update descriptions
- Finalize and save entries later

---

# 10.8.5 Completing a Draft Timesheet

Draft entries can be finalized directly from the overview screen using the **Mark as Done** action.

### Steps:

1. Open the **Draft** tab
2. Swipe the required timesheet entry toward the left
3. Tap the **✔ Mark as Done** icon

### System Response:

A success popup message appears:

**Success:** *Timesheet is now ready to be synced to Odoo.*

### After Completion:

- The entry is removed from the **Draft** tab
- The entry remains visible under the **All** tab
- The timesheet status changes to **Completed**
- The entry becomes available for synchronization with Odoo

---

# 10.8.6 Cancel Option

Clicking the **Cancel** button closes the dialog box without saving the timesheet entry.

### System Behavior:

- The popup window closes
- Unsaved description data is discarded
- No draft entry is created
- The timer data is not stored unless saved manually

---

# 10.9 Odoo Synchronization Readiness

Completed timesheets marked using the **Mark as Done** action become eligible for synchronization with Odoo.

### Synchronization Workflow:

1. User completes or finalizes a draft timesheet
2. System marks the entry as ready for sync
3. The timesheet remains visible in the **All** tab
4. Backend synchronization processes can transfer the entry to Odoo

### 

###