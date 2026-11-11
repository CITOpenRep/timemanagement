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
import Lomiri.Components.Themes.Ambiance 1.3
import QtQuick.Window 2.2
import QtQuick.LocalStorage 2.7 as Sql
import io.thp.pyotherside 1.4
import "../../../../models/accounts.js" as Accounts
import "../../../../models/utils.js" as Utils
import "../../../components"

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
    property bool openInEditMode: false

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
                iconName: "tick"
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
        accountNameInput.text = (accountNameInput.text || "").trim();
        if (!accountNameInput.text) {
            notifPopup.open("Error", "Account name cannot be empty", "error");
            return;
        }

        var dbname = "";
        if (isManualDbMode) {
            dbname = manualDbInput.text || "";
        } else {
            dbname = databaseSelector.selectedName || "";
        }

        if (!linkInput.text || !linkInput.text.trim()) {
            notifPopup.open("Error", "Server URL cannot be empty", "error");
            return;
        }

        var urlResult = Utils.validateAndCleanOdooURL(linkInput.text);
        if (!urlResult.isValid) {
            notifPopup.open("Error", "The Odoo Server URL is Wrong", "error");
            return;
        }

        linkInput.text = urlResult.cleanedUrl;
        usernameInput.text = (usernameInput.text || "").trim();
        passwordInput.text = (passwordInput.text || "").trim();
        dbname = dbname.trim();

        if (!usernameInput.text) {
            notifPopup.open("Error", "Username cannot be empty", "error");
            return;
        }

        if (!passwordInput.text) {
            notifPopup.open("Error", "Password/API Key cannot be empty", "error");
            return;
        }

        if (!dbname) {
            notifPopup.open("Error", "Database name cannot be empty", "error");
            return;
        }

        python.call("backend.login_odoo", [linkInput.text, usernameInput.text, passwordInput.text, dbname], function (result) {
            if (result && result['status'] === 'pass' && result['database']) {
                let apikey = passwordInput.text;

                var accountResult;
                var bridge = (typeof mainView !== "undefined" && mainView.backend_bridge) ? mainView.backend_bridge : ((typeof backend_bridge !== "undefined" && backend_bridge) ? backend_bridge : null);

                if (accountId !== -1) {
                    // Edit mode - update existing account
                    accountResult = Accounts.updateAccount(accountId, accountNameInput.text, linkInput.text, result['database'], usernameInput.text, selectedconnectwithId, apikey, result['uid'], result['name_of_user']);
                    
                    if (!accountResult.success) {
                        if (accountResult.duplicateType === "name") {
                            notifPopup.open("Error", "Account name '" + accountNameInput.text + "' already exists. Please choose a different name.", "error");
                        } else if (accountResult.duplicateType === "connection") {
                            notifPopup.open("Error", "An account with this server connection already exists.", "error");
                        } else {
                            notifPopup.open("Error", accountResult.message || "Unable to update account.", "error");
                        }
                    } else {
                        notifPopup.open("Saved", i18n.dtr("ubtms","Your account has been updated successfully!"), "success");
                        isReadOnly = true;
                        if (typeof mainView !== "undefined" && mainView.startupManager && bridge) {
                            mainView.startupManager.initializePushNotifications(bridge);
                        } else if (bridge) {
                            bridge.call("backend.save_push_token", [""], function(res) {});
                        }
                        // Signal to refresh accounts list in Settings_Page
                        if (typeof settings !== 'undefined' && typeof settings.fetch_accounts === 'function') {
                            settings.fetch_accounts();
                        }
                        if (typeof mainView !== "undefined" && mainView && mainView.accountDataRefreshRequested) {
                            mainView.accountDataRefreshRequested(accountId);
                        }
                    }
                } else {
                    // Create mode - create new account
                    accountResult = Accounts.createAccount(accountNameInput.text, linkInput.text, result['database'], usernameInput.text, selectedconnectwithId, apikey, result['uid'], result['name_of_user']);

                    if (accountResult.duplicateFound) {
                        if (accountResult.duplicateType === "name") {
                            notifPopup.open("Error", "Account name '" + accountNameInput.text + "' already exists. Please choose a different name.", "error");
                        } else if (accountResult.duplicateType === "connection") {
                            notifPopup.open("Error", "An account with this server connection already exists.", "error");
                        } else {
                            notifPopup.open("Error", accountResult.message || "Unable to create account due to duplicate data.", "error");
                        }
                    } else {
                        var newAccountId = accountResult.accountId;
                        if (newAccountId > 0) {
                            accountId = newAccountId;
                        }
                        notifPopup.open("Saved", i18n.dtr("ubtms","Your account has been saved, Enjoy using the app !"), "success");
                        isReadOnly = true;
                        if (typeof mainView !== "undefined" && mainView.startupManager && bridge) {
                            mainView.startupManager.initializePushNotifications(bridge);
                        } else if (bridge) {
                            bridge.call("backend.save_push_token", [""], function(res) {});
                        }

                        // Signal to refresh accounts list in Settings_Page
                        if (typeof settings !== 'undefined' && typeof settings.fetch_accounts === 'function') {
                            settings.fetch_accounts();
                        }

                        if (typeof mainView !== "undefined" && mainView && mainView.accountDataRefreshRequested) {
                            mainView.accountDataRefreshRequested(newAccountId);
                        }

                        // Trigger immediate background sync for the newly created account
                        if (bridge && newAccountId > 0) {
                            bridge.call("backend.resolve_qml_db_path", ["ubtms"], function (path) {
                                var targetDb = path || "app_settings.db";
                                bridge.call("backend.start_sync_in_background", [targetDb, newAccountId], function (syncStarted) {
                                    console.log("Initial background sync initiated for account:", newAccountId, syncStarted);
                                });
                            });
                        }
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
                Utils.getDatabasesFromOdooServer(account.link, function(databases) {
                    if (databases && databases.length > 0) {
                        var dbModelData = [];
                        for (var j = 0; j < databases.length; j++) {
                            dbModelData.push({id: j, name: databases[j]});
                        }
                        databaseSelector.setData(dbModelData);
                        // Select the matching database
                        for (var k = 0; k < databases.length; k++) {
                            if (databases[k] === account.database) {
                                databaseSelector.applyDeferredSelection(k, false);
                                break;
                            }
                        }
                    } else {
                        // No databases found or error, enable manual mode
                        isManualDbMode = true;
                        manualDbInput.text = account.database;
                    }
                });
                
                // Restore connect-with selection
                connectWithSelector.applyDeferredSelection(selectedconnectwithId, false);
                
                // Existing accounts default to read-only unless caller requests direct edit mode.
                isReadOnly = !openInEditMode;
                activeBackendAccount = true;
                
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
        databaseSelector.setData([]);
        databaseSelector.clear();
        activeBackendAccount = false;
        accountId = -1;
        isManualDbMode = false;
    }

    Python {
        id: python

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('../../../../src/'));
            importModule_sync("backend");
        }

        onError: {}
    }

    Rectangle {
        anchors.fill: parent
        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#111111" : "#f2f2f7"
        z: -1
    }

    Flickable {
        id: accountPageFlickable
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Qt.inputMethod.visible ? Qt.inputMethod.keyboardRectangle.height : 0
        anchors.top: pageHeader.bottom
        contentHeight: formColumn.height + units.gu(6)
        flickableDirection: Flickable.VerticalFlick
        clip: true

        Column {
            id: formColumn
            width: parent.width - units.gu(4)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: units.gu(1)
            spacing: units.gu(2)

            // =============================================================
            // SECTION 1: ACCOUNT INFO
            // =============================================================
            Rectangle {
                width: parent.width
                height: accountInfoCol.height + units.gu(3)
                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#1a1a1a" : "white"
                radius: units.gu(1)

                Column {
                    id: accountInfoCol
                    width: parent.width - units.gu(3)
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: units.gu(1.5)
                    spacing: units.gu(2)

                    Text {
                        text: i18n.dtr("ubtms", "Account Details")
                        font.pixelSize: units.gu(1.8)
                        font.bold: true
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#e0e0e0" : "black"
                    }

                    OutlinedTextField {
                        id: accountNameInput
                        width: parent.width
                        readOnly: isReadOnly
                        labelText: i18n.dtr("ubtms", "Account Name")
                        text: ""
                    }
                }
            }

            // =============================================================
            // SECTION 2: SERVER CONNECTION
            // =============================================================
            Rectangle {
                width: parent.width
                height: serverCol.height + units.gu(3)
                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#1a1a1a" : "white"
                radius: units.gu(1)

                Column {
                    id: serverCol
                    width: parent.width - units.gu(3)
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: units.gu(1.5)
                    spacing: units.gu(2)

                    Text {
                        text: i18n.dtr("ubtms", "Server Connection")
                        font.pixelSize: units.gu(1.8)
                        font.bold: true
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#e0e0e0" : "black"
                    }

                    OutlinedTextField {
                        id: linkInput
                        width: parent.width
                        readOnly: isReadOnly
                        labelText: i18n.dtr("ubtms", "URL")
                        placeholderText: "https://"
                        inputMethodHints: Qt.ImhUrlCharactersOnly
                    }

                    TSButton {
                        id: fetch_db_button
                        text: i18n.dtr("ubtms", "Fetch Databases")
                        visible: !isReadOnly
                        width: parent.width
                        height: units.gu(5)
                       // bgColor: "#00b894"
                        fgColor: "white"
                        radius: units.gu(0.8)
                        onClicked: {
                            databaseSelector.setData([]);
                            linkInput.text = linkInput.text.toLowerCase();
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

                                    var dbModelData = [];
                                    for (var i = 0; i < dbList.length; i++) {
                                        dbModelData.push({id: i, name: dbList[i]});
                                        activeBackendAccount = true;
                                    }
                                    databaseSelector.setData(dbModelData);

                                    if (dbList.length > 0) {
                                        databaseSelector.applyDeferredSelection(0, false);
                                    }
                                });
                            } else {
                                console.error("Invalid DB URL");
                                notifPopup.open("Error", "The Odoo Server URL is Wrong", "error");
                                activeBackendAccount = false;
                            }
                        }
                    }

                    InlineOptionSelector {
                        id: databaseSelector
                        width: parent.width
                        visible: activeBackendAccount && !isManualDbMode
                        labelText: i18n.dtr("ubtms", "Database")
                        selectorType: "database"
                        readOnly: isReadOnly
                        enabledState: !isReadOnly
                    }

                    OutlinedTextField {
                        id: manualDbInput
                        width: parent.width
                        visible: isManualDbMode
                        labelText: i18n.dtr("ubtms", "Database Name")
                    }
                }
            }

            // =============================================================
            // SECTION 3: CREDENTIALS
            // =============================================================
            Rectangle {
                width: parent.width
                height: credCol.height + units.gu(3)
                visible: activeBackendAccount
                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#1a1a1a" : "white"
                radius: units.gu(1)

                Column {
                    id: credCol
                    width: parent.width - units.gu(3)
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: units.gu(1.5)
                    spacing: units.gu(2)

                    Text {
                        text: i18n.dtr("ubtms", "Credentials")
                        font.pixelSize: units.gu(1.8)
                        font.bold: true
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#e0e0e0" : "black"
                    }

                    OutlinedTextField {
                        id: usernameInput
                        width: parent.width
                        readOnly: isReadOnly
                        labelText: i18n.dtr("ubtms", "Username")
                    }

                    InlineOptionSelector {
                        id: connectWithSelector
                        width: parent.width
                        labelText: i18n.dtr("ubtms", "Connect With")
                        selectorType: "connectwith"
                        modelData: [
                            {id: 0, name: i18n.dtr("ubtms", "Connect With Api Key")},
                            {id: 1, name: i18n.dtr("ubtms", "Connect With Password")}
                        ]
                        selectedId: selectedconnectwithId
                        readOnly: isReadOnly
                        onSelectionMade: {
                            selectedconnectwithId = id;
                        }
                    }

                    OutlinedTextField {
                        id: passwordInput
                        width: parent.width
                        readOnly: isReadOnly
                        labelText: connectWithSelector.selectedId === 1 ? i18n.dtr("ubtms", "Password") : i18n.dtr("ubtms", "API Key")
                        echoMode: isPasswordVisible ? TextInput.Normal : TextInput.Password
                        
                        Icon {
                            name: isPasswordVisible ? "view-on" : "view-off"
                            width: units.gu(2.5)
                            height: units.gu(2.5)
                            anchors.right: parent.right
                            anchors.rightMargin: units.gu(1.5)
                            anchors.verticalCenter: parent.verticalCenter
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#aaa" : "#666"
                            MouseArea {
                                anchors.fill: parent
                                onClicked: isPasswordVisible = !isPasswordVisible
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
