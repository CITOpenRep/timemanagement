import QtQuick 2.6
import QtQuick.Controls 2.2 as Controls
import Lomiri.Components 1.3
import "settings"

Controls.Drawer {
    id: drawerRoot
    edge: Qt.LeftEdge
    interactive: true

    property var apLayout

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

                // Header for the Drawer
                Rectangle {
                    width: parent.width
                    height: units.gu(8)
                    color: LomiriColors.orange
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(2)
                        text: i18n.dtr("ubtms", "Menu")
                        color: "white"
                        fontSize: "large"
                    }
                }

                Rectangle {
                    width: parent.width
                    height: mainSection.height
                    color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#1e1e1e" : "#ffffff"

                    Column {
                        id: mainSection
                        width: parent.width

                        SettingsListItem {
                            iconName: "home"
                            iconColor: "#3498db"
                            text: i18n.dtr("ubtms", "Dashboard")
                            onClicked: {
                                drawerRoot.close();
                                apLayout.setPageGlobal("Dashboard.qml", 0)
                            }
                        }

                        SettingsListItem {
                            iconName: "alarm-clock"
                            iconColor: "#e67e22"
                            text: i18n.dtr("ubtms", "Timesheet")
                            onClicked: {
                                drawerRoot.close();
                                apLayout.setPageGlobal("Timesheet_Page.qml", 1)
                            }
                        }

                        SettingsListItem {
                            iconName: "calendar"
                            iconColor: "#e74c3c"
                            text: i18n.dtr("ubtms", "Activities")
                            onClicked: {
                                drawerRoot.close();
                                apLayout.setPageGlobal("Activity_Page.qml", 2)
                            }
                        }

                        SettingsListItem {
                            iconName: "scope-manager"
                            iconColor: "#2ecc71"
                            text: i18n.dtr("ubtms", "My Tasks")
                            onClicked: {
                                drawerRoot.close();
                                apLayout.setPageGlobal("MyTasks.qml", 3)
                            }
                        }

                        SettingsListItem {
                            iconName: "view-list-symbolic"
                            iconColor: "#1abc9c"
                            text: i18n.dtr("ubtms", "All Tasks")
                            onClicked: {
                                drawerRoot.close();
                                apLayout.setPageGlobal("Task_Page.qml", 3)
                            }
                        }

                        SettingsListItem {
                            iconName: "folder-symbolic"
                            iconColor: "#9b59b6"
                            text: i18n.dtr("ubtms", "Projects")
                            onClicked: {
                                drawerRoot.close();
                                apLayout.setPageGlobal("Project_Page.qml", 4)
                            }
                        }

                        SettingsListItem {
                            iconName: "history"
                            iconColor: "#f39c12"
                            text: i18n.dtr("ubtms", "Project Updates")
                            onClicked: {
                                drawerRoot.close();
                                apLayout.setPageGlobal("Updates_Page.qml", 5)
                            }
                        }

                        SettingsListItem {
                            iconName: "settings"
                            iconColor: "#7f8c8d"
                            text: i18n.dtr("ubtms", "Settings")
                            showDivider: false
                            onClicked: {
                                drawerRoot.close();
                                apLayout.setPageGlobal("settings/Settings_Page.qml", 6)
                            }
                        }
                    }
                }
            }
        }
    }
}
