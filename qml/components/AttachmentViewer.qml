// AttachmentViewer.qml
import QtQuick 2.7
import QtQuick.Controls 2.2
import Lomiri.Components 1.3

Column {
    id: viewer
    property var attachments: []

    spacing: units.gu(1)

    Repeater {
        model: attachments

        delegate: Rectangle {
            width: parent.width
            height: units.gu(12)
            color: "#f9f9f9"
            radius: units.gu(0.5)
            border.width: 1
            border.color: "#ccc"
            anchors.horizontalCenter: parent.horizontalCenter

            Row {
                spacing: units.gu(1)
                anchors.fill: parent
                anchors.margins: units.gu(1)

                Loader {
                    id: dynamicLoader
                    width: units.gu(8)
                    height: units.gu(8)
                    sourceComponent: modelData && modelData.mimetype && modelData.mimetype.startsWith("image/")
                                     ? imagePreview
                                     : fileIcon
                    onLoaded: {
                        if (item) item.attachment = modelData;
                    }
                }

                Column {
                    spacing: units.gu(0.3)
                    width: viewer.width - units.gu(16)

                    Text {
                        text: modelData.name
                        font.bold: true
                        elide: Text.ElideRight
                        wrapMode: Text.Wrap
                    }

                    Text {
                        text: modelData.mimetype
                        color: "#666"
                        font.pixelSize: units.gu(1.5)
                        wrapMode: Text.Wrap
                    }
                }
            }
        }
    }


    Component {
        id: imagePreview

        Item {
            width: units.gu(8)
            height: units.gu(8)
            property var attachment

            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                source: "data:" + attachment.mimetype + ";base64," + attachment.datas
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    attachmentDialog.imageSource =
                        "data:" + attachment.mimetype + ";base64," + attachment.datas;
                    attachmentDialog.open();
                }
            }
        }
    }

    Component {
        id: fileIcon

        Rectangle {
            width: units.gu(8)
            height: units.gu(8)
            radius: units.gu(0.3)
            color: "#dddddd"
            border.color: "#aaa"
            property var attachment

            Column {
                anchors.centerIn: parent
                spacing: units.gu(0.5)

                Rectangle {
                    color: "red"
                    width: units.gu(4)
                    height: units.gu(4)
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: attachment && attachment.mimetype ? attachment.mimetype.split("/")[1].toUpperCase() : "FILE"
                    font.pixelSize: units.gu(1.5)
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }


    Dialog {
        id: attachmentDialog
        property string imageSource: ""

        width: units.gu(80)
        height: units.gu(80)

        Image {
            anchors.centerIn: parent
            width: parent.width * 0.9
            height: parent.height * 0.9
            fillMode: Image.PreserveAspectFit
            source: attachmentDialog.imageSource
        }
    }
}
