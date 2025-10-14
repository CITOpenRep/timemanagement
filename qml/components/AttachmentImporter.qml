/*
 * MIT License
 * (c) 2025 CIT-Services
 */

import QtQuick 2.7
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.Content 1.3

Item {
    id: root
    width: 0
    height: 0

    // ---- Public API ----
    property string headerText: "Upload from Device"
    property int contentType: ContentType.All
    property int selectionType: ContentTransfer.Single     // or ContentTransfer.Multiple
    property int preferredPosition: PopupUtils.Bottom      // Top/Left/Right/Bottom
    property bool closeOnSelect: true                      // auto-close after user picks peer
    signal canceled()
    signal error(string reason)
    signal received(var items) // emits array of ContentItem(s) when transfer finishes

    // expose activeTransfer (read-only-ish for consumers who want to observe)
    property var activeTransfer: null

    // ---- Private ----
    Component {
        id: popoverComponent

        Popover {
            id: popover
            contentWidth: units.gu(35)
            contentHeight: contentColumn.implicitHeight + units.gu(2)

            Column {
                id: contentColumn
                anchors.fill: parent
                anchors.margins: units.gu(1)
                spacing: units.gu(1)

                Label {
                    text: root.headerText
                    font.bold: true
                    wrapMode: Text.WordWrap
                }

                // The system peer picker embedded INSIDE the popover
                ContentPeerPicker {
                    id: attachmentSource
                    headerText: root.headerText
                    contentType: root.contentType
                    handler: ContentHandler.Source

                    onPeerSelected: {
                        try {
                            peer.selectionType = root.selectionType;
                            root.activeTransfer = peer.request();
                            if (root.closeOnSelect) {
                                PopupUtils.close(popover);
                            }
                        } catch (e) {
                            root.error("Failed to start transfer: " + e);
                        }
                    }

                    onCancelPressed: {
                        PopupUtils.close(popover);
                        root.canceled();
                    }
                }
            }
        }
    }

    // Listen to the transfer lifecycle and emit a simple signal
    Connections {
        target: root.activeTransfer
        ignoreUnknownSignals: true

        function onErrorChanged() {
            if (!root.activeTransfer) return;
            if (root.activeTransfer.error && root.activeTransfer.error.length) {
                root.error(root.activeTransfer.error);
            }
        }

        function onStateChanged() {
            if (!root.activeTransfer) return;

            // ContentTransfer.State enum values:
            // Unknown = 0, Initialized, InProgress, Finished, Error, Canceled (values differ by platform version)
            var st = root.activeTransfer.state;

            // When finished, emit items and clear
            if (st === ContentTransfer.Finished && root.activeTransfer.items) {
                // items is an array of ContentItem: { url, text, contentType, ... }
                root.received(root.activeTransfer.items);
                root.activeTransfer = null;
            }
        }
    }

    // ---- Methods ----
    // Call this from any button: picker.open(button)
    function open(anchorItem) {
        if (anchorItem) {
            PopupUtils.open(popoverComponent, anchorItem, root.preferredPosition);
        } else {
            PopupUtils.open(popoverComponent);
        }
    }

    function close() {
        PopupUtils.close(popoverComponent);
    }
}
