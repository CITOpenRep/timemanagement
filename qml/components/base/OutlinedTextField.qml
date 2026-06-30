import QtQuick 2.7
import QtQuick.Controls 2.2
import Lomiri.Components 1.3
import ".."

Item {
    id: root

    property string labelText: ""
    property alias text: inputField.text
    property string placeholderText: ""
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
        border.color: inputField.activeFocus ? LomiriColors.blue : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#555" : "#c0c0c0")
        border.width: inputField.activeFocus ? 2 : 1
        color: inputField.readOnly ? (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#252525" : "#f0f0f0") : "transparent"
        clip: true

        TextInput {
            id: inputField
            anchors.fill: parent
            anchors.leftMargin: units.gu(1.5)
            anchors.rightMargin: units.gu(1)
            verticalAlignment: TextInput.AlignVCenter
            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
            font.pixelSize: units.gu(2)
            selectByMouse: true
            
            onAccepted: root.accepted()
        }

        Text {
            id: placeholder
            anchors.fill: parent
            anchors.leftMargin: units.gu(1.5)
            anchors.rightMargin: units.gu(1)
            verticalAlignment: Text.AlignVCenter
            text: root.placeholderText
            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#777" : "#999"
            font.pixelSize: units.gu(2)
            visible: !inputField.text && !inputField.activeFocus
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
