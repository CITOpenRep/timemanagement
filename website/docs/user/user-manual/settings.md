# Settings

The **Settings** section allows users to configure the application according to their preferences and manage system-level features such as connected accounts, notifications, synchronization, and appearance.

This section is especially useful for first-time users to personalize their experience and ensure the app works seamlessly with external systems.

---

## Accessing Settings
To open **Settings**:
1. Click on the **Menu (☰)** icon in the top-left corner.
2. Select **Settings** from the sidebar navigation.

The Settings screen is divided into multiple configurable sections.

---

## Settings Overview
The Settings module includes the following options:
1. Connected Accounts
2. Notifications
3. Background Sync
4. Theme Settings

Each option is explained in detail below.

---

## Connected Accounts
The **Connected Accounts** section allows users to link and manage multiple environments or instances (such as local, test, or production systems).

### Purpose:
* Enable integration with different servers or environments.
* Allow switching between multiple accounts.
* Manage synchronization across systems.

### Key Elements:
* **Account List**: Displays all configured accounts.
* **Account Type Indicator**: Shows whether it is Local or Server Instance.
* **Instance URL**: Displays the connected server link.
* **Status Indicator**:
    * *In Progress*: Sync or connection is ongoing.
    * *Successful*: Connection is active and working.
* **Sync Icon (🔄)**: Manually refresh or sync the account.
* **Checkbox Selector**: Activate or select a specific account.
* **Add Button (➕)**: Add a new account.

---

## Adding a New Account
Click on the **(➕)** icon to add a new account.

### Sections in “Create Account” Screen:
1. Account Details
2. Server Connection
3. Credentials
4. Sync Preferences

Each section must be completed carefully to ensure a successful connection.

### Account Details
This section defines how the account will appear inside the application.

**Fields:**
* **Account Name**: Enter a recognizable name (e.g., *Work Account*, *Test Server*). This name helps identify the account when switching between multiple accounts.

### Server Connection
This section is used to connect the app to your server.

**Fields:**
* **URL**: Enter the server URL. Example: `https://tma.onestein.eu/`.

After entering the URL, click **Fetch Databases**.

### Fetch Databases
Clicking **Fetch Databases** initiates a process to retrieve available databases from the provided server.

**System Behavior:**
* The app connects to the server.
* A new screen or dialog opens.
* A list of available databases is displayed.

**User Actions Required:**
On the database selection screen:
* Review the list of available databases.
* Select the appropriate database.
* If required, manually enter the **Database Name**.

**Notes:**
* If no databases appear: Verify the server URL, check internet connectivity, and ensure the server is accessible.
* If multiple databases are listed: Choose the correct one based on your environment.

Once selected, confirm and return to the account setup screen.

### Database Name
After fetching databases:
* The selected database name will be auto-filled or manually entered.
* Ensure the correct database is selected before proceeding.

### Credentials
This section is used to authenticate your account.

**Fields:**
* **Username**: Enter your login username.
* **Connect With**: Connect With Password or API Key.
* **Password**: Enter your account password. Use the visibility toggle (👁) to view or hide the password.

### Sync Preferences
This section allows you to control how data synchronization works.

**Options:**
* **Custom Sync Settings (Toggle Switch)**
    * When enabled: You can define custom sync behavior.
    * When disabled: The system uses default settings (Sync Interval: ~15 minutes; Direction: Two-way sync where data is both sent and received).

### Completing Account Setup
After filling all required fields:
1. Click the **✔ (Save/Confirm)** button at the top-right corner.
2. The system will: Validate credentials, establish connection, and add the account to the Connected Accounts list.

### Post-Setup Behavior
Once the account is successfully created:
* It appears under **Connected Accounts**.
* You can activate it using the checkbox and sync it manually using the 🔄 icon.
* Initial synchronization may begin automatically.

---

## Managing and Syncing Accounts

### Switching Between Accounts
* Use the **checkbox** next to an account to activate it.
* Only one account should be active at a time.
* The active account determines where your data is synced and stored.

### Syncing an Account
* Click the **Sync (🔄)** icon next to an account.
* The system will fetch the latest data and update tasks, projects, timesheets, etc.
* Status will update automatically (e.g., *In Progress → Successful*).

### Managing Accounts (Swipe Actions)
The **Connected Accounts** list supports quick actions using swipe gestures, allowing users to efficiently manage accounts without opening additional screens.

**Purpose:** Provide faster access to common actions, improve usability (especially on touch devices), and reduce navigation steps.

**Available Actions:**
* **Swipe Right (→): Edit Account**
    * Swipe an account item to the **right** to reveal the **Edit** option.
    * Use this to update instance URL, modify login credentials, and change account configuration.
* **Swipe Left (←): View & Delete Options**
    * Swipe an account item to the **left** to reveal two action icons:
        1. **View**: Opens account details and displays configuration and connection information.
        2. **Delete**: Removes the account from the app.

---

## Notifications
The **Notifications** section controls how and when the application alerts you.

### Push Notifications
Allows you to control whether the application can send alerts directly to your device.

**Key Option:**
* **Enable Notifications (Toggle Switch)**
    * **ON**: The app will send real-time notifications for updates such as task changes, project updates, and activity logs.
    * **OFF**: All push notifications will be disabled.

**When to Enable:** If you want to stay informed about updates instantly, or if you rely on reminders for task/project updates and activities.
**When to Disable:** If you prefer fewer interruptions or if you only check updates manually within the app.

### Notification Schedule
Allows you to control *when* notifications are delivered, ensuring they only arrive during your preferred working hours. This is especially useful for maintaining work-life balance and avoiding notifications outside office hours.

**Enable Schedule:**
* **ON**: Notifications will only be sent during configured days and hours.
* **OFF**: Notifications can be sent at any time.

**Timezone:**
* Select your **Timezone** to ensure notifications are aligned with your local time. The default value is usually set to **System Default**.

**Working Days:**
* Options include Monday through Sunday.
* Only selected days will allow notifications, while unselected days will block all notifications.

**Working Hours:**
* **From**: Start time (e.g., 09:00).
* **To**: End time (e.g., 18:00).
* Notifications will only be sent within the selected time range.

**Example Configuration (Standard Work Schedule):**
* Enable Notifications: ON
* Enable Schedule: ON
* Working Days: Monday to Friday
* Working Hours: 09:00 to 18:00
* *Result:* You will only receive notifications during office hours on weekdays.

---

## Background Sync
The **Background Sync** feature ensures your data stays updated automatically.

**Features:**
* Enable automatic synchronization.
* Set sync frequency.
* Sync tasks, timesheets, projects, project updates, etc., in the background.

**Benefits:** Reduces manual effort, keeps data consistent across devices and accounts, and ensures real-time updates.

### Background Sync Settings Overview
This screen allows you to configure how and when your data is synchronized with the server. This feature works in the background without requiring manual intervention.

**Key Configuration Options:**
1. **Enable AutoSync (Toggle Switch)**
    * **ON**: Automatic synchronization is enabled, and the app will sync data at defined intervals.
    * **OFF**: Background sync is disabled, and data must be synced manually.
2. **Sync Interval**
    * Defines how often the application performs automatic synchronization.
    * Example Options: 5 minutes, 15 minutes, 30 minutes or more.
    * Recommendation: Use **5–15 minutes** for active users; use longer intervals to conserve battery and data usage.
3. **Sync Direction**
    * **Both (Up & Down)** *(Default)*: Uploads local changes to the server and downloads updates from the server.
    * **Upload Only (Up)**: Sends local data to the server but does not fetch updates.
    * **Download Only (Down)**: Retrieves updates from the server but does not upload local changes.
4. **Restart Background Daemon**
    * Allows you to restart the background synchronization service. Use this if sync appears stuck, after changing sync settings, or after reconnecting an account.

### How Background Sync Works
When AutoSync is enabled:
1. The app runs a background service.
2. At each interval, it connects to the configured account/server, uploads new or modified data (tasks, timesheets, etc.), and downloads updates from the server.
3. Updates are applied automatically without user action.

**Best Practices:**
* Keep AutoSync enabled for a seamless experience.
* Use a 15-minute interval for balanced performance and battery usage.
* Keep Sync Direction = Both unless you have a specific need.
* Restart the daemon if syncing issues occur.

---

## Theme Settings
The **Theme Settings** section allows users to customize the visual appearance of the application.

**Benefits:** Improves readability, enhances user comfort during extended usage, and supports accessibility preferences.

### Available Theme Options
1. **Light Theme**: Bright and clean interface that uses light backgrounds with dark text. Suitable for well-lit environments and daytime use.
2. **Dark Theme**: Dark background with lighter text. Reduces screen brightness and glare.

### How to Change the Theme
1. Select **Theme Settings**.
2. Choose one of the available options: Light Theme or Dark Theme.
3. The selected theme will be applied immediately.

**System Behavior:**
* The currently selected theme is marked with a **check indicator (✔)**.
* Only one theme can be active at a time.
* Theme changes are applied **instantly** across all screens (no restart or refresh is required).
* The selected theme is **saved automatically** and persists across sessions.