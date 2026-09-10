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
import QtQuick.Controls 2.2 as Controls
import QtGraphicalEffects 1.0
import "../../components"
import "NavigationRoutes.js" as NavigationRoutes

Page {
    id: listpage

    property bool isMultiColumn: apLayout ? (apLayout.columns > 1) : false
    readonly property bool menuCollapsed: apLayout ? apLayout.menuCollapsed : false
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

        // Overlay for collapsed mode to guarantee exact horizontal & vertical centering across 8 GU
        Item {
            parent: header
            anchors.fill: parent
            visible: listpage.menuCollapsed
            z: 100

            Rectangle {
                anchors.fill: parent
                color: collapseOverlayMouseArea.pressed ? "#40ffffff" : (collapseOverlayMouseArea.containsMouse ? "#30ffffff" : "transparent")

                Behavior on color {
                    ColorAnimation { duration: 100 }
                }

                Icon {
                    anchors.centerIn: parent
                    name: "navigation-menu"
                    width: units.gu(2.4)
                    height: units.gu(2.4)
                    color: "white"
                }

                MouseArea {
                    id: collapseOverlayMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (apLayout && typeof apLayout.toggleMenuCollapsed === "function") {
                            apLayout.toggleMenuCollapsed();
                        }
                    }

                    Controls.ToolTip.visible: collapseOverlayMouseArea.containsMouse
                    Controls.ToolTip.text: i18n.dtr("ubtms", "Expand menu")
                    Controls.ToolTip.delay: 400
                }
            }
        }

        contents: RowLayout {
            visible: !listpage.menuCollapsed
            anchors.fill: parent
            anchors.leftMargin: units.gu(1.5)
            anchors.rightMargin: units.gu(1)
            spacing: units.gu(1)

            // Collapse / expand sidebar button (multi-column only)
            Rectangle {
                id: collapseToggleBtn
                visible: listpage.isMultiColumn
                implicitWidth: units.gu(3.6)
                implicitHeight: units.gu(3.6)
                Layout.preferredWidth: implicitWidth
                Layout.preferredHeight: implicitHeight
                radius: height / 2
                color: collapseMouseArea.pressed ? "#40ffffff" : (collapseMouseArea.containsMouse ? "#30ffffff" : "transparent")
                Layout.alignment: Qt.AlignVCenter

                Behavior on color {
                    ColorAnimation { duration: 100 }
                }

                Icon {
                    anchors.centerIn: parent
                    name: "navigation-menu"
                    width: units.gu(2.2)
                    height: units.gu(2.2)
                    color: "white"
                }

                MouseArea {
                    id: collapseMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (apLayout && typeof apLayout.toggleMenuCollapsed === "function") {
                            apLayout.toggleMenuCollapsed();
                        }
                    }

                    Controls.ToolTip.visible: collapseMouseArea.containsMouse
                    Controls.ToolTip.text: i18n.dtr("ubtms", "Collapse menu")
                    Controls.ToolTip.delay: 400
                }
            }

            Label {
                text: i18n.dtr("ubtms", "Menu")
                color: "white"
                fontSize: "large"
                font.bold: true
            }

            Item {
                Layout.fillWidth: true
            }

            // Account Selector chip (visible when expanded)
            Rectangle {
                id: accountBtn
                visible: !listpage.menuCollapsed
                implicitWidth: accountRow.implicitWidth + units.gu(1.8)
                implicitHeight: units.gu(3.6)
                Layout.preferredWidth: implicitWidth
                Layout.preferredHeight: implicitHeight
                radius: height / 2
                color: accountMouseArea.pressed ? "#40ffffff" : (accountMouseArea.containsMouse ? "#30ffffff" : "#20ffffff")
                border.color: "#35ffffff"
                border.width: 1
                Layout.alignment: Qt.AlignVCenter

                Behavior on color {
                    ColorAnimation { duration: 100 }
                }

                RowLayout {
                    id: accountRow
                    anchors.centerIn: parent
                    spacing: units.gu(0.6)

                    Icon {
                        name: "account"
                        width: units.gu(2.2)
                        height: units.gu(2.2)
                        color: "white"
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Label {
                        id: accountLabel
                        visible: !listpage.menuCollapsed
                        Layout.alignment: Qt.AlignVCenter
                        text: {
                            if (typeof accountPicker === "undefined" || !accountPicker.selectedAccountName) return "";
                            return (accountPicker.selectedAccountName === "Local Account" || !accountPicker.selectedAccountName) ? "Local" : accountPicker.selectedAccountName;
                        }
                        color: "white"
                        font.pixelSize: units.dp(13)
                        font.bold: true
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        Layout.maximumWidth: units.gu(10)
                    }
                }

                MouseArea {
                    id: accountMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof accountPicker !== "undefined") {
                            accountPicker.open(accountPicker.selectedAccountId);
                        }
                    }
                }
            }

            // Local Account Toggle Switch
            TSSwitch {
                id: localToggleSwitch
                visible: !listpage.menuCollapsed
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: units.gu(4.2)
                Layout.preferredHeight: units.gu(2.1)
                checked: typeof accountPicker !== "undefined" ? (accountPicker.selectedAccountId === 0) : false

                onClicked: {
                    if (typeof accountPicker !== "undefined") {
                        accountPicker.toggleLocalMode(!checked);
                    }
                }
            }

            // Theme Mode Toggle
            Item {
                visible: !listpage.menuCollapsed
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

        // Pinned bottom actions section when sidebar is collapsed
        Rectangle {
            id: collapsedBottomSection
            visible: listpage.menuCollapsed
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: listpage.menuCollapsed ? (bottomActionsColumn.height + units.dp(1)) : 0
            color: isDark ? "#1e1e1e" : "#ffffff"

            // Divider above bottom actions
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: units.dp(1)
                color: isDark ? "#333333" : "#e8e8e8"
            }

            Column {
                id: bottomActionsColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: units.dp(1)
                spacing: 0

                // 1. Account Action
                Rectangle {
                    id: collapsedAccountBtn
                    width: parent.width
                    height: units.gu(5.5)
                    color: collapsedAccountArea.pressed ? (isDark ? "#2a2a2a" : "#f0f0f0") : (collapsedAccountArea.containsMouse ? (isDark ? "#252525" : "#f7f7f7") : "transparent")

                    Icon {
                        anchors.centerIn: parent
                        name: "account"
                        width: units.gu(2.8)
                        height: units.gu(2.8)
                        color: (typeof accountPicker !== "undefined" && accountPicker.selectedAccountId === 0) ? (isDark ? "#aaaaaa" : "#666666") : LomiriColors.orange
                    }

                    MouseArea {
                        id: collapsedAccountArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof accountPicker !== "undefined") {
                                accountPicker.open(accountPicker.selectedAccountId);
                            }
                        }

                        Controls.ToolTip.visible: collapsedAccountArea.containsMouse
                        Controls.ToolTip.text: {
                            if (typeof accountPicker === "undefined" || !accountPicker.selectedAccountName) return i18n.dtr("ubtms", "Account");
                            var accName = (accountPicker.selectedAccountName === "Local Account" || !accountPicker.selectedAccountName) ? i18n.dtr("ubtms", "Local") : accountPicker.selectedAccountName;
                            return i18n.dtr("ubtms", "Account: %1").arg(accName);
                        }
                        Controls.ToolTip.delay: 400
                    }
                }

                // Divider between Account and Local Account Switch
                Rectangle {
                    id: dividerAccountLocal
                    width: parent.width
                    height: units.dp(1)
                    color: isDark ? "#333333" : "#e8e8e8"
                }

                // 2. Local Account Toggle
                Rectangle {
                    id: collapsedLocalBtn
                    width: parent.width
                    height: units.gu(5.5)
                    color: collapsedLocalArea.pressed ? (isDark ? "#2a2a2a" : "#f0f0f0") : (collapsedLocalArea.containsMouse ? (isDark ? "#252525" : "#f7f7f7") : "transparent")

                    TSSwitch {
                        id: collapsedLocalSwitch
                        anchors.centerIn: parent
                        width: units.gu(4.2)
                        height: units.gu(2.1)
                        interactive: false
                        checked: typeof accountPicker !== "undefined" ? (accountPicker.selectedAccountId === 0) : false
                        uncheckedColor: isDark ? "#444444" : "#cccccc"
                        uncheckedBorderColor: isDark ? "#555555" : "#bbbbbb"
                    }

                    MouseArea {
                        id: collapsedLocalArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof accountPicker !== "undefined") {
                                accountPicker.toggleLocalMode(!collapsedLocalSwitch.checked);
                            }
                        }

                        Controls.ToolTip.visible: collapsedLocalArea.containsMouse
                        Controls.ToolTip.text: collapsedLocalSwitch.checked ? i18n.dtr("ubtms", "Local Account (Active)") : i18n.dtr("ubtms", "Local Account (Disabled)")
                        Controls.ToolTip.delay: 400
                    }
                }

                // Divider between Local Account Switch and Theme Toggle
                Rectangle {
                    id: dividerLocalTheme
                    width: parent.width
                    height: units.dp(1)
                    color: isDark ? "#333333" : "#e8e8e8"
                }

                // 3. Theme Toggle
                Rectangle {
                    id: collapsedThemeBtn
                    width: parent.width
                    height: units.gu(5.5)
                    color: collapsedThemeArea.pressed ? (isDark ? "#2a2a2a" : "#f0f0f0") : (collapsedThemeArea.containsMouse ? (isDark ? "#252525" : "#f7f7f7") : "transparent")

                    Item {
                        anchors.centerIn: parent
                        width: units.gu(2.4)
                        height: units.gu(2.4)

                        Image {
                            id: collapsedThemeImg
                            anchors.fill: parent
                            source: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "../../images/daymode.png" : "../../images/darkmode.png"
                            fillMode: Image.PreserveAspectFit
                            visible: false
                        }

                        ColorOverlay {
                            anchors.fill: collapsedThemeImg
                            source: collapsedThemeImg
                            color: isDark ? "#ffffff" : "#444444"
                        }
                    }

                    MouseArea {
                        id: collapsedThemeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Theme.name = theme.name === "Ubuntu.Components.Themes.SuruDark" ? "Ubuntu.Components.Themes.Ambiance" : "Ubuntu.Components.Themes.SuruDark";
                        }

                        Controls.ToolTip.visible: collapsedThemeArea.containsMouse
                        Controls.ToolTip.text: theme.name === "Ubuntu.Components.Themes.SuruDark" ? i18n.dtr("ubtms", "Day mode") : i18n.dtr("ubtms", "Dark mode")
                        Controls.ToolTip.delay: 400
                    }
                }
            }
        }

        Flickable {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: listpage.menuCollapsed ? collapsedBottomSection.top : parent.bottom
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
                            collapsed: listpage.menuCollapsed
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
