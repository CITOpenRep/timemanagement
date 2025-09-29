# Assignee Filter Implementation for Task Management App

## Overview
This implementation adds an assignee filter functionality to the Task page, similar to the existing stage filter in the Project list view. Users can filter tasks by selecting one or more assignees using a floating action button (FAB) with a selectable list view.

## Components Added/Modified

### 1. New Component: AssigneeFilterMenu.qml
**Location:** `/home/suraj/timemanagement/qml/components/AssigneeFilterMenu.qml`

**Features:**
- Floating Action Button (FAB) with a blue background and contact icon
- Positioned above the existing stage filter menu (anchors.bottomMargin: units.gu(11))
- Shows a badge with the count of selected assignees
- Expandable menu with checkbox-based multi-select functionality
- Search bar for filtering assignees when more than 5 are available
- Apply Filter and Clear Filter buttons
- Smooth animations and hover effects

**Key Properties:**
- `assigneeModel`: Array of available assignees
- `selectedAssigneeIds`: Array of selected assignee IDs
- `expanded`: Controls menu visibility

**Signals:**
- `filterApplied(var selectedAssigneeIds)`: Emitted when Apply Filter is clicked
- `filterCleared`: Emitted when Clear Filter is clicked

### 2. Updated: Task_Page.qml
**Location:** `/home/suraj/timemanagement/qml/Task_Page.qml`

**New Properties Added:**
```qml
// Properties for assignee filtering
property bool filterByAssignees: false
property var selectedAssigneeIds: []
property var availableAssignees: []
```

**New Functions Added:**
- `loadAssignees()`: Loads available assignees for the current account

**Key Changes:**
- Integrated AssigneeFilterMenu component
- Added assignee filter handling in signal handlers
- Updated account change handlers to reload assignees and clear filters
- Enhanced filtering logic to support assignee-based filtering

### 3. Updated: TaskList.qml
**Location:** `/home/suraj/timemanagement/qml/components/TaskList.qml`

**New Properties Added:**
```qml
// Properties for assignee filtering
property bool filterByAssignees: false
property var selectedAssigneeIds: []
```

**Modified Functions:**
- `refreshWithFilter()`: Updated to prioritize assignee filtering over other filters

### 4. Updated: task.js
**Location:** `/home/suraj/timemanagement/models/task.js`

**New Functions Added:**

#### `getAllTaskAssignees(accountId)`
- Returns all unique assignees who have been assigned to tasks in the given account
- Handles comma-separated user IDs in the user_id field
- Returns array of assignee objects with id, name, and odoo_record_id

#### `getTasksByAssignees(assigneeIds, accountId, filterType, searchQuery)`
- Filters tasks by the provided assignee IDs
- Supports additional date filtering and search queries
- Handles multiple assignees per task (comma-separated IDs)
- Returns filtered list of tasks

## User Interface Flow

### 1. Accessing the Filter
- A blue FAB with a contact icon appears at the bottom-right of the Task page
- Positioned above the existing stage filter menu
- Shows a red badge with the count of selected assignees when filters are active

### 2. Selecting Assignees
- Click the FAB to expand the assignee selection menu
- Each assignee appears with a checkbox and name
- Multiple assignees can be selected simultaneously
- Search functionality available for lists with more than 5 assignees

### 3. Applying the Filter
- Click "Apply Filter" to filter tasks by selected assignees
- The task list updates to show only tasks assigned to the selected users
- The FAB badge shows the number of active filters

### 4. Clearing the Filter
- Click "Clear Filter" to remove all assignee filters
- The task list returns to showing all tasks (based on other active filters)
- The FAB badge disappears

### 5. Account Changes
- When switching accounts, the assignee list refreshes automatically
- Any active assignee filters are cleared
- Available assignees are loaded for the new account

## Technical Implementation Details

### Filter Priority
The filtering logic follows this priority order:
1. **Assignee Filter** (if active and has selections)
2. **Account Filter** (if active and account ID >= 0)
3. **Date/Search Filters** (all tasks, filtered by date/search)
4. **Default** (all tasks via populateTaskChildrenMap)

### Data Flow
1. **Load Assignees**: `getAllTaskAssignees()` queries the database for unique assignees
2. **Filter Selection**: User selects assignees via checkboxes in the UI
3. **Apply Filter**: `getTasksByAssignees()` filters tasks by selected assignee IDs
4. **Display Update**: TaskList component refreshes with filtered results

### Database Integration
- Leverages existing `res_users_app` table for user information
- Handles both single and multiple assignees per task (comma-separated in `user_id` field)
- Maintains account-based filtering compatibility

## Benefits

1. **Enhanced Task Management**: Users can quickly filter tasks by assignee responsibility
2. **Multi-Select Capability**: Support for filtering by multiple assignees simultaneously
3. **Account Awareness**: Assignee filters respect account boundaries
4. **Consistent UX**: Follows the same design patterns as the existing stage filter
5. **Search Integration**: Works alongside existing date and search filters
6. **Performance Optimized**: Efficient database queries with proper indexing support

## Usage Scenarios

1. **Team Lead Review**: Filter tasks assigned to specific team members
2. **Workload Analysis**: View tasks distributed across multiple assignees
3. **Personal Task Focus**: Filter to show only tasks assigned to the current user
4. **Project Coordination**: Combine assignee filters with project and date filters for comprehensive task views

This implementation provides a comprehensive assignee filtering solution that integrates seamlessly with the existing task management functionality.