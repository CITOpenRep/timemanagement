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
        console.log("Task DB ID:", ids.taskDbId);
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

        if (ids.taskDbId < 0) {
            notifPopup.open("Error", "You need to select a task to save time sheet", "error");
            return;
        }

        var timesheet_data = {
            'instance_id': ids.accountDbId < 0 ? 0 : ids.accountDbId,
            'record_date': date_widget.formattedDate(),
            'project': ids.projectDbId,
            'task': ids.taskDbId,
            'subprojectId': 0,
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

        const result = Model.createOrSaveTimesheet(timesheet_data);
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
                    onAccountChanged: {
                        console.log("Account id is ->>>>" + accountId);
                    }
                }
            }
        }

        Row {
            id: myRow7
            anchors.top: myRow1a.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: units.gu(1)
            anchors.rightMargin: units.gu(1)

            spacing: units.gu(1.5)
            topPadding: units.gu(2)

            Label {
                id: priority_label
                text: "Priority"
                width: units.gu(7)
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft
                
            }

            Item {
                width: units.gu(2.4)
                height: units.gu(5)
            }

            TSCombobox {
                id: priorityCombo
                width: units.gu(32.5)
                height: units.gu(5)
           
                model: ["Do First (Important & Urgent )", "Do Next (Important & Not Urgent)", "Do Later (Urgent & Not Important)", "Don't do (Not Urgent & Not Important)"]
                enabled: !isReadOnly
                currentIndex: 0
            }
            
            Icon {
                id: helpIcon
                name: "help"
                width: units.gu(3)
                height: units.gu(3)
                anchors.verticalCenter: priorityCombo.verticalCenter
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        notifPopup.open("Priority Help", "What Is Important Is Seldom Urgent. And What Is Urgent Is Seldom Important.\n\n1. Important & Urgent:\nHere you write down important activities, which also have to be done immediately. These are urgent problems or projects with a hard deadline. All signals are on red, so this is a typical activity for the first quadrant.\n\n2. Important & Not Urgent:\nIf you leave the activities in this quadrant for the coming week, nothing will immediately go wrong. But be careful: These are activities and projects that will help you in the long term. Think of thinking about a strategy, improving work processes in your team, investing in relationships and investing in yourself.\n\n3. Urgent & Not Important:\nThis quadrant concerns activities that do not help you in the long run, but that are screaming for your attention this week. With tasks in this quadrant it is very important to check whether they are actually urgent. If you have the opportunity to delegate or outsource these tasks in this quadrant, do so.\n\n4. Not Important & Not Urgent:\nThis type of work that you want to have on your plate as little as possible, because it does not help you in any way. Sometimes these activities are a great short break from your work, but usually they are a great excuse to postpone your important work for a while.", "info");
                    }
                }
            }
        }

        Row {
            id: myRow1
            anchors.top: myRow7.bottom
            anchors.left: parent.left
            Column {
                leftPadding: units.gu(1)
                DaySelector {
                    id: date_widget
                    readOnly: isReadOnly
                    width: timesheetsDetailsPageFlickable.width - units.gu(2)
                    height: units.gu(5)
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
            spacing: units.gu(2)
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
                height: units.gu(5)
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

        TimePickerPopup {
            id: myTimePicker
            onTimeSelected: {
                let timeStr = (hour < 10 ? "0" + hour : hour) + ":" + (minute < 10 ? "0" + minute : minute);
                console.log("Selected time:", timeStr);
                hours_text.text = timeStr;  // for example, update a field
            }
        }

        Component.onCompleted: {
            console.log("XXXX From Timesheet got record id : " + recordid);
            if (recordid != 0) // We are loading a time sheet , depends on readonly value it could be for view/edit
            {
                currentTimesheet = Model.getTimeSheetDetails(recordid);
                let instanceId = (currentTimesheet.instance_id !== undefined && currentTimesheet.instance_id !== null) ? currentTimesheet.instance_id : -1;
                let projectId = (currentTimesheet.project_id !== undefined && currentTimesheet.project_id !== null) ? currentTimesheet.project_id : -1;
                let taskId = (currentTimesheet.task_id !== undefined && currentTimesheet.task_id !== null) ? currentTimesheet.task_id : -1;
                let subProjectId = (currentTimesheet.sub_project_id !== undefined && currentTimesheet.sub_project_id !== null) ? currentTimesheet.sub_project_id : -1;
                let subTaskId = (currentTimesheet.sub_task_id !== undefined && currentTimesheet.sub_task_id !== null) ? currentTimesheet.sub_task_id : -1;
                /* console.log("Timesheet Field Values:");
                console.log("Recordid     →" + recordid);
                console.log("instanceId    →", instanceId);
                console.log("projectId     →", projectId);
                console.log("taskId        →", taskId);
                console.log("subProjectId  →", subProjectId);
                console.log("subTaskId     →", subTaskId);*/

                workItem.applyDeferredSelection(instanceId, projectId, taskId);
                date_widget.setSelectedDate(currentTimesheet.record_date);

                name_text.text = currentTimesheet.name;
                if (currentTimesheet.spentHours && currentTimesheet.spentHours !== "") {
                    hours_text.text = currentTimesheet.spentHours;
                }
                if (currentTimesheet.quadrant_id && currentTimesheet.quadrant_id !== "") {
                    priorityCombo.currentIndex = parseInt(currentTimesheet.quadrant_id) - 1; //index=id-1
                }
            } else //we are creating a new timesheet
            {
                workItem.applyDeferredSelection(Accounts.getDefaultAccountId(), -1, -1);
            }
        }
    }
}
