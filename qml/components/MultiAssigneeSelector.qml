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
import "../../models/accounts.js" as Accounts

Item {
    id: multiAssigneeSelector
    width: parent ? parent.width : 400
    height: mainColumn.implicitHeight + units.gu(2)

    property bool readOnly: false
    property string labelText: "Assignees"
    property int accountId: -1
    property var selectedAssignees: [] // Array of {id, name} objects

    signal assigneesChanged(var assignees)

    // Public API
    function setSelectedAssignees(assignees) {
        selectedAssignees = assignees || [];
        updateDisplayText();
        assigneesChanged(selectedAssignees);
    }

    function getSelectedAssignees() {
        return selectedAssignees;
    }

    function getSelectedAssigneeIds() {
        return selectedAssignees.map(function (assignee) {
            return assignee.id;
        });
    }

    function loadAssignees(accountId) {
        multiAssigneeSelector.accountId = accountId;
        availableAssignees = Accounts.getUsers(accountId);

        // Filter out "Select Assignee" entry and add proper structure
        var filteredAssignees = [];
        for (let i = 0; i < availableAssignees.length; i++) {
            let assignee = availableAssignees[i];
            let id = (accountId === 0) ? assignee.id : assignee.odoo_record_id;
            if (id > 0) {
                // Skip invalid/placeholder entries
                filteredAssignees.push({
                    id: id,
                    name: assignee.name
                });
            }
        }
        availableAssignees = filteredAssignees;
    }

    property var availableAssignees: []

    function updateDisplayText() {
        if (selectedAssignees.length === 0) {
            displayButton.text = "Select Assignees";
        } else if (selectedAssignees.length === 1) {
            displayButton.text = selectedAssignees[0].name;
        } else {
            displayButton.text = selectedAssignees.length + " assignees selected";
        }
    }

    Column {
        id: mainColumn
        anchors.fill: parent
        anchors.margins: units.gu(1)
        spacing: units.gu(1)

        Row {
            width: parent.width
            spacing: units.gu(2)

            TSLabel {
                text: labelText
                width: parent.width * 0.3
                anchors.verticalCenter: parent.verticalCenter
            }

            TSButton {
                id: displayButton
                text: "Select Assignees"
                enabled: !readOnly && availableAssignees.length > 0
                width: parent.width * 0.6
                height: units.gu(5)
                anchors.verticalCenter: parent.verticalCenter

                onClicked: {
                    if (!readOnly) {
                        assigneeDialog.visible = true;
                    }
                }
            }
        }

        // Display selected assignees as chips/tags
        Flow {
            id: assigneeFlow
            width: parent.width
            spacing: units.gu(0.5)
            visible: selectedAssignees.length > 0

            Repeater {
                model: selectedAssignees.length

                Item {
                    width: assigneeChip.width
                    height: assigneeChip.height

                    Rectangle {
                        id: assigneeChip
                        width: assigneeLabel.width + removeButton.width + units.gu(2)
                        height: units.gu(3)
                        radius: units.gu(1.5)
                        color: "#3498db"  // Blue color
                        border.color: "#666666"  // Dark grey
                        border.width: 1

                        Row {
                            anchors.centerIn: parent
                            spacing: units.gu(0.5)

                            Label {
                                id: assigneeLabel
                                text: selectedAssignees[index].name
                                color: "white"
                                font.pixelSize: units.gu(1.2)
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            TSButton {
                                id: removeButton
                                text: "×"
                                visible: !readOnly
                                width: units.gu(2)
                                height: units.gu(2)
                                anchors.verticalCenter: parent.verticalCenter
                                // color: LomiriColors.red

                                onClicked: {
                                    removeAssignee(index);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function removeAssignee(index) {
        if (index >= 0 && index < selectedAssignees.length) {
            selectedAssignees.splice(index, 1);
            selectedAssignees = selectedAssignees; // Trigger change
            updateDisplayText();
            assigneesChanged(selectedAssignees);
        }
    }

    function addAssignee(assignee) {
        // Check if already selected
        for (let i = 0; i < selectedAssignees.length; i++) {
            if (selectedAssignees[i].id === assignee.id) {
                return; // Already selected
            }
        }
        selectedAssignees.push(assignee);
        selectedAssignees = selectedAssignees; // Trigger change
        updateDisplayText();
        assigneesChanged(selectedAssignees);
    }

    // Modal dialog for selecting multiple assignees
    Rectangle {
        id: assigneeDialog
        visible: false
        anchors.fill: parent
        color: "black"
        opacity: 0.8
        z: 1000

        MouseArea {
            anchors.fill: parent
            onClicked: {
                // Close dialog when clicking outside
                assigneeDialog.visible = false;
            }
        }

        Rectangle {
            id: dialogContent
            width: units.gu(60)
            height: units.gu(50)
            anchors.centerIn: parent
            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#2C2C2C" : "white"
            radius: units.gu(1)
            border.color: "#CCCCCC"
            border.width: 2

            MouseArea {
                anchors.fill: parent
                onClicked:
                // Prevent closing when clicking inside dialog
                {}
            }

            Column {
                anchors.fill: parent
                anchors.margins: units.gu(2)
                spacing: units.gu(1)

                Row {
                    width: parent.width

                    TSLabel {
                        text: "Select Assignees"
                        // font.bold: true
                        //font.pixelSize: units.gu(2)
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Item {
                        width: parent.width - closeButton.width - parent.children[0].width
                        height: units.gu(1)
                    }

                    TSButton {
                        id: closeButton
                        text: "×"
                        width: units.gu(4)
                        height: units.gu(4)
                        onClicked: {
                            assigneeDialog.visible = false;
                        }
                    }
                }

                TSLabel {
                    text: "Available Assignees:"
                    // font.bold: true
                }

                Rectangle {
                    width: parent.width
                    height: parent.height - units.gu(15)
                    border.color: "#CCCCCC"
                    border.width: 1
                    color: "transparent"

                    Flickable {
                        id: assigneeFlickable
                        anchors.fill: parent
                        anchors.margins: units.gu(1)
                        contentHeight: assigneeColumn.height
                        clip: true

                        Column {
                            id: assigneeColumn
                            width: parent.width
                            spacing: units.gu(0.5)

                            Repeater {
                                model: availableAssignees.length

                                delegate: Item {
                                    width: assigneeColumn.width
                                    height: units.gu(5)

                                    property var assignee: availableAssignees[index]
                                    property bool isSelected: {
                                        for (let i = 0; i < selectedAssignees.length; i++) {
                                            if (selectedAssignees[i].id === assignee.id) {
                                                return true;
                                            }
                                        }
                                        return false;
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        color: isSelected ? "#E0E0E0" : "transparent"  // Light grey
                                        border.color: "#999999"  // Grey
                                        border.width: 1
                                        radius: units.gu(0.5)

                                        Row {
                                            anchors.left: parent.left
                                            anchors.leftMargin: units.gu(1)
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: units.gu(1)

                                            Rectangle {
                                                id: checkbox
                                                width: units.gu(3)
                                                height: units.gu(3)
                                                color: isSelected ? "#3498db" : "transparent"
                                                border.color: "#666666"
                                                border.width: 1
                                                radius: units.gu(0.3)
                                                anchors.verticalCenter: parent.verticalCenter

                                                Text {
                                                    text: "✓"
                                                    color: "white"
                                                    font.bold: true
                                                    anchors.centerIn: parent
                                                    visible: isSelected
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: {
                                                        if (isSelected) {
                                                            // Find and remove
                                                            for (let i = 0; i < selectedAssignees.length; i++) {
                                                                if (selectedAssignees[i].id === assignee.id) {
                                                                    removeAssignee(i);
                                                                    break;
                                                                }
                                                            }
                                                        } else {
                                                            addAssignee(assignee);
                                                        }
                                                    }
                                                }
                                            }

                                            TSLabel {
                                                text: assignee.name
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: units.gu(1)

                    Item {
                        width: parent.width - clearButton.width - doneButton.width - units.gu(1)
                        height: units.gu(1)
                    }

                    TSButton {
                        id: clearButton
                        text: "Clear All"
                        onClicked: {
                            selectedAssignees = [];
                            updateDisplayText();
                            assigneesChanged(selectedAssignees);
                        }
                    }

                    TSButton {
                        id: doneButton
                        text: "Done"
                        onClicked: {
                            assigneeDialog.visible = false;
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        updateDisplayText();
    }
}
