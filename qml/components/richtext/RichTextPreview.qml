import QtQuick 2.7
import Lomiri.Components 1.3
import QtQuick.LocalStorage 2.7 as Sql
import "js/html-sanitizer.js" as HtmlSanitizer
import "../../../models/global.js" as Global
import "../system"

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
    property bool ignoreNextResult: false
    
    Component.onDestruction: {
        if (listening || processing) {
            console.log("[RichTextPreview] destruction: Stopping voice recognition...")
            ignoreNextResult = true;
            listening = false;
            processing = false;
            _currentVoiceStatus = "";
            textBeforeRecording = root.text;
            _syncVoiceResult();
            backend_bridge.call("backend.stop_voice_recognition", [])
        }
    }
    property string textBeforeRecording: ""
    property bool isVoiceInputEnabled: true

    // This is used to sync the voice input with the parent form's draft handler
    function _syncVoiceResult() {
        var currentContent = root.text;
        originalHtmlContent = currentContent;
        root.contentChanged(currentContent);
        if (root.liveSyncActive) {
            Global.description_temporary_holder = currentContent;
            root._lastSyncedContent = currentContent;
        }
    }

    function checkVoiceInputEnabled() {
        try {
            var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
            var result = true;
            db.transaction(function (tx) {
                tx.executeSql('CREATE TABLE IF NOT EXISTS app_settings (key TEXT PRIMARY KEY, value TEXT)');
                var rs = tx.executeSql('SELECT value FROM app_settings WHERE key = "voice_input_enabled"');
                if (rs.rows.length > 0) {
                    result = rs.rows.item(0).value === "true";
                }
            });
            isVoiceInputEnabled = result;
        } catch (e) {
            console.warn("Error reading voice_input_enabled:", e);
        }
    }

    Component.onCompleted: {
        checkVoiceInputEnabled()
    }
    property string _partialRecognizedText: ""
    property string _currentVoiceStatus: ""

    Connections {
        target: mainView.backend_bridge
        onMessageReceived: {
            // Only handle voice events if this instance is the one listening
            if (!root.listening && !root.processing) return;

            // data is the object sent from Python via bus.send()
            if (data.event === "voice_recognition_partial") {
                var partialText = data.payload
                if (partialText) {
                    root._currentVoiceStatus = i18n.dtr("ubtms", "Listening...");
                    
                    var prefix = "";
                    if (root.textBeforeRecording.length > 0) {
                        var lastChar = root.textBeforeRecording.charAt(root.textBeforeRecording.length - 1);
                        if (lastChar !== '\n' && lastChar !== '\r') {
                            prefix = "\n";
                        }
                    }
                    root._settingContent = true;
                    root.text = root.textBeforeRecording + prefix + partialText;
                    // Force update originalHtmlContent so draft listeners get the live text
                    // without waiting for the mic to stop.
                    root.originalHtmlContent = root.text;
                    root._settingContent = false;
                    
                    // Keep cursor at end and scroll to bottom immediately
                    previewText.cursorPosition = previewText.length;
                    if (previewText.flickableItem) {
                        previewText.flickableItem.contentY = Math.max(0, previewText.flickableItem.contentHeight - previewText.flickableItem.height);
                    } else if (previewText.flickable) {
                        previewText.flickable.contentY = Math.max(0, previewText.flickable.contentHeight - previewText.flickable.height);
                    }
                }
            } else if (data.event === "voice_recognition_status") {
                var statusText = data.payload;
                if (statusText) {
                    root._currentVoiceStatus = statusText;
                }
            } else if (data.event === "voice_recognition_result") {
                if (root.ignoreNextResult) {
                    root.ignoreNextResult = false;
                    root.listening = false;
                    root.processing = false;
                    root._currentVoiceStatus = "";
                    root.textBeforeRecording = root.text;
                    root._syncVoiceResult();
                    cursorTimer.start();
                    return;
                }
                
                root.listening = false
                root.processing = false
                var recognizedText = data.payload
                console.log("[RichTextPreview] Received recognition result: " + recognizedText)
                
                root._currentVoiceStatus = "";
                
                if (recognizedText) {
                    var prefix = "";
                    if (root.textBeforeRecording.length > 0) {
                        var lastChar = root.textBeforeRecording.charAt(root.textBeforeRecording.length - 1);
                        if (lastChar !== '\n' && lastChar !== '\r') {
                            prefix = "\n";
                        }
                    }
                    root._settingContent = true;
                    root.text = root.textBeforeRecording + prefix + recognizedText;
                    root._settingContent = false;
                    root.textBeforeRecording = root.text;
                    root._syncVoiceResult();
                    cursorTimer.start();
                } else {
                    root.textBeforeRecording = root.text;
                    root._syncVoiceResult();
                    cursorTimer.start();
                }
            } else if (data.event === "voice_recognition_error") {
                root.listening = false
                root.processing = false
                root._currentVoiceStatus = "";
                root.textBeforeRecording = root.text;
                root._syncVoiceResult();
                console.log("[RichTextPreview] Voice recognition error: " + data.payload)
                if (data.payload.indexOf("Please download one") !== -1 || data.payload.indexOf("No language model") !== -1) {
                    if (typeof notifPopup !== "undefined") notifPopup.open(i18n.dtr("ubtms", "Action Required"), data.payload, "warning");
                } else {
                    if (typeof notifPopup !== "undefined") notifPopup.open(i18n.dtr("ubtms", "Error"), data.payload, "error");
                }
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
                previewText.cursorPosition = previewText.length;
                
                if (previewText.flickableItem) {
                    previewText.flickableItem.contentY = Math.max(0, previewText.flickableItem.contentHeight - previewText.flickableItem.height);
                } else if (previewText.flickable) {
                    previewText.flickable.contentY = Math.max(0, previewText.flickable.contentHeight - previewText.flickable.height);
                }
            }
        }
    }

    // Separate timer for scrolling during voice input - only scrolls, doesn't move cursor
    Timer {
        id: scrollToBottomTimer
        interval: 50
        repeat: false
        onTriggered: {
            if (previewText) {
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

                readOnly: is_read_only || root.listening || root.processing
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
                        visible: root.isVoiceInputEnabled
                        width: units.gu(3)
                        height: units.gu(3)
                        radius: units.gu(.5)
                        color: root.listening ? LomiriColors.red : LomiriColors.orange
                        
                        Icon {
                            id: voiceIcon
                            // source: "../../images/mic.svg"
                            name: "microphone"
                            width: units.gu(1.5)
                            height: units.gu(1.5)
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            opacity: (root.listening || root.processing) ? 0.5 : 1.0
                            color: "white"
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.listening) {
                                    console.log("[RichTextPreview] Stopping voice recognition...")
                                    root.listening = false
                                    root.processing = true
                                    root._currentVoiceStatus = i18n.dtr("ubtms", "Processing...");
                                    
                                    backend_bridge.call("backend.stop_voice_recognition", [])
                                    return;
                                }
                                if (root.processing) return; // Prevent double trigger
                                
                                console.log("[RichTextPreview] Voice recognition started")
                                root.textBeforeRecording = root.text
                                
                                root._partialRecognizedText = "";
                                root._currentVoiceStatus = i18n.dtr("ubtms", "Starting...");
                                
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
                        color: (root.listening || root.processing) ? LomiriColors.ash : LomiriColors.orange
                        opacity: (root.listening || root.processing) ? 0.5 : 1.0
                        
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
                            onClicked: {
                                if (!root.listening && !root.processing) {
                                    root.clicked()
                                }
                            }
                        }
                    }
                }
                //  padding: units.gu(2)
            }
        }
    }

    VoiceTimerWidget {
        id: voiceTimerWidget
        parent: mainView
        
        isListening: root.listening
        isProcessing: root.processing
        partialText: "" // Don't show partial text in the widget anymore
        voiceStatus: root._currentVoiceStatus
        
        onStopClicked: {
            console.log("[RichTextPreview] Stopping voice recognition from widget...")
            root.listening = false
            root.processing = true
            root._currentVoiceStatus = i18n.dtr("ubtms", "Processing...");
            
            backend_bridge.call("backend.stop_voice_recognition", [])
        }
    }
}
