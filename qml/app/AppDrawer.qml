import QtQuick 2.6
import QtQuick.Controls 2.2 as Controls
import QtQuick.Layouts 1.3
import Lomiri.Components 1.3
import "../components"
import "navigation/NavigationRoutes.js" as NavigationRoutes

Controls.Drawer {
    id: drawerRoot
    edge: Qt.LeftEdge
    interactive: true

    property var apLayout
    property var navigationController

    Connections {
        target: apLayout
        onCurrentPageChanged: {
            if (drawerRoot.opened) {
                drawerRoot.close();
            }
        }
    }

    width: Math.min(parent.width * 0.75, units.gu(35))
    height: parent.height

    Rectangle {
        anchors.fill: parent
        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#111" : "#f2f2f7"

        Flickable {
            anchors.fill: parent
            contentHeight: menuColumn.height + units.gu(4)
            clip: true

            Column {
                id: menuColumn
                width: parent.width

                Rectangle {
                    id: drawerHeader
                    width: parent.width
                    height: units.gu(8)
                    color: LomiriColors.orange

                    Item {
                        anchors.fill: parent
                        anchors.leftMargin: drawerHeader.width < units.gu(32) ? units.gu(1.2) : units.gu(2)
                        anchors.rightMargin: drawerHeader.width < units.gu(32) ? units.gu(0.8) : units.gu(1.2)

                        // Left section: Menu title
                        RowLayout {
                            id: drawerLeftSection
                            anchors.left: parent.left
                            anchors.right: drawerRightSection.left
                            anchors.rightMargin: units.gu(0.5)
                            anchors.verticalCenter: parent.verticalCenter

                            Label {
                                text: i18n.dtr("ubtms", "Menu")
                                color: "white"
                                fontSize: "large"
                                font.bold: true
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        // Right section: Account selector chip, local mode toggle, and theme toggle button
                        RowLayout {
                            id: drawerRightSection
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: drawerHeader.width < units.gu(34) ? units.gu(0.6) : units.gu(0.8)

                            // Account Selector chip (collapses to circular avatar when width is restricted)
                            Rectangle {
                                id: accountSelectorItem
                                implicitWidth: accountNameLabel.visible ? (accountRow.implicitWidth + units.gu(1.6)) : units.gu(3.6)
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
                                    spacing: units.gu(0.5)

                                    Icon {
                                        name: "account"
                                        width: units.gu(2.2)
                                        height: units.gu(2.2)
                                        color: "white"
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    Label {
                                        id: accountNameLabel
                                        visible: drawerHeader.width >= units.gu(29)
                                        Layout.alignment: Qt.AlignVCenter
                                        text: {
                                            if (typeof accountPicker === "undefined" || !accountPicker.selectedAccountName) return "";
                                            return (accountPicker.selectedAccountId === 0 || accountPicker.selectedAccountName === "Local Account") ? "Local" : accountPicker.selectedAccountName;
                                        }
                                        color: "white"
                                        font.pixelSize: units.dp(13)
                                        font.bold: true
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                        Layout.maximumWidth: Math.min(units.gu(10), Math.max(units.gu(3), drawerHeader.width - units.gu(24)))
                                    }
                                }

                                MouseArea {
                                    id: accountMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        drawerRoot.close();
                                        if (typeof accountPicker !== "undefined") {
                                            accountPicker.open(accountPicker.selectedAccountId);
                                        }
                                    }

                                    Controls.ToolTip.visible: accountMouseArea.containsMouse
                                    Controls.ToolTip.text: {
                                        var name = (typeof accountPicker !== "undefined" && accountPicker.selectedAccountName) ? accountPicker.selectedAccountName : "";
                                        if (!name || name === "Local Account" || (typeof accountPicker !== "undefined" && accountPicker.selectedAccountId === 0)) {
                                            return i18n.dtr("ubtms", "Local Account");
                                        }
                                        return name;
                                    }
                                    Controls.ToolTip.delay: 400
                                }
                            }

                            // Local Account Toggle Switch (hidden on narrow widths to guarantee fit)
                            TSSwitch {
                                id: localToggleSwitch
                                visible: drawerHeader.width >= units.gu(25)
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

                            // Theme Toggle Button (guaranteed to be visible and anchored at the right edge)
                            Rectangle {
                                id: themeToggleBtn
                                implicitWidth: units.gu(3.6)
                                implicitHeight: units.gu(3.6)
                                Layout.preferredWidth: implicitWidth
                                Layout.preferredHeight: implicitHeight
                                radius: height / 2
                                color: themeMouseArea.pressed ? "#40ffffff" : (themeMouseArea.containsMouse ? "#30ffffff" : "transparent")
                                Layout.alignment: Qt.AlignVCenter

                                Behavior on color {
                                    ColorAnimation { duration: 100 }
                                }

                                Image {
                                    anchors.centerIn: parent
                                    width: units.gu(2.2)
                                    height: units.gu(2.2)
                                    source: theme.name === "Ubuntu.Components.Themes.SuruDark" ? Qt.resolvedUrl("../images/daymode.png") : Qt.resolvedUrl("../images/darkmode.png")
                                    fillMode: Image.PreserveAspectFit
                                }

                                MouseArea {
                                    id: themeMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Theme.name = theme.name === "Ubuntu.Components.Themes.SuruDark" ? "Ubuntu.Components.Themes.Ambiance" : "Ubuntu.Components.Themes.SuruDark";
                                    }

                                    Controls.ToolTip.visible: themeMouseArea.containsMouse
                                    Controls.ToolTip.text: theme.name === "Ubuntu.Components.Themes.SuruDark" ? i18n.dtr("ubtms", "Light mode") : i18n.dtr("ubtms", "Dark mode")
                                    Controls.ToolTip.delay: 400
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: mainSection.height
                    color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#1e1e1e" : "#ffffff"

                    Column {
                        id: mainSection
                        width: parent.width

                        NavigationMenuList {
                            width: parent.width
                            menuItems: NavigationRoutes.menuItems()
                            selectedPageUrl: apLayout && apLayout.currentMenuPageUrl ? apLayout.currentMenuPageUrl : ""
                            onItemSelected: function (item) {
                                drawerRoot.close();
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
