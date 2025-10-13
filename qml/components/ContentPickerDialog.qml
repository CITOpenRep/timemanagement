// ContentPickerDialog.qml
import QtQuick 2.4
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3 as Popups
import Lomiri.Content 1.3

Popups.PopupBase  {
    id: picker
    z: 100

    // true = export (send from your app to another), false = import (pick from device)
    property bool isExport: false

    // when exporting, pass a file url so we can resolve the content type
    property string fileUrl: ""

    // ContentHub plumbing
    property var activeTransfer
    signal complete()
    signal filesImported(var files)  // emitted on import (isExport === false)

    Rectangle {
        anchors.fill: parent

        ContentTransferHint {
            anchors.fill: parent
            activeTransfer: picker.activeTransfer
        }

        ContentPeerPicker {
            id: peerPicker
            anchors.fill: parent
            visible: true

            // For import, start with Documents or Pictures if All shows odd peers
            contentType:  isExport ? Content.resolveType(fileUrl) : ContentType.All
            handler:      isExport ? ContentHandler.Destination     : ContentHandler.Source

            onPeerSelected: {
                peer.selectionType = (isExport ? ContentTransfer.Single : ContentTransfer.Single)
                picker.activeTransfer = peer.request()
                stateChangeConnection.target = picker.activeTransfer
            }
            onCancelPressed: {
                PopupUtils.close(picker)
                picker.complete()
            }
        }
    }

    Connections {
        id: stateChangeConnection
        onStateChanged: {
            if (!picker.activeTransfer) return

            if (isExport && picker.activeTransfer.state === ContentTransfer.InProgress) {
                // Example export path (not used for your upload flow)
                picker.activeTransfer.items = [transferComponent.createObject(picker, { "url": fileUrl })]
                picker.activeTransfer.state = ContentTransfer.Charged
                closeTimer.start()

            } else if (!isExport && picker.activeTransfer.state === ContentTransfer.Charged) {
                // IMPORT: hand picked items to the caller and close
                picker.filesImported(picker.activeTransfer.items)
                closeTimer.start()
            }
        }
    }

    Timer {
        id: closeTimer
        interval: 350
        repeat: false
        onTriggered: {
            PopupUtils.close(picker)
            picker.complete()
        }
    }

    Component { id: transferComponent; ContentItem {} }
}
