// Single task list row delegate used in the project detail screen.
import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Layouts 1.12
import "chartUtils.js" as ChartUtils

Item {
    id: root

    property var taskData: ({})
    property real projectTotalHours: 0
    property color accentColour: Theme.palette.selected.background

    signal clicked()

    implicitHeight: units.gu(8)

    UbuntuShape {
        anchors.fill: parent
        color: Theme.palette.normal.base

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: units.gu(1.5)
            anchors.rightMargin: units.gu(1.5)
            spacing: units.gu(1)

            Rectangle {
                Layout.preferredWidth: units.gu(1.5)
                Layout.preferredHeight: units.gu(1.5)
                radius: width / 2
                color: accentColour
            }

            Column {
                Layout.fillWidth: true
                spacing: units.gu(0.2)

                Label {
                    width: parent.width
                    text: taskData.name || ""
                    color: Theme.palette.normal.baseText
                    font.pixelSize: units.dp(13)
                    elide: Text.ElideRight
                }

                Label {
                    text: ChartUtils.percentLabel(taskData.totalHours || 0, projectTotalHours)
                    color: Theme.palette.normal.backgroundText
                    font.pixelSize: units.dp(12)
                }
            }

            Label {
                text: ChartUtils.formatHours(taskData.totalHours || 0)
                color: Theme.palette.normal.baseText
                font.bold: true
                font.pixelSize: units.dp(13)
            }

            Label {
                text: ">"
                color: Theme.palette.normal.backgroundText
                font.pixelSize: units.dp(16)
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
