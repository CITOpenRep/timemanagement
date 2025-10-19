import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Window 2.2
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.Content 1.3
import io.thp.pyotherside 1.4

// DB helpers
import "../../models/accounts.js" as Accounts

// --- Fullscreen Image Previewer (Download → Open in…) ---
Rectangle {
    id: imagePreviewer
    anchors.fill: parent
    color: "#444"
    visible: false
    z: 999
    focus: true

    // Provided by caller when opening the preview
    property url imageSource: ""
    property string originalFilename: ""
    property string mimetype: "image/*"
    property int accountId: 0
    property int recordId: 0
    property bool busy: false
    property var notifier: (typeof attachmentManager !== "undefined") ? attachmentManager.notifier : null

    // Internal: has this attachment been exported at least once?
    property bool _downloadedOnce: false

    // Refresh the flag whenever a new item shows up
    onVisibleChanged: if (visible) _refreshDownloadedFlag()
    onRecordIdChanged: _refreshDownloadedFlag()
    onAccountIdChanged: _refreshDownloadedFlag()

    function _refreshDownloadedFlag() {
        if (!accountId || !recordId) { _downloadedOnce = false; return; }
        _downloadedOnce = Accounts.isAttachmentDownloaded(accountId, recordId);
    }

    // PY bridge present but not used in Option A; keep if other parts rely on it
    Python {
        id: python
        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl("../src/"));
            importModule("backend", function () { console.log("[ImagePreviewer] backend imported"); });
        }
        onError: function (name, msg, tb) { console.error("[ImagePreviewer][py] " + name + ": " + msg + "\n" + tb); }
    }

    Image {
        id: overlayImage
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
        source: imagePreviewer.imageSource
    }

    // Close (X)
    Button {
        id: closeBtn
        text: "\u2715"
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: units.gu(1)
        onClicked: imagePreviewer.visible = false
    }

    // Download / Open in…
    Button {
        id: downloadBtn
        text:  i18n.dtr("ubtms", "Download")
        visible: imagePreviewer._downloadedOnce ? false:true
        anchors.right: parent.right
        anchors.horizontalCenter: parent
        anchors.bottom: parent.bottom
        anchors.margins: units.gu(2)
        enabled: !imagePreviewer.busy
        onClicked: {
            if (imagePreviewer._downloadedOnce)
                imagePreviewer._openWith();
            else
                imagePreviewer._exportOnce();
        }
    }

    // Busy overlay
    Rectangle {
        anchors.fill: parent
        color: "#00000055"
        visible: imagePreviewer.busy
        BusyIndicator {
            anchors.centerIn: parent
            running: parent.visible
            visible: running
        }
    }

    // Your existing Content Hub dialog (export mode)
    Component {
        id: contentExporterComponent
        ContentPickerDialog {
            id: exportDlg
            isExport: true
            // fileUrl, autoPickGallery, host, mode are passed via PopupUtils.open params
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: imagePreviewer.visible = false
        propagateComposedEvents: true
        onPressed: mouse.accepted = false
    }

    Keys.onEscapePressed: imagePreviewer.visible = false

    function _notify(msg) {
        if (imagePreviewer.notifier && imagePreviewer.notifier.open) imagePreviewer.notifier.open(msg, 2000);
        else console.log("[ImagePreviewer]", msg);
    }

    function _exportOnce() {
        var src = imagePreviewer.imageSource ? imagePreviewer.imageSource.toString() : "";
        if (!src || src.length === 0) { _notify(i18n.dtr("ubtms","No image to save")); return; }

        var fileUrl = (src.indexOf("file://") === 0) ? src : ("file://" + src);

        try {
            // Open by URL; then set properties on the instance
            var dlg = PopupUtils.open(Qt.resolvedUrl("ContentPickerDialog.qml"));
            if (dlg) {
                dlg.isExport = true;
                dlg.fileUrl = fileUrl;
                dlg.host = imagePreviewer;
                // only set this if your dialog defines it (yours does)
                dlg.autoPickGallery = true;

                dlg.complete.connect(function () {
                    // Mark as downloaded in your DB (per account/record)
                    if (imagePreviewer.accountId && imagePreviewer.recordId) {
                        Accounts.markAttachmentDownloaded(
                            imagePreviewer.accountId,
                            imagePreviewer.recordId,
                            imagePreviewer.originalFilename || ""
                        );
                        imagePreviewer._downloadedOnce = true;
                    }
                    _notify(i18n.dtr("ubtms","Saved"));
                });

                _notify(i18n.dtr("ubtms","Choose where to save"));
            } else {
                _notify(i18n.dtr("ubtms","Could not open export dialog"));
            }
        } catch (e) {
            console.error("[ImagePreviewer] export error:", e);
            _notify(i18n.dtr("ubtms","Save failed"));
        }
    }

    function _openWith() {
        var src = imagePreviewer.imageSource ? imagePreviewer.imageSource.toString() : "";
        if (!src || src.length === 0) { _notify(i18n.dtr("ubtms","No image to open")); return; }

        var fileUrl = (src.indexOf("file://") === 0) ? src : ("file://" + src);

        try {
            // Same pattern: open by URL, set props on instance
            var dlg = PopupUtils.open(Qt.resolvedUrl("ContentPickerDialog.qml"));
            if (dlg) {
                dlg.isExport = true;
                dlg.fileUrl = fileUrl;
                dlg.host = imagePreviewer;
                // For "Open in…" do NOT auto-pick Gallery; let user choose a viewer
                dlg.autoPickGallery = false;

                dlg.complete.connect(function () {
                    _notify(i18n.dtr("ubtms","Done"));
                });
            } else {
                _notify(i18n.dtr("ubtms","Could not open chooser"));
            }
        } catch (e) {
            console.error("[ImagePreviewer] open-with error:", e);
            _notify(i18n.dtr("ubtms","Open failed"));
        }
    }

}
