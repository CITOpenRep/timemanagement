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
import "../../models/task.js" as Task
import Lomiri.Components 1.3
import QtQuick.Layouts 1.1

ListItem {
    id: taskCard
    width: parent.width
    height: units.gu(15)
    property int screenWidth: parent.width
    property int priority: 0 // 0-3 priority levels (0 = lowest, 3 = highest)
    property bool isFavorite: priority > 0 // Backward compatibility, true if priority > 0
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
    property int stage: -1
    property bool hasChildren: false
    property int childCount: 0
    property bool timer_on: false
    property bool timer_paused: false
    property bool starInteractionActive: false

    signal editRequested(int localId)
    signal deleteRequested(int localId)
    signal viewRequested(int localId)
    signal timesheetRequested(int localId)
    signal taskUpdated(int localId)

    NotificationPopup {
        id: notifPopup
        width: units.gu(80)
        height: units.gu(80)
    }

    CustomDatePicker {
        id: dateSelector
        titleText: "Reschedule Task"
        mode: "next"
        currentDate: endDate || Utils.getToday()

        onDateSelected: {
            updateTaskEndDate(date);
        }
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

    function updateTaskEndDate(newDate) {
        try {
            // Get current task details to preserve existing data
            var taskDetails = Task.getTaskDetails(localId);
            if (!taskDetails || !taskDetails.id) {
                throw "Task not found";
            }

            // Prepare data for saveOrUpdateTask function
            var updateData = {
                record_id: localId  // This tells saveOrUpdateTask to UPDATE
                ,
                accountId: taskDetails.account_id,
                name: taskDetails.name,
                projectId: taskDetails.project_id,
                parentId: taskDetails.parent_id,
                plannedHours: taskDetails.initial_planned_hours,
                priority: taskDetails.priority || "0" // Priority field as string (0-3) to match Odoo
                ,
                description: taskDetails.description,
                assigneeUserId: taskDetails.user_id,
                subProjectId: taskDetails.sub_project_id,
                startDate: taskDetails.start_date,
                endDate: newDate  // This is what we're updating
                ,
                deadline: taskDetails.deadline,
                status: "updated"
            };

            // Update the task in the database
            var result = Task.saveOrUpdateTask(updateData);

            if (result.success) {
                // Update the endDate property for UI feedback
                endDate = newDate;

                // Emit signal to notify parent components that task was updated
                taskUpdated(localId);

                // Show success notification
                notifPopup.open("Success", "Task Rescheduled to " + Utils.formatDate(new Date(newDate)), "success");
            } else {
                throw result.error || "Update failed";
            }
        } catch (error) {
            console.error("Failed to update task end date:", error);
            notifPopup.open("Error", "Failed to update end date: " + error, "error");
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
            },
            Action {
                iconName: "reload"
                onTriggered: {
                    // Open date selector popup
                    dateSelector.open();
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
        Rectangle {
            id: progressindicator
            anchors.bottom: parent.bottom
            width: parent.width
            height: units.gu(2)
            //  visible: !hasChildren //if there are tasks with child tasks then we will hide this view
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
                        spacing: units.gu(0.2)

                        Text {
                            id: projectTitleText
                            text: (taskName !== "" ? hasChildren ? truncateText(taskName, 20) : truncateText(taskName, 30) : "Unnamed Task")
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

                        // Priority Stars replacing the Details label
                        Item {
                            width: parent.width - units.gu(2)
                            height: units.gu(3)

                            Row {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: units.gu(0.2)

                                // First row - 1 star (top of pyramid)
                                Repeater {
                                    model: 3 // Maximum of 3 stars

                                    Image {
                                        source: index < priority ? "../images/star.png" : "../images/star-inactive.png"
                                        fillMode: Image.PreserveAspectFit
                                        width: units.gu(1.5)
                                        height: units.gu(1.5)
                                        z: 100  // Ensure it's on top

                                        MouseArea {
                                            anchors.fill: parent
                                            z: 1000  // Much higher z-index
                                            propagateComposedEvents: false
                                            preventStealing: true
                                            onPressed: {
                                                starInteractionActive = true;
                                                mouse.accepted = true;
                                            }
                                            onClicked: {
                                                mouse.accepted = true;

                                                var newPriority = (index + 1 === priority) ? priority - 1 : index + 1;

                                                var result = Task.setTaskPriority(localId, newPriority, "updated");

                                                if (result.success) {
                                                    priority = newPriority;
                                                } else {
                                                    console.warn("⚠️ Failed to set task priority:", result.message);
                                                }

                                                starInteractionActive = false;
                                            }

                                            onReleased: {
                                                starInteractionActive = false;
                                                mouse.accepted = true;
                                            }
                                            onDoubleClicked: {
                                                mouse.accepted = true;
                                            }
                                        }
                                    }
                                }

                                // // Second row - 2 stars (bottom of pyramid)
                                // Row {
                                //     spacing: units.gu(0.3)

                                //     // Left star (priority level 2)
                                //     Image {
                                //         source: 1 < priority ? "../images/star.png" : "../images/star-inactive.png"
                                //         fillMode: Image.PreserveAspectFit
                                //         width: units.gu(1.2)
                                //         height: units.gu(1.2)

                                //         MouseArea {
                                //             anchors.fill: parent
                                //             onClicked: {
                                //                 mouse.accepted = true;

                                //                 var newPriority = (2 === priority) ? 1 : 2;
                                //                 var result = Task.setTaskPriority(localId, newPriority, "updated");

                                //                 if (result.success) {
                                //                     priority = newPriority;
                                //                     console.log("✅ Task priority set to", priority, ":", result.message);
                                //                 } else {
                                //                     console.warn("⚠️ Failed to set task priority:", result.message);
                                //                 }
                                //             }
                                //         }
                                //     }

                                //     // Right star (priority level 3)
                                //     Image {
                                //         source: 2 < priority ? "../images/star.png" : "../images/star-inactive.png"
                                //         fillMode: Image.PreserveAspectFit
                                //         width: units.gu(1.2)
                                //         height: units.gu(1.2)

                                //         MouseArea {
                                //             anchors.fill: parent
                                //             onClicked: {
                                //                 mouse.accepted = true;

                                //                 var newPriority = (3 === priority) ? 2 : 3;
                                //                 var result = Task.setTaskPriority(localId, newPriority, "updated");

                                //                 if (result.success) {
                                //                     priority = newPriority;
                                //                     console.log("✅ Task priority set to", priority, ":", result.message);
                                //                 } else {
                                //                     console.warn("⚠️ Failed to set task priority:", result.message);
                                //                 }
                                //             }
                                //         }
                                //     }
                                // }
                            }

                            // View Details text on the right side
                            // Text {
                            //     text: "View Details"
                            //     anchors.right: parent.right
                            //     anchors.verticalCenter: parent.verticalCenter
                            //     font.pixelSize: units.gu(1.4)
                            //     color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#80bfff" : "blue"
                            //     font.underline: true

                            //     MouseArea {
                            //         anchors.fill: parent
                            //         onClicked: {
                            //             mouse.accepted = true; // Prevent event propagation to parent MouseArea
                            //             viewRequested(localId);
                            //         }
                            //     }
                            // }
                        }

                        Text {
                            text: (childCount > 0 ? " [+" + childCount + "] Tasks" : "")
                            visible: childCount > 0
                            color: hasChildren ? AppConst.Colors.Orange : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black")
                            font.pixelSize: units.gu(1.5)
                            //  horizontalAlignment: Text.AlignRight
                            width: parent.width
                        }

                        Rectangle {
                            color: Task.getTaskStageName(stage).toLowerCase() === "completed" || Task.getTaskStageName(stage).toLowerCase() === "finished" || Task.getTaskStageName(stage).toLowerCase() === "closed" || Task.getTaskStageName(stage).toLowerCase() === "verified" || Task.getTaskStageName(stage).toLowerCase() === "done" ? "green" : AppConst.Colors.Orange
                            width: parent.width / 2
                            height: units.gu(3)

                            Text {
                                anchors.centerIn: parent
                                text: Task.getTaskStageName(stage)
                                color: "white"
                                font.pixelSize: units.gu(1.5)
                                font.bold: true
                            }
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
                        text: Utils.getTimeStatusInText(deadline)
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

        // If we have a localId, get the task details to set the priority
        if (localId > 0) {
            var taskDetails = Task.getTaskDetails(localId);
            if (taskDetails && taskDetails.id) {
                // Convert string priority to numeric for UI (0-3)
                taskCard.priority = Math.max(0, Math.min(3, parseInt(taskDetails.priority || "0")));
                // Update isFavorite for backward compatibility
                taskCard.isFavorite = taskCard.priority > 0;
            }
        } else if (isFavorite) {
            // If isFavorite was set but priority wasn't (for backward compatibility)
            taskCard.priority = isFavorite ? 1 : 0;
        }
    }
}
