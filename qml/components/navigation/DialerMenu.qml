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
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.0
import Lomiri.Components 1.3
import "../../../models/constants.js" as AppConst
import ".."

Item {
    id: dialerMenu
    anchors.fill: parent

    signal menuItemSelected(int index)

    property alias menuModel: repeater.model
    property bool expanded: false
    property int fabSize: units.gu(6.5)
    property int itemSize: units.gu(5)

    // Backdrop dismiss scrim (captures taps outside menu to dismiss)
    Rectangle {
        id: backdropScrim
        anchors.fill: parent
        color: "#000000"
        opacity: dialerMenu.expanded ? 0.35 : 0.0
        visible: opacity > 0.01
        z: 10

        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
        }

        MouseArea {
            anchors.fill: parent
            enabled: dialerMenu.expanded
            cursorShape: Qt.ArrowCursor
            onClicked: dialerMenu.expanded = false
        }
    }

    // Action menu items column
    Column {
        id: menuList
        visible: dialerMenu.expanded
        spacing: units.gu(1.2)
        anchors.right: fabContainer.right
        anchors.bottom: fabContainer.top
        anchors.bottomMargin: units.gu(1.5)
        z: 20

        Repeater {
            id: repeater

            delegate: Item {
                id: itemDelegate
                width: cardRow.implicitWidth + units.gu(1.6)
                height: dialerMenu.itemSize
                anchors.right: parent ? parent.right : undefined

                readonly property bool isDarkTheme: theme.name === "Ubuntu.Components.Themes.SuruDark"
                readonly property string itemIcon: (modelData && modelData.iconName) ? modelData.iconName : "add"
                readonly property string itemLabel: (modelData && modelData.label) ? modelData.label : ""

                opacity: dialerMenu.expanded ? 1.0 : 0.0
                scale: dialerMenu.expanded ? 1.0 : 0.85
                transform: Translate {
                    y: dialerMenu.expanded ? 0 : units.gu(1.5)
                    Behavior on y {
                        NumberAnimation {
                            duration: 180 + (repeater.count - 1 - index) * 35
                            easing.type: Easing.OutBack
                        }
                    }
                }

                Behavior on opacity {
                    id: opacityAnim
                    NumberAnimation {
                        duration: 150 + (repeater.count - 1 - index) * 30
                        easing.type: Easing.OutQuad
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: 180 + (repeater.count - 1 - index) * 35
                        easing.type: Easing.OutBack
                    }
                }

                Rectangle {
                    id: cardBg
                    anchors.fill: parent
                    radius: height / 2
                    color: itemMouseArea.pressed
                           ? (itemDelegate.isDarkTheme ? "#383838" : "#ebebeb")
                           : (itemMouseArea.containsMouse
                              ? (itemDelegate.isDarkTheme ? "#303030" : "#f7f7f7")
                              : (itemDelegate.isDarkTheme ? "#222222" : "#ffffff"))
                    border.color: itemDelegate.isDarkTheme ? "#404040" : "#e0e0e0"
                    border.width: 1

                    layer.enabled: true
                    layer.effect: DropShadow {
                        transparentBorder: true
                        horizontalOffset: 0
                        verticalOffset: units.gu(0.3)
                        radius: units.gu(1.0)
                        samples: 16
                        color: itemDelegate.isDarkTheme ? "#60000000" : "#25000000"
                    }

                    Behavior on color {
                        ColorAnimation { duration: 100 }
                    }

                    Row {
                        id: cardRow
                        anchors.centerIn: parent
                        anchors.leftMargin: units.gu(1.8)
                        anchors.rightMargin: units.gu(0.8)
                        spacing: units.gu(1.2)

                        Text {
                            id: labelText
                            anchors.verticalCenter: parent.verticalCenter
                            text: itemDelegate.itemLabel
                            color: itemDelegate.isDarkTheme ? "#f5f5f5" : "#1a1a1a"
                            font.pixelSize: units.gu(1.8)
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        // Circular icon chip
                        Rectangle {
                            id: iconChip
                            width: units.gu(3.8)
                            height: units.gu(3.8)
                            radius: width / 2
                            anchors.verticalCenter: parent.verticalCenter
                            color: LomiriColors.orange

                            Icon {
                                id: actionIcon
                                anchors.centerIn: parent
                                width: units.gu(2)
                                height: units.gu(2)
                                name: itemDelegate.itemIcon
                                color: "#ffffff"
                            }

                            ColorOverlay {
                                anchors.fill: actionIcon
                                source: actionIcon
                                color: "#ffffff"
                            }
                        }
                    }
                }

                MouseArea {
                    id: itemMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        dialerMenu.expanded = false;
                        dialerMenu.menuItemSelected(index);
                    }
                }
            }
        }
    }

    // Main Floating Action Button Container
    Item {
        id: fabContainer
        width: dialerMenu.fabSize
        height: dialerMenu.fabSize
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: units.gu(2.5)
        z: 20

        scale: fabMouseArea.pressed ? 0.92 : (fabMouseArea.containsMouse ? 1.05 : 1.0)
        Behavior on scale {
            NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
        }

        Rectangle {
            id: fabCircle
            anchors.fill: parent
            radius: width / 2
            color: fabMouseArea.containsMouse ? Qt.darker(LomiriColors.orange, 1.1) : LomiriColors.orange

            Behavior on color {
                ColorAnimation { duration: 150 }
            }

            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                horizontalOffset: 0
                verticalOffset: units.gu(0.4)
                radius: units.gu(1.2)
                samples: 16
                color: "#45000000"
            }

            // Dual-icon container with smooth rotation and cross-fade morph
            Item {
                id: iconContainer
                anchors.centerIn: parent
                width: units.gu(3)
                height: units.gu(3)

                // Hamburger icon layer
                Item {
                    anchors.fill: parent
                    opacity: dialerMenu.expanded ? 0.0 : 1.0
                    rotation: dialerMenu.expanded ? 90 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
                    }
                    Behavior on rotation {
                        NumberAnimation { duration: 220; easing.type: Easing.OutBack }
                    }

                    Icon {
                        id: hamburgerIcon
                        anchors.fill: parent
                        name: "open-menu-symbolic"
                        color: "#ffffff"
                    }

                    ColorOverlay {
                        anchors.fill: hamburgerIcon
                        source: hamburgerIcon
                        color: "#ffffff"
                    }
                }

                // Close 'x' icon layer
                Item {
                    anchors.fill: parent
                    opacity: dialerMenu.expanded ? 1.0 : 0.0
                    rotation: dialerMenu.expanded ? 0 : -90

                    Behavior on opacity {
                        NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
                    }
                    Behavior on rotation {
                        NumberAnimation { duration: 220; easing.type: Easing.OutBack }
                    }

                    Icon {
                        id: closeIcon
                        anchors.fill: parent
                        name: "close"
                        color: "#ffffff"
                    }

                    ColorOverlay {
                        anchors.fill: closeIcon
                        source: closeIcon
                        color: "#ffffff"
                    }
                }
            }
        }

        MouseArea {
            id: fabMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                dialerMenu.expanded = !dialerMenu.expanded;
            }
        }
    }
}
