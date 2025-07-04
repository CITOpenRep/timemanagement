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
import Lomiri.Components 1.3
import QtCharts 2.0
import QtQuick.Layouts 1.11
import Qt.labs.settings 1.0
import "../../models/constants.js" as AppConst
import "../../models/timer_service.js" as TimerService

Rectangle {
    id: autoRecorder
    width: parent.width - units.gu(2)
    height: units.gu(8)
    color: theme.palette.normal.background
    radius: units.gu(0.5)
    border.color: LomiriColors.orange
    border.width: 1
    anchors.horizontalCenter: parent.horizontalCenter

    property bool isRecording: false
    property string elapsedTime: "00:00:00"
    property int timesheetId: 0

    Timer {
        id: updateTimer
        interval: 1000
        repeat: true
        running: autoRecorder.isRecording
        onTriggered: {
            elapsedTime = TimerService.getElapsedTime();
            timeDisplay.text = elapsedTime;
        }
    }

    Label {
        id: infoLabel
        visible: timesheetId === 0
        width: parent.width
        text: "Automated time tracking\n Please click on save button to use this feature."
        wrapMode: Text.WordWrap
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
    }

    Row {
        visible: timesheetId > 0
        anchors.fill: parent
        anchors.margins: units.gu(1)
        spacing: units.gu(1)

        Label {
            id: label
            text: "Automatic Recording"
            font.bold: true
            verticalAlignment: Text.AlignVCenter
        }

        Label {
            id: timeDisplay
            text: elapsedTime
            font.bold: true
            verticalAlignment: Text.AlignVCenter
        }

        TSButton {
            id: startStopButton
            width: parent.width * 0.2
            text: autoRecorder.isRecording ? "Stop" : "Start"
            enabled: true
            anchors.verticalCenter: parent.verticalCenter
            onClicked: {
                if (!autoRecorder.isRecording) {
                    TimerService.start(timesheetId);
                    autoRecorder.isRecording = true;
                    updateTimer.start();
                } else {
                    TimerService.stop(timesheetId);
                    autoRecorder.isRecording = false;
                    updateTimer.stop();
                }
            }
        }
    }
    Component.onCompleted: {
        if (timesheetId > 0 && timesheetId === TimerService.getActiveTimesheetId()) {
            // Resume live tracking in this widget
            isRecording = true;
            elapsedTime = TimerService.getFormattedElapsedTime();
            updateTimer.start();
        } else {
            // Not the currently active timer
            isRecording = false;
            elapsedTime = "00:00:00";
            updateTimer.stop();
        }
    }
}
