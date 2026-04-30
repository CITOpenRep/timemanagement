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

    implicitHeight: units.gu(9)

    // Micro-animation states
    scale: mouseArea.pressed ? 0.98 : 1.0
    opacity: mouseArea.pressed ? 0.9 : 1.0
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
    Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: units.gu(1.5)
        anchors.rightMargin: units.gu(1.5)
        anchors.topMargin: units.gu(0.4)
        anchors.bottomMargin: units.gu(0.4)
        radius: units.gu(1)
        color: Theme.palette.normal.base

        // Subtle accent tint
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: root.accentColour
            opacity: Theme.name === "Ubuntu.Components.Themes.SuruDark" ? 0.08 : 0.04
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: units.gu(1.5)
            spacing: units.gu(1.5)

            // Pill indicator instead of plain circle
            Rectangle {
                Layout.preferredWidth: units.gu(0.6)
                Layout.fillHeight: true
                radius: width / 2
                color: root.accentColour
            }

            Column {
                Layout.fillWidth: true
                spacing: units.gu(0.4)

                Label {
                    width: parent.width
                    text: taskData.name || ""
                    color: Theme.palette.normal.baseText
                    font.pixelSize: units.dp(14)
                    font.bold: true
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
                color: Theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : Theme.palette.normal.baseText
                font.bold: true
                font.pixelSize: units.dp(15)
            }

            // Modern chevron icon
            Icon {
                Layout.preferredWidth: units.gu(2)
                Layout.preferredHeight: units.gu(2)
                name: "go-next"
                color: Theme.palette.normal.backgroundText
                opacity: 0.7
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
