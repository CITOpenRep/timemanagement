/*
 * Multiple Assignees Implementation Guide for Tasks
 * 
 * This document explains how the multiple assignee feature works and how to use it.
 */

IMPLEMENTATION OVERVIEW:
=======================

1. DATABASE CHANGES:
   - Added new table: project_task_assignee_app
   - Stores relationships between tasks and assignees
   - Supports multiple assignees per task

2. NEW COMPONENTS:
   - MultiAssigneeSelector.qml: UI component for selecting multiple assignees
   - Updated WorkItemSelector.qml: Now supports both single and multiple assignee modes

3. UPDATED FILES:
   - Tasks.qml: Now supports multiple assignee selection
   - task.js: Updated to handle saving/loading multiple assignees
   - dbinit.js: Added new database table

HOW TO USE:
===========

1. Enable Multiple Assignees in WorkItemSelector:
   ```qml
   WorkItemSelector {
       id: workItem
       enableMultipleAssignees: true  // Set this to enable multiple assignees
       showAssigneeSelector: true
       // ... other properties
   }
   ```

2. Save Function Changes:
   The save function now checks for multiple assignees:
   ```javascript
   function save_task_data() {
       const ids = workItem.getIds();
       
       // Check for assignees - either single or multiple
       var hasAssignees = false;
       if (workItem.enableMultipleAssignees) {
           hasAssignees = ids.multiple_assignees && ids.multiple_assignees.length > 0;
       } else {
           hasAssignees = ids.assignee_id !== null;
       }
       
       if (!hasAssignees) {
           notifPopup.open("Error", "Please select at least one assignee", "error");
           return;
       }
       
       // ... rest of save logic
   }
   ```

3. Database Schema:
   ```sql
   CREATE TABLE project_task_assignee_app (
       id INTEGER PRIMARY KEY AUTOINCREMENT,
       task_id INTEGER,        -- Local task ID
       account_id INTEGER,     -- Account ID
       user_id INTEGER,        -- Assignee user ID
       last_modified datetime,
       status TEXT DEFAULT "",
       UNIQUE (task_id, account_id, user_id)
   );
   ```

UI DISPLAY:
===========

When multiple assignees are enabled, the UI shows:
- A button labeled "Select Assignees"
- When assignees are selected, shows count: "3 assignees selected"
- Displays selected assignees as removable chips/tags below the button
- Dialog with checkboxes for selecting/deselecting assignees

BENEFITS:
=========

1. Better Collaboration: Multiple team members can be assigned to a task
2. Clear Responsibility: Shows all responsible parties for a task
3. Flexible UI: Can switch between single and multiple assignee modes
4. Backward Compatible: Existing single-assignee tasks continue to work

MIGRATION:
==========

Existing tasks with single assignees will continue to work normally.
When you enable multiple assignees on an existing task:
1. The current assignee (user_id) is preserved in the main task table
2. Additional assignees are stored in the new relationship table
3. The UI shows all assignees (both old and new)

API FUNCTIONS:
==============

New functions added to task.js:
- getTaskAssignees(taskId, accountId): Returns array of assignees for a task
- saveOrUpdateTask(): Now accepts multipleAssignees array in data

New functions in WorkItemSelector:
- setMultipleAssignees(assignees): Sets the selected assignees
- getMultipleAssignees(): Gets the currently selected assignees
- getIds(): Now returns multiple_assignees and assignee_ids arrays

EXAMPLE USAGE:
==============

```qml
WorkItemSelector {
    id: workItem
    enableMultipleAssignees: true
    showAssigneeSelector: true
    
    onMultiAssigneesChanged: {
        console.log("Assignees changed:", JSON.stringify(assignees));
    }
}

// Get selected assignees
var selectedAssignees = workItem.getIds().multiple_assignees;
// Returns: [{id: 1, name: "John Doe"}, {id: 2, name: "Jane Smith"}]

// Set assignees programmatically
workItem.setMultipleAssignees([
    {id: 1, name: "John Doe"},
    {id: 3, name: "Bob Wilson"}
]);
```
