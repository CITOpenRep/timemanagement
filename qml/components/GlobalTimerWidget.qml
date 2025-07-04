import QtQuick 2.7
import QtQuick.Controls 2.2
import Lomiri.Components 1.3
import "../../models/timer_service.js" as TimerService

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

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            if (TimerService.isRunning()) {
                globalTimer.visible = true;
                globalTimer.elapsedDisplay = TimerService.getElapsedTime() + " " + TimerService.getActiveTimesheetName();
            } else {
                globalTimer.visible = false;
            }
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

    // Stop Button
    TSButton {
        id: stopbutton
        text: "Stop"
        anchors.top: parent.top
        anchors.right: parent.right
        width: units.gu(10)
        anchors.margins: units.gu(1)
        onClicked: {
            console.log("Stopping the Timesheet");
            TimerService.stop();
        }
    }

    // Name Label
    Label {
        text: globalTimer.elapsedDisplay
        color: "white"
        font.pixelSize: units.gu(2)
        anchors.top: parent.top
        anchors.topMargin: units.gu(3)
        anchors.left: indicator.right
        anchors.margins: units.gu(1)
        anchors.right: stopbutton.left
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
    }
}
