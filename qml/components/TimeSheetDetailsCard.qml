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
import QtQuick.Layouts 1.1
import "../../models/utils.js" as Utils
import "../../models/constants.js" as AppConst
import "../../models/timer_service.js" as TimerService

ListItem {
    id: timesheetItem
    height: units.gu(12)

    property string name: ""
    property string project: ""
    property string task: ""
    property string user: ""
    property string date: ""
    property string instance: ""
    property string spentHours: "0"
    property string quadrant: "Do"
    property int recordId: -1
    property bool isFavorite: false
    property string status: ""
    property bool timer_on: false
    property bool timer_paused: false

    signal editRequested(int recordId)
    signal viewRequested(int recordId)
    signal deleteRequested(int recordId)
    signal toggleFavorite(int recordId, bool currentState)

    /* leadingActions: ListItemActions {
        actions: Action {
            iconSource: isFavorite ? "images/star-active.svg" : "images/starinactive.svg"
            onTriggered: toggleFavorite(recordId, isFavorite)
        }
    }*/

    Connections {
        target: globalTimerWidget

        onTimerStopped: {
            if (recordId === TimerService.getActiveTimesheetId()) {
                timer_on = false;
            }
        }
        onTimerStarted: {
            if (recordId === TimerService.getActiveTimesheetId()) {
                timer_on = true;
            }
        }
        onTimerPaused: {
            if (recordId === TimerService.getActiveTimesheetId()) {
                timer_paused = true;
            }
        }
        onTimerResumed: {
            if (recordId === TimerService.getActiveTimesheetId()) {
                timer_paused = false;
            }
        }
    }

    leadingActions: ListItemActions {
        actions: [
            Action {
                iconName: "delete"
                onTriggered: deleteRequested(recordId)
            }
        ]
    }

    trailingActions: ListItemActions {
        actions: [
            Action {
                iconName: "edit"
                onTriggered: editRequested(recordId)
            },
            Action {
                id: playpauseaction
                iconSource: (recordId === TimerService.getActiveTimesheetId()) ? (timer_paused ? "../images/play.png" : "../images/pause.png") : "../images/play.png"
                visible: recordId > 0
                text: "update Timesheet"
                onTriggered: {
                    if (recordId === TimerService.getActiveTimesheetId()) {
                        if (TimerService.isRunning() && !TimerService.isPaused()) {
                            // If running and not paused, pause it
                            TimerService.pause();
                        } else if (TimerService.isPaused()) {
                            // If paused, resume it
                            TimerService.start(recordId);
                        }
                    } else {
                        // Start this timesheet, pausing any other running one
                        TimerService.start(recordId);
                    }
                }
            },
            Action {
                id: startstopaction
                iconSource: "../images/stop.png"
                visible: recordId > 0
                text: "update Timesheet"
                onTriggered: {
                    if (TimerService.isRunning() && (recordId === TimerService.getActiveTimesheetId()))
                        TimerService.stop();
                }
            }
        ]
    }

    clip: true

    ListItemLayout {
        anchors.fill: parent
        // Animated dot
        Rectangle {
            id: indicator
            width: units.gu(2)
            height: units.gu(2)
            radius: units.gu(1)
            color: "#ffa500"
            anchors.left: parent.left
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

        Row {
            anchors.left: indicator.right
            anchors.right: parent.right
            spacing: units.gu(2)
            // Left Column
            Column {
                width: parent.width * 0.65
                spacing: units.gu(0.5)

                Text {
                    text: Utils.truncateText(name, 40)
                    font.pixelSize: units.gu(AppConst.FontSizes.ListHeading)
                    elide: Text.ElideRight
                    width: parent.width
                    color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "White" : "#222"
                }

                Text {
                    text: (project ? project : "No Project")
                    font.pixelSize: units.gu(AppConst.FontSizes.ListSubHeading)
                    elide: Text.ElideRight
                    color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "White" : "#222"
                }
                Text {
                    text: task
                    font.pixelSize: units.gu(AppConst.FontSizes.ListSubHeading)
                    elide: Text.ElideRight
                    color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "White" : "#222"
                }
                Text {
                    text: (user ? user : "Unknown User")
                    font.pixelSize: units.gu(AppConst.FontSizes.ListSubHeading)
                    elide: Text.ElideRight
                    color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "White" : "#222"
                }
            }

            // Right Column
            Column {
                width: parent.width * 0.25
                spacing: units.gu(0.5)
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: spentHours + " H"
                    font.pixelSize: units.gu(AppConst.FontSizes.ListSubSubHeading)
                    horizontalAlignment: Text.AlignRight
                    width: parent.width
                    color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "White" : "#222"
                }

                Text {
                    text: date
                    font.pixelSize: units.gu(AppConst.FontSizes.ListSubSubHeading)
                    horizontalAlignment: Text.AlignRight
                    width: parent.width
                    color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "White" : "#222"
                }

                EHowerIndicator {
                    quadrantKey: quadrant
                    horizontalAlignment: Text.AlignRight
                    width: parent.width
                }
            }
        }
    }

    onClicked: viewRequested(recordId)
}
