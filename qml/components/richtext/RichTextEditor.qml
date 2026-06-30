/* Copyright (C) 2016 - 2018 Dan Chapman <dpniel@ubuntu.com>
   Copyright (C) 2025 Dekko Project - QtWebEngine Migration
   Adapted for timemanagement project

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation; either version 2 of
   the License or (at your option) version 3

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
import QtQuick 2.7
import QtQuick.Window 2.2
import Lomiri.Components 1.3
import QtWebEngine 1.5
import QtQuick.LocalStorage 2.7 as Sql
import "../system"
import "js/html-sanitizer.js" as HtmlSanitizer

Item {
    id: editor

    property bool isMultiColumn: apLayout.columns > 1

    // ============ PUBLIC PROPERTIES ============
    
    /** The HTML content of the editor */
    property string text: ""
    
    /** Whether the editor is in read-only mode */
    property bool readOnly: false
    
    /** Placeholder text when editor is empty */
    property string placeholder: "Write something amazing..."
    
    /** Dark mode state - auto-detected from theme */
    property bool darkMode: theme.name === "Ubuntu.Components.Themes.SuruDark"
    


    /**
     * Font formatting state object
     * Contains: bold, italic, underline, strikethrough
     */
    property alias font: p.font

    /** Current font size at cursor position (e.g., "12pt", "16px") */
    property string currentFontSize: "12pt"
    
    /** Current text color at cursor position */
    property color currentTextColor: "#000000"
    
    /** Current highlight/background color at cursor position */
    property color currentHighlightColor: "transparent"

    // ============ SIGNALS ============
    
    /** Emitted when content changes */
    signal contentChanged(string newText)
    
    /** Emitted when editor has finished loading */
    signal contentLoaded()

     // ============ VOICE RECOGNITION ============
    
    /** Whether the editor is currently listening for voice input */
    property bool listening: false
    
    /** Whether the editor is processing voice input */
    property bool processing: false
    
    /** Ignore the final result from the backend if stop was explicitly clicked */
    property bool ignoreNextVoiceResult: false
    
    /** Partial voice recognition text (for UI feedback) */
    property string _partialVoiceText: ""
    property string _currentVoiceStatus: ""
    
    /** Whether voice input is enabled globally */
    property bool isVoiceInputEnabled: true

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

    Connections {
        target: mainView.backend_bridge
        onMessageReceived: {
            if (data.event === "voice_recognition_partial") {
                // Only handle voice events if this instance is active
                if (!listening && !processing) return;
                
                var partialText = data.payload
                if (partialText) {
                    editor._currentVoiceStatus = "Listening...";
                    var script = "
                        var el = document.getElementById('voice-live-transcription');
                        if (el) {
                            el.innerText = ' ' + " + JSON.stringify(partialText) + ";
                        }
                    ";
                    wv.runJavaScript(script);
                }
            } else if (data.event === "voice_recognition_result") {
                if (editor.ignoreNextVoiceResult) {
                    editor.ignoreNextVoiceResult = false;
                    editor.listening = false;
                    editor.processing = false;
                    editor._currentVoiceStatus = "";
                    
                    var finalScript = "
                        var el = document.getElementById('voice-live-transcription');
                        if (el) {
                            var txt = el.innerText.trim();
                            var parent = el.parentNode;
                            if (txt) {
                                var textNode = document.createTextNode(txt);
                                parent.replaceChild(textNode, el);
                            } else {
                                parent.parentNode.removeChild(parent);
                            }
                        }
                        document.body.contentEditable = " + (!readOnly).toString() + ";
                    ";
                    wv.runJavaScript(finalScript);
                    editor.syncContent();
                    return;
                }
                
                editor.listening = false
                editor.processing = false
                var recognizedText = data.payload
                console.log("[RichTextEditor] Received recognition result: " + recognizedText)
                
                editor._currentVoiceStatus = "";
                
                var jsCode = "
                    var el = document.getElementById('voice-live-transcription');
                    var finalTxt = " + JSON.stringify(recognizedText) + ";
                    if (el) {
                        var parent = el.parentNode;
                        if (finalTxt && finalTxt.trim()) {
                            var textNode = document.createTextNode(finalTxt);
                            parent.replaceChild(textNode, el);
                        } else {
                            parent.parentNode.removeChild(parent);
                        }
                    }
                    document.body.contentEditable = " + (!readOnly).toString() + ";
                ";
                wv.runJavaScript(jsCode);
                
                // Force a sync to update the 'text' property and emit contentChanged
                editor.syncContent();
            } else if (data.event === "voice_recognition_status") {
                if (!listening && !processing) return;
                var statusText = data.payload;
                if (statusText) {
                    editor._currentVoiceStatus = statusText;
                }
            } else if (data.event === "voice_recognition_error") {
                editor.listening = false
                editor.processing = false
                editor._partialVoiceText = "";
                editor._currentVoiceStatus = "";
                console.log("[RichTextEditor] Voice recognition error: " + data.payload)
                if (data.payload.indexOf("Please download one") !== -1 || data.payload.indexOf("No language model") !== -1) {
                    if (typeof notifPopup !== "undefined") notifPopup.open(i18n.dtr("ubtms", "Action Required"), data.payload, "warning");
                } else {
                    if (typeof notifPopup !== "undefined") notifPopup.open(i18n.dtr("ubtms", "Error"), data.payload, "error");
                }
                
                wv.runJavaScript("document.body.contentEditable = " + (!readOnly).toString() + ";");
            }
        }
    }

    Component.onDestruction: {
        if (listening || processing) {
            console.log("[RichTextEditor] destruction: Stopping voice recognition...")
            stopAndFinalizeVoice();
        }
    }

    /**
     * Stop voice recognition and finalize any in-progress transcription.
     * Replaces the live transcription span with its text content so it
     * persists correctly in the saved HTML. Call this before saving.
     */
    function stopAndFinalizeVoice(callback) {
        ignoreNextVoiceResult = true;
        listening = false;
        processing = false;
        _currentVoiceStatus = "";
        
        wv.runJavaScript("
            var el = document.getElementById('voice-live-transcription');
            if (el) {
                var txt = el.innerText.trim();
                var parent = el.parentNode;
                if (txt) {
                    var textNode = document.createTextNode(txt);
                    parent.replaceChild(textNode, el);
                } else {
                    parent.parentNode.removeChild(parent);
                }
            }
            document.body.contentEditable = " + (!readOnly).toString() + ";
        ");
        
        mainView.backend_bridge.call("backend.stop_voice_recognition", []);
        
        // Sync content so the finalized text is captured
        syncContent();
        
        if (callback && typeof callback === 'function') {
            callback();
        }
    }

    /** Toggle voice recognition state */
    function toggleVoiceRecognition() {
        if (listening) {
            console.log("[RichTextEditor] Stopping voice recognition...")
            listening = false
            processing = true
            editor._currentVoiceStatus = "Processing..."
            mainView.backend_bridge.call("backend.stop_voice_recognition", [])
        } else {
            if (processing) return;
            console.log("[RichTextEditor] Starting voice recognition...")
            listening = true
            processing = false
            _partialVoiceText = ""
            editor._currentVoiceStatus = "Starting..."
            
            wv.runJavaScript("
                if (window.editor) {
                    // Clean up any stale span from a previous session
                    var oldEl = document.getElementById('voice-live-transcription');
                    if (oldEl) {
                        var txt = oldEl.innerText.trim();
                        var oldParent = oldEl.parentNode;
                        if (txt) {
                            var tn = document.createTextNode(txt);
                            oldParent.replaceChild(tn, oldEl);
                        } else {
                            oldParent.parentNode.removeChild(oldParent);
                        }
                    }
                    
                    var el = document.createElement('span');
                    el.id = 'voice-live-transcription';
                    el.innerText = ' ';
                    
                    var wrapper = document.createElement('div');
                    wrapper.appendChild(el);
                    document.body.appendChild(wrapper);
                    
                    document.body.contentEditable = false;
                    el.scrollIntoView({behavior: 'smooth', block: 'nearest'});
                }
            ");
            
            mainView.backend_bridge.call("backend.run_voice_recognition", [])
        }
    }

    // ============ PRIVATE PROPERTIES ============
    
    property bool _isLoaded: false
    property string _pendingText: ""
    property bool _internalUpdate: false

    /**
     * Tracks the last HTML content set to or received from Squire.
     * Prevents the feedback loop where binding updates cause setText()
     * to re-set identical content, which resets scroll position.
     */
    property string _lastSetContent: ""

    /**
     * When true, suppress emitting the contentChanged signal.
     * Starts as true so Squire's very first init events (fired via the URL-hash
     * bridge during page load, before onLoadingChanged fires) cannot clobber
     * Global.description_temporary_holder. Cleared in onLoadingChanged after
     * the real content is confirmed by getHTML().
     */
    property bool _suppressContentChanged: true

    Timer {
        id: suppressTimer
        interval: 600
        repeat: false
        onTriggered: {
            editor._suppressContentChanged = false;
        }
    }

    /**
     * Strip <script>...</script> tags from Squire's getHTML() output.
     * Squire returns the full body HTML including bridge/setup scripts;
     * we only want the actual user content.
     */
    function stripScriptTags(html) {
        if (!html) return "";
        return html.replace(/<script[\s\S]*?<\/script>/gi, "").replace(/^\s+|\s+$/g, "");
    }

    // ============ PUBLIC FUNCTIONS ============

    /** Toggle bold formatting */
    function toggleBold() {
        wv.runJavaScript("(function() { var e = window.editor; if (e.hasFormat('B') || e.hasFormat('STRONG')) { e.removeBold(); } else { e.bold(); } })();");
    }

    /** Toggle italic formatting */
    function toggleItalic() {
        wv.runJavaScript("(function() { var e = window.editor; if (e.hasFormat('I') || e.hasFormat('EM')) { e.removeItalic(); } else { e.italic(); } })();");
    }

    /** Toggle underline formatting */
    function toggleUnderline() {
        wv.runJavaScript("(function() { var e = window.editor; if (e.hasFormat('U')) { e.removeUnderline(); } else { e.underline(); } })();");
    }

    /** Toggle strikethrough formatting */
    function toggleStrikethrough() {
        wv.runJavaScript("(function() { var e = window.editor; if (e.hasFormat('S')) { e.removeStrikethrough(); } else { e.strikethrough(); } })();");
    }

    /** Undo user action */
    function undo() {
        wv.runJavaScript("window.editor.focus(); window.editor.undo();");
    }

    /** Redo user action */
    function redo() {
        wv.runJavaScript("window.editor.focus(); window.editor.redo();");
    }

    /** Create an unordered list */
    function makeUnorderedList() { 
        wv.runJavaScript("window.editor.focus(); window.editor.makeUnorderedList(); void 0;");
    }

    /** Create an ordered list */
    function makeOrderedList() { 
        wv.runJavaScript("window.editor.focus(); window.editor.makeOrderedList(); void 0;");
    }

    /**
     * Set font size
     * @param size - Size string like "12pt" or "16px"
     */
    function setFontSize(size) { 
        wv.runJavaScript("window.editor.focus(); window.editor.setFontSize('" + size + "'); void 0;");
    }

    /**
     * Set text color
     * @param color - Color string like "#FF0000"
     */
    function setTextColor(color) { 
        wv.runJavaScript("window.editor.focus(); window.editor.setTextColour('" + color + "'); void 0;");
    }

    /**
     * Set highlight/background color
     * @param color - Color string like "#FFFF00"
     */
    function setHighlightColor(color) { 
        wv.runJavaScript("window.editor.focus(); window.editor.setHighlightColour('" + color + "'); void 0;");
    }

    /** Remove all formatting from selected text */
    function removeAllFormatting() { 
        wv.runJavaScript("window.editor.focus(); window.editor.removeAllFormatting(); void 0;");
    }

    /**
     * Set text alignment
     * @param alignment - Qt.AlignLeft, Qt.AlignCenter, Qt.AlignRight, or Qt.AlignJustify
     */
    function setTextAlignment(alignment) { 
        p.textAlignment = alignment; 
    }

    /**
     * Create a link from selected text
     * @param url - Link URL
     */
    function insertLink(url) {
        wv.runJavaScript("window.editor.makeLink('" + url + "');");
    }

    /**
     * Insert a link with custom text
     * @param url - Link URL
     * @param text - Link display text
     */
    function insertLinkWithText(url, text) {
        wv.runJavaScript("window.editor.insertHTML('<a href=\"" + url + "\">" + text + "</a>');");
    }

    /**
     * Sanitize HTML content using the centralized HtmlSanitizer.
     * Handles Qt wrappers, Odoo HTML, and ensures clean content for Squire.
     * @param content - HTML string that may need sanitization
     * @return Clean HTML content
     */
    function sanitizeHtml(content) {
        if (!content) return "";
        
        // Check if sanitization is needed
        if (HtmlSanitizer.needsSanitization(content)) {
            console.log("[RichTextEditor] Sanitizing HTML content");
            var result = HtmlSanitizer.sanitize(content);
            console.log("[RichTextEditor] Sanitized result:", result ? result.substring(0, 100) : "(empty)");
            return result;
        }
        
        return content;
    }

    /**
     * Set text content
     * @param htmlText - HTML string to set
     */
    function setText(htmlText) {
        // Sanitize the HTML to remove Qt wrapper if present
        var cleanedDoc = sanitizeHtml(htmlText ? htmlText.trim() : "");
        
        if (_isLoaded) {
            // Skip if content is identical to what Squire already has,
            // to avoid resetting scroll position via setHTML()
            if (cleanedDoc === _lastSetContent) {
                return;
            }
            _lastSetContent = cleanedDoc;
            // Suppress contentChanged during setHTML — Squire fires intermediate
            // empty-content events before delivering the real content.
            _suppressContentChanged = true;
            suppressTimer.restart();
            var jsCode = "window.editor.setHTML(" + JSON.stringify(cleanedDoc) + ");";
            wv.runJavaScript(jsCode);
        } else {
            _pendingText = cleanedDoc;
        }
    }

    /**
     * Get text content asynchronously
     * @param callback - Function to call with result
     */
    function getText(callback) {
        if (_isLoaded) {
            wv.runJavaScript("window.editor.getHTML();", function(result) {
                if (callback) {
                    callback(result || "");
                }
            });
        } else if (callback) {
            callback("");
        }
    }

    /**
     * Get formatted text synchronously (API compatible with RichTextPreview)
     * Returns the cached 'text' property which is kept up-to-date via contentChanged events.
     * @return Current text property value
     */
    function getFormattedText() {
        return editor.text || "";
    }

    /**
     * Check if content is valid HTML content (not the raw editor page)
     * Uses the centralized HtmlSanitizer validation.
     * @param content - HTML string to validate
     * @return true if content is valid, false if it contains editor internals
     */
    function isValidContent(content) {
        if (!content) return true; // Empty is valid
        var validation = HtmlSanitizer.validate(content);
        if (!validation.isValid) {
            console.log("[RichTextEditor] Invalid content:", validation.issues.join(", "));
        }
        return validation.isValid;
    }

    /**
     * Force sync current content
     * Returns the current cached text for immediate sync needs.
     */
    function syncContent() {
        if (_isLoaded && !readOnly) {
            getText(function(content) {
                // Only update if content is valid (not corrupted editor HTML)
                if (isValidContent(content) && content !== editor.text) {
                    _internalUpdate = true;
                    editor.text = content;
                    editor.contentChanged(content);
                    _internalUpdate = false;
                }
            });
        }
        return editor.text || "";
    }

    // ============ PROPERTY CHANGE HANDLERS ============

    onTextChanged: {
        if (!_internalUpdate) {
            if (_isLoaded) {
                setText(text);
            } else {
                _pendingText = text || "";
            }
        }
    }

    onReadOnlyChanged: {
        if (_isLoaded) {
            wv.runJavaScript("document.body.contentEditable = " + (!readOnly).toString() + ";");
        }
    }

    onDarkModeChanged: {
        if (_isLoaded) {
            wv.reload();
        }
    }

    // ============ EDITOR AREA ============

    // Background behind WebView to prevent any white flash
    Rectangle {
        anchors.fill: parent
        color: darkMode ? "#2d2d2d" : "#ffffff"
        z: -1
    }

    WebEngineView {
        id: wv
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: editor._oskHeight
        zoomFactor: isMultiColumn ? 1.0 : 2.52
        backgroundColor: darkMode ? "#2d2d2d" : "#ffffff"
        
        url: Qt.resolvedUrl("js/editor.html") + "?darkMode=" + darkMode + 
             "&readonly=" + readOnly + 
             "&placeholder=" + encodeURIComponent(placeholder)

        settings.javascriptEnabled: true
        settings.localContentCanAccessRemoteUrls: false
        settings.localContentCanAccessFileUrls: true

        onLoadingChanged: {
            if (loadRequest.status === WebEngineView.LoadSucceededStatus) {
                _isLoaded = true;
                // Suppress spurious empty contentChanged events that Squire
                // fires during initialisation / setHTML processing.
                _suppressContentChanged = true;
                suppressTimer.restart();
                console.log("[RichTextEditor] Loaded. text=", editor.text ? editor.text.substring(0, 100) : "(empty)", "_pendingText=", _pendingText ? _pendingText.substring(0, 100) : "(empty)");
                
                // Set pending text if any
                if (_pendingText !== "") {
                    console.log("[RichTextEditor] Setting pending text");
                    setText(_pendingText);
                    _pendingText = "";
                } else if (editor.text !== "") {
                    console.log("[RichTextEditor] Setting editor.text");
                    setText(editor.text);
                }
                
                // Apply read-only state
                if (readOnly) {
                    wv.runJavaScript("document.body.contentEditable = false;");
                }
                
                // Sync content after a short delay to ensure Squire has processed the HTML.
                // NOTE: Do NOT clear _suppressContentChanged here. The suppress timer (600ms)
                // is the sole authority that clears suppression. Clearing it here races with
                // any subsequent setText() calls triggered by onContentLoaded handlers (e.g.
                // ReadMorePage.onContentLoaded sets editor.text which calls setText again),
                // causing Squire's intermediate <div><br></div> events to slip through.
                Qt.callLater(function() {
                    wv.runJavaScript("window.editor.getHTML();", function(result) {
                        // Strip script tags that Squire includes from its body HTML
                        var cleanResult = stripScriptTags(result);
                        console.log("[RichTextEditor] Synced from Squire:", cleanResult ? cleanResult.substring(0, 100) : "(empty)");
                        if (cleanResult && cleanResult !== editor.text) {
                            _internalUpdate = true;
                            editor.text = cleanResult;
                            _internalUpdate = false;
                        }
                    });
                });
                
                editor.contentLoaded();
            } else if (loadRequest.status === WebEngineView.LoadFailedStatus) {
                console.error("[RichTextEditor] Failed to load editor:", loadRequest.errorString);
            }
        }

        // Handle URL fragment changes for bridge communication
        onUrlChanged: {
            var urlStr = url.toString();
            var hashIndex = urlStr.indexOf('#');
            if (hashIndex === -1) return;
            
            var hash = urlStr.substring(hashIndex + 1);
            
            if (hash.indexOf('qtevent:') === 0) {
                var parts = hash.substring(8).split(':');
                var eventType = parts[0];
                var payload = {};
                if (parts.length > 1) {
                    try {
                        var decoded = JSON.parse(decodeURIComponent(parts[1]));
                        payload = decoded.payload || decoded;
                    } catch (e) {
                        // Silently ignore parse errors
                    }
                }
                p.handleEvent(eventType, payload);
            }
        }

        onNewViewRequested: {
            request.action = WebEngineView.IgnoreRequest;
        }
    }

    // ============ PRIVATE IMPLEMENTATION ============

    QtObject {
        id: p
        
        property QtObject font: QtObject {
            property bool bold: false
            property bool italic: false
            property bool underline: false
            property bool strikethrough: false
            
            onBoldChanged: {
                if (bold) {
                    wv.runJavaScript("window.editor.bold();");
                } else {
                    wv.runJavaScript("window.editor.removeBold();");
                }
            }
            onItalicChanged: {
                if (italic) {
                    wv.runJavaScript("window.editor.italic();");
                } else {
                    wv.runJavaScript("window.editor.removeItalic();");
                }
            }
            onUnderlineChanged: {
                if (underline) {
                    wv.runJavaScript("window.editor.underline();");
                } else {
                    wv.runJavaScript("window.editor.removeUnderline();");
                }
            }
            onStrikethroughChanged: {
                if (strikethrough) {
                    wv.runJavaScript("window.editor.strikethrough();");
                } else {
                    wv.runJavaScript("window.editor.removeStrikethrough();");
                }
            }
        }
        
        property int textAlignment: Qt.AlignLeft

        onTextAlignmentChanged: {
            var alignStr = "left";
            switch (textAlignment) {
                case Qt.AlignLeft:
                    alignStr = "left";
                    break;
                case Qt.AlignHCenter:
                    alignStr = "center";
                    break;
                case Qt.AlignRight:
                    alignStr = "right";
                    break;
                case Qt.AlignJustify:
                    alignStr = "justify";
                    break;
            }
            wv.runJavaScript("window.editor.setTextAlignment('" + alignStr + "');");
        }

        function handleEvent(eventType, payload) {
            switch (eventType) {
                case 'contentChanged':
                    if (!editor._internalUpdate) {
                        var content = payload.content || "";
                        // Strip script tags — Squire's getHTML() returns the full body
                        // HTML including bridge/setup scripts
                        content = editor.stripScriptTags(content);
                        console.log("[RichTextEditor] contentChanged from Squire, length:", content.length);

                        // Track what Squire currently has to prevent feedback loop
                        editor._lastSetContent = content;

                        // Update internal text property always so editor.text stays
                        // in sync, but only emit the public contentChanged signal
                        // when we are NOT in a load/setText suppression window.
                        // This prevents Squire's intermediate empty-content events
                        // from overwriting Global.description_temporary_holder.
                        editor._internalUpdate = true;
                        editor.text = content;
                        editor._internalUpdate = false;

                        if (!editor._suppressContentChanged) {
                            editor.contentChanged(content);
                        }
                    }
                    break;
                case 'pathChanged':
                    parseFormatFromPath(payload.path || "");
                    break;
            }
        }

        function parseFormatFromPath(path) {
            // Parse formatting tags
            var hasBold = path.indexOf('>B') !== -1 || path.indexOf('>STRONG') !== -1;
            var hasItalic = path.indexOf('>I') !== -1 || path.indexOf('>EM') !== -1;
            var hasUnderline = path.indexOf('>U') !== -1;
            
            if (font.bold !== hasBold) font.bold = hasBold;
            if (font.italic !== hasItalic) font.italic = hasItalic;
            if (font.underline !== hasUnderline) font.underline = hasUnderline;
            
            // Parse font size [fontSize=12pt]
            var fontSizeMatch = path.match(/\[fontSize=([^\]]+)\]/);
            if (fontSizeMatch && fontSizeMatch[1]) {
                editor.currentFontSize = fontSizeMatch[1];
            }
            
            // Parse text color [color=rgb(0,0,0)] or [color=#000000]
            var colorMatch = path.match(/\[color=([^\]]+)\]/);
            if (colorMatch && colorMatch[1]) {
                editor.currentTextColor = colorMatch[1];
            }
            
            // Parse highlight/background color [backgroundColor=rgb(255,255,0)]
            var bgColorMatch = path.match(/\[backgroundColor=([^\]]+)\]/);
            if (bgColorMatch && bgColorMatch[1]) {
                editor.currentHighlightColor = bgColorMatch[1];
            } else {
                editor.currentHighlightColor = "transparent";
            }
        }
    }

    // ============ KEYBOARD HANDLING ============

    /**
     * On-screen keyboard height (QML logical pixels).
     * Qt.inputMethod.keyboardRectangle is in window coordinates,
     * same coordinate space as QML — no devicePixelRatio conversion needed.
     */
    property real _oskHeight: Qt.inputMethod.visible
                              ? Qt.inputMethod.keyboardRectangle.height
                              : 0

    /**
     * Push the current keyboard height into the WebEngineView JS layer
     * so scrollCursorIntoView() knows how much of the viewport is hidden.
     * Heights are converted to CSS pixels (QML px / zoomFactor).
     */
    function _pushKeyboardHeightToJs() {
        if (!_isLoaded) return;
        var cssPx = Math.round(_oskHeight / wv.zoomFactor);
        wv.runJavaScript("window.setKeyboardHeight(" + cssPx + ");");
    }

    on_OskHeightChanged: _pushKeyboardHeightToJs()

    Connections {
        target: Qt.inputMethod
        onVisibleChanged: {
            if (_isLoaded) {
                editor._pushKeyboardHeightToJs();
            }
        }
    }

    // ============ LOADING INDICATOR ============

    ActivityIndicator {
        id: loadingIndicator
        anchors.centerIn: parent
        running: !_isLoaded
        visible: running
    }

    // ============ ERROR HANDLING ============

    Rectangle {
        id: errorMessage
        anchors.fill: parent
        color: darkMode ? "#3d3d3d" : "#f5f5f5"
        visible: !wv.loading && _isLoaded === false && wv.loadProgress === 100

        Column {
            anchors.centerIn: parent
            spacing: units.gu(2)

            Icon {
                name: "dialog-error"
                width: units.gu(6)
                height: units.gu(6)
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Label {
                text: "Failed to load rich text editor"
                fontSize: "medium"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Button {
                text: "Retry"
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    wv.reload();
                }
            }
        }
    }

    VoiceTimerWidget {
        id: voiceTimerWidget
        parent: mainView
        anchors.bottomMargin: editor._oskHeight + units.gu(1)
        
        isListening: editor.listening
        isProcessing: editor.processing
        partialText: "" // Don't show partial text in the widget anymore
        voiceStatus: editor._currentVoiceStatus
        
        onStopClicked: {
            console.log("[RichTextEditor] Stopping voice recognition from widget...")
            editor.stopAndFinalizeVoice();
        }
    }
}
