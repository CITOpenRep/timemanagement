# Task Stage Change Feature - Quick Start Guide

## What's New?

You can now change the stage of a task directly from the Task form view!

## Location

**File**: Tasks.qml (Task Detail/Form View)

## New UI Elements

### 1. Current Stage Display
```
┌─────────────────────────────────────────────────────┐
│ Current Stage:    In Progress                       │
│ (label)          (current stage name - bold)        │
└─────────────────────────────────────────────────────┘
```
- Located above the button row
- Shows the current task stage in bold
- Green color for completed stages

### 2. Change Stage Button
```
┌────────────────────────┬───────────────────────────┐
│   Create Activity      │      Change Stage         │
└────────────────────────┴───────────────────────────┘
```
- Located next to "Create Activity" button
- Equal width buttons (50% each)

### 3. Stage Selector Dialog
```
╔═══════════════════════════════════════════════╗
║           Change Task Stage                   ║
╠═══════════════════════════════════════════════╣
║ Current Stage: In Progress                    ║
║                                               ║
║ Select New Stage:                             ║
║                                               ║
║ ┌───────────────────────────────────────────┐ ║
║ │ ▌New                                      │ ║
║ │   (No description)                        │ ║
║ ├───────────────────────────────────────────┤ ║
║ │ ▌In Progress  ◄ (Current - Orange)       │ ║
║ │   Work is in progress                     │ ║
║ ├───────────────────────────────────────────┤ ║
║ │ ▌In Review                                │ ║
║ │   Waiting for review                      │ ║
║ ├───────────────────────────────────────────┤ ║
║ │ ▌Done                                     │ ║
║ │   Task completed                          │ ║
║ │   (Folded/Closed Stage)                   │ ║
║ └───────────────────────────────────────────┘ ║
║                                               ║
║              [ Cancel ]                       ║
╚═══════════════════════════════════════════════╝
```

## How to Use

### Step 1: Open an Existing Task
- Navigate to Tasks view
- Open an existing task (not in creation mode)
- You'll see the "Current Stage" label and "Change Stage" button

### Step 2: Click "Change Stage" Button
- The Stage Selector Dialog will open
- Shows all available stages for the task's project

### Step 3: Select New Stage
- Click on any stage (except the current one)
- Current stage is highlighted with orange border
- Cannot re-select the current stage

### Step 4: Stage Updates
- Dialog closes automatically
- Task stage is updated in database
- "Current Stage" label refreshes
- Success notification appears

## Multi-Account Support

✓ Each task shows only stages from its own account  
✓ Stages from different accounts don't mix  
✓ Proper validation prevents cross-account issues

## Code Flow

```
User Action → Change Stage Button
              ↓
         TaskStageSelector Dialog Opens
              ↓
         Load stages via getTaskStagesForProject()
              ↓
         User Selects New Stage
              ↓
         updateTaskStage() validates & updates
              ↓
         Task Reloads → UI Updates → Notification
```

## Database Updates

When stage changes:
- `project_task_app.state` → Updated to new stage's odoo_record_id
- `project_task_app.status` → Set to "updated"
- `project_task_app.last_modified` → Current timestamp

## Key Features

✓ Visual current stage indicator  
✓ Account-specific stage filtering  
✓ Stage descriptions displayed  
✓ Fold status shown for closed stages  
✓ Prevents selecting current stage  
✓ Scrollable list for many stages  
✓ Success/error notifications  
✓ Automatic UI refresh  

## Example Scenarios

### Scenario 1: Move Task to Review
1. Open task (currently in "In Progress")
2. Click "Change Stage"
3. Select "In Review" from list
4. ✓ Stage changes, notification shows success

### Scenario 2: Mark Task Complete
1. Open task (currently in "In Review")
2. Click "Change Stage"
3. Select "Done" from list
4. ✓ Stage changes to Done (green label)

### Scenario 3: Multiple Accounts
1. User has Account A and Account B
2. Open task from Account A
3. Click "Change Stage"
4. ✓ Only sees stages from Account A
5. Cannot accidentally assign Account B stages

## Files Modified

```
models/task.js
  + getTaskStagesForProject()
  + updateTaskStage()

qml/Tasks.qml
  + TaskStageSelector component
  + handleStageChange() function
  + Current Stage display row
  + Modified button row

qml/components/TaskStageSelector.qml (NEW)
  + Complete dialog implementation
```

## Technical Notes

- Stage filtering uses `account_id` and `is_global=1`
- Stages ordered by `sequence` field
- Current stage identified by `odoo_record_id` match
- Error handling for missing data
- Proper validation prevents invalid updates
