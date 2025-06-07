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
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.Components.Pickers 1.3
import QtCharts 2.0
import QtQuick.Window 2.2
import Qt.labs.settings 1.0
import "../models/Timesheet.js" as Timesheet
import "../models/Utils.js" as Utils
import "components"

Page {
    id: timesheetsDetails
    title: "Timesheet Details"
    header: PageHeader {
        id: tsHeader
        title: timesheetsDetails.title
        StyleHints {
            foregroundColor: "white"

            backgroundColor: LomiriColors.orange
            dividerColor: LomiriColors.slate
        }

        trailingActionBar.actions: [
            Action {
                iconName: "edit"
                text: "Edit"
                visible: isReadOnly
                onTriggered: {
                    console.log("Edit Timesheet clicked");
                    // console.log("Account ID: " + currentProject.account_id)
                    isReadOnly = !isReadOnly;
                }
            },
            Action {
                iconSource: "images/save.svg"
                text: "Save"
                visible: !isReadOnly
                onTriggered: {
                    var timesheet_data = {
                        'id': recordid,
                        'instance_id': accountSelectorCombo.selectedInstanceId < 0 ? null : accountSelectorCombo.selectedInstanceId,
                        'dateTime': date_widget.date,
                        'project': projectSelectorCombo.selectedProjectId < 0 ? null : projectSelectorCombo.selectedProjectId,
                        'task': taskSelectorCombo.selectedTaskId < 0 ? null : taskSelectorCombo.selectedTaskId,
                        'subprojectId': subprojectSelectorCombo.selectedSubProjectId < 0 ? null : subprojectSelectorCombo.selectedSubProjectId,
                        'subTask': subTaskSelectorCombo.selectedSubTaskId < 0 ? null : subTaskSelectorCombo.selectedSubTaskId,
                        'description': description_text.text,
                        'manualSpentHours': hours_text.text,
                        'spenthours': hours_text.text,
                        'isManualTimeRecord': isManualTime,
                        'quadrant': priorityCombo.currentIndex + 1,
                        'status': "updated"
                    };

                    const result = Timesheet.create_or_update_timesheet(timesheet_data);
                    if (!result.success) {
                        notifPopup.open("Error", "Unable to Save the Task", "error");
                    } else {
                        notifPopup.open("Saved", "Task has been saved successfully", "success");
                    }
                }
            }
        ]
    }

    NotificationPopup {
        id: notifPopup
        width: units.gu(80)
        height: units.gu(80)
        onClosed: console.log("Notification dismissed")
    }

    property var recordid: 0
    property bool isManualTime: false
    property bool isSaved: true
    property string saveMessage: ''
    property bool isVisibleMessage: false
    property bool workpersonaSwitchState: true
    property bool isReadOnly: true
    property var currentTimesheet: {}
    property int favorites: 0
    property int selectedInstanceId: 0
    property int selectedProjectId: 0
    property int selectedSubProjectId: 0
    property int selectedTaskId: 0
    property int selectedSubTaskId: 0

    function floattoint(value) {
        return Number.parseFloat(value).toFixed(0);
    }

    Flickable {
        id: timesheetsDetailsPageFlickable
        anchors.fill: parent
        contentHeight: parent.height
        // + 1000
        flickableDirection: Flickable.VerticalFlick
        anchors.top: tsHeader.bottom
        anchors.topMargin: tsHeader.height + units.gu(4)
        anchors.bottomMargin: units.gu(4)
        width: parent.width

        Row {
            id: instanceRow
            anchors.left: parent.left
            topPadding: units.gu(2)
            Column {
                leftPadding: units.gu(1)
                Rectangle {
                    width: units.gu(10)
                    height: units.gu(5)
                    Label {
                        id: instance_label
                        text: "Instance"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
            Column {
                leftPadding: units.gu(3)
                LomiriShape {
                    width: units.gu(30)
                    height: units.gu(5)

                    AccountSelector {
                        id: accountSelectorCombo
                        enabled: !isReadOnly

                        width: parent.width
                        height: parent.height
                        anchors.centerIn: parent.centerIn
                        flat: true
                    }
                }
            }
        }

        Row {
            id: recordDateRow
            anchors.top: instanceRow.bottom
            anchors.left: parent.left
            topPadding: units.gu(2)
            Column {
                leftPadding: units.gu(1)
                Rectangle {
                    width: units.gu(10)
                    height: units.gu(5)
                    Label {
                        id: recorddate_label
                        text: "Date"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
            Column {
                leftPadding: units.gu(3)
                QuickDateSelector {
                    id: date_widget
                    enabled: !isReadOnly
                    mode: "previous"
                    width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                    height: units.gu(4)
                    anchors.centerIn: parent.centerIn
                    Component.onCompleted: {}
                }
            }
        }

        Row {
            id: projectRow
            anchors.top: recordDateRow.bottom
            anchors.left: parent.left
            topPadding: units.gu(2)
            Column {
                leftPadding: units.gu(1)
                Rectangle {
                    width: units.gu(10)
                    height: units.gu(5)
                    Label {
                        id: project_label
                        text: "Project"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
            Column {
                leftPadding: units.gu(3)
                LomiriShape {
                    width: units.gu(30)
                    height: units.gu(5)
                    ProjectSelector {
                        id: projectSelectorCombo
                        enabled: !isReadOnly
                        editable: true
                        width: parent.width
                        height: parent.height
                        anchors.centerIn: parent.centerIn
                    }
                }
            }
        }

        Row {
            id: subProjectRow
            anchors.top: projectRow.bottom
            anchors.left: parent.left
            topPadding: units.gu(2)
            Column {
                leftPadding: units.gu(1)
                Rectangle {
                    width: units.gu(10)
                    height: units.gu(5)
                    Label {
                        id: subproject_label
                        text: "Sub Project"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
            Column {
                leftPadding: units.gu(3)
                LomiriShape {
                    width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                    height: units.gu(5)
                    SubProjectSelector {
                        id: subprojectSelectorCombo
                        enabled: !isReadOnly
                        editable: true
                        width: parent.width
                        height: parent.height
                        anchors.centerIn: parent.centerIn
                        onSubProjectSelected: {
                            selectedSubProjectId = id;
                        }
                    }
                }
            }
        }

        Row {
            id: taskRow
            anchors.top: subProjectRow.bottom
            anchors.left: parent.left
            topPadding: units.gu(2)
            Column {
                leftPadding: units.gu(1)
                Rectangle {
                    width: units.gu(10)
                    height: units.gu(5)
                    Label {
                        id: task_label
                        text: "Task"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
            Column {
                leftPadding: units.gu(3)
                LomiriShape {
                    width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                    height: units.gu(5)
                    TaskSelector {
                        id: taskSelectorCombo
                        editable: true
                        enabled: !isReadOnly
                        width: parent.width
                        height: parent.height
                        anchors.centerIn: parent.centerIn
                        onTaskSelected: {
                            subTaskSelectorCombo.accountId = accountSelectorCombo.selectedInstanceId;
                            subTaskSelectorCombo.taskId = id;
                            subTaskSelectorCombo.loadSubTasks();
                        }
                    }
                }
            }
        }

        Row {
            id: subTaskRow
            anchors.top: taskRow.bottom
            anchors.left: parent.left
            topPadding: units.gu(2)
            Column {
                leftPadding: units.gu(1)
                Rectangle {
                    width: units.gu(10)
                    height: units.gu(5)
                    Label {
                        id: sub_task_label
                        text: "Sub Task"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
            Column {
                leftPadding: units.gu(3)
                LomiriShape {
                    width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                    height: units.gu(5)
                    SubTaskSelector {
                        id: subTaskSelectorCombo
                        enabled: !isReadOnly
                        editable: true
                        width: parent.width
                        height: parent.height
                        anchors.centerIn: parent.centerIn
                    }
                }
            }
        }

        Column {
            id: descriptionSection
            anchors.top: subTaskRow.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: units.gu(1)
            topPadding: units.gu(2)
            leftPadding: units.gu(1)

            Label {
                text: "Description"
            }

            TextArea {
                id: description_text
                enabled: !isReadOnly
                text: Utils.stripHtmlTags(currentTimesheet.description)
                width: parent.width
            }
        }

        Row {
            id: spentHoursRow
            anchors.top: descriptionSection.bottom
            anchors.left: parent.left
            topPadding: units.gu(2)
            leftPadding: units.gu(2)
            Label {
                id: hours_label
                text: "Spent Hours"
                verticalAlignment: Text.AlignVCenter
            }
            Row {
                leftPadding: units.gu(2)
                spacing: units.gu(2)
                TextField {
                    id: hours_text
                    enabled: !isReadOnly
                    width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(20) : units.gu(50)
                    text: currentTimesheet.spentHours
                    readOnly: true
                }
                Button {
                    objectName: "button_manual"
                    enabled: !isReadOnly
                    width: units.gu(8)
                    action: Action {
                        text: i18n.tr("Manual")
                        property bool flipped
                        onTriggered: {
                            myTimePicker.open(0, 0);
                            flipped = !flipped;
                            isManualTime = true;
                            hours_text.readOnly = false;
                        }
                    }
                    color: action.flipped ? LomiriColors.blue : LomiriColors.slate
                }
            }
        }
        Row {
            id: myRow7
            anchors.top: spentHoursRow.bottom
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
                        width: units.gu(10)
                        text: "Priority"
                        wrapMode: Text.WordWrap
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        //textSize: Label.Large
                    }
                }
            }
            Column {
                leftPadding: units.gu(2)
                ComboBox {
                    id: priorityCombo
                    enabled: !isReadOnly
                    width: units.gu(30)
                    model: ["Do (Urgent & Important)", "Plan (Important,Not Urgent)", "Delegate (Not Important,Urgent)", "Delete (Not Important&Not Urgent)"]
                    currentIndex: 0

                    // Use +1 so the stored value matches quadrant_id 1-4
                    onCurrentIndexChanged: {
                        selectedQuadrant = currentIndex + 1;
                    }
                }
            }
        }
    }
    TimePickerPopup {
        id: myTimePicker
        onTimeSelected: {
            let timeStr = (hour < 10 ? "0" + hour : hour) + ":" + (minute < 10 ? "0" + minute : minute);
            console.log("Selected time:", timeStr);
            hours_text.text = timeStr;  // for example, update a field
        }
    }
    Component.onCompleted: {
        if (recordid != 0) {
            currentTimesheet = Timesheet.get_timesheet_details(recordid);
            console.log("currentTimesheet = " + JSON.stringify(currentTimesheet, null, 2));
            //     favorites = currentProject.favorites;
            selectedInstanceId = currentTimesheet.instance_id;
            if (!selectedInstanceId) {
                notifPopup.open("Error", "Unable to load the timesheet,Critical Error", "error");
                return;
            }

            accountSelectorCombo.selectAccountById(selectedInstanceId);
            if (currentTimesheet.record_date) {
                date_widget.setDate(currentTimesheet.record_date);
            }

            if (!currentTimesheet.project_id)
                currentTimesheet.project_id = 0; //Setting as a parent project (internal)

            selectedProjectId = currentTimesheet.project_id;
            projectSelectorCombo.accountId = selectedInstanceId;
            projectSelectorCombo.shouldDeferSelection = true;
            projectSelectorCombo.loadProjects();

            if (selectedProjectId) {
                console.log("Selecting Account " + selectedProjectId);
                projectSelectorCombo.selectProjectById(selectedProjectId);

                // Task Selector
                taskSelectorCombo.projectId = selectedProjectId;
                taskSelectorCombo.accountId = selectedInstanceId;

                if (currentTimesheet.task_id) {
                    selectedTaskId = currentTimesheet.task_id;
                    taskSelectorCombo.deferredTaskId = currentTimesheet.task_id;
                    taskSelectorCombo.shouldDeferSelection = true;
                }
                taskSelectorCombo.loadTasks();

                // Subproject Selector
                subprojectSelectorCombo.accountId = selectedInstanceId;
                subprojectSelectorCombo.projectId = selectedProjectId;

                if (currentTimesheet.sub_project_id) {
                    selectedSubProjectId = currentTimesheet.sub_project_id;
                    subprojectSelectorCombo.deferredSubProjectId = currentTimesheet.sub_project_id;
                    subprojectSelectorCombo.shouldDeferSelection = true;
                }
                subprojectSelectorCombo.loadSubProjects();

                //subTaskSelectorCombo
                subTaskSelectorCombo.taskId = selectedTaskId;
                subTaskSelectorCombo.accountId = selectedInstanceId;

                if (currentTimesheet.sub_task_id) {
                    selectedSubTaskId = currentTimesheet.sub_task_id;
                    subTaskSelectorCombo.deferredSubTaskId = currentTimesheet.sub_task_id;
                    subTaskSelectorCombo.shouldDeferSelection = true;
                }
                subTaskSelectorCombo.loadSubTasks();
            } else {
                console.log("Invalid Projectid");
            }

            if (currentTimesheet.quadrant_id)
            //prioritySlider.value = parseInt(currentTimesheet.quadrant_id || 0) + 1;
            {}
        } else {
            setInstanceList();
            selectedInstanceId = instanceModel.get(0).id;
            setProjectList();
            instance_combo.currentIndex = instanceModel.get(0).id;
            instance_combo.editText = instanceModel.get(0).id;
            isReadOnly = false;
            currentTimesheet = {
                'record_date': Qt.formatDate(new Date(), "MM/dd/yyyy")
            };
        }
    }
}
