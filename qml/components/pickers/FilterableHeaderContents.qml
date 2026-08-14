import QtQuick 2.7
import QtQuick.Layouts 1.3
import Lomiri.Components 1.3

Item {
    id: root
    anchors.fill: parent

    property bool showDateFilter: false
    property string title: ""
    property bool showSubtitle: true
    property alias dateFilter: dateFilterItem

    signal dateRangeChanged()

    // Normal state: Title + filter subtitle
    RowLayout {
        anchors.fill: parent
        visible: !root.showDateFilter
        spacing: units.gu(1)

        ColumnLayout {
            spacing: 0
            Layout.alignment: Qt.AlignVCenter

            Label {
                text: root.title
                color: "white"
                fontSize: "large"
            }

            Label {
                text: dateFilterItem.presetLabel
                color: "white"
                fontSize: "small"
                opacity: 0.8
                visible: root.showSubtitle
            }
        }

        Item {
            Layout.fillWidth: true
        }
    }

    // Filter state: DateRangeHeaderFilter + close button
    Item {
        anchors.fill: parent
        visible: root.showDateFilter

        Item {
            anchors.left: parent.left
            anchors.right: closeFilterBtn.left
            anchors.rightMargin: units.gu(1)
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height

            DateRangeHeaderFilter {
                id: dateFilterItem
                anchors.fill: parent
                showClearButton: false
                onDateRangeChanged: {
                    root.dateRangeChanged();
                    root.showDateFilter = false;
                }
            }
        }

        Item {
            id: closeFilterBtn
            width: units.gu(4)
            height: units.gu(4)
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            Icon {
                name: "close"
                anchors.centerIn: parent
                width: units.gu(2.4)
                height: units.gu(2.4)
                color: "white"
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.showDateFilter = false;
                }
            }
        }
    }
}
