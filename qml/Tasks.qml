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
import "../models/global.js" as Global
import "../models/accounts.js" as Accounts

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
    property bool isReadOnly: false
    property int selectedProjectId: 0
    property int selectedparentId: 0
    property int selectedTaskId: 0
    property int favorites: 0
    property int subProjectId: 0
    property var prevtask: ""

    property var currentTask: {}

    function switchToEditMode() {
        // Simply change the current page to edit mode
        if (recordid !== 0) {
            isReadOnly = false;
        }
    }

    function save_task_data() {
        const ids = workItem.getAllSelectedDbRecordIds();
        const user = Accounts.getCurrentUserOdooId(ids.accountDbId);
        if (!user) {
            notifPopup.open("Error", "Unable to find the user , can not save", "error");
            return;
        }
        if (name_text.text != "") {
            const saveData = {
                accountId: ids.accountDbId < 0 ? 0 : ids.accountDbId,
                name: name_text.text,
                record_id: recordid,
                projectId: ids.projectDbId < 0 ? 0 : ids.projectDbId,
                subProjectId: 0,
                parentId: ids.taskDbId > 0 ? ids.taskDbId : 0,
                startDate: date_range_widget.formattedStartDate(),
                endDate: date_range_widget.formattedEndDate(),
                deadline: date_range_widget.formattedEndDate(),
                favorites: 0,
                plannedHours: Utils.convertDurationToFloat(hours_text.text),
                description: description_text.text,
                assigneeUserId: ids.assigneeDbId < 0 ? null : ids.assigneeDbId,
                status: "updated"
            };

            const result = Task.saveOrUpdateTask(saveData);
            if (!result.success) {
                notifPopup.open("Error", "Unable to Save the Task", "error");
            } else {
                notifPopup.open("Saved", "Task has been saved successfully", "success");
            }
        } else {
            notifPopup.open("Error", "Please add a Name to the task", "error");
        }
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
        contentHeight: parent.height + 500
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
                    taskLabelText: "Parent Task"
                    width: tasksDetailsPageFlickable.width - units.gu(2)
                    height: units.gu(10)
                    showAccountSelector: true
                    showProjectSelector: true
                    showSubProjectSelector: true
                    showTaskSelector: true
                    showSubTaskSelector: false
                    showAssigneeSelector: true
                }
            }
        }
        Row {
            id: myRow1b
            anchors.top: myRow1a.bottom
            anchors.left: parent.left
            topPadding: units.gu(25)
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
                }
            }
        }
        Row {
            id: myRow9
            anchors.top: myRow1b.bottom
            anchors.left: parent.left
            topPadding: units.gu(5)
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
                TextArea {
                    id: description_text
                    readOnly: isReadOnly
                    textFormat: Text.RichText
                    autoSize: false
                    maximumLineCount: 0
                    width: tasksDetailsPageFlickable.width < units.gu(361) ? tasksDetailsPageFlickable.width - units.gu(15) : tasksDetailsPageFlickable.width - units.gu(10)
                    anchors.centerIn: parent.centerIn
                    text: ""
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
    }
    TimePickerPopup {
        id: myTimePicker
        onTimeSelected: {
            let timeStr = (hour < 10 ? "0" + hour : hour) + ":" + (minute < 10 ? "0" + minute : minute);
            hours_text.text = timeStr;
        }
    }

    Timer {
        id: selectorSetupTimer
        interval: 2000  // increased delay to 2000ms for deferred loading
        repeat: false
        property var instanceId: -1
        property var parentProjectId: -1
        property var subProjectId: -1  // added to store subproject for read-only display
        property var parentTaskId: -1
        property var subTaskId: -1       // added to store current task for selection
        property var assigneeId: -1
        onTriggered: {
            console.log("=== Setting up WorkItemSelector (Timer) ===");
            console.log("Configuring selector with:", JSON.stringify({
                instanceId: instanceId,
                parentProjectId: parentProjectId,
                subProjectId: subProjectId,
                parentTaskId: parentTaskId,
                subTaskId: subTaskId,
                assigneeId: assigneeId
            }));
            
            // Pass subTaskId instead of hard-coded -1 to select the current task in tasks view
            workItem.applyDeferredSelection(instanceId, parentProjectId, subProjectId, parentTaskId, subTaskId, assigneeId);
            console.log("=== WorkItemSelector configured ===");

            // Set view mode to read-only after selector population
            isReadOnly = true;
            console.log("Tasks.qml - switched to read-only mode");

            // Start final verification timer
            finalVerificationTimer.start();
        }
    }

    Timer {
        id: finalVerificationTimer
        interval: 1000
        repeat: false
        onTriggered: {
            console.log("Final field values verification:");
            console.log("  - name_text has text property:", typeof name_text.text);
            console.log("  - description_text has text property:", typeof description_text.text);
            console.log("  - hours_text has text property:", typeof hours_text.text);
            
            // Set view mode to read-only if needed
            if (isReadOnly) {
                console.log("Task is in read-only mode");
            }
        }
    }

    Component.onCompleted: {
        console.log("Tasks.qml Component.onCompleted - recordid:", recordid, "isReadOnly:", isReadOnly);
        
        if (recordid != 0) // We are loading a task, depends on readonly value it could be for view/edit
        {
            console.log("=== Loading Task Details for recordid:", recordid, "===");
            currentTask = Task.getTaskDetails(recordid);
            console.log("Raw task data returned:", JSON.stringify(currentTask));

            if (currentTask && Object.keys(currentTask).length > 0) {
                console.log("Task loaded successfully - field details:");
                console.log("  - id:", currentTask.id);
                console.log("  - name:", currentTask.name);
                console.log("  - account_id:", currentTask.account_id);
                console.log("  - project_id:", currentTask.project_id);
                console.log("  - parent_id:", currentTask.parent_id);
                console.log("  - user_id:", currentTask.user_id);
                console.log("  - description:", currentTask.description);
                console.log("  - initial_planned_hours:", currentTask.initial_planned_hours);
            } else {
                console.log("Failed to load task details - empty or null task object");
                return;
            }

            // Set the form fields with task details FIRST
            console.log("=== Setting form fields ===");
            console.log("Setting name_text.text to:", currentTask.name || "");
            name_text.text = currentTask.name || "";
            
            console.log("Setting description_text.text to:", currentTask.description || "");
            description_text.text = currentTask.description || "";
            
            console.log("Setting hours_text.text from initial_planned_hours:", currentTask.initial_planned_hours);
            hours_text.text = currentTask.initial_planned_hours ? Utils.convertFloatToTime(parseFloat(currentTask.initial_planned_hours)) : "01:00";

            // Set date range
            if (currentTask.start_date && currentTask.end_date) {
                console.log("Setting date range:", currentTask.start_date, "to", currentTask.end_date);
                date_range_widget.setDateRange(currentTask.start_date, currentTask.end_date);
            } else if (currentTask.start_date) {
                console.log("Setting single date:", currentTask.start_date);
                date_range_widget.setDateRange(currentTask.start_date, currentTask.start_date);
            }
            
            console.log("=== Form fields set complete ===");
            
            // Store the IDs in the timer properties and start the deferred setup
            let instanceId = (currentTask.account_id !== undefined && currentTask.account_id !== null) ? currentTask.account_id : -1;
            // Use >0 test to avoid treating zero as a valid ID for view-only selectors
            let parent_project_id = (currentTask.project_id > 0) ? currentTask.project_id : -1;
            // Include sub-project for read-only display
            // Include sub-project for read-only display; only positive IDs are valid
            let sub_project_id = (currentTask.sub_project_id > 0) ? currentTask.sub_project_id : -1;
            // Only positive parent IDs are valid; zero means no parent task
            let parent_task_id = (currentTask.parent_id > 0) ? currentTask.parent_id : -1;
            let assignee_id = (currentTask.user_id !== undefined && currentTask.user_id !== null) ? currentTask.user_id : -1;
            
            selectorSetupTimer.instanceId = instanceId;
            selectorSetupTimer.parentProjectId = parent_project_id;
            selectorSetupTimer.subProjectId = sub_project_id;
            selectorSetupTimer.parentTaskId = parent_task_id;
            selectorSetupTimer.assigneeId = assignee_id;
            // Start selector setup timer so subprojects are displayed in read-only mode as well
            selectorSetupTimer.start();
        }
    }
}
