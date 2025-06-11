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
    title: "New Task"
    header: PageHeader {
        title: taskCreate.title
        StyleHints {
            foregroundColor: "white"

            backgroundColor: LomiriColors.orange
            dividerColor: LomiriColors.slate
        }

        //    enable: true
        trailingActionBar.actions: [
            Action {
                iconSource: "images/save.svg"
                text: "Save"
                onTriggered: {
                    isReadOnly = !isReadOnly;
                    console.log("Save Task clicked");
                    save_task_data();
                }
            }
        ]
    }
    property var recordid: 0 //0 means creatiion mode

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

    function save_task_data() {
        //this shit has to be updated
        console.log("Account ID: " + Global.selectedInstanceId);
        const ids = workItem.getAllSelectedDbRecordIds();
        console.log("Account DB ID:", ids.accountDbId);
        console.log("Project DB ID:", ids.projectDbId);
        console.log("Subproject DB ID:", ids.subprojectDbId);
        console.log("Task DB ID:", ids.taskDbId);
        console.log("Subtask DB ID:", ids.subtaskDbId);
        console.log("Get the Current User");
        const user = Accounts.getCurrentUserOdooId(ids.accountDbId);
        if (!user) {
            notifPopup.open("Error", "Unable to find the user , can not save", "error");
            return;
        }
        if (task_text.text != "") {
            const saveData = {
                accountId: ids.accountDbId < 0 ? 0 : ids.accountDbId,
                name: task_text.text,
                projectId: ids.projectDbId < 0 ? 0 : ids.projectDbId,
                subProjectId: ids.subprojectDbId < 0 ? 0 : ids.subprojectDbId,
                 
                parentId: taskselector_combo.selectedTaskId > 0 ? taskselector_combo.selectedTaskId : null,

                startDate: start_date_widget.date,
                endDate: end_date_widget.date,
                deadline: deadline_widget.date,
                favorites: favorites,
                plannedHours: hours_text.text,
                description: description_text.text,
                assigneeUserId: assigneecombo.selectedUserId,
                status: "updated"
            };

            const result = Task.saveOrUpdateTask(saveData);
            if (!result.success) {
                notifPopup.open("Error", "Unable to Save the Task", "error");
            } else {
                notifPopup.open("Saved", "Task has been saved successfully", "success");
            }
        } else {
            notifPopup.open("Error", "Unable to Save the Data", "error");
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
        onClosed: console.log("Notification dismissed")
    }
    Flickable {
        id: tasksDetailsPageFlickable
        anchors.topMargin: units.gu(6)
        anchors.fill: parent
        contentHeight: parent.height+ 500
        // + 1000
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
                    width: tasksDetailsPageFlickable.width - units.gu(2)
                    // height: units.gu(29) // Uncomment if you need fixed height
                }
            }
        }
        Row {
            id: myRow9
            anchors.top: myRow1a.bottom
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
                        // font.bold: true
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        //textSize: Label.Large
                    }
                }
            }
            Column {
                id: myCol9
                leftPadding: units.gu(3)
                TextArea {
                    id: description_text
                    readOnly: isReadOnly
                    autoSize: true
                    maximumLineCount: 0
                    width: tasksDetailsPageFlickable.width < units.gu(361) ? tasksDetailsPageFlickable.width - units.gu(15) : tasksDetailsPageFlickable.width - units.gu(10)
                    anchors.centerIn: parent.centerIn
                    text: ""
                }
            }
        }

        Row {
            id: myRow2
            anchors.top: myRow9.bottom
            anchors.left: parent.left
            topPadding: 10
            Column {
                leftPadding: units.gu(1)
                LomiriShape {
                    width: units.gu(10)
                    height: units.gu(5)
                    aspect: LomiriShape.Flat
                    Label {
                        id: assignee_label
                        // font.bold: true
                        text: "Assignee"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        //textSize: Label.Large
                    }
                }
            }
            Column {
                leftPadding: units.gu(3)
                LomiriShape {
                    width: tasksDetailsPageFlickable.width < units.gu(361) ? tasksDetailsPageFlickable.width - units.gu(15) : tasksDetailsPageFlickable.width - units.gu(10)
                    height: 60

                    UserSelector {
                        id: assigneeCombo
                        editable: true
                        width: parent.width
                        height: parent.height
                        anchors.centerIn: parent.centerIn
                        flat: true
                        enabled: !taskCreate.isReadOnly
                        Component.onCompleted: {
                            assigneeCombo.accountId = tasks[0].account_id;
                            assigneeCombo.loadUsers();
                            projectCombo.selectProjectById(tasks[0].user);
                        }
                    }
                }
            }
        }

        Row {
            id: myRow4
            anchors.top: myRow2.bottom
            anchors.left: parent.left
            height: units.gu(5)
            topPadding: units.gu(2)
            Column {
                leftPadding: units.gu(1)
                LomiriShape {
                    width: units.gu(10)
                    height: units.gu(5)
                    aspect: LomiriShape.Flat
                    Label {
                        id: hours_label
                        text: "Planned Hours"
                        //font.bold: true
                        anchors.left: parent.left

                        anchors.verticalCenter: parent.verticalCenter
                        //textSize: Label.Large
                    }
                }
            }
            Column {
                leftPadding: units.gu(3)
                TSButton {
                    id: minusbutton
                    anchors.left: plusbutton.right
                    height: units.gu(4)
                    width: units.gu(4)
                    text: "-"
                    onClicked: {
                        incdecHrs(2);
                    }
                }
            }
            Column {
                id: planColumn
                leftPadding: units.gu(1)
                TextField {
                    id: hours_text
                    readOnly: isReadOnly
                    width: units.gu(20)
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "1"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Column {
                leftPadding: units.gu(1)
                TSButton {
                    id: plusbutton
                    height: units.gu(4)
                    width: units.gu(4)
                    text: "+"
                    onClicked: {
                        incdecHrs(1);
                    }
                }
            }
        }
        Row {
            id: myRow5
            anchors.top: myRow4.bottom
            anchors.left: parent.left
            topPadding: units.gu(2)
            Column {
                leftPadding: units.gu(1)
                LomiriShape {
                    width: units.gu(10)
                    height: units.gu(5)
                    aspect: LomiriShape.Flat
                    Label {
                        id: start_label
                        text: "Start Date"
                        //font.bold: true
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        //textSize: Label.Large
                    }
                }
            }
            Column {
                leftPadding: units.gu(3)
                QuickDateSelector {
                    id: start_date_widget
                    width: tasksDetailsPageFlickable.width < units.gu(361) ? tasksDetailsPageFlickable.width - units.gu(15) : tasksDetailsPageFlickable.width - units.gu(10)

                    height: units.gu(4)
                    anchors.centerIn: parent.centerIn
                }
            }
        }

        Row {
            id: myRow6
            anchors.top: myRow5.bottom
            anchors.left: parent.left
            topPadding: units.gu(2)
            Column {
                leftPadding: units.gu(1)
                LomiriShape {
                    width: units.gu(10)
                    height: units.gu(5)
                    aspect: LomiriShape.Flat
                    Label {
                        id: end_label
                        text: "End Date"
                        //font.bold: true
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        //textSize: Label.Large
                    }
                }
            }
            Column {
                leftPadding: units.gu(3)
                QuickDateSelector {
                    id: end_date_widget
                    width: tasksDetailsPageFlickable.width < units.gu(361) ? tasksDetailsPageFlickable.width - units.gu(15) : tasksDetailsPageFlickable.width - units.gu(10)
                    height: units.gu(4)
                    anchors.centerIn: parent.centerIn
                }
            }
        }

        Row {
            id: myRow7
            anchors.top: myRow6.bottom
            anchors.left: parent.left
            topPadding: units.gu(2)
            Column {
                leftPadding: units.gu(1)
                LomiriShape {
                    width: units.gu(10)
                    height: units.gu(5)
                    aspect: LomiriShape.Flat
                    Label {
                        id: deadline_label
                        text: "Deadline"
                        //font.bold: true
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        //textSize: Label.Large
                    }
                }
            }
            Column {
                leftPadding: units.gu(3)
                QuickDateSelector {
                    id: deadline_widget
                    width: tasksDetailsPageFlickable.width < units.gu(361) ? tasksDetailsPageFlickable.width - units.gu(15) : tasksDetailsPageFlickable.width - units.gu(10)
                    height: units.gu(4)
                    anchors.centerIn: parent.centerIn
                }
            }
        }
    }
    Component.onCompleted: {
        //Utils.updateOdooUsers(assigneeModel);
        // console.log("From Timesheet got record id : " + recordid);
        if (recordid != 0) // We are loading a time sheet, depends on readonly value it could be for view/edit
        {
            console.log(("Got the call"));
            //// return;
            currentTask = Task.getTaskDetails(recordid);

            console.log("Task Details:");
            console.log("ID:", currentTask.id);
            console.log("Name:", currentTask.name);
            console.log("Account ID:", currentTask.account_id);
            console.log("Project ID:", currentTask.project_id);
            console.log("Sub Project ID:", currentTask.sub_project_id);
            console.log("Parent ID:", currentTask.parent_id);
            console.log("Start Date:", currentTask.start_date);
            console.log("End Date:", currentTask.end_date);
            console.log("Deadline:", currentTask.deadline);
            console.log("Initial Planned Hours:", currentTask.initial_planned_hours);
            console.log("Favorites:", currentTask.favorites);
            console.log("State:", currentTask.state);
            console.log("Description:", currentTask.description);
            console.log("Last Modified:", currentTask.last_modified);
            console.log("User ID:", currentTask.user_id);
            console.log("Status:", currentTask.status);
            console.log("Odoo Record ID:", currentTask.odoo_record_id);

            let instanceId = (currentTask.account_id !== undefined && currentTask.account_id !== null) ? currentTask.account_id : -1;
            let projectId = (currentTask.project_id !== undefined && currentTask.project_id !== null) ? currentTask.project_id : -1;
            let taskId = (currentTask.task_id !== undefined && currentTask.task_id !== null) ? currentTask.task_id : -1;
            let subProjectId = (currentTask.sub_project_id !== undefined && currentTask.sub_project_id !== null) ? currentTask.sub_project_id : -1;

            workItem.applyDeferredSelection(instanceId, projectId, subProjectId, taskId, -1);

            if (currentTask.record_date && currentTask.record_date !== "") {
                var parts = currentTask.record_date.split("-");
                if (parts.length === 3) {
                    var day = parseInt(parts[0], 10);
                    var month = parseInt(parts[1], 10) - 1; // Month is 0-based in JS Date
                    var year = parseInt(parts[2], 10);
                    var parsedDate = new Date(year, month, day);
                    date_widget.selectedDate = parsedDate;
                }
            } else {
                date_widget.selectedDate = null; // or leave unset if DaySelector handles it
            }

            name_text.text = currentTask.name;
            if (currentTask.spentHours && currentTask.spentHours !== "") {
                hours_text.text = currentTask.spentHours;
            }
            if (currentTask.quadrant_id && currentTask.quadrant_id !== "") {
                priorityCombo.currentIndex = parseInt(currentTask.quadrant_id) - 1; //index=id-1
            }
        } else //we are creating a new Task
        {
            console.log("Creating a new task");
            workItem.applyDeferredSelection(Accounts.getDefaultAccountId(), -1, -1, -1);
        }
    }
}
