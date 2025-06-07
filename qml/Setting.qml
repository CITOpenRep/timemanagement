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
import io.thp.pyotherside 1.4
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
    property bool loading: false
    property string loadingMessage: ""
    property bool issearchHeader: false
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
            recordModel.clear();
            for (var i = 0; i < accountsList.length; i++) {
                recordModel.append(accountsList[i]);
            }
        });
    }
    function filtersynList(query) {
        recordModel.clear();

        for (var i = 0; i < accountsList.length; i++) {
            var entry = accountsList[i];
            if (entry.name.toLowerCase().includes(query.toLowerCase())) {
                recordModel.append(entry);
            }
        }
    }

    function deleteData(recordId) {
        var db = LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);

        db.transaction(function (tx) {
            var users = tx.executeSql('DELETE FROM users where id =' + parseInt(recordId));

            queryData();
        });
    }
    ListModel {
        id: recordModel
    }
    Rectangle {
        id: setting_header
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
            anchors.leftMargin: isDesktop() ? issearchHeader ? 55 : 70 : issearchHeader ? -10 : 15
            anchors.right: parent.right
            anchors.rightMargin: isDesktop() ? 15 : 20

            Rectangle {
                id: header_tital
                visible: !issearchHeader
                color: "transparent"
                width: parent.width / 5
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height

                Row {

                    anchors.verticalCenter: parent.verticalCenter

                    Label {
                        text: "Accounts"
                        font.pixelSize: isDesktop() ? 20 : 40
                        anchors.verticalCenter: parent.verticalCenter

                        font.bold: true
                        color: "#121944"
                    }
                }
            }

            Rectangle {
                id: header_btnADD
                visible: !issearchHeader
                color: "transparent"
                width: parent.width / 8
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                anchors.right: parent.right

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: isDesktop() ? 10 : 20
                    anchors.right: parent.right

                    ToolButton {
                        width: isDesktop() ? 40 : 80
                        height: isDesktop() ? 35 : 80
                        background: Rectangle {
                            color: "transparent"
                        }
                        contentItem: Ubuntu.Icon {
                            name: "add"
                        }
                        onClicked: {
                            goToLogin();
                        }
                    }
                    ToolButton {
                        id: search_id
                        width: isDesktop() ? 40 : 80
                        height: isDesktop() ? 35 : 80
                        background: Rectangle {
                            color: "transparent"
                        }
                        contentItem: Ubuntu.Icon {
                            name: "search"
                        }
                        onClicked: {
                            issearchHeader = true;
                        }
                    }
                }
            }
            Rectangle {
                id: search_header
                visible: issearchHeader
                width: parent.width
                anchors.verticalCenter: parent.verticalCenter
                ToolButton {
                    id: back_idn
                    width: isDesktop() ? 35 : 80
                    height: isDesktop() ? 35 : 80
                    anchors.verticalCenter: parent.verticalCenter
                    background: Rectangle {
                        color: "transparent"
                    }
                    contentItem: Ubuntu.Icon {
                        name: "back"
                    }
                    onClicked: {
                        issearchHeader = false;
                        searchField.text = "";
                    }
                }

                TextField {
                    id: searchField
                    placeholderText: "Search..."
                    anchors.left: back_idn.right
                    anchors.leftMargin: isDesktop() ? 0 : 5
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    onTextChanged: {
                        filtersynList(searchField.text);
                    }
                }
            }
        }
    }
    Rectangle {
        width: parent.width
        height: parent.height
        anchors.top: parent.top
        anchors.topMargin: isDesktop() ? 65 : 120
        anchors.left: parent.left
        anchors.leftMargin: isDesktop() ? 70 : 20
        anchors.right: parent.right
        anchors.rightMargin: isDesktop() ? 10 : 20
        anchors.bottom: parent.bottom
        anchors.bottomMargin: isDesktop() ? 0 : 100
        color: "#ffffff"
        Rectangle {

            anchors.fill: parent
            anchors.top: searchId.bottom
            anchors.topMargin: isDesktop() ? 68 : 170
            border.color: "#CCCCCC"
            border.width: isDesktop() ? 1 : 2

            Flickable {
                id: listView
                anchors.fill: parent
                width: parent.width
                contentHeight: column.height
                clip: true

                Column {
                    id: column
                    width: parent.width
                    spacing: 0

                    Repeater {
                        model: recordModel
                        delegate: Rectangle {
                            width: parent.width
                            height: isDesktop() ? 80 : 130

                            color: "#FFFFFF"
                            border.color: "#CCCCCC"
                            border.width: isDesktop() ? 1 : 2

                            Column {
                                spacing: 0
                                anchors.fill: parent

                                Row {
                                    width: parent.width
                                    height: isDesktop() ? 80 : 130
                                    spacing: 20

                                    Rectangle {
                                        id: imgmodulename
                                        width: isDesktop() ? 50 : 90
                                        height: isDesktop() ? 50 : 90
                                        color: "#0078d4"
                                        radius: 80
                                        border.color: "#0056a0"
                                        border.width: 2
                                        anchors.rightMargin: 10

                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.leftMargin: 10

                                        Text {
                                            text: model.name.charAt(0).toUpperCase()
                                            color: "#fff"
                                            anchors.centerIn: parent
                                            font.pixelSize: isDesktop() ? 20 : 40
                                        }
                                    }

                                    Column {
                                        spacing: 5
                                        width: parent.width - 280
                                        anchors.centerIn: parent

                                        Text {
                                            text: model.name
                                            font.pixelSize: isDesktop() ? 20 : 40
                                            color: "#000"
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            text: (model.link.length > 40) ? model.link.substring(0, 40) + "..." : model.link
                                            font.pixelSize: isDesktop() ? 18 : 30
                                            color: "#0078d4"
                                            elide: Text.ElideNone
                                        }
                                    }

                                    Button {

                                        width: isDesktop() ? 40 : 90
                                        height: isDesktop() ? 40 : 90

                                        background: Rectangle {
                                            color: "transparent"
                                            radius: 10
                                            border.color: "transparent"
                                        }
                                        Image {
                                            source: "images/delete.png"
                                            anchors.fill: parent
                                            smooth: true
                                        }
                                        anchors.right: parent.right
                                        anchors.rightMargin: 20
                                        anchors.verticalCenter: parent.verticalCenter
                                        onClicked: {
                                            logInPage(model.user_id);

                                            deleteData(model.user_id);
                                            recordModel.remove(index);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            Item {
                id: loader
                visible: loading

                Rectangle {
                    width: Screen.width
                    height: Screen.height
                    color: "lightgray"
                    radius: 10
                    opacity: 0.8
                    Text {
                        anchors.centerIn: parent
                        text: loadingMessage
                        font.pixelSize: 50
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        queryData();
        issearchHeader = false;
    }

    signal logInPage(string Accountuser_id)
    signal goToLogin
    signal backPage
}
