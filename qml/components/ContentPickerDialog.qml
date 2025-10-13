// ContentPickerDialog.qml


// ContentPickerDialog.qml
import QtQuick 2.4
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.0 as Popups
import Lomiri.Content 1.3
// If ContentResolver.qml is in the same dir:
import "." as Utils
// If it lives in qml/utils/, use: import "qml/utils" as Utils

Popups.PopupBase  {
    id: picker
    z: 100

    property bool isExport: true
    property string fileUrl: ""       // local path or file:// url
    property var activeTransfer
    signal complete()
    signal filesImported(var files)

    function resolveType(fileUrl) {
        if (!fileUrl || fileUrl.length === 0)
            return ContentType.All;

        var ext = fileUrl.toString().toLowerCase();
        var lastDot = ext.lastIndexOf(".");
        if (lastDot === -1)
            return ContentType.All;

        ext = ext.substring(lastDot + 1);

        switch (ext) {
        case "png": case "jpg": case "jpeg": case "bmp": case "gif":
        case "webp": case "heic": case "heif":
            return ContentType.Pictures;

        case "mp3": case "ogg": case "wav": case "m4a": case "opus": case "flac":
            return ContentType.Music;

        case "avi": case "mpeg": case "mp4": case "mkv": case "mov": case "wmv": case "webm":
            return ContentType.Videos;

        case "txt": case "doc": case "docx": case "xls": case "xlsx": case "ppt":
        case "pptx": case "pdf": case "odt": case "ods": case "odp": case "csv":
        case "html": case "rtf": case "md":
            return ContentType.Documents;

        case "vcard": case "vcf":
            return ContentType.Contacts;

        case "epub": case "mobi": case "azw3":
            return ContentType.EBooks;

        default:
            return ContentType.All;
        }
    }


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
            contentType: isExport
                         ? picker.resolveType(fileUrl)
                         : ContentType.All
            handler:     isExport ? ContentHandler.Destination
                                  : ContentHandler.Source

            onPeerSelected: {
                peer.selectionType = (isExport ? ContentTransfer.Single
                                               : ContentTransfer.Multiple)
                picker.activeTransfer = peer.request()
                stateChangeConnection.target = picker.activeTransfer
            }
            onCancelPressed: {
                Popups.PopupUtils.close(picker)
                picker.complete()
            }
        }
    }

    Connections {
        id: stateChangeConnection
        onStateChanged: {
            if (!picker.activeTransfer) return

            if (isExport && picker.activeTransfer.state === ContentTransfer.InProgress) {
                // use the local file we’re “opening with…”
                picker.activeTransfer.items = [transferComponent.createObject(picker, { "url": fileUrl })]
                picker.activeTransfer.state = ContentTransfer.Charged
                closeTimer.start()

            } else if (!isExport && picker.activeTransfer.state === ContentTransfer.Charged) {
                // import: hand items back to caller
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
            Popups.PopupUtils.close(picker)
            picker.complete()
        }
    }

    Component { id: transferComponent; ContentItem {} }
}
