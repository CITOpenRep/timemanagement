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
import io.thp.pyotherside 1.4
import "../models/sync.js" as SyncData
import "../models/utils.js" as Utils
import "components"

Page {
    id: createAccountPage
    title: "Create Account"

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
                onTriggered: {
                    handleAccountSave();
                }
            }
        ]
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

        python.call("backend.login_odoo", [linkInput.text, usernameInput.text, passwordInput.text, dbname], function (result) {
            if (result && result['status'] === 'pass' && result['database']) {
                let apikey = passwordInput.text;

                var isDuplicate = SyncData.createAccount(accountNameInput.text, linkInput.text, result['database'], usernameInput.text, selectedconnectwithId, apikey);

                if (isDuplicate) {
                    notifPopup.open("Error", "You already have this account", "error");
                } else {
                    notifPopup.open("Saved", "Your account has been saved, Enjoy using the app !", "success");
                }
            } else {
                notifPopup.open("Error", "Unable to save the Account, Please check the URL , Database name or your credentials", "error");
            }
        });
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
                            text: "Account Name"
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
                            anchors.horizontalCenter: parent.horizontalCenter
                            placeholderText: "Account Name"
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
                            placeholderText: "Enter Odoo URL here"
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
                        text: "Fetch Databases"
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
                                        console.log(dbList[i]);
                                        databaseListModel.append({
                                            name: dbList[i]
                                        });
                                        activeBackendAccount = true;
                                    }

                                    if (dbList.length > 0) {
                                        database_combo.currentIndex = 0;
                                        console.log("First DB selected:", database_combo.currentText);
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
                            text: "Database"
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
                            placeholderText: "Enter Database Name"
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
                            text: "Username"
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
                            placeholderText: "Username"
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
                            text: "Connect With"
                            visible: activeBackendAccount
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
                Column {
                    leftPadding: units.gu(1)
                    ComboBox {
                        id: connectWith_combo
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
                                text: model.modelData
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
                        width: units.gu(5)
                        height: passwordInput.height
                        visible: activeBackendAccount
                        fontSize: units.gu(1.2)
                        text: isPasswordVisible ? "hide" : "show"
                        onClicked: {
                            isPasswordVisible = !isPasswordVisible;
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
        onClosed: console.log("Notification dismissed")
    }
}
