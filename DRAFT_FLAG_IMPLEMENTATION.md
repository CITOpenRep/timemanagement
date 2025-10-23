# Adding `has_draft` Flag to Tasks and Timesheets

## Overview
This document describes how to add a `has_draft` boolean flag to track when tasks/timesheets have unsaved form drafts.

## Database Schema Changes

### 1. Update `project_task_app` table (Tasks)
```javascript
// In models/dbinit.js
DBCommon.createOrUpdateTable("project_task_app",
    'CREATE TABLE IF NOT EXISTS project_task_app (\
        ...existing fields...\
        has_draft INTEGER DEFAULT 0,\
        ...\
    )',
    [...existing columns..., 'has_draft INTEGER DEFAULT 0']
);
```

### 2. Update `account_analytic_line_app` table (Timesheets)
```javascript
// In models/dbinit.js
DBCommon.createOrUpdateTable("account_analytic_line_app",
    'CREATE TABLE IF NOT EXISTS account_analytic_line_app (\
        ...existing fields...\
        has_draft INTEGER DEFAULT 0,\
        ...\
    )',
    [...existing columns..., 'has_draft INTEGER DEFAULT 0']
);
```

## Logic Changes

### 1. Set `has_draft = 1` when saving draft
```javascript
// In models/draft_manager.js - saveDraft() function

// After saving/updating form_drafts table, update the parent record
if (recordId && recordId > 0) {
    var tableName = (draftType === "task") ? "project_task_app" : 
                    (draftType === "timesheet") ? "account_analytic_line_app" : null;
    
    if (tableName) {
        tx.executeSql(
            "UPDATE " + tableName + " SET has_draft = 1 WHERE id = ?",
            [recordId]
        );
        console.log("✅ Set has_draft=1 for " + draftType + " #" + recordId);
    }
}
```

### 2. Clear `has_draft = 0` when clearing draft
```javascript
// In models/draft_manager.js - deleteDraft() function

// Before deleting from form_drafts, get the record info
var draftInfo = tx.executeSql(
    "SELECT draft_type, record_id FROM form_drafts WHERE id = ?",
    [draftId]
);

if (draftInfo.rows.length > 0) {
    var row = draftInfo.rows.item(0);
    var recordId = row.record_id;
    var draftType = row.draft_type;
    
    // Delete the draft
    tx.executeSql("DELETE FROM form_drafts WHERE id = ?", [draftId]);
    
    // Clear has_draft flag on parent record
    if (recordId && recordId > 0) {
        var tableName = (draftType === "task") ? "project_task_app" : 
                        (draftType === "timesheet") ? "account_analytic_line_app" : null;
        
        if (tableName) {
            tx.executeSql(
                "UPDATE " + tableName + " SET has_draft = 0 WHERE id = ?",
                [recordId]
            );
            console.log("✅ Cleared has_draft=0 for " + draftType + " #" + recordId);
        }
    }
}
```

### 3. Clear `has_draft = 0` when saving record successfully
```javascript
// In models/task.js - saveOrUpdateTask() function
db.transaction(function (tx) {
    if (data.record_id) {
        // UPDATE
        tx.executeSql('UPDATE project_task_app SET \
            ...all fields...\
            has_draft = 0 \
            WHERE id = ?',
            [...params..., data.record_id]
        );
    }
});

// In models/timesheet.js - saveTimesheet() function
db.transaction(function (tx) {
    tx.executeSql(`UPDATE account_analytic_line_app SET
        ...all fields...,
        has_draft = 0
        WHERE id = ?`,
        [...params..., data.id]
    );
});
```

## Usage Examples

### 1. Query tasks with drafts
```javascript
function getTasksWithDrafts(accountId) {
    var tasks = [];
    db.transaction(function(tx) {
        var result = tx.executeSql(
            "SELECT * FROM project_task_app WHERE account_id = ? AND has_draft = 1",
            [accountId]
        );
        for (var i = 0; i < result.rows.length; i++) {
            tasks.push(result.rows.item(i));
        }
    });
    return tasks;
}
```

### 2. Show draft indicator in list view
```qml
// In Tasks list view
ListItem {
    Label {
        text: modelData.name + (modelData.has_draft === 1 ? " •" : "")
    }
}
```

### 3. Warn user about drafts
```javascript
function hasPendingDrafts(accountId) {
    var count = 0;
    db.transaction(function(tx) {
        var result = tx.executeSql(
            "SELECT COUNT(*) as count FROM project_task_app WHERE account_id = ? AND has_draft = 1",
            [accountId]
        );
        count = result.rows.item(0).count;
    });
    return count > 0;
}
```

## Migration Strategy

1. **Add columns** to both tables (will default to 0 for existing records)
2. **Update existing drafts**: Run one-time migration to set `has_draft=1` for records that have drafts in `form_drafts` table
3. **Update all save/draft functions** to maintain the flag
4. **Test thoroughly** to ensure flag is always accurate

## Benefits

✅ Fast queries for "records with drafts" (no JOIN needed)
✅ Visual indicators in list views
✅ Better user awareness of unsaved changes
✅ Consistent with UI convention (header shows "•" when has unsaved changes)

## Considerations

⚠️ **Data consistency**: Must ensure flag is always accurate
⚠️ **Migration**: Existing records need to be checked
⚠️ **Testing**: Test all code paths (save, discard, crash recovery)
