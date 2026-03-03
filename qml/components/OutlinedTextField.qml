import QtQuick 2.7
import QtQuick.Controls 2.2
import Lomiri.Components 1.3

Item {
    id: root

    property string labelText: ""
    property alias text: inputField.text
    property alias placeholderText: inputField.placeholderText
    property alias echoMode: inputField.echoMode
    property alias enabled: inputField.enabled
    property alias maximumLength: inputField.maximumLength
    property alias inputMethodHints: inputField.inputMethodHints
    property alias validator: inputField.validator
    property alias readOnly: inputField.readOnly

    signal accepted()

    // Internal standard margin
    height: units.gu(6.5)

    Rectangle {
        id: borderRect
        anchors.fill: parent
        anchors.topMargin: units.gu(1)
        radius: units.gu(0.8)
        border.color: "transparent"
        border.width: inputField.activeFocus ? 2 : 1
        color: "transparent"
        
        TextField {
            id: inputField
            anchors.fill: parent
            anchors.margins: 2
            anchors.leftMargin: units.gu(1.5)
            anchors.rightMargin: units.gu(1)
            verticalAlignment: TextInput.AlignVCenter
            
            onAccepted: root.accepted()
        }
    }

    Rectangle {
        visible: root.labelText !== ""
        height: label.height
        width: label.width + units.gu(1)
        
        // This overlaps the border
        anchors.left: borderRect.left
        anchors.leftMargin: units.gu(1.5)
        anchors.verticalCenter: borderRect.top
        
        // Match the background of the card
        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#1a1a1a" : "white"
        
        Text {
            id: label
            anchors.centerIn: parent
            text: root.labelText
            color: inputField.activeFocus ? LomiriColors.blue : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#aaa" : "#555")
            font.pixelSize: units.gu(1.3)
        }
    }
}
