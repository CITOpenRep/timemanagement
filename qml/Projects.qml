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
import "../models/activity.js" as Activity
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
        project = Project.getProjectDetails(projectId);
        if (project && Object.keys(project).length > 0) {
            // Set all fields with project details
            // console.log("ACCOUNT id is ")
            // console.log( project.account_id)
            let instanceId = (project.account_id !== undefined && project.account_id !== null) ? project.account_id : -1;
            let parentId = (project.parent_id !== undefined && project.parent_id !== null) ? project.parent_id : -1;

            // Set parent project selection
            if (workItem.deferredLoadExistingRecordSet) {
                workItem.deferredLoadExistingRecordSet(instanceId, parentId, -1, -1, -1, -1);
            } else if (workItem.applyDeferredSelection) {
                workItem.applyDeferredSelection(instanceId, parentId, -1);
            }

            project_name.text = project.name || "";
            description_text.setContent(project.description || "");

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

    CreateUpdateDialog {
        id: updates_dialog
        width: units.gu(80)
        height: units.gu(80)
        onUpdateCreated: {
            let result = Project.createUpdateSnapShot(updateData);
            if (result['is_success'] === false) {
                notifPopup.open("Failed", result['message'], "error");
            } else {
                notifPopup.open("Saved", "Project updated has been saved", "success");
            }
        }
    }

    Flickable {
        id: projectDetailsPageFlickable
        anchors.topMargin: units.gu(6)
        anchors.fill: parent
        contentHeight: descriptionExpanded ? parent.height + units.gu(120) : parent.height + units.gu(120)
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
                            //set the data to a global Store and pass the key to the page
                            Global.description_temporary_holder = getFormattedText();
                            Global.description_context = "project_description";
                            apLayout.addPageToNextColumn(projectCreate, Qt.resolvedUrl("ReadMorePage.qml"), {
                                isReadOnly: isReadOnly
                            });
                        }
                    }
                }
            }
        }
        Grid {
            id: myRow82
            anchors.top: myRow9.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: units.gu(1)
            anchors.rightMargin: units.gu(1)
            columns: 3
            spacing: units.gu(1)

            // First Row - Activities
            TSLabel {
                visible: isReadOnly
                text: "Activities"
                width: (parent.width - units.gu(2)) / 3
                height: units.gu(6)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                fontBold: true
                color: LomiriColors.orange
            }

            TSButton {
                visible: isReadOnly
                bgColor: "#fef1e7"
                fgColor: "#f97316"
                hoverColor: '#f3e0d1'
              iconName: "add"
                fontBold: true
                width: (parent.width - units.gu(2)) / 3
                text: "Create"
                onClicked: {
                    let project = Project.getProjectDetails(recordid);
                    let result = Activity.createActivityFromProjectOrTask(true, project.account_id, project.odoo_record_id);
                    if (result.success) {
                        apLayout.addPageToNextColumn(projectCreate, Qt.resolvedUrl("Activities.qml"), {
                            "recordid": result.record_id,
                            "accountid": project.account_id,
                            "isReadOnly": false
                        });
                    } else {
                        notifPopup.open("Failed", "Unable to create activity", "error");
                    }
                }
            }

            TSButton {
                visible: isReadOnly && recordid > 0
                bgColor: "#f3f4f6"
                fgColor: "#1f2937"
                hoverColor: '#d1d5db'
                borderColor: "#d1d5db"
                fontBold: true
                iconName: "view-on"
                width: (parent.width - units.gu(2)) / 3
                text: "View"
                onClicked: {
                    let project = Project.getProjectDetails(recordid);
                    apLayout.addPageToNextColumn(projectCreate, Qt.resolvedUrl("Activity_Page.qml"), {
                        "filterByProject": true,
                        "projectOdooRecordId": project.odoo_record_id,
                        "projectAccountId": project.account_id,
                        "projectName": project.name
                    });
                }
            }

            // Second Row - Tasks
            TSLabel {
                visible: isReadOnly
                text: "Tasks"
                width: (parent.width - units.gu(2)) / 3
                height: units.gu(6)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                fontBold: true
                color: LomiriColors.orange
            }

            TSButton {
                visible: isReadOnly
                bgColor: "#fef1e7"
                fgColor: "#f97316"
                hoverColor: '#f3e0d1'
                fontBold: true
                width: (parent.width - units.gu(2)) / 3
                text: "Create"
                onClicked: {
                    let project = Project.getProjectDetails(recordid);
                    // Determine if this is a subproject and get parent project info
                    let isSubProject = project.parent_id && project.parent_id > 0;
                    let parentProjectId = isSubProject ? project.parent_id : -1;

                    apLayout.addPageToNextColumn(projectCreate, Qt.resolvedUrl("Tasks.qml"), {
                        "recordid": 0  // 0 means creation mode
                        ,
                        "isReadOnly": false,
                        "prefilledAccountId": project.account_id,
                        "prefilledProjectId": isSubProject ? -1 : project.odoo_record_id  // Main project if not subproject
                        ,
                        "prefilledSubProjectId": isSubProject ? project.odoo_record_id : -1  // Subproject if it is one
                        ,
                        "prefilledParentProjectId": parentProjectId,
                        "prefilledProjectName": project.name
                    });
                }
            }

            TSButton {
                visible: isReadOnly && recordid > 0
                bgColor: "#f3f4f6"
                fgColor: "#1f2937"
                hoverColor: '#d1d5db'
                borderColor: "#d1d5db"
                fontBold: true
                width: (parent.width - units.gu(2)) / 3
                text: "View"
                onClicked: {
                    let project = Project.getProjectDetails(recordid);
                    apLayout.addPageToNextColumn(projectCreate, Qt.resolvedUrl("Task_Page.qml"), {
                        "filterByProject": true,
                        "projectOdooRecordId": project.odoo_record_id,
                        "projectAccountId": project.account_id,
                        "projectName": project.name
                    });
                }
            }

            // Third Row - Project Updates
            TSLabel {
                visible: isReadOnly
                text: "Project Updates"
                width: (parent.width - units.gu(2)) / 3
                height: units.gu(6)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                fontBold: true
                color: LomiriColors.orange
            }

            TSButton {
                visible: isReadOnly
                bgColor: "#fef1e7"
                fgColor: "#f97316"
                hoverColor: '#f3e0d1'
                fontBold: true
                width: (parent.width - units.gu(2)) / 3
                text: "Create"
                onClicked: {
                    let project = Project.getProjectDetails(recordid);
                    updates_dialog.open(project.account_id, project.odoo_record_id);
                }
            }

            TSButton {
                visible: isReadOnly && recordid > 0
               bgColor: "#f3f4f6"
                fgColor: "#1f2937"
                hoverColor: '#d1d5db'
                borderColor: "#d1d5db"
                fontBold: true
                width: (parent.width - units.gu(2)) / 3
                text: "View"
                onClicked: {
                    let project = Project.getProjectDetails(recordid);
                    apLayout.addPageToNextColumn(projectCreate, Qt.resolvedUrl("Updates_Page.qml"), {
                        "filterByProject": true,
                        "projectOdooRecordId": project.odoo_record_id,
                        "projectAccountId": project.account_id,
                        "projectName": project.name
                    });
                }
            }
        }

        Row {
            id: myRow4
            anchors.top: myRow82.bottom
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

        Rectangle {
            //color:"yellow"
            id: attachmentRow
            anchors.top: myRow6.bottom
            //anchors.top: attachmentuploadRow.bottom
            height: units.gu(50)
            width: parent.width
            anchors.margins: units.gu(0.1)
            AttachmentViewer {
                id: attachments_widget
                visible: (Accounts.getAccountName(project.account_id) === "LOCAL ACCOUNT") ? false : true // We should not show the attachment feature for local account : TODO
                anchors.fill: parent
                onRefresh: {
                    if (recordid !== 0) {
                        if (!loadProjectData(recordid)) {
                            notifPopup.open("Failed", "Error during attachment refresh", "error");
                        }
                    }
                }
            }
        }

        Rectangle {
            //color:"red"
            id: attachmentuploadRow
            anchors.top: attachmentRow.bottom
            anchors.bottom: parent.bottom
            width: parent.width
            //height: units.gu(30)
            anchors.margins: units.gu(0.1)
            AttachmentUploader {
                id: attachmentsupload_widget
                visible: (Accounts.getAccountName(project.account_id) === "LOCAL ACCOUNT") ? false : true // We should not show the attachment feature for local account : TODO
                anchors.fill: parent
                resource_id: project.odoo_record_id
                account_id: project.account_id
                onProcessed: {
                    console.log("Uploaded the attchment lets do a refresh");
                    if (recordid !== 0) {
                        if (!loadProjectData(recordid)) {
                            notifPopup.open("Failed", "Error during attachment refresh", "error");
                        }
                    }
                }
            }
        }
    }

    ColorPicker {
        id: colorpicker
        width: units.gu(80)
        height: units.gu(80)
        onColorPicked: function (index, value) {
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
            // For new projects, force local account (id = 0) to respect restrictAccountToLocalOnly
            if (workItem.deferredLoadExistingRecordSet) {
                workItem.deferredLoadExistingRecordSet(0, -1, -1, -1, -1, -1); // Use local account (id = 0)
            } else if (workItem.applyDeferredSelection) {
                workItem.applyDeferredSelection(0, -1, -1); // Use local account (id = 0)
            }
        }
    }
    onVisibleChanged: {
        if (visible) {
            if (Global.description_temporary_holder !== "" && Global.description_context === "project_description") {
                //Check if you are coming back from the ReadMore page for project description
                description_text.setContent(Global.description_temporary_holder);
                Global.description_temporary_holder = "";
                Global.description_context = "";
            }
        }
        // Don't clear context when page becomes invisible as it might be needed
        // for the ReadMore page editing flow
    }
}
