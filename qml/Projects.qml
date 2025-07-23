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

                    // Validate hours format before saving
                    if (!hours_text.isValid) {
                        notifPopup.open("Error", "Please enter allocated hours in HH:MM format (e.g., 1000:30 for large projects)", "error");
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

                    // Use the current recordid (0 for new projects, existing ID for updates)
                    var response = Project.createUpdateProject(project_data, recordid);
                    if (response) {
                        if (response.is_success) {
                            notifPopup.open("Saved", response.message, "success");

                            // Update recordid if it was a new project creation
                            if (recordid === 0 && response.record_id) {
                                recordid = response.record_id;
                            }

                            // Reload the project data to reflect the saved state
                            if (recordid !== 0) {
                                loadProjectData(recordid);
                            }
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

    // Helper function to load project data
    function loadProjectData(projectId) {
        let project = Project.getProjectDetails(projectId);
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

            // Handle color inheritance for subprojects
            let projectColor = project.color_pallet || 0;

            // If this is a subproject (has parentId) and doesn't have its own color, inherit from parent
            if (parentId !== -1 && (!project.color_pallet || parseInt(project.color_pallet) === 0)) {
                let parentProject = Project.getProjectDetails(parentId);
                if (parentProject && parentProject.color_pallet) {
                    projectColor = parentProject.color_pallet;
                }
            }

            project_color = projectColor;
            project_color_label.color = colorpicker.getColorByIndex(projectColor);
            date_range_widget.setDateRange(project.planned_start_date || "", project.planned_end_date || "");
            hours_text.text = project.allocated_hours !== undefined && project.allocated_hours !== null ? String(project.allocated_hours) : "01:00";
            attachments_widget.setAttachments(Project.getAttachmentsForProject(project.odoo_record_id));
            return true;
        }
        return false;
    }

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
                    restrictAccountToLocalOnly: recordid === 0  // Only restrict to local when creating new projects
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
            anchors.top: (recordid > 0) ? myRow1.bottom : myRow1.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            topPadding: units.gu(5)

            Column {
                id: myCol9

                Item {
                    id: textAreaContainer
                    width: projectDetailsPageFlickable.width
                    height: description_text.height

                    RichTextPreview {
                        id: description_text
                        width: parent.width
                        height: units.gu(20) // Start with collapsed height
                        anchors.centerIn: parent.centerIn
                        text: ""
                       is_read_only: isReadOnly
                        onClicked: {
                            //set the data to a global Slore and pass the key to the page
                            Global.description_temporary_holder=text
                            apLayout.addPageToNextColumn(projectCreate,Qt.resolvedUrl("ReadMorePage.qml"), {
                                                             isReadOnly:isReadOnly
                                                         });
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
                text: "01:00"
                placeholderText: "HH:MM (e.g., 1000:30 for large projects)"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                // Custom validation for HH:MM format (allowing 1000+ hours for project allocation)
                property bool isValid: {
                    if (!/^[0-9]{1,4}:[0-5][0-9]$/.test(text))
                        return false;
                    var parts = text.split(":");
                    var hours = parseInt(parts[0]);
                    var minutes = parseInt(parts[1]);
                    return hours >= 0 && hours <= 9999 && minutes <= 59;
                }

                // Visual feedback for invalid input
                color: isValid ? (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black") : "red"

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
                radius: units.gu(0.5)
                border.width: parent.activeFocus ? units.gu(0.2) : units.gu(0.1)
                border.color: parent.activeFocus ? LomiriColors.orange : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#d3d1d1" : "#999")
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
            if (!loadProjectData(recordid)) {
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
    onVisibleChanged: {
        if (visible) {
            if (Global.description_temporary_holder !== "") { //Check if you are coming back from the ReadMore page
                description_text.text=Global.description_temporary_holder
                Global.description_temporary_holder=""
            }
        }else
        {
            Global.description_temporary_holder=""
        }
    }
}
