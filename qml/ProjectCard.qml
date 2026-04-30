// Single project summary card delegate for the portfolio screen.
import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Layouts 1.12
import "chartUtils.js" as ChartUtils

UbuntuShape {
    id: root

    property var projectData: ({})
    property real maxHours: 1

    signal clicked()

    width: parent ? parent.width : units.gu(40)
    implicitHeight: units.gu(11)
    color: Theme.palette.normal.base

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: units.gu(0.7)
        color: projectData.colour || Theme.palette.selected.background
    }

    Column {
        anchors.fill: parent
        anchors.leftMargin: units.gu(2)
        anchors.rightMargin: units.gu(1.5)
        anchors.topMargin: units.gu(1.2)
        anchors.bottomMargin: units.gu(1.2)
        spacing: units.gu(0.7)

        RowLayout {
            width: parent.width

            Label {
                Layout.fillWidth: true
                text: projectData.name || ""
                color: Theme.palette.normal.baseText
                font.bold: true
                font.pixelSize: units.dp(14)
                elide: Text.ElideRight
            }

            Label {
                text: ChartUtils.formatHours(projectData.totalHours || 0)
                color: Theme.palette.normal.baseText
                font.bold: true
                font.pixelSize: units.dp(13)
            }
        }

        Label {
            text: String(projectData.taskCount || 0) + " " + i18n.dtr("ubtms", "tasks")
            color: Theme.palette.normal.backgroundText
            font.pixelSize: units.dp(12)
        }

        Rectangle {
            width: parent.width
            height: units.gu(1)
            color: Theme.palette.normal.background

            Rectangle {
                width: parent.width * Math.min(1, Number(projectData.totalHours || 0) / Math.max(root.maxHours, 0.1))
                height: parent.height
                color: projectData.colour || Theme.palette.selected.background
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
