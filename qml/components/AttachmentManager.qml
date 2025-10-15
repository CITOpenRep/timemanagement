/*
 * MIT License
 * Copyright (c) 2025
 */

import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Window 2.2
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.Content 1.3
import io.thp.pyotherside 1.4

Item {
    id: attachmentManager
    width: parent ? parent.width : 0
    height: implicitHeight

    // ----------- Public API -----------
    property int account_id: 0
    property string resource_type: "project.project"
    property int resource_id: 0

    /** Optional: provide your own model. If not set, we use internalModel. */
    property alias model: listView.model

    /** Optional: notifier with .open(msg, ms) (e.g., your infobar). */
    property var notifier: null

    /** Title shown above the list */
    property string title: i18n.dtr("ubtms", "Attachments")

    /** Read-only: live transfer (for hint) */
    property var activeTransfer: null

    /** Signals */
    signal uploadStarted
    signal uploadCompleted
    signal uploadFailed
    signal itemClicked(var item)

    // ----------- Internal state -----------
    property list<ContentItem> _importItems
    property bool _busy: false

    // Fallback ListModel
    ListModel {
        id: internalModel
    }

    readonly property bool _usingInternalModel: listView.model === internalModel

    Component.onCompleted: {
        if (!listView.model)
            listView.model = internalModel;
        if (typeof backend_bridge !== "undefined" && backend_bridge.messageReceived) {
            backend_bridge.messageReceived.connect(_handleSyncEvent);
        }
    }

    // ----------- Header + Upload button -----------
    ColumnLayout {
        id: rootLayout
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: units.gu(1)

        RowLayout {
            Layout.fillWidth: true

            Label {
                text: attachmentManager.title
                font.bold: true
                Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            }

            Item {
                Layout.fillWidth: true
            } // spacer

            Button {
                id: uploadBtn
                text: i18n.dtr("ubtms", "Upload")
                onClicked: openContentPicker()
            }
        }

        // ----------- List of attachments -----------
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"
            border.color: "#00000022"
            border.width: 1
            radius: units.gu(0.5)

            ListView {
                id: listView
                anchors.fill: parent
                anchors.margins: units.gu(1)
                clip: true
                spacing: units.gu(0.5)

                // Roles expected: name, url, mimetype, size, created, account_id, odoo_record_id, _raw
                delegate: Rectangle {
                    width: listView.width
                    height: Math.max(units.gu(5), nameLabel.implicitHeight + units.gu(2))
                    radius: units.gu(0.5)
                    color: "transparent"
                    border.color: "#00000022"

                    // Guarded convenience values
                    property string _name: (typeof name !== "undefined" && name) ? name : ((typeof url !== "undefined" && url) ? url : "Unnamed")
                    property string _url: (typeof url !== "undefined" && url) ? url : ""
                    property string _mimetype: (typeof mimetype !== "undefined" && mimetype) ? mimetype : ""
                    property var _size: (typeof size !== "undefined") ? size : 0
                    property string _created: (typeof created !== "undefined" && created) ? created : ""
                    property int _accId: (typeof account_id !== "undefined") ? account_id : attachmentManager.account_id
                    property int _odooId: (typeof odoo_record_id !== "undefined") ? odoo_record_id : 0
                    property var rawData: (typeof _raw !== "undefined") ? _raw : null

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            var rec = {
                                name: _name,
                                url: _url,
                                mimetype: _mimetype,
                                size: _size,
                                created: _created,
                                account_id: _accId,
                                odoo_record_id: _odooId,
                                _raw: rawData
                            };
                            // emit for custom handlers
                            attachmentManager.itemClicked(rec);
                            // default behavior: download and open
                            attachmentManager._downloadAndOpen(rec);
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: units.gu(1)
                        spacing: units.gu(1)

                        Rectangle {
                            width: units.gu(3)
                            height: units.gu(3)
                            radius: units.gu(0.5)
                            color: _chipColor(_mimetype)
                            Layout.alignment: Qt.AlignVCenter
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: units.gu(0.3)

                            Label {
                                id: nameLabel
                                text: _name
                                elide: Label.ElideRight
                                maximumLineCount: 1
                                Layout.fillWidth: true
                            }

                            Label {
                                text: _metaLine(_mimetype, _size, _created)
                                color: "#808080"
                                font.pixelSize: units.gu(1.5)
                                elide: Label.ElideRight
                                maximumLineCount: 1
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }

            // Busy overlay (optional)
            Rectangle {
                anchors.fill: parent
                color: "#00000022"
                visible: attachmentManager._busy
                BusyIndicator {
                    anchors.centerIn: parent
                    running: parent.visible
                    visible: running
                }
            }
        }

        // ----------- ContentHub transfer hint -----------
        ContentTransferHint {
            id: transferHint
            Layout.fillWidth: true
            height: visible ? units.gu(4) : 0
            activeTransfer: attachmentManager.activeTransfer
            visible: attachmentManager.activeTransfer !== null
        }
    }

    // ----------- Python backend -----------
    Python {
        id: python
        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl("../src/"));
            importModule("backend", function () {
                console.log("backend imported");
            });
        }
        onError: console.log("python error: " + traceback)
    }

    // ----------- IMPORT dialog (ContentPickerDialog) -----------
    Component {
        id: contentPickerComponent

        ContentPickerDialog {
            id: dlg
            isExport: false   // importing from device/apps

            onFilesImported: function (files) {
                if (!files || !files.length)
                    return;

                attachmentManager.activeTransfer = dlg.activeTransfer;
                attachmentManager.uploadStarted();

                for (var i = 0; i < files.length; i++) {
                    var filePath = (files[i].url || "").toString().replace(/^file:\/\//, "");

                    python.call("backend.resolve_qml_db_path", ["ubtms"], function (path) {
                        if (!path) {
                            _notify("Failed to upload", 2000);
                            attachmentManager.uploadFailed();
                            return;
                        }
                        python.call("backend.attachment_upload", [path, attachmentManager.account_id, filePath, attachmentManager.resource_type, attachmentManager.resource_id], function (res) {
                            if (!res) {
                                console.warn("No response from attachment_upload");
                                _notify("Failed to upload", 2000);
                                attachmentManager.uploadFailed();
                                return;
                            }
                        // Success via backend_bridge
                        });
                    });
                }
            }

            onComplete: /* dialog auto-closes itself */ {}
        }
    }

    // ----------- EXPORT dialog (Open with…) -----------
    Component {
        id: contentExporterComponent

        ContentPickerDialog {
            id: exportDlg
            isExport: true    // exporting a local file to another app
            // fileUrl will be assigned when we open this dialog
        }
    }

    function openContentPicker() {
        try {
            PopupUtils.open(contentPickerComponent);
            console.log("[AttachmentManager] ContentPickerDialog (import) opened");
        } catch (e) {
            console.error("[AttachmentManager] Failed to open import dialog:", e);
        }
    }

    // Helper to open a local file via the export dialog
    function openFileWithDialog(fileUrl) {
        try {
            var url = (fileUrl && fileUrl.indexOf("file://") === 0) ? fileUrl : "file://" + fileUrl;
            var inst = PopupUtils.open(contentExporterComponent);
            if (inst) {
                inst.fileUrl = url; // pass file to dialog
                console.log("[AttachmentManager] ContentPickerDialog (export) opened for", url);
            } else {
                console.warn("[AttachmentManager] Export dialog instance missing; falling back to Qt.openUrlExternally");
                Qt.openUrlExternally(url);
            }
        } catch (e) {
            console.error("[AttachmentManager] openFileWithDialog error:", e);
            Qt.openUrlExternally(fileUrl);
        }
    }

    // ----------- Wiring: listen to activeTransfer (optional) -----------
    Connections {
        target: attachmentManager.activeTransfer
        onStateChanged: {
            if (!attachmentManager.activeTransfer)
                return;
            if (attachmentManager.activeTransfer.state === ContentTransfer.Charged) {
                _importItems = attachmentManager.activeTransfer.items || [];
                console.log("ImportItems count:", _importItems.length);
                // Uploads already handled in onFilesImported()
            }
        }
    }

    // ----------- Handle backend_bridge events -----------
    function _handleSyncEvent(data) {
        if (!data || !data.event)
            return;

        switch (data.event) {
        case "ondemand_upload_message":
            _notify(data.payload, 2000);
            break;
        case "ondemand_upload_completed":
            if (data.payload === true) {
                _notify("Attachment has been processed", 2000);
                attachmentManager.uploadCompleted();
            } else {
                _notify("Failed to upload", 2000);
                attachmentManager.uploadFailed();
            }
            break;
        }
    }

    // ----------- Public list API (internal model only) -----------
    function setAttachments(items) {
        if (!_usingInternalModel) {
            console.warn("[AttachmentManager] setAttachments ignored: external model is bound.");
            return;
        }
        internalModel.clear();
        if (!items || !items.length)
            return;
        for (var i = 0; i < items.length; i++) {
            internalModel.append(_normalizeItem(items[i]));
        }
    }

    function clearAttachments() {
        if (!_usingInternalModel) {
            console.warn("[AttachmentManager] clearAttachments ignored: external model is bound.");
            return;
        }
        internalModel.clear();
    }

    function appendAttachment(item) {
        if (!_usingInternalModel) {
            console.warn("[AttachmentManager] appendAttachment ignored: external model is bound.");
            return;
        }
        internalModel.append(_normalizeItem(item));
    }

    // ----------- Helpers -----------
    function _notify(msg, ms) {
        if (notifier && notifier.open) {
            notifier.open(msg, ms || 2000);
        } else {
            console.log("[AttachmentManager]", msg);
        }
    }

    function _normalizeItem(obj) {
        if (!obj)
            obj = {};
        return {
            id: obj.id !== undefined ? obj.id : obj.attachment_id,
            name: obj.name !== undefined ? obj.name : (obj.filename || obj.title || ""),
            url: obj.url !== undefined ? obj.url : (obj.fileUrl || ""),
            mimetype: obj.mimetype !== undefined ? obj.mimetype : (obj.mime || "application/octet-stream"),
            size: obj.size !== undefined ? obj.size : (obj.bytes || 0),
            created: obj.created !== undefined ? obj.created : (obj.created_at || obj.date || ""),
            account_id: obj.account_id !== undefined ? obj.account_id : attachmentManager.account_id,
            odoo_record_id: obj.odoo_record_id !== undefined ? obj.odoo_record_id : 0,
            _raw: obj
        };
    }

    function _metaLine(mime, sz, createdStr) {
        var parts = [];
        if (mime)
            parts.push(mime);
        if (createdStr)
            parts.push(createdStr);
        return parts.join(" • ");
    }

    function _fmtSize(bytes) {
        if (typeof bytes !== "number")
            return bytes;
        var thresh = 1024.0;
        if (bytes < thresh)
            return bytes + " B";
        var units = ["KB", "MB", "GB", "TB"];
        var u = -1;
        do {
            bytes /= thresh;
            ++u;
        } while (bytes >= thresh && u < units.length - 1)
        return bytes.toFixed(1) + " " + units[u];
    }

    function _chipColor(mime) {
        if (!mime)
            return "#607D8B";
        if (mime.indexOf("image/") === 0)
            return "#4CAF50";
        if (mime.indexOf("video/") === 0)
            return "#9C27B0";
        if (mime.indexOf("audio/") === 0)
            return "#03A9F4";
        if (mime.indexOf("text/") === 0)
            return "#FFC107";
        if (mime.indexOf("application/pdf") === 0)
            return "#F44336";
        return "#607D8B";
    }

    //  FileSmart(fileUrl, mime) – avoids Gallery duplicates for images
    function openFileSmart(fileUrl, mime) {
        var url = (fileUrl && fileUrl.indexOf("file://") === 0) ? fileUrl : "file://" + fileUrl;
        var m = mime || "";

        // For images, open directly (no ContentHub export → no copies in Pictures)
        if (m.indexOf("image/") === 0) {
            console.log("Showing in builtin image viewer");
            _showImageInApp(url);
            return;
        }

        // For everything else, keep your existing "Open with…" flow
        try {
            var inst = PopupUtils.open(contentExporterComponent);
            if (inst) {
                inst.fileUrl = url;
                console.log("[AttachmentManager] Export dialog opened for", url);
            } else {
                console.warn("[AttachmentManager] Export dialog missing; fallback to external open");
                Qt.openUrlExternally(url);
            }
        } catch (e) {
            console.error("[AttachmentManager] openFileSmart/export error:", e);
            Qt.openUrlExternally(url);
        }
    }

    function _showImageInApp(fileUrl) {
        try {
            var url = (fileUrl && fileUrl.indexOf("file://") === 0) ? fileUrl : "file://" + fileUrl;

            imagePreviewer.imageSource = url;
            imagePreviewer.visible = true;
        } catch (e) {
            console.error("[AttachmentManager] _showImageInApp error:", e);
        }
    }

    function _downloadAndOpen(rec) {
        if (!rec)
            return;

        // If there's no Odoo id but we already have a file/url, open it
        if (rec.odoo_record_id <= 0) {
            if (rec.url && rec.url.toString().length) {
                var u = rec.url.toString();
                if (u.indexOf("http://") === 0 || u.indexOf("https://") === 0) {
                    Qt.openUrlExternally(u);
                } else {
                    if (u.indexOf("file://") !== 0)
                        u = "file://" + u;
                    // PASS MIME so images bypass ContentHub
                    openFileSmart(u, rec.mimetype || "application/octet-stream");
                }
                return;
            }
            _notify("Attachment missing identifiers", 2500);
            return;
        }

        var fname = (rec.name && rec.name.length) ? rec.name : "attachment";
        var mime = rec.mimetype || "application/octet-stream";

        python.call("backend.get_existing_attachment_path", [fname, mime], function (existingPath) {
            if (existingPath && existingPath.length) {
                // Open the existing file right away
                console.log("We already have the local copy of this file, Lets open!!!!");
                var fileUrl = existingPath.indexOf("file://") === 0 ? existingPath : "file://" + existingPath;
                openFileSmart(fileUrl, mime);   // <<< use smart opener here
                return;
            }
            console.log("Unable to find locally !!!");

            // ---- Not present locally: proceed with on-demand download as before ----
            _busy = true;

            python.call("backend.resolve_qml_db_path", ["ubtms"], function (path) {
                if (!path) {
                    _busy = false;
                    _notify("DB not found.", 2500);
                    return;
                }

                python.call("backend.attachment_ondemand_download", [path, rec.account_id || attachmentManager.account_id, rec.odoo_record_id], function (res) {
                    _busy = false;

                    if (!res) {
                        _notify("No response from ondemand_download", 2500);
                        return;
                    }

                    if (res.type === "binary" && res.data) {
                        var dlName = (res.name && res.name.length) ? res.name : fname;
                        var dlMime = res.mimetype || mime;

                        python.call("backend.ensure_export_file_from_base64", [dlName, res.data, dlMime], function (resultPath) {
                            if (!resultPath || !resultPath.length) {
                                _notify("Failed to prepare file", 2500);
                                return;
                            }
                            var fileUrl = resultPath.indexOf("file://") === 0 ? resultPath : "file://" + resultPath;
                            openFileSmart(fileUrl, dlMime);  // <<< smart open
                        });
                    } else if (res.type === "url" && res.url) {
                        Qt.openUrlExternally(res.url);
                    } else {
                        _notify("Attachment has no usable data", 2500);
                    }
                });
            });
        });
    }
}
