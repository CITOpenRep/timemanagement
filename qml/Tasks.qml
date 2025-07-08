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

    property var currentTask: {}

    function switchToEditMode() {
        // Simply change the current page to edit mode
        if (recordid !== 0) {
            isReadOnly = false;
        }
    }

    function save_task_data() {
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
                    showAccountSelector: true
                    showAssigneeSelector: true
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

                    Rectangle {
                        visible: !isReadOnly
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
            height: units.gu(5)
            visible: (recordid > 0) ? true : false
            TSButton {
                text: "Add Timesheet"
                visible: (recordid > 0) ? true : false
                width: parent.width / 2
                height: parent.height
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    let result = Timesheet.createTimesheetFromTask(recordid);
                    if (result.success) {
                        //We got the result success, lets open the record with the id
                        apLayout.addPageToNextColumn(taskCreate, Qt.resolvedUrl("Timesheet.qml"), {
                            "recordid": result.id,
                            "isReadOnly": false
                        });
                    } else {
                        console.log(result.error);
                        notifPopup.open("Error", "Unable to create timesheet", "error");
                    }
                }
            }
        }
        Row {
            id: myRow9
            anchors.top: (recordid > 0) ? add_timesheet.bottom : myRow1b.bottom //we are not showing add timesheet for a new task.
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

                    Rectangle {
                        visible: !isReadOnly
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
    Component.onCompleted: {
        console.log("Tasks Component.onCompleted - recordid:", recordid, "isReadOnly:", isReadOnly);

        if (recordid != 0) // We are loading a task, depends on readonly value it could be for view/edit
        {
            currentTask = Task.getTaskDetails(recordid);

            let instanceId = (currentTask.account_id !== undefined && currentTask.account_id !== null) ? currentTask.account_id : -1;
            let parent_project_id = (currentTask.project_id !== undefined && currentTask.project_id !== null) ? currentTask.project_id : -1;
            let sub_project_id = (currentTask.sub_project_id !== undefined && currentTask.sub_project_id !== null) ? currentTask.sub_project_id : -1;
            let parent_task_id = (currentTask.parent_id !== undefined && currentTask.parent_id !== null) ? currentTask.parent_id : -1;
            let assignee_id = (currentTask.user_id !== undefined && currentTask.user_id !== null) ? currentTask.user_id : -1;

            console.log("Loading task data:", JSON.stringify({
                instanceId: instanceId,
                parent_project_id: parent_project_id,
                sub_project_id: sub_project_id,
                parent_task_id: parent_task_id,
                assignee_id: assignee_id
            }));

            workItem.deferredLoadExistingRecordSet(instanceId, parent_project_id, sub_project_id, parent_task_id, -1, assignee_id); //passing -1 as no subtask feature is needed

            name_text.text = currentTask.name || "";
            description_text.text = currentTask.description || "";
            hours_text.text = currentTask.initial_planned_hours ? Utils.convertFloatToDuration(parseFloat(currentTask.initial_planned_hours)) : "01:00";

            // Set date range
            if (currentTask.start_date && currentTask.end_date) {
                date_range_widget.setDateRange(currentTask.start_date, currentTask.end_date);
            } else if (currentTask.start_date) {
                date_range_widget.setDateRange(currentTask.start_date, currentTask.start_date);
            }
        } else {
            workItem.loadAccounts();
        }
    }
}
