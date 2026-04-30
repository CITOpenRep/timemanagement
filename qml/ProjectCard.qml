// Single project summary card delegate for the portfolio screen.
import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Layouts 1.12
import "chartUtils.js" as ChartUtils

Item {
    id: root

    property var projectData: ({})
    property real maxHours: 1

    signal clicked()

    readonly property bool isDark: Theme.name === "Ubuntu.Components.Themes.SuruDark"
    readonly property color projectColor: projectData.colour || "#E95420"

    width: parent ? parent.width : units.gu(40)
    implicitHeight: units.gu(11)

    // Micro-animation states
    scale: mouseArea.pressed ? 0.97 : 1.0
    opacity: mouseArea.pressed ? 0.85 : 1.0
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
    Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

    Rectangle {
        id: cardBg
        anchors.fill: parent
        anchors.leftMargin: units.gu(2)
        anchors.rightMargin: units.gu(2)
        anchors.topMargin: units.gu(0.5)
        anchors.bottomMargin: units.gu(0.5)
        radius: units.gu(1.2)
        color: Theme.palette.normal.base
        border.color: root.isDark ? Qt.rgba(root.projectColor.r, root.projectColor.g, root.projectColor.b, 0.25) : Qt.rgba(0,0,0,0.1)
        border.width: units.dp(1)

        // Left accent strip
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: units.gu(0.6)
            radius: width / 2
            color: root.projectColor
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: units.gu(2.5)
            anchors.rightMargin: units.gu(2)
            anchors.topMargin: units.gu(1.5)
            anchors.bottomMargin: units.gu(1.5)
            spacing: units.gu(1.5)

            Column {
                Layout.fillWidth: true
                spacing: units.gu(0.8)

                Label {
                    width: parent.width
                    text: projectData.name || ""
                    color: Theme.palette.normal.baseText
                    font.bold: true
                    font.pixelSize: units.dp(15)
                    elide: Text.ElideRight
                }

                Label {
                    text: String(projectData.taskCount || 0) + " " + i18n.dtr("ubtms", "tasks")
                    color: Theme.palette.normal.backgroundText
                    font.pixelSize: units.dp(12)
                }

                // Progress bar
                Rectangle {
                    width: parent.width
                    height: units.gu(0.7)
                    radius: height / 2
                    color: root.isDark ? Qt.rgba(1,1,1,0.05) : Qt.rgba(0,0,0,0.05)

                    Rectangle {
                        width: parent.width * Math.min(1, Number(projectData.totalHours || 0) / Math.max(root.maxHours, 0.1))
                        height: parent.height
                        radius: parent.radius
                        color: root.projectColor

                        Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                    }
                }
            }

            // Hours pill
            Rectangle {
                Layout.preferredWidth: hoursLabel.implicitWidth + units.gu(1.5)
                Layout.preferredHeight: units.gu(3.5)
                radius: height / 2
                color: Qt.rgba(root.projectColor.r, root.projectColor.g, root.projectColor.b, root.isDark ? 0.2 : 0.12)

                Label {
                    id: hoursLabel
                    anchors.centerIn: parent
                    text: ChartUtils.formatHours(projectData.totalHours || 0)
                    color: root.projectColor
                    font.bold: true
                    font.pixelSize: units.dp(14)
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
