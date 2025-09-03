import QtQuick 2.7
import QtQuick.Controls 2.2
import Lomiri.Components 1.3
import io.thp.pyotherside 1.4
import Lomiri.Content 1.3
import Lomiri.Components.Popups 1.3

Row {
    id: attachmentUploader
    width: parent.width
    height: parent.height
    property list<ContentItem> importItems
    property var activeTransfer
    property int importId: 0
    property int account_id
    property int resource_id
    property string resource_type:"project.project"
    spacing: units.gu(0.2)

    property string dialogImageSource: ""

    Python {
        id: python

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('../src/'));

            importModule('backend', function() {
                console.log('module imported');
            });
        }

        onError: {
            console.log('python error: ' + traceback);
        }
    }

    ContentPeerPicker {
        id: attachmentSource
        headerText:"Upload from Device"
        contentType:  ContentType.All
        handler: ContentHandler.Source
        onPeerSelected: {
            peer.selectionType = ContentTransfer.Single
            activeTransfer = peer.request()
            signalConnections.target = attachmentUploader
        }

        onCancelPressed: {
            PopupUtils.close(attachmentUploader.attachmentSource)
        }

    }

    ContentTransferHint {
        id: importHint
        anchors.fill: parent
        activeTransfer: attachmentUploader.activeTransfer
    }

    Connections {
        target: attachmentUploader.activeTransfer

        onStateChanged: {
            if (!attachmentUploader.activeTransfer)
            {
                console.log("Attachment is empty")
                return
            }
            if (attachmentUploader.activeTransfer.state === ContentTransfer.Charged) {
                importItems = attachmentUploader.activeTransfer.items
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
                        console.log("Resource is is " + attachmentUploader.resource_id)
                        // 2) call backend with 3 args: path, account_id, odoo_record_id
                        python.call("backend.attachment_upload",
                                    [path, attachmentUploader.account_id, filePath,attachmentUploader.resource_type,attachmentUploader.resource_id],
                                    function (res) {
                                        if (!res) {
                                            console.warn("No response from attachment_upload");
                                            return;
                                        }
                                        else
                                        {
                                            //3. We must need to do a sync to ensure that local db is aligned
                                            console.log("Syncing :", path);
                                            python.call("backend.start_sync_in_background", [path,attachmentUploader.account_id], function (result) {
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

}
