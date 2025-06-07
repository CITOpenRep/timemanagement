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
                text: "Save"
                onTriggered: {
                    save_timesheet();
                    console.log("Timesheet Save Button clicked");
                }
            }
        ]
    }

    function save_timesheet() {
        console.log("Timesheet Saved");
        var timesheet_data = {
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
            topPadding: 40
            Column {
                leftPadding: units.gu(2)
                LomiriShape {
                    width: units.gu(10)
                    height: units.gu(5)
                    aspect: LomiriShape.Flat
                    Label {
                        id: instance_label
                        text: "Instance"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        //textSize: Label.Large
                    }
                }
            }
            Column {
                leftPadding: units.gu(1)
                LomiriShape {
                    width: units.gu(30)
                    height: units.gu(5)

                    AccountSelector {
                        id: accountSelectorCombo
                        editable: true
                        width: parent.width
                        height: parent.height
                        anchors.centerIn: parent.centerIn
                        flat: true
                        onAccountSelected: {
                            projectSelectorCombo.accountId = id;
                            projectSelectorCombo.loadProjects();
                            subprojectSelectorCombo.clear();
                            taskSelectorCombo.clear();
                            subTaskSelectorCombo.clear();
                        }
                    }
                }
            }
        }

        Row {
            id: myRow1
            anchors.top: myRow1a.bottom
            anchors.left: parent.left
            topPadding: 10
            Column {
                leftPadding: units.gu(2)
                LomiriShape {
                    width: units.gu(10)
                    height: units.gu(5)
                    aspect: LomiriShape.Flat
                    Label {
                        id: date_label
                        text: "Date"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        //textSize: Label.Large
                    }
                }
            }
            Column {
                leftPadding: units.gu(1)
                QuickDateSelector {
                    id: date_widget
                    mode: "previous"
                    width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                    height: units.gu(4)
                    anchors.centerIn: parent.centerIn
                }
            }
        }
        Row {
            id: myRow2
            anchors.top: myRow1.bottom
            anchors.left: parent.left
            topPadding: 10
            Column {
                id: myCol
                leftPadding: units.gu(2)
                LomiriShape {
                    width: units.gu(10)
                    height: units.gu(5)
                    aspect: LomiriShape.Flat
                    Label {
                        id: project_label
                        text: "Project"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        //textSize: Label.Large
                    }
                }
            }
            Column {
                id: myCol1
                leftPadding: units.gu(1)
                LomiriShape {
                    width: units.gu(30)
                    height: units.gu(5)
                    ProjectSelector {
                        id: projectSelectorCombo
                        editable: true
                        width: parent.width
                        height: parent.height
                        anchors.centerIn: parent.centerIn
                        onProjectSelected: {
                            subprojectSelectorCombo.accountId = accountSelectorCombo.selectedInstanceId;
                            subprojectSelectorCombo.projectId = id;
                            subprojectSelectorCombo.loadSubProjects();
                            taskSelectorCombo.clear();
                            taskSelectorCombo.projectId = id;
                            taskSelectorCombo.accountId = accountSelectorCombo.selectedInstanceId;
                            taskSelectorCombo.loadTasks();
                            subTaskSelectorCombo.clear();
                        }
                    }
                }
            }
        }
        /************************************************************
*       Added Sub Project below                             *
************************************************************/
        Row {
            id: myRow9
            anchors.top: myRow2.bottom
            anchors.left: parent.left
            topPadding: 10
            visible: true
            Column {
                id: myCol8
                leftPadding: units.gu(2)
                LomiriShape {
                    width: units.gu(10)
                    height: units.gu(5)
                    aspect: LomiriShape.Flat
                    Label {
                        id: subproject_label
                        text: "Sub Project"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        //textSize: Label.Large
                    }
                }
            }
            Column {
                id: myCol9
                leftPadding: units.gu(1)
                LomiriShape {
                    width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                    height: units.gu(5)
                    SubProjectSelector {
                        id: subprojectSelectorCombo
                        editable: true
                        width: parent.width
                        height: parent.height
                        anchors.centerIn: parent.centerIn
                        onSubProjectSelected: {
                            taskSelectorCombo.clear();
                            taskSelectorCombo.projectId = id;
                            taskSelectorCombo.accountId = accountSelectorCombo.selectedInstanceId;
                            taskSelectorCombo.loadTasks();
                        }
                    }
                }
            }
        }

        /**********************************************************/

        Row {
            id: myRow3
            anchors.top: myRow9.bottom
            anchors.left: parent.left
            topPadding: 10
            Column {
                leftPadding: units.gu(2)
                LomiriShape {
                    width: units.gu(10)
                    height: units.gu(5)
                    aspect: LomiriShape.Flat
                    Label {
                        id: task_label
                        text: "Task"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        //textSize: Label.Large
                    }
                }
            }
            Column {
                leftPadding: units.gu(1)
                LomiriShape {
                    width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                    height: units.gu(5)
                    TaskSelector {
                        id: taskSelectorCombo
                        editable: true
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

        /************************************************************
*       Added Sub Task below                                *
************************************************************/
        Row {
            id: myRow10
            anchors.top: myRow3.bottom
            anchors.left: parent.left
            topPadding: 10
            visible: true
            Column {
                id: myCol10
                leftPadding: units.gu(2)
                LomiriShape {
                    width: units.gu(10)
                    height: units.gu(5)
                    aspect: LomiriShape.Flat
                    Label {
                        id: subtask_label
                        text: "Sub Task"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        //textSize: Label.Large
                    }
                }
            }
            Column {
                id: myCol11
                leftPadding: units.gu(1)
                LomiriShape {
                    width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                    height: 60
                    SubTaskSelector {
                        id: subTaskSelectorCombo
                        editable: true
                        width: parent.width
                        height: parent.height
                        anchors.centerIn: parent.centerIn
                    }
                }
            }
        }

        /**********************************************************/

        Column {
            id: descriptionSection
            anchors.top: myRow10.bottom
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
                text: ""
                width: parent.width
            }
        }

        // Row for Spent Hours and Manual Entry
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
                    width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(20) : units.gu(50)
                    text: ""
                    readOnly: true
                }
                Button {
                    objectName: "button_manual"
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
                    width: units.gu(30)
                    model: ["Do", "Plan", "Delegate", "Delete"]
                    currentIndex: 0

                    // Use +1 so the stored value matches quadrant_id 1-4
                    onCurrentIndexChanged: {
                        selectedQuadrant = currentIndex + 1;
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
            console.log("From Timesheet " + apLayout.columns);
            //  myTimePicker.open(9, 30) //testing
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
