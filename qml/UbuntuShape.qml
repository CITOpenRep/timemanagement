// Flat container helper used to emulate UbuntuShape styling without shadows.
import QtQuick 2.12
import Lomiri.Components 1.3

Item {
    id: root

    property alias color: background.color
    property real radius: units.gu(0.8)
    property color borderColor: Theme.palette.normal.background
    property real borderWidth: 0
    default property alias data: content.data

    implicitWidth: background.implicitWidth
    implicitHeight: background.implicitHeight

    Rectangle {
        id: background
        anchors.fill: parent
        radius: root.radius
        border.color: root.borderColor
        border.width: root.borderWidth
    }

    Item {
        id: content
        anchors.fill: parent
    }
}
