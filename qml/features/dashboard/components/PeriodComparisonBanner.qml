import QtQuick 2.7
import Lomiri.Components 1.3
import QtQuick.Layouts 1.1
import "../js/periodComparison.js" as PeriodHelper

Item {
    id: root
    width: parent ? parent.width : units.gu(48)
    implicitHeight: isFiltered ? container.implicitHeight : 0
    visible: isFiltered

    property bool isFiltered: false
    property bool isDark: Theme.name === "Ubuntu.Components.Themes.SuruDark"

    // Current period metrics
    property real currentHours: 0
    property int currentTasks: 0
    property int currentProjects: 0
    
    property real currentAverage: currentTasks > 0 ? currentHours / currentTasks : 0

    // Previous period metrics
    property real prevHours: 0
    property int prevTasks: 0
    property int prevProjects: 0
    property real prevAverage: prevTasks > 0 ? prevHours / prevTasks : 0

    // YoY metrics
    property real yoyHours: 0
    property int yoyTasks: 0
    property int yoyProjects: 0
    property real yoyAverage: yoyTasks > 0 ? yoyHours / yoyTasks : 0

    property string comparisonMode: "both" // "previous", "yoy", or "both"

    // Determine the number of columns based on width
    property int cols: root.width > units.gu(70) ? 3 : (root.width > units.gu(45) ? 2 : 1)
    property real spacingGu: units.gu(2)
    property real cardWidth: (root.width - (spacingGu * (cols - 1))) / cols

    Grid {
        id: container
        width: parent.width
        columns: root.cols
        spacing: root.spacingGu
        visible: root.isFiltered

        // 1. Tasks Card
        Rectangle {
            width: root.cardWidth
            height: units.gu(14)
            radius: units.gu(0.8)
            // Odoo Tasks card: light blue
            color: root.isDark ? Qt.rgba(0.1, 0.4, 0.8, 0.15) : "#f0f7fb"

            Label {
                text: i18n.dtr("ubtms", "Tasks")
                color: Theme.palette.normal.baseText
                font.bold: true
                font.pixelSize: units.dp(14)
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: units.gu(1.5)
            }

            Label {
                text: String(root.currentTasks)
                color: Theme.palette.normal.baseText
                font.pixelSize: units.dp(32)
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -units.gu(1)
            }

            Column {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: units.gu(1)
                spacing: units.gu(0.2)

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: units.gu(0.5)
                    visible: root.comparisonMode === "previous" || root.comparisonMode === "both"
                    property var varianceData: PeriodHelper.formatVariance(root.currentTasks, root.prevTasks)
                    
                    Label {
                        text: parent.varianceData.percent
                        color: parent.varianceData.color
                        font.pixelSize: units.dp(12)
                    }
                    Label {
                        text: i18n.dtr("ubtms", "since last period")
                        color: Theme.palette.normal.backgroundText
                        font.pixelSize: units.dp(12)
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: units.gu(0.5)
                    visible: root.comparisonMode === "yoy" || root.comparisonMode === "both"
                    property var varianceData: PeriodHelper.formatVariance(root.currentTasks, root.yoyTasks)
                    
                    Label {
                        text: parent.varianceData.percent
                        color: parent.varianceData.color
                        font.pixelSize: units.dp(12)
                    }
                    Label {
                        text: i18n.dtr("ubtms", "vs last year")
                        color: Theme.palette.normal.backgroundText
                        font.pixelSize: units.dp(12)
                    }
                }
            }
        }

        // 2. Hours Logged Card
        Rectangle {
            width: root.cardWidth
            height: units.gu(14)
            radius: units.gu(0.8)
            // Odoo Hours Logged card: light pink/red
            color: root.isDark ? Qt.rgba(0.8, 0.2, 0.2, 0.15) : "#fdf2f2"

            Label {
                text: i18n.dtr("ubtms", "Hours Logged")
                color: Theme.palette.normal.baseText
                font.bold: true
                font.pixelSize: units.dp(14)
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: units.gu(1.5)
            }

            Label {
                text: Number(root.currentHours).toFixed(1)
                color: Theme.palette.normal.baseText
                font.pixelSize: units.dp(32)
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -units.gu(1)
            }

            Column {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: units.gu(1)
                spacing: units.gu(0.2)

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: units.gu(0.5)
                    visible: root.comparisonMode === "previous" || root.comparisonMode === "both"
                    property var varianceData: PeriodHelper.formatVariance(root.currentHours, root.prevHours)
                    
                    Label {
                        text: parent.varianceData.percent
                        color: parent.varianceData.color
                        font.pixelSize: units.dp(12)
                    }
                    Label {
                        text: i18n.dtr("ubtms", "since last period")
                        color: Theme.palette.normal.backgroundText
                        font.pixelSize: units.dp(12)
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: units.gu(0.5)
                    visible: root.comparisonMode === "yoy" || root.comparisonMode === "both"
                    property var varianceData: PeriodHelper.formatVariance(root.currentHours, root.yoyHours)
                    
                    Label {
                        text: parent.varianceData.percent
                        color: parent.varianceData.color
                        font.pixelSize: units.dp(12)
                    }
                    Label {
                        text: i18n.dtr("ubtms", "vs last year")
                        color: Theme.palette.normal.backgroundText
                        font.pixelSize: units.dp(12)
                    }
                }
            }
        }

        // 3. Projects Card
        Rectangle {
            width: root.cardWidth
            height: units.gu(14)
            radius: units.gu(0.8)
            // Odoo Time to Assign card style (light orange/pinkish)
            color: root.isDark ? Qt.rgba(0.8, 0.4, 0.1, 0.15) : "#fef6f5"

            Label {
                text: i18n.dtr("ubtms", "Active Projects")
                color: Theme.palette.normal.baseText
                font.bold: true
                font.pixelSize: units.dp(14)
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: units.gu(1.5)
            }

            Label {
                text: String(root.currentProjects)
                color: Theme.palette.normal.baseText
                font.pixelSize: units.dp(32)
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -units.gu(1)
            }

            Column {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: units.gu(1)
                spacing: units.gu(0.2)

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: units.gu(0.5)
                    visible: root.comparisonMode === "previous" || root.comparisonMode === "both"
                    property var varianceData: PeriodHelper.formatVariance(root.currentProjects, root.prevProjects)
                    
                    Label {
                        text: parent.varianceData.percent
                        color: parent.varianceData.color
                        font.pixelSize: units.dp(12)
                    }
                    Label {
                        text: i18n.dtr("ubtms", "since last period")
                        color: Theme.palette.normal.backgroundText
                        font.pixelSize: units.dp(12)
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: units.gu(0.5)
                    visible: root.comparisonMode === "yoy" || root.comparisonMode === "both"
                    property var varianceData: PeriodHelper.formatVariance(root.currentProjects, root.yoyProjects)
                    
                    Label {
                        text: parent.varianceData.percent
                        color: parent.varianceData.color
                        font.pixelSize: units.dp(12)
                    }
                    Label {
                        text: i18n.dtr("ubtms", "vs last year")
                        color: Theme.palette.normal.backgroundText
                        font.pixelSize: units.dp(12)
                    }
                }
            }
        }
    }
}

