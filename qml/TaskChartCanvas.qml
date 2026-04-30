// Reusable native QML horizontal bar chart for top task time visualization.
import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Layouts 1.12
import "chartUtils.js" as ChartUtils

Item {
    id: root

    property var tasksData: []
    property color accentColour: Theme.palette.selected.background
    property int highlightedIndex: -1

    signal taskSelected(string taskId)

    implicitHeight: layout.implicitHeight + units.gu(4)

    Column {
        id: layout
        width: parent.width - units.gu(4)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: units.gu(2)
        spacing: units.gu(2.5)

        Repeater {
            model: root.tasksData

            Item {
                width: parent.width
                height: units.gu(4.5)

                property real maxHours: ChartUtils.maxTaskHours(root.tasksData)
                property real fraction: maxHours > 0 ? (Number(modelData.totalHours || 0) / maxHours) : 0
                property bool isHighlighted: root.highlightedIndex < 0 || root.highlightedIndex === index
                // Generate a vibrant distinct color for each task bar using the golden angle
                property color barColor: Qt.hsla( (index * 137.5) % 360 / 360.0, 0.75, Theme.name === "Ubuntu.Components.Themes.SuruDark" ? 0.6 : 0.5, 1.0 )

                RowLayout {
                    anchors.fill: parent
                    spacing: units.gu(1.5)

                    // Left Task Name
                    Label {
                        Layout.preferredWidth: units.gu(14)
                        text: modelData.name || ""
                        color: Theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : Theme.palette.normal.baseText
                        font.pixelSize: units.dp(14)
                        elide: Text.ElideRight
                        opacity: isHighlighted ? 1.0 : 0.6
                    }

                    // Bar Track
                    Item {
                        Layout.fillWidth: true
                        height: units.gu(1.5)
                        
                        Rectangle {
                            anchors.fill: parent
                            color: Theme.palette.normal.backgroundText
                            opacity: 0.1
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
                        color: Theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : Theme.palette.normal.baseText
                        font.bold: true
                        font.pixelSize: units.dp(14)
                        horizontalAlignment: Text.AlignRight
                        opacity: isHighlighted ? 1.0 : 0.6
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.taskSelected(modelData.id)
                    
                    // Add subtle press effect
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -units.gu(0.5)
                        radius: units.gu(0.5)
                        color: barColor
                        opacity: parent.pressed ? 0.15 : 0.0
                        
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                }
            }
        }
    }
}
