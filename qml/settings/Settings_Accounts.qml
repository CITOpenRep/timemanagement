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
import Lomiri.Components.Popups 1.3
import Lomiri.Components.ListItems 1.3 as ListItemOld
import io.thp.pyotherside 1.4
import "../../models/utils.js" as Utils
import "../../models/accounts.js" as Accounts
import "../components"
import "../components/settings"

Page {
    id: accountsSettingsPage
    title: i18n.dtr("ubtms", "Connected Accounts")

    header: SettingsHeader {
        id: pageHeader
        title: accountsSettingsPage.title
        trailingActions: [
            Action {
                iconName: "add"
                onTriggered: {
                    apLayout.addPageToNextColumn(accountsSettingsPage, Qt.resolvedUrl('../Account_Page.qml'));
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
                //console.log("Progress is " + data.payload);
                //Show Progress Bar
            } else if (data.event === "sync_message") {
                //console.log("Sync message is " + data.payload);
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

    property int accountToDelete: -1
    property int accountIndexToDelete: -1

    // Confirmation Dialog for Account Deletion
    Component {
        id: deleteConfirmationDialogComponent
        Dialog {
            id: deleteConfirmationDialog
            title: i18n.dtr("ubtms", "Delete Account")
            
            Label {
                text: i18n.dtr("ubtms", "Are you sure you want to delete this account? This will permanently remove the account and all associated data including projects, tasks, and timesheets.")
                wrapMode: Text.WordWrap
            }
            
            Button {
                text: i18n.dtr("ubtms", "Cancel")
                onClicked: {
                    PopupUtils.close(deleteConfirmationDialog);
                    accountToDelete = -1;
                    accountIndexToDelete = -1;
                }
            }
            
            Button {
                text: i18n.dtr("ubtms", "Delete")
                color: LomiriColors.red
                onClicked: {
                    if (accountToDelete !== -1) {
                        Accounts.deleteAccountAndRelatedData(accountToDelete);
                        if (accountIndexToDelete !== -1) {
                            accountListModel.remove(accountIndexToDelete);
                        }
                        accountToDelete = -1;
                        accountIndexToDelete = -1;
                    }
                    PopupUtils.close(deleteConfirmationDialog);
                }
            }
        }
    }

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
                //console.log("🕐 Settings page: Local sync state timed out for account:", timeoutAccountId);
            }
        }
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
                        //console.log("✅ Sync completed for account:", syncingAccountId, "Status:", currentStatus);

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

    // Format minutes into human-readable interval text
    function formatSyncInterval(minutes) {
        var m = parseInt(minutes);
        if (isNaN(m) || m <= 0) return minutes + " min";
        if (m < 60) return m + " min";
        if (m === 60) return "1 hour";
        if (m < 1440) return (m / 60) + " hours";
        if (m === 1440) return "1 day";
        if (m < 10080) return (m / 1440) + " days";
        if (m === 10080) return "1 week";
        return m + " min";
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
        anchors.top: pageHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#111" : "#f5f5f5"

        ListView {
            id: listView
            anchors.fill: parent
            clip: true
            spacing: 0
            model: accountListModel
            
            delegate: ListItem {
                id: delegateItem
                width: parent.width
                height: delegateColumn.height
                divider.visible: false
                highlightColor: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#252525" : "#e8e8e8"

                onClicked: {
                    if (model.id !== 0) {
                        apLayout.addPageToNextColumn(accountsSettingsPage, Qt.resolvedUrl('../Account_Page.qml'), {
                            "accountId": model.id
                        });
                    }
                }

                // ── Swipe Left → Edit ──
                leadingActions: ListItemActions {
                    actions: [
                        Action {
                            iconName: "edit"
                            enabled: model.id !== 0
                            onTriggered: {
                                apLayout.addPageToNextColumn(accountsSettingsPage, Qt.resolvedUrl('../Account_Page.qml'), {
                                    "accountId": model.id
                                });
                            }
                        }
                    ]
                }

                // ── Swipe Right → Log, Delete ──
                trailingActions: ListItemActions {
                    actions: [
                        Action {
                            iconName: "note"
                            text: i18n.dtr("ubtms", "Log")
                            enabled: model.id !== 0
                            onTriggered: {
                                apLayout.addPageToNextColumn(accountsSettingsPage, Qt.resolvedUrl("../SyncLog.qml"), {
                                    "recordid": model.id
                                });
                            }
                        },
                        Action {
                            iconName: "delete"
                            text: i18n.dtr("ubtms", "Delete")
                            enabled: model.id !== 0
                            onTriggered: {
                                accountToDelete = model.id;
                                accountIndexToDelete = index;
                                PopupUtils.open(deleteConfirmationDialogComponent);
                            }
                        }
                    ]
                }

                Column {
                    id: delegateColumn
                    width: parent.width

                    // ── Main content area ──
                    Item {
                        width: parent.width
                        height: contentRow.height + units.gu(2.5)

                        Row {
                            id: contentRow
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                leftMargin: units.gu(2)
                                rightMargin: units.gu(2)
                            }
                            spacing: units.gu(1.5)

                            // ── Avatar ──
                            Rectangle {
                                id: avatar
                                width: units.gu(5)
                                height: units.gu(5)
                                radius: units.gu(1)
                                anchors.verticalCenter: parent.verticalCenter
                                color: model.id === 0 ? "#8e8e93"
                                     : model.is_default === 1 ? LomiriColors.orange
                                     : "#335280"

                                Text {
                                    text: model.name.charAt(0).toUpperCase()
                                    anchors.centerIn: parent
                                    color: "#ffffff"
                                    font.pixelSize: units.gu(2.2)
                                    font.weight: Font.DemiBold
                                }

                                // Default indicator dot
                                Rectangle {
                                    visible: model.is_default === 1
                                    width: units.gu(1.4)
                                    height: units.gu(1.4)
                                    radius: width / 2
                                    color: "#ffffff"
                                    border.color: LomiriColors.orange
                                    border.width: units.dp(2)
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.rightMargin: -units.gu(0.3)
                                    anchors.bottomMargin: -units.gu(0.3)

                                    Icon {
                                        anchors.centerIn: parent
                                        width: units.gu(0.8)
                                        height: units.gu(0.8)
                                        name: "tick"
                                        color: LomiriColors.orange
                                    }
                                }
                            }

                            // ── Text Column ──
                            Column {
                                id: textCol
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - avatar.width - actionCol.width - units.gu(3)
                                spacing: units.gu(0.2)

                                // Account name
                                Text {
                                    text: model.name
                                    width: parent.width
                                    font.pixelSize: units.gu(1.9)
                                    font.weight: Font.Medium
                                    color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#f5f5f5" : "#111"
                                    elide: Text.ElideRight
                                }

                                // URL
                                Text {
                                    text: model.link
                                    width: parent.width
                                    font.pixelSize: units.gu(1.2)
                                    color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#888" : "#777"
                                    elide: Text.ElideMiddle
                                }

                                // Sync status line (combined: status + interval)
                                Text {
                                    visible: model.id !== 0
                                    width: parent.width
                                    font.pixelSize: units.gu(1.1)
                                    elide: Text.ElideRight
                                    color: {
                                        var s = Utils.getLastSyncStatus(model.id);
                                        if (s.indexOf("Successful") !== -1) return theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#66bb6a" : "#43a047";
                                        if (s.indexOf("Failed") !== -1) return theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#ef5350" : "#e53935";
                                        return theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#888" : "#999";
                                    }
                                    text: {
                                        var s = Utils.getLastSyncStatus(model.id);
                                        // Extract just the date/time part for brevity
                                        var interval = "";
                                        if (model.sync_interval_minutes !== undefined && model.sync_interval_minutes !== null && model.sync_interval_minutes !== "") {
                                            interval = formatSyncInterval(model.sync_interval_minutes);
                                        } else {
                                            var gi = "15";
                                            try {
                                                var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
                                                db.readTransaction(function (tx) {
                                                    var rs = tx.executeSql('SELECT value FROM app_settings WHERE key = ?', ["sync_interval_minutes"]);
                                                    if (rs.rows.length > 0) gi = rs.rows.item(0).value;
                                                });
                                            } catch (e) {}
                                            interval = formatSyncInterval(gi);
                                        }
                                        if (s && s.length > 0) {
                                            // Shorten long status text
                                            var shortStatus = s.length > 35 ? s.substring(0, 32) + "…" : s;
                                            return shortStatus + "  ·  " + interval;
                                        }
                                        return "⟳ " + interval;
                                    }
                                }
                            }

                            // ── Right Action Column ──
                            Column {
                                id: actionCol
                                anchors.verticalCenter: parent.verticalCenter
                                width: model.id !== 0 ? units.gu(5) : units.gu(4)
                                spacing: units.gu(0.5)

                                // Sync icon button (non-local only)
                                Item {
                                    visible: model.id !== 0
                                    width: units.gu(4.5)
                                    height: units.gu(4.5)

                                    property bool syncing: syncingAccountId === model.id

                                    // Sync button
                                    Rectangle {
                                        id: syncCircle
                                        anchors.centerIn: parent
                                        width: units.gu(4)
                                        height: units.gu(4)
                                        radius: width / 2
                                        visible: !parent.syncing
                                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#252525" : "#f0f0f0"
                                        border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#444" : "#ddd"
                                        border.width: units.dp(1)

                                        Icon {
                                            anchors.centerIn: parent
                                            width: units.gu(2.2)
                                            height: units.gu(2.2)
                                            name: "sync"
                                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#ccc" : "#555"
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                syncingAccountId = model.id;
                                                syncTimeoutTimer.start();
                                                syncStatusChecker.start();
                                                accountDisplayRefreshTimer.start();

                                                if (typeof globalTimerWidget !== 'undefined') {
                                                    globalTimerWidget.startSync(model.id, model.name);
                                                }

                                                backend_bridge.call("backend.resolve_qml_db_path", ["ubtms"], function (path) {
                                                    if (path === "") {
                                                        syncingAccountId = -1;
                                                        syncTimeoutTimer.stop();
                                                        syncStatusChecker.stop();
                                                        accountDisplayRefreshTimer.stop();
                                                        if (typeof globalTimerWidget !== 'undefined') {
                                                            globalTimerWidget.stopSync();
                                                        }
                                                    } else {
                                                        backend_bridge.call("backend.start_sync_in_background", [path, model.id], function (result) {
                                                            if (!result) {
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
                                    }

                                    // Syncing spinner
                                    Rectangle {
                                        id: syncingIndicator
                                        anchors.centerIn: parent
                                        width: units.gu(4)
                                        height: units.gu(4)
                                        radius: width / 2
                                        visible: parent.syncing
                                        color: LomiriColors.orange

                                        SequentialAnimation {
                                            running: syncingIndicator.visible
                                            loops: Animation.Infinite
                                            PropertyAnimation { target: syncingIndicator; property: "opacity"; from: 1.0; to: 0.4; duration: 600 }
                                            PropertyAnimation { target: syncingIndicator; property: "opacity"; from: 0.4; to: 1.0; duration: 600 }
                                        }

                                        Icon {
                                            anchors.centerIn: parent
                                            width: units.gu(2)
                                            height: units.gu(2)
                                            name: "sync"
                                            color: "#ffffff"
                                        }
                                    }
                                }

                                // Star for setting default (non-local only)
                                Item {
                                    visible: model.id !== 0
                                    width: units.gu(4.5)
                                    height: units.gu(2)

                                    Icon {
                                        anchors.centerIn: parent
                                        width: units.gu(2)
                                        height: units.gu(2)
                                        name: model.is_default === 1 ? "starred" : "non-starred"
                                        color: model.is_default === 1 ? LomiriColors.orange
                                             : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#555" : "#ccc")
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            if (model.is_default !== 1) {
                                                setDefaultAccount(model.id);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── Bottom divider ──
                    Rectangle {
                        width: parent.width - units.gu(4)
                        height: units.dp(1)
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#2a2a2a" : "#e0e0e0"
                    }
                }
            }
        }
    }

    onVisibleChanged: {
        fetch_accounts();
        if (visible) {
            
        } else {
            // When page is hidden, stop all timers to prevent unnecessary polling
            syncStatusChecker.stop();
            accountDisplayRefreshTimer.stop();
        }
    }
}
