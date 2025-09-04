# Account Drawer Demo Guide

## Overview
This guide demonstrates the new Account Drawer functionality in the Ubuntu Touch Time Management app.

## Features Demonstrated

### 1. Account Selection
- **Multiple Accounts**: Support for local and remote Odoo accounts
- **Default Account**: Automatic selection of default account
- **Account Switching**: Easy switching between accounts

### 2. Data Synchronization
- **Sync Progress**: Step-by-step sync progress display
- **Local Account Handling**: Proper handling of local accounts
- **Sync Status**: Last sync timestamp display

### 3. User Interface
- **Popup Interface**: Modern popup-based interface
- **Theme Support**: Dark and light theme compatibility
- **Responsive Design**: Works on different screen sizes

## How to Test

### Step 1: Open the Account Drawer
1. **Method 1**: Swipe down from the top edge of the screen
2. **Method 2**: Tap the account icon in the dashboard header
3. **Method 3**: Programmatically call `mainView.openAccountDrawer()`

### Step 2: Test Account Selection
1. Open the drawer
2. Select different accounts from the dropdown
3. Verify that the current account display updates
4. Check that the account is set as default

### Step 3: Test Sync Functionality
1. Select a remote account (not local)
2. Tap the "Sync Data" button
3. Watch the progress bar and step-by-step sync display
4. Verify the success notification appears

### Step 4: Test Local Account
1. Select the "Local Account" (ID: 0)
2. Tap the "Sync Data" button
3. Verify that it shows "Local account - no sync required"

## Expected Behavior

### Account Selection
- Dropdown should show all available accounts
- Default account should be pre-selected
- Current account display should update immediately
- Account should be set as default when selected

### Sync Process
- Sync button should be enabled for remote accounts
- Progress bar should show step-by-step progress
- Sync steps should display: "Connecting to server...", "Syncing projects...", etc.
- Success notification should appear when complete

### Local Account
- Sync button should be enabled but show "Local account - no sync required"
- No actual sync process should run
- Info notification should appear

## Technical Details

### Files Modified
- `qml/components/AccountDrawer.qml` - Main drawer component
- `qml/TSApp.qml` - Main app integration
- `qml/Dashboard.qml` - Account button in header

### Key Functions
- `loadAccounts()` - Load accounts from database
- `selectDefaultAccount()` - Select default account
- `startSync()` - Start sync process
- `performSync()` - Execute sync steps
- `refreshAppData()` - Refresh app data after changes

### Database Integration
- Uses existing `users` table
- `is_default` flag for default account tracking
- `sync_report` table for sync history

## Troubleshooting

### Common Issues
1. **Drawer not opening**: Check if gesture area is properly positioned
2. **No accounts shown**: Verify database has accounts in `users` table
3. **Sync not working**: Check account selection and network connectivity
4. **Theme issues**: Verify color scheme compatibility

### Debug Information
- Console logs show account changes and sync progress
- Error messages display in notifications
- Database queries are logged for debugging

## Future Enhancements

### Planned Features
1. **Real Sync Integration**: Connect to actual Python sync functions
2. **Background Sync**: Automatic sync scheduling
3. **Sync Filters**: Selective data synchronization
4. **Conflict Resolution**: Handle sync conflicts
5. **Offline Mode**: Enhanced offline support

### UI Improvements
1. **Animated Transitions**: Smooth drawer animations
2. **Haptic Feedback**: Touch feedback for interactions
3. **Custom Progress**: Enhanced progress indicators
4. **Account Settings**: Per-account configuration

## Conclusion

The Account Drawer provides a modern, user-friendly interface for account management and data synchronization. It integrates seamlessly with the existing app architecture and provides a foundation for future enhancements.
