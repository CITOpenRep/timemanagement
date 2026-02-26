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
import Lomiri.Components 1.3
import QtQuick.Window 2.2
import QtQuick.LocalStorage 2.7 as Sql
import io.thp.pyotherside 1.4
import "../models/accounts.js" as Accounts
import "../models/utils.js" as Utils
import "components"

Page {
    id: createAccountPage
    title: accountId !== -1 ? i18n.dtr("ubtms", "Edit Account") : i18n.dtr("ubtms", "Create Account")

    property bool isTextInputVisible: false
    property bool isTextMenuVisible: false
    property bool connectionSuccess: false
    property bool isValidUrl: true
    property bool isValidAccount: true
    property bool isPasswordVisible: false
    property int selectedconnectwithId: 1
    property string single_db: ""
    property bool activeBackendAccount: false
    property bool isManualDbMode: false

    property bool isReadOnly: false
    property int accountId: -1  // -1 means create mode, otherwise edit mode
    property bool useCustomSyncSettings: false  // Whether per-account sync overrides are enabled

    header: PageHeader {
        id: pageHeader
        title: createAccountPage.title
        StyleHints {
            foregroundColor: "white"

            backgroundColor: LomiriColors.orange
            dividerColor: LomiriColors.slate
        }
        trailingActionBar.actions: [
            Action {
                iconSource: "images/save.svg"
                visible: !isReadOnly
                text: i18n.dtr("ubtms","Save")
                
                onTriggered: {
                    handleAccountSave();
                }
            },
            Action {
                iconName: "edit"
                visible: isReadOnly
                text: i18n.dtr("ubtms","Edit")
                onTriggered: {
                    switchToEditMode();
                }
            }
        ]
    }

    function switchToEditMode() {
        isReadOnly = false;
    }

    function handleAccountSave() {
        if (!accountNameInput.text) {
            notifPopup.open("Error", "Account name cannot be empty", "error");
            return;
        }

        var dbname = "";
        if (isManualDbMode) {
            dbname = manualDbInput.text;
        } else {
            dbname = database_combo.currentText;
        }

        if (!linkInput.text.trim()) {
            notifPopup.open("Error", "Server URL cannot be empty", "error");
            return;
        }

        if (!usernameInput.text.trim()) {
            notifPopup.open("Error", "Username cannot be empty", "error");
            return;
        }

        if (!passwordInput.text.trim()) {
            notifPopup.open("Error", "Password/API Key cannot be empty", "error");
            return;
        }

        if (!dbname.trim()) {
            notifPopup.open("Error", "Database name cannot be empty", "error");
            return;
        }

        python.call("backend.login_odoo", [linkInput.text, usernameInput.text, passwordInput.text, dbname], function (result) {
            if (result && result['status'] === 'pass' && result['database']) {
                let apikey = passwordInput.text;

                var accountResult;
                if (accountId !== -1) {
                    // Edit mode - update existing account
                    accountResult = Accounts.updateAccount(accountId, accountNameInput.text, linkInput.text, result['database'], usernameInput.text, selectedconnectwithId, apikey);
                    
                    if (!accountResult.success) {
                        if (accountResult.duplicateType === "name") {
                            notifPopup.open("Error", "Account name '" + accountNameInput.text + "' already exists. Please choose a different name.", "error");
                        } else if (accountResult.duplicateType === "connection") {
                            notifPopup.open("Error", "An account with this server connection already exists.", "error");
                        } else {
                            notifPopup.open("Error", accountResult.message || "Unable to update account.", "error");
                        }
                    } else {
                        savePerAccountSyncSettings(accountId);
                        notifPopup.open("Saved", i18n.dtr("ubtms","Your account has been updated successfully!"), "success");
                        isReadOnly = true;
                        // Signal to refresh accounts list in Settings_Page
                        if (typeof settings !== 'undefined') {
                            settings.fetch_accounts();
                        }
                    }
                } else {
                    // Create mode - create new account
                    accountResult = Accounts.createAccount(accountNameInput.text, linkInput.text, result['database'], usernameInput.text, selectedconnectwithId, apikey);

                    if (accountResult.duplicateFound) {
                        if (accountResult.duplicateType === "name") {
                            notifPopup.open("Error", "Account name '" + accountNameInput.text + "' already exists. Please choose a different name.", "error");
                        } else if (accountResult.duplicateType === "connection") {
                            notifPopup.open("Error", "An account with this server connection already exists.", "error");
                        } else {
                            notifPopup.open("Error", accountResult.message || "Unable to create account due to duplicate data.", "error");
                        }
                    } else {
                        // For new accounts, get the newly created account's ID to save sync settings
                        var newAccounts = Accounts.getAccountsList();
                        for (var a = 0; a < newAccounts.length; a++) {
                            if (newAccounts[a].name === accountNameInput.text) {
                                savePerAccountSyncSettings(newAccounts[a].id);
                                break;
                            }
                        }
                        notifPopup.open("Saved", i18n.dtr("ubtms","Your account has been saved, Enjoy using the app !"), "success");
                        isReadOnly = true;
                    }
                }
            } else {
                notifPopup.open("Error", "Unable to save the account. Please check the URL, database name, or your credentials.", "error");
            }
        });
    }

    function loadAccountForEdit(accId) {
        console.log("Loading account for edit:", accId);
        accountId = accId;
        
        var accountsList = Accounts.getAccountsList();
        for (var i = 0; i < accountsList.length; i++) {
            if (accountsList[i].id === accId) {
                var account = accountsList[i];
                console.log("Found account:", account.name);
                
                // Populate form fields
                accountNameInput.text = account.name;
                linkInput.text = account.link;
                usernameInput.text = account.username;
                passwordInput.text = account.api_key || "";
                selectedconnectwithId = account.connectwith_id || 1;
                
                // Fetch databases for this URL
                python.call("backend.list_databases", [account.link], function(databases) {
                    if (databases && databases.length > 0) {
                        databaseListModel.clear();
                        for (var j = 0; j < databases.length; j++) {
                            databaseListModel.append({"name": databases[j]});
                        }
                        
                        // Set the current database as selected
                        for (var k = 0; k < databases.length; k++) {
                            if (databases[k] === account.database) {
                                database_combo.currentIndex = k;
                                break;
                            }
                        }
                    } else {
                        // No databases found or error, enable manual mode
                        isManualDbMode = true;
                        manualDbInput.text = account.database;
                    }
                });
                
                // Set read-only mode initially
                isReadOnly = true;
                activeBackendAccount = true;
                
                // Load per-account sync settings
                var syncSettings = Accounts.getAccountSyncSettings(accId);
                if (syncSettings.sync_interval_minutes !== null ||
                    syncSettings.sync_direction !== null ||
                    syncSettings.autosync_enabled !== null) {
                    useCustomSyncSettings = true;
                    
                    // Set interval combo
                    var intervalValues = ["1", "5", "15", "30", "60"];
                    var savedInterval = String(syncSettings.sync_interval_minutes || getGlobalSyncDefault("sync_interval_minutes"));
                    for (var si = 0; si < intervalValues.length; si++) {
                        if (intervalValues[si] === savedInterval) {
                            syncIntervalCombo.currentIndex = si;
                            break;
                        }
                    }
                    
                    // Set direction combo
                    var directionValues = ["both", "download_only", "upload_only"];
                    var savedDirection = syncSettings.sync_direction || getGlobalSyncDefault("sync_direction");
                    for (var di = 0; di < directionValues.length; di++) {
                        if (directionValues[di] === savedDirection) {
                            syncDirectionCombo.currentIndex = di;
                            break;
                        }
                    }
                    
                    // Set enable switch
                    perAccountSyncSwitch.checked = (syncSettings.autosync_enabled === null) ? true : (syncSettings.autosync_enabled === 1);
                } else {
                    useCustomSyncSettings = false;
                }
                
                break;
            }
        }
    }
    
    Component.onCompleted: {
        // If accountId is set (edit mode), load the account data
        if (accountId !== -1) {
            loadAccountForEdit(accountId);
        }
    }

    function clearForm() {
        accountNameInput.text = "";
        linkInput.text = "";
        usernameInput.text = "";
        passwordInput.text = "";
        manualDbInput.text = "";
        databaseListModel.clear();
        activeBackendAccount = false;
        accountId = -1;
        isManualDbMode = false;
        database_combo.currentIndex = -1;
        useCustomSyncSettings = false;
    }

    // Read a global sync default from app_settings table
    function getGlobalSyncDefault(key) {
        var defaults = {
            "autosync_enabled": "true",
            "sync_interval_minutes": "15",
            "sync_direction": "both"
        };
        try {
            var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
            var result = defaults[key] || "";
            db.transaction(function (tx) {
                tx.executeSql('CREATE TABLE IF NOT EXISTS app_settings (key TEXT PRIMARY KEY, value TEXT)');
                var rs = tx.executeSql('SELECT value FROM app_settings WHERE key = ?', [key]);
                if (rs.rows.length > 0) {
                    result = rs.rows.item(0).value;
                }
            });
            return result;
        } catch (e) {
            return defaults[key] || "";
        }
    }

    // Save per-account sync settings after account is saved
    function savePerAccountSyncSettings(accId) {
        if (!useCustomSyncSettings) {
            // Reset to global defaults (NULL)
            Accounts.updateAccountSyncSettings(accId, null, null, null);
            return;
        }
        var intervalValues = ["1", "5", "15", "30", "60"];
        var directionValues = ["both", "download_only", "upload_only"];
        var interval = parseInt(intervalValues[syncIntervalCombo.currentIndex]) || 15;
        var direction = directionValues[syncDirectionCombo.currentIndex] || "both";
        var enabled = perAccountSyncSwitch.checked ? 1 : 0;
        Accounts.updateAccountSyncSettings(accId, interval, direction, enabled);
    }

    Python {
        id: python

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('../src/'));
            importModule_sync("backend");
        }

        onError: {}
    }

    ListModel {
        id: databaseListModel
    }

    ListModel {
        id: menuconnectwithModel
        ListElement {
            modelData: "Connect With Api Key"
            itemid: 0
        }
        ListElement {
            modelData: "Connect With Password"
            itemid: 1
        }
    }

    Flickable {
        id: accountPageFlickable
        anchors.fill: parent
        contentHeight: signup_shape.height + 1500
        flickableDirection: Flickable.VerticalFlick
        anchors.top: pageHeader.bottom
        anchors.topMargin: pageHeader.height + units.gu(4)
        width: parent.width
        LomiriShape {
            id: signup_shape
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            radius: "large"
            width: parent.width
            height: parent.height
            Row {
                id: accountRow
                anchors.topMargin: 5
                Column {
                    leftPadding: units.gu(2)
                    Item {
                        width: units.gu(12)
                        height: units.gu(4)
                        TSLabel {
                            id: account_name_label
                            text: i18n.dtr("ubtms", "Account Name")
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
                Column {
                    leftPadding: units.gu(1)
                    Item {
                        width: units.gu(28)
                        height: units.gu(5)
                        TextField {
                            id: accountNameInput
                            enabled: !isReadOnly
                            anchors.horizontalCenter: parent.horizontalCenter
                            placeholderText:i18n.dtr("ubtms", "Account Name")
                            width: parent.width
                        }
                    }
                }
            }

            Row {
                id: linkRow
                anchors.top: accountRow.bottom
                // anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: units.gu(2)
                Column {
                    leftPadding: units.gu(2)
                    Item {
                        width: units.gu(12)
                        height: units.gu(4)
                        TSLabel {
                            id: link_label
                            text: "URL"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
                Column {
                    leftPadding: units.gu(1)
                    spacing: units.gu(1)
                    Item {
                        width: units.gu(28)
                        height: units.gu(4)
                        TextField {
                            id: linkInput
                            enabled: !isReadOnly
                            placeholderText: i18n.dtr("ubtms", "Enter Odoo URL here")
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width
                            height: parent.height
                            onTextChanged: {
                                text = text.toLowerCase();
                            }
                        }
                    }
                    TSButton {
                        id: fetch_db_button
                        text: i18n.dtr("ubtms", "Fetch Databases")
                        visible: !isReadOnly
                        width: units.gu(28)
                        height: units.gu(4)
                        onClicked: {
                            databaseListModel.clear();
                            text = text.toLowerCase();
                            let result = Utils.validateAndCleanOdooURL(linkInput.text);
                            if (result.isValid) {
                                isManualDbMode = false;
                                activeBackendAccount = false;
                                linkInput.text = result.cleanedUrl;
                                isValidUrl = true;
                                Utils.getDatabasesFromOdooServer(linkInput.text, function (dbList) {
                                    if (dbList.length === 0) {
                                        isManualDbMode = true;
                                        activeBackendAccount = true;
                                        notifPopup.open("Error", "Unable to fetch the DBs from the Server (may be due to security), please enter it manually below", "error");
                                    }

                                    for (var i = 0; i < dbList.length; i++) {
                                        databaseListModel.append({
                                            name: dbList[i]
                                        });
                                        activeBackendAccount = true;
                                    }

                                    if (dbList.length > 0) {
                                        database_combo.currentIndex = 0;
                                    }
                                });
                            } else {
                                console.error("Invalid DB URL");
                                notifPopup.open("Error", "The Odoo Server URL is Wrong", "error");
                                activeBackendAccount = false;
                            }
                        }
                    }
                }
            }

            Row {
                id: databaseListRow
                anchors.top: linkRow.bottom

                Column {
                    leftPadding: units.gu(2)
                    Item {
                        width: units.gu(12)
                        height: units.gu(3)
                        TSLabel {
                            id: database_list_label
                            text: i18n.dtr("ubtms", "Database")
                            anchors.verticalCenter: parent.verticalCenter
                            visible: activeBackendAccount
                        }
                    }
                }

                Column {
                    leftPadding: units.gu(1)

                    // ComboBox shown only if databases were fetched
                    Item {
                        width: units.gu(28)
                        height: units.gu(5)
                        visible: activeBackendAccount && !isManualDbMode
                        ComboBox {
                            id: database_combo
                            width: parent.width
                            enabled: !isReadOnly
                            height: parent.height
                            background: Rectangle {
                                color: "transparent"
                                border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#d3d1d1" : "#999"
                                border.width: 1
                                radius: units.gu(0.5)
                            }
                            flat: true
                            model: databaseListModel
                            contentItem: Text {
                                text: database_combo.displayText
                                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                                anchors.verticalCenter: parent.verticalCenter
                                leftPadding: units.gu(2)
                            }
                            delegate: ItemDelegate {
                                width: database_combo.width
                                hoverEnabled: true
                                contentItem: Text {
                                    text: model.name
                                    color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                                    leftPadding: units.gu(1)
                                    elide: Text.ElideRight
                                }
                                background: Rectangle {
                                    color: hovered ? (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#444" : "#e0e0e0") : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#222" : "white")
                                    radius: 4
                                }
                            }
                        }
                    }

                    // Manual TextField shown when DB list fetch fails
                    Item {
                        width: units.gu(28)
                        height: units.gu(5)
                        visible: isManualDbMode
                        TextField {
                            id: manualDbInput
                            width: parent.width
                            placeholderText: i18n.dtr("ubtms", "Enter Database Name")
                        }
                    }
                }
            }

            Row {
                id: usernameRow
                anchors.top: databaseListRow.bottom
                anchors.topMargin: units.gu(3)
                Column {
                    leftPadding: units.gu(2)
                    Item {
                        width: units.gu(12)
                        height: units.gu(4)
                        TSLabel {
                            id: username_label
                            visible: activeBackendAccount
                            text: i18n.dtr("ubtms", "Username")
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
                Column {
                    leftPadding: units.gu(1)
                    Item {
                        width: units.gu(28)
                        height: units.gu(5)
                        TextField {
                            id: usernameInput
                            visible: activeBackendAccount
                            enabled: !isReadOnly
                            placeholderText: i18n.dtr("ubtms", "Username")
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width
                        }
                    }
                }
            }

            Row {
                id: connectWithRow
                anchors.top: usernameRow.bottom
                anchors.topMargin: units.gu(2)
                Column {
                    leftPadding: units.gu(2)
                    Item {
                        width: units.gu(12)
                        height: units.gu(5)
                        TSLabel {
                            id: connectwith_label
                            text: i18n.dtr("ubtms", "Connect With")
                            visible: activeBackendAccount
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
                Column {
                    leftPadding: units.gu(1)
                    ComboBox {
                        id: connectWith_combo
                        enabled: !isReadOnly
                        width: units.gu(28)
                        height: units.gu(5)
                        visible: activeBackendAccount

                        background: Rectangle {
                            color: "transparent"
                            border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#d3d1d1" : "#999"
                            border.width: 1
                            radius: units.gu(0.5)
                        }
                        anchors.centerIn: parent.centerIn
                        flat: true
                        model: menuconnectwithModel
                        contentItem: Text {
                            text: connectWith_combo.displayText
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                            anchors.verticalCenter: parent.verticalCenter
                            leftPadding: units.gu(2)
                        }
                        delegate: ItemDelegate {
                            width: connectWith_combo.width
                            hoverEnabled: true
                            contentItem: Text {
                                text: i18n.dtr("ubtms", model.modelData)
                                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                                leftPadding: units.gu(1)
                                elide: Text.ElideRight
                            }
                            background: Rectangle {
                                color: hovered ? (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#444" : "#e0e0e0") : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#222" : "white")
                                radius: 4
                            }
                        }
                    }
                }
            }

            Row {
                id: passwordRow
                anchors.top: connectWithRow.bottom
                anchors.topMargin: units.gu(3)
                Column {
                    leftPadding: units.gu(2)
                    Item {
                        width: units.gu(12)
                        height: units.gu(4)
                        TSLabel {
                            id: password_label
                            visible: activeBackendAccount
                            text: connectWith_combo.currentIndex == 1 ? "Password" : "API Key"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
                Column {
                    leftPadding: units.gu(1)
                    Item {
                        width: units.gu(23)
                        height: units.gu(5)
                        TextField {
                            id: passwordInput
                            enabled: !isReadOnly
                            visible: activeBackendAccount
                            echoMode: isPasswordVisible ? TextInput.Normal : TextInput.Password
                            placeholderText: connectWith_combo.currentIndex == 1 ? "Password" : "API Key"
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width
                        }
                    }
                }
                Column {
                    TSButton {
                        enabled: !isReadOnly
                        width: units.gu(5)
                        height: passwordInput.height
                        visible: activeBackendAccount
                        fontSize: units.gu(1.2)
                        text: isPasswordVisible ? i18n.dtr("ubtms", "Hide") : i18n.dtr("ubtms","show")
                        onClicked: {
                            isPasswordVisible = !isPasswordVisible;
                        }
                    }
                }
            }

            // =============================================================
            // PER-ACCOUNT SYNC SETTINGS SECTION
            // =============================================================
            Rectangle {
                id: syncSettingsSection
                visible: activeBackendAccount
                anchors.top: passwordRow.bottom
                anchors.topMargin: units.gu(3)
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: units.gu(1)
                anchors.rightMargin: units.gu(1)
                height: syncSettingsColumn.height + units.gu(2)
                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#1a1a1a" : "#f8f8f8"
                border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#444" : "#ddd"
                border.width: 1
                radius: units.gu(1)

                Column {
                    id: syncSettingsColumn
                    width: parent.width - units.gu(2)
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: units.gu(1)
                    spacing: units.gu(1.5)

                    // Section header
                    Text {
                        text: i18n.dtr("ubtms", "Sync Settings")
                        font.pixelSize: units.gu(2)
                        font.bold: true
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#e0e0e0" : "#333"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    // Custom sync toggle
                    Row {
                        width: parent.width
                        spacing: units.gu(2)
                        Text {
                            text: i18n.dtr("ubtms", "Custom Sync Settings")
                            font.pixelSize: units.gu(1.8)
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#e0e0e0" : "#333"
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - customSyncCheckbox.width - units.gu(4)
                        }
                        CheckBox {
                            id: customSyncCheckbox
                            checked: useCustomSyncSettings
                            enabled: !isReadOnly
                            anchors.verticalCenter: parent.verticalCenter
                            onCheckedChanged: {
                                useCustomSyncSettings = checked;
                            }
                        }
                    }

                    // Info when using defaults
                    Text {
                        visible: !useCustomSyncSettings
                        text: i18n.dtr("ubtms", "Using global sync defaults (interval: ") +
                              getGlobalSyncDefault("sync_interval_minutes") +
                              i18n.dtr("ubtms", " min, direction: ") +
                              getGlobalSyncDefault("sync_direction") + ")"
                        font.pixelSize: units.gu(1.3)
                        font.italic: true
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#888" : "#888"
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }

                    // Per-account enable/disable toggle
                    Row {
                        width: parent.width
                        visible: useCustomSyncSettings
                        spacing: units.gu(2)
                        Text {
                            text: i18n.dtr("ubtms", "Enable Sync")
                            font.pixelSize: units.gu(1.8)
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#e0e0e0" : "#333"
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - perAccountSyncSwitch.width - units.gu(4)
                        }
                        Switch {
                            id: perAccountSyncSwitch
                            checked: true
                            enabled: !isReadOnly
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Sync Interval
                    Column {
                        width: parent.width
                        visible: useCustomSyncSettings
                        spacing: units.gu(0.5)

                        Text {
                            text: i18n.dtr("ubtms", "Sync Interval")
                            font.pixelSize: units.gu(1.6)
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#b0b0b0" : "#666"
                        }

                        ComboBox {
                            id: syncIntervalCombo
                            width: parent.width
                            enabled: !isReadOnly && perAccountSyncSwitch.checked
                            model: ["1 minute", "5 minutes", "15 minutes", "30 minutes", "60 minutes"]
                            currentIndex: 2  // Default: 15 minutes
                            background: Rectangle {
                                color: "transparent"
                                border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#d3d1d1" : "#999"
                                border.width: 1
                                radius: units.gu(0.5)
                            }
                            contentItem: Text {
                                text: syncIntervalCombo.displayText
                                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: units.gu(2)
                            }
                            delegate: ItemDelegate {
                                width: syncIntervalCombo.width
                                hoverEnabled: true
                                contentItem: Text {
                                    text: modelData
                                    color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                                    leftPadding: units.gu(1)
                                }
                                background: Rectangle {
                                    color: hovered ? (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#444" : "#e0e0e0") : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#222" : "white")
                                    radius: 4
                                }
                            }
                        }
                    }

                    // Sync Direction
                    Column {
                        width: parent.width
                        visible: useCustomSyncSettings
                        spacing: units.gu(0.5)

                        Text {
                            text: i18n.dtr("ubtms", "Sync Direction")
                            font.pixelSize: units.gu(1.6)
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#b0b0b0" : "#666"
                        }

                        ComboBox {
                            id: syncDirectionCombo
                            width: parent.width
                            enabled: !isReadOnly && perAccountSyncSwitch.checked
                            model: ["Both (Up & Down)", "Download Only", "Upload Only"]
                            currentIndex: 0  // Default: both
                            background: Rectangle {
                                color: "transparent"
                                border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#d3d1d1" : "#999"
                                border.width: 1
                                radius: units.gu(0.5)
                            }
                            contentItem: Text {
                                text: syncDirectionCombo.displayText
                                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: units.gu(2)
                            }
                            delegate: ItemDelegate {
                                width: syncDirectionCombo.width
                                hoverEnabled: true
                                contentItem: Text {
                                    text: modelData
                                    color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                                    leftPadding: units.gu(1)
                                }
                                background: Rectangle {
                                    color: hovered ? (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#444" : "#e0e0e0") : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#222" : "white")
                                    radius: 4
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    NotificationPopup {
        id: notifPopup
        width: units.gu(80)
        height: units.gu(80)
    }
}
