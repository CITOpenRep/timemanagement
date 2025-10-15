// ContentPickerDialog.qml
import QtQuick 2.4
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.0 as Popups
import Lomiri.Content 1.3

Popups.PopupBase {
    id: picker
    z: 100

    // Props
    property bool isExport: true                  // true = open file with another app; false = import/pick file(s)
    property string fileUrl: ""                   // local path or file:// url for export
    property var activeTransfer
    signal complete
    signal filesImported(var files)

    // --- Simple type resolver (no singleton) ---
    function resolveType(fileUrl) {
        if (!fileUrl || fileUrl.length === 0)
            return ContentType.All;
        var ext = fileUrl.toString().toLowerCase();
        var lastDot = ext.lastIndexOf(".");
        if (lastDot === -1)
            return ContentType.All;
        ext = ext.substring(lastDot + 1);
        switch (ext) {
        case "png":
        case "jpg":
        case "jpeg":
        case "bmp":
        case "gif":
        case "webp":
        case "heic":
        case "heif":
        case "tif":
        case "tiff":
            return ContentType.Pictures;
        case "mp3":
        case "ogg":
        case "wav":
        case "m4a":
        case "opus":
        case "flac":
            return ContentType.Music;
        case "avi":
        case "mpeg":
        case "mp4":
        case "mkv":
        case "mov":
        case "wmv":
        case "webm":
            return ContentType.Videos;
        case "txt":
        case "doc":
        case "docx":
        case "xls":
        case "xlsx":
        case "ppt":
        case "pptx":
        case "pdf":
        case "odt":
        case "ods":
        case "odp":
        case "csv":
        case "html":
        case "rtf":
        case "md":
            return ContentType.Documents;
        case "vcard":
        case "vcf":
            return ContentType.Contacts;
        case "epub":
        case "mobi":
        case "azw3":
            return ContentType.EBooks;
        default:
            return ContentType.All;
        }
    }

    // --- Auto-pick Gallery for images ---
    property bool autoPickGallery: true
    // common gallery identifiers across UT variants
    property var _galleryIds: ["com.ubuntu.gallery", "lomiri.gallery", "gallery"]

    function _isImageExport() {
        return isExport && autoPickGallery && resolveType(fileUrl) === ContentType.Pictures;
    }

    function _startWithPeer(peer) {
        try {
            peer.selectionType = ContentTransfer.Single;
            picker.activeTransfer = peer.request();
            stateChangeConnection.target = picker.activeTransfer;
            return true;
        } catch (e) {
            console.log("[ContentPickerDialog] auto-pick failed:", e);
            return false;
        }
    }

    // Try to auto-select Gallery when dialog becomes visible (exporting images)
    onVisibleChanged: {
        if (!visible)
            return;
        if (!_isImageExport())
            return;

        // Defer until peers list is populated
        Qt.callLater(function () {
            var model = peerPicker.peers || peerPicker.model;   // depends on UT build
            var count = model && model.count ? model.count : 0;
            for (var i = 0; i < count; ++i) {
                var p = model.get(i);
                var id = ((p.appId || p.name || "") + "").toLowerCase();
                for (var j = 0; j < _galleryIds.length; ++j) {
                    if (id.indexOf(_galleryIds[j]) !== -1) {
                        if (_startWithPeer(p)) {
                            // transfer started programmatically; user won't see the dialog
                            return;
                        }
                    }
                }
            }
        // No gallery found -> fall back to normal picker UI
        });
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
            contentType: isExport ? picker.resolveType(fileUrl) : ContentType.All
            handler: isExport ? ContentHandler.Destination : ContentHandler.Source

            onPeerSelected: {
                // normal manual selection
                peer.selectionType = (isExport ? ContentTransfer.Single : ContentTransfer.Multiple);
                picker.activeTransfer = peer.request();
                stateChangeConnection.target = picker.activeTransfer;
            }
            onCancelPressed: {
                Popups.PopupUtils.close(picker);
                picker.complete();
            }
        }
    }

    Connections {
        id: stateChangeConnection
        onStateChanged: {
            if (!picker.activeTransfer)
                return;

            if (isExport && picker.activeTransfer.state === ContentTransfer.InProgress) {
                // Export: inject our local file, then charge + close
                picker.activeTransfer.items = [transferComponent.createObject(picker, {
                        "url": fileUrl
                    })];
                picker.activeTransfer.state = ContentTransfer.Charged;
                closeTimer.start();
            } else if (!isExport && picker.activeTransfer.state === ContentTransfer.Charged) {
                // Import: deliver selected items, then close
                picker.filesImported(picker.activeTransfer.items);
                closeTimer.start();
            }
        }
    }

    Timer {
        id: closeTimer
        interval: 350
        repeat: false
        onTriggered: {
            Popups.PopupUtils.close(picker);
            picker.complete();
        }
    }

    Component {
        id: transferComponent
        ContentItem {}
    }
}
