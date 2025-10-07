# TaskStageSelector Fix - PopupUtils.open() Error Resolution

## Problem
The application was throwing an error:
```
qml: PopupUtils.open(): TaskStageSelector_QMLTYPE_265(0x5d2a70835130) is not a component or a link
```

## Root Cause
The `TaskStageSelector` was being used directly as an instantiated object, but `PopupUtils.open()` requires a Component definition, not an instantiated Dialog.

## Solution Applied

### 1. Wrapped TaskStageSelector in a Component (Tasks.qml)

**Before:**
```qml
TaskStageSelector {
    id: taskStageSelector
    onStageSelected: {
        handleStageChange(stageOdooRecordId, stageName);
    }
}
```

**After:**
```qml
Component {
    id: taskStageSelector
    TaskStageSelector {
        onStageSelected: {
            handleStageChange(stageOdooRecordId, stageName);
        }
    }
}
```

### 2. Updated Dialog Opening Method (Tasks.qml)

**Before:**
```qml
taskStageSelector.openDialog(
    currentTask.id,
    currentTask.project_id,
    currentTask.account_id,
    currentTask.state || -1
);
```

**After:**
```qml
var dialog = PopupUtils.open(taskStageSelector, taskCreate, {
    taskId: currentTask.id,
    projectOdooRecordId: currentTask.project_id,
    accountId: currentTask.account_id,
    currentStageOdooRecordId: currentTask.state || -1
});
```

### 3. Refactored TaskStageSelector.qml

**Changes:**
- Removed `openDialog()` function
- Added `loadStages()` function to load stages internally
- Added `Component.onCompleted` to automatically load stages when dialog is created
- Properties are now set via the object initializer in `PopupUtils.open()`

**Before:**
```qml
function openDialog(taskId, projectOdooRecordId, accountId, currentStageOdooRecordId) {
    stageSelectorDialog.taskId = taskId;
    stageSelectorDialog.projectOdooRecordId = projectOdooRecordId;
    stageSelectorDialog.accountId = accountId;
    stageSelectorDialog.currentStageOdooRecordId = currentStageOdooRecordId;
    
    // Load stages...
    
    PopupUtils.open(stageSelectorDialog);
}
```

**After:**
```qml
function loadStages() {
    // Load available stages for this project and account
    availableStages = Task.getTaskStagesForProject(projectOdooRecordId, accountId);
    
    // Update the stage list model...
}

Component.onCompleted: {
    loadStages();
}
```

## How It Works Now

1. **Component Definition**: `TaskStageSelector` is wrapped in a `Component` in Tasks.qml
2. **Property Initialization**: When `PopupUtils.open()` is called, it creates a new instance and initializes the properties
3. **Auto-Loading**: `Component.onCompleted` triggers automatically, calling `loadStages()`
4. **Signal Handling**: The `onStageSelected` signal handler remains the same and calls `handleStageChange()`

## Technical Details

### PopupUtils.open() Signature
```qml
PopupUtils.open(component, parent, properties)
```
- `component`: Component definition (not an instantiated object)
- `parent`: Parent item for the dialog
- `properties`: Object containing property values to initialize

### Property Binding
Properties passed in the third parameter are automatically bound to the component instance:
```qml
{
    taskId: currentTask.id,
    projectOdooRecordId: currentTask.project_id,
    accountId: currentTask.account_id,
    currentStageOdooRecordId: currentTask.state || -1
}
```

## Testing Checklist

✓ Component wrapping applied
✓ PopupUtils.open() call updated
✓ Property initialization working
✓ Auto-loading on Component.onCompleted
✓ Files compiled successfully
✓ TaskStageSelector.qml installed to build directory

## Files Modified

1. **Tasks.qml**
   - Wrapped TaskStageSelector in Component
   - Updated dialog opening to use PopupUtils.open()
   - Added property initialization object

2. **TaskStageSelector.qml**
   - Removed openDialog() method
   - Added loadStages() method
   - Added Component.onCompleted handler
   - Updated documentation comments

## Expected Behavior

1. User clicks "Change Stage" button
2. `PopupUtils.open()` creates a new TaskStageSelector instance
3. Properties are automatically set (taskId, projectOdooRecordId, accountId, currentStageOdooRecordId)
4. `Component.onCompleted` fires and calls `loadStages()`
5. Dialog displays with stage list populated
6. User selects stage → `onStageSelected` signal emits → `handleStageChange()` called
7. Dialog closes and stage is updated

## Notes

- This is the standard pattern for using Lomiri/Ubuntu Touch Dialogs
- Component wrapping allows PopupUtils to manage dialog lifecycle
- Property initialization via object literal is cleaner than method calls
- Auto-loading ensures stages are ready when dialog appears
