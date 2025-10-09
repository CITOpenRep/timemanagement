# Personal Stages Implementation

## Overview
Implemented support for personal stages in the Time Management app. Personal stages allow users to track their own workflow independently from project stages.

## Database Changes

### field_config.json
Added mapping for Odoo's personal_stage_id field:
```json
"personal_stage_id": "personal_stage"
```

### dbinit.js
Added `personal_stage INTEGER` field to project_task_app table:
- Stores the odoo_record_id of the personal stage
- Can be NULL when no personal stage is set
- Independent from the `state` field (project stage)

## Backend Functions (task.js)

### New Functions Added:

1. **getPersonalStagesForUser(userId, accountId)**
   - Retrieves all personal stages for a specific user
   - Personal stages identified by `is_global = '[]'` in project_task_type_app
   - Returns array of stage objects with odoo_record_id, name, sequence, fold

2. **updateTaskPersonalStage(taskId, personalStageOdooRecordId, accountId)**
   - Updates the personal_stage field of a task
   - Validates that the task exists and belongs to the account
   - Validates that the personal stage exists and is_global = '[]'
   - Sets status = "updated" for sync
   - Can accept null to clear the personal stage

### Modified Functions:

1. **saveOrUpdateTask(data)**
   - Added personal_stage to INSERT statement
   - Added personal_stage to UPDATE statement
   - Accepts data.personalStageOdooRecordId parameter (optional)

2. **getTaskDetails(task_id)**
   - Added personal_stage to returned task object
   - Returns null if no personal stage is set

## UI Component

### PersonalStageSelector.qml (NEW)
A popup dialog for selecting and changing personal task stages.

**Features:**
- Lists all personal stages for the current user
- Shows current personal stage with blue indicator
- Includes "(Clear Personal Stage)" option
- Independent from project stage selector
- Blue theme to distinguish from orange project stages

**Usage:**
```qml
Component {
    id: personalStageSelector
    PersonalStageSelector {
        onPersonalStageSelected: {
            // Handle personal stage change
            var result = Task.updateTaskPersonalStage(taskId, personalStageOdooRecordId, accountId);
            if (result.success) {
                // Refresh task details
            }
        }
    }
}

// Open dialog
PopupUtils.open(personalStageSelector, parentPage, {
    taskId: taskLocalId,
    accountId: accountId,
    userId: currentUserOdooId,
    currentPersonalStageOdooRecordId: currentPersonalStageId
})
```

## Next Steps - UI Integration

### Tasks.qml Modifications Needed:

1. **Import PersonalStageSelector Component**
```qml
Component {
    id: personalStageSelector
    PersonalStageSelector {
        onPersonalStageSelected: {
            var result = Task.updateTaskPersonalStage(taskDetailObj.id, personalStageOdooRecordId, selectedAccountId);
            if (result.success) {
                console.log("Personal stage updated successfully");
                taskDetailObj = Task.getTaskDetails(taskDetailObj.id);
            } else {
                console.error("Failed to update personal stage:", result.error);
            }
        }
    }
}
```

2. **Add "Change Personal Stage" Button (Read-Only Mode)**
Add next to the existing "Change Stage" button:
```qml
TSButton {
    text: "Change Personal Stage"
    visible: !isReadOnly && taskDetailObj && taskDetailObj.id > 0
    onClicked: {
        var userId = Account.getCurrentUserOdooId(selectedAccountId);
        PopupUtils.open(personalStageSelector, taskPage, {
            taskId: taskDetailObj.id,
            accountId: selectedAccountId,
            userId: userId,
            currentPersonalStageOdooRecordId: taskDetailObj.personal_stage || -1
        });
    }
}
```

3. **Display Current Personal Stage**
Add a label showing the current personal stage (if set):
```qml
Row {
    spacing: units.gu(1)
    visible: !isReadOnly && taskDetailObj.personal_stage
    
    Label {
        text: "Personal Stage:"
        font.bold: true
    }
    
    Label {
        text: Task.getTaskStageName(taskDetailObj.personal_stage)
        color: LomiriColors.blue
    }
}
```

4. **Add Personal Stage ComboBox (Creation Mode)**
Add a personal stage selector in the task creation form, similar to the existing stage selector:
```qml
Row {
    spacing: units.gu(2)
    visible: isReadOnly
    
    TSComboBox {
        id: personalStageComboBox
        width: parent.width / 2 - units.gu(1)
        model: personalStageModel
        textRole: "name"
        enabled: selectedProjectId > 0
        
        onCurrentIndexChanged: {
            if (currentIndex >= 0) {
                selectedPersonalStageOdooRecordId = personalStageModel.get(currentIndex).odoo_record_id;
            }
        }
    }
}

ListModel {
    id: personalStageModel
}

// Add function to load personal stages
function loadPersonalStages() {
    personalStageModel.clear();
    var userId = Account.getCurrentUserOdooId(selectedAccountId);
    var stages = Task.getPersonalStagesForUser(userId, selectedAccountId);
    
    personalStageModel.append({
        odoo_record_id: -1,
        name: "(No Personal Stage)"
    });
    
    for (var i = 0; i < stages.length; i++) {
        personalStageModel.append(stages[i]);
    }
}
```

5. **Update saveTask() Function**
Include personal stage when saving:
```javascript
var data = {
    // ... existing fields ...
    personalStageOdooRecordId: selectedPersonalStageOdooRecordId > 0 ? selectedPersonalStageOdooRecordId : null,
    // ... rest of fields ...
};
```

## Key Design Decisions

1. **Independence**: Personal stages are completely independent from project stages
   - A task can have both a project stage and a personal stage
   - Clearing one does not affect the other

2. **User-Specific**: Personal stages belong to individual users
   - Filtered by is_global = '[]' in the database
   - Each user can have their own set of personal stages

3. **Optional**: Personal stages are optional
   - Tasks can exist without a personal stage
   - NULL in database means no personal stage assigned

4. **Color Coding**: 
   - Project stages use orange color (existing)
   - Personal stages use blue color (new) to distinguish them visually

5. **Sync Support**: 
   - Changes to personal_stage mark task as status = "updated"
   - Field mapped in field_config.json for Odoo sync
   - Supports Odoo's personal_stage_id field

## Testing Checklist

- [ ] Database migration works (personal_stage column added)
- [ ] Personal stages load correctly for user
- [ ] Can select personal stage during task creation
- [ ] Can change personal stage on existing task
- [ ] Can clear personal stage (set to NULL)
- [ ] Personal stage appears in task details
- [ ] Personal stage syncs to Odoo correctly
- [ ] Personal stage is independent from project stage
- [ ] Empty state shows when no personal stages available
- [ ] UI distinguishes between project and personal stages (orange vs blue)

## Odoo Field Information

The implementation uses the following Odoo fields:
- **personal_stage_id** (many2one): Current personal stage - THIS IS WHAT WE IMPLEMENTED
- **personal_stage_type_ids** (many2many): Not implemented yet (future: available personal stages)
- **personal_stage_type_id** (many2one): Not implemented yet (future: possibly related to template)

Personal stages in Odoo:
- Stored in same table as regular stages (project.task.type)
- Identified by empty is_global field (stored as '[]' in our database)
- User-specific workflow tracking independent from project stages
