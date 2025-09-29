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
    id: assigneeFilterMenu
    anchors.fill: parent

    signal filterApplied(var selectedAssigneeIds)
    signal filterCleared

    property var assigneeModel: []
    property bool expanded: false
    property var selectedAssigneeIds: []
    property int fabSize: units.gu(7)
    property int maxMenuHeight: units.gu(50)

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
        bgColor: LomiriColors.blue
        fgColor: "white"
        hoverColor: Qt.darker(bgColor, 1.2)
        radius: width / 2
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: units.gu(3)
        anchors.bottomMargin: units.gu(11) // Position above the stage filter menu
        iconName: expanded ? "close" : "contact"
        iconBold: true
        iconSize: units.gu(3)

        z: 15

        onClicked: {
            expanded = !expanded;
            console.log("Assignee filter menu", expanded ? "expanded" : "collapsed", "- Assignees available:", assigneeModel.length);
        }

        // Badge showing number of selected assignees
        Rectangle {
            visible: selectedAssigneeIds.length > 0
            width: units.gu(2.5)
            height: units.gu(2.5)
            radius: width / 2
            color: LomiriColors.red
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: units.gu(0.2)
            anchors.rightMargin: units.gu(0.2)

            Text {
                anchors.centerIn: parent
                text: selectedAssigneeIds.length.toString()
                color: "white"
                font.pixelSize: units.gu(1.2)
                font.bold: true
            }
        }
    }

    // Filter menu container
    Rectangle {
        id: menuContainer
        visible: expanded
        width: units.gu(40)
        height: {
            // Calculate dynamic height: header + search + assignee list + buttons + margins
            var baseHeight = units.gu(22); // Header + search + buttons + margins
            var assigneeListHeight = Math.min(assigneeModel.length * units.gu(6), units.gu(25)); // Max 25 units for list
            return Math.min(units.gu(50), baseHeight + assigneeListHeight);
        }

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
            id: contentColumn
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
                        name: "contact"
                        width: units.gu(2.5)
                        height: units.gu(2.5)
                        anchors.verticalCenter: parent.verticalCenter
                        color: theme.palette.normal.backgroundText
                    }

                    Text {
                        text: "Filter by Assignees"
                        font.bold: true
                        font.pixelSize: units.gu(2.2)
                        color: theme.palette.normal.backgroundText
                        anchors.verticalCenter: parent.verticalCenter
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
                visible: assigneeModel.length > 5
                width: parent.width
                height: units.gu(4)
                placeholderText: "Search assignees..."

                onTextChanged: {
                    filterModel.update();
                }
            }

            // Assignee list view
            ListView {
                id: assigneeListView
                width: parent.width
                height: Math.min(units.gu(20), Math.max(units.gu(12), filterModel.count * units.gu(6)))
                clip: true

                model: ListModel {
                    id: filterModel

                    function update() {
                        clear();
                        var searchText = searchField.text.toLowerCase();

                        for (var i = 0; i < assigneeModel.length; i++) {
                            var assignee = assigneeModel[i];
                            var displayText = assignee.name;
                            if (assignee.account_name) {
                                displayText = assignee.name + " (" + assignee.account_name + ")";
                            }
                            if (!searchText || displayText.toLowerCase().indexOf(searchText) >= 0) {
                                append({
                                    "assigneeId": assignee.odoo_record_id || assignee.id,
                                    "name": assignee.name,
                                    "account_name": assignee.account_name || "",
                                    "account_id": assignee.account_id || -1,
                                    "displayText": displayText,
                                    "selected": selectedAssigneeIds.indexOf(assignee.odoo_record_id || assignee.id) !== -1
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
                    height: units.gu(6)
                    color: mouseArea.pressed ? theme.palette.selected.background : "transparent"
                    radius: units.gu(0.5)

                    Row {
                        anchors.fill: parent
                        anchors.margins: units.gu(1)
                        spacing: units.gu(1.5)

                        // Checkbox
                        CheckBox {
                            id: checkbox
                            anchors.verticalCenter: parent.verticalCenter
                            checked: model.selected
                            enabled: false  // Disable direct checkbox interaction to avoid conflicts
                        }

                        // User icon
                        Icon {
                            name: "contact"
                            width: units.gu(2.5)
                            height: units.gu(2.5)
                            anchors.verticalCenter: parent.verticalCenter
                            color: theme.palette.normal.backgroundText
                        }

                        // Assignee name with account
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - checkbox.width - units.gu(6)
                            spacing: units.gu(0.2)

                            Text {
                                text: model.name
                                font.pixelSize: units.gu(2)
                                color: theme.palette.normal.backgroundText
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                visible: model.account_name !== ""
                                text: "(" + model.account_name  + ")"
                                font.pixelSize: units.gu(1.5)
                                color: theme.palette.normal.backgroundSecondaryText
                                elide: Text.ElideRight
                                width: parent.width
                                opacity: 0.7
                            }
                        }
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: {
                            // Toggle checkbox state
                            checkbox.checked = !checkbox.checked;

                            // Update selection logic
                            var assigneeId = model.assigneeId;
                            var currentIndex = selectedAssigneeIds.indexOf(assigneeId);

                            console.log("MouseArea clicked - Assignee:", model.name, "ID:", assigneeId, "Account:", model.account_name, "Account ID:", model.account_id, "Checked:", checkbox.checked);
                            console.log("Current selectedAssigneeIds before:", JSON.stringify(selectedAssigneeIds));

                            if (checkbox.checked && currentIndex === -1) {
                                // Add to selection
                                selectedAssigneeIds.push(assigneeId);
                                console.log("Added assignee ID", assigneeId, "to selection");
                            } else if (!checkbox.checked && currentIndex !== -1) {
                                // Remove from selection
                                selectedAssigneeIds.splice(currentIndex, 1);
                                console.log("Removed assignee ID", assigneeId, "from selection");
                            }

                            // Trigger property change notification
                            selectedAssigneeIds = selectedAssigneeIds.slice();

                            console.log("Current selectedAssigneeIds after:", JSON.stringify(selectedAssigneeIds));
                            console.log("Apply button should be enabled:", selectedAssigneeIds.length > 0);

                            // Update model
                            filterModel.setProperty(index, "selected", checkbox.checked);
                        }
                    }

                    // Hover effect
                    Rectangle {
                        anchors.fill: parent
                        color: theme.palette.highlighted.background
                        opacity: mouseArea.containsMouse ? 0.1 : 0
                        radius: parent.radius

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 150
                            }
                        }
                    }
                }
            }

            // Action buttons
            Rectangle {
                width: parent.width
                height: units.gu(8)
                color: "transparent"

                Rectangle {
                    width: parent.width
                    height: 1
                    color: theme.palette.normal.base
                    anchors.top: parent.top
                }

                Row {
                    anchors.centerIn: parent
                    spacing: units.gu(2)

                    // Apply Filter Button
                    TSButton {
                        text: "Apply Filter"
                        enabled: selectedAssigneeIds.length > 0
                        width: units.gu(15)
                        height: units.gu(4)
                        bgColor: enabled ? LomiriColors.blue : LomiriColors.ash
                        fgColor: "white"

                        Component.onCompleted: {
                            console.log("Apply button created, enabled:", enabled);
                        }

                        onClicked: {
                            if (selectedAssigneeIds.length > 0) {
                                console.log("Apply button clicked with", selectedAssigneeIds.length, "assignees");
                                expanded = false;
                                filterApplied(selectedAssigneeIds.slice());
                            } else {
                                console.log("Apply button clicked but no assignees selected - ignoring");
                            }
                        }
                    }

                    // Clear Filter Button
                    TSButton {
                        text: "Clear Filter"
                        enabled: selectedAssigneeIds.length > 0
                        width: units.gu(15)
                        height: units.gu(4)
                        bgColor: enabled ? LomiriColors.orange : LomiriColors.ash
                        fgColor: "white"

                        Component.onCompleted: {
                            console.log("Clear button created, enabled:", enabled);
                        }

                        onClicked: {
                            console.log("Clear button clicked");
                            selectedAssigneeIds = [];
                            filterModel.update();
                            expanded = false;
                            filterCleared();
                        }
                    }
                }
            }

            // Footer with current selection count
            Rectangle {
                width: parent.width
                height: units.gu(3)
                color: "transparent"
                visible: selectedAssigneeIds.length > 0

                Rectangle {
                    width: parent.width
                    height: 1
                    color: theme.palette.normal.base
                    anchors.top: parent.top
                }

                Text {
                    text: selectedAssigneeIds.length + " assignee" + (selectedAssigneeIds.length === 1 ? "" : "s") + " selected"
                    font.pixelSize: units.gu(1.6)
                    color: theme.palette.normal.backgroundText
                    anchors.centerIn: parent
                    opacity: 0.7
                }
            }
        }
    }

    // Function to load assignees for the current account
    function loadAssignees(accountId) {
    // This will be called from the parent component
    // to populate the assigneeModel
    }

    // Initialize the filter model when assigneeModel changes
    onAssigneeModelChanged: {
        if (filterModel) {
            filterModel.update();
        }
    }

    // Update filter model when selectedAssigneeIds changes
    onSelectedAssigneeIdsChanged: {
        if (filterModel) {
            // Update the selected state in the model
            for (var i = 0; i < filterModel.count; i++) {
                var assigneeId = filterModel.get(i).assigneeId;
                var isSelected = selectedAssigneeIds.indexOf(assigneeId) !== -1;
                filterModel.setProperty(i, "selected", isSelected);
            }
        }
    }

    Component.onCompleted: {
        if (filterModel) {
            filterModel.update();
        }
    }
}
