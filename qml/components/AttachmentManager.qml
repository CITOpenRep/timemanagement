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
                onClicked: _openPicker(uploadBtn)
            }
        }

        // ----------- List of attachments -----------
        Rectangle {
            Layout.fillWidth: true
             Layout.fillHeight: true
            color: "transparent"
            // Safe fallback if theme is unavailable
            border.color: "#00000022"
            radius: units.gu(0.5)

            ListView {
                id: listView
                anchors.fill: parent
                anchors.margins: units.gu(1)
                clip: true
                spacing: units.gu(0.5)

                // For ListModel, delegate directly sees roles: name, url, mimetype, size, created, _raw
                delegate: Rectangle {
                    width: listView.width
                    height: Math.max(units.gu(5), nameLabel.implicitHeight + units.gu(2))
                    radius: units.gu(0.5)
                    color: "transparent"
                    border.color: "#00000022"

                    // Local convenience (guard against undefined)
                    property string _name:    typeof name     !== "undefined" && name     ? name     : (typeof url !== "undefined" && url ? url : "Unnamed")
                    property string _url:     typeof url      !== "undefined" && url      ? url      : ""
                    property string _mimetype:typeof mimetype !== "undefined" && mimetype ? mimetype : ""
                    property var    _size:    typeof size     !== "undefined"             ? size     : 0
                    property string _created: typeof created  !== "undefined" && created  ? created  : ""
                    property var    rawData:     typeof _raw     !== "undefined"             ? _raw     : null

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            attachmentManager.itemClicked({
                                name: _name,
                                url: _url,
                                mimetype: _mimetype,
                                size: _size,
                                created: _created,
                                _raw: rawData
                            })
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: units.gu(1)
                        spacing: units.gu(1)

                        // tiny icon via mime group
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
                                color: "#808080" // safe fallback instead of theme.palette.normal.backgroundTextDisabled
                                font.pixelSize: units.gu(1.5)
                                elide: Label.ElideRight
                                maximumLineCount: 1
                                Layout.fillWidth: true
                            }
                        }
                    }
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

    // ----------- Python backend (unchanged API) -----------
    Python {
        id: python
        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl("../src/"));
            importModule("backend", function () { console.log("backend imported"); });
        }
        onError: console.log("python error: " + traceback);
    }

    // ----------- Picker popover (embedded) -----------
    Component {
        id: pickerPopoverComponent

        Popover {
            id: pickerPopover
            contentWidth: units.gu(35)
            contentHeight: col.implicitHeight + units.gu(2)

            Column {
                id: col
                anchors.fill: parent
                anchors.margins: units.gu(1)
                spacing: units.gu(1)

                Label {
                    text: "Upload from Device"
                    font.bold: true
                    wrapMode: Text.WordWrap
                }

                ContentPeerPicker {
                    id: picker
                    headerText: "Upload from Device"
                    contentType: ContentType.All
                    handler: ContentHandler.Source

                    onPeerSelected: {
                        try {
                            peer.selectionType = ContentTransfer.Single;
                            attachmentManager.activeTransfer = peer.request();
                            attachmentManager.uploadStarted();
                            PopupUtils.close(pickerPopover);
                        } catch (e) {
                            _notify("Failed to start transfer: " + e, 3000);
                        }
                    }

                    onCancelPressed: {
                        PopupUtils.close(pickerPopover);
                    }
                }
            }
        }
    }

    // ----------- Wiring: handle transfer -> call Python APIs (unchanged) -----------
    Connections {
        target: attachmentManager.activeTransfer

        onStateChanged: {
            if (!attachmentManager.activeTransfer) return;

            // Keep your original gate (you used 'Charged')
            if (attachmentManager.activeTransfer.state === ContentTransfer.Charged) {
                _importItems = attachmentManager.activeTransfer.items || [];
                console.log("ImportItems count:", _importItems.length);

                for (var i = 0; i < _importItems.length; i++) {
                    var item = _importItems[i];
                    var filePath = (item.url || "").toString().replace(/^file:\/\//, "");

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
                            // Success path is signaled by backend_bridge events below
                        });
                    });
                }
            }
        }
    }

    // ----------- Handle backend_bridge events (unchanged semantics) -----------
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
                // Parent may refresh the 'model' now (list of attachments)
            } else {
                _notify("Failed to upload", 2000);
                attachmentManager.uploadFailed();
            }
            break;
        }
    }

    // ----------- Public list API (internal model only) -----------
    function setAttachments(items) {
        console.log("Setting attachments of " + items.length)
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
    function _openPicker(anchor) {
        PopupUtils.open(pickerPopoverComponent, anchor || uploadBtn, PopupUtils.Top);
    }

    function _notify(msg, ms) {
        if (notifier && notifier.open) {
            notifier.open(msg, ms || 2000);
        } else {
            console.log("[AttachmentManager]", msg);
        }
    }

    function _normalizeItem(obj) {
        if (!obj) obj = {};
        console.log(obj.name)
        return {
            id:        obj.id        !== undefined ? obj.id        : obj.attachment_id,
            name:      obj.name      !== undefined ? obj.name      : (obj.filename || obj.title || ""),
            url:       obj.url       !== undefined ? obj.url       : (obj.fileUrl || ""),
            mimetype:  obj.mimetype  !== undefined ? obj.mimetype  : (obj.mime || "application/octet-stream"),
            size:      obj.size      !== undefined ? obj.size      : (obj.bytes || 0),
            created:   obj.created   !== undefined ? obj.created   : (obj.created_at || obj.date || ""),
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
}
