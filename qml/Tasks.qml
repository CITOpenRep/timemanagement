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
import "../models/timesheet.js" as Timesheet
import "../models/utils.js" as Utils
import "../models/global.js" as Global
import "../models/accounts.js" as Accounts
import "../models/timer_service.js" as TimerService

import "components"

Page {
    id: taskCreate
    title: "Task"
    header: PageHeader {
        title: taskCreate.title
        StyleHints {
            foregroundColor: "white"
            backgroundColor: LomiriColors.orange
            dividerColor: LomiriColors.slate
        }

        trailingActionBar.actions: [
            Action {
                iconSource: "images/save.svg"
                visible: !isReadOnly
                text: "Save"
                onTriggered: {
                    save_task_data();
                }
            },
            Action {
                iconName: "edit"
                visible: isReadOnly && recordid !== 0
                text: "Edit"
                onTriggered: {
                    switchToEditMode();
                }
            }
        ]
    }
    property var recordid: 0 //0 means creation mode

    property string currentEditingField: ""
    property bool workpersonaSwitchState: true
    property bool isReadOnly: recordid != 0 // Set read-only immediately based on recordid
    property int selectedProjectId: 0
    property int selectedparentId: 0
    property int selectedTaskId: 0
    property int favorites: 0
    property int subProjectId: 0
    property var prevtask: ""
    property var textkey: ""
    property bool descriptionExpanded: false
    property real expandedHeight: units.gu(60)

    property var currentTask: {}

    function switchToEditMode() {
        // Simply change the current page to edit mode
        if (recordid !== 0) {
            isReadOnly = false;
        }
    }

    function save_task_data() {
        const ids = workItem.getIds();

        // Check for assignees - either single or multiple
        var hasAssignees = false;
        if (workItem.enableMultipleAssignees) {
            hasAssignees = ids.multiple_assignees && ids.multiple_assignees.length > 0;
        } else {
            hasAssignees = ids.assignee_id !== null;
        }

        if (!hasAssignees) {
            notifPopup.open("Error", "Please select at least one assignee", "error");
            return;
        }
        if (!ids.project_id) {
            notifPopup.open("Error", "Please select the project", "error");
            return;
        }
        if (name_text.text != "") {
            const saveData = {
                accountId: ids.account_id < 0 ? 0 : ids.account_id,
                name: name_text.text,
                record_id: recordid,
                projectId: ids.project_id,
                subProjectId: ids.subproject_id,
                parentId: ids.task_id,
                startDate: date_range_widget.formattedStartDate(),
                endDate: date_range_widget.formattedEndDate(),
                deadline: date_range_widget.formattedEndDate(),
                favorites: 0,
                plannedHours: Utils.convertDurationToFloat(hours_text.text),
                description: description_text.text,
                assigneeUserId: ids.assignee_id,
                status: "updated"
            };

            // Add multiple assignees if enabled
            if (workItem.enableMultipleAssignees && ids.multiple_assignees) {
                saveData.multipleAssignees = ids.multiple_assignees;
            }

            const result = Task.saveOrUpdateTask(saveData);
            if (!result.success) {
                notifPopup.open("Error", "Unable to Save the Task", "error");
            } else {
                notifPopup.open("Saved", "Task has been saved successfully", "success");
                // Reload the task data to reflect changes
                if (recordid !== 0) {
                    currentTask = Task.getTaskDetails(recordid);
                }
                // No navigation - stay on the same page like Timesheet.qml
                // User can use back button to return to list page
            }
        } else {
            notifPopup.open("Error", "Please add a Name to the task", "error");
        }

    //  isReadOnly = true; // Switch back to read-only mode after saving
    }

    function incdecHrs(value) {
        if (value === 1) {
            var hrs = Number(hours_text.text);
            hrs++;
            hours_text.text = hrs;
        } else {
            var hrs = Number(hours_text.text);
            if (hrs > 0)
                hrs--;
            hours_text.text = hrs;
        }
    }

    NotificationPopup {
        id: notifPopup
        width: units.gu(80)
        height: units.gu(80)
    }

    Flickable {
        id: tasksDetailsPageFlickable
        anchors.topMargin: units.gu(6)
        anchors.fill: parent
        contentHeight: descriptionExpanded ? parent.height + units.gu(140) : parent.height + units.gu(70)
        flickableDirection: Flickable.VerticalFlick

        width: parent.width

        Row {
            id: myRow1a
            anchors.left: parent.left
            topPadding: units.gu(5)
            z: 999
            Column {
                leftPadding: units.gu(1)

                WorkItemSelector {
                    id: workItem
                    readOnly: isReadOnly
                    taskLabelText: "Parent Task"
                    showAccountSelector: true
                    showAssigneeSelector: true
                    enableMultipleAssignees: true  // Enable multiple assignee selection
                    showProjectSelector: true
                    showSubProjectSelector: true
                    showTaskSelector: true
                    showSubTaskSelector: false
                    width: tasksDetailsPageFlickable.width - units.gu(2)
                    height: units.gu(10)
                }
            }
        }
        Row {
            id: myRow1b
            anchors.top: myRow1a.bottom
            anchors.left: parent.left
            topPadding: units.gu(40)
            Column {
                id: myCol88
                leftPadding: units.gu(1)
                LomiriShape {
                    width: units.gu(10)
                    height: units.gu(5)
                    aspect: LomiriShape.Flat
                    Label {
                        id: name_label
                        text: "Name"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
            Column {
                id: myCol99
                leftPadding: units.gu(3)
                TextField {
                    id: name_text
                    readOnly: isReadOnly
                    width: tasksDetailsPageFlickable.width < units.gu(361) ? tasksDetailsPageFlickable.width - units.gu(15) : tasksDetailsPageFlickable.width - units.gu(10)
                    anchors.centerIn: parent.centerIn
                    text: ""

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
        }
        Row {
            id: add_timesheet
            anchors.top: myRow1b.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: units.gu(1)
            visible: false
        }
        Row {
            id: myRow9
            anchors.top: (recordid > 0) ? add_timesheet.bottom : myRow1b.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            topPadding: units.gu(5)

            Column {
                id: myCol9

                Item {
                    id: textAreaContainer
                    width: tasksDetailsPageFlickable.width
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
                            Global.description_temporary_holder = text;
                            apLayout.addPageToNextColumn(taskCreate, Qt.resolvedUrl("ReadMorePage.qml"), {
                                isReadOnly: isReadOnly
                            });
                        }
                    }
                }
            }
        }

        Row {
            id: plannedh_row
            anchors.top: myRow9.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: units.gu(1)
            anchors.rightMargin: units.gu(1)
            spacing: units.gu(2)
            topPadding: units.gu(1)

            TSLabel {
                id: hours_label
                text: "Planned Hours"
                width: parent.width * 0.3
                anchors.verticalCenter: parent.verticalCenter
            }

            TSLabel {
                id: hours_text
                text: "01:00"
                enabled: !isReadOnly
                width: parent.width * 0.3
                fontBold: true
                anchors.verticalCenter: parent.verticalCenter
            }

            TSButton {
                text: "Select"
                objectName: "button_manual"
                enabled: !isReadOnly
                width: parent.width * 0.2
                height: units.gu(5)
                anchors.verticalCenter: parent.verticalCenter

                onClicked: {
                    myTimePicker.open(1, 0);
                }
            }
        }

        Row {
            id: myRow6
            anchors.top: plannedh_row.bottom
            anchors.left: parent.left
            topPadding: units.gu(1)
            height: units.gu(30)
            Column {
                leftPadding: units.gu(1)
                DateRangeSelector {
                    id: date_range_widget
                    readOnly: isReadOnly
                    width: tasksDetailsPageFlickable.width < units.gu(361) ? tasksDetailsPageFlickable.width - units.gu(35) : tasksDetailsPageFlickable.width - units.gu(30)
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
    TimePickerPopup {
        id: myTimePicker
        onTimeSelected: {
            let timeStr = (hour < 10 ? "0" + hour : hour) + ":" + (minute < 10 ? "0" + minute : minute);
            hours_text.text = timeStr;
        }
    }
    Component.onCompleted: {
        if (recordid != 0) // We are loading a task, depends on readonly value it could be for view/edit
        {
            currentTask = Task.getTaskDetails(recordid);

            let instanceId = (currentTask.account_id !== undefined && currentTask.account_id !== null) ? currentTask.account_id : -1;
            let project_id = (currentTask.project_id !== undefined && currentTask.project_id !== null && currentTask.project_id > 0) ? currentTask.project_id : -1;
            let sub_project_id = (currentTask.sub_project_id !== undefined && currentTask.sub_project_id !== null) ? currentTask.sub_project_id : -1;
            let parent_task_id = (currentTask.parent_id !== undefined && currentTask.parent_id !== null) ? currentTask.parent_id : -1;

            // Handle assignee_id - extract first ID if comma-separated (for single assignee mode)
            let assignee_id = -1;
            if (currentTask.user_id !== undefined && currentTask.user_id !== null && currentTask.user_id !== "") {
                let userIdStr = currentTask.user_id.toString();
                if (userIdStr.indexOf(',') >= 0) {
                    // Multiple assignees stored as comma-separated - take the first one for single assignee mode
                    let firstId = parseInt(userIdStr.split(',')[0].trim());
                    assignee_id = isNaN(firstId) ? -1 : firstId;
                } else {
                    // Single assignee
                    let singleId = parseInt(userIdStr);
                    assignee_id = isNaN(singleId) ? -1 : singleId;
                }
            }

            /*  console.log("Loading task data:", JSON.stringify({
                                                                 instanceId: instanceId,
                                                                 project_id: project_id,
                                                                 sub_project_id: sub_project_id,
                                                                 parent_task_id: parent_task_id,
                                                                 assignee_id: assignee_id
                                                             }));*/

            workItem.deferredLoadExistingRecordSet(instanceId, project_id, sub_project_id, parent_task_id, -1, assignee_id); //passing -1 as no subtask feature is needed

            name_text.text = currentTask.name || "";
            description_text.text = currentTask.description || "";

            // Handle planned hours more carefully
            if (currentTask.initial_planned_hours !== undefined && currentTask.initial_planned_hours !== null && currentTask.initial_planned_hours > 0) {
                hours_text.text = Utils.convertDecimalHoursToHHMM(parseFloat(currentTask.initial_planned_hours));
            } else {
                hours_text.text = "01:00";  // Default value
            }

            // Set date range more carefully to preserve original dates

            if (currentTask.start_date && currentTask.end_date) {
                date_range_widget.setDateRange(currentTask.start_date, currentTask.end_date);
            } else if (currentTask.start_date) {
                date_range_widget.setDateRange(currentTask.start_date, null);
            } else if (currentTask.end_date) {
                date_range_widget.setDateRange(null, currentTask.end_date);
            }
            // If no dates are set, don't call setDateRange to avoid defaulting to today

            // Load multiple assignees if enabled
            if (workItem.enableMultipleAssignees) {
                var existingAssignees = Task.getTaskAssignees(recordid, instanceId);
                workItem.setMultipleAssignees(existingAssignees);
            }

            attachments_widget.setAttachments(Task.getAttachmentsForTask(currentTask.odoo_record_id));
        } else {
            workItem.loadAccounts();
        }
        //  console.log("currentTask loaded:", JSON.stringify(currentTask));
    }

    onVisibleChanged: {
        if (visible) {
            if (Global.description_temporary_holder !== "") {
                //Check if you are coming back from the ReadMore page
                description_text.text = Global.description_temporary_holder;
                Global.description_temporary_holder = "";
            }
        } else {
            Global.description_temporary_holder = "";
        }
    }
}
