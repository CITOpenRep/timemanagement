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
import Lomiri.Components 1.3
Page {
    id: dashboard
    title: i18n.dtr("ubtms", "Charts")
    property int lastRefreshAccountId: -999999
    header: PageHeader {
        title: dashboard.title
        StyleHints {
            foregroundColor: "white"

            backgroundColor: LomiriColors.orange
            dividerColor: LomiriColors.slate
        }
    }

    function refreshData() {
        var accountId = typeof accountPicker !== "undefined" ? accountPicker.selectedAccountId : -1;
        if (lastRefreshAccountId === accountId) {
            return;
        }

        lastRefreshAccountId = accountId;
        console.log("Refreshing Dashboard2 charts for account: " + accountId);
        if (load3.item && typeof load3.item.reloadData === "function")
            load3.item.reloadData();
        if (load4.item && typeof load4.item.reloadData === "function")
            load4.item.reloadData();
    }

    Connections {
        target: typeof accountPicker !== "undefined" ? accountPicker : null
        onAccepted: function (accountId, accountName) {
            refreshData();
        }
    }

    Flickable {
        id: flick1
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Qt.inputMethod.visible ? Qt.inputMethod.keyboardRectangle.height : 0
        contentWidth: parent.width
        contentHeight: contentColumn.height + units.gu(4)
        flickableDirection: Flickable.VerticalFlick
        clip: true

        rebound: Transition {
            NumberAnimation {
                properties: "x,y"
                duration: 1000
                easing.type: Easing.OutBounce
            }
        }

        Column {
            id: contentColumn
            width: flick1.width
            spacing: units.gu(2)

            Item {
                width: parent.width
                height: units.gu(1)
            }

            Rectangle {
                width: parent.width - units.gu(2)
                height: load3.item ? load3.item.height : units.gu(40)
                anchors.horizontalCenter: parent.horizontalCenter
                color: "transparent"

                Loader {
                    id: load3
                    anchors.fill: parent
                    source: "../charts/Charts3.qml"
                    onLoaded: {
                        if (item) {
                            item.autoRefreshOnAccountChange = false;
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width - units.gu(2)
                height: load4.item ? load4.item.implicitHeight : units.gu(80)
                anchors.horizontalCenter: parent.horizontalCenter
                color: "transparent"

                Loader {
                    id: load4
                    anchors.fill: parent
                    source: "../charts/Charts4.qml"
                    onLoaded: {
                        if (item) {
                            item.autoRefreshOnAccountChange = false;
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: units.gu(2)
            }
        }


    }

    Scrollbar {
        flickableItem: flick1
        align: Qt.AlignTrailing
    }
}
