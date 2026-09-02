import QtQuick 2.6
import QtQuick.Controls 2.2 as Controls
import QtQuick.Layouts 1.3
import Lomiri.Components 1.3
import Lomiri.Components.Themes.Ambiance 1.3
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
                    width: parent.width
                    height: units.gu(8)
                    color: LomiriColors.orange

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: units.gu(2)
                        anchors.rightMargin: units.gu(1.2)
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
                            id: accountSelectorItem
                            implicitWidth: accountRow.implicitWidth
                            implicitHeight: accountRow.implicitHeight
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
                                    id: accountNameLabel
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
                                    Layout.maximumWidth: units.gu(10)
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    drawerRoot.close();
                                    if (typeof accountPicker !== "undefined") {
                                        accountPicker.open(accountPicker.selectedAccountId);
                                    }
                                }
                            }
                        }

                        // Local Account Toggle Switch
                        Switch {
                            id: localToggleSwitch
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredWidth: units.gu(4.2)
                            Layout.preferredHeight: units.gu(2.1)
                            width: units.gu(4.2)
                            height: units.gu(2.1)
                            checked: typeof accountPicker !== "undefined" ? (accountPicker.selectedAccountId === 0) : false
                            style: Component {
                                SwitchStyle {
                                    implicitWidth: units.gu(4.2)
                                    implicitHeight: units.gu(2.1)
                                    checkedBackgroundColor: "#ffd8a8"
                                }
                            }

                            onClicked: {
                                if (typeof accountPicker !== "undefined") {
                                    accountPicker.toggleLocalMode(checked);
                                }
                            }

                            Binding {
                                target: localToggleSwitch
                                property: "checked"
                                value: typeof accountPicker !== "undefined" ? (accountPicker.selectedAccountId === 0) : false
                            }

                            Connections {
                                target: typeof accountPicker !== "undefined" ? accountPicker : null
                                onSelectedAccountIdChanged: {
                                    localToggleSwitch.checked = (accountPicker.selectedAccountId === 0);
                                }
                                onAccepted: {
                                    localToggleSwitch.checked = (accountId === 0);
                                }
                            }

                            Connections {
                                target: typeof rootApp !== "undefined" ? rootApp : null
                                onGlobalAccountChanged: {
                                    localToggleSwitch.checked = (accountId === 0);
                                }
                            }
                        }

                        // Theme Toggle Button
                        Item {
                            width: units.gu(4)
                            height: units.gu(4)
                            Layout.alignment: Qt.AlignVCenter

                            Image {
                                anchors.centerIn: parent
                                width: units.gu(2.2)
                                height: units.gu(2.2)
                                source: theme.name === "Ubuntu.Components.Themes.SuruDark" ? Qt.resolvedUrl("../images/daymode.png") : Qt.resolvedUrl("../images/darkmode.png")
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
