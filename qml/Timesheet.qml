/*
 * MIT License
 *
 * Copyright (c) 2025 CIT-Services
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, publish, distribute, sublicense, and/or sell
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
import "../models/utils.js" as Utils
import "../models/global.js" as Global
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

    function save_timesheet() {
        //check if timer is running
        console.log(TimerService.getActiveTimesheetId());
        console.log("Record id is" + recordid);
        if (recordid === TimerService.getActiveTimesheetId()) {
            notifPopup.open("Error", "Please stop the timer before saving the record", "error");
            return;
        }

        const ids = workItem.getIds();
        console.log("getAllSelectedDbRecordIds returned:");
        console.log("   accountDbId: " + ids.account_id);
        console.log("   projectDbId: " + ids.project_id);
        console.log("   subProjectDbId: " + ids.subproject_id);
        console.log("   taskDbId: " + ids.task_id);
        console.log("   subTaskDbId: " + ids.subtask_id);
        const user = Accounts.getCurrentUserOdooId(ids.account_id);

        if (!user) {
            notifPopup.open("Error", "Unable to find the user , can not save", "error");
            return;
        }

        if (ids.project_id === null) {
            notifPopup.open("Error", "You need to select a project to save time sheet", "error");
            return;
        }

        if (ids.task_id === null) {
            notifPopup.open("Error", "You need to select a task to save time sheet", "error");
            return;
        }

        let time = time_sheet_widget.elapsedTime;
        console.log("Recording " + time);
        console.log("Decimal Representation is " + Utils.convertHHMMtoDecimalHours(time));

        var timesheet_data = {
            'record_date': date_widget.formattedDate(),
            'instance_id': ids.account_id < 0 ? 0 : ids.account_id,
            'project': ids.project_id,
            'task': ids.task_id,
            'subTask': ids.subtask_id,
            'subprojectId': ids.subproject_id,
            'description': description_text.text,
            'unit_amount': Utils.convertHHMMtoDecimalHours(time),
            'quadrant': priorityGrid.currentIndex + 1,
            'user_id': user,
            'status': "draft"
        };

        //Finally check if the record is not empty (Usecase Edit)
        if (recordid && recordid !== 0) {
            timesheet_data.id = recordid;
        }

        const result = Model.saveTimesheet(timesheet_data);
        if (!result.success) {
            notifPopup.open("Error", "Unable to Save the Task", "error");
        } else {
            notifPopup.open("Saved", "Timesheet has been saved successfully", "success");
        }
        //check if timerservice is running & active sheet is this  , then use it stop it as well to save the data
        if (TimerService.isRunning() && TimerService.activeTimesheetId == recordid) {
            time = TimerService.stop();
        }
    }

    function switchToEditMode() {
        // Simply change the current page to edit mode
        if (recordid !== 0) {
            isReadOnly = false;
        }
    }

    property bool isManualTime: false
    property bool running: false
    property int selectedSubTaskId: 0
    property var recordid: 0 //0 means creation mode
    property bool isReadOnly: false // Can be overridden when page is opened
    property var currentTimesheet: {}

    NotificationPopup {
        id: notifPopup
        width: units.gu(80)
        height: units.gu(80)
    }

    Flickable {
        id: timesheetsDetailsPageFlickable
        anchors.topMargin: units.gu(6)
        anchors.fill: parent
        contentHeight: parent.height + units.gu(50)
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
                    showAssigneeSelector: false
                    showAccountSelector: true
                    showProjectSelector: true
                    showSubProjectSelector: true
                    showTaskSelector: true
                    showSubTaskSelector: true
                    width: timesheetsDetailsPageFlickable.width - units.gu(2)
                    // height: units.gu(29) // Uncomment if you need fixed height
                    //onAccountChanged:
                    // console.log("Account id is ->>>>" + accountId);
                    //{}
                }
            }
        }

        Column {
            id: myRow7
            anchors.top: myRow1a.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: units.gu(1)
            anchors.rightMargin: units.gu(1)
            spacing: units.gu(1)
            topPadding: units.gu(2)

            Row {
                spacing: units.gu(1.5)

                Label {
                    id: priority_label
                    text: "Priority"
                    width: units.gu(7)
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                }

                Icon {
                    id: helpIcon
                    name: "help"
                    width: units.gu(2.5)
                    height: units.gu(2.5)
                    color: theme.palette.normal.backgroundText
                    anchors.verticalCenter: priority_label.verticalCenter
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            notifPopup.open("Priority Help", "What Is Important Is Seldom Urgent, and What Is Urgent Is Seldom Important.<br><br><b>1. Important & Urgent:</b><br>Here you write down important activities, which also have to be done immediately. These are urgent problems or projects with a hard deadline. I.e. If you manage a restaurant and an employee has not shown up, it is a rather urgent and acute problem. All signals are on red, so this is a typical activity for the first quadrant.<br><br><b>2. Important & Not Urgent:</b><br>If you leave the activities in this quadrant for the coming week, nothing will immediately go wrong. But be careful: These are activities and projects that will help you in the long term. Think of thinking about a strategy, improving work processes in your team, investing in relationships and investing in yourself. i.e. You are a team leader who has just been told during his performance review that more creative input is expected. Such an outcome of a performance review is an assignment that will never feel urgent, but is very important. You can quickly recognize the important & non-urgent activities by answering the question: if I don't do this, will it get me into trouble in the long run? If the answer is yes, then you have an important & non-urgent activity. If the answer is no, then it is a non-important & non-urgent activity.<br><br><b>3. Urgent & Not Important:</b><br>This quadrant concerns activities that do not help you in the long run, but that are screaming for your attention this week. An adjustment in a presentation that has to be done for a colleague on the spur of the moment or the milk that is almost empty. With tasks in this quadrant it is very important to check whether they are actually urgent. Requests from others in particular often seem very urgent, while they can sometimes wait a day or a week. It is usually fine to postpone this work to a more suitable moment, provided that I communicate well about this. If you have the opportunity to delegate or outsource these tasks in this quadrant, do so. If you work for yourself, this is not always possible. In that case, I advise you to organize your working day in such a way that you are guided as little as possible by these urgent tasks, if necessary by reserving a fixed time block each day for these types of emergencies. That way you keep control over your agenda.<br><br><b>4. Not Important & Not Urgent:</b><br>This type of work that you want to have on your plate as little as possible, because it does not help you in any way. Constantly refreshing your mailbox, for example. But meetings without a clear goal also fall into this category. You can undoubtedly point out more of these types of 'busy work' examples yourself: things that you do, but that do not really benefit anyone. Sometimes these activities are a great short break from your work, but usually they are a great excuse to postpone your important work for a while.", "info");
                        }
                    }
                }
            }

            Grid {
                id: priorityGrid
                columns: 2
                spacing: units.gu(0.5)
                width: parent.width - units.gu(2)

                property int currentIndex: 0

                RadioButton {
                    id: priority1
                    text: "Important, Urgent (1)"
                    enabled: !isReadOnly
                    checked: priorityGrid.currentIndex === 0
                    contentItem: Text {
                        text: priority1.text
                        font.pixelSize: units.gu(1.5)
                        color: theme.palette.normal.backgroundText
                        leftPadding: priority1.indicator.width + priority1.spacing
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.WordWrap
                    }
                    onCheckedChanged: {
                        if (checked)
                            priorityGrid.currentIndex = 0;
                    }
                }

                RadioButton {
                    id: priority2
                    text: "Important, Not Urgent (2)"
                    enabled: !isReadOnly
                    checked: priorityGrid.currentIndex === 1
                    contentItem: Text {
                        text: priority2.text
                        font.pixelSize: units.gu(1.5)
                        color: theme.palette.normal.backgroundText
                        leftPadding: priority2.indicator.width + priority2.spacing
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.WordWrap
                    }
                    onCheckedChanged: {
                        if (checked)
                            priorityGrid.currentIndex = 1;
                    }
                }

                RadioButton {
                    id: priority3
                    text: "Urgent, Not Important (3)"
                    enabled: !isReadOnly
                    checked: priorityGrid.currentIndex === 2
                    contentItem: Text {
                        font.pixelSize: units.gu(1.5)
                        text: priority3.text
                        color: theme.palette.normal.backgroundText
                        leftPadding: priority3.indicator.width + priority3.spacing
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.WordWrap
                    }
                    onCheckedChanged: {
                        if (checked)
                            priorityGrid.currentIndex = 2;
                    }
                }

                RadioButton {
                    id: priority4
                    text: "Not Urgent, Not Important (4)"
                    enabled: !isReadOnly
                    checked: priorityGrid.currentIndex === 3
                    contentItem: Text {
                        text: priority4.text
                        font.pixelSize: units.gu(1.5)
                        color: theme.palette.normal.backgroundText
                        leftPadding: priority4.indicator.width + priority4.spacing
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.WordWrap
                    }
                    onCheckedChanged: {
                        if (checked)
                            priorityGrid.currentIndex = 3;
                    }
                }
            }
        }

        Row {
            id: time_sheet_row
            anchors.top: myRow7.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: units.gu(1)
            anchors.rightMargin: units.gu(1)
            spacing: units.gu(2)
            topPadding: units.gu(1)
            height: recordid ? units.gu(20) : units.gu(5)
            TimeRecorderWidget {
                id: time_sheet_widget
                enabled: !isReadOnly
                anchors.fill: time_sheet_row
                timesheetId: recordid
                visible: recordid
                onInvalidtimesheet: {
                    notifPopup.open("Error", "Save the time sheet first", "error");
                }
            }
            Label {
                anchors.fill: parent
                anchors.margins: units.gu(1)
                anchors.horizontalCenter: parent.horizontalCenter
                visible: !recordid
                text: "Please save the timesheet before recording your working hours."
                color: "red"
                font.italic: true
            }
        }
        Row {
            id: myRow1
            anchors.top: time_sheet_row.bottom
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

        /**********************************************************/

        Row {
            id: myRow9
            anchors.top: myRow1.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            topPadding: units.gu(5)

            Column {
                id: myCol9

                Item {
                    id: textAreaContainer
                    width: timesheetsDetailsPageFlickable.width
                    height: description_text.height

                    RichTextPreview {
                        id: description_text
                        width: parent.width
                        height: units.gu(20) // Start with collapsed height
                        anchors.centerIn: parent.centerIn
                        text: ""
                        is_read_only: isReadOnly
                        onClicked: {
                            //set the data to a global store and pass the key to the page
                            Global.description_temporary_holder = text;
                            apLayout.addPageToNextColumn(timeSheet, Qt.resolvedUrl("ReadMorePage.qml"), {
                                isReadOnly: isReadOnly
                            });
                        }
                    }
                }
            }
        }

        Component.onCompleted: {
            console.log("Timesheet Component.onCompleted - recordid:", recordid, "isReadOnly:", isReadOnly);

            if (recordid != 0) // We are loading a time sheet , depends on readonly value it could be for view/edit
            {
                currentTimesheet = Model.getTimeSheetDetails(recordid);
                let instanceId = (currentTimesheet.instance_id !== undefined && currentTimesheet.instance_id !== null) ? currentTimesheet.instance_id : -1;
                let projectId = (currentTimesheet.project_id !== undefined && currentTimesheet.project_id !== null) ? currentTimesheet.project_id : -1;
                let taskId = (currentTimesheet.task_id !== undefined && currentTimesheet.task_id !== null) ? currentTimesheet.task_id : -1;
                let subProjectId = (currentTimesheet.sub_project_id !== undefined && currentTimesheet.sub_project_id !== null) ? currentTimesheet.sub_project_id : -1;
                let subTaskId = (currentTimesheet.sub_task_id !== undefined && currentTimesheet.sub_task_id !== null) ? currentTimesheet.sub_task_id : -1;

                console.log("Now lets call this with workitemselector ");

                workItem.deferredLoadExistingRecordSet(instanceId, projectId, subProjectId, taskId, subTaskId, -1); //passing -1 as no assignee is needed
                date_widget.setSelectedDate(currentTimesheet.record_date);

                description_text.text = currentTimesheet.name;
                if (currentTimesheet.spentHours && currentTimesheet.spentHours !== "") {
                    time_sheet_widget.elapsedTime = currentTimesheet.spentHours;
                }
                if (currentTimesheet.quadrant_id && currentTimesheet.quadrant_id !== "") {
                    priorityGrid.currentIndex = parseInt(currentTimesheet.quadrant_id) - 1; //index=id-1
                }
            } else {
                workItem.loadAccounts();
                console.log("----------------------------------------------Creating new timesheet, setting default values-----------------------------------------------------");
            }
        }
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
