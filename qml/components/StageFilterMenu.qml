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
import "../../models/constants.js" as AppConst

Item {
    id: stageFilterMenu
    anchors.fill: parent

    signal menuItemSelected(int index)
    signal filterCleared

    property var menuModel: []
    property bool expanded: false
    property int selectedIndex: -1
    property string selectedFilterName: "All Stages"
    property int fabSize: units.gu(7)
    property int maxMenuHeight: units.gu(40)

    // Background overlay when expanded
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: expanded ? 0.3 : 0
        visible: expanded

        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: expanded = false
        }
    }

    // Floating Action Button (FAB)
    TSIconButton {
        id: fab
        width: fabSize
        height: fabSize
        bgColor: LomiriColors.orange
        fgColor: "white"
        hoverColor: Qt.darker(bgColor, 1.2)
        radius: width / 2
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: units.gu(3)
        iconName: expanded ? "close" : "filters"
        iconBold: true
        iconSize: units.gu(3)
        

        z: 15

        onClicked: {
            expanded = !expanded;
        }

        // Badge showing current filter
        Rectangle {
            visible: selectedIndex > 0 // Show badge when not "All Stages"
            width: units.gu(2)
            height: units.gu(2)
            radius: width / 2
            color: LomiriColors.red
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: units.gu(0.5)
            anchors.rightMargin: units.gu(0.5)

            Text {
                anchors.centerIn: parent
                text: "●"
                color: "white"
                font.pixelSize: units.gu(1)
            }
        }
    }

    // Filter menu container
    Rectangle {
        id: menuContainer
        visible: expanded
        width: Math.min(units.gu(35), parent.width * 0.8)
        height: Math.min(maxMenuHeight, menuListView.contentHeight + units.gu(8))

        anchors.bottom: fab.top
        anchors.right: parent.right
        anchors.margins: units.gu(1)
        anchors.bottomMargin: units.gu(2)

        radius: units.gu(2)
        color: theme.palette.normal.background
        border.color: theme.palette.normal.base
        border.width: 1

        

        z: 12

        // Drop shadow effect
        layer.enabled: true
        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: 4
            radius: 8
            samples: 17
            color: "#40000000"
        }

        // Scale and opacity animations
        scale: expanded ? 1 : 0.8
        opacity: expanded ? 1 : 0

        Behavior on scale {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutBack
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }

        Column {
            anchors.fill: parent
            anchors.margins: units.gu(1)
            spacing: units.gu(1)

            // Header
            Rectangle {
                width: parent.width
                height: units.gu(5)
                color: "transparent"

                Row {
                    anchors.fill: parent
                    anchors.margins: units.gu(1)
                    spacing: units.gu(1)

                    Icon {
                        name: "filters"
                        width: units.gu(2.5)
                        height: units.gu(2.5)
                        anchors.verticalCenter: parent.verticalCenter
                        color: theme.palette.normal.backgroundText
                    }

                    Text {
                        text: "Filter by Stage"
                        font.bold: true
                        font.pixelSize: units.gu(2.2)
                        color: theme.palette.normal.backgroundText
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Item {
                        Layout.fillWidth: true
                    } // Spacer

                    // Clear filter button
                    TSIconButton {
                        visible: selectedIndex > 0
                        width: units.gu(3.5)
                        height: units.gu(3.5)
                        radius: width / 2
                        iconName: "edit-clear"
                        bgColor: LomiriColors.orange
                        fgColor: "white"
                        hoverColor: Qt.darker(bgColor, 1.2)
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right

                        onClicked: {
                            selectedIndex = 0;
                            selectedFilterName = menuModel.length > 0 ? menuModel[0].label : "All Stages";
                            expanded = false;
                            filterCleared();
                            menuItemSelected(0);
                        }
                    }
                }
            }

            // Separator
            Rectangle {
                width: parent.width
                height: 1
                color: theme.palette.normal.base
            }

            // Search bar for long lists
            TextField {
                id: searchField
                visible: menuModel.length > 10
                width: parent.width
                height: units.gu(4)
                placeholderText: "Search stages..."

                onTextChanged: {
                    filterModel.update();
                }
            }

            // Filtered list view
            ListView {
                id: menuListView
                width: parent.width
                height: parent.parent.height - units.gu(7) - (searchField.visible ? units.gu(5) : 0)
                clip: true

                model: ListModel {
                    id: filterModel

                    function update() {
                        clear();
                        var searchText = searchField.text.toLowerCase();

                        for (var i = 0; i < menuModel.length; i++) {
                            var item = menuModel[i];
                            if (!searchText || item.label.toLowerCase().indexOf(searchText) >= 0) {
                                append({
                                    "originalIndex": i,
                                    "label": item.label,
                                    "value": item.value
                                });
                            }
                        }
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    width: units.gu(1)
                }

                delegate: Rectangle {
                  
                    width: parent.width
                    height: units.gu(5.5)
                    color: mouseArea.pressed ? theme.palette.selected.background : (selectedIndex === model.originalIndex ? theme.palette.selected.background : "transparent")
                    radius: units.gu(0.5)

                    Rectangle {
                        visible: selectedIndex === model.originalIndex
                        width: units.gu(0.5)
                        height: parent.height * 0.6
                        color: LomiriColors.orange
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: units.gu(0.5)
                        radius: width / 2
                    }

                    Row {
                        anchors.fill: parent
                        anchors.margins: units.gu(1)
                        spacing: units.gu(1.5)
                        anchors.leftMargin: units.gu(1.5)

                        Icon {
                            name: model.originalIndex === 0 ? "view-list-symbolic" : "tag"
                            width: units.gu(2)
                            height: units.gu(2)
                            anchors.verticalCenter: parent.verticalCenter
                            color: selectedIndex === model.originalIndex ? theme.palette.selected.backgroundText : theme.palette.normal.backgroundText
                        }

                        Text {
                            text: model.label
                            font.pixelSize: units.gu(2)
                            color: selectedIndex === model.originalIndex ? theme.palette.selected.backgroundText : theme.palette.normal.backgroundText
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                            width: parent.width - units.gu(4)

                            font.weight: model.originalIndex === 0 ? Font.Bold : Font.Normal
                        }
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: {
                            selectedIndex = model.originalIndex;
                            selectedFilterName = model.label;
                            expanded = false;
                            menuItemSelected(model.originalIndex);
                        }
                    }

                    // Hover effect
                    Rectangle {
                        anchors.fill: parent
                        color: theme.palette.highlighted.background
                        opacity: mouseArea.containsMouse && selectedIndex !== model.originalIndex ? 0.1 : 0
                        radius: parent.radius

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 150
                            }
                        }
                    }
                }
            }

            // Footer with current selection
            Rectangle {
                width: parent.width
                height: units.gu(3)
                color: "transparent"
                visible: selectedIndex >= 0

                Rectangle {
                    width: parent.width
                    height: 1
                    color: theme.palette.normal.base
                    anchors.top: parent.top
                }

                Text {
                    text: "Current: " + selectedFilterName
                    font.pixelSize: units.gu(1.6)
                    color: theme.palette.normal.backgroundText
                    anchors.centerIn: parent
                    opacity: 0.7
                    elide: Text.ElideRight
                    width: parent.width - units.gu(2)
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }

    // Initialize the filter model when menuModel changes
    onMenuModelChanged: {
        if (filterModel) {
            filterModel.update();
        }
    }

    Component.onCompleted: {
        if (filterModel) {
            filterModel.update();
        }
    }
}
