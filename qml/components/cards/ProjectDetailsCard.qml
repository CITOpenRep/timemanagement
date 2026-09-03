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
import "../../../models/constants.js" as AppConst
import "../../../models/utils.js" as Utils
import "../../../models/timesheet.js" as Timesheet
import "../../../models/timer_service.js" as TimerService
import "../../../models/project.js" as Project
import Lomiri.Components 1.3
import QtQuick.Layouts 1.1
import ".."

ListItem {
    id: projectCard
    width: parent ? parent.width : units.gu(40)
    height: units.gu(8.8)
    divider.visible: false
    color: "transparent"
    highlightColor: "transparent"

    readonly property bool isDark: theme.name === "Ubuntu.Components.Themes.SuruDark"
    readonly property color bgColor: isDark ? "#121212" : "#ffffff"
    readonly property color bgPressedColor: isDark ? "#222222" : "#f5f5f5"
    readonly property color dividerColor: isDark ? "#2c2c2e" : "#e5e7eb"
    readonly property color baseTextColor: isDark ? "#f3f4f6" : "#111827"
    readonly property color subTextColor: isDark ? "#9ca3af" : "#6b7280"

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
    property int accountId: -1
    property bool hasChildren: false
    property int childCount: 0
    property int stage: 0
    property int taskCount: 0
    property bool timer_on: false
    property bool timer_paused: false
    property bool hasDraft: false
    signal editRequested(int recordId)
    signal viewRequested(int recordId)
    signal timesheetRequested(int localId)
    signal navigationRequested(int projectId, int accountId, string projectName)

    property string stageName: (stage && stage > 0) ? (Project.getProjectStageName(stage) || "") : ""
    property bool isStageDone: {
        if (!stageName) return false;
        var lower = stageName.toLowerCase();
        return lower === "completed" || lower === "finished" || lower === "closed" || lower === "verified" || lower === "done";
    }

    property string timeStatus: Utils.getTimeStatusInText(deadline || endDate)
    property bool hasValidTimeStatus: timeStatus !== "N/A" && timeStatus !== "Invalid"
    property bool isOverdue: timeStatus.indexOf("overdue") !== -1
    property bool isDueToday: timeStatus === "Due today"

    property string descriptionSnippet: {
        if (!description) return "";
        var str = String(description).trim();
        if (str === "" || str === "0" || str === "false" || str === "null" || str === "undefined") return "";
        var stripped = Utils.stripHtmlTags ? Utils.stripHtmlTags(str) : str;
        var cleaned = Utils.cleanText ? Utils.cleanText(stripped) : stripped;
        cleaned = cleaned.trim();
        if (cleaned === "" || cleaned === "0" || cleaned === "false") return "";
        return cleaned;
    }

    property string dateRangeFormatted: {
        if (!startDate && !endDate) return "";
        var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        if (startDate && endDate) {
            var s = new Date(startDate);
            var e = new Date(endDate);
            if (!isNaN(s.getTime()) && !isNaN(e.getTime())) {
                if (s.getFullYear() === e.getFullYear()) {
                    return months[s.getMonth()] + " " + s.getDate() + " – " + months[e.getMonth()] + " " + e.getDate() + ", " + e.getFullYear();
                } else {
                    return months[s.getMonth()] + " " + s.getDate() + ", " + s.getFullYear() + " – " + months[e.getMonth()] + " " + e.getDate() + ", " + e.getFullYear();
                }
            }
            return startDate + " – " + endDate;
        }
        if (endDate) {
            var eOnly = new Date(endDate);
            if (!isNaN(eOnly.getTime())) {
                return i18n.dtr("ubtms", "Due ") + months[eOnly.getMonth()] + " " + eOnly.getDate() + ", " + eOnly.getFullYear();
            }
            return i18n.dtr("ubtms", "Due ") + endDate;
        }
        return i18n.dtr("ubtms", "Starts ") + startDate;
    }

    property string plannedHoursText: {
        if (allocatedHours === undefined || allocatedHours === null) return "";
        var num = parseFloat(allocatedHours);
        if (!isNaN(num) && num > 0) {
            var rounded = Math.round(num * 10) / 10;
            return rounded + "h planned";
        }
        return "";
    }

    property string formattedAccount: {
        var name = accountName !== "" ? accountName : "Local";
        return name.toUpperCase();
    }

    property string remainingSubtitle: {
        var parts = [];

        // 1. If no urgency status, show date range
        if (!hasValidTimeStatus && dateRangeFormatted !== "") {
            parts.push(dateRangeFormatted);
        }

        // 2. Tasks count
        if (taskCount > 0) {
            parts.push(taskCount + (taskCount === 1 ? " task" : " tasks"));
        }

        // 3. Planned hours
        if (plannedHoursText !== "") {
            parts.push(plannedHoursText);
        }

        // 4. Subprojects count
        if (hasChildren && childCount > 0) {
            parts.push(childCount + (childCount === 1 ? " subproject" : " subprojects"));
        }

        // 5. Description preview
        if (descriptionSnippet !== "") {
            parts.push(descriptionSnippet);
        }

        return parts.join("  •  ");
    }

    property int effectiveProjectId: (projectCard.accountId === 0 || recordId <= 0) ? localId : recordId

    Connections {
        target: globalTimerWidget
        onTimerStopped: {
            timer_on = false;
            timer_paused = false;
        }
        onTimerStarted: {
            if (Timesheet.doesProjectIdMatchSheetInActive(effectiveProjectId, TimerService.getActiveTimesheetId())) {
                timer_on = true;
            }
        }
        onTimerPaused: {
            if (Timesheet.doesProjectIdMatchSheetInActive(effectiveProjectId, TimerService.getActiveTimesheetId())) {
                timer_paused = true;
            }
        }
        onTimerResumed: {
            if (Timesheet.doesProjectIdMatchSheetInActive(effectiveProjectId, TimerService.getActiveTimesheetId())) {
                timer_paused = false;
            }
        }
    }

    Component.onCompleted: {
        if (TimerService.isRunning() && Timesheet.doesProjectIdMatchSheetInActive(effectiveProjectId, TimerService.getActiveTimesheetId())) {
            timer_on = true;
            timer_paused = TimerService.isPaused();
        }
    }

    function play_pause_workflow() {
        if (Timesheet.doesProjectIdMatchSheetInActive(effectiveProjectId, TimerService.getActiveTimesheetId())) {
            if (TimerService.isRunning() && !TimerService.isPaused()) {
                TimerService.pause();
            } else if (TimerService.isPaused()) {
                TimerService.start(TimerService.getActiveTimesheetId());
            }
        } else {
            let result = Timesheet.createTimesheetFromProject(effectiveProjectId);
            if (result.success) {
                const result_start = TimerService.start(result.id);
                if (!result_start.success) {
                    console.warn("Timer start failed:", result_start.error);
                }
            } else {
                console.warn("Timesheet creation failed:", result.error);
            }
        }
    }

    function stop_workflow() {
        var activeId = TimerService.getActiveTimesheetId();
        if (Timesheet.doesProjectIdMatchSheetInActive(effectiveProjectId, activeId)) {
            TimerService.stop();
            if (projectCard.accountId === 0) {
                Timesheet.markTimesheetAsSavedById(activeId);
            }
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
                iconSource: timer_on ? (timer_paused ? "../../images/play.png" : "../../images/pause.png") : "../../images/play.png"
                visible: (projectCard.accountId === 0 && localId > 0) || (projectCard.accountId > 0 && recordId > 0)
                text: "Start Timer"
                onTriggered: {
                    play_pause_workflow();
                }
            },
            Action {
                id: startstopaction
                visible: (projectCard.accountId === 0 && localId > 0) || (projectCard.accountId > 0 && recordId > 0)
                iconSource: "../../images/stop.png"
                text: i18n.dtr("ubtms", "Stop Timer")
                onTriggered: {
                    stop_workflow();
                }
            }
        ]
    }

    Rectangle {
        id: itemBackground
        anchors.fill: parent
        color: itemMouseArea.pressed ? projectCard.bgPressedColor : projectCard.bgColor

        Behavior on color {
            ColorAnimation { duration: 100 }
        }

        // Left accent capsule bar for project color (Taste skill: tactile floating capsule)
        Rectangle {
            id: accentBar
            anchors.left: parent.left
            anchors.leftMargin: units.gu(0.35)
            anchors.verticalCenter: parent.verticalCenter
            width: units.gu(0.4)
            height: parent.height - units.gu(3.2)
            radius: units.gu(0.2)
            color: Utils.getColorFromOdooIndex(colorPallet)
        }

        // Card tap area
        MouseArea {
            id: itemMouseArea
            anchors.fill: parent
            z: 1
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (hasChildren) {
                    var navId = (projectCard.accountId === 0 || recordId <= 0) ? localId : recordId;
                    navigationRequested(navId, projectCard.accountId || 0, projectName);
                } else {
                    viewRequested(localId);
                }
            }
        }

        // Left icon container: Favorite Star / Timer active indicator
        // Perfectly top-anchored and aligned with Title row (height: 2.8 GU)
        Item {
            id: leftIconArea
            anchors.left: parent.left
            anchors.leftMargin: units.gu(1.6)
            anchors.top: parent.top
            anchors.topMargin: units.gu(1.5)
            width: units.gu(3.4)
            height: units.gu(2.8)
            z: 10

            Image {
                id: starIcon
                anchors.centerIn: parent
                source: isFavorite ? "../../images/star.png" : "../../images/star-inactive.png"
                fillMode: Image.PreserveAspectFit
                width: units.gu(2.4)
                height: units.gu(2.4)
                visible: !timer_on
            }

            Rectangle {
                id: indicator
                width: units.gu(2.0)
                height: units.gu(2.0)
                radius: units.gu(1.0)
                color: "#ffa500"
                anchors.centerIn: parent
                visible: timer_on

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: indicator.visible
                    NumberAnimation { from: 0.3; to: 1.0; duration: 800; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 1.0; to: 0.3; duration: 800; easing.type: Easing.InOutQuad }
                }
            }

            // Expanded tap target for easy one-handed thumb toggle
            MouseArea {
                anchors.fill: parent
                anchors.margins: -units.gu(0.8)
                enabled: !timer_on
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    mouse.accepted = true;
                    var newFavoriteState = !isFavorite;
                    var result = Project.toggleProjectFavorite(localId, newFavoriteState, "updated");
                    if (result.success) {
                        isFavorite = newFavoriteState;
                        starIcon.source = isFavorite ? "../../images/star.png" : "../../images/star-inactive.png";
                    } else {
                        console.warn("Failed to toggle project favorite:", result.message);
                    }
                }
            }
        }

        // Right content column: Top-anchored at 1.5 GU with 8.8 GU card height
        Column {
            id: contentColumn
            anchors.left: leftIconArea.right
            anchors.leftMargin: units.gu(1.2)
            anchors.right: parent.right
            anchors.rightMargin: units.gu(1.8)
            anchors.top: parent.top
            anchors.topMargin: units.gu(1.5)
            spacing: units.gu(0.7)
            z: 5

            // ROW 1: Header (Title, Draft Badge, Stage Pill, Chevron)
            Row {
                id: titleRow
                width: parent.width
                height: units.gu(2.8)
                spacing: units.gu(0.8)

                Text {
                    id: titleText
                    text: projectName !== "" ? projectName : i18n.dtr("ubtms", "Unnamed Project")
                    color: hasChildren ? AppConst.Colors.Orange : projectCard.baseTextColor
                    font.pixelSize: units.gu(1.85)
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    width: parent.width - headerRightRow.width - parent.spacing
                    anchors.verticalCenter: parent.verticalCenter
                }

                Row {
                    id: headerRightRow
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: units.gu(0.6)

                    // Draft indicator badge
                    Rectangle {
                        visible: hasDraft
                        height: units.gu(2.2)
                        width: draftLabel.width + units.gu(1.2)
                        radius: height / 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: projectCard.isDark ? "#312010" : "#fff7ed"
                        border.color: "#fb923c"
                        border.width: 1

                        Text {
                            id: draftLabel
                            text: i18n.dtr("ubtms", "DRAFT")
                            font.pixelSize: units.gu(1.05)
                            font.bold: true
                            color: "#ea580c"
                            anchors.centerIn: parent
                        }
                    }

                    // Stage pill with high-contrast styling for high-DPI
                    Rectangle {
                        visible: stageName !== ""
                        height: units.gu(2.5)
                        width: stageText.width + units.gu(1.6)
                        radius: height / 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: isStageDone ? (projectCard.isDark ? "#064e3b" : "#ecfdf5")
                             : (projectCard.isDark ? "#1e293b" : "#f1f5f9")
                        border.color: isStageDone ? (projectCard.isDark ? "#059669" : "#a7f3d0")
                             : (projectCard.isDark ? "#334155" : "#cbd5e1")
                        border.width: 1

                        Text {
                            id: stageText
                            text: stageName
                            font.pixelSize: units.gu(1.2)
                            font.bold: true
                            anchors.centerIn: parent
                            color: isStageDone ? (projectCard.isDark ? "#6ee7b7" : "#047857")
                                 : (projectCard.isDark ? "#cbd5e1" : "#475569")
                        }
                    }

                    // Progression chevron for projects with subprojects (like SettingsListItem)
                    Item {
                        visible: hasChildren
                        width: units.gu(1.6)
                        height: parent.height

                        Text {
                            anchors.centerIn: parent
                            text: "›"
                            font.pixelSize: units.gu(2.4)
                            color: projectCard.isDark ? "#888888" : "#c7c7cc"
                        }
                    }
                }
            }

            // ROW 2: Subtitle (Workspace • Urgency • Tasks • Subprojects • Description)
            Row {
                id: subtitleRow
                width: parent.width
                height: units.gu(2.3)
                spacing: units.gu(0.6)

                // Formatted uppercase account name (e.g. "CIT")
                Text {
                    id: accountLabel
                    text: formattedAccount
                    font.pixelSize: units.gu(1.3)
                    font.bold: true
                    color: projectCard.isDark ? "#a1a1aa" : "#475569"
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Urgency status indicator & text
                Row {
                    id: urgencyRow
                    visible: hasValidTimeStatus
                    spacing: units.gu(0.35)
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text: "•"
                        font.pixelSize: units.gu(1.25)
                        color: projectCard.isDark ? "#4b5563" : "#cbd5e1"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Icon {
                        name: isOverdue ? "dialog-warning" : "appointment"
                        width: units.gu(1.3)
                        height: units.gu(1.3)
                        color: isOverdue ? (projectCard.isDark ? "#f87171" : "#dc2626")
                             : (isDueToday ? (projectCard.isDark ? "#fbbf24" : "#d97706")
                             : (projectCard.isDark ? "#4ade80" : "#16a34a"))
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: timeStatus
                        font.pixelSize: units.gu(1.25)
                        font.bold: isOverdue || isDueToday
                        color: isOverdue ? (projectCard.isDark ? "#f87171" : "#dc2626")
                             : (isDueToday ? (projectCard.isDark ? "#fbbf24" : "#d97706")
                             : (projectCard.isDark ? "#4ade80" : "#16a34a"))
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // Separator dot before remaining metadata
                Text {
                    id: sepDot
                    visible: remainingSubtitle !== ""
                    text: "•"
                    font.pixelSize: units.gu(1.25)
                    color: projectCard.isDark ? "#4b5563" : "#cbd5e1"
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Remaining metadata (tasks, hours, subprojects, description)
                Text {
                    id: remainingText
                    visible: remainingSubtitle !== ""
                    text: remainingSubtitle
                    font.pixelSize: units.gu(1.25)
                    color: projectCard.subTextColor
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    width: Math.max(units.gu(5), parent.width - accountLabel.width - (urgencyRow.visible ? urgencyRow.width + parent.spacing : 0) - (sepDot.visible ? sepDot.width + parent.spacing : 0) - parent.spacing)
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // Clean bottom divider line matching Settings / MenuPage (indented past star icon area)
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: units.gu(6.2)
            height: units.dp(1)
            color: projectCard.dividerColor
        }
    }
}
