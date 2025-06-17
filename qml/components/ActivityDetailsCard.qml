import QtQuick 2.7
import Lomiri.Components 1.3
import "../../models/utils.js" as Utils
import "../../models/activity.js" as Activity

ListItem {
    id: root
    width: parent.width
    height: units.gu(10)

    property string notes: ""
    property string activity_type_name: ""
    property string summary: ""
    property int activity_type_id: -1
    property string user: ""
    property string due_date: ""
    property string state: ""
    property int id: -1
    property var odoo_record_id

    signal cardClicked(int recordid)

    function truncateText(text, maxLength) {
        if (text.length > maxLength) {
            return text.slice(0, maxLength) + '...';
        }
        return text;
    }

    Rectangle {
        id: left_rect
        anchors.fill: parent
        border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#444" : "#dcdcdc"
        radius: units.gu(0.2)
        anchors.leftMargin: units.gu(0.2)
        anchors.rightMargin: units.gu(0.2)
        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#111" : "#fff"

        Row {
            anchors.fill: parent
            spacing: units.gu(2)

            Image {
                width: parent.height / 2
                height: parent.height / 2
                fillMode: Image.PreserveAspectFit
                source: "../images/" + Activity.getActivityIconForType(activity_type_name)
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                id: leftrect
                width: parent.width * 0.60
                height: parent.height
                color: "transparent"

                Row {
                    width: parent.width
                    height: parent.height
                    spacing: units.gu(0.4)

                    Column {
                        width: parent.width - units.gu(4)
                        height: parent.height - units.gu(2)
                        spacing: 0

                        Text {
                            text: (typeof root.summary === "string" && root.summary.trim() !== "" && root.summary !== "0") ? truncateText(root.summary, 300) : "No Summary"
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                            font.pixelSize: units.gu(2)
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            clip: true
                            width: parent.width - units.gu(2)
                        }

                        Text {
                            text: (typeof root.notes === "string" && root.notes.trim() !== "" && root.notes !== "0") ? truncateText(root.notes, 300) : "No Notes"
                            font.pixelSize: units.gu(1.6)
                            wrapMode: Text.NoWrap
                            elide: Text.ElideRight
                            width: parent.width - units.gu(2)
                            height: units.gu(2)
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#bbb" : "#222"
                        }

                        Text {
                            text: root.user ? "Assigned to: " + root.user : "Unassigned"
                            width: parent.width - units.gu(2)
                            font.pixelSize: units.gu(1.6)
                            height: units.gu(3)
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#80bfff" : "#222"
                        }
                    }
                }
            }

            Rectangle {
                id: right_rect
                width: parent.width * 0.40  // 25% of total width
                height: parent.height
                color: "transparent"

                Column {
                    anchors.fill: parent
                    anchors.margins: units.gu(1)
                    spacing: units.gu(0.4)

                    Text {
                        text: root.activity_type_name || ("Type ID: " + root.activity_type_id)
                        font.pixelSize: units.gu(1.5)
                        horizontalAlignment: Text.AlignRight
                        width: units.gu(6)
                        height: units.gu(2.2)
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#bbb" : "#555"
                    }

                    Text {
                        text: Qt.formatDate(new Date(root.due_date), "dd MMM")
                        font.pixelSize: units.gu(1.5)
                        horizontalAlignment: Text.AlignRight
                        width: units.gu(6)
                        height: units.gu(2.2)
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#bbb" : "#222"
                    }

                    Rectangle {
                        width: units.gu(6)
                        height: units.gu(2.2)
                        color: root.state === "done" ? "#4CAF50" : root.state === "open" ? "#FF9800" : "#9E9E9E"

                        Text {
                            anchors.centerIn: parent
                            text: root.state ? root.state.toUpperCase() : "N/A"
                            font.pixelSize: units.gu(1.2)
                            color: "white"
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.cardClicked(root.odoo_record_id)
    }
}
