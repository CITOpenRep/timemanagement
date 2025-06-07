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
import Ubuntu.Components 1.3 as Ubuntu
import io.thp.pyotherside 1.4
import "../models/Sync.js" as SyncData
import "../models/Utils.js" as Utils
import "components"

Page {
    id: settings
    title: "Settings"
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
            }
        ]
    }

    Python {
        id: python

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('../src/'));
            importModule_sync("backend");
        }

        onError: function (errorName, errorMessage, traceback) {
            console.error("Python Error:", errorName);
            console.error("Message:", errorMessage);
            console.error("Traceback:\n" + traceback);
        }
    }

    Connections {
        target: python
        onSyncDone: {
            console.log("✅Hurray  Sync completed");
        }
    }

    property bool loading: false
    property string loadingMessage: ""

    ListModel {
        id: accountListModel
    }

    function fetch_accounts() {
        accountListModel.clear();
        var accountsList = SyncData.get_accounts_list();
        for (var account = 0; account < accountsList.length; account++) {
            accountListModel.append(accountsList[account]);
        }
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
        color: "#ffffff"
        Rectangle {
            anchors.fill: parent
            anchors.top: pageHeader.bottom
            anchors.topMargin: units.gu(5)
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
                    spacing: 0
                    Repeater {
                        model: accountListModel
                        delegate: Rectangle {
                            width: parent.width
                            height: units.gu(16)
                            color: "#FFFFFF"
                            border.color: "#CCCCCC"
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
                                        color: "#0078d4"
                                        radius: 80
                                        border.color: "#0056a0"
                                        border.width: 1
                                        anchors.rightMargin: units.gu(1)
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.leftMargin: units.gu(1)

                                        Text {
                                            text: model.name.charAt(0).toUpperCase()
                                            anchors.verticalCenter: parent.verticalCenter
                                            color: "#fff"
                                            anchors.centerIn: parent
                                            font.pixelSize: units.gu(2)
                                        }
                                    }

                                    Column {
                                        spacing: 5
                                        // anchors.centerIn:  parent
                                        anchors.left: imgmodulename.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.leftMargin: units.gu(2)

                                        Text {
                                            text: model.name.toUpperCase()
                                            font.pixelSize: units.gu(2)
                                            color: "#000"
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            text: "URL : " + (model.link.length > 40) ? model.link.substring(0, 40) + "..." : model.link
                                            font.pixelSize: units.gu(1.2)
                                            color: "#666"
                                            elide: Text.ElideNone
                                        }
                                        Text {
                                            text: "Database : " + model.database
                                            font.pixelSize: units.gu(1.1)
                                            color: "#666"
                                        }
                                        Text {
                                            text: Utils.getLastSyncStatus(0)
                                            font.pixelSize: units.gu(1)
                                            color: "#666"
                                        }
                                    }
                                    Column {
                                        anchors.right: parent.right
                                        anchors.rightMargin: units.gu(1)
                                        anchors.verticalCenter: parent.verticalCenter
                                        TSButton {
                                            visible:(model.user_id!==0)
                                            width: units.gu(10)
                                            height: units.gu(4)
                                            fontSize: units.gu(1.5)
                                            text: "Delete"
                                            onClicked: {
                                                Utils.deleteAccountAndRelatedData(model.user_id);
                                                accountListModel.remove(index);
                                            }
                                        }
                                        TSButton {
                                            visible:(model.user_id!==0)
                                            width: units.gu(10)
                                            height: units.gu(4)
                                            fontSize: units.gu(1.5)
                                            text: "Show Logs"
                                            onClicked: {
                                                apLayout.addPageToNextColumn(settings, Qt.resolvedUrl("SyncLog.qml"), {
                                                    "recordid": model.user_id
                                                });
                                            }
                                        }
                                        // Sync Button
                                        TSButton {
                                            visible:(model.user_id!==0)
                                            id: syncBtn
                                            width: units.gu(10)
                                            height: units.gu(4)
                                            fontSize: units.gu(1.5)
                                            text: "Sync"
                                            onClicked: {
                                                python.call("backend.resolve_qml_db_path", ["ubtms"], function (path) {
                                                    if (path === "") {
                                                        console.warn("DB not found.");
                                                    } else {
                                                        console.log("Actual DB path resolved by Python:", path);
                                                        //remeber to remove hardcoded index , pasing account index
                                                        python.call("backend.start_sync_in_background", [path, model.user_id], function (result) {
                                                            if (result) {
                                                                console.log("Background sync started...");
                                                            } else {
                                                                console.warn("Failed to start sync");
                                                            }
                                                        });
                                                    }
                                                });
                                            }
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

    onVisibleChanged: {
        fetch_accounts();
    }
}
