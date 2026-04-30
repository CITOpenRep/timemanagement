// Reusable native QML horizontal bar chart for top task time visualization.
import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Layouts 1.12
import "chartUtils.js" as ChartUtils

Item {
    id: root

    property var tasksData: []
    property color accentColour: "#E95420"
    property int highlightedIndex: -1

    signal taskSelected(string taskId)

    readonly property bool isDark: Theme.name === "Ubuntu.Components.Themes.SuruDark"
    // Vibrant color palette for bars
    readonly property var barColors: [
        "#E95420", "#3498DB", "#2ECC71", "#E74C3C", "#9B59B6",
        "#F39C12", "#1ABC9C", "#E67E22", "#16A085", "#D35400"
    ]

    implicitHeight: layout.implicitHeight + units.gu(4)

    Column {
        id: layout
        width: parent.width - units.gu(2)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: units.gu(1.5)
        spacing: units.gu(2)

        Repeater {
            model: root.tasksData

            Item {
                width: parent.width
                height: units.gu(4.5)

                property real maxHours: ChartUtils.maxTaskHours(root.tasksData)
                property real fraction: maxHours > 0 ? (Number(modelData.totalHours || 0) / maxHours) : 0
                property bool isHighlighted: root.highlightedIndex < 0 || root.highlightedIndex === index
                property color barColor: root.barColors[index % root.barColors.length]

                RowLayout {
                    anchors.fill: parent
                    spacing: units.gu(1.5)

                    // Left Task Name
                    Label {
                        Layout.preferredWidth: units.gu(14)
                        text: modelData.name || ""
                        color: root.isDark ? "#FFFFFF" : "#1A1A2E"
                        font.pixelSize: units.dp(13)
                        elide: Text.ElideRight
                        opacity: isHighlighted ? 1.0 : 0.6
                    }

                    // Bar Track
                    Item {
                        Layout.fillWidth: true
                        height: units.gu(1.2)

                        Rectangle {
                            anchors.fill: parent
                            color: root.isDark ? "#2A2A4A" : "#EEEEF2"
                            radius: height / 2
                        }

                        // Active Bar
                        Rectangle {
                            height: parent.height
                            width: Math.max(height, parent.width * fraction)
                            radius: height / 2
                            color: barColor
                            opacity: isHighlighted ? 1.0 : 0.6

                            Behavior on width {
                                NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
                            }
                        }
                    }

                    // Right Hours Value
                    Label {
                        Layout.preferredWidth: units.gu(6)
                        text: ChartUtils.formatHours(Number(modelData.totalHours || 0))
                        color: barColor
                        font.bold: true
                        font.pixelSize: units.dp(13)
                        horizontalAlignment: Text.AlignRight
                        opacity: isHighlighted ? 1.0 : 0.6
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.taskSelected(modelData.id)

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -units.gu(0.5)
                        radius: units.gu(0.5)
                        color: barColor
                        opacity: parent.pressed ? 0.12 : 0.0

                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                }
            }
        }
    }
}
