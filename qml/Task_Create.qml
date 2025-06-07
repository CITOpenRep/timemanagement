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
import "../models/Task.js" as Task
import "../models/Utils.js" as Utils
import "../models/Global.js" as Global
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

    property string currentEditingField: ""
    property bool workpersonaSwitchState: true
    property bool isReadOnly: false
    property int selectedProjectId: 0
    property int selectedparentId: 0
    property int selectedTaskId: 0
    property int favorites: 0
    property int subProjectId: 0
    property var prevtask: ""

    function save_task_data() {
        //this shit has to be updated
        console.log("Account ID: " + Global.selectedInstanceId);
        if (task_text.text != "") {
            const saveData = {
                accountId: accountCombo.selectedInstanceId,
                name: task_text.text,
                projectId: (projectCombo.selectedProjectId < 0) ? 0 : projectCombo.selectedProjectId,
                subProjectId: 0,
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

    ListModel {
        id: taskModel1
    }

    ListModel {
        id: assigneeModel
    }

    ScrollView {
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: parent.height
        anchors.bottom: parent.bottom
        LomiriShape {
            id: rect1
            anchors.top: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            radius: "large"
            width: parent.width
            height: parent.height

            Row {
                id: myRow1a
                anchors.left: parent.left
                topPadding: units.gu(2)
                Column {
                    leftPadding: units.gu(2)
                    LomiriShape {
                        width: units.gu(10)
                        height: units.gu(5)
                        aspect: LomiriShape.Flat
                        Label {
                            id: instance_label
                            text: "Instance"
                            font.bold: true
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            //textSize: Label.Large
                        }
                    }
                }
                Column {
                    leftPadding: units.gu(3)
                    LomiriShape {
                        width: units.gu(30)
                        height: units.gu(8.5)

                        AccountSelector {
                            id: accountCombo
                            editable: true
                            width: parent.width
                            height: parent.height
                            anchors.centerIn: parent.centerIn
                            flat: true
                            Component.onCompleted: {
                                console.log("Account id is " + accountCombo.selectedInstanceId);
                            }

                            onAccountSelected: {
                                //fetch the users from the account
                                assigneecombo.accountId = id;
                                assigneecombo.loadUsers();

                                //fetch projects
                                projectCombo.accountId = id;
                                projectCombo.loadProjects();

                                //add account id to task
                                taskselector_combo.clear();
                                taskselector_combo.accountId = accountCombo.selectedInstanceId;
                            }
                        }
                    }
                }
            }

            Row {
                id: myRow1
                anchors.top: myRow1a.bottom
                anchors.left: parent.left
                topPadding: units.gu(2)
                Column {
                    leftPadding: units.gu(2)
                    LomiriShape {
                        width: units.gu(10)
                        height: units.gu(5)
                        aspect: LomiriShape.Flat
                        Label {
                            id: task_label
                            text: "Task Name"
                            font.bold: true
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            //textSize: Label.Large
                        }
                    }
                }
                Column {
                    leftPadding: units.gu(3)
                    TextField {
                        id: task_text
                        readOnly: isReadOnly
                        width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                        text: ""
                    }
                }
            }

            Row {
                id: myRow2
                anchors.top: myRow1.bottom
                anchors.left: parent.left
                topPadding: units.gu(2)
                Column {
                    leftPadding: units.gu(2)
                    LomiriShape {
                        width: units.gu(10)
                        height: units.gu(5)
                        aspect: LomiriShape.Flat
                        Label {
                            id: assignee_label
                            text: "Assignee"
                            font.bold: true
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            //textSize: Label.Large
                        }
                    }
                }
                Column {
                    leftPadding: units.gu(3)
                    LomiriShape {
                        width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                        height: units.gu(8.5)

                        UserSelector {
                            id: assigneecombo
                            editable: true
                            width: parent.width
                            height: parent.height
                            anchors.centerIn: parent.centerIn
                            flat: true
                            onUserSelected:
                            //selectedAssigneeRemoteId = remoteid
                            {}
                        }
                    }
                }
            }

            Row {
                id: myRow9
                anchors.top: myRow2.bottom
                anchors.left: parent.left
                topPadding: units.gu(2)
                Column {
                    id: myCol8
                    leftPadding: units.gu(2)
                    LomiriShape {
                        width: units.gu(10)
                        height: units.gu(5)
                        aspect: LomiriShape.Flat
                        Label {
                            id: description_label
                            text: "Description"
                            font.bold: true
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
                        width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                        anchors.centerIn: parent.centerIn
                        text: ""
                    }
                }
            }

            Row {
                id: myRow3
                anchors.top: myRow9.bottom
                anchors.left: parent.left
                topPadding: units.gu(2)
                Column {
                    leftPadding: units.gu(2)
                    LomiriShape {
                        width: units.gu(10)
                        height: units.gu(5)
                        aspect: LomiriShape.Flat
                        Label {
                            id: project_label
                            text: "Project"
                            font.bold: true
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            //textSize: Label.Large
                        }
                    }
                }
                Column {
                    leftPadding: units.gu(3)
                    LomiriShape {
                        width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                        height: units.gu(5)
                        MouseArea {
                            anchors.fill: parent
                        }

                        ProjectSelector {
                            id: projectCombo
                            editable: true
                            width: parent.width
                            height: parent.height
                            anchors.centerIn: parent.centerIn
                            flat: true
                            onProjectSelected: {
                                console.log("Selected Project ID: " + id + ", Name: " + name);
                                selectedProjectId = id;
                                // do follow-up logic, e.g. load tasks
                                taskselector_combo.clear();
                                taskselector_combo.projectId = selectedProjectId;
                                taskselector_combo.loadTasks();
                            }
                        }
                    }
                }
            }

            Row {
                id: myRow10
                anchors.top: myRow3.bottom
                anchors.left: parent.left
                topPadding: units.gu(2)
                Column {
                    id: myCol10
                    leftPadding: units.gu(2)
                    LomiriShape {
                        width: units.gu(10)
                        height: units.gu(5)
                        aspect: LomiriShape.Flat
                        Label {
                            id: parent_label
                            text: "Parent Task"
                            font.bold: true
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            //textSize: Label.Large
                        }
                    }
                }
                Column {
                    id: myCol11
                    leftPadding: units.gu(3)
                    LomiriShape {
                        width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                        height: units.gu(8.5)
                        TaskSelector {
                            id: taskselector_combo
                            width: parent.width
                            height: parent.height
                            anchors.centerIn: parent.centerIn
                            onTaskSelected: {}
                        }
                    }
                }
            }

            Row {
                id: myRow4
                anchors.top: myRow10.bottom
                anchors.left: parent.left
                height: units.gu(5)
                topPadding: units.gu(2)
                Column {
                    leftPadding: units.gu(2)
                    LomiriShape {
                        width: units.gu(10)
                        height: units.gu(5)
                        aspect: LomiriShape.Flat
                        Label {
                            id: hours_label
                            text: "Planned Hours"
                            font.bold: true
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
                    leftPadding: units.gu(2)
                    LomiriShape {
                        width: units.gu(10)
                        height: units.gu(5)
                        aspect: LomiriShape.Flat
                        Label {
                            id: start_label
                            text: "Start Date"
                            font.bold: true
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
                        width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
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
                    leftPadding: units.gu(2)
                    LomiriShape {
                        width: units.gu(10)
                        height: units.gu(5)
                        aspect: LomiriShape.Flat
                        Label {
                            id: end_label
                            text: "End Date"
                            font.bold: true
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
                        width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
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
                    leftPadding: units.gu(2)
                    LomiriShape {
                        width: units.gu(10)
                        height: units.gu(5)
                        aspect: LomiriShape.Flat
                        Label {
                            id: deadline_label
                            text: "Deadline"
                            font.bold: true
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
                        width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                        height: units.gu(4)
                        anchors.centerIn: parent.centerIn
                    }
                }
            }

            Row {
                id: myRow8
                anchors.top: myRow7.bottom
                anchors.left: parent.left
                topPadding: units.gu(2)
                Column {
                    leftPadding: units.gu(2)
                    LomiriShape {
                        width: units.gu(10)
                        height: units.gu(5)
                        aspect: LomiriShape.Flat
                        Label {
                            id: priority_label
                            text: "Priority"
                            font.bold: true
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            //textSize: Label.Large
                        }
                    }
                }
                Column {
                    leftPadding: units.gu(3)
                    Row {
                        id: img_star
                        width: units.gu(20)
                        height: units.gu(20)
                        spacing: units.gu(1)
                        property int selectedPriority: 0

                        Image {
                            source: favorites > 0 ? "images/star-active.svg" : "images/starinactive.svg"
                            width: units.gu(5)
                            height: units.gu(5)
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    favorites = favorites > 0 ? 0 : 1;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    NotificationPopup {
        id: notifPopup
        width: units.gu(80)
        height: units.gu(80)
        onClosed: console.log("Notification dismissed")
    }

    Component.onCompleted: {
        Utils.updateOdooUsers(assigneeModel);
    }
}
