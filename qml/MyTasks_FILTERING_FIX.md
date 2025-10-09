# MyTasks Filtering Fix

## Problem
The MyTasks page was not filtering tasks by the logged-in user. All tasks were displayed regardless of assignee.

## Root Cause
The issue was traced to the account selection logic. When the MyTasks page loaded, it was initializing with `accountId = -1` (which represents "All Accounts"). 

**Why this breaks filtering:**
- The `getCurrentUserOdooId(accountId)` function requires a specific account ID to determine which user is logged in
- When `accountId = -1`, the function cannot determine the current user because each account has its own logged-in user
- Without a valid user ID, the assignee filter cannot work

## Console Evidence
```
qml: 🔍 MyTasks: updateCurrentUser called with accountId: -1
qml: ℹ️ MyTasks: All accounts selected, will filter by all current users
qml: ⚠️ MyTasks: Component.onCompleted - currentAccountId is invalid: -1
```

## Solution
Modified MyTasks.qml to **force a specific account selection** instead of allowing "All Accounts" (-1):

### Changes Made:

1. **Component.onCompleted** - Added fallback logic:
```javascript
// If "All Accounts" (-1) is selected, default to the default account
if (initialAccountNum < 0) {
    initialAccountNum = Account.getDefaultAccountId();
    console.log("⚠️ MyTasks: 'All Accounts' not supported, defaulting to account:", initialAccountNum);
}
```

2. **updateCurrentUser()** - Force account selection:
```javascript
// CRITICAL FIX: MyTasks doesn't support "All Accounts" (-1)
// Force to default account if -1
if (accountId < 0) {
    accountId = Account.getDefaultAccountId();
    myTasksList.selectedAccountId = accountId;
    console.log("⚠️ MyTasks: Forced account from -1 to default account:", accountId);
}
```

3. **Connections handlers** - Updated onAccountChanged and onGlobalAccountChanged:
```javascript
// If "All Accounts" selected, use default account instead
if (idNum < 0) {
    idNum = Account.getDefaultAccountId();
    console.log("⚠️ MyTasks: Account changed to 'All Accounts', forcing to default account:", idNum);
}
```

## Expected Behavior After Fix

When MyTasks page loads:
1. **Checks account selection** - If "All Accounts" (-1), switches to default account
2. **Gets current user ID** - Calls `getCurrentUserOdooId(accountId)` with valid account
3. **Sets up filtering** - `filterByAssignees = true` with current user's odoo_record_id
4. **Displays filtered tasks** - Only shows tasks assigned to the logged-in user

### Expected Console Output:
```
⚠️ MyTasks: 'All Accounts' not supported, defaulting to account: 0
MyTasks initial account selection (numeric): 0
🚀 MyTasks: Component.onCompleted - Initial setup
🔍 MyTasks: updateCurrentUser called with accountId: 0
✅ MyTasks: Current user odoo_record_id for account 0 is 1
✅ MyTasks: Setting up assignee filter with user ID: 1
🔎 DIAGNOSTIC: Found X tasks out of Y total tasks assigned to user 1
✅ MyTasks: Component.onCompleted - Filtering by current user: 1
📋 MyTasks: Component.onCompleted - Applying initial filter: today
```

## Design Rationale

**Why MyTasks doesn't support "All Accounts":**
- MyTasks is a **personal task view** showing only tasks for the logged-in user
- Each account has its own set of users with different credentials
- "All Accounts" mode would show tasks from multiple accounts with different users
- There's no way to determine "the current user" when viewing all accounts simultaneously

**Alternative approaches considered:**
1. Show tasks from all accounts for all users matching the username ❌ (Complex, confusing)
2. Support per-account filtering ❌ (Defeats purpose of "My Tasks")
3. Force default account ✅ (Simple, clear, works)

## Testing

To verify the fix works:

1. **Run the app:**
   ```bash
   clickable desktop
   ```

2. **Navigate to MyTasks page**

3. **Verify console shows:**
   - Account forced to specific ID (not -1)
   - User odoo_record_id retrieved successfully
   - Task count matches expected personal tasks

4. **Verify UI shows:**
   - Only tasks assigned to you
   - Account selector shows specific account (not "All Accounts")

5. **Test account switching:**
   - Switch to different account
   - Verify tasks update to show that account's user tasks

## Related Files

- `/qml/MyTasks.qml` - Main page (modified)
- `/models/accounts.js` - getCurrentUserOdooId() function
- `/models/task.js` - getTasksByAssigneesHierarchical() function
- `/qml/components/TaskList.qml` - Task list component

## Future Enhancements

Possible improvements:
1. **Add visual indicator** showing which user's tasks are displayed
2. **Quick account switcher** in MyTasks page header
3. **User avatar/name** in the header
4. **Task statistics** for current user (pending, completed, overdue)
