# Account Drawer Implementation

## Overview

This implementation adds a top drawer to the Ubuntu Touch Time Management app that provides account selection and data synchronization functionality.

## Features

### 1. Account Selection
- **Dropdown Menu**: Choose from available accounts (local and remote Odoo accounts)
- **Default Account**: Automatically selects the default account on app startup
- **Account Switching**: Change accounts and automatically set as default

### 2. Data Synchronization
- **Sync Button**: Trigger data synchronization for the selected account
- **Progress Indicator**: Shows step-by-step sync progress with detailed status
- **Sync Status**: Displays last sync timestamp
- **Local Account Support**: Handles local accounts (no sync required)

### 3. User Interface
- **Top Drawer**: Swipe down from top of screen or tap account button
- **Modern Design**: Follows Ubuntu Touch design guidelines
- **Dark/Light Theme Support**: Adapts to current theme
- **Responsive Layout**: Works on different screen sizes

## How to Use

### Opening the Drawer
1. **Swipe Down**: Swipe down from the top edge of the screen
2. **Account Button**: Tap the account icon in the dashboard header
3. **Programmatic**: Call `mainView.openAccountDrawer()` from any page

### Selecting an Account
1. Open the drawer
2. Choose an account from the dropdown
3. The account is automatically set as default
4. App data refreshes for the new account

### Syncing Data
1. Select a remote account (not local)
2. Tap the "Sync Data" button
3. Watch the progress as data syncs step by step
4. Receive notification when sync completes

## Technical Implementation

### Components

#### AccountDrawer.qml
- Main drawer component with account selection and sync functionality
- Integrates with existing account management system
- Provides step-by-step sync progress

#### Integration Points
- **TSApp.qml**: Main app integration with gesture support
- **Dashboard.qml**: Account button in header
- **accounts.js**: Account management functions
- **utils.js**: Sync status functions

### Key Functions

#### Account Management
```javascript
// Load accounts from database
loadAccounts()

// Select default account
selectDefaultAccount()

// Set account as default
Accounts.setDefaultAccount(accountId)
```

#### Sync Process
```javascript
// Start sync process
startSync()

// Perform step-by-step sync
performSync()

// Handle sync completion
syncCompleted(success, message)
```

#### Data Refresh
```javascript
// Refresh app data after account change
refreshAppData()

// Refresh specific page data
page.refreshData()
```

### Gesture Support
- **Swipe Down**: Opens drawer from top edge
- **Touch Area**: 3 GU height at top of screen
- **Drag Detection**: Minimum 2 GU swipe distance

### Notifications
- **Success**: Sync completed successfully
- **Error**: Sync failed with error details
- **Info**: Account changes and status updates

## Database Integration

### Account Storage
- Uses existing `users` table
- `is_default` flag for default account
- Account details: name, link, database, username, api_key

### Sync Status
- `sync_report` table for sync history
- Timestamp tracking for last sync
- Status messages for sync results

## Future Enhancements

### Real Sync Integration
- Connect to actual Python sync functions
- Support for bidirectional sync (to/from Odoo)
- Error handling for network issues

### Advanced Features
- Background sync scheduling
- Sync conflict resolution
- Offline mode support
- Sync filters and options

### UI Improvements
- Animated drawer transitions
- Haptic feedback
- Custom sync progress indicators
- Account-specific settings

## Testing

### Manual Testing
1. Create multiple accounts
2. Test account switching
3. Verify sync progress display
4. Check gesture recognition
5. Test theme compatibility

### Automated Testing
- Unit tests for account functions
- Integration tests for sync process
- UI tests for drawer interactions

## Troubleshooting

### Common Issues
- **Drawer not opening**: Check gesture area positioning
- **Sync not starting**: Verify account selection
- **Data not refreshing**: Check refreshData() implementation
- **Theme issues**: Verify color scheme compatibility

### Debug Information
- Console logs for account changes
- Sync progress tracking
- Error message display
- Database query logging
