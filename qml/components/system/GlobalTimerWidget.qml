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
    color: "#1e222b"
    border.color: "#333a46"
    border.width: 1
    radius: units.gu(1.6)
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.margins: units.gu(1)
    z: 999

    property string elapsedDisplay: ""
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
        if (!TimerService.isRunning()) {
            globalTimer.visible = false;
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            const currentlyRunning = TimerService.isRunning();
            const currentlyPaused = TimerService.isPaused();
            const currentTimesheetId = TimerService.getActiveTimesheetId() !== null ? TimerService.getActiveTimesheetId() : -1;

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
                    globalTimer.elapsedDisplay = TimerService.getElapsedTime() + " " + TimerService.getActiveTimesheetName();
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

    // Animated indicator dot
    Rectangle {
        id: indicator
        width: units.gu(1.4)
        height: units.gu(1.4)
        radius: units.gu(0.7)
        color: {
            if (isSyncing && !TimerService.isRunning()) {
                if (syncFailed)
                    return "#ef4444"; // Red for error
                if (syncSuccessful)
                    return "#22c55e"; // Green for success
                return "#3b82f6"; // Blue for syncing
            }
            return TimerService.isPaused() ? "#f59e0b" : "#10b981"; // Amber for paused, Green for running
        }
        anchors.left: parent.left
        anchors.leftMargin: units.gu(1.5)
        anchors.verticalCenter: parent.verticalCenter

        // Pulsing animation
        SequentialAnimation on opacity {
            loops: Animation.Infinite
            running: globalTimer.visible && !TimerService.isPaused()
            NumberAnimation {
                from: 0.3
                to: 1.0
                duration: {
                    if (isSyncing && !TimerService.isRunning()) {
                        return syncSuccessful ? 400 : 600;
                    }
                    return 800;
                }
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                from: 1.0
                to: 0.3
                duration: {
                    if (isSyncing && !TimerService.isRunning()) {
                        return syncSuccessful ? 400 : 600;
                    }
                    return 800;
                }
                easing.type: Easing.InOutQuad
            }
        }
    }

    // Main Content Section (Two-Line Layout)
    Column {
        id: textContent
        anchors.left: indicator.right
        anchors.leftMargin: units.gu(1.2)
        anchors.right: buttonRow.visible ? buttonRow.left : parent.right
        anchors.rightMargin: units.gu(1.2)
        anchors.verticalCenter: parent.verticalCenter
        spacing: units.gu(0.3)

        // Line 1: Timesheet / Account Title
        Label {
            id: titleLabel
            width: parent.width
            text: {
                if (TimerService.isRunning()) {
                    var name = TimerService.getActiveTimesheetName();
                    return (name && name.trim() !== "") ? name.trim() : "Active Timesheet";
                } else if (isSyncing) {
                    return syncAccountName || "Cloud Sync";
                }
                return "";
            }
            color: "#f3f4f6"
            font.pixelSize: units.gu(1.6)
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        // Line 2: Timer Duration + Status Badge (or Sync Status Message)
        Row {
            id: subtitleRow
            spacing: units.gu(1)
            width: parent.width

            // Digital Clock
            Label {
                id: timerClock
                visible: TimerService.isRunning()
                text: TimerService.getElapsedTime()
                color: TimerService.isPaused() ? "#f59e0b" : "#38bdf8"
                font.pixelSize: units.gu(1.8)
                font.family: "Ubuntu Mono, DejaVu Sans Mono, monospace"
                font.weight: Font.Bold
                anchors.verticalCenter: parent.verticalCenter
            }

            // Status Badge (RECORDING / PAUSED)
            Rectangle {
                id: statusBadge
                visible: TimerService.isRunning()
                radius: units.gu(0.4)
                height: units.gu(1.8)
                width: statusBadgeText.implicitWidth + units.gu(1)
                color: TimerService.isPaused() ? "#451a03" : "#064e3b"
                border.color: TimerService.isPaused() ? "#78350f" : "#047857"
                border.width: 1
                anchors.verticalCenter: parent.verticalCenter

                Label {
                    id: statusBadgeText
                    anchors.centerIn: parent
                    text: TimerService.isPaused() ? "PAUSED" : "RECORDING"
                    font.pixelSize: units.gu(1.0)
                    font.weight: Font.Bold
                    color: TimerService.isPaused() ? "#fbbf24" : "#34d399"
                }
            }

            // Sync Status Subtitle (when syncing without timer)
            Label {
                id: syncSubtitle
                visible: isSyncing && !TimerService.isRunning()
                width: parent.width
                text: {
                    if (syncFailed) return syncStatusMessage || "Sync Failed";
                    if (syncSuccessful) return "✅ All items up to date";
                    var progressPercent = Math.round(syncProgress * 100);
                    return (syncStatusMessage || "Syncing...") + " (" + progressPercent + "%)";
                }
                color: syncFailed ? "#ef4444" : (syncSuccessful ? "#22c55e" : "#9ca3af")
                font.pixelSize: units.gu(1.3)
                elide: Text.ElideRight
                maximumLineCount: 1
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // Action Buttons Container
    Row {
        id: buttonRow
        anchors.right: parent.right
        anchors.rightMargin: units.gu(1.2)
        anchors.verticalCenter: parent.verticalCenter
        spacing: units.gu(1)
        visible: !isSyncing || TimerService.isRunning()

        // Pause/Resume Button
        Rectangle {
            id: pausebutton
            width: units.gu(4.2)
            height: units.gu(4.2)
            radius: width / 2
            color: TimerService.isPaused() ? "#10b981" : "#f59e0b"

            Image {
                id: pauseIcon
                anchors.centerIn: parent
                width: units.gu(2.4)
                height: units.gu(2.4)
                source: TimerService.isPaused() ? "../../images/play.png" : "../../images/pause.png"
                fillMode: Image.PreserveAspectFit
            }

            MouseArea {
                anchors.fill: parent
                onPressed: pausebutton.scale = 0.92
                onReleased: pausebutton.scale = 1.0
                onCanceled: pausebutton.scale = 1.0
                onClicked: {
                    if (TimerService.isPaused())
                        TimerService.start(TimerService.getActiveTimesheetId());
                    else
                        TimerService.pause();
                }
            }
        }

        // Stop Button
        Rectangle {
            id: stopbutton
            width: units.gu(4.2)
            height: units.gu(4.2)
            radius: width / 2
            color: "#ef4444"

            Image {
                id: stopIcon
                anchors.centerIn: parent
                width: units.gu(2.4)
                height: units.gu(2.4)
                source: "../../images/stop.png"
                fillMode: Image.PreserveAspectFit
            }

            MouseArea {
                anchors.fill: parent
                onPressed: stopbutton.scale = 0.92
                onReleased: stopbutton.scale = 1.0
                onCanceled: stopbutton.scale = 1.0
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

    // Progress Bar Indicator at Bottom
    Rectangle {
        id: progressContainer
        visible: isSyncing
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottomMargin: units.gu(0.2)
        anchors.leftMargin: units.gu(1)
        anchors.rightMargin: units.gu(1)
        height: units.gu(0.4)
        radius: units.gu(0.2)
        color: "#111827"
        clip: true

        Rectangle {
            id: progressIndicator
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: isSyncing ? parent.width * syncProgress : 0
            radius: parent.radius
            color: syncSuccessful ? "#22c55e" : (syncFailed ? "#ef4444" : "#3b82f6")

            Behavior on width {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutQuad
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