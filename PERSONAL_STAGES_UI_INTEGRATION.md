# Personal Stages UI Integration - Completed

## Implementation Summary

Successfully integrated personal stage functionality into the Tasks.qml form. Users can now view and change personal stages for existing tasks.

## Changes Made to Tasks.qml

### 1. PersonalStageSelector Component Import (Lines 260-267)

Added the PersonalStageSelector component declaration:

```qml
Component {
    id: personalStageSelector
    PersonalStageSelector {
        onPersonalStageSelected: {
            handlePersonalStageChange(personalStageOdooRecordId, personalStageName);
        }
    }
}
```

### 2. Personal Stage Change Handler (Lines 289-307)

Added `handlePersonalStageChange()` function to handle personal stage updates:

```qml
function handlePersonalStageChange(personalStageOdooRecordId, personalStageName) {
    if (!currentTask || !currentTask.id) {
        notifPopup.open("Error", "Task data not available", "error");
        return;
    }

    var result = Task.updateTaskPersonalStage(currentTask.id, personalStageOdooRecordId, currentTask.account_id);
    
    if (result.success) {
        currentTask.personal_stage = personalStageOdooRecordId;
        loadTask();
        
        var message = personalStageOdooRecordId === null ? 
            "Personal stage cleared" : 
            "Personal stage changed to: " + personalStageName;
        notifPopup.open("Success", message, "success");
    } else {
        notifPopup.open("Error", "Failed to change personal stage: " + (result.error || "Unknown error"), "error");
    }
}
```

### 3. Current Personal Stage Display (Lines 668-703)

Added a row to display the current personal stage:

```qml
Row {
    id: currentPersonalStageRow
    visible: recordid !== 0
    anchors.top: currentStageRow.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: units.gu(1)
    anchors.rightMargin: units.gu(1)
    topPadding: units.gu(1)
    
    TSLabel {
        text: "Personal Stage:"
        width: parent.width * 0.25
        anchors.verticalCenter: parent.verticalCenter
    }
    
    Label {
        text: {
            if (!currentTask || !currentTask.personal_stage || currentTask.personal_stage === -1) {
                return "(Not set)";
            }
            return Task.getTaskStageName(currentTask.personal_stage);
        }
        width: parent.width * 0.75
        font.pixelSize: units.gu(2)
        font.bold: currentTask && currentTask.personal_stage && currentTask.personal_stage !== -1
        font.italic: !currentTask || !currentTask.personal_stage || currentTask.personal_stage === -1
        color: {
            if (!currentTask || !currentTask.personal_stage || currentTask.personal_stage === -1) {
                return theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#888" : "#666";
            }
            return LomiriColors.blue;
        }
        anchors.verticalCenter: parent.verticalCenter
        wrapMode: Text.WordWrap
    }
}
```

**Features:**
- Shows "(Not set)" in gray/italic when no personal stage is assigned
- Shows personal stage name in **blue** and **bold** when assigned
- Appears below the regular stage display
- Only visible for existing tasks (recordid !== 0)

### 4. "Change Personal Stage" Button (Lines 753-789)

Added a new row with a full-width button to change personal stage:

```qml
Row {
    id: myRow83
    anchors.top: myRow82.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: units.gu(1)
    anchors.rightMargin: units.gu(1)
    spacing: units.gu(1)
    topPadding: units.gu(1)
    
    TSButton {
        visible: recordid !== 0
        width: parent.width
        text: "Change Personal Stage"
        color: LomiriColors.blue
        onClicked: {
            if (!currentTask || !currentTask.id) {
                notifPopup.open("Error", "Task data not available", "error");
                return;
            }
            
            var userId = Accounts.getCurrentUserOdooId(currentTask.account_id);
            if (userId <= 0) {
                notifPopup.open("Error", "Unable to determine current user", "error");
                return;
            }
            
            // Open the personal stage selector dialog with parameters
            var dialog = PopupUtils.open(personalStageSelector, taskCreate, {
                taskId: currentTask.id,
                accountId: currentTask.account_id,
                userId: userId,
                currentPersonalStageOdooRecordId: currentTask.personal_stage || -1
            });
        }
    }
}
```

**Features:**
- Full-width blue button (distinguishes from orange project stage button)
- Gets current user from Accounts.getCurrentUserOdooId()
- Opens PersonalStageSelector dialog with proper parameters
- Only visible for existing tasks (recordid !== 0)
- Positioned below "Create Activity" and "Change Stage" buttons

### 5. Layout Adjustments

Updated the anchor chain:
- `currentStageRow` → shows project stage (existing)
- `currentPersonalStageRow` → shows personal stage (NEW)
- `myRow82` → "Create Activity" and "Change Stage" buttons (existing, now anchored to currentPersonalStageRow)
- `myRow83` → "Change Personal Stage" button (NEW)
- `plannedh_row` → planned hours field (existing, now anchored to myRow83)

## UI Design Choices

### Color Scheme
- **Project Stages**: Orange theme (LomiriColors.orange) - existing
- **Personal Stages**: Blue theme (LomiriColors.blue) - new
- Clear visual distinction between the two stage types

### Layout Position
Personal stage elements positioned immediately after project stage elements to show their relationship:
1. Current Stage (project) - orange
2. Current Personal Stage - blue
3. Change Stage button (project) - half-width, orange
4. Change Personal Stage button - full-width, blue

### Text Styling
- **Set personal stage**: Bold blue text
- **Unset personal stage**: Italic gray text "(Not set)"
- Consistent with how project stages are displayed

## User Flow

### Viewing Personal Stage
1. Open an existing task in read mode
2. See "Personal Stage:" label with current value
3. If not set, shows "(Not set)" in gray italic
4. If set, shows stage name in blue bold

### Changing Personal Stage
1. Click "Change Personal Stage" button (blue, full-width)
2. PersonalStageSelector dialog opens
3. Shows current personal stage highlighted in blue
4. Lists all available personal stages for the user
5. Includes "(Clear Personal Stage)" option at top
6. Select new stage or clear
7. Dialog closes, success notification appears
8. Personal stage display updates immediately

## Testing Completed

✅ Build successful: `clickable build --arch all`
✅ Application launches: `clickable desktop`
✅ No new compilation errors introduced
✅ Pre-existing QML warnings unrelated to our changes

## Files Modified

1. **qml/Tasks.qml** - Added personal stage UI components
   - PersonalStageSelector component declaration
   - handlePersonalStageChange() function
   - currentPersonalStageRow display
   - myRow83 with "Change Personal Stage" button
   - Layout anchor adjustments

## Files Created

1. **qml/components/PersonalStageSelector.qml** - Personal stage selector dialog
2. **models/task.js** - Added personal stage functions:
   - getPersonalStagesForUser()
   - updateTaskPersonalStage()
   - Updated saveOrUpdateTask()
   - Updated getTaskDetails()
3. **models/dbinit.js** - Added personal_stage field to database
4. **field_config.json** - Added personal_stage_id mapping

## Next Steps (Optional Enhancements)

### For Task Creation Mode
If you want to add personal stage selection during task creation (not just for existing tasks):

1. Add a personal stage ComboBox in the creation form
2. Load personal stages when account is selected
3. Include selectedPersonalStageOdooRecordId in saveTask() data
4. Similar to how stage selection works during creation

### For MyTasks Page
Consider adding personal stage filtering to MyTasks.qml:
- Filter by personal stage
- Show personal stage column in task list
- Quick personal stage change from list view

## Technical Notes

- Personal stages are user-specific (is_global = '[]')
- Independent from project stages (can have both)
- Stored in same table as project stages (project_task_type_app)
- Blue theme consistently distinguishes personal from project elements
- Full-width button provides better touch target for mobile devices
