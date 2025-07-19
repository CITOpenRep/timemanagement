import QtQuick 2.7
import QtQuick.Controls 2.2
import Lomiri.Components 1.3

Rectangle {
    id: attachmentViewer
    width: parent.width
    height: parent.height
    color: "transparent"

    ListModel {
        id: attachmentModel
    }

    function setAttachments(list) {
        attachmentModel.clear();
        for (var i = 0; i < list.length; i++) {
            var item = list[i];
            attachmentModel.append({
                name: item.name,
                mimetype: item.mimetype,
                datas: item.datas
            });
        }
    }

    Column {
        id: headerColumn
        width: parent.width
        spacing: units.gu(1)
        padding: units.gu(1)

        Label {
            text: "Attachments"
            font.pixelSize: units.gu(2)
            color: "#333"
            horizontalAlignment: Text.AlignHCenter
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Label {
            visible: attachmentModel.count === 0
            text: "No files attached"
            font.italic: true
            color: "#777"
            horizontalAlignment: Text.AlignHCenter
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    Flickable {
        id: scrollArea
        anchors.top: headerColumn.bottom
        anchors.margins: 1
        width: parent.width
        height: parent.height - headerColumn.height - units.gu(2)
        contentWidth: width
        contentHeight: attachmentColumn.height
        clip: true

        Column {
            id: attachmentColumn
            width: scrollArea.width
            spacing: units.gu(1)

            Repeater {
                model: attachmentModel

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
                            width: units.gu(8)
                            height: units.gu(8)
                            sourceComponent: mimetype && mimetype.startsWith("image/") ? imagePreview : fileIcon
                            onLoaded: {
                                if (item) item.attachment = { name: name, mimetype: mimetype, datas: datas };
                            }
                        }

                        Column {
                            spacing: units.gu(0.3)
                            width: scrollArea.width - units.gu(20)

                            Text {
                                text: name
                                font.bold: true
                                elide: Text.ElideRight
                                wrapMode: Text.Wrap
                                horizontalAlignment: Text.AlignHCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
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
                    attachmentDialog.imageSource = "data:" + attachment.mimetype + ";base64," + attachment.datas
                    attachmentDialog.open()
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
            Rectangle {
                color: "white"
                width: parent.width
                height: parent.height
                anchors.horizontalCenter: parent.horizontalCenter
                Text {
                    text: attachment && attachment.mimetype ? attachment.mimetype.split("/")[1].toUpperCase() : "FILE"
                    font.pixelSize: units.gu(1)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

    Dialog {
        id: attachmentDialog
        property string imageSource: ""
        width: parent.width
        height: parent.height
        anchors.centerIn: parent
        modal: true

        Rectangle {
            anchors.fill: parent
            color: "#00000088"  // semi-transparent dark background

            // Image Preview
            Image {
                anchors.centerIn: parent
                width: parent.width * 0.9
                height: parent.height * 0.9
                fillMode: Image.PreserveAspectFit
                source: attachmentDialog.imageSource
                asynchronous: true
                cache: false
                onStatusChanged: {
                    if (status === Image.Error) {
                        console.error("❌ Failed to load image:", source);
                    }
                }
            }

            // Close Button
            Button {
                id: closeBtn
                text: "\u2715" // Unicode for ×
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: units.gu(1)
                anchors.rightMargin: units.gu(1)
                width: units.gu(4)
                height: units.gu(4)
                onClicked: attachmentDialog.close()
            }
        }
    }

}
