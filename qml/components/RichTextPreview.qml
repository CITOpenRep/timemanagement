import QtQuick 2.7
import Lomiri.Components 1.3

Rectangle {
    id: root
    property alias text: previewText.text
    property string title: "Description"
    property bool is_read_only: true
    width: parent.width
    height: parent.height//column.implicitHeight
    color: "transparent"

    signal clicked()

    Column {
        id: column
        width: parent.width
        height:parent.height
        spacing: units.gu(0)
        Label {
            text:title
            anchors.left:parent.left
            anchors.leftMargin: units.gu(2)
        }

        Item {
            id: textContainer
            width: parent.width
            height: maxHeight
            clip: true

            property int maxHeight: units.gu(16)

            Text {
                id: previewText
                textFormat: Text.RichText
                wrapMode: Text.WordWrap
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                padding: units.gu(2)
            }
        }

        Label {
            id: readMoreLabel
            visible: previewText.paintedHeight > textContainer.maxHeight || !is_read_only
            text: is_read_only ? "Read More" : "Edit"
            font.underline: true
            color: "blue"
            anchors.right:parent.right
            anchors.rightMargin: units.gu(2)

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.clicked()
            }
        }
    }
}
