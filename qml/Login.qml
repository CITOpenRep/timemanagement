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
import QtQuick.Window 2.2
import QtQuick.Controls 2.2
import QtQuick.LocalStorage 2.7
import Ubuntu.Components 1.3 as Ubuntu

Item {
    width: parent.width
    height: parent.height
    property var optionList: []
    property bool isTextInputVisible: false
    property bool isTextMenuVisible: false
    property bool isValidUrl: true
    property bool isValidLogin: true
    property bool isValidAccount: true
    property bool isPasswordVisible: false
    property var accountsList: []
    property string user_name: ""
    property string single_db: ""
    property string account_name: ""
    property string selected_database: ""
    property string selected_link: ""
    property int currentUserId: 0
    property int selectedconnectwithId: 0

    function initializeDatabase() {
        var db = LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);

        db.transaction(function (tx) {
            tx.executeSql('CREATE TABLE IF NOT EXISTS users (\
                id INTEGER PRIMARY KEY AUTOINCREMENT,\
                name TEXT NOT NULL,\
                link TEXT NOT NULL,\
                last_modified datetime,\
                database TEXT NOT NULL,\
                connectwith_id INTEGER,\
                api_key TEXT,\
                username TEXT NOT NULL\
            )');
        });
    }

    function insertData(name, link, database, username, selectedconnectwithId, apikey) {
        var db = LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);

        db.transaction(function (tx) {
            var result = tx.executeSql('SELECT id, COUNT(*) AS count FROM users WHERE link = ? AND database = ? AND username = ?', [link, database, username]);
            if (result.rows.item(0).count === 0) {
                var api_key_text = ' ';
                if (selectedconnectwithId == 1) {
                    api_key_text = apikey;
                }
                tx.executeSql('INSERT INTO users (name, link, database, username, connectwith_id, api_key) VALUES (?, ?, ?, ?, ?, ?)', [name, link, database, username, selectedconnectwithId, api_key_text]);
                var newResult = tx.executeSql('SELECT id FROM users WHERE link = ? AND database = ? AND username = ?', [link, database, username]);
                currentUserId = newResult.rows.item(0).id;
            } else {
                currentUserId = result.rows.item(0).id;
            }
        });
    }

    function queryData() {
        var db = LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);

        db.transaction(function (tx) {
            var result = tx.executeSql('SELECT * FROM users');
            accountsList = [];
            for (var i = 0; i < result.rows.length; i++) {
                accountsList.push({
                    'user_id': result.rows.item(i).id,
                    'name': result.rows.item(i).name,
                    'link': result.rows.item(i).link,
                    'database': result.rows.item(i).database,
                    'username': result.rows.item(i).username
                });
            }
        });
        selectedconnectwithId = 1;
        connectwith.text = 'Connect With Api Key';
    }

    ListModel {
        id: menuconnectwithModel
        ListElement {
            itemId: 0
            name: "Connect With Password"
        }
        ListElement {
            itemId: 1
            name: "Connect With Api Key"
        }
    }

    Rectangle {
        width: parent.width
        height: parent.height
        color: "#FFFFFF"
        anchors.centerIn: parent
        Rectangle {
            id: loginHeder
            width: parent.width
            height: isDesktop() ? 60 : 120
            anchors.top: parent.top
            anchors.topMargin: isDesktop() ? 60 : 120
            color: "#FFFFFF"
            z: 1

            Rectangle {
                width: parent.width
                height: 2
                color: "#DDDDDD"
                anchors.bottom: parent.bottom
            }

            Row {
                id: row_id
                width: parent.width
                anchors.verticalCenter: parent.verticalCenter
                anchors.fill: parent
                spacing: isDesktop() ? 20 : 40
                anchors.left: parent.left
                anchors.leftMargin: isDesktop() ? 55 : -10
                anchors.right: parent.right
                anchors.rightMargin: isDesktop() ? 15 : 20

                Rectangle {
                    id: header_tital
                    color: "transparent"
                    width: parent.width
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height

                    Row {

                        anchors.verticalCenter: parent.verticalCenter

                        ToolButton {
                            width: isDesktop() ? 40 : 80
                            height: isDesktop() ? 35 : 80
                            background: Rectangle {
                                color: "transparent"
                            }
                            contentItem: Ubuntu.Icon {
                                name: "back"
                            }
                            onClicked: {
                                stackView.push(settingAccounts);
                            }
                        }

                        Label {
                            text: "Login Account"
                            font.pixelSize: isDesktop() ? 20 : 40
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: ToolButton.right
                            font.bold: true
                            color: "#121944"
                        }
                    }
                }
            }
        }

        Image {
            id: logo

            anchors.top: parent.top
            anchors.topMargin: isDesktop() ? 150 : phoneLarg() ? 240 : 300
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.margins: 20
        }
        Flickable {
            id: flickableContainer
            width: parent.width
            height: parent.height
            contentHeight: loginFlickable.childrenRect.height + 370
            anchors.fill: parent
            Column {
                id: loginFlickable
                spacing: 10
                anchors.top: parent.top
                anchors.topMargin: isDesktop() ? 200 : phoneLarg() ? 270 : 300
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.margins: 20
                height: childrenRect.height + 20

                ListModel {
                    id: accountsListModel
                }

                TextField {
                    id: manageAccountInput
                    placeholderText: "Select Account"
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: isDesktop() ? 500 : 1000
                    visible: accountsList.length == 0
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            queryData();
                            accountsListModel.clear();
                            for (var i = 0; i < accountsList.length; i++) {
                                accountsListModel.append(accountsList[i]);
                            }
                            accountsListModel.append({
                                'name': 'Add New account',
                                'user_id': false
                            });
                            menuManageAccounts.open();
                        }
                    }
                    Menu {
                        id: menuManageAccounts
                        x: manageAccountInput.x
                        y: manageAccountInput.y
                        width: manageAccountInput.width

                        Repeater {
                            model: accountsListModel

                            MenuItem {
                                width: parent.width
                                height: isDesktop() ? 50 : 80
                                property string itemId: model.user_id
                                property string itemName: model.name || ''
                                Text {
                                    text: itemName
                                    font.pixelSize: isDesktop() ? 20 : 40
                                    color: "#000" ? itemId != false : "#121944"
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    wrapMode: Text.WordWrap
                                    elide: Text.ElideRight
                                    maximumLineCount: 2
                                }
                                onClicked: {
                                    if (itemId != false) {
                                        manageAccountInput.text = model.name || '';
                                        linkInput.forceActiveFocus();
                                        linkInput.text = model.link;
                                        linkInput.focus = false;
                                        linkInput.forceActiveFocus();
                                        dbInput.text = model.database;
                                        dbInputMenu.text = model.database;
                                        usernameInput.text = model.username;
                                    } else {
                                        manageAccountInput.text = '';
                                        linkInput.text = '';
                                        dbInput.text = '';
                                        dbInputMenu.text = '';
                                        usernameInput.text = '';
                                    }
                                    menuManageAccounts.close();
                                }
                            }
                        }
                    }
                }

                TextField {
                    id: accountNameInput
                    placeholderText: "Account Name"
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: isDesktop() ? 500 : 1000
                }

                TextField {
                    id: linkInput
                    placeholderText: "Link"
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: isDesktop() ? 500 : 1000

                    onEditingFinished: {
                        text = text.toLowerCase();
                        if (isValidURL(linkInput.text)) {
                            isValidUrl = true;
                            python.call("backend.fetch_databases", [linkInput.text], function (result) {
                                isTextInputVisible = result.text_field;
                                isTextMenuVisible = result.menu_items;
                                if (isTextMenuVisible) {
                                    optionList = result.menu_items;
                                } else if (result.single_db) {
                                    single_db = result.single_db;
                                }
                            });
                        } else {
                            isValidUrl = false;
                        }
                    }

                    onTextChanged: {
                        text = text.toLowerCase();
                    }

                    function isValidURL(url) {
                        var pattern = new RegExp('^(https?:\\/\\/)?' + '(([a-zA-Z0-9\\-\\.]+)\\.([a-zA-Z]{2,4})|' + '(\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3})|' + '\\[([a-fA-F0-9:\\.]+)\\])' + '(\\:\\d+)?(\\/[-a-zA-Z0-9@:%_\\+.~#?&//=]*)*$', 'i');
                        return pattern.test(url);
                    }
                }

                Text {
                    id: errorMessage
                    text: isValidUrl ? "" : "Please enter a valid URL"
                    color: "red"
                    visible: !isValidUrl
                    font.pixelSize: isDesktop() ? 20 : 40
                }

                TextField {
                    id: dbInput
                    placeholderText: "Database"
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: isDesktop() ? 500 : 1000
                    visible: isTextInputVisible
                }

                TextField {
                    id: dbInputMenu
                    placeholderText: "Database"
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: isDesktop() ? 500 : 1000
                    visible: isTextMenuVisible
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            menuTasks.open();
                        }
                    }
                    Menu {
                        id: menuTasks
                        x: dbInputMenu.x
                        y: dbInputMenu.y
                        width: dbInputMenu.width

                        Repeater {
                            model: optionList

                            MenuItem {
                                width: parent.width
                                height: isDesktop() ? 50 : 40
                                Text {
                                    text: modelData
                                    font.pixelSize: isDesktop() ? 20 : 40
                                    color: "#000"
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    wrapMode: Text.WordWrap
                                    elide: Text.ElideRight
                                    maximumLineCount: 2
                                }
                                onClicked: {
                                    dbInputMenu.text = modelData;
                                    menuTasks.close();
                                }
                            }
                        }
                    }
                }

                TextField {
                    id: usernameInput
                    placeholderText: "Username"
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: isDesktop() ? 500 : 1000
                }

                Label {
                    id: connectwithLabel
                    text: 'Connection Options:'
                }

                TextField {
                    id: connectwith
                    placeholderText: "Connect With"
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: isDesktop() ? 500 : 1000
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            menuconnectwith.open();
                        }
                    }
                    Menu {
                        id: menuconnectwith
                        x: connectwith.x
                        width: connectwith.width

                        Repeater {
                            model: menuconnectwithModel

                            MenuItem {
                                width: parent.width
                                height: isDesktop() ? 50 : 80
                                property string connectId: model.itemId || 0
                                property string connectName: model.name || ''
                                Text {
                                    text: connectName
                                    font.pixelSize: isDesktop() ? 20 : 40
                                    color: "#000"
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    wrapMode: Text.WordWrap
                                    elide: Text.ElideRight
                                    maximumLineCount: 2
                                }
                                onClicked: {
                                    connectwith.text = connectName;
                                    selectedconnectwithId = connectId;
                                    menuconnectwith.close();
                                }
                            }
                        }
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 5

                    TextField {
                        id: passwordInput
                        placeholderText: selectedconnectwithId == 0 ? "Password" : "API Key"
                        width: isDesktop() ? 452 : 900
                        echoMode: isPasswordVisible ? TextInput.Normal : TextInput.Password
                    }

                    Button {
                        width: isDesktop() ? 40 : 100
                        height: passwordInput.height
                        Image {
                            source: isPasswordVisible ? "images/show.png" : "images/hide.png"
                            anchors.fill: parent
                            smooth: true
                        }
                        onClicked: {
                            isPasswordVisible = !isPasswordVisible;
                        }
                    }
                }

                Button {
                    id: loginButton
                    anchors.topMargin: 20
                    width: isDesktop() ? 500 : 1000

                    background: Rectangle {
                        color: "#FB634E"
                        radius: isDesktop() ? 5 : 10
                        border.color: "#FB634E"
                    }

                    contentItem: Text {
                        text: "Login"
                        color: "#ffffff"
                        font.pixelSize: isDesktop() ? 20 : 30
                    }
                    anchors.horizontalCenter: parent.horizontalCenter
                    onClicked: {
                        if (!accountNameInput.text && !manageAccountInput.text) {
                            isValidAccount = false;
                        } else {
                            python.call("backend.login_odoo", [linkInput.text, usernameInput.text, passwordInput.text,
                                {
                                    'input_text': dbInput.text || single_db,
                                    'selected_db': dbInputMenu.text,
                                    'isTextInputVisible': isTextInputVisible,
                                    'isTextMenuVisible': isTextMenuVisible
                                }
                            ], function (result) {
                                if (result && result['result'] == 'pass') {
                                    let apikey = "";
                                    if (selectedconnectwithId == 1) {
                                        apikey = passwordInput.text;
                                    }
                                    insertData(accountNameInput.text, linkInput.text, result['database'], usernameInput.text, selectedconnectwithId, apikey);
                                    isValidLogin = true;
                                    loggedIn(result['name_of_user'], currentUserId);
                                } else {
                                    isValidLogin = false;
                                }
                            });
                        }
                    }
                }

                Text {
                    id: errorMessageAccount
                    text: isValidAccount ? "" : "Please enter Account Name to save!"
                    color: "red"
                    visible: !isValidAccount
                    font.pixelSize: isDesktop() ? 20 : 40
                }

                Text {
                    id: errorMessageLogin
                    text: isValidLogin ? "" : "Please enter valid Credentials!"
                    color: "red"
                    visible: !isValidLogin
                    font.pixelSize: isDesktop() ? 20 : 40
                }

                Label {
                    text: selectedconnectwithId == 1 ? "Notes:<br/>Connect with API Key: Your API key will be securely stored on your device, enabling synchronization without requiring a password.<br/><br/>In Odoo, you can generate your API key in the <b>My Profile</b> page under the <b>Account Security</b> tab." : "Notes:<br/>Connect with Password: You will be prompted to enter your password each time synchronization is performed."
                    textFormat: Text.RichText
                    anchors.left: parent.left
                    anchors.right: parent.right
                    horizontalAlignment: Label.AlignHCenter
                    verticalAlignment: Label.AlignVCenter
                    wrapMode: Label.Wrap
                }
            }
        }
    }

    Component.onCompleted: {
        initializeDatabase();
        queryData();
    }

    signal loggedIn(string username, int currentUserId)
}
