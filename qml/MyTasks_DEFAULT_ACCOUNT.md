# MyTasks - Default Account Implementation

## Changes Made

### Summary
MyTasks page has been simplified to **ALWAYS use the DEFAULT account** set in the Settings page. It no longer responds to the account selector/filter and ignores account switching.

### Key Changes

1. **Removed Account Filtering**
   - `filterByAccount: false` in TaskList
   - Removed `selectedAccountId` tracking
   - Removed all account selection logic

2. **Always Use Default Account**
   - `updateCurrentUser()` now calls `Account.getDefaultAccountId()` directly
   - No longer checks `myTasksList.selectedAccountId`
   - No fallback logic needed

3. **Removed Account Change Listeners**
   - Deleted `Connections` for `accountFilter`
   - Deleted `Connections` for `mainView.onGlobalAccountChanged`
   - Deleted `Connections` for `mainView.onAccountDataRefreshRequested`

4. **Simplified Component.onCompleted**
   - Removed all account detection/selection logic
   - Directly uses `defaultAccountId` property
   - Cleaner initialization

## How It Works Now

```
MyTasks Page Opens
       ↓
Get Default Account ID from Settings (e.g., Account ID = 2)
       ↓
Get Current User for that account (e.g., User ID = 42)
       ↓
Apply Filter: filterByAssignees = true, selectedAssigneeIds = [42]
       ↓
Display Tasks Assigned to User 42 from Account 2 ✅
```

## User Workflow

### To View Tasks from Different Account:

1. **Open Settings Page**
2. **Check the "Default" checkbox** for the desired account
3. **Return to MyTasks**
4. MyTasks automatically shows tasks from the new default account

### Important Notes:

- ✅ MyTasks **IGNORES** the global account selector
- ✅ MyTasks **ONLY** uses the default account from Settings
- ✅ No account switching while viewing MyTasks
- ✅ Clean, predictable behavior

## Code Comparison

### BEFORE (Complex):
```javascript
// Tracked account selection from global filter
property variant selectedAccountId: -1
property int currentAccountId: -1

// Complex logic to determine account
function updateCurrentUser() {
    var accountId = myTasksList.selectedAccountId;
    if (accountId < 0) {
        accountId = Account.getDefaultAccountId();
        myTasksList.selectedAccountId = accountId;
    }
    currentAccountId = accountId;
    // ... more logic
}

// Multiple Connections listening to account changes
Connections { target: accountFilter; onAccountChanged: {...} }
Connections { target: mainView; onGlobalAccountChanged: {...} }
Connections { target: mainView; onAccountDataRefreshRequested: {...} }
```

### AFTER (Simple):
```javascript
// Only track default account
property int defaultAccountId: Account.getDefaultAccountId()

// Simple function - always uses default account
function updateCurrentUser() {
    var accountId = Account.getDefaultAccountId();
    console.log("🔍 MyTasks: Using DEFAULT account from Settings:", accountId);
    // ... rest of logic
}

// No Connections needed!
// Comment explains behavior instead
```

## Benefits

1. **Simpler Code**: Removed ~150 lines of account handling logic
2. **Clearer Behavior**: Users know MyTasks uses Settings default
3. **No Confusion**: Account selector doesn't affect MyTasks
4. **Consistent**: Always shows the same account's tasks until Settings changed
5. **Maintainable**: Less code to maintain and debug

## Testing

### Test Case 1: Default Account Usage
1. Open Settings
2. Set Account A as Default
3. Open MyTasks
4. **Expected**: Shows tasks from Account A assigned to current user

### Test Case 2: Ignores Account Selector
1. MyTasks is open showing Account A's tasks
2. Change account selector to Account B
3. **Expected**: MyTasks STILL shows Account A's tasks (ignores selector)

### Test Case 3: Change Default in Settings
1. MyTasks showing Account A's tasks
2. Go to Settings
3. Set Account B as Default
4. Return to MyTasks
5. **Expected**: Now shows Account B's tasks

## Console Output

### Expected on Page Load:
```
🚀 MyTasks: Component.onCompleted - Initial setup
📌 MyTasks: Using DEFAULT account from Settings
🔍 MyTasks: Using DEFAULT account from Settings: 2
✅ MyTasks: Current user odoo_record_id for account 2 is 42
✅ MyTasks: Setting up assignee filter with user ID: 42
🔎 DIAGNOSTIC: Found 5 tasks out of 20 total tasks assigned to user 42
✅ MyTasks: Filtering by current user: 42 from default account: 2
📋 MyTasks: Applying initial filter: today
```

## Related Files

- `/qml/MyTasks.qml` - Main page (simplified)
- `/qml/Settings_Page.qml` - Where default account is set
- `/models/accounts.js` - `getDefaultAccountId()` and `getCurrentUserOdooId()`

## Migration Notes

### For Users:
- No visible changes if they only have one account
- Multi-account users will see MyTasks consistently shows default account
- Need to use Settings to change which account's tasks are displayed

### For Developers:
- MyTasks is now independent of global account filtering
- If implementing similar "My X" pages, follow this pattern
- Default account is the source of truth for personal views
