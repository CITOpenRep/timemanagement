import QtQuick 2.7
import QtQuick.Controls 2.2
import Lomiri.Components 1.3

Column {
    id: attachmentViewer
    width: parent.width
    height: parent.height
    spacing: units.gu(1)

    property string dialogImageSource: ""

    Label {
        text: "Attachments"
        font.pixelSize: units.gu(2)
        font.bold: true
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Label {
        visible: attachmentModel.count === 0
        text: "No files attached"
        font.italic: true
        color: "#777"
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Rectangle {
        width: parent.width - units.gu(2) // leave some margin so centering makes sense
        anchors.horizontalCenter: parent.horizontalCenter
        height: (attachmentModel.count === 0) ? units.gu(1) : parent.height - units.gu(8)
        color: "transparent"
        border.color: "#ccc"
        border.width: (attachmentModel.count === 0) ? 0 : 1
        radius: units.gu(0.5) // Optional rounded corners

        GridView {
            id: gridView
            anchors.fill: parent
            anchors.margins: units.gu(1) // Optional padding inside the border
            model: attachmentModel
            clip: true

            cellWidth: Math.floor(parent.width / 3) - spacing
            cellHeight: cellWidth

            delegate: AttachmentCard {
                width: gridView.cellWidth
                height: gridView.cellHeight
                name: model.name
                mimetype: model.mimetype
                datas: model.datas

                onImageClicked: {
                    dialogImageSource = "data:" + mimetype + ";base64," + datas;
                    attachmentDialog.open();
                }
            }
        }
    }

    Dialog {
        id: attachmentDialog
        width: parent.width
        height: parent.height
        modal: true

        Rectangle {
            anchors.fill: parent
            color: "#00000088"

            Image {
                anchors.centerIn: parent
                width: parent.width * 0.9
                height: parent.height * 0.9
                fillMode: Image.PreserveAspectFit
                source: dialogImageSource
            }

            Button {
                text: "\u2715"
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: units.gu(1)
                width: units.gu(4)
                height: units.gu(4)
                onClicked: attachmentDialog.close()
            }
        }
    }

    ListModel {
        id: attachmentModel
    }

    function setAttachments(list) {
        attachmentModel.clear();
        for (var i = 0; i < list.length; i++) {
            attachmentModel.append(list[i]);
        }
    }
}
