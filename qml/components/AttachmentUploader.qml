import QtQuick 2.7
import QtQuick.Controls 2.2
import Lomiri.Components 1.3
import io.thp.pyotherside 1.4
import Lomiri.Content 1.3
import Lomiri.Components.Popups 1.3
import QtQuick.Window 2.2

Row {
    id: attachmentUploader
    width: parent.width
    height: parent.height
    property list<ContentItem> importItems
    property var activeTransfer
    property int importId: 0
    property int account_id
    property int resource_id
    property string resource_type: "project.project"
    spacing: units.gu(0.2)
    signal processed
    signal failed

    property string dialogImageSource: ""

    Component.onCompleted: {
        backend_bridge.messageReceived.connect(handleSyncEvent);
    }

    // Handle sync events from Python backend
    function handleSyncEvent(data) {
        if (!data || !data.event)
            return;

        //console.log("handleSyncEvent: Received sync event:", data.event, "Payload:", data.payload);

        switch (data.event) {
        case "sync_progress":
            break;
        case "ondemand_upload_message":
            infobar.open(data.payload);
            break;
        case "sync_completed":
            if (data.payload === true)
                console.log("");
            else
                //completeSyncSuccessfully();
                console.log("");
            //failSync("Sync Failed ");
            break;
        case "ondemand_upload_completed":
            if (data.payload === true) {
                infobar.open("Attachment has been processed", 2000);
                processed();
            } else
                infobar.open("Failed to upload", 2000);
            break;
        }
    }

    Python {
        id: python

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('../src/'));

            importModule('backend', function () {
                console.log('module imported');
            });
        }

        onError: {
            console.log('python error: ' + traceback);
        }
    }

    ContentPeerPicker {
        id: attachmentSource
        headerText: "Upload from Device"
        contentType: ContentType.All
        handler: ContentHandler.Source
        onPeerSelected: {
            peer.selectionType = ContentTransfer.Single;
            activeTransfer = peer.request();
            signalConnections.target = attachmentUploader;
        }

        onCancelPressed: {
            PopupUtils.close(attachmentUploader.attachmentSource);
        }
    }

    NotificationPopup {
        id: notifPopup
        width: units.gu(80)
        height: units.gu(80)
    }

    ContentTransferHint {
        id: importHint
        anchors.fill: parent
        activeTransfer: attachmentUploader.activeTransfer
    }

    Connections {
        target: attachmentUploader.activeTransfer

        onStateChanged: {
            if (!attachmentUploader.activeTransfer) {
                console.log("Attachment is empty");
                return;
            }
            if (attachmentUploader.activeTransfer.state === ContentTransfer.Charged) {
                importItems = attachmentUploader.activeTransfer.items;
                console.log("ImportItems count:", importItems.length);

                // Process each imported item
                for (var i = 0; i < importItems.length; i++) {
                    var item = importItems[i];
                    console.log("Item #" + i + " URL: " + item.url);
                    // Convert QUrl to string and get local file path
                    var filePath = item.url.toString().replace(/^file:\/\//, "");

                    python.call("backend.resolve_qml_db_path", ["ubtms"], function (path) {
                        if (!path) {
                            //notifPopup.open("Error", "Attachment Failed", "error");
                            failed();
                            return;
                        }
                        python.call("backend.attachment_upload", [path, attachmentUploader.account_id, filePath, attachmentUploader.resource_type, attachmentUploader.resource_id], function (res) {
                            if (!res) {
                                console.warn("No response from attachment_upload");
                                infobar.open("Failed to upload", 2000);
                                return;
                            }
                        });
                    });
                }
            }
        }
    }
}
