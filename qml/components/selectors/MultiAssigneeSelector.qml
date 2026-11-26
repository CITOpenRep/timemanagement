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
import QtQuick.Layouts 1.3
import Lomiri.Components 1.3
import "../../../models/accounts.js" as Accounts
import ".."

Item {
    id: multiAssigneeSelector
    width: parent ? parent.width : 0
    height: mainColumn.implicitHeight + (2 * units.gu(1))
    implicitHeight: height

    property bool readOnly: false
    property string labelText: i18n.dtr("ubtms", "Assignees")
    property int accountId: -1
    property bool enabledState: true
    property var optionPickerOverride: null
    property var selectedAssignees: [] // Array of {id, name} objects
    readonly property var selectedAssigneeIdList: {
        var ids = [];
        for (var i = 0; i < selectedAssignees.length; i++) {
            ids.push(selectedAssignees[i].id);
        }
        return ids;
    }

    signal assigneesChanged(var assignees)
    signal openingPicker()

    // Public API
    function setSelectedAssignees(assignees) {
        selectedAssignees = assignees || [];
        // updateDisplayText();
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

    function setEnabled(isEnabled) {
        // Only enable if not in read-only mode
        if (readOnly) {
            enabledState = false;
            console.log("[MultiAssigneeSelector] Ignoring setEnabled(" + isEnabled + ") because readOnly is true");
        } else {
            enabledState = isEnabled;
        }
    }

    function loadAssignees(accountId) {
        multiAssigneeSelector.accountId = accountId;
        availableAssignees = Accounts.getUsers(accountId);

        // Filter out "Select Assignee" entry and add proper structure
        var filteredAssignees = [];
        for (let i = 0; i < availableAssignees.length; i++) {
            let assignee = availableAssignees[i];
            let id = (accountId === 0) ? assignee.id : assignee.odoo_record_id;
            if (id > 0 && assignee.name && String(assignee.name).trim() !== "") {
                filteredAssignees.push({
                    id: id,
                    name: String(assignee.name).trim()
                });
            }
        }
        availableAssignees = filteredAssignees;
    }

    property var availableAssignees: []

    Column {
        id: mainColumn
        anchors.fill: parent
        anchors.margins: units.gu(1)
        spacing: units.gu(1)

        Row {
            width: parent.width
            spacing: units.gu(2)

            // TSLabel {
            //     text: labelText
            //     width: parent.width * 0.3
            //     anchors.verticalCenter: parent.verticalCenter
            // }

            TSButton {
                id: displayButton
                text: i18n.dtr("ubtms", "Select Assignees")
                enabled: enabledState && !readOnly && availableAssignees.length > 0
                width: parent.width * 0.3
                height: units.gu(5)
                anchors.verticalCenter: parent.verticalCenter

                onClicked: {
                    if (!readOnly && enabledState) {
                        openingPicker();
                        var picker = _getPicker();
                        if (picker) {
                            picker.open({
                                titleText: i18n.dtr("ubtms", "Select Assignees"),
                                modelData: multiAssigneeSelector.availableAssignees,
                                multiSelect: true,
                                selectedIds: multiAssigneeSelector.selectedAssigneeIdList,
                                searchThreshold: 5,
                                onMultiToggled: function (id, name, shouldSelect) {
                                    if (shouldSelect) {
                                        addAssignee({
                                            id: id,
                                            name: name
                                        });
                                    } else {
                                        for (var i = 0; i < selectedAssignees.length; i++) {
                                            if (selectedAssignees[i].id === id) {
                                                removeAssignee(i);
                                                break;
                                            }
                                        }
                                    }
                                },
                                onMultiCleared: function () {
                                    if (!readOnly) {
                                        selectedAssignees = [];
                                        assigneesChanged(selectedAssignees);
                                    }
                                }
                            });
                        }
                    }
                }
            }

            // Grid layout for selected assignees
            Grid {
                id: assigneeGrid
                width: parent.width - displayButton.width - parent.spacing
                columns: Math.floor(parent.width / units.gu(20)) // Adjust column width as needed
                spacing: units.gu(0.5)
                visible: selectedAssignees.length > 0

                Repeater {
                    model: selectedAssignees.length

                    Item {
                        width: units.gu(12) // Fixed width for grid items
                        height: assigneeChip.height

                        Rectangle {
                            id: assigneeChip
                            width: parent.width
                            height: units.gu(2.7) // Slightly taller for better appearance
                            radius: units.gu(1.5)
                            color: "#3498db"  // Blue color
                            border.color: "#666666"  // Dark grey
                            border.width: 1

                            Item {
                                anchors.fill: parent
                                anchors.margins: units.gu(0.5)

                                TSLabel {
                                    id: assigneeLabel
                                    text: selectedAssignees[index].name

                                    color: "white"
                                    fontSize: units.gu(1.5)
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.right: removeButton.left
                                    anchors.rightMargin: units.gu(0.5)
                                    elide: Text.ElideRight // Truncate text if too long
                                    wrapMode: Text.NoWrap
                                }

                                TSButton {
                                    id: removeButton
                                    text: "×"
                                    enabled: !readOnly && enabledState
                                    width: units.gu(2)
                                    height: units.gu(2)
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.right: parent.right
                                    anchors.rightMargin: units.gu(0.5)

                                    onClicked: {
                                        if (!readOnly && enabledState) {
                                            removeAssignee(index);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Display selected assignees as chips/tags

    }

    function removeAssignee(index) {
        if (readOnly) {
            console.log("[MultiAssigneeSelector] removeAssignee called but readOnly is true, ignoring");
            return;
        }
        if (index >= 0 && index < selectedAssignees.length) {
            var next = selectedAssignees.slice();
            next.splice(index, 1);
            selectedAssignees = next;
            assigneesChanged(selectedAssignees);
        }
    }

    function addAssignee(assignee) {
        if (readOnly) {
            console.log("[MultiAssigneeSelector] addAssignee called but readOnly is true, ignoring");
            return;
        }
        // Check if already selected
        for (let i = 0; i < selectedAssignees.length; i++) {
            if (selectedAssignees[i].id === assignee.id) {
                return; // Already selected
            }
        }
        var next = selectedAssignees.slice();
        next.push(assignee);
        selectedAssignees = next;
        assigneesChanged(selectedAssignees);
    }

    function _getPicker() {
        if (optionPickerOverride) {
            return optionPickerOverride;
        }
        if (typeof mainView !== "undefined" && mainView && mainView.optionPicker) {
            return mainView.optionPicker;
        }
        return null;
    }

    Component.onCompleted:
    {}
}
