import QtQuick 2.6
import QtQuick.Controls 2.2 as Controls
import Lomiri.Components 1.3
import "settings"
import "MenuData.js" as MenuData

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

                    Item {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: units.gu(1.2)
                        width: units.gu(4)
                        height: units.gu(4)

                        Image {
                            anchors.centerIn: parent
                            width: units.gu(2.2)
                            height: units.gu(2.2)
                            source: theme.name === "Ubuntu.Components.Themes.SuruDark" ? Qt.resolvedUrl("../images/daymode.png") : Qt.resolvedUrl("../images/darkmode.png")
                            fillMode: Image.PreserveAspectFit
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                Theme.name = theme.name === "Ubuntu.Components.Themes.SuruDark" ? "Ubuntu.Components.Themes.Ambiance" : "Ubuntu.Components.Themes.SuruDark";
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
                            menuItems: MenuData.items()
                            onItemSelected: function(item) {
                                drawerRoot.close()
                                apLayout.setPageGlobal(item.pageUrl, item.pageNum)
                            }
                        }
                    }
                }
            }
        }
    }
}
