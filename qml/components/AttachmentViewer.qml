import QtQuick 2.7
import QtQuick.Controls 2.2
import Lomiri.Components 1.3
import Lomiri.Content 1.4
import io.thp.pyotherside 1.4

Column {
    id: attachmentViewer
    width: parent.width
    height: parent.height
    spacing: units.gu(1)
    property list<ContentItem> importItems
    property var activeTransfer
    property int importId: 0
    property int account_id
    property var resource_id
    property string resource_type:"project.project"

    property string dialogImageSource: ""

    Python {
        id: python

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('../src/'));

            importModule('example', function() {
                console.log('module imported');
            });
        }

        onError: {
            console.log('python error: ' + traceback);
        }
    }

    ContentPeer {
        id: attachmentSource
        contentType: ContentType.Pictures
        handler: ContentHandler.Source
        selectionType: ContentTransfer.Single
    }

    ContentTransferHint {
        id: importHint
        anchors.fill: parent
        activeTransfer: attachmentViewer.activeTransfer
    }

    Connections {
        target: attachmentViewer.activeTransfer

        onStateChanged: {
            if (!attachmentViewer.activeTransfer)
            {
                console.log("Attachment is empty")
                return
            }
            if (attachmentViewer.activeTransfer.state === ContentTransfer.Charged) {
                importItems = attachmentViewer.activeTransfer.items
                console.log("ImportItems count:", importItems.length)

                // Process each imported item
                for (var i = 0; i < importItems.length; i++) {
                    var item = importItems[i]
                    console.log("Item #" + i + " URL: " + item.url)
                    // Convert QUrl to string and get local file path
                    var filePath = item.url.toString().replace(/^file:\/\//, "")

                    python.call("backend.resolve_qml_db_path", ["ubtms"], function (path) {
                        if (!path) {
                            console.warn("DB not found.");
                            return;
                        }
                        console.log("Resource is is " + resource_id)
                        // 2) call backend with 3 args: path, account_id, odoo_record_id
                            python.call("backend.attachment_upload",
                                        [path, account_id, filePath,resource_type,16],
                            function (res) {
                            if (!res) {
                                console.warn("No response from attachment_upload");
                                return;
                            }
                            else
                            {
                                console.log("Returned value is  " + res)
                                //3. We must need to do a sync to ensure that local db is aligned
                                python.call("backend.start_sync_in_background", [path,account_id], function (result) {
                                    if (result) {
                                        console.log("Background sync started for account:", account_id);
                                    } else {
                                        console.warn("Failed to start sync for account:", account_id);
                                    }
                                });
                            }
                        });

                    });

                }
            }
        }
    }

    Button{
        text:"Add files"
        anchors.horizontalCenter: parent.horizontalCenter
        onClicked:
        {
            activeTransfer = attachmentSource.request()
        }
    }

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
                odoo_record_id: model.odoo_record_id
                account_id:model.account_id

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
