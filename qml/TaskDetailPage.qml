// Task detail page showing summary metrics, task metadata, and newest-first time logs.
import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Layouts 1.12
import "chartUtils.js" as ChartUtils

Page {
    id: root

    property var taskData: ({})
    property string projectName: ""

    header: PageHeader {
        id: pageHeader
        title: taskData ? taskData.name : ""
        subtitle: projectName
        flickable: detailsFlickable
    }

    Flickable {
        id: detailsFlickable
        anchors.fill: parent
        contentWidth: width
        contentHeight: detailsColumn.height
        clip: true

        Column {
            id: detailsColumn
            width: detailsFlickable.width
            spacing: units.gu(1.5)

            Grid {
                width: parent.width - units.gu(3)
                anchors.horizontalCenter: parent.horizontalCenter
                columns: 2
                spacing: units.gu(1)

                Repeater {
                    model: [
                        {
                            label: i18n.dtr("ubtms", "Time spent"),
                            value: ChartUtils.formatHours(taskData ? taskData.totalHours : 0)
                        },
                        {
                            label: i18n.dtr("ubtms", "% of project"),
                            value: taskData && taskData.projectTotalHours ?
                                       ChartUtils.percentLabel(taskData.totalHours, taskData.projectTotalHours) :
                                       i18n.dtr("ubtms", "0.0%")
                        }
                    ]

                    delegate: UbuntuShape {
                        width: (parent.width - units.gu(1)) / 2
                        height: units.gu(10)
                        color: Theme.palette.normal.base

                        Column {
                            anchors.fill: parent
                            anchors.margins: units.gu(1.5)
                            spacing: units.gu(0.5)

                            Label {
                                text: modelData.label
                                color: Theme.palette.normal.backgroundText
                                font.pixelSize: units.dp(12)
                            }

                            Label {
                                text: modelData.value
                                color: Theme.palette.normal.baseText
                                font.bold: true
                                font.pixelSize: units.dp(14)
                            }
                        }
                    }
                }
            }

            UbuntuShape {
                width: parent.width - units.gu(3)
                anchors.horizontalCenter: parent.horizontalCenter
                implicitHeight: metaColumn.implicitHeight + units.gu(3)
                color: Theme.palette.normal.base

                Column {
                    id: metaColumn
                    anchors.fill: parent
                    anchors.margins: units.gu(1.5)
                    spacing: units.gu(1)

                    Repeater {
                        model: [
                            { label: i18n.dtr("ubtms", "Assignee"), value: taskData.assignee || i18n.dtr("ubtms", "Unassigned") },
                            { label: i18n.dtr("ubtms", "Status"), value: taskData.status || i18n.dtr("ubtms", "Unknown") },
                            { label: i18n.dtr("ubtms", "Project"), value: projectName },
                            { label: i18n.dtr("ubtms", "Log entries count"), value: String(taskData.logs ? taskData.logs.length : 0) }
                        ]

                        delegate: RowLayout {
                            width: parent.width

                            Label {
                                Layout.preferredWidth: units.gu(12)
                                text: modelData.label
                                color: Theme.palette.normal.backgroundText
                                font.pixelSize: units.dp(12)
                            }

                            Label {
                                Layout.fillWidth: true
                                text: modelData.value
                                color: Theme.palette.normal.baseText
                                font.pixelSize: units.dp(12)
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }
            }

            Column {
                width: parent.width - units.gu(3)
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: units.gu(0.8)

                Label {
                    text: i18n.dtr("ubtms", "Time log")
                    color: Theme.palette.normal.baseText
                    font.bold: true
                    font.pixelSize: units.dp(14)
                }

                Repeater {
                    model: taskData.logs || []

                    delegate: UbuntuShape {
                        width: parent.width
                        height: units.gu(7)
                        color: Theme.palette.normal.base

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: units.gu(1.5)
                            anchors.rightMargin: units.gu(1.5)
                            spacing: units.gu(1)

                            Label {
                                Layout.preferredWidth: units.gu(9)
                                text: modelData.date || ""
                                color: Theme.palette.normal.baseText
                                font.pixelSize: units.dp(12)
                                elide: Text.ElideRight
                            }

                            Label {
                                Layout.fillWidth: true
                                text: modelData.note || i18n.dtr("ubtms", "No note")
                                color: Theme.palette.normal.backgroundText
                                font.pixelSize: units.dp(12)
                                elide: Text.ElideRight
                            }

                            Label {
                                text: ChartUtils.formatHours(modelData.hours || 0)
                                color: Theme.palette.normal.baseText
                                font.bold: true
                                font.pixelSize: units.dp(12)
                            }
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: units.gu(2)
            }
        }
    }
}
