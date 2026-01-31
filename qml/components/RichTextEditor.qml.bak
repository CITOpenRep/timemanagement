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
import Lomiri.Components 1.3
import QtWebEngine 1.5

Item {
    id: editor

    // ============ PUBLIC PROPERTIES (preserving original API) ============
    
    /** The HTML content of the editor */
    property string text: ""
    
    /** Whether the editor is in read-only mode */
    property bool readOnly: false
    
    /** Font size in pixels */
    property int fontSize: 13
    
    /** Placeholder text when editor is empty */
    property string placeholder: "Write something amazing..."
    
    /** Dark mode state - auto-detected from theme */
    property bool darkMode: theme.name === "Ubuntu.Components.Themes.SuruDark"
    
    /** Border color for the editor wrapper */
    property color borderColor: "#dee2e6"
    
    /** Focus highlight color */
    property color focusColor: "#714B67"

    /** Focused state of the editor */
    readonly property bool focused: p.focused

    /** Undo state of the document */
    readonly property bool canUndo: p.undoState && p.undoState['canUndo'] === true

    /** Redo state of the document */
    readonly property bool canRedo: p.undoState && p.undoState['canRedo'] === true

    /**
     * Font formatting state object
     * Contains: bold, italic, underline, size, textColor, highlightColor
     */
    property alias font: p.font

    // ============ SIGNALS (preserving original API) ============
    
    /** Emitted when content changes */
    signal contentChanged(string newText)
    
    /** Emitted when editor has finished loading */
    signal contentLoaded()
    
    /** Emitted when the formatting path changes */
    signal pathChanged(string path)
    
    /** Emitted when text is selected */
    signal textSelected(string text)
    
    /** Emitted when document is ready (in response to requestDocument) */
    signal documentReady(string document)
    
    /** Emitted when cursor position changes */
    signal cursorPositionChanged(var rect)

    // ============ PRIVATE PROPERTIES ============
    
    property bool _isLoaded: false
    property string _pendingText: ""
    property bool _internalUpdate: false
    property int _replyCounter: 0
    property var _pendingReplies: ({})

    // ============ PUBLIC FUNCTIONS (preserving original API) ============

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
        console.log("[RichTextEditor] undo called");
        wv.runJavaScript("window.editor.focus(); window.editor.undo();");
    }

    /** Redo user action */
    function redo() {
        console.log("[RichTextEditor] redo called");
        wv.runJavaScript("window.editor.focus(); window.editor.redo();");
    }

    /**
     * Focus or blur the editor
     * @param shouldFocus - true to focus, false to blur
     */
    function focusEditor(shouldFocus) {
        if (shouldFocus) {
            wv.forceActiveFocus();
            wv.runJavaScript("window.editor.focus();");
        } else {
            wv.runJavaScript("window.editor.blur();");
        }
    }

    /**
     * Request the current HTML document content
     * Emits documentReady signal when ready
     */
    function requestDocument() { 
        p.getHTML(); 
    }

    /**
     * Set the HTML document content
     * @param doc - HTML string to set
     */
    function setDocument(doc) {
        // Clean the content - remove leading/trailing whitespace while preserving HTML structure
        var cleanedDoc = doc ? doc.trim() : "";
        console.log("[RichTextEditor] setDocument called with:", cleanedDoc ? cleanedDoc.substring(0, 100) : "empty");
        
        // Use JSON.stringify for proper escaping to avoid issues with quotes and special characters
        var jsCode = "window.editor.setHTML(" + JSON.stringify(cleanedDoc) + ");";
        wv.runJavaScript(jsCode);
    }

    /** Move cursor to start of document */
    function moveCursorToStart() { 
        wv.runJavaScript("window.editor.moveCursorToStart();"); 
    }

    /** Move cursor to end of document */
    function moveCursorToEnd() { 
        wv.runJavaScript("window.editor.moveCursorToEnd();"); 
    }

    /**
     * Insert an image at cursor position
     * @param src - Image source URL
     */
    function insertImage(src) {
        wv.runJavaScript("window.editor.insertImage('" + src + "'); void 0;");
    }

    /**
     * Create a link from selected text
     * @param url - Link URL
     * @param attrs - Optional attributes object
     */
    function insertLink(url, attrs) {
        wv.runJavaScript("window.editor.makeLink('" + url + "');");
    }

    /**
     * Insert a link with custom text
     * @param url - Link URL
     * @param text - Link display text
     * @param attrs - Optional attributes object
     */
    function insertLinkWithText(url, text, attrs) {
        // Insert text then make it a link
        wv.runJavaScript("window.editor.insertHTML('<a href=\"" + url + "\">" + text + "</a>');");
    }

    /** Increase current quote level by 1 */
    function increaseQuoteLevel() { 
        wv.runJavaScript("window.editor.increaseQuoteLevel(); void 0;"); 
    }

    /** Decrease current quote level by 1 */
    function decreaseQuoteLevel() { 
        wv.runJavaScript("window.editor.decreaseQuoteLevel(); void 0;"); 
    }

    /** Create an unordered list */
    function makeUnorderedList() { 
        console.log("[RichTextEditor] makeUnorderedList called");
        wv.runJavaScript("window.editor.focus(); window.editor.makeUnorderedList(); void 0;");
    }

    /** Create an ordered list */
    function makeOrderedList() { 
        console.log("[RichTextEditor] makeOrderedList called");
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

    // ============ LEGACY API FUNCTIONS (for backward compatibility) ============

    /**
     * Set text content (legacy API)
     * @param htmlText - HTML string to set
     */
    function setText(htmlText) {
        console.log("RichTextEditor.setText called with:", htmlText ? htmlText.substring(0, 100) : "empty");
        if (_isLoaded) {
            setDocument(htmlText || "");
        } else {
            _pendingText = htmlText || "";
        }
    }

    /**
     * Get text content asynchronously (legacy API)
     * @param callback - Function to call with result
     */
    function getText(callback) {
        if (_isLoaded) {
            console.log("[RichTextEditor] getText called");
            wv.runJavaScript("window.editor.getHTML();", function(result) {
                console.log("[RichTextEditor] getText result:", result ? result.substring(0, 100) : "empty");
                if (callback) {
                    callback(result || "");
                }
            });
        } else if (callback) {
            console.log("[RichTextEditor] getText called but not loaded");
            callback("");
        }
    }

    /**
     * Get formatted text synchronously (API compatible with RichTextPreview)
     * Returns the cached 'text' property which is kept up-to-date via contentChanged events.
     * @return Current text property value
     */
    function getFormattedText() {
        // The text property is updated whenever contentChanged event fires from the JS editor
        // This should be reliable for sync access
        return editor.text || "";
    }

    /**
     * Set read-only mode (legacy API)
     * @param isReadOnly - true to enable read-only
     */
    function setReadOnly(isReadOnly) {
        if (_isLoaded) {
            wv.runJavaScript("document.body.contentEditable = " + (!isReadOnly).toString() + ";");
        }
    }

    /**
     * Check if content has changed (legacy API)
     * @param callback - Function to call with boolean result
     */
    function hasChanged(callback) {
        // For now, always return true since we don't track initial state
        if (callback) {
            callback(true);
        }
    }

    /**
     * Force sync current content (legacy API)
     * This updates the text property from the WebEngine editor synchronously if possible,
     * otherwise returns the current cached text property.
     */
    function syncContent() {
        console.log("[RichTextEditor] syncContent called - _isLoaded:", _isLoaded, "readOnly:", readOnly);
        if (_isLoaded && !readOnly) {
            // Get current content and update text property
            getText(function(content) {
                console.log("[RichTextEditor] syncContent got content length:", content ? content.length : 0);
                if (content !== editor.text) {
                    _internalUpdate = true;
                    editor.text = content;
                    editor.contentChanged(content);
                    _internalUpdate = false;
                }
            });
        }
        // Always return current cached text for immediate sync needs
        return editor.text || "";
    }

    // ============ PROPERTY CHANGE HANDLERS ============

    onTextChanged: {
        console.log("[RichTextEditor] onTextChanged - _internalUpdate:", _internalUpdate, "_isLoaded:", _isLoaded, "text length:", text ? text.length : 0);
        if (!_internalUpdate) {
            if (_isLoaded) {
                setText(text);
            } else {
                // Store as pending text to be set when editor loads
                _pendingText = text || "";
            }
        }
    }

    onReadOnlyChanged: {
        if (_isLoaded) {
            setReadOnly(readOnly);
        }
    }

    onDarkModeChanged: {
        if (_isLoaded) {
            wv.reload();
        }
    }

    onFocusChanged: {
        if (!focus) focusEditor(false);
    }

    onPathChanged: {
        p.parseFormatFromPath(path);
    }

    // ============ EDITOR WRAPPER ============

    Rectangle {
        id: editorWrapper
        anchors.fill: parent
        color: darkMode ? "#2d2d2d" : "#ffffff"
        border.width: 1
        border.color: darkMode ? "#495057" : borderColor
        radius: 4

        WebEngineView {
            id: wv
            anchors.fill: parent
            anchors.margins: units.gu(0.5)
            
            // High DPI zoom factor - adjust as needed for your device
          //  zoomFactor: 2.52
            
            url: Qt.resolvedUrl("js/editor.html") + "?darkMode=" + darkMode + 
                 "&readonly=" + readOnly + 
                 "&placeholder=" + encodeURIComponent(placeholder)

            settings.javascriptEnabled: true
            settings.localContentCanAccessRemoteUrls: false
            settings.localContentCanAccessFileUrls: true

            // Helper function to call JS functions without expecting a reply
            function callFuncNoReply(funcName, payload) {
                var payloadStr;
                if (payload === undefined || payload === null) {
                    payloadStr = '{}';
                } else if (typeof payload === 'string') {
                    payloadStr = JSON.stringify(payload);
                } else {
                    payloadStr = JSON.stringify(payload);
                }
                var jsCode = "qtBridge.processMessage('" + funcName + "', " + payloadStr + ");";
                console.log("[RichTextEditor] Calling JS:", jsCode);
                runJavaScript(jsCode);
            }

            // Helper function to call JS functions with a reply
            function callFuncWithReply(funcName, payload, callback) {
                var callId = editor._replyCounter++;
                editor._pendingReplies[callId] = callback;
                var payloadStr = payload ? JSON.stringify(payload) : '{}';
                runJavaScript("qtBridge.processMessageWithReply('" + funcName + "', " + payloadStr + ", " + callId + ");");
            }

            onLoadingChanged: {
                if (loadRequest.status === WebEngineView.LoadSucceededStatus) {
                    console.log("[RichTextEditor] WebEngine loaded successfully");
                    _isLoaded = true;
                    
                    // Set pending text if any
                    console.log("[RichTextEditor] Checking pending text - _pendingText length:", _pendingText ? _pendingText.length : 0, "editor.text length:", editor.text ? editor.text.length : 0);
                    if (_pendingText !== "") {
                        console.log("[RichTextEditor] Setting pending text:", _pendingText ? _pendingText.substring(0, 100) : "empty");
                        setText(_pendingText);
                        _pendingText = "";
                    } else if (editor.text !== "") {
                        console.log("[RichTextEditor] Setting editor.text:", editor.text ? editor.text.substring(0, 100) : "empty");
                        setText(editor.text);
                    }
                    
                    // Apply read-only state
                    setReadOnly(readOnly);
                    
                    // Emit contentLoaded signal
                    editor.contentLoaded();
                } else if (loadRequest.status === WebEngineView.LoadFailedStatus) {
                    console.error("[RichTextEditor] Failed to load editor:", loadRequest.errorString);
                }
            }

            onJavaScriptConsoleMessage: {
                console.log("[Editor JS]", message);
            }

            // Handle URL fragment changes for bridge communication
            onUrlChanged: {
                var urlStr = url.toString();
                var hashIndex = urlStr.indexOf('#');
                if (hashIndex === -1) return;
                
                var hash = urlStr.substring(hashIndex + 1);
                
                // Handle events from JS
                if (hash.indexOf('qtevent:') === 0) {
                    var parts = hash.substring(8).split(':');
                    var eventType = parts[0];
                    var payload = {};
                    if (parts.length > 1) {
                        try {
                            var decoded = JSON.parse(decodeURIComponent(parts[1]));
                            // The bridge wraps in {type, payload}, extract the nested payload
                            payload = decoded.payload || decoded;
                        } catch (e) {
                            console.warn("[RichTextEditor] Failed to parse event payload:", e);
                        }
                    }
                    p.handleEvent(eventType, payload);
                }
                // Handle replies from JS
                else if (hash.indexOf('qtreply:') === 0) {
                    var replyParts = hash.substring(8).split(':');
                    var callId = parseInt(replyParts[0]);
                    var replyData = null;
                    if (replyParts.length > 1) {
                        try {
                            var decoded = JSON.parse(decodeURIComponent(replyParts[1]));
                            replyData = decoded.data;
                        } catch (e) {
                            console.warn("[RichTextEditor] Failed to parse reply:", e);
                        }
                    }
                    
                    if (editor._pendingReplies[callId]) {
                        editor._pendingReplies[callId](replyData);
                        delete editor._pendingReplies[callId];
                    }
                }
            }

            onNewViewRequested: {
                request.action = WebEngineView.IgnoreRequest;
            }
        }
    }

    // ============ PRIVATE IMPLEMENTATION ============

    QtObject {
        id: p

        property bool focused: false
        property var undoState: null
        property string template: ""
        
        property QtObject font: QtObject {
            property bool bold: false
            property bool italic: false
            property bool underline: false
            property bool strikethrough: false
            property int size: 13
            property color textColor: "black"
            property color highlightColor: "white"
            
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
        property string selectedText: ""

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

        function getHTML() {
            wv.runJavaScript("window.editor.getHTML();", function(html) {
                editor.documentReady(html || "");
            });
        }

        function handleEvent(eventType, payload) {
            switch (eventType) {
                case 'editorReady':
                    console.log("[RichTextEditor] Editor ready");
                    break;
                case 'contentChanged':
                    console.log("[RichTextEditor] contentChanged event received, content length:", payload.content ? payload.content.length : 0);
                    if (!editor._internalUpdate) {
                        editor._internalUpdate = true;
                        editor.text = payload.content || "";
                        editor.contentChanged(payload.content || "");
                        editor._internalUpdate = false;
                    }
                    break;
                case 'pathChanged':
                    editor.pathChanged(payload.path || "");
                    break;
                case 'textSelected':
                    p.selectedText = payload.text || "";
                    editor.textSelected(payload.text || "");
                    break;
                case 'cursorPositionChanged':
                    editor.cursorPositionChanged(payload);
                    break;
                case 'undoStateChanged':
                    p.undoState = payload;
                    break;
                case 'focus':
                    p.focused = true;
                    break;
                case 'blur':
                    p.focused = false;
                    break;
            }
        }

        function parseFormatFromPath(path) {
            // Parse path string to update font formatting state
            // Path format: "DIV>B>I" or "DIV>SPAN[fontSize=14pt]"
            var hasBold = path.indexOf('>B') !== -1 || path.indexOf('>STRONG') !== -1;
            var hasItalic = path.indexOf('>I') !== -1 || path.indexOf('>EM') !== -1;
            var hasUnderline = path.indexOf('>U') !== -1;
            
            // Update without triggering change handlers
            if (font.bold !== hasBold) font.bold = hasBold;
            if (font.italic !== hasItalic) font.italic = hasItalic;
            if (font.underline !== hasUnderline) font.underline = hasUnderline;
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
}
