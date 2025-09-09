import QtQuick 2.7

Item {
    id: root
    width: parent.width
    height: units.gu(20)
    visible: false
    z: 99999

    // --- Config ---
    property alias text: message.text
    property int autoCloseMs: 10000
    property bool autoCloseEnabled: true

    signal opened
    signal closed

    // --- Public API ---
    function open(msg, durationMs) {
        if (msg !== undefined && msg !== null) {
            message.text = String(msg);
        }
        visible = true;
        opened();
        // restart timer if enabled
        if (autoCloseEnabled) {
            autoCloseTimer.interval = (durationMs === 0 || durationMs === undefined || durationMs === null) ? autoCloseMs : durationMs;
            if (autoCloseTimer.interval > 0) {
                autoCloseTimer.restart();
            } else {
                autoCloseTimer.stop();
            }
        } else {
            autoCloseTimer.stop();
        }
    }

    function close() {
        autoCloseTimer.stop();
        if (visible) {
            visible = false;
            closed();
        }
    }

    function setText(t) {
        message.text = String(t);
    }

    // --- UI (minimal) ---
    // Simple centered banner; tweak anchors to position elsewhere if you like.
    Item {
        id: container
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 16
        implicitWidth: parent.width
        implicitHeight: parent.height

        Rectangle {
            anchors.fill: parent
            color: "#2d2d2d"
            border.color: "#00000055"
            border.width: 1
        }

        Text {
            id: message
            anchors.centerIn: parent
            text: ""
            wrapMode: Text.WordWrap
            font.pixelSize: units.gu(2)
            color: "white"
        }
    }

    // --- Auto-close timer ---
    Timer {
        id: autoCloseTimer
        repeat: false
        onTriggered: root.close()
    }
}
