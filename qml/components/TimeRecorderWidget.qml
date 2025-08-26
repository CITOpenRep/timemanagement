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
    property bool autoMode: false
    property string elapsedTime: "01:00"
    property int timesheetId: 0
    signal invalidtimesheet

    Connections {
        target: globalTimerWidget

        onTimerStopped: {
            updateTimer.running = false;
        }
        onTimerStarted: {
            updateTimer.running = true;
        }
    }

    NotificationPopup {
        id: notifPopup
        width: units.gu(80)
        height: units.gu(80)
    }

    TimePickerPopup {
        id: myTimePicker
        onTimeSelected: {
            let timeStr = (hour < 10 ? "0" + hour : hour) + ":" + (minute < 10 ? "0" + minute : minute);

            elapsedTime = timeStr;  // for example, update a field
            timeDisplay.text = elapsedTime;
            TimeSheet.updateTimesheetWithDuration(timesheetId, timeDisplay.text);
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
            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "White" : "#444"
            anchors.horizontalCenter: parent.horizontalCenter
            height: units.gu(2)
        }

        RowLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: units.gu(1)

            RadioButton {
                id: manualRadio
                text: "Manual"
                contentItem: Text {
                    text: manualRadio.text
                    color: theme.palette.normal.backgroundText
                    leftPadding: manualRadio.indicator.width + manualRadio.spacing
                    verticalAlignment: Text.AlignVCenter
                }

                checked: !autoMode
                onClicked: {
                    autoMode = false;
                }
            }

            RadioButton {
                id: automatedRadio
                text: "Automated"
                contentItem: Text {
                    text: automatedRadio.text
                    color: theme.palette.normal.backgroundText
                    leftPadding: automatedRadio.indicator.width + automatedRadio.spacing
                    verticalAlignment: Text.AlignVCenter
                }
                checked: autoMode
                onClicked: {
                    autoMode = true;
                }
            }
        }

        RowLayout {
            spacing: units.gu(1)
            anchors.horizontalCenter: parent.horizontalCenter

            TSButton {
                id: timeDisplay
                text: elapsedTime
                width: units.gu(10)
                enabled: !autoMode
                onClicked: {
                    myTimePicker.open(1, 0);
                }
            }
            Item {
                id: recordIconContainer
                visible: autoMode
                Layout.preferredWidth: units.gu(5)    // smaller, adaptive to row height
                Layout.preferredHeight: units.gu(5)

                Image {
                    id: recordIcon
                    anchors.fill: parent
                    anchors.margins: units.gu(0.3)

                    source: {
                        if (!autoMode)
                            return "../images/play (1).png";

                        var serviceRunning = TimerService.isRunning();
                        var servicePaused = TimerService.isPaused();
                        var activeId = TimerService.getActiveTimesheetId();

                        if (serviceRunning && activeId === timesheetId && !servicePaused) {
                            return "../images/pause.png";
                        } else {
                            return "../images/play (1).png";
                        }
                    }

                    fillMode: Image.PreserveAspectFit
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true

                    onClicked: {
                        if (timesheetId <= 0) {
                            autoRecorder.invalidtimesheet();
                            return;
                        }

                        var serviceRunning = TimerService.isRunning();
                        var servicePaused = TimerService.isPaused();
                        var activeId = TimerService.getActiveTimesheetId();

                        if (!serviceRunning || activeId !== timesheetId) {
                            if (TimeSheet.isTimesheetReadyToStartTimer(timesheetId)) {
                                var result = TimerService.start(timesheetId);
                                if (result.success) {
                                    isRecording = true;
                                    updateTimer.start();
                                } else {
                                    notifPopup.open("Timer Error", result.error, "error");
                                }
                            } else {
                                notifPopup.open("Incomplete Timesheet", "Please select a project first.", "error");
                            }
                        } else if (servicePaused) {
                            TimerService.resume();
                            isRecording = true;
                        } else {
                            TimerService.pause();
                            isRecording = false;
                        }
                    }
                }
            }

            Item {
                id: finalizeIconContainer
                visible: autoMode
                Layout.preferredWidth: units.gu(5)
                Layout.preferredHeight: units.gu(5)

                Image {
                    id: finalizeIcon
                    anchors.fill: parent
                    anchors.margins: units.gu(0.3)
                    source: "../images/stop.png"
                    fillMode: Image.PreserveAspectFit
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true

                    onPressed: finalizeIcon.opacity = 0.6
                    onReleased: finalizeIcon.opacity = 1.0
                    onCanceled: finalizeIcon.opacity = 1.0

                    onClicked: {
                        if (timesheetId <= 0) {
                            autoRecorder.invalidtimesheet();
                            return;
                        }

                        const result = TimeSheet.markTimesheetAsReadyById(timesheetId);
                        if (!result.success) {
                            notifPopup.open("Error", "Both Project and Task must be selected before finalizing", "error");
                        } else {
                            notifPopup.open("Saved", "Timesheet has been finalised successfully", "success");
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: updateTimer
        interval: 1000
        repeat: true
        running: autoMode && (TimerService.isRunning() && TimerService.getActiveTimesheetId() === timesheetId)

        onTriggered: {
            var serviceRunning = TimerService.isRunning();
            var servicePaused = TimerService.isPaused();
            var activeId = TimerService.getActiveTimesheetId();

            if (serviceRunning && activeId === timesheetId) {
                isRecording = true;
                timeDisplay.text = TimerService.getElapsedTime();
            } else {
                isRecording = false;

                var savedTime = TimeSheet.getTimesheetUnitAmount(timesheetId);
                timeDisplay.text = Utils.convertDecimalHoursToHHMM(savedTime);
            }

            elapsedTime = timeDisplay.text;
        }
    }

    Component.onCompleted: {
        if (timesheetId > 0 && timesheetId === TimerService.getActiveTimesheetId()) {
            isRecording = true;
            automode = true;
            if (autoMode)
                updateTimer.start();
        } else {
            isRecording = false;
            updateTimer.stop();
        }
    }
}
