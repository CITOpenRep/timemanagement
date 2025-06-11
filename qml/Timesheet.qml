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
import QtQuick.Layouts 1.3
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.Components.Pickers 1.3
import QtCharts 2.0
import QtQuick.Window 2.2
import Qt.labs.settings 1.0
import "../models/timesheet.js" as Model
import "../models/accounts.js" as Accounts
import "../models/timer_service.js" as TimerService
import "components"

Page {
    id: timeSheet
    title: "Timesheet"
    header: PageHeader {
        id: tsHeader
        StyleHints {
            foregroundColor: "white"

            backgroundColor: LomiriColors.orange
            dividerColor: LomiriColors.slate
        }

        title: timeSheet.title

        trailingActionBar.actions: [
            Action {
                iconSource: "images/save.svg"
                visible: !isReadOnly
                text: "Save"
                onTriggered: {
                    save_timesheet();
                    console.log("Timesheet Save Button clicked");
                }
            }
        ]
    }

    function save_timesheet() {
        console.log("Trying to save time sheet");
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

        console.log("User ID is " + user);
        if (ids.projectDbId < 0) {
            notifPopup.open("Error", "You need to select a project to save time sheet", "error");
            return;
        }

        var timesheet_data = {
            'instance_id': ids.accountDbId < 0 ? 0 : ids.accountDbId,
            'dateTime': date_widget.selectedDate,
            'project': ids.projectDbId,
            'task': ids.taskDbId,
            'subprojectId': ids.subprojectDbId,
            'subTask': ids.subtaskDbId,
            'description': name_text.text,
            'manualSpentHours': hours_text.text,
            'spenthours': hours_text.text,
            'isManualTimeRecord': isManualTime,
            'quadrant': priorityCombo.currentIndex + 1,
            'user_id': user,
            'status': "updated"
        };

        //Finally check if the record is not empty (Usecase Edit)
        if (recordid && recordid !== 0) {
            timesheet_data.id = recordid;
        }

        const result = Model.create_or_update_timesheet(timesheet_data);
        if (!result.success) {
            notifPopup.open("Error", "Unable to Save the Task", "error");
        } else {
            notifPopup.open("Saved", "Task has been saved successfully", "success");
        }
    }

    property bool isManualTime: false
    property bool running: false
    property int selectedSubTaskId: 0
    property var recordid: 0 //0 means creatiion mode
    property bool isReadOnly: false //edit or view mode
    property var currentTimesheet: {}

    NotificationPopup {
        id: notifPopup
        width: units.gu(80)
        height: units.gu(80)
        onClosed: console.log("Notification dismissed")
    }

    Flickable {
        id: timesheetsDetailsPageFlickable
        anchors.topMargin: units.gu(6)
        anchors.fill: parent
        contentHeight: parent.height
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
                    width: timesheetsDetailsPageFlickable.width - units.gu(2)
                    // height: units.gu(29) // Uncomment if you need fixed height
                }
            }
        }

        Row {
            id: myRow1
            anchors.top: myRow1a.bottom
            anchors.left: parent.left
            Column {
                leftPadding: units.gu(1)
                DaySelector {
                    id: date_widget
                    readOnly: isReadOnly
                    width: timesheetsDetailsPageFlickable.width - units.gu(2)
                    height: units.gu(8)
                    anchors.centerIn: parent.centerIn
                }
            }
        }

        // Row for Spent Hours and Manual Entry
        Row {
            id: spentHoursRow
            anchors.top: myRow1.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: units.gu(1)
            anchors.rightMargin: units.gu(1)
            spacing: units.gu(1)
            topPadding: units.gu(1)

            TSLabel {
                id: hours_label
                text: "Spent Hours"
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
                text: "Manual"
                objectName: "button_manual"
                enabled: !isReadOnly
                width: parent.width * 0.2
                height: units.gu(3)
                anchors.verticalCenter: parent.verticalCenter

                onClicked: {
                    myTimePicker.open(1, 0);
                    isManualTime = true;
                    // hours_text.readOnly = false;
                }
            }
            Rectangle {
                id: spacer
                color: "red"
                Layout.fillWidth: true
                height: units.gu(3)
            }
        }

        /**********************************************************/

        Column {
            id: descriptionSection
            anchors.top: spentHoursRow.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: units.gu(1)
            topPadding: units.gu(1)
            leftPadding: units.gu(1)

            Label {
                text: "Description"
            }

            TextArea {
                id: name_text
                enabled: !isReadOnly
                text: ""
                width: parent.width - units.gu(2)
            }
        }

        Row {
            id: myRow7
            anchors.top: descriptionSection.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: units.gu(1)
            anchors.rightMargin: units.gu(1)
            spacing: units.gu(1)
            topPadding: units.gu(1)

            Label {
                id: priority_label
                text: "Priority"
                width: units.gu(6)
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft
            }

            TSCombobox {
                id: priorityCombo
                width: units.gu(33)
                model: ["Do (Important & Urgent )", "Plan (Important & Not Urgent)", "Delegate (Urgent & Not Important)", "Delete (Not Urgent & Not Important)"]
                enabled: !isReadOnly
                currentIndex: 0
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
            console.log("From Timesheet got record id : " + recordid);
            if (recordid != 0) // We are loading a time sheet , depends on readonly value it could be for view/edit
            {
                currentTimesheet = Model.get_timesheet_details(recordid);
                let instanceId = (currentTimesheet.instance_id !== undefined && currentTimesheet.instance_id !== null) ? currentTimesheet.instance_id : -1;
                let projectId = (currentTimesheet.project_id !== undefined && currentTimesheet.project_id !== null) ? currentTimesheet.project_id : -1;
                let taskId = (currentTimesheet.task_id !== undefined && currentTimesheet.task_id !== null) ? currentTimesheet.task_id : -1;
                let subProjectId = (currentTimesheet.sub_project_id !== undefined && currentTimesheet.sub_project_id !== null) ? currentTimesheet.sub_project_id : -1;
                let subTaskId = (currentTimesheet.sub_task_id !== undefined && currentTimesheet.sub_task_id !== null) ? currentTimesheet.sub_task_id : -1;
                console.log("Timesheet Field Values:");
                console.log("Recordid     →" + recordid);
                console.log("instanceId    →", instanceId);
                console.log("projectId     →", projectId);
                console.log("taskId        →", taskId);
                console.log("subProjectId  →", subProjectId);
                console.log("subTaskId     →", subTaskId);

                workItem.applyDeferredSelection(instanceId, projectId, subProjectId,taskId, subTaskId);
                if (currentTimesheet.record_date && currentTimesheet.record_date !== "") {
                    var parts = currentTimesheet.record_date.split("-");
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

                name_text.text = currentTimesheet.name;
                if (currentTimesheet.spentHours && currentTimesheet.spentHours !== "") {
                    hours_text.text = currentTimesheet.spentHours;
                }
                if (currentTimesheet.quadrant_id && currentTimesheet.quadrant_id !== "") {
                    priorityCombo.currentIndex = parseInt(currentTimesheet.quadrant_id) - 1; //index=id-1
                }
            } else //we are creating a new timesheet
            {
                console.log("Creating a new timesheet");
                workItem.applyDeferredSelection(Accounts.getDefaultAccountId(), -1, -1, -1);
            }
        }
    }
}
