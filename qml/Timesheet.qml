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
import "../models/timer_service.js" as TimerService
import "components"

Page {
    id: timeSheet
    title: "New Timesheet"
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
            'description': description_text.text,
            'manualSpentHours': hours_text.text,
            'spenthours': hours_text.text,
            'isManualTimeRecord': isManualTime,
            'quadrant': priorityCombo.currentIndex + 1,
            'status': "updated"
        };

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
                    enabled: !isReadOnly
                    width: timesheetsDetailsPageFlickable.width - units.gu(2)
                    height: units.gu(8)
                    anchors.centerIn: parent.centerIn
                }
            }
        }

        /**********************************************************/

        Column {
            id: descriptionSection
            anchors.top: myRow1.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: units.gu(1)
            topPadding: units.gu(1)
            leftPadding: units.gu(1)

            Label {
                text: "Description"
            }

            TextArea {
                id: description_text
                enabled: !isReadOnly
                text: ""
                width: parent.width - units.gu(2)
            }
        }

        // Row for Spent Hours and Manual Entry
        Row {
            id: spentHoursRow
            anchors.top: descriptionSection.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: units.gu(1)
            anchors.rightMargin: units.gu(1)

            Label {
                id: hours_label
                text: "Spent Hours"
                verticalAlignment: Text.AlignVCenter
                Layout.alignment: Qt.AlignVCenter
            }

            TextField {
                id: hours_text
                text: "01:00"
                readOnly: true
                Layout.alignment: Qt.AlignVCenter
                validator: RegExpValidator {
                    regExp: /^([0-1][0-9]|2[0-3]):[0-5][0-9]$/
                }
                inputMethodHints: Qt.ImhTime
            }

            TSButton {
                text: "Manual"
                objectName: "button_manual"
                width: parent.width * 0.2
                height: units.gu(3)

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

        Row {
            id: myRow7
            anchors.top: spentHoursRow.bottom
            anchors.left: parent.left
            anchors.leftMargin: units.gu(2)
            spacing: units.gu(2)
            height: units.gu(5)

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

                onCurrentIndexChanged: {
                    selectedQuadrant = currentIndex + 1;
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
            console.log("From Timesheet " + apLayout.columns);
            if (recordid != 0) // We are loading a time sheet , depends on readonly value it could be for view/edit
            {
                console.log("Loading time sheet " + recordid);
                currentTimesheet = Model.get_timesheet_details(recordid);
                let instanceId = currentTimesheet.instance_id !== undefined ? currentTimesheet.instance_id : -1;
                let projectId = currentTimesheet.project_id !== undefined ? currentTimesheet.project_id : -1;
                let taskId = currentTimesheet.task_id !== undefined ? currentTimesheet.task_id : -1;
                let subProjectId = currentTimesheet.sub_project_id !== undefined ? currentTimesheet.sub_project_id : -1;
                workItem.applyDeferredSelection(instanceId, projectId, taskId, subProjectId);
                if (currentTimesheet.record_date) {
                    date_widget.selectedDate = currentTimesheet.record_date;
                }
                description_text.text = currentTimesheet.description;
            } else //we are creating a new timesheet
            {}
        }
    }

    onVisibleChanged: {
        if (visible)
        //to update the UI
        //if (TimerService.isRunning())
        //stopwatchTimer.start();
        //else
        //  stopwatchTimer.stop();
        {} else
        //stopwatchTimer.stop();
        {}
    }
}
