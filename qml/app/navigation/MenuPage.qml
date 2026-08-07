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
import QtCharts 2.0
import QtQuick.Layouts 1.11
import Qt.labs.settings 1.0
import "../../components"
import "NavigationRoutes.js" as NavigationRoutes

Page {
    id: listpage

    property bool isMultiColumn: apLayout.columns > 1
    property var navigationController

    title: i18n.dtr("ubtms", "Menu")
    anchors.fill: parent

    header: PageHeader {
        id: header

        StyleHints {
            foregroundColor: "white"
            backgroundColor: LomiriColors.orange
            dividerColor: LomiriColors.slate
        }

        contents: RowLayout {
            anchors.fill: parent
            anchors.leftMargin: units.gu(2)
            anchors.rightMargin: units.gu(1)
            spacing: units.gu(1)

            Label {
                text: i18n.dtr("ubtms", "Menu")
                color: "white"
                fontSize: "large"
                font.bold: true
            }

            Item {
                Layout.fillWidth: true
            }

            // Account Selector button with Account label adjacent to icon
            Item {
                id: accountBtn
                implicitWidth: accountRow.implicitWidth
                height: units.gu(4)
                Layout.alignment: Qt.AlignVCenter

                RowLayout {
                    id: accountRow
                    anchors.fill: parent
                    spacing: units.gu(0.5)

                    Icon {
                        name: "account"
                        width: units.gu(2.4)
                        height: units.gu(2.4)
                        color: "white"
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Label {
                        id: accountLabel
                        Layout.alignment: Qt.AlignVCenter
                        text: "Account [" + (typeof accountPicker !== "undefined" ? accountPicker.selectedAccountName : "") + "]"
                        color: "white"
                        font.pixelSize: units.dp(13)
                        font.bold: true
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof accountPicker !== "undefined") {
                            accountPicker.open(accountPicker.selectedAccountId);
                        }
                    }
                }
            }

            // Theme Mode Toggle
            Item {
                width: units.gu(4)
                height: units.gu(4)
                Layout.alignment: Qt.AlignVCenter

                Image {
                    anchors.centerIn: parent
                    width: units.gu(2.2)
                    height: units.gu(2.2)
                    source: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "../../images/daymode.png" : "../../images/darkmode.png"
                    fillMode: Image.PreserveAspectFit
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Theme.name = theme.name === "Ubuntu.Components.Themes.SuruDark" ? "Ubuntu.Components.Themes.Ambiance" : "Ubuntu.Components.Themes.SuruDark";
                    }
                }
            }
        }
    }

    readonly property bool isDark: theme.name === "Ubuntu.Components.Themes.SuruDark"

    Rectangle {
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        color: isDark ? "#111" : "#f2f2f7"

        Flickable {
            anchors.fill: parent
            contentHeight: menuColumn.height + units.gu(4)
            clip: true

            Column {
                id: menuColumn
                width: parent.width
                anchors.top: parent.top

                Rectangle {
                    width: parent.width
                    height: mainSection.height
                    color: isDark ? "#1e1e1e" : "#ffffff"

                    Column {
                        id: mainSection
                        width: parent.width

                        NavigationMenuList {
                            width: parent.width
                            menuItems: NavigationRoutes.menuItems()
                            selectedPageUrl: apLayout && apLayout.currentMenuPageUrl ? apLayout.currentMenuPageUrl : ""

                            onItemSelected: function(item) {
                                if (navigationController && typeof navigationController.navigateMenuItem === "function") {
                                    navigationController.navigateMenuItem(item);
                                } else if (apLayout && typeof apLayout.setPageGlobal === "function") {
                                    apLayout.setPageGlobal(item.pageUrl, item.pageNum);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
