/*
* MIT License
*
* Copyright (c) 2025 CIT-Services
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.LocalStorage 2.7 as Sql
import Lomiri.Components 1.3
import io.thp.pyotherside 1.4
import "../models/utils.js" as Utils
import "../models/accounts.js" as Accounts
import "components"

Page {
    id: settings
    title: i18n.dtr("ubtms", "Settings")
    header: PageHeader {
        id: pageHeader
        StyleHints {

            foregroundColor: "white"

            backgroundColor: LomiriColors.orange
            dividerColor: LomiriColors.slate
        }
        title: settings.title
        trailingActionBar.actions: [
            Action {
                iconName: "add"
                onTriggered: {
                    apLayout.addPageToNextColumn(settings, Qt.resolvedUrl('Account_Page.qml'));
                }
            },
            Action {
                iconName: "revert"
                onTriggered: {
                    toggleVisibleMigrationSection();
                }
            },
            Action {
                iconName: "message"
                text: "Test Notification"
                onTriggered: {
                    mainView.showSystemNotification("Test Notification", "This is a test notification from TimeManagement app!");
                }
            }
        ]
    }

    // Listen for sync timeout from GlobalTimerWidget
    Connections {
        target: typeof globalTimerWidget !== 'undefined' ? globalTimerWidget : null
        onSyncTimedOut: function (accountId) {
            if (syncingAccountId === accountId) {
                syncingAccountId = -1;
                syncTimeoutTimer.stop(); // Stop local timeout timer
                syncStatusChecker.stop(); // Stop status checker
                accountDisplayRefreshTimer.stop(); // Stop display refresh
                // Refresh accounts list when timeout occurs
                fetch_accounts();
            }
        }
    }

    //LISTEN To backend
    Connections {
        target: backend_bridge

        onMessageReceived: function (data) {
            if (data.event === "sync_progress") {
                console.log("Progress is " + data.payload);
                //Show Progress Bar
            } else if (data.event === "sync_message") {
                console.log("Sync message is " + data.payload);
                //Show the message in UI
            } else if (data.event === "sync_completed")
            //Close the Sync uI
            {} else if (data.event === "sync_error")
            //show error in UI
            {} else
            //not interested
            {}
        }
    }

    property int syncingAccountId: -1
    property var lastSyncStatuses: ({})

    property bool visibleMigrationSection: false

    // Simplified timeout timer - only resets local state, GlobalTimerWidget handles its own timeout
    Timer {
        id: syncTimeoutTimer
        interval: 26000 // 26 seconds timeout
        running: false
        repeat: false
        onTriggered: {
            if (syncingAccountId !== -1) {
                var timeoutAccountId = syncingAccountId; // Store before resetting
                syncingAccountId = -1;
                syncStatusChecker.stop(); // Stop status checker
                accountDisplayRefreshTimer.stop(); // Stop display refresh
                console.log("🕐 Settings page: Local sync state timed out for account:", timeoutAccountId);
            }
        }
    }

    function toggleVisibleMigrationSection() {
        visibleMigrationSection = !visibleMigrationSection;
    }

    // Sync completion checker - polls for sync status updates but doesn't interfere with GlobalTimerWidget
    Timer {
        id: syncStatusChecker
        interval: 2000 // Check every 2 seconds (less frequent to avoid interfering)
        running: false
        repeat: true
        onTriggered: {
            if (syncingAccountId !== -1) {
                // Get current sync status for the syncing account
                var currentStatus = Utils.getLastSyncStatus(syncingAccountId);

                // Get last known status for this account
                var lastStatus = lastSyncStatuses[syncingAccountId] || "";

                // Check if status changed and sync completed successfully or failed
                if (currentStatus !== lastStatus) {
                    lastSyncStatuses[syncingAccountId] = currentStatus;

                    // If sync completed (successful or failed), only refresh accounts list
                    // Let GlobalTimerWidget handle its own timeout and display lifecycle
                    if (currentStatus.indexOf("Successful") !== -1 || currentStatus.indexOf("Failed") !== -1) {
                        console.log("✅ Sync completed for account:", syncingAccountId, "Status:", currentStatus);

                        // Only reset local sync state and refresh accounts - don't stop GlobalTimerWidget
                        var completedAccountId = syncingAccountId;
                        syncingAccountId = -1;
                        syncTimeoutTimer.stop();
                        syncStatusChecker.stop();
                        accountDisplayRefreshTimer.stop();

                        // Refresh accounts list to show updated status
                        fetch_accounts();

                        // NOTE: Let GlobalTimerWidget handle its own stopSync() through its internal timeout
                        // This preserves the progress indication and success display
                    }
                }
            } else {
                // No sync in progress, stop checking
                syncStatusChecker.stop();
            }
        }
    }

    // Separate timer for refreshing account display during sync (for real-time status updates)
    Timer {
        id: accountDisplayRefreshTimer
        interval: 3000 // Refresh account display every 3 seconds during sync
        running: false
        repeat: true
        onTriggered: {
            if (syncingAccountId !== -1) {
                // Only refresh the accounts list display, don't interfere with sync logic
                fetch_accounts();
            } else {
                // Stop refreshing when no sync is active
                accountDisplayRefreshTimer.stop();
            }
        }
    }
    // Theme management functions
    function getCurrentTheme() {
        return theme.name;
    }

    function setThemePreference(themeName) {
        try {
            // Apply theme immediately
            Theme.name = themeName;

            // Save to database directly
            saveThemeToDatabase(themeName);

            // Update checkboxes
            updateThemeCheckboxes();
        } catch (e) {
            console.error("Error setting theme preference:", e);
        }
    }

    function saveThemeToDatabase(themeName) {
        try {
            var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);

            db.transaction(function (tx) {
                // Create settings table if it doesn't exist
                tx.executeSql('CREATE TABLE IF NOT EXISTS app_settings (key TEXT PRIMARY KEY, value TEXT)');

                // Save theme preference (INSERT OR REPLACE)
                tx.executeSql('INSERT OR REPLACE INTO app_settings (key, value) VALUES (?, ?)', ['theme_preference', themeName]);
            });
        } catch (e) {
            console.warn("Error saving theme to database:", e);
        }
    }

    function updateThemeCheckboxes() {
        if (typeof lightThemeCheckbox !== 'undefined') {
            lightThemeCheckbox.checked = getCurrentTheme() === "Ubuntu.Components.Themes.Ambiance";
        }
        if (typeof darkThemeCheckbox !== 'undefined') {
            darkThemeCheckbox.checked = getCurrentTheme() === "Ubuntu.Components.Themes.SuruDark";
        }
    }

    ListModel {
        id: accountListModel
    }

    function fetch_accounts() {
        accountListModel.clear();
        lastSyncStatuses = {}; // Clear previous sync statuses
        var accountsList = Accounts.getAccountsList();
        for (var account = 0; account < accountsList.length; account++) {
            accountListModel.append(accountsList[account]);
            // Initialize last sync status for each account
            var accountData = accountsList[account];
            lastSyncStatuses[accountData.id] = Utils.getLastSyncStatus(accountData.id);
        }
    }

    function setDefaultAccount(accountId) {
        // Update the local model first
        for (let i = 0; i < accountListModel.count; i++) {
            const account = accountListModel.get(i);
            const isSelected = account.id === accountId ? 1 : 0;
            accountListModel.setProperty(i, "is_default", isSelected);
        }

        // Persist to database
        Accounts.setDefaultAccount(accountId);

        // Refresh the accounts list to ensure consistency
        fetch_accounts();
    }

    Rectangle {
        width: parent.width
        height: parent.height
        anchors.top: parent.top
        anchors.topMargin: units.gu(1)
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: units.gu(1)
        Rectangle {
            anchors.fill: parent
            anchors.topMargin: units.gu(5)
            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#111" : "transparent"
            Flickable {
                id: listView
                anchors.fill: parent
                width: parent.width
                contentHeight: column.height
                flickableDirection: Flickable.VerticalFlick
                clip: true
                Column {
                    id: column
                    width: parent.width
                    spacing: units.gu(2)

                    // Theme Preference Section
                    Rectangle {
                        width: parent.width
                        height: themeSection.height + units.gu(2)
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#1a1a1a" : "#f8f8f8"
                        border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#444" : "#ddd"
                        border.width: 1
                        radius: units.gu(1)

                        Column {
                            id: themeSection
                            width: parent.width - units.gu(2)
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: units.gu(1)
                            spacing: units.gu(1)

                            // Header
                            Text {
                                text: i18n.dtr("ubtms", "App Theme Preference")
                                font.pixelSize: units.gu(2.5)
                                font.bold: true
                                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#e0e0e0" : "#333"
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                text: i18n.dtr("ubtms", "Choose your preferred theme for the application")
                                font.pixelSize: units.gu(1.5)
                                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#b0b0b0" : "#666"
                                anchors.horizontalCenter: parent.horizontalCenter
                                wrapMode: Text.WordWrap
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                            }

                            // Theme Options
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: units.gu(4)

                                // Light Theme Option
                                Column {
                                    spacing: units.gu(1)

                                    Rectangle {
                                        width: units.gu(8)
                                        height: units.gu(6)
                                        color: "#ffffff"
                                        border.color: getCurrentTheme() === "Ubuntu.Components.Themes.Ambiance" ? LomiriColors.orange : "#ccc"
                                        border.width: getCurrentTheme() === "Ubuntu.Components.Themes.Ambiance" ? 3 : 1
                                        radius: units.gu(0.5)

                                        // Light theme preview
                                        Column {
                                            anchors.fill: parent
                                            anchors.margins: units.gu(0.5)
                                            spacing: units.gu(0.2)

                                            Rectangle {
                                                width: parent.width
                                                height: units.gu(1)
                                                color: "#f0f0f0"
                                                radius: units.gu(0.2)
                                            }
                                            Rectangle {
                                                width: parent.width * 0.7
                                                height: units.gu(0.5)
                                                color: "#666"
                                                radius: units.gu(0.1)
                                            }
                                            Rectangle {
                                                width: parent.width * 0.9
                                                height: units.gu(0.5)
                                                color: "#999"
                                                radius: units.gu(0.1)
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                setThemePreference("Ubuntu.Components.Themes.Ambiance");
                                            }
                                        }
                                    }

                                    Text {
                                        text: i18n.dtr("ubtms", "Light Theme")
                                        font.pixelSize: units.gu(1.5)
                                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#e0e0e0" : "#333"
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }

                                    CheckBox {
                                        id: lightThemeCheckbox
                                        checked: getCurrentTheme() === "Ubuntu.Components.Themes.Ambiance"
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        onClicked: {
                                            if (checked) {
                                                setThemePreference("Ubuntu.Components.Themes.Ambiance");
                                            }
                                        }
                                    }
                                }

                                // Dark Theme Option
                                Column {
                                    spacing: units.gu(1)

                                    Rectangle {
                                        width: units.gu(8)
                                        height: units.gu(6)
                                        color: "#2c2c2c"
                                        border.color: getCurrentTheme() === "Ubuntu.Components.Themes.SuruDark" ? LomiriColors.orange : "#666"
                                        border.width: getCurrentTheme() === "Ubuntu.Components.Themes.SuruDark" ? 3 : 1
                                        radius: units.gu(0.5)

                                        // Dark theme preview
                                        Column {
                                            anchors.fill: parent
                                            anchors.margins: units.gu(0.5)
                                            spacing: units.gu(0.2)

                                            Rectangle {
                                                width: parent.width
                                                height: units.gu(1)
                                                color: "#444"
                                                radius: units.gu(0.2)
                                            }
                                            Rectangle {
                                                width: parent.width * 0.7
                                                height: units.gu(0.5)
                                                color: "#e0e0e0"
                                                radius: units.gu(0.1)
                                            }
                                            Rectangle {
                                                width: parent.width * 0.9
                                                height: units.gu(0.5)
                                                color: "#b0b0b0"
                                                radius: units.gu(0.1)
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                setThemePreference("Ubuntu.Components.Themes.SuruDark");
                                            }
                                        }
                                    }

                                    Text {
                                        text: i18n.dtr("ubtms", "Dark Theme")
                                        font.pixelSize: units.gu(1.5)
                                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#e0e0e0" : "#333"
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }

                                    CheckBox {
                                        id: darkThemeCheckbox
                                        checked: getCurrentTheme() === "Ubuntu.Components.Themes.SuruDark"
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        onClicked: {
                                            if (checked) {
                                                setThemePreference("Ubuntu.Components.Themes.SuruDark");
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Data Migration Section
                    Rectangle {
                        visible: visibleMigrationSection
                        width: parent.width
                        height: migrationSection.height + units.gu(2)
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#1a1a1a" : "#f8f8f8"
                        border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#444" : "#ddd"
                        border.width: 1
                        radius: units.gu(1)

                        Column {
                            id: migrationSection
                            width: parent.width - units.gu(2)
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: units.gu(1)
                            spacing: units.gu(1)

                            // Header
                            Text {
                                text: i18n.dtr("ubtms", "Personal Stages Diagnostics")
                                font.pixelSize: units.gu(2.5)
                                font.bold: true
                                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#e0e0e0" : "#333"
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                text: i18n.dtr("ubtms", "Check personal stage data status and configuration")
                                font.pixelSize: units.gu(1.5)
                                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#b0b0b0" : "#666"
                                anchors.horizontalCenter: parent.horizontalCenter
                                wrapMode: Text.WordWrap
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                            }

                            // Diagnostic Button
                            TSButton {
                                id: migrateButton
                                width: units.gu(30)
                                height: units.gu(5)
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: i18n.dtr("ubtms", "Check Personal Stage Status")
                                fontSize: units.gu(1.8)
                                onClicked: {
                                    var result = Utils.migratePersonalStageData();
                                    if (result.success) {
                                        migrationStatusText.text = "✓ " + result.message;
                                        migrationStatusText.color = theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#4CAF50" : "#2E7D32";
                                    } else {
                                        migrationStatusText.text = "✗ " + result.message;
                                        migrationStatusText.color = theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#f44336" : "#c62828";
                                    }
                                    migrationStatusText.visible = true;
                                    resyncStatusText.visible = false;
                                }
                            }

                            // Status Text
                            Text {
                                id: migrationStatusText
                                visible: false
                                text: ""
                                font.pixelSize: units.gu(1.5)
                                wrapMode: Text.WordWrap
                                width: parent.width - units.gu(2)
                                horizontalAlignment: Text.AlignHCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            // Divider
                            Rectangle {
                                width: parent.width - units.gu(4)
                                height: 1
                                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#444" : "#ddd"
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            // Force Resync Section
                            Text {
                                text: i18n.dtr("ubtms", "Force Task Re-sync")
                                font.pixelSize: units.gu(2)
                                font.bold: true
                                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#e0e0e0" : "#333"
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                text: i18n.dtr("ubtms", "Reset task timestamps to force fresh sync from Odoo")
                                font.pixelSize: units.gu(1.5)
                                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#b0b0b0" : "#666"
                                anchors.horizontalCenter: parent.horizontalCenter
                                wrapMode: Text.WordWrap
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: units.gu(2)

                                // Reset Tasks Without Stages
                                TSButton {
                                    id: resyncWithoutStagesButton
                                    width: units.gu(21)
                                    height: units.gu(5)
                                    text: i18n.dtr("ubtms", "Reset Tasks Without Stages")
                                    fontSize: units.gu(1.5)
                                    bgColor: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#FF9800" : "#F57C00"
                                    onClicked: {
                                        var result = Utils.forceTaskResync(true);
                                        if (result.success) {
                                            resyncStatusText.text = "✓ " + result.message;
                                            resyncStatusText.color = theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#4CAF50" : "#2E7D32";
                                        } else {
                                            resyncStatusText.text = "✗ " + result.message;
                                            resyncStatusText.color = theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#f44336" : "#c62828";
                                        }
                                        resyncStatusText.visible = true;
                                        migrationStatusText.visible = false;
                                    }
                                }

                                // Reset All Tasks
                                TSButton {
                                    id: resyncAllButton
                                    width: units.gu(21)
                                    height: units.gu(5)
                                    text: i18n.dtr("ubtms", "Reset All Tasks")
                                    fontSize: units.gu(1.5)
                                    bgColor: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#f44336" : "#c62828"
                                    onClicked: {
                                        var result = Utils.forceTaskResync(false);
                                        if (result.success) {
                                            resyncStatusText.text = "✓ " + result.message;
                                            resyncStatusText.color = theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#4CAF50" : "#2E7D32";
                                        } else {
                                            resyncStatusText.text = "✗ " + result.message;
                                            resyncStatusText.color = theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#f44336" : "#c62828";
                                        }
                                        resyncStatusText.visible = true;
                                        migrationStatusText.visible = false;
                                    }
                                }
                            }

                            // Resync Status Text
                            Text {
                                id: resyncStatusText
                                visible: false
                                text: ""
                                font.pixelSize: units.gu(1.5)
                                wrapMode: Text.WordWrap
                                width: parent.width - units.gu(2)
                                horizontalAlignment: Text.AlignHCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }

                    // Accounts Section Header
                    Text {
                        text: i18n.dtr("ubtms", "Connected Accounts")
                        font.pixelSize: units.gu(2.5)
                        font.bold: true
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#e0e0e0" : "#333"
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(1)
                    }

                    // Account List
                    Column {
                        width: parent.width
                        spacing: 0
                        Repeater {
                            model: accountListModel
                            delegate: Rectangle {
                                width: parent.width
                                height: units.gu(16)
                                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#111" : "transparent"
                                border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#444" : "#CCCCCC"
                                border.width: 1
                                Column {
                                    spacing: 0
                                    anchors.fill: parent
                                    Row {
                                        width: parent.width
                                        height: units.gu(15)
                                        spacing: units.gu(1)

                                        Rectangle {
                                            id: imgmodulename
                                            width: units.gu(5)
                                            height: units.gu(5)
                                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#0078d4" : "#0078d4"
                                            radius: 80
                                            border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#0056a0" : "#0056a0"
                                            border.width: 1
                                            anchors.rightMargin: units.gu(1)
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left
                                            anchors.leftMargin: units.gu(1)

                                            Text {
                                                text: Utils.truncateText(model.name.charAt(0), 20).toUpperCase()
                                                anchors.verticalCenter: parent.verticalCenter
                                                color: "#fff"
                                                anchors.centerIn: parent
                                                font.pixelSize: units.gu(2)
                                            }
                                        }

                                        Column {
                                            spacing: 5
                                            anchors.left: imgmodulename.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.leftMargin: units.gu(2)

                                            Text {
                                                text: Utils.truncateText(model.name, 20).toUpperCase()
                                                font.pixelSize: units.gu(2)
                                                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#e0e0e0" : "#000"
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                text: i18n.dtr("ubtms", "URL : ") + ((model.link.length > 40) ? model.link.substring(0, 40) + "..." : model.link)
                                                font.pixelSize: units.gu(1.2)
                                                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#b0b0b0" : "#666"
                                                elide: Text.ElideNone
                                            }
                                            Text {
                                                text: i18n.dtr("ubtms", "Database : ") + model.database
                                                font.pixelSize: units.gu(1.1)
                                                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#b0b0b0" : "#666"
                                            }
                                            Text {
                                                text: Utils.getLastSyncStatus(model.id)
                                                font.pixelSize: units.gu(1)
                                                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#b0b0b0" : "#666"
                                            }
                                            CheckBox {
                                                id: defaultCheckBox
                                                checked: model.is_default === 1
                                                text: i18n.dtr("ubtms", "Default")

                                                // Handle the click/toggle event
                                                onClicked: {
                                                    // Only set as default if this checkbox was unchecked and is now checked
                                                    if (checked) {
                                                        setDefaultAccount(model.id);
                                                    } else {
                                                        // Prevent unchecking - there must always be a default account
                                                        checked = true;
                                                    }
                                                }
                                            }
                                        }
                                        Column {
                                            anchors.right: parent.right
                                            anchors.rightMargin: units.gu(1)
                                            anchors.verticalCenter: parent.verticalCenter
                                            TSButton {
                                                visible: (model.id !== 0)
                                                width: units.gu(10)
                                                height: units.gu(4)
                                                fontSize: units.gu(1.5)
                                                text: Utils.truncateText(i18n.dtr("ubtms", "Delete"),10)
                                                onClicked: {
                                                    Accounts.deleteAccountAndRelatedData(model.id);
                                                    accountListModel.remove(index);
                                                }
                                            }
                                            TSButton {
                                                visible: (model.id !== 0)
                                                width: units.gu(10)
                                                height: units.gu(4)
                                                fontSize: units.gu(1.5)
                                                text: Utils.truncateText(i18n.dtr("ubtms", "Show Log"),10)
                                                onClicked: {
                                                    apLayout.addPageToNextColumn(settings, Qt.resolvedUrl("SyncLog.qml"), {
                                                        "recordid": model.id
                                                    });
                                                }
                                            }
                                            Rectangle {
                                                id: syncContainer
                                                visible: (model.id !== 0)
                                                width: units.gu(10)
                                                height: units.gu(4)
                                                color: "transparent"

                                                property bool syncing: syncingAccountId === model.id

                                                TSButton {
                                                    id: syncBtn
                                                    anchors.fill: parent
                                                    visible: !syncContainer.syncing
                                                    fontSize: units.gu(1.5)
                                                    text: Utils.truncateText(i18n.dtr("ubtms", "Sync"),10)
                                                    onClicked: {
                                                        console.log("Starting sync for account:", model.id, "(" + model.name + ")");
                                                        syncingAccountId = model.id;
                                                        syncTimeoutTimer.start(); // Start timeout timer
                                                        syncStatusChecker.start(); // Start status checking
                                                        accountDisplayRefreshTimer.start(); // Start account display refresh

                                                        // Notify global timer widget about sync start
                                                        if (typeof globalTimerWidget !== 'undefined') {
                                                            globalTimerWidget.startSync(model.id, model.name);
                                                        }

                                                        backend_bridge.call("backend.resolve_qml_db_path", ["ubtms"], function (path) {
                                                            if (path === "") {
                                                                console.warn("DB not found.");
                                                                syncingAccountId = -1;
                                                                syncTimeoutTimer.stop();
                                                                syncStatusChecker.stop();
                                                                accountDisplayRefreshTimer.stop();
                                                                if (typeof globalTimerWidget !== 'undefined') {
                                                                    globalTimerWidget.stopSync();
                                                                }
                                                            } else {
                                                                backend_bridge.call("backend.start_sync_in_background", [path, model.id], function (result) {
                                                                    if (result) {
                                                                        console.log("Background sync started for account:", model.id);
                                                                        // Keep syncing = true, will be set to false when sync completes or times out
                                                                    } else {
                                                                        console.warn("Failed to start sync for account:", model.id);
                                                                        syncingAccountId = -1;
                                                                        syncTimeoutTimer.stop();
                                                                        syncStatusChecker.stop();
                                                                        accountDisplayRefreshTimer.stop();
                                                                        if (typeof globalTimerWidget !== 'undefined') {
                                                                            globalTimerWidget.stopSync();
                                                                        }
                                                                    }
                                                                });
                                                            }
                                                        });
                                                    }
                                                }

                                                Rectangle {
                                                    id: loadingIndicator
                                                    anchors.fill: parent
                                                    visible: syncContainer.syncing
                                                    color: "#0078d4"
                                                    radius: units.gu(0.5)
                                                    border.color: "#0056a0"
                                                    border.width: 1

                                                    // Pulsing animation for loading indicator
                                                    SequentialAnimation {
                                                        running: syncContainer.syncing
                                                        loops: Animation.Infinite

                                                        PropertyAnimation {
                                                            target: loadingIndicator
                                                            property: "opacity"
                                                            from: 1.0
                                                            to: 0.6
                                                            duration: 800
                                                        }

                                                        PropertyAnimation {
                                                            target: loadingIndicator
                                                            property: "opacity"
                                                            from: 0.6
                                                            to: 1.0
                                                            duration: 800
                                                        }
                                                    }

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: i18n.dtr("ubtms", "Syncing...")
                                                        color: "white"
                                                        font.pixelSize: units.gu(1.2)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    onVisibleChanged: {
        fetch_accounts();
        if (visible) {
            updateThemeCheckboxes();
        } else {
            // When page is hidden, stop all timers to prevent unnecessary polling
            syncStatusChecker.stop();
            accountDisplayRefreshTimer.stop();
        }
    }
}
