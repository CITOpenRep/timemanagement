import QtQuick 2.7
import QtQuick.Controls 2.2
import Lomiri.Components 1.3

Item {
    id: root

    property string labelText: ""
    property bool isActiveFocus: (container.children.length > 0 && container.children[0].activeFocus)
    default property alias content: container.data

    height: units.gu(6.5)

    Rectangle {
        id: borderRect
        anchors.fill: parent
        anchors.topMargin: units.gu(1)
        radius: units.gu(0.8)
        border.color: root.isActiveFocus ? LomiriColors.blue : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#555" : "#c0c0c0")
        border.width: root.isActiveFocus ? 2 : 1
        color: "transparent"
        
        Item {
            id: container
            anchors.fill: parent
            anchors.margins: 1
        }
    }

    Rectangle {
        visible: root.labelText !== ""
        height: label.height
        width: label.width + units.gu(1)
        
        anchors.left: borderRect.left
        anchors.leftMargin: units.gu(1.5)
        anchors.verticalCenter: borderRect.top
        
        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#1a1a1a" : "white"
        
        Text {
            id: label
            anchors.centerIn: parent
            text: root.labelText
            color: root.isActiveFocus ? LomiriColors.blue : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#aaa" : "#555")
            font.pixelSize: units.gu(1.3)
        }
    }
}
