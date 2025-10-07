# Task Stage Change Feature Implementation

## Overview
This implementation adds a "Change Stage" button to the Task form view (Tasks.qml) that allows users to change a task's stage through a popup dialog. The feature properly handles multiple account instances and displays the current stage.

## Components Added/Modified

### 1. **TaskStageSelector.qml** (NEW)
   - **Location**: `/home/suraj/timemanagement/qml/components/TaskStageSelector.qml`
   - **Purpose**: A reusable popup dialog component for selecting and changing task stages
   - **Features**:
     - Displays all available task stages for the project and account
     - Shows current stage with visual indicator (orange border and marker)
     - Displays stage description and fold status
     - Prevents selecting the same stage (already selected)
     - Properly handles account filtering to work with multiple instances
     - Ordered by sequence for logical display

### 2. **task.js Functions** (MODIFIED)
   - **Location**: `/home/suraj/timemanagement/models/task.js`
   - **New Functions**:
   
   #### `getTaskStagesForProject(projectOdooRecordId, accountId)`
   - Retrieves all task stages (types) for a specific project and account
   - Returns only global stages (is_global=1) that belong to the account
   - Orders by sequence and name for proper display
   - **Parameters**:
     - `projectOdooRecordId`: The odoo_record_id of the project
     - `accountId`: The account ID
   - **Returns**: Array of stage objects with id, odoo_record_id, name, sequence, fold, description
   
   #### `updateTaskStage(taskId, stageOdooRecordId, accountId)`
   - Updates the stage of a task with proper validation
   - Verifies task and stage belong to the correct account
   - Updates the task's state field and marks it as "updated"
   - **Parameters**:
     - `taskId`: The local ID of the task
     - `stageOdooRecordId`: The odoo_record_id of the new stage
     - `accountId`: The account ID
   - **Returns**: Success/error result object

### 3. **Tasks.qml** (MODIFIED)
   - **Location**: `/home/suraj/timemanagement/qml/Tasks.qml`
   - **Changes**:
   
   #### Added TaskStageSelector Component
   ```qml
   TaskStageSelector {
       id: taskStageSelector
       onStageSelected: {
           handleStageChange(stageOdooRecordId, stageName);
       }
   }
   ```
   
   #### Added handleStageChange Function
   - Handles the stage change operation
   - Validates task data availability
   - Calls the backend function to update the stage
   - Reloads the task to reflect changes
   - Shows success/error notifications
   
   #### Added Current Stage Display Row
   - Shows "Current Stage:" label with the current task stage name
   - Uses color coding (green for completed stages, default for others)
   - Positioned above the button row
   - Only visible when viewing an existing task (recordid !== 0)
   
   #### Modified Button Row
   - Added "Change Stage" button next to "Create Activity" button
   - Both buttons are now equal width (50% each with spacing)
   - "Change Stage" button opens the TaskStageSelector dialog
   - Passes correct parameters: task ID, project ID, account ID, and current stage

## How It Works

1. **User clicks "Change Stage" button**
   - Button is only visible when viewing an existing task (recordid !== 0)
   - Validates that task data is available

2. **Dialog opens with stage list**
   - Fetches all available task stages for the task's project and account
   - Displays stages in sequence order
   - Highlights the current stage with visual indicators
   - Shows stage descriptions and fold status

3. **User selects a new stage**
   - Click on a stage in the list (current stage cannot be re-selected)
   - Dialog emits `stageSelected` signal with stage ID and name

4. **Stage is updated**
   - `handleStageChange` function is called
   - Backend function validates and updates the database
   - Task is reloaded to reflect the new stage
   - Success notification is displayed
   - Current stage label updates automatically

## Multi-Account Support

The implementation properly handles multiple account instances:

1. **Stage Filtering**: Only shows stages that belong to the task's account
   - Query filters by `account_id` in `project_task_type_app` table
   - Ensures stages from different accounts don't mix

2. **Validation**: Verifies both task and stage belong to the same account
   - Prevents cross-account stage assignment
   - Provides clear error messages if validation fails

3. **Global Stages**: Only shows global stages (is_global=1)
   - Aligns with Odoo's stage model
   - Ensures proper stage availability

## Database Schema Reference

### project_task_app
- `state INTEGER`: Stores the odoo_record_id of the current stage
- `account_id INTEGER`: Links task to account

### project_task_type_app
- `odoo_record_id INTEGER`: Unique identifier for the stage
- `account_id INTEGER`: Links stage to account
- `name TEXT`: Stage name
- `sequence INTEGER`: Display order
- `fold INTEGER`: Indicates if stage is closed/folded
- `is_global INTEGER`: Indicates if stage is available to all projects (1) or specific projects (0)

## User Interface

### Current Stage Display
- **Label**: "Current Stage: [Stage Name]"
- **Styling**: Bold text, green color for completed stages
- **Position**: Above the button row

### Button Row
- **Create Activity**: Left button (50% width)
- **Change Stage**: Right button (50% width)
- **Both buttons**: Only visible when viewing existing task

### Stage Selector Dialog
- **Title**: "Change Task Stage"
- **Current Stage**: Displayed at top with bold styling
- **Stage List**: Scrollable list with:
  - Stage name (bold if current)
  - Description (if available)
  - Fold status indicator
  - Orange highlight for current stage
  - Visual feedback on hover/press
- **Cancel Button**: Close dialog without changes

## Testing Recommendations

1. **Single Account Scenario**:
   - Open an existing task
   - Verify current stage is displayed correctly
   - Click "Change Stage" button
   - Verify all stages for the project are listed
   - Select a new stage and verify it updates

2. **Multiple Account Scenario**:
   - Create tasks in different accounts
   - Verify each task only shows stages from its own account
   - Try changing stages across accounts to verify validation

3. **Edge Cases**:
   - Task with no stage set (state = null)
   - Project with only one stage
   - Project with no stages
   - Completed/cancelled task stage changes

## Future Enhancements

Possible improvements for future versions:

1. **Project-Specific Stages**: Add support for stages that are specific to certain projects (is_global=0)
2. **Stage Workflow**: Add validation to prevent invalid stage transitions
3. **Bulk Stage Update**: Allow changing stage for multiple tasks at once
4. **Stage Change History**: Track when and who changed the stage
5. **Automatic Actions**: Trigger actions when stage changes (e.g., send notifications)

## Files Modified

1. `/home/suraj/timemanagement/models/task.js` - Added stage management functions
2. `/home/suraj/timemanagement/qml/Tasks.qml` - Added UI elements and stage change logic
3. `/home/suraj/timemanagement/qml/components/TaskStageSelector.qml` - NEW dialog component

## Dependencies

- QtQuick 2.12
- QtQuick.Controls 2.2
- Lomiri.Components 1.3
- Lomiri.Components.Popups 1.3
- Existing task.js functions (getTaskStageName, getTaskDetails)
- Existing utils.js functions (getFormattedTimestampUTC)
