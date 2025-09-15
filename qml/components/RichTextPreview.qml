import QtQuick 2.7
import Lomiri.Components 1.3

Rectangle {
    id: root
    property alias text: previewText.text
    property string title: "Description"
    property bool is_read_only: true
    property bool useRichText: true
    width: parent.width
    height: parent.height//column.implicitHeight
    color: "transparent"

    signal clicked

    // Function to get the raw text content with formatting preserved
    function getFormattedText() {
        if (useRichText && previewText.textFormat === Text.RichText) {
            // For rich text, return the text as-is since it should preserve basic formatting
            return previewText.text;
        } else {
            return previewText.text;
        }
    }

    Column {
        id: column
        width: parent.width
        height: parent.height
        spacing: units.gu(1)
        Label {
            text: title
            anchors.left: parent.left
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
                textFormat: useRichText ? Text.RichText : Text.PlainText

                readOnly: is_read_only
                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                wrapMode: Text.WordWrap
                font.pixelSize: units.gu(2)

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

                Item {
                    id: floatingActionButton
                    width: units.gu(3)
                    height: units.gu(3)
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: units.gu(1)
                    anchors.bottomMargin: units.gu(1)
                    z: 10
                    visible: true

                    Rectangle {

                        radius: units.gu(.5)
                        color: LomiriColors.orange
                        anchors.fill: parent
                        Image {
                            id: expansionIcon

                            source: "../images/expansion.png"
                            width: units.gu(1.5)
                            height: units.gu(1.5)
                            // anchors.right: parent.right
                            //  anchors.rightMargin: units.gu(2)
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.clicked()
                            }
                        }
                    }
                }
                //  padding: units.gu(2)
            }
        }
    }
}
