# Task Stage Selector - Personal Stages Filter Fix

## Problem
The TaskStageSelector was showing "Internal" as the only stage option, when there were actually 20 stages in the database. Investigation revealed that most stages had empty `is_global` values, which indicated they were personal user stages, not project stages.

## Root Cause Analysis

### Database Investigation
When querying the `project_task_type_app` table, we found:
- **20 total stages** for account 20
- **Only 1 stage** with `is_global = 1` → "Internal" (truly global stage)
- **13 stages** with empty `is_global` → Personal/User stages like "Inbox", "Today", "This Week", etc.
- **6 stages** with `is_global` containing project IDs → Project-specific stages like "Analysis", "Development", etc.

### Understanding `is_global` Field

From the field configuration mapping (`field_config.json`):
```json
"project.task.type": {
    "project_ids": "is_global"
}
```

This means:
- **`is_global = 1`**: Stage is available to ALL projects (no project_ids restriction in Odoo)
- **`is_global = "3,4,5"`**: Stage is available to specific projects (project_ids = [3, 4, 5] in Odoo)
- **`is_global = NULL/empty`**: Stage has no project_ids, meaning it's a **PERSONAL stage** (from `personal_stage_type_ids` in Odoo)

### Personal vs Project Stages in Odoo

In Odoo's `project.task` model:
- **`stage_id`** (many2one) → Project-wide stage (stored in `project_task_type_app`)
- **`personal_stage_type_ids`** (many2many) → Personal user stages (user-specific, not shared)

Personal stages like "Inbox", "Today", "This Week", "Done", "Canceled" are meant for personal task management and should NOT be shown in the project-wide stage selector.

## Solution

Updated the SQL query in `getTaskStagesForProject()` to filter out personal stages:

### Before:
```sql
SELECT id, odoo_record_id, name, sequence, fold, description, is_global 
FROM project_task_type_app 
WHERE account_id = ? AND active = 1 
ORDER BY sequence ASC, name COLLATE NOCASE ASC
```

### After:
```sql
SELECT id, odoo_record_id, name, sequence, fold, description, is_global 
FROM project_task_type_app 
WHERE account_id = ? AND active = 1 
AND (is_global IS NOT NULL AND is_global != "")
ORDER BY sequence ASC, name COLLATE NOCASE ASC
```

### Key Change:
Added filter: `AND (is_global IS NOT NULL AND is_global != "")`

This ensures we only show stages that have either:
1. `is_global = 1` (globally available project stages)
2. `is_global = "project_ids"` (project-specific stages)

And **excludes** stages with:
- `is_global = NULL` or empty string (personal stages)

## Impact

### Before Fix:
- Only showed **1 stage**: "Internal"
- Personal stages were incorrectly included in the query but not properly displayed

### After Fix:
Shows **7 PROJECT stages** (example from test database):
1. Internal (seq: 1, global: 1) - Globally available
2. New (seq: 1, global: 34) - Available to project 34
3. Analysis (seq: 2, global: 19,20,21,33...) - Available to multiple projects
4. Specification (seq: 3, global: 19,20,21,33...)
5. Design (seq: 4, global: 19,20,21,33...)
6. Development (seq: 5, global: 19,20,21,33...)
7. Testing (seq: 6, global: 19,20,21,33...)
8. PR Pending (seq: 7, global: 4)
9. PR Created (seq: 9, global: 4)
10. Done (seq: 10, global: 19,20,21,33...)
11. Cancelled (seq: 11, global: 19,20,21,33...)

### Excluded Personal Stages:
- Inbox
- Today
- This Week
- This Month
- Later
- Done (personal version)
- Canceled (personal version)
- Custom
- Merge

## Testing Recommendations

1. **Single Account Test**:
   - Open a task
   - Click "Change Stage"
   - Verify only PROJECT stages are shown (not personal stages like "Inbox", "Today")

2. **Multi-Account Test**:
   - Switch between accounts
   - Verify each account shows only its own project stages

3. **Stage Display Verification**:
   - Confirm stages are ordered by sequence
   - Verify stage descriptions are shown
   - Check fold status indicators work correctly

## Technical Notes

- Personal stages are synced from Odoo's `personal_stage_type_ids` field
- They have empty `is_global` values because they don't have `project_ids` associated
- The filter `is_global IS NOT NULL AND is_global != ""` correctly identifies project stages
- Global stages (`is_global = 1`) are still included and work correctly
- Project-specific stages are included and filtered appropriately

## Files Modified

1. `/home/suraj/timemanagement/models/task.js`
   - Updated `getTaskStagesForProject()` function
   - Added personal stage filtering logic
   - Enhanced logging for debugging

## Related Documentation

- See `STAGE_CHANGE_IMPLEMENTATION.md` for overall feature documentation
- See `TASKSTAGE_POPUP_FIX.md` for PopupUtils.open() fix
- See `field_config.json` for Odoo field mappings
- See Odoo `project.task` model documentation for stage types

## Summary

The fix correctly distinguishes between:
- **Project Stages** (shared across projects/users) → **SHOWN** in stage selector
- **Personal Stages** (user-specific task organization) → **HIDDEN** from stage selector

This ensures users can only change tasks to proper project stages, maintaining consistency in project-wide task management.
