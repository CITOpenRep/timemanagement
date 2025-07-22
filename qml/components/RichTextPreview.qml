import QtQuick 2.7
import Lomiri.Components 1.3

Rectangle {
    id: root
    property alias text: previewText.text
    property string title: "Details"
    property bool is_read_only: true
    width: parent.width
    height: column.implicitHeight
    color: "transparent"

    signal clicked()

    Column {
        id: column
        width: parent.width
        spacing: units.gu(1)

        Item {
            id: textContainer
            width: parent.width
            height: maxHeight
            clip: true

            property int maxHeight: units.gu(10)

            Text {
                id: previewText
                textFormat: Text.RichText
                wrapMode: Text.WordWrap
                width: parent.width - units.gu(4)
                anchors.horizontalCenter: parent.horizontalCenter
                padding: units.gu(2)
            }
        }

        Label {
            id: readMoreLabel
            visible: previewText.paintedHeight > textContainer.maxHeight
            text: is_read_only ? "Read More" : "Edit"
            font.underline: true
            color: "blue"
            anchors.horizontalCenter: parent.horizontalCenter

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.clicked()
            }
        }
    }
}
