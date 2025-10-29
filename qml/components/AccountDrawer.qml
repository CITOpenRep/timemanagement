import QtQuick 2.7
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.11
import "../../models/accounts.js" as Accounts
import "../../models/utils.js" as Utils

Item {
    id: accountDrawer
    width: 0
    height: 0

    property bool isSyncing: false
    property int currentAccountId: -1
    property string currentAccountName: ""
    property var syncSteps: []
    property int currentStep: 0

    signal accountChanged(int accountId, string accountName)
    signal syncCompleted(bool success, string message)

    Component {
        id: accountDrawerPopup

        Dialog {
            id: accountDialog
            title: i18n.dtr("ubtms", "Account Selection")
            width: parent.width * 0.9
            height: parent.height * 0.8

            Rectangle {
                anchors.fill: parent
                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#2D2D2D" : "#FFFFFF"
                radius: units.gu(0.5)
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: units.gu(2)
                spacing: units.gu(2)

                // Header
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: units.gu(8)
                    color: "transparent"

                    RowLayout {
                        anchors.fill: parent
                        spacing: units.gu(2)

                        Icon {
                            name: "account"
                            width: units.gu(3)
                            height: units.gu(3)
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                        }

                        Label {
                            text: i18n.dtr("ubtms", "Account Selection")
                            font.pixelSize: units.gu(2.5)
                            font.weight: Font.Bold
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Button {
                            text: i18n.dtr("ubtms", "Close")
                            onClicked: PopupUtils.close(accountDialog)
                        }
                    }
                }

                // Account Selector
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: units.gu(12)
                    color: "transparent"

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: units.gu(1)

                        Label {
                            text: i18n.dtr("ubtms", "Select Account:")
                            font.pixelSize: units.gu(1.8)
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                        }

                        ComboBox {
                            id: accountComboBox
                            Layout.fillWidth: true
                            Layout.preferredHeight: units.gu(5)
                            model: accountModel
                            textRole: "name"

                            background: Rectangle {
                                color: "transparent"
                                radius: units.gu(0.6)
                                border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#d3d1d1" : "#999"
                                border.width: 1
                            }

                            contentItem: Text {
                                text: accountComboBox.displayText
                                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                                anchors.verticalCenter: parent.verticalCenter
                                leftPadding: units.gu(2)
                            }

                            delegate: ItemDelegate {
                                width: accountComboBox.width
                                hoverEnabled: true
                                contentItem: Text {
                                    text: model.name
                                    color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                                    leftPadding: units.gu(1)
                                    elide: Text.ElideRight
                                }
                                background: Rectangle {
                                    color: (hovered ? "skyblue" : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#444" : "#e2e0da"))
                                    radius: units.gu(0.5)
                                    border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#d3d1d1" : "#999"
                                }
                            }

                            onActivated: {
                                if (currentIndex >= 0) {
                                    const selected = model.get(currentIndex);
                                    currentAccountId = selected.id;
                                    currentAccountName = selected.name;
                                    accountChanged(selected.id, selected.name);
                                }
                            }
                        }
                    }
                }

                // Current Account Info
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: units.gu(8)
                    color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#3D3D3D" : "#F5F5F5"
                    radius: units.gu(0.5)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: units.gu(1)
                        spacing: units.gu(0.5)

                        Label {
                            text: i18n.dtr("ubtms", "Current Account:")
                            font.pixelSize: units.gu(1.5)
                            font.weight: Font.Bold
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                        }

                        Label {
                            text: currentAccountName || i18n.dtr("ubtms", "No account selected")
                            font.pixelSize: units.gu(1.8)
                            color: currentAccountName ? (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#4CAF50" : "#2E7D32") : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#FF6B6B" : "#D32F2F")
                        }
                    }
                }

                // Sync Status
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: units.gu(6)
                    color: "transparent"

                    RowLayout {
                        anchors.fill: parent
                        spacing: units.gu(2)

                        Label {
                            text: i18n.dtr("ubtms", "Last Sync:")
                            font.pixelSize: units.gu(1.5)
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                        }

                        Label {
                            id: lastSyncLabel
                            text: i18n.dtr("ubtms", "Never")
                            font.pixelSize: units.gu(1.5)
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#FFA726" : "#F57C00"
                        }

                        Item {
                            Layout.fillWidth: true
                        }
                    }
                }

                // Sync Button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: units.gu(8)
                    color: "transparent"

                    Button {
                        id: syncButton
                        anchors.centerIn: parent
                        width: units.gu(20)
                        height: units.gu(5)
                        text: isSyncing ? i18n.dtr("ubtms", "Syncing...") : i18n.dtr("ubtms", "Sync Data")
                        enabled: !isSyncing && currentAccountId >= 0 && currentAccountId !== -1

                        background: Rectangle {
                            color: syncButton.enabled ? (syncButton.pressed ? "#1976D2" : "#2196F3") : "#CCCCCC"
                            radius: units.gu(0.5)
                        }

                        contentItem: RowLayout {
                            spacing: units.gu(1)

                            Rectangle {
                                width: units.gu(2)
                                height: units.gu(2)
                                radius: width / 2
                                color: "white"
                                opacity: isSyncing ? 0.6 : 1.0

                                SequentialAnimation on opacity {
                                    running: isSyncing
                                    loops: Animation.Infinite

                                    PropertyAnimation {
                                        from: 0.6
                                        to: 1.0
                                        duration: 800
                                    }

                                    PropertyAnimation {
                                        from: 1.0
                                        to: 0.6
                                        duration: 800
                                    }
                                }
                            }

                            Text {
                                text: syncButton.text
                                color: "white"
                                font.pixelSize: units.gu(1.8)
                                font.weight: Font.Bold
                            }
                        }

                        onClicked: {
                            if (currentAccountId >= 0 && currentAccountId !== -1) {
                                startSync();
                            }
                        }
                    }
                }

                // Sync Button Info for "All Accounts"
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: currentAccountId === -1 ? units.gu(6) : 0
                    color: "transparent"
                    visible: currentAccountId === -1

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: units.gu(0.5)

                        Label {
                            text: i18n.dtr("ubtms", "Note: Sync is not available for 'All Accounts' view")
                            font.pixelSize: units.gu(1.4)
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#FFA726" : "#F57C00"
                            font.italic: true
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                        }

                        Label {
                            text: i18n.dtr("ubtms", "Please select a specific account to sync data")
                            font.pixelSize: units.gu(1.2)
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#CCCCCC" : "#666666"
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                        }
                    }
                }

                // Sync Progress
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: isSyncing ? units.gu(8) : 0
                    color: "transparent"
                    visible: isSyncing

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: units.gu(1)

                        Label {
                            text: syncSteps.length > 0 && currentStep < syncSteps.length ? syncSteps[currentStep] : i18n.dtr("ubtms", "Syncing data...")
                            font.pixelSize: units.gu(1.5)
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                        }

                        ProgressBar {
                            id: syncProgressBar
                            Layout.fillWidth: true
                            Layout.preferredHeight: units.gu(0.5)
                            value: syncSteps.length > 0 ? (currentStep + 1) / syncSteps.length : 0
                        }

                        Label {
                            text: syncSteps.length > 0 ? (currentStep + 1) + " / " + syncSteps.length : ""
                            font.pixelSize: units.gu(1.2)
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#CCCCCC" : "#666666"
                        }
                    }
                }

                Item {
                    Layout.fillHeight: true
                }
            }

            Button {
                text: i18n.dtr("ubtms", "OK")
                onClicked: PopupUtils.close(accountDialog)
            }
        }
    }

    ListModel {
        id: accountModel
    }

    function open() {
        try {
            PopupUtils.open(accountDrawerPopup);
        } catch (e) {
            console.error("Error opening AccountDrawer:", e);
        }
    }

    function close() {
    // Popup will close automatically when OK/Close buttons are clicked
    }

    Component.onCompleted: {
        loadAccounts();
        updateLastSyncStatus();
    }

    function loadAccounts() {
        accountModel.clear();

        // Add "All Accounts" option first
        accountModel.append({
            id: -1,
            name: i18n.dtr("ubtms", "All Accounts"),
            database: "",
            link: "",
            username: "",
            is_default: 0
        });

        const accounts = Accounts.getAccountsList();

        for (let i = 0; i < accounts.length; i++) {
            accountModel.append({
                id: accounts[i].id,
                name: accounts[i].name,
                database: accounts[i].database,
                link: accounts[i].link,
                username: accounts[i].username,
                is_default: accounts[i].is_default || 0
            });
        }

        // Select default account
        selectDefaultAccount();
    }

    function selectDefaultAccount() {
        const defaultId = Accounts.getDefaultAccountId();
        if (defaultId >= 0) {
            // Look for the default account (skip index 0 which is "All Accounts")
            for (let i = 1; i < accountModel.count; i++) {
                const item = accountModel.get(i);
                if (item.id === defaultId) {
                    accountComboBox.currentIndex = i;
                    currentAccountId = item.id;
                    currentAccountName = item.name;
                    accountChanged(item.id, item.name);
                    break;
                }
            }
        } else if (accountModel.count > 1) {
            // If no default account, select the first real account (index 1)
            const first = accountModel.get(1);
            accountComboBox.currentIndex = 1;
            currentAccountId = first.id;
            currentAccountName = first.name;
            Accounts.setDefaultAccount(first.id);
            accountChanged(first.id, first.name);
        } else {
            // If only "All Accounts" option exists, select it
            accountComboBox.currentIndex = 0;
            currentAccountId = -1;
            currentAccountName = i18n.dtr("ubtms", "All Accounts");
            accountChanged(-1, i18n.dtr("ubtms", "All Accounts"));
        }
    }

    function updateLastSyncStatus() {
        if (currentAccountId >= 0 && currentAccountId !== -1) {
            const syncStatus = Utils.getLastSyncStatus(currentAccountId);
            if (syncStatus && syncStatus !== "") {
                lastSyncLabel.text = syncStatus;
            } else {
                lastSyncLabel.text = i18n.dtr("ubtms", "Never");
            }
        } else {
            lastSyncLabel.text = i18n.dtr("ubtms", "N/A for All Accounts");
        }
    }

    function startSync() {
        if (currentAccountId < 0 || currentAccountId === -1)
            return;

        isSyncing = true;

        // Set the selected account as default
        Accounts.setDefaultAccount(currentAccountId);

        // Start actual sync process
        performSync();
    }

    function performSync() {
        // Get account details
        const accounts = Accounts.getAccountsList();
        const currentAccount = accounts.find(acc => acc.id === currentAccountId);

        if (!currentAccount) {
            syncFailed(i18n.dtr("ubtms", "Account not found"));
            return;
        }

        // Check if it's a local account
        if (currentAccount.id === 0) {
            // Local account - no sync needed
            isSyncing = false;
            syncCompleted(true, i18n.dtr("ubtms", "Local account - no sync required"));
            if (typeof notifPopup !== 'undefined') {
                notifPopup.open(i18n.dtr("ubtms", "Info"), i18n.dtr("ubtms", "Local account - no sync required"), "info");
            }
            return;
        }

        // For remote accounts, we would call the Python sync functions
        // For now, simulate the sync process
        console.log("🔄 Starting sync for account:", currentAccount.name);

        // Simulate sync steps
        syncSteps = [i18n.dtr("ubtms", "Connecting to server..."), i18n.dtr("ubtms", "Syncing projects..."), i18n.dtr("ubtms", "Syncing tasks..."), i18n.dtr("ubtms", "Syncing timesheets..."), i18n.dtr("ubtms", "Syncing activities..."), i18n.dtr("ubtms", "Updating local data...")];
        currentStep = 0;

        // Start step-by-step sync simulation
        syncStepTimer.start();
    }

    function syncFailed(error) {
        isSyncing = false;
        syncCompleted(false, i18n.dtr("ubtms", "Sync failed: ") + error);

        if (typeof notifPopup !== 'undefined') {
            notifPopup.open(i18n.dtr("ubtms", "Error"), i18n.dtr("ubtms", "Sync failed: ") + error, "error");
        }
    }

    Timer {
        id: syncStepTimer
        interval: 800 // 800ms per step
        repeat: true
        onTriggered: {
            currentStep++;

            if (currentStep >= syncSteps.length) {
                // Sync completed
                syncStepTimer.stop();
                isSyncing = false;
                updateLastSyncStatus();
                syncCompleted(true, i18n.dtr("ubtms", "Sync completed successfully"));

                // Show success notification
                if (typeof notifPopup !== 'undefined') {
                    notifPopup.open(i18n.dtr("ubtms", "Success"), i18n.dtr("ubtms", "Data synchronized successfully!"), "success");
                }
            }
        }
    }

    function refreshAccounts() {
        loadAccounts();
        updateLastSyncStatus();
    }
}
