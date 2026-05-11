// Reusable native QML horizontal bar chart for top task time visualization.
import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Layouts 1.12
import "../js/chartUtils.js" as ChartUtils

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

    property real maxHours: ChartUtils.maxTaskHours(root.tasksData) > 0 ? ChartUtils.maxTaskHours(root.tasksData) : 1

    implicitHeight: (root.tasksData.length * units.gu(4.5)) + units.gu(3)

    RowLayout {
        anchors.fill: parent
        spacing: units.gu(1.5)

        // Labels Column
        Column {
            Layout.preferredWidth: units.gu(14)
            Layout.fillHeight: true
            spacing: units.gu(1.5)

            Repeater {
                model: root.tasksData
                Item {
                    width: parent.width
                    height: units.gu(3) // match bar height
                    Label {
                        anchors.fill: parent
                        text: modelData.name || ""
                        color: Theme.palette.normal.baseText
                        font.pixelSize: units.dp(12)
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                }
            }
            
            // Bottom spacer to align with X-axis labels
            Item { width: 1; height: units.gu(3) }
        }

        // Bars & Grid Column
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Grid Lines & X-Axis
            Repeater {
                model: 5
                Item {
                    x: parent.width * (index / 4)
                    height: parent.height - units.gu(3)
                    width: units.dp(1)

                    // Vertical grid line
                    Rectangle {
                        anchors.fill: parent
                        color: root.isDark ? Qt.rgba(1,1,1,0.1) : Qt.rgba(0,0,0,0.1)
                        visible: index > 0 // hide the 0 line to avoid overlapping the axis
                    }

                    // Axis Label
                    Label {
                        anchors.top: parent.bottom
                        anchors.topMargin: units.dp(6)
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: ChartUtils.formatHours(root.maxHours * (index / 4))
                        color: Theme.palette.normal.backgroundText
                        font.pixelSize: units.dp(10)
                    }
                }
            }

            // Left axis line (stronger)
            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                height: parent.height - units.gu(3)
                width: units.dp(2)
                color: Theme.palette.normal.backgroundText
                z: 1
            }

            // Bars
            Column {
                anchors.fill: parent
                spacing: units.gu(1.5)
                z: 2

                Repeater {
                    model: root.tasksData
                    Item {
                        width: parent.width
                        height: units.gu(3)
                        
                        property real fraction: Number(modelData.totalHours || 0) / root.maxHours
                        property color barColor: root.barColors[index % root.barColors.length]

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            height: parent.height
                            width: Math.max(units.dp(2), Math.min(parent.width * fraction, parent.width - units.gu(6)))
                            radius: units.dp(4)
                            
                            // Flatten left corners
                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.radius
                                color: parent.color
                            }

                            color: barColor

                            Behavior on width { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }
                        }
                        
                        // Label displaying hours at the end of the bar
                        Label {
                            anchors.left: parent.left
                            anchors.leftMargin: Math.max(units.dp(2), Math.min(parent.width * fraction, parent.width - units.gu(6))) + units.dp(8)
                            anchors.verticalCenter: parent.verticalCenter
                            text: ChartUtils.formatHours(modelData.totalHours || 0)
                            color: Theme.palette.normal.baseText
                            font.pixelSize: units.dp(11)
                            font.bold: true
                            opacity: 0.8
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            anchors.rightMargin: -units.gu(4) // allow clicking near the end
                            onClicked: root.taskSelected(modelData.id)
                        }
                    }
                }
            }
        }
    }
}
