import QtQuick 2.7
import Lomiri.Components 1.3
import "js/html-sanitizer.js" as HtmlSanitizer
import "../../../models/global.js" as Global

Rectangle {
    id: root
    property alias text: previewText.text
    property string title: i18n.dtr("ubtms", "Description")
    property bool is_read_only: true
    property bool useRichText: true

    // Store the original HTML content to preserve formatting
    property string originalHtmlContent: ""

    /**
     * Enable bidirectional live sync with Global.description_temporary_holder.
     * When true, a polling timer keeps this preview in sync with the
     * RichTextEditor on ReadMorePage — changes flow both ways automatically
     * without manual save.
     */
    property bool liveSyncActive: false
    property bool listening: false
    property bool processing: false
    property string textBeforeRecording: ""
    property int _liveStartPos: 0
    property int _liveLength: 0

    Connections {
        target: mainView.backend_bridge
        onMessageReceived: {
            // Only handle voice events if this instance is the one listening
            if (!root.listening && !root.processing) return;

            // data is the object sent from Python via bus.send()
            if (data.event === "voice_recognition_partial") {
                var partialText = data.payload
                if (partialText) {
                    var str = " " + partialText + " (Listening...)";
                    previewText.remove(root._liveStartPos, root._liveStartPos + root._liveLength);
                    previewText.insert(root._liveStartPos, str);
                    root._liveLength = str.length;
                    
                    cursorTimer.start();
                }
            } else if (data.event === "voice_recognition_result") {
                root.listening = false
                root.processing = false
                var recognizedText = data.payload
                console.log("[RichTextPreview] Received recognition result: " + recognizedText)
                
                if (recognizedText) {
                    var finalStr = " " + recognizedText;
                    previewText.remove(root._liveStartPos, root._liveStartPos + root._liveLength);
                    previewText.insert(root._liveStartPos, finalStr);
                    root._liveLength = 0;
                    
                    root.contentChanged(previewText.text);
                    cursorTimer.start();
                } else {
                    // Restore if no text
                    previewText.remove(root._liveStartPos, root._liveStartPos + root._liveLength);
                    root._liveLength = 0;
                    cursorTimer.start();
                }
            } else if (data.event === "voice_recognition_error") {
                root.listening = false
                root.processing = false
                root.text = root.textBeforeRecording
                console.log("[RichTextPreview] Voice recognition error: " + data.payload)
                cursorTimer.start()
            }
        }
    }

    // Internal: tracks last synced content to detect external changes
    property string _lastSyncedContent: ""

    width: parent.width
    height: parent.height//column.implicitHeight
    color: "transparent"

    signal clicked
    signal contentChanged(string content)

    // Function to get the raw text content with formatting preserved
    function getFormattedText() {
        // Return the stored original HTML content, not the Qt-converted text
        // Qt's TextArea converts HTML when using Text.RichText format,
        // which adds DOCTYPE and <html> tags - we want to preserve the original
      //  console.log("[RichTextPreview] getFormattedText returning, full content:");
       // console.log(originalHtmlContent);
        return originalHtmlContent || "";
    }

    /**
     * Get text content asynchronously (API compatible with RichTextEditor)
     * @param callback - Function to call with the HTML content
     */
    function getText(callback) {
        var content = getFormattedText();
        if (callback) {
            callback(content);
        }
    }

    /**
     * Check if content is valid HTML content (not corrupted editor internals)
     * Uses the centralized HtmlSanitizer validation.
     * @param content - HTML string to validate
     * @return true if content is valid, false if it contains editor internals
     */
    function isValidContent(content) {
        if (!content) return true; // Empty is valid
        var validation = HtmlSanitizer.validate(content);
        if (!validation.isValid) {
          //  console.log("[RichTextPreview] Invalid content:", validation.issues.join(", "));
        }
        return validation.isValid;
    }

    /**
     * Sanitize HTML content using the centralized HtmlSanitizer.
     * Handles Qt wrappers, Odoo HTML, and Squire output.
     * @param content - HTML string that may need sanitization
     * @return Clean HTML content
     */
    function sanitizeHtml(content) {
        if (!content) return "";
        
        // Check if sanitization is needed
        if (HtmlSanitizer.needsSanitization(content)) {
           // console.log("[RichTextPreview] Sanitizing HTML content");
            var result = HtmlSanitizer.sanitize(content);
           // console.log("[RichTextPreview] Sanitized result:", result ? result.substring(0, 100) : "(empty)");
            return result;
        }
        
        return content;
    }

    // Function to set content with HTML preservation
    function setContent(htmlContent) {
      //  console.log("[RichTextPreview] setContent called with length:", htmlContent ? htmlContent.length : 0);
        
        // Validate content - reject if it contains editor internals
        if (!isValidContent(htmlContent)) {
          //  console.warn("[RichTextPreview] Ignoring corrupted content (contains editor internals)");
            return;
        }
        
        // Sanitize the HTML to remove Qt wrapper if present
        var cleanContent = sanitizeHtml(htmlContent || "");
        
        // Store the clean HTML
        originalHtmlContent = cleanContent;
        
        // Prevent onTextChanged from overwriting originalHtmlContent
        _settingContent = true;
        previewText.text = cleanContent;
        _settingContent = false;
    }

    /**
     * Set HTML document content (API compatible with RichTextEditor)
     * @param doc - HTML string to set
     */
    function setDocument(doc) {
        setContent(doc);
    }

    /**
     * Set text content (API compatible with RichTextEditor)
     * @param htmlText - HTML string to set
     */
    function setText(htmlText) {
        setContent(htmlText);
    }

    /**
     * Sync content (API compatible with RichTextEditor)
     * Returns the current content for immediate sync needs
     */
    function syncContent() {
        // RichTextPreview is synchronous - return the stored original HTML
        // Do NOT use previewText.text as Qt adds DOCTYPE and <html> tags
        return originalHtmlContent || "";
    }

    /**
     * Extract body content from Qt's TextArea HTML wrapper.
     * In RichText mode, Qt wraps content with <!DOCTYPE><html><body>...</body></html>.
     * This extracts just the inner body content.
     */
    function extractBodyContent(html) {
        if (!html) return "";
        var bodyStart = html.indexOf("<body");
        if (bodyStart === -1) return html;
        var bodyTagEnd = html.indexOf(">", bodyStart);
        if (bodyTagEnd === -1) return html;
        var bodyEnd = html.indexOf("</body>", bodyTagEnd);
        if (bodyEnd === -1) return html;
        return html.substring(bodyTagEnd + 1, bodyEnd).trim();
    }

    // Property to track if content was set programmatically
    property bool _settingContent: false

    // Reset sync state when liveSyncActive changes
    onLiveSyncActiveChanged: {
        if (liveSyncActive) {
            _lastSyncedContent = originalHtmlContent || "";
          //  console.log("[RichTextPreview] Live sync STARTED, initial content length:", _lastSyncedContent.length);
        } else {
            _lastSyncedContent = "";
          //  console.log("[RichTextPreview] Live sync STOPPED");
        }
    }

    /**
     * Live sync timer — polls Global.description_temporary_holder every 300ms.
     * When active, any content change from the RichTextEditor (via ReadMorePage)
     * is automatically picked up and displayed in the preview.
     */
    Timer {
        id: liveSyncTimer
        interval: 300
        repeat: true
        running: root.liveSyncActive
        onTriggered: {
            var holderContent = Global.description_temporary_holder;
            if (holderContent !== "" && holderContent !== root._lastSyncedContent) {
               // console.log("[RichTextPreview] External change detected - PULLING from Global, length:", holderContent.length);
                root._lastSyncedContent = holderContent;
                root.setContent(holderContent);
                // Emit contentChanged so parent page's draft handler gets notified.
                // setContent() suppresses the TextArea.onTextChanged signal to avoid
                // feedback loops, but the parent page needs to know content changed
                // in order to track it in the draft system.
                root.contentChanged(root.originalHtmlContent);
            }
        }
    }

    Timer {
        id: cursorTimer
        interval: 100
        repeat: false
        onTriggered: {
            if (previewText) {
                // Ensure the TextArea is focused so it respects scroll-to-cursor
                // and use .length (visible characters) instead of .text.length (HTML source length)
                previewText.cursorPosition = previewText.length;
                
                // Force scroll to bottom if internal flickable exists
                if (previewText.flickableItem) {
                    previewText.flickableItem.contentY = Math.max(0, previewText.flickableItem.contentHeight - previewText.flickableItem.height);
                } else if (previewText.flickable) {
                    previewText.flickable.contentY = Math.max(0, previewText.flickable.contentHeight - previewText.flickable.height);
                }
            }
        }
    }

    Column {
        id: column
        width: parent.width
        height: parent.height
        spacing: units.gu(1)
        Label {
            text: title
            anchors.left: parent.left
            anchors.leftMargin: units.gu(2)
        }

        Item {
            id: textContainer
            width: parent.width
            height: maxHeight
            clip: true

            anchors.margins: units.gu(2)

            property int maxHeight: units.gu(16)

            TextArea {
                id: previewText
                textFormat: useRichText ? Text.RichText : Text.PlainText

                readOnly: is_read_only
                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                wrapMode: Text.WordWrap
                font.pixelSize: units.gu(2)

                width: parent.width - units.gu(2)
                anchors.horizontalCenter: parent.horizontalCenter
                height: parent.height

                // Update originalHtmlContent when user types
                onTextChanged: {
                    // Only update if user is typing (not read-only) and we're not setting content programmatically
                    if (!is_read_only && !_settingContent) {
                        var currentContent;
                        if (useRichText && (text.indexOf("<!DOCTYPE") !== -1 || text.indexOf("<html") !== -1)) {
                            // Rich text mode: Qt wraps content in DOCTYPE/html — extract body content
                            currentContent = root.extractBodyContent(text);
                        } else {
                            currentContent = text;
                        }

                        if (currentContent && currentContent !== originalHtmlContent) {
                          //  console.log("[RichTextPreview] User typing detected, content length:", currentContent.length);
                            originalHtmlContent = currentContent;
                            root.contentChanged(currentContent);
                            // Live sync: push user's typing to Global so RichTextEditor picks it up
                            if (root.liveSyncActive) {
                           //     console.log("[RichTextPreview] PUSHING to Global, length:", currentContent.length);
                                Global.description_temporary_holder = currentContent;
                                root._lastSyncedContent = currentContent;
                            }
                        }
                    }
                }

                Rectangle {
                    // visible: !isReadOnly
                    anchors.fill: parent
                    color: "transparent"
                    radius: units.gu(0.5)
                    border.width: parent.activeFocus ? units.gu(0.2) : units.gu(0.1)
                    border.color: parent.activeFocus ? LomiriColors.orange : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#d3d1d1" : "#999")
                    // z: -1
                }

                Row {
                    id: floatingActionButton
                    // width: units.gu(3)
                    // height: units.gu(3)
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: units.gu(1)
                    anchors.bottomMargin: units.gu(1)
                    spacing: units.gu(1)
                    z: 10
                    visible: true

                    Rectangle {
                        id: voiceButton
                        width: units.gu(3)
                        height: units.gu(3)
                        radius: units.gu(.5)
                        color: root.listening ? LomiriColors.red : LomiriColors.orange
                        
                        Image {
                            id: voiceIcon
                            source: "../../images/mic.svg"
                            width: units.gu(2)
                            height: units.gu(2)
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            opacity: (root.listening || root.processing) ? 0.5 : 1.0
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.listening) {
                                    console.log("[RichTextPreview] Stopping voice recognition...")
                                    root.listening = false
                                    root.processing = true
                                    
                                    // Replace the Listening indicator with Processing via direct node manipulation
                                    previewText.remove(root._liveStartPos, root._liveStartPos + root._liveLength);
                                    previewText.insert(root._liveStartPos, " (Processing...)");
                                    root._liveLength = " (Processing...)".length;
                                    
                                    backend_bridge.call("backend.stop_voice_recognition", [])
                                    return;
                                }
                                if (root.processing) return; // Prevent double trigger
                                
                                console.log("[RichTextPreview] Voice recognition started")
                                root.textBeforeRecording = root.text
                                
                                // Initialize the live insertion point at the very end
                                root._liveStartPos = previewText.length;
                                root._liveLength = " (Listening...)".length;
                                previewText.insert(root._liveStartPos, " (Listening...)");
                                
                                cursorTimer.start()
                                root.listening = true
                                root.processing = false
                                backend_bridge.call("backend.run_voice_recognition", [])
                            }
                        }
                    }

                    Rectangle {
                        id: expansionButton
                        width: units.gu(3)
                        height: units.gu(3)
                        radius: units.gu(.5)
                        color: LomiriColors.orange
                        
                        Image {
                            id: expansionIcon
                            source: "../../images/expansion.png"
                            width: units.gu(1.5)
                            height: units.gu(1.5)
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        MouseArea {
                            anchors.fill: parent
                            // cursorShape: Qt.PointingHandCursor
                            onClicked: root.clicked()
                        }
                    }
                }
                //  padding: units.gu(2)
            }
        }
    }
}
