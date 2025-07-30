import QtQuick 2.7
import QtQuick.Controls 2.2
import Lomiri.Components 1.3
import "../../models/timer_service.js" as TimerService
import "../../models/utils.js" as Utils

Rectangle {
    id: globalTimer
    width: units.gu(40)
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
    property bool previousRunningState: false
    property bool previousPausedState: false
    property int previousTimesheetId: -1

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            const currentlyRunning = TimerService.isRunning();
            const currentlyPaused = TimerService.isPaused();
            const currentTimesheetId = TimerService.getActiveTimesheetId() !== null ? TimerService.getActiveTimesheetId() : -1;

            // Update display and visibility
            if (currentlyRunning) {
                globalTimer.visible = true;
                globalTimer.elapsedDisplay = TimerService.getElapsedTime() + " " + TimerService.getActiveTimesheetName();
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

    // Animated dot
    Rectangle {
        id: indicator
        width: units.gu(1)
        height: units.gu(1)
        radius: units.gu(0.5)
        color: "#ffa500"
        anchors.left: parent.left
        anchors.margins: units.gu(1)
        anchors.verticalCenter: parent.verticalCenter
        SequentialAnimation on opacity {
            loops: Animation.Infinite
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

    // play/pause Button
    // play/pause Button with simple click feedback
    Image {
        id: pausebutton
        anchors.verticalCenter: parent.verticalCenter
        anchors.top: parent.top
        anchors.right: stopbutton.left
        anchors.margins: units.gu(1)
        width: units.gu(5)
        height: units.gu(5)
        source: "../images/pause.png"
        fillMode: Image.PreserveAspectFit

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

    // Stop Button
    Image {
        id: stopbutton
        anchors.verticalCenter: parent.verticalCenter
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: units.gu(1)
        width: units.gu(5)
        height: units.gu(5)
        source: "../images/stop.png"
        fillMode: Image.PreserveAspectFit

        MouseArea {
            anchors.fill: parent
            onPressed: stopbutton.opacity = 0.5
            onReleased: stopbutton.opacity = 1.0
            onCanceled: stopbutton.opacity = 1.0
            onClicked: {
                TimerService.stop();
            }
        }
    }

    // Name Label
    Label {
        text: Utils.truncateText( globalTimer.elapsedDisplay, 20) 
        color: "white"
        font.pixelSize: units.gu(2)
        anchors.top: parent.top
        anchors.topMargin: units.gu(3)
        anchors.left: indicator.right
        anchors.margins: units.gu(1)
        anchors.right: pausebutton.left
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
    }
}
