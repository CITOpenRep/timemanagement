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
    property string title: "Attachments"

    /** Read-only: live transfer (for hint) */
    property var activeTransfer: null

    /** Signals */
    signal uploadStarted()
    signal uploadCompleted()
    signal uploadFailed()
    signal itemClicked(var item)

    // ----------- Internal state -----------
    property list<ContentItem> _importItems
    property bool _busy: false

    // Fallback ListModel
    ListModel { id: internalModel }

    readonly property bool _usingInternalModel: listView.model === internalModel

    Component.onCompleted: {
        if (!listView.model) listView.model = internalModel;
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

            Item { Layout.fillWidth: true } // spacer

            Button {
                id: uploadBtn
                text: "Upload"
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
                    property string _name:     (typeof name     !== "undefined" && name)     ? name     : ((typeof url !== "undefined" && url) ? url : "Unnamed")
                    property string _url:      (typeof url      !== "undefined" && url)      ? url      : ""
                    property string _mimetype: (typeof mimetype !== "undefined" && mimetype) ? mimetype : ""
                    property var    _size:     (typeof size     !== "undefined")             ? size     : 0
                    property string _created:  (typeof created  !== "undefined" && created)  ? created  : ""
                    property int    _accId:    (typeof account_id      !== "undefined") ? account_id      : attachmentManager.account_id
                    property int    _odooId:   (typeof odoo_record_id  !== "undefined") ? odoo_record_id  : 0
                    property var    rawData:   (typeof _raw            !== "undefined") ? _raw            : null

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
                            width: units.gu(3); height: units.gu(3); radius: units.gu(0.5)
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
            importModule("backend", function () { console.log("backend imported"); });
        }
        onError: console.log("python error: " + traceback);
    }

    // ----------- Use Dekko-style ContentPickerDialog (import) -----------
    // NOTE: Ensure ContentPickerDialog.qml is in the same directory or importable path.
    Component {
        id: contentPickerComponent

        ContentPickerDialog {
            id: dlg
            isExport: false   // we are IMPORTING from device/apps

            onFilesImported: function(files) {
                if (!files || !files.length) return;

                // Make the TransferHint show progress/state, if useful
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
                        python.call("backend.attachment_upload",
                                    [path, attachmentManager.account_id, filePath,
                                     attachmentManager.resource_type, attachmentManager.resource_id],
                                    function (res) {
                                        if (!res) {
                                            console.warn("No response from attachment_upload");
                                            _notify("Failed to upload", 2000);
                                            attachmentManager.uploadFailed();
                                            return;
                                        }
                                        // Success path signaled via backend_bridge events
                                    });
                    });
                }
            }

            // Optional: hook when dialog fully completes/auto-closes
            onComplete: {
                // no-op; picker closes itself inside ContentPickerDialog
            }
        }
    }

    function openContentPicker() {
        try {
            PopupUtils.open(contentPickerComponent);  // instantiate dialog lazily
            console.log("[AttachmentManager] ContentPickerDialog opened");
        } catch (e) {
            console.error("[AttachmentManager] Failed to open ContentPickerDialog:", e);
        }
    }

    // ----------- Wiring: (kept) listen to activeTransfer for CHARGED -----------
    Connections {
        target: attachmentManager.activeTransfer

        onStateChanged: {
            if (!attachmentManager.activeTransfer) return;

            if (attachmentManager.activeTransfer.state === ContentTransfer.Charged) {
                _importItems = attachmentManager.activeTransfer.items || [];
                console.log("ImportItems count:", _importItems.length);

                // NOTE: We already upload in onFilesImported().
                // Keeping this block is harmless if you later move uploads here.
            }
        }
    }

    // ----------- Handle backend_bridge events -----------
    function _handleSyncEvent(data) {
        if (!data || !data.event) return;

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
        if (!items || !items.length) return;
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
        if (!obj) obj = {};
        return {
            id:              obj.id              !== undefined ? obj.id              : obj.attachment_id,
            name:            obj.name            !== undefined ? obj.name            : (obj.filename || obj.title || ""),
            url:             obj.url             !== undefined ? obj.url             : (obj.fileUrl || ""),
            mimetype:        obj.mimetype        !== undefined ? obj.mimetype        : (obj.mime || "application/octet-stream"),
            size:            obj.size            !== undefined ? obj.size            : (obj.bytes || 0),
            created:         obj.created         !== undefined ? obj.created         : (obj.created_at || obj.date || ""),
            account_id:      obj.account_id      !== undefined ? obj.account_id      : attachmentManager.account_id,
            odoo_record_id:  obj.odoo_record_id  !== undefined ? obj.odoo_record_id  : 0,
            _raw: obj
        };
    }

    function _metaLine(mime, sz, createdStr) {
        var parts = [];
        if (mime) parts.push(mime);
        if (typeof sz === "number") parts.push(_fmtSize(sz));
        if (createdStr) parts.push(createdStr);
        return parts.join(" • ");
    }

    function _fmtSize(bytes) {
        if (typeof bytes !== "number") return bytes;
        var thresh = 1024.0;
        if (bytes < thresh) return bytes + " B";
        var units = ["KB","MB","GB","TB"];
        var u = -1;
        do { bytes /= thresh; ++u; } while (bytes >= thresh && u < units.length-1);
        return bytes.toFixed(1) + " " + units[u];
    }

    function _chipColor(mime) {
        if (!mime) return "#607D8B";
        if (mime.indexOf("image/") === 0) return "#4CAF50";
        if (mime.indexOf("video/") === 0) return "#9C27B0";
        if (mime.indexOf("audio/") === 0) return "#03A9F4";
        if (mime.indexOf("text/")  === 0) return "#FFC107";
        if (mime.indexOf("application/pdf") === 0) return "#F44336";
        return "#607D8B";
    }

    // ---- on-click download + open using your Python APIs ----
    function _downloadAndOpen(rec) {
        if (!rec) return;

        if (rec.odoo_record_id <= 0) {
            if (rec.url && rec.url.toString().length) {
                var maybeUrl = rec.url.toString();
                if (maybeUrl.indexOf("file://") !== 0 && maybeUrl.indexOf("http") !== 0)
                    maybeUrl = "file://" + maybeUrl;
                Qt.openUrlExternally(maybeUrl);
                return;
            }
            _notify("Attachment missing identifiers", 2500);
            return;
        }

        _busy = true;
        python.call("backend.resolve_qml_db_path", ["ubtms"], function (path) {
            if (!path) {
                _busy = false;
                _notify("DB not found.", 2500);
                return;
            }

            python.call("backend.attachment_ondemand_download",
                        [path, rec.account_id || attachmentManager.account_id, rec.odoo_record_id],
                        function (res) {
                            _busy = false;

                            if (!res) {
                                _notify("No response from ondemand_download", 2500);
                                return;
                            }

                            if (res.type === "binary" && res.data) {
                                var fname = (res.name && res.name.length) ? res.name :
                                            (rec.name && rec.name.length ? rec.name : "attachment");
                                var mime = res.mimetype || rec.mimetype || "application/octet-stream";

                                python.call("backend.ensure_export_file_from_base64",
                                            [fname, res.data, mime],
                                            function (resultPath) {
                                                if (!resultPath || !resultPath.length) {
                                                    _notify("Failed to prepare file", 2500);
                                                    return;
                                                }
                                                var fileUrl = resultPath.indexOf("file://") === 0 ? resultPath : "file://" + resultPath;
                                                Qt.openUrlExternally(fileUrl);
                                            });

                            } else if (res.type === "url" && res.url) {
                                Qt.openUrlExternally(res.url);
                            } else {
                                _notify("Attachment has no usable data", 2500);
                            }
                        });
        });
    }
}
