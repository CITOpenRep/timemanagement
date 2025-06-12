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
                visible: !isReadOnly
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
        if (name_text.text != "") {
            const saveData = {
                accountId: ids.accountDbId < 0 ? 0 : ids.accountDbId,
                name: name_text.text,
                record_id: recordid,
                projectId: ids.projectDbId < 0 ? 0 : ids.projectDbId,
                subProjectId: ids.subprojectDbId < 0 ? 0 : ids.subprojectDbId,
                parentId: ids.taskDbId > 0 ? ids.taskDbId : 0,
                startDate: date_range_widget.formattedStartDate(),
                endDate: date_range_widget.formattedEndDate(),
                deadline: date_range_widget.formattedEndDate() //for now we made deadline as enddate
                ,
                favorites: 0//for now do nothing
                ,
                plannedHours: hours_text.text,
                description: description_text.text,
                assigneeUserId: assigneeCombo.selectedUserId === -1 ? null : assigneeCombo.selectedUserId //add a messagebox if you want to have an assignee based on the -1 value
                ,
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
        onClosed: console.log("Notification dismissed")
    }
    Flickable {
        id: tasksDetailsPageFlickable
        anchors.topMargin: units.gu(6)
        anchors.fill: parent
        contentHeight: parent.height + 500
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
                    taskLabelText: "Parent Task"
                    showSubtaskSelector: false
                    width: tasksDetailsPageFlickable.width - units.gu(2)
                    // height: units.gu(29) // Uncomment if you need fixed height
                    onAccountChanged: {
                        console.log("Account id is " + accountId);
                        assigneeCombo.accountId = accountId;
                        assigneeCombo.shouldDeferUserSelection = false;
                        assigneeCombo.loadUsers();
                    }
                }
            }
        }
        Row {
            id: myRow1b
            anchors.top: myRow1a.bottom
            anchors.left: parent.left
            topPadding: units.gu(5)
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
                        // font.bold: true
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        //textSize: Label.Large
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
                    enabled: !isReadOnly
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
                    enabled: !isReadOnly
                    onClicked: {
                        incdecHrs(1);
                    }
                }
            }
        }

        Row {
            id: myRow6
            anchors.top: myRow4.bottom
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
    Component.onCompleted: {
        //Utils.updateOdooUsers(assigneeModel);
        // console.log("From Timesheet got record id : " + recordid);
        if (recordid != 0) // We are loading a time sheet, depends on readonly value it could be for view/edit
        {
            console.log("Loading Task with id->" + recordid);
            //// return;
            currentTask = Task.getTaskDetails(recordid);

            /* console.log("Sub Project ID:", currentTask.sub_project_id);
            console.log("Project ID:", currentTask.project_id);
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
            console.log("Odoo Record ID:", currentTask.odoo_record_id);*/

            let instanceId = (currentTask.account_id !== undefined && currentTask.account_id !== null) ? currentTask.account_id : -1;
            let projectId = (currentTask.project_id !== undefined && currentTask.project_id !== null) ? currentTask.project_id : -1;
            let taskId = (currentTask.task_id !== undefined && currentTask.task_id !== null) ? currentTask.task_id : -1;
            let subProjectId = (currentTask.sub_project_id !== undefined && currentTask.sub_project_id !== null) ? currentTask.sub_project_id : -1;
            let user_id = (currentTask.user_id !== undefined && currentTask.user_id !== null) ? currentTask.user_id : -1;

            workItem.applyDeferredSelection(instanceId, currentTask.project_id, currentTask.sub_project_id, -1, -1);
            //We do not now setting the parent task

            //Todo Gokul to implement the defered loading in assignees , we get [] for invalid users
            if (typeof currentTask.user_id === "number" && currentTask.user_id > 0) {
                console.log("User ID:", currentTask.user_id);
                assigneeCombo.accountId = instanceId;
                assigneeCombo.deferredUserId = currentTask.user_id;
                assigneeCombo.shouldDeferUserSelection = true;
                assigneeCombo.loadUsers();
            } else {
                console.warn("⚠️ Invalid or empty user_id:", currentTask.user_id);
            }

            date_range_widget.setDateRange(currentTask.start_date, currentTask.end_date);

            name_text.text = currentTask.name;
            if (currentTask.initial_planned_hours && currentTask.initial_planned_hours !== "") {
                hours_text.text = currentTask.initial_planned_hours;
            }

            description_text.text = currentTask.description;
        } else //we are creating a new Task
        {
            console.log("Creating a new task");
            workItem.applyDeferredSelection(Accounts.getDefaultAccountId(), -1, -1, -1);
            assigneeCombo.accountId = Accounts.getDefaultAccountId();
            assigneeCombo.shouldDeferUserSelection = false;
            assigneeCombo.loadUsers();
        }
    }
}
