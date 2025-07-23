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
        spacing: units.gu(1)
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

            anchors.margins: units.gu(2)

            property int maxHeight: units.gu(16)

            TextArea {
                id: previewText
                textFormat: Text.RichText
                readOnly: is_read_only
                color : theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                wrapMode: Text.WordWrap
       
                width: parent.width - units.gu(2)
                anchors.horizontalCenter: parent.horizontalCenter

                  Rectangle {
                        // visible: !isReadOnly
                        anchors.fill: parent
                        color: "transparent"
                        radius: units.gu(0.5)
                        border.width: parent.activeFocus ? units.gu(0.2) : units.gu(0.1)
                        border.color: parent.activeFocus ? LomiriColors.orange : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#d3d1d1" : "#999")
                        // z: -1
                    }
              //  padding: units.gu(2)
            }


        
        }

        Label {
            id: readMoreLabel
            visible: true
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
