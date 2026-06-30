import QtQuick 2.7
import Lomiri.Components 1.3

Rectangle {
    id: voiceTimerWidget
    
    // Properties to control the widget state
    property bool isListening: false
    property bool isProcessing: false
    property string partialText: ""
    property string voiceStatus: ""
    
    // Signal emitted when the user clicks the stop button
    signal stopClicked()
    
    width: units.gu(47)
    height: units.gu(8)
    color: "#2d2d2d"
    radius: units.gu(1)
    
    // Default positioning logic that can be overridden by instantiators
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottomMargin: Qt.inputMethod.visible ? Qt.inputMethod.keyboardRectangle.height + units.gu(1) : units.gu(1)
    z: 999
    
    visible: isListening || isProcessing

    Rectangle {
        id: indicator
        width: units.gu(1.5)
        height: units.gu(1.5)
        radius: units.gu(.75)
        color: voiceTimerWidget.isProcessing ? "#ffa500" : "#0078d4"
        anchors.left: parent.left
        anchors.margins: units.gu(2)
        anchors.verticalCenter: parent.verticalCenter

        SequentialAnimation on opacity {
            loops: Animation.Infinite
            running: voiceTimerWidget.visible
            NumberAnimation { from: 0.3; to: 1; duration: 800; easing.type: Easing.InOutQuad }
            NumberAnimation { from: 1; to: 0.3; duration: 800; easing.type: Easing.InOutQuad }
        }
    }

    Flickable {
        id: textFlickable
        anchors.left: indicator.right
        anchors.leftMargin: units.gu(1)
        anchors.right: stopbutton.left
        anchors.rightMargin: units.gu(1)
        anchors.verticalCenter: parent.verticalCenter
        height: units.gu(4)
        contentWidth: voiceLabel.paintedWidth
        contentHeight: height
        clip: true
        interactive: false

        Label {
            id: voiceLabel
            text: voiceTimerWidget.voiceStatus + (voiceTimerWidget.partialText ? " - " + voiceTimerWidget.partialText : "")
            color: "white"
            font.pixelSize: units.gu(2)
            anchors.verticalCenter: parent.verticalCenter
            verticalAlignment: Text.AlignVCenter

            onTextChanged: {
                if (paintedWidth > textFlickable.width) {
                    textFlickable.contentX = paintedWidth - textFlickable.width;
                } else {
                    textFlickable.contentX = 0;
                }
            }
        }
    }

    Image {
        id: stopbutton
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.margins: units.gu(1)
        width: units.gu(4)
        height: units.gu(4)
        // Image path assumes we are in components/system/
        source: "../../images/stop.png"
        fillMode: Image.PreserveAspectFit
        visible: voiceTimerWidget.isListening

        MouseArea {
            anchors.fill: parent
            onPressed: stopbutton.opacity = 0.5
            onReleased: stopbutton.opacity = 1.0
            onCanceled: stopbutton.opacity = 1.0
            onClicked: {
                voiceTimerWidget.stopClicked()
            }
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: units.gu(0.5)
        color: "#333333"
        opacity: 0.7
        
        Rectangle {
            id: progressIndicator
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * 0.3
            color: voiceTimerWidget.isProcessing ? "#ffa500" : "#0078d4"
            
            SequentialAnimation on x {
                running: voiceTimerWidget.visible && voiceTimerWidget.isProcessing
                loops: Animation.Infinite
                NumberAnimation { from: -progressIndicator.width; to: voiceTimerWidget.width; duration: 2000; easing.type: Easing.InOutQuad }
            }
        }
    }
}
