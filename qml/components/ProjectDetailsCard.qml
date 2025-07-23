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
    id: projectCard
    width: parent.width
    height: units.gu(20)

    property bool isFavorite: true
    property string projectName: ""
    property string accountName: ""
    property double allocatedHours: 0
    property double remainingHours: 0
    property string startDate: ""
    property string endDate: ""
    property string deadline: ""
    property string description: ""
    property int colorPallet: 0
    property int recordId: -1
    property int localId: -1
    property bool hasChildren: false
    property int childCount: 0
    property bool timer_on: false
    property bool timer_paused: false
    signal editRequested(int recordId)
    signal viewRequested(int recordId)
    signal timesheetRequested(int localId)

    Connections {
        target: globalTimerWidget
        onTimerStopped: {
            if (Timesheet.doesProjectIdMatchSheetInActive(recordId, TimerService.getActiveTimesheetId())) {
                timer_on = false;
            }
        }
        onTimerStarted: {
            if (Timesheet.doesProjectIdMatchSheetInActive(recordId, TimerService.getActiveTimesheetId())) {
                timer_on = true;
            }
        }
        onTimerPaused: {
            if (Timesheet.doesProjectIdMatchSheetInActive(recordId, TimerService.getActiveTimesheetId())) {
                timer_paused = true;
            }
        }
        onTimerResumed: {
            if (Timesheet.doesProjectIdMatchSheetInActive(recordId, TimerService.getActiveTimesheetId())) {
                timer_paused = false;
            }
        }
    }

    function play_pause_workflow() {
        if (Timesheet.doesProjectIdMatchSheetInActive(recordId, TimerService.getActiveTimesheetId())) {
            if (TimerService.isRunning() && !TimerService.isPaused()) {
                // If running and not paused, pause it
                TimerService.pause();
            } else if (TimerService.isPaused()) {
                // If paused, resume it
                TimerService.start(TimerService.getActiveTimesheetId());
            }
        } else {
            let result = Timesheet.createTimesheetFromProject(recordId);
            if (result.success) {
                const result_start = TimerService.start(result.id);
                if (!result_start.success) {
                    console.log("Timer start failed:", result_start.error);
                }
            } else {
                console.log("Timesheet creation failed:", result.error);
            }
        }
    }

    function stop_workflow() {
        if (Timesheet.doesProjectIdMatchSheetInActive(recordId, TimerService.getActiveTimesheetId())) {
            TimerService.stop();
        }
    }

    trailingActions: ListItemActions {
        actions: [
            Action {
                iconName: "view-on"
                onTriggered: viewRequested(localId)
            },
            Action {
                id: playpauseaction
                iconSource: timer_on ? (timer_paused ? "../images/play.png" : "../images/pause.png") : "../images/play.png"
                visible: recordId > 0
                text: "Start Timer"
                onTriggered: {
                    play_pause_workflow();
                }
            },
            Action {
                id: startstopaction
                visible: recordId > 0
                iconSource: "../images/stop.png"
                text: "Stop Timer"
                onTriggered: {
                    stop_workflow();
                }
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


        Row {
            anchors.fill: parent
            spacing: 2

            Rectangle {
                width: parent.width - units.gu(17)
                height: parent.height
                color: "transparent"
                z: 1

                Row {
                    width: parent.width
                    height: parent.height
                    spacing: units.gu(1)

                    Item {
                        width: units.gu(4)
                        height: parent.height
                        z: 2

                        Image {
                            id: starIcon
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.leftMargin: units.gu(0.5)
                            source: isFavorite ? (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "../images/star.png" : "../images/star.png") : ""
                            fillMode: Image.PreserveAspectFit
                            width: units.gu(2)
                            height: units.gu(2)
                            visible: !timer_on
                        }
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

                    Column {
                        width: parent.width - units.gu(4)
                        height: parent.height - units.gu(2)
                        spacing: 0

                        Text {
                            text: projectName !== "" ? projectName : "Unnamed Project"
                            color: hasChildren ? AppConst.Colors.Orange : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black")
                            font.pixelSize: units.gu(2)
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            clip: true
                            width: parent.width - units.gu(2)
                            // height: units.gu(5)
                        }

                        Text {
                            text: accountName !== "" ? accountName : "Local"
                            font.pixelSize: units.gu(1.6)
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
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
                            text: (childCount > 0 ? " [+" + childCount + "] Projects " : "")
                            visible: childCount > 0
                            color: hasChildren ? AppConst.Colors.Orange : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black")
                            font.pixelSize: units.gu(1.5)
                            //  horizontalAlignment: Text.AlignRight
                            width: parent.width
                        }
                    }
                }
            }

            Rectangle {
                width: units.gu(15)
                height: parent.height
                color: 'transparent'

                Column {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: units.gu(0.4)
                    width: parent.width

                    Text {
                        text: "Planned (H): " + allocatedHours
                        font.pixelSize: units.gu(1.5)
                        horizontalAlignment: Text.AlignRight
                        width: parent.width
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#bbb" : "#555"
                    }

                    Text {
                        text: "Start Date: " + (startDate !== "" ? startDate : "Not set")
                        font.pixelSize: units.gu(1.5)
                        horizontalAlignment: Text.AlignRight
                        width: parent.width
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#bbb" : "#222"
                    }

                    Text {
                        text: "End Date: " + (endDate !== "" ? endDate : "Not set")
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
}
