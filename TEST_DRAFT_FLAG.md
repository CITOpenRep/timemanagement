# Testing has_draft Flag Display

## Steps to Test:

### 1. Check Console Output
Run the app with `clickable desktop` and check the console for these debug messages:
- `TaskList - Setting hasDraft for task:` - Shows what value is being passed from TaskList
- `TaskDetailsCard - Task:` - Shows what value is received in TaskDetailsCard
- `TaskDetailsCard - has_draft from DB:` - Shows the actual database value

### 2. Manually Set has_draft Flag for Testing

Open the SQLite database and manually set a task's `has_draft` to 1:

```sql
-- Find a task to test with
SELECT id, name, has_draft FROM project_task_app LIMIT 5;

-- Set has_draft = 1 for testing (replace <task_id> with actual ID)
UPDATE project_task_app SET has_draft = 1 WHERE id = <task_id>;

-- Verify it was set
SELECT id, name, has_draft FROM project_task_app WHERE has_draft = 1;
```

### 3. Check if the Bullet Appears

After setting `has_draft = 1`, refresh the task list and look for the `•` bullet next to the task name.

### 4. Alternative: Create a Draft to Test

1. Open a task for editing
2. Make a change (e.g., edit the name or description)
3. Don't save - just wait for auto-save (5 minutes) or navigate away
4. Check if `has_draft` is set to 1 in the database
5. Return to the task list and see if the bullet appears

## Expected Behavior:

✅ Task with `has_draft = 0`: **"Task Name"**
✅ Task with `has_draft = 1`: **"Task Name •"**

## Debugging Issues:

If the bullet doesn't appear, check:
1. Is `has_draft` actually 1 in the database?
2. Are the debug console messages showing the correct value?
3. Is the value being passed from TaskList to TaskDetailsCard?
4. Is the Text element being re-rendered when hasDraft changes?
