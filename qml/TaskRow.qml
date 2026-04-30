// Single task list row delegate used in the project detail screen.
import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Layouts 1.12
import "chartUtils.js" as ChartUtils

Item {
    id: root

    property var taskData: ({})
    property real projectTotalHours: 0
    property color accentColour: "#E95420"

    signal clicked()

    readonly property bool isDark: Theme.name === "Ubuntu.Components.Themes.SuruDark"

    implicitHeight: units.gu(8)

    // Micro-animation states
    scale: mouseArea.pressed ? 0.97 : 1.0
    opacity: mouseArea.pressed ? 0.85 : 1.0
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
    Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: units.gu(2)
        anchors.rightMargin: units.gu(2)
        anchors.topMargin: units.gu(0.4)
        anchors.bottomMargin: units.gu(0.4)
        radius: units.gu(1.2)
        color: root.isDark ? Qt.rgba(1,1,1,0.05) : Theme.palette.normal.base
        border.color: root.isDark ? Qt.rgba(1,1,1,0.1) : Qt.rgba(0,0,0,0.1)
        border.width: units.dp(1)

        // Left accent strip
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: units.gu(0.5)
            radius: width / 2
            color: root.accentColour
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: units.gu(2.5)
            anchors.rightMargin: units.gu(1.5)
            anchors.topMargin: units.gu(1)
            anchors.bottomMargin: units.gu(1)
            spacing: units.gu(1.5)

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

            // Hours pill
            Rectangle {
                Layout.preferredWidth: taskHoursLabel.implicitWidth + units.gu(1.5)
                Layout.preferredHeight: units.gu(3)
                radius: height / 2
                color: Qt.rgba(root.accentColour.r, root.accentColour.g, root.accentColour.b, root.isDark ? 0.2 : 0.12)

                Label {
                    id: taskHoursLabel
                    anchors.centerIn: parent
                    text: ChartUtils.formatHours(taskData.totalHours || 0)
                    color: root.accentColour
                    font.bold: true
                    font.pixelSize: units.dp(13)
                }
            }

            // Chevron
            Icon {
                Layout.preferredWidth: units.gu(2)
                Layout.preferredHeight: units.gu(2)
                name: "go-next"
                color: Theme.palette.normal.backgroundText
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
