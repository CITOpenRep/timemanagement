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

import QtQuick 2.12
import QtQuick.Controls 2.2
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import "../../models/task.js" as Task
import "../../models/accounts.js" as Account

/**
 * PersonalStageSelector - A popup dialog for selecting and changing personal task stages
 *
 * Personal stages are user-specific and independent from project stages.
 * They are identified by is_global = '[]' in the database.
 *
 * Usage:
 *   Component {
 *       id: personalStageSelector
 *       PersonalStageSelector {
 *           onPersonalStageSelected: {
 *               // Handle personal stage change
 *               console.log("Selected personal stage:", personalStageOdooRecordId, personalStageName)
 *           }
 *       }
 *   }
 *
 *   // Open the dialog with parameters
 *   PopupUtils.open(personalStageSelector, parentPage, {
 *       taskId: taskLocalId,
 *       accountId: accountId,
 *       userId: currentUserOdooId,
 *       currentPersonalStageOdooRecordId: currentPersonalStageId
 *   })
 */
Dialog {
    id: personalStageSelectorDialog
    title: i18n.dtr("ubtms", "Change Personal Stage")

    property int taskId: -1
    property int accountId: -1
    property int userId: -1
    property int currentPersonalStageOdooRecordId: -1
    property var availablePersonalStages: []

    signal personalStageSelected(int personalStageOdooRecordId, string personalStageName)

    /**
     * Loads available personal stages for this user and account
     */
    function loadPersonalStages() {
        // Load personal stages for this user
        availablePersonalStages = Task.getPersonalStagesForUser(userId, accountId);

        console.log("PersonalStageSelector: loaded", availablePersonalStages.length, "personal stages for userId:", userId);

        // Update the stage list model
        personalStageListModel.clear();

        // Add "Clear Personal Stage" option
        personalStageListModel.append({
            odoo_record_id: -1,
            name: "(Clear Personal Stage)",
            sequence: -1,
            fold: 0,
            isCurrent: currentPersonalStageOdooRecordId === null || currentPersonalStageOdooRecordId === undefined || currentPersonalStageOdooRecordId === -1
        });

        // Add available personal stages
        for (var i = 0; i < availablePersonalStages.length; i++) {
            personalStageListModel.append({
                odoo_record_id: availablePersonalStages[i].odoo_record_id,
                name: availablePersonalStages[i].name,
                sequence: availablePersonalStages[i].sequence,
                fold: availablePersonalStages[i].fold,
                isCurrent: availablePersonalStages[i].odoo_record_id === currentPersonalStageOdooRecordId
            });
        }
    }

    Component.onCompleted: {
        loadPersonalStages();
    }

    ListModel {
        id: personalStageListModel
    }

    Column {
        spacing: units.gu(2)
        width: parent.width

        // Current Personal Stage Label
        Label {
            id: currentPersonalStageLabel
            width: parent.width
            wrapMode: Text.WordWrap
            text: {
                if (currentPersonalStageOdooRecordId === null || currentPersonalStageOdooRecordId === undefined || currentPersonalStageOdooRecordId === -1) {
                    return "Current Personal Stage: <b>None</b>";
                }
                var currentStageName = Task.getTaskStageName(currentPersonalStageOdooRecordId);
                return "Current Personal Stage: <b>" + currentStageName + "</b>";
            }
            font.pixelSize: units.gu(2)
            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
        }

        Label {
            text: "Select Personal Stage:"
            font.pixelSize: units.gu(1.8)
            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#bbb" : "#555"
        }

        Label {
            text: "Personal stages are separate from project stages and help you track your own workflow."
            font.pixelSize: units.gu(1.4)
            font.italic: true
            wrapMode: Text.WordWrap
            width: parent.width
            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#999" : "#666"
        }

        // Personal Stage List
        Rectangle {
            width: parent.width
            height: Math.min(units.gu(40), personalStageListView.contentHeight + units.gu(2))
            border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#444" : "#dcdcdc"
            border.width: units.gu(0.1)
            radius: units.gu(0.5)
            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#222" : "#fafafa"

            ListView {
                id: personalStageListView
                anchors.fill: parent
                anchors.margins: units.gu(1)
                clip: true
                spacing: units.gu(1)

                model: personalStageListModel

                delegate: Rectangle {
                    width: personalStageListView.width
                    height: units.gu(6)
                    radius: units.gu(0.5)
                    border.color: model.isCurrent ? LomiriColors.blue : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#444" : "#ddd")
                    border.width: model.isCurrent ? units.gu(0.3) : units.gu(0.1)
                    color: personalStageMouseArea.pressed ? (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#333" : "#e8e8e8") : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#2a2a2a" : "#fff")

                    Row {
                        anchors.fill: parent
                        anchors.margins: units.gu(1)
                        spacing: units.gu(1)

                        // Current stage indicator
                        Rectangle {
                            width: units.gu(0.5)
                            height: parent.height
                            color: model.isCurrent ? LomiriColors.blue : "transparent"
                            radius: units.gu(0.25)
                        }

                        Column {
                            width: parent.width - units.gu(1.5)
                            spacing: units.gu(0.3)

                            Label {
                                text: model.name
                                font.pixelSize: units.gu(2)
                                font.bold: model.isCurrent
                                font.italic: model.odoo_record_id === -1
                                color: model.isCurrent ? LomiriColors.blue : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black")
                                wrapMode: Text.WordWrap
                                width: parent.width
                            }

                            Label {
                                text: model.fold === 1 ? "(Folded/Closed Stage)" : ""
                                font.pixelSize: units.gu(1.3)
                                font.italic: true
                                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#888" : "#777"
                                visible: model.fold === 1
                            }
                        }
                    }

                    MouseArea {
                        id: personalStageMouseArea
                        anchors.fill: parent
                        onClicked: {
                            // Don't allow selecting the current stage
                            if (!model.isCurrent) {
                                // If clearing personal stage (odoo_record_id === -1), pass null
                                var stageId = model.odoo_record_id === -1 ? null : model.odoo_record_id;
                                personalStageSelected(stageId, model.name);
                                PopupUtils.close(personalStageSelectorDialog);
                            }
                        }
                    }
                }

                // Empty state message
                Label {
                    anchors.centerIn: parent
                    visible: personalStageListModel.count <= 1  // Only "Clear" option
                    text: "No personal stages available.\nPersonal stages must be created in Odoo first."
                    font.pixelSize: units.gu(1.8)
                    color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#888" : "#666"
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            // Scrollbar indicator
            Rectangle {
                visible: personalStageListView.contentHeight > personalStageListView.height
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: units.gu(0.5)
                width: units.gu(0.5)
                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#444" : "#ddd"
                radius: units.gu(0.25)

                Rectangle {
                    width: parent.width
                    height: (personalStageListView.height / personalStageListView.contentHeight) * parent.height
                    y: (personalStageListView.contentY / personalStageListView.contentHeight) * parent.height
                    color: LomiriColors.blue
                    radius: parent.radius
                }
            }
        }
    }

    Button {
        text: "Cancel"
        onClicked: PopupUtils.close(personalStageSelectorDialog)
    }
}
