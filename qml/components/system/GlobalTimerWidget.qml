import QtQuick 2.7
import QtQuick.Controls 2.2
import Lomiri.Components 1.3
import "../../../models/timer_service.js" as TimerService
import "../../../models/utils.js" as Utils
import "../../features/timesheets/components" as TimesheetComponents
import ".."
import "../../../models/logger.js" as Logger

Rectangle {
    id: globalTimer
    width: Math.min(parent ? parent.width - units.gu(4) : units.gu(46), units.gu(46))
    height: units.gu(7.2)
    color: "#262626"
    border.color: "#3d3d3d"
    border.width: 1
    radius: units.gu(1.2)
    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
    z: 999

    property bool enableTimesheetTimer: true
    property string elapsedDisplay: ""
    property string activeTitle: "Active Timesheet"
    property string activeTime: "00:00:00"
    property bool isTimerRunning: false
    property bool isTimerPaused: false

    signal timerStopped
    signal timerStarted
    signal timerPaused
    signal timerResumed
    signal syncTimedOut(int accountId)
    property bool previousRunningState: false
    property bool previousPausedState: false
    property int previousTimesheetId: -1

    // Enhanced properties for sync status
    property bool isSyncing: false
    property string syncAccountName: ""
    property int syncAccountId: -1
    property bool syncSuccessful: false
    property real syncProgress: 0.0 // Progress from 0.0 to 1.0
    property bool syncFailed: false
    property string syncStatusMessage: ""

    // BackendBridge for real-time sync communication (connect to global bridge)
    property var backendBridge: null

    // Public function to immediately sync UI state with TimerService
    function refreshDisplay() {
        const currentlyRunning = enableTimesheetTimer ? TimerService.isRunning() : false;
        const currentlyPaused = enableTimesheetTimer ? TimerService.isPaused() : false;
        isTimerRunning = currentlyRunning;
        isTimerPaused = currentlyPaused;
        if (currentlyRunning) {
            var rawName = TimerService.getActiveTimesheetName();
            activeTitle = (rawName && rawName.trim() !== "") ? rawName.trim() : "Active Timesheet";
            activeTime = TimerService.getElapsedTime();
            globalTimer.visible = true;
        } else if (!isSyncing) {
            globalTimer.visible = false;
        }
    }

    // Connect to the global backend bridge when available
    Component.onCompleted: {
        // Try to find the global backend bridge
        var root = globalTimer;
        while (root.parent) {
            root = root.parent;
            if (root.backend_bridge) {
                backendBridge = root.backend_bridge;
                Logger.debug("GlobalTimerWidget", "GlobalTimer: Connected to backend bridge")
                backendBridge.messageReceived.connect(handleSyncEvent);
                break;
            }
        }
        refreshDisplay();
    }

    // Handle sync events from Python backend
    function handleSyncEvent(data) {
        if (!data || !data.event || !isSyncing)
            return;

        switch (data.event) {
        case "sync_progress":
            syncProgress = data.payload / 100.0; // Convert to 0.0-1.0 range
            updateSyncMessage();
            break;
        case "sync_message":
            syncStatusMessage = data.payload;
            break;
        case "sync_completed":
            if (data.payload === true)
                completeSyncSuccessfully();
            else
                failSync("Sync Failed ");
            break;
        case "sync_error":
            failSync("Failed " + data.payload);
            break;
        }
    }

    // Update sync message based on progress
    function updateSyncMessage() {
        if (!isSyncing)
            return;

        var progressPercent = Math.round(syncProgress * 100);

        if (progressPercent < 25) {
            syncStatusMessage = "Initializing sync...";
        } else if (progressPercent < 50) {
            syncStatusMessage = "Downloading from server...";
        } else if (progressPercent < 90) {
            syncStatusMessage = "Uploading to server...";
        } else if (progressPercent < 100) {
            syncStatusMessage = "Finalizing sync...";
        } else {
            syncStatusMessage = "Sync complete!";
        }
    }

    // Complete sync successfully
    function completeSyncSuccessfully() {
        syncSuccessful = true;
        syncFailed = false;
        syncProgress = 1.0;
        syncStatusMessage = "✅ Sync Complete!";

        // Auto-hide after 3 seconds
        autoHideTimer.interval = 3000;
        autoHideTimer.start();
    }

    // Fail sync with error message
    function failSync(errorMessage) {
        syncSuccessful = false;
        syncFailed = true;
        syncStatusMessage = "❌ " + (errorMessage || "Sync Failed");

        // Auto-hide after 5 seconds
        autoHideTimer.interval = 5000;
        autoHideTimer.start();
    }

    // Auto-hide timer for success/error states
    Timer {
        id: autoHideTimer
        running: false
        repeat: false
        onTriggered: {
            if (syncSuccessful || syncFailed) {
                stopSync();
            }
        }
    }

    // Function to start sync indication with BackendBridge integration
    function startSync(accountId, accountName) {
        syncAccountId = accountId;
        syncAccountName = accountName || "Account " + accountId;
        isSyncing = true;
        syncSuccessful = false;
        syncFailed = false;
        syncProgress = 0.0;
        syncStatusMessage = "Starting sync...";
        globalTimer.visible = true;
    }

    // Enhanced function to stop sync indication
    function stopSync() {
        autoHideTimer.stop();

        isSyncing = false;
        syncSuccessful = false;
        syncFailed = false;
        syncProgress = 0.0;
        syncAccountId = -1;
        syncAccountName = "";
        syncStatusMessage = "";

        // Hide if no timer is running either
        if (!enableTimesheetTimer || !TimerService.isRunning()) {
            globalTimer.visible = false;
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            const currentlyRunning = enableTimesheetTimer ? TimerService.isRunning() : false;
            const currentlyPaused = enableTimesheetTimer ? TimerService.isPaused() : false;
            const currentTimesheetId = TimerService.getActiveTimesheetId() !== null ? TimerService.getActiveTimesheetId() : -1;

            isTimerRunning = currentlyRunning;
            isTimerPaused = currentlyPaused;

            if (currentlyRunning) {
                var rawName = TimerService.getActiveTimesheetName();
                activeTitle = (rawName && rawName.trim() !== "") ? rawName.trim() : "Active Timesheet";
                activeTime = TimerService.getElapsedTime();
            }

            // Update display and visibility
            if (currentlyRunning || isSyncing) {
                globalTimer.visible = true;
                if (isSyncing && !currentlyRunning) {
                    if (syncFailed) {
                        globalTimer.elapsedDisplay = syncStatusMessage + " - " + syncAccountName;
                    } else if (syncSuccessful) {
                        globalTimer.elapsedDisplay = "✅ Sync Complete - " + syncAccountName;
                    } else {
                        var progressPercent = Math.round(syncProgress * 100);
                        var statusMsg = syncStatusMessage || "Syncing...";
                        globalTimer.elapsedDisplay = statusMsg + " (" + progressPercent + "%) - " + syncAccountName;
                    }
                } else if (currentlyRunning) {
                    globalTimer.elapsedDisplay = activeTime + " " + activeTitle;
                }
            } else {
                globalTimer.visible = false;
            }

            // Emit started/stopped signals
            if (currentlyRunning && (!globalTimer.previousRunningState || currentTimesheetId !== globalTimer.previousTimesheetId)) {
                globalTimer.timerStarted();
            } else if (!currentlyRunning && globalTimer.previousRunningState) {
                globalTimer.timerStopped();
            }

            // Emit paused/resumed signals
            if (currentlyPaused && !globalTimer.previousPausedState) {
                globalTimer.timerPaused();
            } else if (!currentlyPaused && globalTimer.previousPausedState) {
                globalTimer.timerResumed();
            }

            // Update previous states
            globalTimer.previousRunningState = currentlyRunning;
            globalTimer.previousTimesheetId = currentTimesheetId;
            globalTimer.previousPausedState = currentlyPaused;
        }
    }

    // Left Indicator: Pulsing Dot (for Timer) or Animated Sync Icon (for Sync)
    Item {
        id: leftIconContainer
        width: units.gu(2.4)
        height: units.gu(2.4)
        anchors.left: parent.left
        anchors.leftMargin: units.gu(1.5)
        anchors.verticalCenter: parent.verticalCenter

        // Pulsing Dot (Visible when timer is running)
        Rectangle {
            id: timerIndicatorDot
            visible: globalTimer.isTimerRunning
            anchors.centerIn: parent
            width: units.gu(1.3)
            height: units.gu(1.3)
            radius: units.gu(0.65)
            color: globalTimer.isTimerPaused ? "#AEA79F" : "#38B44A"

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: globalTimer.visible && globalTimer.isTimerRunning && !globalTimer.isTimerPaused
                NumberAnimation { from: 0.3; to: 1.0; duration: 800; easing.type: Easing.InOutQuad }
                NumberAnimation { from: 1.0; to: 0.3; duration: 800; easing.type: Easing.InOutQuad }
            }
        }

        // Rotating Sync Icon (Visible when syncing without timer)
        Image {
            id: syncIcon
            visible: globalTimer.isSyncing && !globalTimer.isTimerRunning && !globalTimer.syncSuccessful && !globalTimer.syncFailed
            anchors.fill: parent
            source: "../../images/refresh.svg"
            fillMode: Image.PreserveAspectFit

            RotationAnimation on rotation {
                loops: Animation.Infinite
                running: globalTimer.visible && globalTimer.isSyncing && !globalTimer.isTimerRunning && !globalTimer.syncSuccessful && !globalTimer.syncFailed
                from: 0
                to: 360
                duration: 1200
            }
        }

        // Success Icon
        Label {
            id: syncSuccessIcon
            visible: globalTimer.isSyncing && !globalTimer.isTimerRunning && globalTimer.syncSuccessful
            anchors.centerIn: parent
            text: "✓"
            color: "#38B44A"
            font.pixelSize: units.gu(2.2)
            font.weight: Font.Bold
        }

        // Error Icon
        Label {
            id: syncErrorIcon
            visible: globalTimer.isSyncing && !globalTimer.isTimerRunning && globalTimer.syncFailed
            anchors.centerIn: parent
            text: "!"
            color: "#DF382C"
            font.pixelSize: units.gu(2.0)
            font.weight: Font.Bold
        }
    }

    // Main Content Section (Two-Line Layout)
    Column {
        id: textContent
        anchors.left: leftIconContainer.right
        anchors.leftMargin: units.gu(1.2)
        anchors.right: (globalTimer.isTimerRunning ? buttonRow.left : (globalTimer.isSyncing ? syncRightBadge.left : parent.right))
        anchors.rightMargin: units.gu(1.2)
        anchors.verticalCenter: parent.verticalCenter
        spacing: units.gu(0.2)

        // Line 1: Timesheet / Account Title
        Label {
            id: titleLabel
            width: parent.width
            text: {
                if (globalTimer.isTimerRunning) {
                    return globalTimer.activeTitle;
                } else if (globalTimer.isSyncing) {
                    return globalTimer.syncAccountName ? ("Syncing " + globalTimer.syncAccountName) : "Cloud Sync";
                }
                return "";
            }
            color: "#FFFFFF"
            font.pixelSize: units.gu(1.7)
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        // Line 2: Timer Duration + Status (or Sync Status Message)
        Row {
            id: subtitleRow
            spacing: units.gu(0.8)
            width: parent.width

            // Digital Clock (Timer mode)
            Label {
                id: timerClock
                visible: globalTimer.isTimerRunning
                text: globalTimer.activeTime
                color: "#FFFFFF"
                font.pixelSize: units.gu(1.7)
                font.family: "Ubuntu, DejaVu Sans, sans-serif"
                font.weight: Font.Normal
                anchors.verticalCenter: parent.verticalCenter
            }

            // Clean Status Text (Timer mode)
            Label {
                id: statusText
                visible: globalTimer.isTimerRunning
                text: "• " + (globalTimer.isTimerPaused ? "Paused" : "Recording")
                color: globalTimer.isTimerPaused ? "#E95420" : "#AEA79F"
                font.pixelSize: units.gu(1.4)
                font.weight: Font.Normal
                anchors.verticalCenter: parent.verticalCenter
            }

            // Sync Status Subtitle (Sync mode)
            Label {
                id: syncSubtitle
                visible: globalTimer.isSyncing && !globalTimer.isTimerRunning
                width: parent.width
                text: {
                    if (globalTimer.syncFailed) return globalTimer.syncStatusMessage || "Sync failed";
                    if (globalTimer.syncSuccessful) return "All items up to date";
                    return globalTimer.syncStatusMessage || "Synchronizing...";
                }
                color: globalTimer.syncFailed ? "#DF382C" : (globalTimer.syncSuccessful ? "#38B44A" : "#D0CBC5")
                font.pixelSize: units.gu(1.3)
                elide: Text.ElideRight
                maximumLineCount: 1
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // Right Side Sync Status / Percentage Badge (Sync mode)
    Item {
        id: syncRightBadge
        visible: globalTimer.isSyncing && !globalTimer.isTimerRunning
        anchors.right: parent.right
        anchors.rightMargin: units.gu(1.5)
        anchors.verticalCenter: parent.verticalCenter
        width: syncProgressText.implicitWidth + units.gu(1.5)
        height: units.gu(3.2)

        Label {
            id: syncProgressText
            anchors.centerIn: parent
            text: {
                if (globalTimer.syncFailed) return "FAILED";
                if (globalTimer.syncSuccessful) return "DONE";
                return Math.round(globalTimer.syncProgress * 100) + "%";
            }
            color: globalTimer.syncFailed ? "#DF382C" : (globalTimer.syncSuccessful ? "#38B44A" : "#19B6EE")
            font.pixelSize: (globalTimer.syncFailed || globalTimer.syncSuccessful) ? units.gu(1.3) : units.gu(1.7)
            font.weight: Font.Bold
        }
    }

    // Action Buttons Container (Timer mode)
    Row {
        id: buttonRow
        anchors.right: parent.right
        anchors.rightMargin: units.gu(1.2)
        anchors.verticalCenter: parent.verticalCenter
        spacing: units.gu(1)
        visible: globalTimer.isTimerRunning

        // Pause/Resume Button
        Image {
            id: pausebutton
            width: units.gu(4.4)
            height: units.gu(4.4)
            source: globalTimer.isTimerPaused ? "../../images/play.png" : "../../images/pause.png"
            fillMode: Image.PreserveAspectFit

            MouseArea {
                anchors.fill: parent
                onPressed: pausebutton.opacity = 0.6
                onReleased: pausebutton.opacity = 1.0
                onCanceled: pausebutton.opacity = 1.0
                onClicked: {
                    if (TimerService.isPaused())
                        TimerService.start(TimerService.getActiveTimesheetId());
                    else
                        TimerService.pause();
                }
            }
        }

        // Stop Button
        Image {
            id: stopbutton
            width: units.gu(4.4)
            height: units.gu(4.4)
            source: "../../images/stop.png"
            fillMode: Image.PreserveAspectFit

            MouseArea {
                anchors.fill: parent
                onPressed: stopbutton.opacity = 0.6
                onReleased: stopbutton.opacity = 1.0
                onCanceled: stopbutton.opacity = 1.0
                onClicked: {
                    var activeTimesheetId = TimerService.getActiveTimesheetId();
                    var activeTimesheetName = TimerService.getActiveTimesheetName();
                    var elapsedTime = TimerService.getElapsedTime();

                    if (activeTimesheetId && activeTimesheetId > 0) {
                        descriptionPopup.open(activeTimesheetId, activeTimesheetName, elapsedTime);
                    } else {
                        TimerService.stop();
                    }
                }
            }
        }
    }

    // Integrated Bottom Progress Bar
    Rectangle {
        id: progressContainer
        visible: globalTimer.isSyncing
        anchors.bottom: parent.bottom
        anchors.bottomMargin: units.gu(0.5)
        anchors.left: parent.left
        anchors.leftMargin: units.gu(1.5)
        anchors.right: parent.right
        anchors.rightMargin: units.gu(1.5)
        height: units.gu(0.35)
        radius: units.gu(0.2)
        color: "#1c1c1c"
        clip: true

        Rectangle {
            id: progressIndicator
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: globalTimer.isSyncing ? (parent.width * Math.max(0.02, Math.min(1.0, globalTimer.syncProgress))) : 0
            radius: parent.radius
            color: globalTimer.syncSuccessful ? "#38B44A" : (globalTimer.syncFailed ? "#DF382C" : "#19B6EE")

            Behavior on width {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    // Property for notification function
    property var showNotification: null

    // Description popup for when timer is stopped
    TimesheetComponents.TimeSheetDescriptionPopup {
        id: descriptionPopup

        onSaved: function (description, status) {
            Logger.debug("GlobalTimerWidget", "Timesheet description saved:", description, "Status:", status)
            TimerService.stop();
        }

        onFinalized: function (success, message) {
            Logger.debug("GlobalTimerWidget", "Timesheet finalized:", success, "Message:", message)
            if (globalTimer.showNotification) {
                if (success) {
                    globalTimer.showNotification("Success", message, "success");
                } else {
                    globalTimer.showNotification("Update needed", message, "error");
                }
            }
        }

        onCancelled: {
            Logger.debug("GlobalTimerWidget", "Description popup cancelled - timer continues running")
        }
    }
}