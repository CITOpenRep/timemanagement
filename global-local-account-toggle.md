# Implementation Plan: Global Local Account Toggle

## 1. Overview
Add a dedicated `Switch` control to the menu header in both desktop (`MenuPage.qml`) and mobile (`AppDrawer.qml`) layouts to enable instant global switching between the Local Account (`accountId = 0`) and the previously active or default remote account (`accountId > 0`).

---

## 2. Requirements & Behavior
1. **Control Type**: Dedicated compact `Switch` component styled cleanly in the header.
2. **Placement**: Placed adjacent to the account selector button in both `qml/app/navigation/MenuPage.qml` and `qml/app/AppDrawer.qml`.
3. **Toggle ON (Checked)**:
   - Switches the global application account to `0` ("Local Account").
   - Triggers `rootApp.globalAccountChanged(0, "Local Account")` and `rootApp.accountDataRefreshRequested(0)`.
4. **Toggle OFF (Unchecked)**:
   - Restores the previously active remote account (`lastRemoteAccountId`).
   - If no previous remote account was used in the session, falls back to the default account selected in settings (`is_default = 1` where `id > 0`), or the first available remote account.
5. **Bidirectional Synchronization**:
   - `Switch.checked` reflects `accountPicker.selectedAccountId === 0`.
   - When the user selects "Local Account" via `AccountSelectorDialog`, `Switch` turns ON automatically.
   - When the user selects a remote account (e.g. "CIT") via `AccountSelectorDialog`, `Switch` turns OFF automatically and records that remote account as `lastRemoteAccountId`.
6. **Account Label Clickability**:
   - The account selector label remains clickable at all times.

---

## 3. Architecture & File Changes

### Task 1: Remote Account Memory Helper
* **File**: `models/accounts.js`
* **Action**: Add `getDefaultRemoteAccountId()` helper to find the default remote account (`id > 0` and `is_default = 1`) or first remote account (`id > 0`).

### Task 2: State Tracking & Switch Logic in Global Context
* **File**: `qml/components/dialogs/AccountSelectorDialog.qml` and `qml/app/GlobalWidgets.qml`
* **Action**:
  - Add `property int lastRemoteAccountId` initialized to `Accounts.getDefaultRemoteAccountId()`.
  - In `accountPicker.onAccepted` (or inside dialog): if `id > 0`, update `lastRemoteAccountId = id`.
  - Add a helper method `switchToLocalMode(bool enableLocal)` to execute the toggle transition cleanly.

### Task 3: Header Toggle in Desktop View
* **File**: `qml/app/navigation/MenuPage.qml`
* **Action**:
  - Add the `Switch` component in the header `RowLayout` beside the account selector button.
  - Bind `checked: typeof accountPicker !== "undefined" && accountPicker.selectedAccountId === 0`.
  - Handle toggle action to switch between local and remote mode.

### Task 4: Header Toggle in Mobile Drawer View
* **File**: `qml/app/AppDrawer.qml`
* **Action**:
  - Mirror the `Switch` component in the drawer header `RowLayout` with identical bindings and behaviors.

### Task 5: Verification & Regression Testing
* **Action**:
  - Test toggling ON switches app to Local Account (tasks, projects, dashboard update).
  - Test toggling OFF restores the previous remote account (e.g. "CIT").
  - Test opening `AccountSelectorDialog` and choosing an account updates the switch.
  - Run lint and full project checklist (`python3 .agent/scripts/checklist.py .`).

---

## 4. Verification Criteria
- [ ] Toggling ON sets global account to 0 ("Local Account") across all pages.
- [ ] Toggling OFF restores the last active remote account.
- [ ] Selecting an account in the dialog keeps the toggle in sync.
- [ ] Header layout in both desktop and mobile drawer remains visually balanced without overflow or clipping.
- [ ] No regression on remote or local synchronization and data queries.
