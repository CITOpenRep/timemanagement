import QtQuick 2.7
import QtQuick.Controls 2.2
import Lomiri.Components 1.3
import "../../models/timer_service.js" as TimerService
import "../../models/utils.js" as Utils

Rectangle {
    id: globalTimer
    width: units.gu(47)
    height: units.gu(8)
    color: "#2d2d2d" // semi-transparent dark
    radius: units.gu(1)
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.margins: units.gu(1)
    z: 999

    property string elapsedDisplay: ""
    signal timerStopped
    signal timerStarted
    signal timerPaused
    signal timerResumed
    signal syncTimedOut(int accountId) // New signal for sync timeout
    property bool previousRunningState: false
    property bool previousPausedState: false
    property int previousTimesheetId: -1

    // Enhanced properties for sync status
    property bool isSyncing: false
    property string syncAccountName: ""
    property int syncAccountId: -1
    property bool syncSuccessful: false
    property real syncProgress: 0.0 // Progress from 0.0 to 1.0
    property real syncStartTime: 0

    // Built-in sync timeout timer with success phase
    Timer {
        id: syncTimeoutTimer
        interval: 26000 // 20 seconds timeout-> Change according to Sync Timeout
        running: false
        repeat: false
        onTriggered: {
            if (isSyncing) {
                //  console.warn("⚠️ GlobalTimer: Sync timeout for account", syncAccountId, "- stopping sync indication");
                var timedOutAccountId = syncAccountId; // Store before clearing
                stopSync();
                // Emit signal so other components can react to timeout
                globalTimer.syncTimedOut(timedOutAccountId);
            }
        }
    }

    // Success phase timer (shows success for 2 seconds before timeout)
    Timer {
        id: successTimer
        interval: 24000 // Show success at 18 seconds (1 seconds before timeout)
        running: false
        repeat: false
        onTriggered: {
            if (isSyncing) {
                // console.log("✅ GlobalTimer: Showing sync success for account", syncAccountId);
                syncSuccessful = true;
                syncProgress = 1.0;
            }
        }
    }

    // Progress update timer
    Timer {
        id: progressTimer
        interval: 100 // Update every 100ms for smooth progress
        running: false
        repeat: true
        onTriggered: {
            if (isSyncing && !syncSuccessful) {
                var elapsed = Date.now() - syncStartTime;
                var totalTime = 24000; // Progress completes at 15 seconds (when success shows)
                syncProgress = Math.min(elapsed / totalTime, 1.0);
                //   console.log("Progress update:", syncProgress, "Elapsed:", elapsed, "StartTime:", syncStartTime, "Now:", Date.now());
            }
        }
    }

    // Function to start sync indication
    function startSync(accountId, accountName) {
        // console.log("🔥 GlobalTimer: Starting sync indication for account", accountId, "(" + accountName + ")");
        syncAccountId = accountId;
        syncAccountName = accountName || "Account " + accountId;
        isSyncing = true;
        syncSuccessful = false;
        syncProgress = 0.0;
        syncStartTime = Date.now(); // This is correct
        globalTimer.visible = true;

        // Start all timers
        syncTimeoutTimer.start();
        successTimer.start();
        progressTimer.start();
    }
    // Function to stop sync indication
    function stopSync() {
        //  console.log("✅ GlobalTimer: Stopping sync indication for account", syncAccountId);

        // Stop all timers
        syncTimeoutTimer.stop();
        successTimer.stop();
        progressTimer.stop();

        isSyncing = false;
        syncSuccessful = false;
        syncProgress = 0.0;
        syncAccountId = -1;
        syncAccountName = "";

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
                    // Show sync status when no timer is running
                    if (syncSuccessful) {
                        globalTimer.elapsedDisplay = "✅ Sync Complete - " + syncAccountName;
                    } else {
                        globalTimer.elapsedDisplay = "Syncing " + syncAccountName + "...";
                    }
                } else if (currentlyRunning) {
                    // Show timer status (prioritize timer over sync)
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
                pausebutton.source = "../images/play.png";
            } else if (!currentlyPaused && globalTimer.previousPausedState) {
                globalTimer.timerResumed();
                pausebutton.source = "../images/pause.png";
            }

            // Update previous states
            globalTimer.previousRunningState = currentlyRunning;
            globalTimer.previousTimesheetId = currentTimesheetId;
            globalTimer.previousPausedState = currentlyPaused;
        }
    }

    // Animated dot - changes behavior based on sync status
    Rectangle {
        id: indicator
        width: units.gu(1.5)
        height: units.gu(1.5)
        radius: units.gu(.75)
        color: {
            if (isSyncing && !TimerService.isRunning()) {
                return syncSuccessful ? "#28a745" : "#0078d4"; // Green for success, blue for syncing
            }
            return "#ffa500"; // Orange for timer
        }
        anchors.left: parent.left
        anchors.margins: units.gu(2)
        anchors.verticalCenter: parent.verticalCenter

        // Pulsing animation
        SequentialAnimation on opacity {
            loops: Animation.Infinite
            running: globalTimer.visible
            NumberAnimation {
                from: 0.3
                to: 1
                duration: {
                    if (isSyncing && !TimerService.isRunning()) {
                        return syncSuccessful ? 400 : 600; // Faster pulse for success
                    }
                    return 800;
                }
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                from: 1
                to: 0.3
                duration: {
                    if (isSyncing && !TimerService.isRunning()) {
                        return syncSuccessful ? 400 : 600; // Faster pulse for success
                    }
                    return 800;
                }
                easing.type: Easing.InOutQuad
            }
        }

        // Add rotating animation for sync status only (not for success)
        RotationAnimation on rotation {
            running: isSyncing && !TimerService.isRunning() && !syncSuccessful
            loops: Animation.Infinite
            from: 0
            to: 360
            duration: 2000
            easing.type: Easing.Linear
        }

        // Scale animation - different for success vs syncing
        SequentialAnimation on scale {
            running: isSyncing && !TimerService.isRunning()
            loops: Animation.Infinite
            NumberAnimation {
                from: 1.0
                to: syncSuccessful ? 1.5 : 1.3 // Bigger scale for success
                duration: syncSuccessful ? 800 : 1000
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                from: syncSuccessful ? 1.5 : 1.3
                to: 1.0
                duration: syncSuccessful ? 800 : 1000
                easing.type: Easing.InOutQuad
            }
        }
    }

    // play/pause Button - hide during sync-only mode
    Image {
        id: pausebutton
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: stopbutton.left
        anchors.margins: units.gu(1)
        width: units.gu(5)
        height: units.gu(5)
        source: "../images/pause.png"
        fillMode: Image.PreserveAspectFit

        visible: !syncTimeoutTimer.running

        MouseArea {
            anchors.fill: parent

            onPressed: pausebutton.opacity = 0.5
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

    // Stop Button - hide during sync-only mode
    Image {
        id: stopbutton
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.margins: units.gu(1)
        width: units.gu(5)
        height: units.gu(5)
        source: "../images/stop.png"
        fillMode: Image.PreserveAspectFit
        visible: !syncTimeoutTimer.running

        MouseArea {
            anchors.fill: parent
            onPressed: stopbutton.opacity = 0.5
            onReleased: stopbutton.opacity = 1.0
            onCanceled: stopbutton.opacity = 1.0
            onClicked: {
                // Stop the timer and set timesheet status to draft
                TimerService.stop();
            }
        }
    }

    // Name Label
    Label {
        text: !syncTimeoutTimer.running ? Utils.truncateText(globalTimer.elapsedDisplay, 20) : globalTimer.elapsedDisplay
        color: "white"
        font.pixelSize: units.gu(2)
        anchors.top: parent.top
        anchors.topMargin: units.gu(3)
        anchors.left: indicator.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        // anchors.margins: units.gu(-12)
        anchors.right: (TimerService.isRunning() || TimerService.isPaused()) ? pausebutton.left : parent.right
        anchors.rightMargin: units.gu(1)
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
    }

    // Enhanced progress indicator - changes based on timer state
    Rectangle {
        id: progressContainer
        visible: syncTimeoutTimer.running
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: units.gu(0.5)
        color: "#333333"
        opacity: 0.7

        // Progress bar background
        Rectangle {
            id: progressBackground
            anchors.fill: parent
            color: {
                if (TimerService.isRunning()) {
                    return TimerService.isPaused() ? "#ff6b35" : "#ffa500"; // Orange/red for timer
                } else if (isSyncing) {
                    return syncSuccessful ? "#28a745" : "#0078d4"; // Green for success, blue for syncing
                }
                return "#0078d4";
            }
            opacity: 0.3
        }

        // Animated progress indicator
        Rectangle {
            id: progressIndicator
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: {
                if (isSyncing) {
                    // For sync: show actual progress
                    return parent.width * syncProgress;
                }
                return 0;
            }
            color: {
                if (isSyncing) {
                    return syncSuccessful ? "#28a745" : "#ffffff"; // Green for success, white for syncing
                }
                return "#ffffff";
            }
            opacity: 0.9

            // Sliding animation for timer mode only
            SequentialAnimation on x {
                running: progressContainer.visible && TimerService.isRunning()
                loops: Animation.Infinite
                NumberAnimation {
                    from: -progressIndicator.width
                    to: progressContainer.width
                    duration: TimerService.isPaused() ? 3000 : 2000 // Slower when paused
                    easing.type: Easing.InOutQuad
                }
            }

            // Smooth width animation for sync progress
            Behavior on width {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutQuad
                }
            }

            // Success completion animation
            SequentialAnimation on opacity {
                running: syncSuccessful
                loops: 3 // Flash 3 times when successful
                NumberAnimation {
                    from: 0.9
                    to: 0.3
                    duration: 200
                }
                NumberAnimation {
                    from: 0.3
                    to: 0.9
                    duration: 200
                }
            }
        }
    }
}
