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
import QtQuick 2.12
import QtQuick.Controls 2.2
import "../../models/constants.js" as AppConst
import "../../models/utils.js" as Utils
import "../../models/timesheet.js" as Timesheet
import "../../models/timer_service.js" as TimerService
import Lomiri.Components 1.3
import QtQuick.Layouts 1.1

ListItem {
    id: taskCard
    width: parent.width
    height: units.gu(28)
    property int screenWidth: parent.width
    property bool isFavorite: true
    property string taskName: ""
    property string projectName: ""
    property double allocatedHours: 0
    property double spentHours: 0
    property string deadline: ""
    property string startDate: ""
    property string endDate: ""
    property string description: ""
    property int colorPallet: 0
    property int localId: -1
    property int recordId: -1
    property bool hasChildren: false
    property int childCount: 0
    property bool timer_on: false
    property bool timer_paused: false

    signal editRequested(int localId)
    signal deleteRequested(int localId)
    signal viewRequested(int localId)
    signal timesheetRequested(int localId)

    NotificationPopup {
        id: notifPopup
        width: units.gu(80)
        height: units.gu(80)
    }

    Connections {
        target: globalTimerWidget

        onTimerStopped: {
            if (Timesheet.doesTaskIdMatchSheetInActive(recordId, TimerService.getActiveTimesheetId())) {
                timer_on = false;
            }
        }
        onTimerStarted: {
            if (Timesheet.doesTaskIdMatchSheetInActive(recordId, TimerService.getActiveTimesheetId())) {
                timer_on = true;
            }
        }
        onTimerPaused: {
            if (Timesheet.doesTaskIdMatchSheetInActive(recordId, TimerService.getActiveTimesheetId())) {
                timer_paused = true;
            }
        }
        onTimerResumed: {
            if (Timesheet.doesTaskIdMatchSheetInActive(recordId, TimerService.getActiveTimesheetId())) {
                timer_paused = false;
            }
        }
    }

    function play_pause_workflow() {
        if (Timesheet.doesTaskIdMatchSheetInActive(recordId, TimerService.getActiveTimesheetId())) {
            if (TimerService.isRunning() && !TimerService.isPaused()) {
                // If running and not paused, pause it
                TimerService.pause();
            } else if (TimerService.isPaused()) {
                // If paused, resume it
                TimerService.start(TimerService.getActiveTimesheetId());
            }
        } else {
            let result = Timesheet.createTimesheetFromTask(recordId);
            if (result.success) {
                const result_start = TimerService.start(result.id);
                if (!result_start.success) {
                    notifPopup.open("Error", result_start.error, "error");
                }
                //do we need to show a success popup ? why?
            } else {
                console.error(result.error);
                notifPopup.open("Error", result.error, "error");
            }
        }
    }

    function stop_workflow() {
        if (Timesheet.doesTaskIdMatchSheetInActive(recordId, TimerService.getActiveTimesheetId()))
            TimerService.stop();
    }

    trailingActions: ListItemActions {
        actions: [
            Action {
                iconName: "view-on"
                onTriggered: viewRequested(localId)
            },
            Action {
                iconName: "edit"
                onTriggered: editRequested(localId)
            },
            Action {
                id: playpauseaction
                iconSource: (Timesheet.doesTaskIdMatchSheetInActive(recordId, TimerService.getActiveTimesheetId())) ? (timer_paused ? "../images/play.png" : "../images/pause.png") : "../images/play.png"
                visible: recordId > 0
                text: "update Timesheet"
                onTriggered: {
                    play_pause_workflow();
                }
            },
            Action {
                id: startstopaction
                visible: recordId > 0
                iconSource: "../images/stop.png"
                text: "update Timesheet"
                onTriggered: {
                    stop_workflow();
                }
            }
        ]
    }
    leadingActions: ListItemActions {
        actions: [
            Action {
                iconName: "delete"
                onTriggered: deleteRequested(localId)
            }
        ]
    }

    Rectangle {
        anchors.fill: parent
        border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#444" : "#dcdcdc"
        radius: units.gu(0.2)
        anchors.leftMargin: units.gu(0.2)
        anchors.rightMargin: units.gu(0.2)
        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#111" : "#fff"
        // subtle color fade on the left
        Rectangle {
            width: parent.width * 0.025
            height: parent.height
            anchors.left: parent.left
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0.0
                    color: Utils.getColorFromOdooIndex(colorPallet)
                }
                GradientStop {
                    position: 1.0
                    color: Qt.rgba(Utils.getColorFromOdooIndex(colorPallet).r, Utils.getColorFromOdooIndex(colorPallet).g, Utils.getColorFromOdooIndex(colorPallet).b, 0.0)
                }
            }
        }
        Rectangle {
            id: progressindicator
            anchors.bottom: parent.bottom
            width: parent.width
            height: units.gu(2)
            visible: !hasChildren //if there are tasks with child tasks then we will hide this view
            color: "transparent"

            // Show progress bar only if planned hours > 0 and spentHours > 0
            TSProgressbar {
                id: determinateBar
                anchors.fill: parent
                anchors.margins: units.gu(0.5)
                visible: allocatedHours > 0 && spentHours > 0
                minimumValue: 0
                maximumValue: parseInt(allocatedHours)
                value: parseInt(Math.min(spentHours, allocatedHours))
            }
            // Case: spentHours > 0 but planned = 0 → warning
            Label {
                anchors.centerIn: parent
                //visible: allocatedHours === 0 && spentHours > 0
                visible: false
                text: "Unable to track progress – no planned hours"
                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#ff6666" : "#e53935"
                font.pixelSize: units.gu(1.5)
                anchors.bottomMargin: units.gu(.5)
            }

            // Case: spentHours = 0 → no progress
            Label {
                anchors.centerIn: parent
               // visible: spentHours === 0
               visible: false
                text: "No progress yet"
                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#ff6666" : "#e53935"
                font.pixelSize: units.gu(1.5)
                anchors.bottomMargin: units.gu(.5)
            }
        }

        Row {
            anchors.top: parent.top
            anchors.bottom: progressindicator.top
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 2

            Rectangle {
                width: parent.width - units.gu(20)
                height: parent.height
                color: "transparent"

                Row {
                    width: parent.width
                    height: parent.height
                    spacing: units.gu(0.4)

                    // Wrap gray block in a Column to align it to the bottom
                    Column {
                        width: units.gu(4)
                        height: parent.height
                        spacing: 0

                        // Filler pushes gray to the bottom
                        Item {
                            Layout.fillHeight: true
                        }

                        Item {
                            width: units.gu(4)
                            height: parent.height
                            z: 2

                            Image {
                                id: starIcon
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                                source: isFavorite ? "../images/star.png" : ""
                                fillMode: Image.PreserveAspectFit
                                width: units.gu(2)
                                height: units.gu(2)
                            }
                        }
                        // Animated dot if there is a active time sheet on it
                        Rectangle {
                            id: indicator
                            width: units.gu(2)
                            height: units.gu(2)
                            radius: units.gu(1)
                            color: "#ffa500"
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            visible: timer_on
                            SequentialAnimation on opacity {
                                loops: Animation.Infinite
                                running: indicator.visible
                                NumberAnimation {
                                    from: 0.3
                                    to: 1
                                    duration: 800
                                    easing.type: Easing.InOutQuad
                                }
                                NumberAnimation {
                                    from: 1
                                    to: 0.3
                                    duration: 800
                                    easing.type: Easing.InOutQuad
                                }
                            }
                        }
                    }

                    // 🟨 Yellow + 🟩 Green
                    Column {
                        width: parent.width - units.gu(4)
                        height: parent.height - units.gu(2)
                        spacing: 0

                        Text {
                            id: projectTitleText
                            text: (taskName !== "" ? truncateText(taskName, 300) : "Unnamed Task")
                            color: hasChildren ? AppConst.Colors.Orange : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black")
                            font.pixelSize: units.gu(2)
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            clip: true
                            width: parent.width - units.gu(2)
                        }

                        Text {
                            id: yellowBlock
                            text: projectName
                            font.pixelSize: units.gu(1.6)
                            wrapMode: Text.NoWrap
                            elide: Text.ElideRight
                            width: parent.width - units.gu(2)
                            height: units.gu(2)
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#bbb" : "#222"
                        }

                        Label {
                            id: details
                            text: "Details"
                            width: parent.width - units.gu(2)
                            font.pixelSize: units.gu(1.6)
                            height: units.gu(3)
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#80bfff" : "blue"
                            font.underline: true
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    viewRequested(localId);
                                }
                            }
                        }

                        Text {
                            text: (childCount > 0 ? " [+" + childCount + "] Tasks" : "")
                            visible: childCount > 0
                            color: hasChildren ? AppConst.Colors.Orange : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black")
                            font.pixelSize: units.gu(1.5)
                            //  horizontalAlignment: Text.AlignRight
                            width: parent.width
                        }
                    }
                }
            }

            // space for date and time
            Rectangle {
                width: units.gu(19)
                height: parent.height
                color: 'transparent'
                Column {
                    anchors.right: parent.right
                    anchors.rightMargin: units.gu(2)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: units.gu(0.4)
                    width: parent.width
                    Text {
                        text: "Planned (H): " + (allocatedHours !== 0 ? allocatedHours : "N/A")
                        font.pixelSize: units.gu(1.5)
                        horizontalAlignment: Text.AlignRight
                        width: parent.width
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#bbb" : "#555"
                    }
                    Text {
                        text: "Start Date: " + (startDate !== "" ? toDateOnly(startDate) : "Not set")
                        font.pixelSize: units.gu(1.5)
                        horizontalAlignment: Text.AlignRight
                        width: parent.width
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#bbb" : "#222"
                    }
                    Text {
                        text: "End Date: " + (endDate !== "" ? toDateOnly(endDate) : "Not set")
                        font.pixelSize: units.gu(1.5)
                        horizontalAlignment: Text.AlignRight
                        width: parent.width
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#bbb" : "#222"
                    }

                    Text {
                        text: Utils.getTimeStatusInText(endDate)
                        font.pixelSize: units.gu(1.5)
                        horizontalAlignment: Text.AlignRight
                        width: parent.width
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#ff6666" : "#e53935"
                    }
                }
            }
        }
    }
    function truncateText(text, maxLength) {
        if (text.length > maxLength) {
            return text.slice(0, maxLength) + '...';
        }
        return text;
    }
    function toDateOnly(datetimeStr) {
        // Assumes input like "2025-06-06 15:30:00"
        if (!datetimeStr || typeof datetimeStr !== "string")
            return "";

        // Split by space to remove time
        return datetimeStr.split(" ")[0];
    }

    Component.onCompleted: {
        taskCard.timer_on = Timesheet.doesTaskIdMatchSheetInActive(recordId, TimerService.activeTimesheetId);
    }
}
