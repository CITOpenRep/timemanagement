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
import "../../models/project.js" as Project

/**
 * ProjectStageSelector - A popup dialog for selecting and changing project stages
 *
 * Usage:
 *   Component {
 *       id: stageSelector
 *       ProjectStageSelector {
 *           onStageSelected: {
 *               // Handle stage change
 *               console.log("Selected stage:", stageOdooRecordId, stageName)
 *           }
 *       }
 *   }
 *
 *   // Open the dialog with parameters
 *   PopupUtils.open(stageSelector, parentPage, {
 *       projectId: projectLocalId,
 *       accountId: accountId,
 *       currentStageOdooRecordId: currentStageId
 *   })
 */
Dialog {
    id: stageSelectorDialog
    title: i18n.dtr("ubtms", "Change Project Stage")

    property int projectId: -1
    property int accountId: -1
    property int currentStageOdooRecordId: -1
    property var availableStages: []

    signal stageSelected(int stageOdooRecordId, string stageName)

    /**
     * Loads available stages for projects filtered by account ID
     */
    function loadStages() {
        // Load available project stages for this specific account
        if (accountId > 0) {
            availableStages = Project.getProjectStagesForAccount(accountId);
        } else {
            // Fallback to all stages if no account specified
            availableStages = Project.getAllProjectStages();
        }

        // Update the stage list model
        stageListModel.clear();
        for (var i = 0; i < availableStages.length; i++) {
            stageListModel.append({
                odoo_record_id: availableStages[i].odoo_record_id,
                name: availableStages[i].name,
                sequence: availableStages[i].sequence,
                fold: availableStages[i].fold,
                isCurrent: availableStages[i].odoo_record_id === currentStageOdooRecordId
            });
        }
    }

    Component.onCompleted: {
        loadStages();
    }

    ListModel {
        id: stageListModel
    }

    Column {
        spacing: units.gu(2)
        width: parent.width

        // Current Stage Label
        Label {
            id: currentStageLabel
            width: parent.width
            wrapMode: Text.WordWrap
            text: {
                var currentStageName = Project.getProjectStageName(currentStageOdooRecordId);
                return i18n.dtr("ubtms", "Current Stage: ") + "<b>" + (currentStageName || i18n.dtr("ubtms", "Not set")) + "</b>";
            }
            font.pixelSize: units.gu(2)
            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
        }

        Label {
            text: i18n.dtr("ubtms", "Select New Stage:")
            font.pixelSize: units.gu(1.8)
            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#bbb" : "#555"
        }

        // Stage List
        Rectangle {
            width: parent.width
            height: Math.min(units.gu(40), stageListView.contentHeight + units.gu(2))
            border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#444" : "#dcdcdc"
            border.width: units.gu(0.1)
            radius: units.gu(0.5)
            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#222" : "#fafafa"

            ListView {
                id: stageListView
                anchors.fill: parent
                anchors.margins: units.gu(1)
                clip: true
                spacing: units.gu(1)

                model: stageListModel

                delegate: Rectangle {
                    width: stageListView.width
                    height: units.gu(6)
                    radius: units.gu(0.5)
                    border.color: model.isCurrent ? LomiriColors.orange : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#444" : "#ddd")
                    border.width: model.isCurrent ? units.gu(0.3) : units.gu(0.1)
                    color: stageMouseArea.pressed ? (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#333" : "#e8e8e8") : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#2a2a2a" : "#fff")

                    Row {
                        anchors.fill: parent
                        anchors.margins: units.gu(1)
                        spacing: units.gu(1)

                        // Current stage indicator
                        Rectangle {
                            width: units.gu(0.5)
                            height: parent.height
                            color: model.isCurrent ? LomiriColors.orange : "transparent"
                            radius: units.gu(0.25)
                        }

                        Column {
                            width: parent.width - units.gu(1.5)
                            spacing: units.gu(0.3)

                            Label {
                                text: model.name
                                font.pixelSize: units.gu(2)
                                font.bold: model.isCurrent
                                color: model.isCurrent ? LomiriColors.orange : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black")
                                wrapMode: Text.WordWrap
                                width: parent.width
                            }

                            Label {
                                text: model.fold === 1 ? i18n.dtr("ubtms", "(Folded/Closed Stage)") : ""
                                font.pixelSize: units.gu(1.3)
                                font.italic: true
                                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#888" : "#777"
                                visible: model.fold === 1
                            }
                        }
                    }

                    MouseArea {
                        id: stageMouseArea
                        anchors.fill: parent
                        onClicked: {
                            // Don't allow selecting the current stage
                            if (!model.isCurrent) {
                                stageSelected(model.odoo_record_id, model.name);
                                PopupUtils.close(stageSelectorDialog);
                            }
                        }
                    }
                }

                // Empty state message
                Label {
                    anchors.centerIn: parent
                    visible: stageListModel.count === 0
                    text: i18n.dtr("ubtms", "No stages available")
                    font.pixelSize: units.gu(1.8)
                    color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#888" : "#666"
                }
            }

            // Scrollbar indicator
            Rectangle {
                visible: stageListView.contentHeight > stageListView.height
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: units.gu(0.5)
                width: units.gu(0.5)
                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#444" : "#ddd"
                radius: units.gu(0.25)

                Rectangle {
                    width: parent.width
                    height: (stageListView.height / stageListView.contentHeight) * parent.height
                    y: (stageListView.contentY / stageListView.contentHeight) * parent.height
                    color: LomiriColors.orange
                    radius: parent.radius
                }
            }
        }
    }

    Button {
        text: i18n.dtr("ubtms", "Cancel")
        onClicked: PopupUtils.close(stageSelectorDialog)
    }
}
