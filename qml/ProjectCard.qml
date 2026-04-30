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

    width: parent ? parent.width : units.gu(40)
    implicitHeight: units.gu(12)

    // Micro-animation states
    scale: mouseArea.pressed ? 0.98 : 1.0
    opacity: mouseArea.pressed ? 0.9 : 1.0
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
    Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

    Rectangle {
        id: cardBg
        anchors.fill: parent
        anchors.leftMargin: units.gu(1.5)
        anchors.rightMargin: units.gu(1.5)
        anchors.topMargin: units.gu(0.5)
        anchors.bottomMargin: units.gu(0.5)
        radius: units.gu(1)
        color: Theme.palette.normal.base

        // Subtle tint using the project color
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: projectData.colour || Theme.palette.selected.background
            opacity: Theme.name === "Ubuntu.Components.Themes.SuruDark" ? 0.12 : 0.08
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: units.gu(1.5)
            spacing: units.gu(1.5)

            // Accent pill indicator
            Rectangle {
                Layout.preferredWidth: units.gu(0.6)
                Layout.fillHeight: true
                radius: width / 2
                color: projectData.colour || Theme.palette.selected.background
            }

            Column {
                Layout.fillWidth: true
                spacing: units.gu(0.8)

                RowLayout {
                    width: parent.width

                    Label {
                        Layout.fillWidth: true
                        text: projectData.name || ""
                        color: Theme.palette.normal.baseText
                        font.bold: true
                        font.pixelSize: units.dp(15)
                        elide: Text.ElideRight
                    }

                    Label {
                        text: ChartUtils.formatHours(projectData.totalHours || 0)
                        color: Theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : Theme.palette.normal.baseText
                        font.bold: true
                        font.pixelSize: units.dp(16)
                    }
                }

                Label {
                    text: String(projectData.taskCount || 0) + " " + i18n.dtr("ubtms", "tasks")
                    color: Theme.palette.normal.backgroundText
                    font.pixelSize: units.dp(12)
                }

                // Smooth Rounded Progress Bar
                Rectangle {
                    width: parent.width
                    height: units.gu(0.8)
                    radius: height / 2
                    color: Theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#333333" : "#E5E5E5"

                    Rectangle {
                        width: parent.width * Math.min(1, Number(projectData.totalHours || 0) / Math.max(root.maxHours, 0.1))
                        height: parent.height
                        radius: parent.radius
                        color: projectData.colour || Theme.palette.selected.background
                        
                        // Subtle width animation on load
                        Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                    }
                }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
