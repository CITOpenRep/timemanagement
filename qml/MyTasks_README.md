# MyTasks Page

## Overview
The `MyTasks.qml` page is a specialized task list view that shows only tasks assigned to the currently logged-in user. It's similar to the `Task_Page.qml` but with automatic filtering by the current user's assignments.

## Features

### Automatic User Filtering
- **Current User Detection**: Automatically determines the logged-in user based on the selected account
- **Personal Task View**: Shows only tasks where the current user is an assignee
- **Multi-Account Support**: When switching accounts, automatically updates to show tasks for that account's current user

### Standard Task Management Features
- **Time-based Filters**: Today, This Week, This Month, Later, Done, All
- **Search**: Full-text search across task names and descriptions
- **Quick Actions**: View, Edit, Create Timesheet, Delete
- **Create New**: Add new tasks directly from the page

### Account Integration
- **Account Selector**: Works with the global account filter
- **Dynamic Updates**: Automatically refreshes when account changes
- **Proper User Mapping**: Uses `getCurrentUserOdooId()` to map account credentials to Odoo user records

## Usage

### Navigation
To open the MyTasks page from another page:
```qml
apLayout.addPageToNextColumn(currentPage, Qt.resolvedUrl("MyTasks.qml"));
```

### Integration with Menu
Add to the main navigation menu (e.g., in Menu.qml or Dashboard.qml):
```qml
Action {
    iconName: "contact"  // or another appropriate icon
    text: "My Tasks"
    onTriggered: {
        apLayout.addPageToNextColumn(currentPage, Qt.resolvedUrl("MyTasks.qml"));
    }
}
```

## Technical Details

### User Identification
The page uses `Account.getCurrentUserOdooId(accountId)` to retrieve the current user's `odoo_record_id` from the `res_users_app` table. This function:
1. Looks up the username from the `users` table for the given account
2. Finds the matching user in `res_users_app` by matching the `login` field
3. Returns the `odoo_record_id` which is used to filter tasks

### Filtering Logic
```javascript
// In updateCurrentUser()
if (accountId >= 0) {
    currentUserOdooId = Account.getCurrentUserOdooId(accountId);
    
    // Set up TaskList filtering
    myTasksList.filterByAssignees = true;
    myTasksList.selectedAssigneeIds = [currentUserOdooId];
}
```

### Key Properties
- `currentUserOdooId`: The odoo_record_id of the logged-in user
- `currentAccountId`: The currently selected account
- `filterByAssignees`: Always true for this page (enforces user filtering)
- `selectedAssigneeIds`: Array containing only the current user's ID

## Differences from Task_Page.qml

| Feature | Task_Page.qml | MyTasks.qml |
|---------|---------------|-------------|
| **Assignee Filter** | Optional (user can toggle) | Always enabled (current user only) |
| **Filter Menu** | Has AssigneeFilterMenu component | No filter menu (automatic) |
| **Default View** | All tasks (for selected account) | Only current user's tasks |
| **Use Case** | Team/manager view | Personal task list |

## Example Scenarios

### Scenario 1: Single Account User
- User logs into LOCAL ACCOUNT (id = 0)
- MyTasks shows all tasks assigned to user with `odoo_record_id = 1`
- Filters work across all tasks assigned to this user

### Scenario 2: Multi-Account User
- User has accounts: LOCAL (id=0), Odoo Production (id=1)
- Switches to Odoo Production account
- MyTasks automatically filters to show tasks assigned to their Odoo user
- Uses `getCurrentUserOdooId(1)` to get proper Odoo user ID

### Scenario 3: Shared Device
- Multiple users share same device but different Odoo accounts
- Each user sees only their own tasks when they switch accounts
- Proper user isolation maintained

## Files Modified/Created

### New Files
- `/qml/MyTasks.qml` - Main page component

### Dependencies
- `TaskList.qml` - Task list component (shared with Task_Page)
- `ListHeader.qml` - Header with filters (shared)
- `../models/accounts.js` - For getCurrentUserOdooId()
- `../models/task.js` - For task operations

## Future Enhancements

Possible improvements:
1. **Statistics**: Show count of tasks by status (Today: 5, This Week: 12, etc.)
2. **Priorities**: Visual indicator for high-priority tasks
3. **Overdue Alerts**: Highlight overdue tasks for the current user
4. **Quick Filters**: Add buttons for "Urgent", "High Priority", "Due Soon"
5. **Workload Indicator**: Show estimated hours vs. available time

## Testing

To test the MyTasks page:
1. Log into an account
2. Create several tasks assigned to different users
3. Open MyTasks page
4. Verify only tasks assigned to current user appear
5. Switch accounts and verify tasks update correctly
6. Test all time filters (Today, This Week, etc.)
7. Test search functionality
8. Test task actions (View, Edit, Create Timesheet, Delete)
