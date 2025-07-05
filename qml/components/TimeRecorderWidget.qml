/*
 * MIT License
 * Copyright (c) 2025 CIT-Services
 */

import QtQuick 2.7
import Lomiri.Components 1.3
import QtQuick.Layouts 1.11
import QtQuick.Controls 2.2
import "../../models/constants.js" as AppConst
import "../../models/timer_service.js" as TimerService
import "../../models/timesheet.js" as TimeSheet
import "../../models/utils.js" as Utils

Item {
    id: autoRecorder
    width: parent.width - units.gu(2)
    height: units.gu(12)
    anchors.horizontalCenter: parent.horizontalCenter

    property bool isRecording: false
    property bool autoMode: true  // Automated by default
    property string elapsedTime: "00:00"
    property int timesheetId: 0

    NotificationPopup {
        id: notifPopup
        width: units.gu(80)
        height: units.gu(80)
    }

    TimePickerPopup {
        id: myTimePicker
        onTimeSelected: {
            let timeStr = (hour < 10 ? "0" + hour : hour) + ":" + (minute < 10 ? "0" + minute : minute);
            console.log("Selected time:", timeStr);
            elapsedTime = timeStr;  // for example, update a field
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: units.gu(1.5)
        spacing: units.gu(1)

        Label {
            text: "Time Tracking"
            anchors.left: parent.left
            anchors.right: parent.right
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
            height: units.gu(2)
        }

        RowLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: units.gu(1)

            RadioButton {
                id: manualRadio
                text: "Manual"
                checked: !autoMode
                onClicked: {
                    autoMode = false;
                    updateUiMode();
                }
            }

            RadioButton {
                id: automatedRadio
                text: "Automated"
                checked: autoMode
                onClicked: {
                    autoMode = true;
                    updateUiMode();
                }
            }
        }

        RowLayout {
            spacing: units.gu(1)
            anchors.horizontalCenter: parent.horizontalCenter

            Label {
                id: timeDisplay
                text: elapsedTime
                font.pixelSize: units.gu(2)
            }
        }

        RowLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: units.gu(1)

            TSButton {
                text: isRecording ? "Stop" : "Start"
                visible: autoMode
                width: units.gu(10)
                onClicked: {
                    if (!isRecording) {
                        TimerService.start(timesheetId);
                        isRecording = true;
                        updateTimer.start();
                    } else {
                        TimerService.stop(timesheetId);
                        isRecording = false;
                        updateTimer.stop();
                    }
                }
            }

            TSButton {
                text: "Set"
                visible: !autoMode
                width: units.gu(10)
                onClicked: {
                    myTimePicker.open(1, 0);
                    // Here we can make the Entry as updated
                    // TimerService.manualEntry(timesheetId, timeDisplay.text)
                    console.log("Finalized manual entry: " + timeDisplay.text);
                }
            }
            TSButton {
                text: "Finalize"
                width: units.gu(10)
                onClicked: {
                    console.log("Finalized manual entry: " + timeDisplay.text);
                    const result = TimeSheet.markTimesheetAsReadyById(timesheetId);
                    if (!result.success) {
                        notifPopup.open("Error", "Unable to finalise the timesheet", "error");
                    } else {
                        notifPopup.open("Saved", "Timesheet has been finalised successfully", "success");
                    }
                }
            }
        }
    }

    Timer {
        id: updateTimer
        interval: 1000
        repeat: true
        running: isRecording && autoMode
        onTriggered: {
            if (TimerService.isRunning()) {
                timeDisplay.text = "Tracking your time ...";
                isRecording = true;
            } else {
                timeDisplay.text = Utils.convertDecimalHoursToHHMM(TimeSheet.getTimesheetUnitAmount(timesheetId));
                isRecording = false;
            }
        }
    }

    function updateUiMode() {
        console.log("Switched to mode:", autoMode ? "Automated" : "Manual");
        if (!autoMode) {
            if (isRecording) {
                TimerService.stop(timesheetId);
                isRecording = false;
                updateTimer.stop();
            }
        }
    }

    Component.onCompleted: {
        if (timesheetId > 0 && timesheetId === TimerService.getActiveTimesheetId()) {
            isRecording = true;
            if (autoMode)
                updateTimer.start();
        } else {
            isRecording = false;
            updateTimer.stop();
        }
    }
}
