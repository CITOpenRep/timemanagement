# Task Creation Stage Selector with Fallback Implementation

## Overview
Implemented a stage selector ComboBox for task creation that allows users to select a stage, with automatic fallback to the first stage if no selection is made.

## Implementation Details

### 1. User Interface (Tasks.qml)

#### Stage Selector ComboBox:
```qml
Row {
    id: stageRow
    visible: recordid === 0 // Only visible during task creation
    
    TSLabel {
        text: "Initial Stage"
    }
    
    ComboBox {
        id: stageComboBox
        model: stageListModel
        // Displays available stages for the selected project
    }
}
```

### 2. Stage Loading Logic

#### Function: `loadStagesForProject(projectOdooRecordId, accountId)`

**Behavior:**
- Loads stages specific to the selected project
- Automatically selects the **first stage** in the list as default
- User can change the selection using the ComboBox
- Filters out "Internal" stage and personal stages

**Code:**
```javascript
function loadStagesForProject(projectOdooRecordId, accountId) {
    var stages = Task.getTaskStagesForProject(projectOdooRecordId, accountId);
    stageListModel.clear();
    
    for (var i = 0; i < stages.length; i++) {
        stageListModel.append({
            odoo_record_id: stages[i].odoo_record_id,
            name: stages[i].name,
            sequence: stages[i].sequence,
            fold: stages[i].fold
        });
    }
    
    // Auto-select first stage as default
    if (stageListModel.count > 0) {
        stageComboBox.currentIndex = 0;
        var firstStage = stageListModel.get(0);
        selectedStageOdooRecordId = firstStage.odoo_record_id;
    }
}
```

### 3. Save Logic with Fallback

#### Function: `save_task_data()` - Stage Assignment

**Fallback Logic:**
1. Check if user selected a stage (`selectedStageOdooRecordId > 0`)
2. If not, use the first stage from `stageListModel` as fallback
3. Save task with the assigned stage

**Code:**
```javascript
if (recordid === 0) {
    var stageToAssign = selectedStageOdooRecordId;
    
    // Fallback to first stage if no stage selected
    if (stageToAssign <= 0 && stageListModel.count > 0) {
        var firstStage = stageListModel.get(0);
        stageToAssign = firstStage.odoo_record_id;
        console.log("Using fallback stage:", firstStage.name);
    }
    
    if (stageToAssign > 0) {
        saveData.stageOdooRecordId = stageToAssign;
    }
}
```

### 4. Automatic Stage Reloading

**Triggers:**
- When user selects an account
- When user selects a project
- When user selects a subproject

**Implementation:**
```javascript
onStateChanged: {
    if (recordid === 0) {
        if (newState === "AccountSelected" || 
            newState === "ProjectSelected" || 
            newState === "SubprojectSelected") {
            var ids = workItem.getIds();
            if (ids.project_id > 0 && ids.account_id > 0) {
                loadStagesForProject(ids.project_id, ids.account_id);
            }
        }
    }
}
```

## User Experience Flow

### Scenario 1: User Selects a Stage
1. User creates new task
2. Selects account and project
3. Stage ComboBox populates with available stages (first stage pre-selected)
4. User changes selection to different stage
5. User saves task
6. **Result:** Task is saved with user-selected stage

### Scenario 2: User Doesn't Change Default Stage
1. User creates new task
2. Selects account and project
3. Stage ComboBox populates with first stage auto-selected
4. User doesn't change the stage selection
5. User saves task
6. **Result:** Task is saved with the first stage (auto-selected)

### Scenario 3: System Fallback (Edge Case)
1. User creates new task
2. Selects account and project
3. First stage is auto-selected but `selectedStageOdooRecordId` becomes invalid/reset
4. User saves task
5. **Result:** System detects invalid selection and falls back to first stage from model

## Benefits

1. **User Flexibility:** Users can choose any available stage during task creation
2. **Smart Default:** First stage is automatically pre-selected for quick task creation
3. **Safety Fallback:** Even if selection is lost, system ensures a valid stage is assigned
4. **Project-Aware:** Only shows stages relevant to the selected project
5. **No Manual Intervention:** Works automatically without requiring extra user actions

## Technical Notes

- ComboBox is only visible during task creation (`recordid === 0`)
- For editing tasks, users must use the "Change Stage" button
- Stage filtering logic excludes:
  - "Internal" stage (hardcoded filter)
  - Personal stages (stages with `is_global = '[]'`)
  - Stages not available for the selected project
- First stage is determined by the `sequence` field in the database (lowest first)

## Testing

To test the feature:
1. Run `clickable desktop`
2. Create a new task
3. Select account and project
4. Verify ComboBox shows stages with first one selected
5. Option A: Keep default stage → Save → Check task has first stage
6. Option B: Change to different stage → Save → Check task has selected stage

## Console Logging

The implementation includes detailed logging:
- `"Loading stages for project: X account: Y"`
- `"Auto-selected first stage as default: NAME with odoo_record_id: ID"`
- `"User selected stage: NAME with odoo_record_id: ID"`
- `"Using fallback stage: NAME with odoo_record_id: ID"` (if fallback triggered)
- `"Saving task with stage: ID"`
