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
import QtQuick.Window 2.2
import Qt.labs.settings 1.0
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.Components.Pickers 1.3
import QtCharts 2.0
import "../models/task.js" as Task
import "../models/utils.js" as Utils
import "../models/accounts.js" as Accounts
import "../models/project.js" as Project
import "../models/global.js" as Global
import "components"

Page {
    id: projectCreate
    title: "Project"
    header: PageHeader {
        id: header
        title: projectCreate.title
        StyleHints {
            foregroundColor: "white"
            backgroundColor: LomiriColors.orange
            dividerColor: LomiriColors.slate
        }
        trailingActionBar.actions: [
            Action {
                iconSource: "images/save.svg" // New Save Icon
                text: "Save"
                visible: !isReadOnly
                onTriggered: {
                    const ids = workItem.getIds();
                    console.log("getAllSelectedDbRecordIds returned:");
                    console.log("   accountDbId: " + ids.account_id);
                    console.log("   projectDbId: " + ids.project_id);
                    console.log("   subProjectDbId: " + ids.subproject_id);
                    console.log("   taskDbId: " + ids.task_id);
                    console.log("   subTaskDbId: " + ids.subtask_id);
                    if (!ids.assignee_id) {
                        notifPopup.open("Error", "Please select the assignee", "error");
                        return;
                    }

                    // isReadOnly = !isReadOnly
                    var project_data = {
                        'account_id': ids.account_id >= 0 ? ids.account_id : 0,
                        'name': project_name.text,
                        'planned_start_date': date_range_widget.formattedStartDate(),
                        'planned_end_date': date_range_widget.formattedEndDate(),
                        'parent_id': ids.project_id,
                        'allocated_hours': hours_text.text,
                        'description': description_text.text,
                        'favorites': 0,
                        'color': project_color,
                        'status': "updated"
                    };
                    //  console.log(JSON.stringify(project_data, null, 4));
                    var recordid = 0; //project creation
                    var response = Project.createUpdateProject(project_data, recordid);
                    if (response) {
                        if (response.is_success) {
                            notifPopup.open("Saved", response.message, "success");
                        } else {
                            notifPopup.open("Failed", response.message, "error");
                        }
                    } else {
                        notifPopup.open("Failed", "Unable to save project", "error");
                    }
                }
            }
        ]
    }

    property bool isReadOnly: false
    property var recordid: 0
    property int project_color: 0
    property var project: {}
    property bool descriptionExpanded: false
    property real expandedHeight: units.gu(60)

    NotificationPopup {
        id: notifPopup
        width: units.gu(80)
        height: units.gu(80)
    }

    Flickable {
        id: projectDetailsPageFlickable
        anchors.topMargin: units.gu(6)
        anchors.fill: parent
        contentHeight: descriptionExpanded ? parent.height + 1500 : parent.height + 500
        flickableDirection: Flickable.VerticalFlick

        width: parent.width

        Row {
            id: myRow1a
            anchors.left: parent.left
            topPadding: units.gu(5)

            Column {
                leftPadding: units.gu(1)

                WorkItemSelector {
                    id: workItem
                    readOnly: isReadOnly
                    projectLabelText: "Parent Project"
                    showTaskSelector: false
                    showSubProjectSelector: false
                    showAssigneeSelector: true
                    showSubTaskSelector: false
                    width: projectDetailsPageFlickable.width - units.gu(2)
                    height: units.gu(10)
                }
            }
        }

        Row {
            id: myRow1
            anchors.top: myRow1a.bottom
            anchors.left: parent.left
            topPadding: units.gu(12)
            Column {
                id: myCol88
                leftPadding: units.gu(1)
                LomiriShape {
                    width: units.gu(10)
                    height: units.gu(5)
                    aspect: LomiriShape.Flat
                    Label {
                        id: project_label
                        text: "Project Name"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
            Column {
                id: myCol99
                leftPadding: units.gu(3)
                TextField {
                    id: project_name
                    readOnly: isReadOnly
                    width: projectDetailsPageFlickable.width < units.gu(361) ? projectDetailsPageFlickable.width - units.gu(15) : projectDetailsPageFlickable.width - units.gu(10)
                    anchors.centerIn: parent.centerIn
                    text: ""

                    Rectangle {
                        // visible: !isReadOnly
                        anchors.fill: parent
                        color: "transparent"
                        radius: units.gu(0.5)
                        border.width: parent.activeFocus ? units.gu(0.2) : units.gu(0.1)
                        border.color: parent.activeFocus ? LomiriColors.orange : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#d3d1d1" : "#999")
                        // z: -1
                    }
                }
            }
        }

        Row {
            id: myRow9
            anchors.top: myRow1.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            topPadding: units.gu(1)

            Column {
                id: myCol8
                leftPadding: units.gu(1)
                LomiriShape {
                    width: units.gu(10)
                    height: units.gu(5)
                    aspect: LomiriShape.Flat
                    Label {
                        id: description_label
                        text: "Description"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Column {
                id: myCol9
                leftPadding: units.gu(3)

                Item {
                    id: textAreaContainer
                    width: projectDetailsPageFlickable.width < units.gu(361) ? projectDetailsPageFlickable.width - units.gu(15) : projectDetailsPageFlickable.width - units.gu(10)
                    height: description_text.height

                    TextArea {
                        id: description_text
                        readOnly: isReadOnly
                        textFormat: Text.RichText
                        autoSize: false
                        maximumLineCount: 0
                        width: parent.width
                        height: units.gu(10) // Start with collapsed height
                        anchors.centerIn: parent.centerIn
                        text: ""
                        wrapMode: TextArea.Wrap
                        selectByMouse: true

                        onHeightChanged: {
                            console.log("Description TextArea height changed to:", height, "Expanded state:", projectCreate.descriptionExpanded);
                        }

                        Rectangle {
                            //  visible: !isReadOnly
                            anchors.fill: parent
                            color: "transparent"
                            radius: units.gu(0.5)
                            border.width: parent.activeFocus ? units.gu(0.2) : units.gu(0.1)
                            border.color: parent.activeFocus ? LomiriColors.orange : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#d3d1d1" : "#999")
                            // z: -1
                        }
                    }

                    // Floating Action Button
                    Item {
                        id: floatingActionButton
                        width: units.gu(3)
                        height: units.gu(3)
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.rightMargin: units.gu(1)
                        anchors.bottomMargin: units.gu(1)
                        z: 10
                        //  visible: !isReadOnly

                        // Circular background
                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: LomiriColors.orange

                            // Shadow effect
                            Rectangle {
                                anchors.fill: parent
                                anchors.topMargin: units.gu(0.15)
                                anchors.leftMargin: units.gu(0.15)
                                radius: parent.radius
                                color: "#30000000"
                                z: -1
                            }
                        }

                        Icon {
                            id: expandIcon
                            anchors.centerIn: parent
                            width: units.gu(1.5)
                            height: units.gu(1.5)
                            name: projectCreate.descriptionExpanded ? "up" : "down"
                            color: "white"
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                console.log("Floating button clicked! Current state:", projectCreate.descriptionExpanded);
                                projectCreate.descriptionExpanded = !projectCreate.descriptionExpanded;
                                console.log("New state:", projectCreate.descriptionExpanded);

                                // Force height update with smooth transition
                                if (projectCreate.descriptionExpanded) {
                                    description_text.height = projectCreate.expandedHeight;
                                } else {
                                    description_text.height = units.gu(10);
                                }
                            }

                            onPressed: {
                                parent.scale = 0.95;
                            }

                            onReleased: {
                                parent.scale = 1.0;
                            }
                        }
                    }
                }
            }
        }

        Row {
            id: myRow4
            anchors.top: myRow9.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: units.gu(1)
            anchors.rightMargin: units.gu(1)
            spacing: units.gu(2)
            topPadding: units.gu(1)

            TSLabel {
                id: hours_label
                text: "Allocated Hours"
                width: parent.width * 0.3
                anchors.verticalCenter: parent.verticalCenter
            }

            TextField {
                id: hours_text
                readOnly: isReadOnly
                width: parent.width * 0.3
                anchors.verticalCenter: parent.verticalCenter
                text: "1"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                validator: IntValidator {
                    bottom: 0
                }

                Rectangle {
                    //  visible: !isReadOnly
                    anchors.fill: parent
                    color: "transparent"
                    radius: units.gu(0.5)
                    border.width: parent.activeFocus ? units.gu(0.2) : units.gu(0.1)
                    border.color: parent.activeFocus ? LomiriColors.orange : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#d3d1d1" : "#999")
                    // z: -1
                }
            }
        }

        Row {
            id: colorRow
            anchors.top: myRow4.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: units.gu(1)
            anchors.rightMargin: units.gu(1)
            spacing: units.gu(2)
            topPadding: units.gu(1)

            TSLabel {
                id: color_Label
                text: "Color"
                width: parent.width * 0.3
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                id: project_color_label
                width: units.gu(4)
                height: units.gu(4)
                color: "red"
                enabled: !isReadOnly
                anchors.verticalCenter: parent.verticalCenter
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        colorpicker.open();
                    }
                }
            }
        }

        Row {
            id: myRow6
            anchors.top: colorRow.bottom
            anchors.left: parent.left
            topPadding: units.gu(1)
            height: units.gu(30)
            Column {
                leftPadding: units.gu(1)
                DateRangeSelector {
                    id: date_range_widget
                    readOnly: isReadOnly
                    width: projectDetailsPageFlickable.width < units.gu(361) ? projectDetailsPageFlickable.width - units.gu(35) : projectDetailsPageFlickable.width - units.gu(30)
                    height: units.gu(4)
                    anchors.centerIn: parent.centerIn
                }
            }
        }

        Item {
            id: attachmentRow
            anchors.bottom: parent.bottom
            anchors.top: myRow6.bottom
            width: parent.width
            //height: units.gu(30)
            anchors.margins: units.gu(1)
            AttachmentViewer {
                id: attachments_widget
                anchors.fill: parent
            }
        }
    }

    ColorPicker {
        id: colorpicker
        width: units.gu(80)
        height: units.gu(80)
        onColorPicked: function (index, value) {
            // console.log("Selected index:", index);
            // console.log("Selected color:", value);
            project_color_label.color = value;
            project_color = index;
        }
    }

    Component.onCompleted: {
        if (recordid !== 0) {
            let project = Project.getProjectDetails(recordid);
            if (project && Object.keys(project).length > 0) {
                // Set all fields with project details
                let instanceId = (project.account_id !== undefined && project.account_id !== null) ? project.account_id : -1;
                let parentId = (project.parent_id !== undefined && project.parent_id !== null) ? project.parent_id : -1;

                // Set parent project selection
                if (workItem.deferredLoadExistingRecordSet) {
                    workItem.deferredLoadExistingRecordSet(instanceId, parentId, -1, -1, -1, -1);
                } else if (workItem.applyDeferredSelection) {
                    workItem.applyDeferredSelection(instanceId, parentId, -1);
                }

                project_name.text = project.name || "";
                description_text.text = project.description || "";
                project_color = project.color_pallet || 0;
                project_color_label.color = colorpicker.getColorByIndex(project.color_pallet || 0);
                date_range_widget.setDateRange(project.planned_start_date || "", project.planned_end_date || "");
                hours_text.text = project.allocated_hours !== undefined && project.allocated_hours !== null ? String(project.allocated_hours) : "1";
                attachments_widget.setAttachments(Project.getAttachmentsForProject(project.odoo_record_id));
            } else {
                notifPopup.open("Failed", "Unable to open the project details", "error");
            }
        } else {
            //do nothing as we are creating project
            recordid = 0;
            if (workItem.deferredLoadExistingRecordSet) {
                workItem.deferredLoadExistingRecordSet(Accounts.getDefaultAccountId(), -1, -1, -1, -1, -1);
            } else if (workItem.applyDeferredSelection) {
                workItem.applyDeferredSelection(Accounts.getDefaultAccountId(), -1, -1);
            }
        }
    }
}
