import QtQuick 2.7
import Lomiri.Components 1.3
import QtWebEngine 1.5

Item {
    id: richTextEditor

    // Public properties
    property string text: ""
    property bool readOnly: false
    property int fontSize: 13
    property string placeholder: "Write something amazing..."
    property bool darkMode: theme.name === "Ubuntu.Components.Themes.SuruDark"
    property color borderColor: "#dee2e6"
    property color focusColor: "#714B67"

    // Signals
    signal contentChanged(string newText)
    signal contentLoaded

    // Private properties
    property bool _isLoaded: false
    property string _pendingText: ""

    // Odoo-style wrapper
    Rectangle {
        id: editorWrapper
        anchors.fill: parent
        color: darkMode ? "#2d2d2d" : "#ffffff"
        border.width: 1
        border.color: darkMode ? "#495057" : borderColor
        radius: 4

        // Add subtle shadow effect
        Rectangle {
            anchors.fill: parent
            anchors.margins: -1
            color: "transparent"
            border.width: 1
            border.color: parent.border.color
            radius: parent.radius
            opacity: 0.1
            z: -1
        }

        WebEngineView {
            id: webView
            anchors.fill: parent
            anchors.margins: 1

            // Set a default zoom factor to make content larger on high-DPI screens (Please uncomment while building on a real device.)
          //  zoomFactor: 2.52

            // Load the Quill.js HTML file
            url: Qt.resolvedUrl("quill-editor.html") + "?" + (readOnly ? "readonly=true" : "readonly=false") + "&darkMode=" + darkMode

            // Handle page load completion
            onLoadingChanged: {
                if (loadRequest.status === WebEngineView.LoadSucceededStatus) {
                    _isLoaded = true;
                    contentLoaded();

                    // Set initial content if there was pending text
                    if (_pendingText !== "") {
                        setText(_pendingText);
                        _pendingText = "";
                    }

                    // Set read-only mode
                    setReadOnly(readOnly);
                }
            }

            // Handle JavaScript messages from the web page
            onNewViewRequested: {
                // Handle any navigation requests if needed
                request.action = WebEngineView.IgnoreRequest;
            }

        onJavaScriptConsoleMessage: {
            console.log("WebView Console:", message);
        }

            // Enable JavaScript
            settings.javascriptEnabled: true
        }
    }    // Function to clean Qt HTML and convert it to standard HTML
    function cleanQtHtml(qtHtml) {
        if (!qtHtml || qtHtml.trim() === "") {
            return "";
        }

        var cleaned = qtHtml;

        // Remove DOCTYPE declaration and HTML wrapper if present
        if (cleaned.indexOf("<!DOCTYPE") !== -1) {
            // Extract content from body tag
            var bodyStart = cleaned.indexOf("<body");
            var bodyEnd = cleaned.indexOf("</body>");

            if (bodyStart !== -1 && bodyEnd !== -1) {
                // Find the end of the opening body tag
                var bodyTagEnd = cleaned.indexOf(">", bodyStart);
                if (bodyTagEnd !== -1) {
                    cleaned = cleaned.substring(bodyTagEnd + 1, bodyEnd);
                }
            }
        }

        // Convert Qt's CSS-based formatting to Quill-friendly HTML tags
        // Convert font-weight:600 to <strong> tags
        cleaned = cleaned.replace(/<span style="([^"]*?)font-weight:\s*600;([^"]*?)">(.*?)<\/span>/g, function (match, beforeStyle, afterStyle, content) {
            var newStyle = (beforeStyle + afterStyle).replace(/;\s*;/g, ';').replace(/^;|;$/g, '');
            if (newStyle.trim() === '') {
                return '<strong>' + content + '</strong>';
            } else {
                return '<strong><span style="' + newStyle + '">' + content + '</span></strong>';
            }
        });

        // Convert text-decoration: underline to <u> tags
        cleaned = cleaned.replace(/<span style="([^"]*?)text-decoration:\s*underline;([^"]*?)">(.*?)<\/span>/g, function (match, beforeStyle, afterStyle, content) {
            var newStyle = (beforeStyle + afterStyle).replace(/;\s*;/g, ';').replace(/^;|;$/g, '');
            if (newStyle.trim() === '') {
                return '<u>' + content + '</u>';
            } else {
                return '<u><span style="' + newStyle + '">' + content + '</span></u>';
            }
        });

        // Convert text-decoration: line-through to <s> tags
        cleaned = cleaned.replace(/<span style="([^"]*?)text-decoration:\s*line-through;([^"]*?)">(.*?)<\/span>/g, function (match, beforeStyle, afterStyle, content) {
            var newStyle = (beforeStyle + afterStyle).replace(/;\s*;/g, ';').replace(/^;|;$/g, '');
            if (newStyle.trim() === '') {
                return '<s>' + content + '</s>';
            } else {
                return '<s><span style="' + newStyle + '">' + content + '</span></s>';
            }
        });

        // Clean up Qt-specific attributes and styles
        cleaned = cleaned
        // Remove Qt-specific CSS properties
        .replace(/-qt-block-indent:\s*\d+;\s*/g, "").replace(/-qt-list-indent:\s*\d+;\s*/g, "").replace(/text-indent:\s*0px;\s*/g, "")
        // Remove layout-specific margin styles
        .replace(/margin-top:\s*\d+px;\s*/g, "").replace(/margin-bottom:\s*\d+px;\s*/g, "").replace(/margin-left:\s*0px;\s*/g, "").replace(/margin-right:\s*0px;\s*/g, "")
        // Remove meta tags and head content if any remain
        .replace(/<meta[^>]*>/g, "").replace(/<style[^>]*>[\s\S]*?<\/style>/g, "")
        // Clean up empty style attributes
        .replace(/style="\s*"/g, "").replace(/style=''/g, "");

        console.log("Original Qt HTML:", qtHtml.substring(0, 300) + "...");
        console.log("Cleaned HTML:", cleaned.substring(0, 300) + "...");

        return cleaned.trim();
    }

    // Function to set text content
    function setText(htmlText) {
        console.log("RichTextEditor.setText called with:", htmlText);
        if (_isLoaded) {
            // Clean Qt HTML before setting
            var cleanedText = cleanQtHtml(htmlText || "");
            console.log("Cleaned HTML:", cleanedText);

            // Use JSON.stringify to properly escape the content for JavaScript
            var escapedText = JSON.stringify(cleanedText);
            console.log("Calling setContent with escaped text:", escapedText);
            webView.runJavaScript("window.quillEditor.setContent(" + escapedText + ");");
        } else {
            _pendingText = htmlText;
        }
    }

    // Function to get text content
    function getText(callback) {
        if (_isLoaded) {
            webView.runJavaScript("window.quillEditor.getContent();", function (result) {
                if (callback) {
                    callback(result);
                }
            });
        } else if (callback) {
            callback("");
        }
    }

    // Function to set read-only mode
    function setReadOnly(isReadOnly) {
        if (_isLoaded) {
            webView.runJavaScript("window.quillEditor.setReadOnly(" + isReadOnly + ");");
        }
    }

    // Function to check if content has changed
    function hasChanged(callback) {
        if (_isLoaded) {
            webView.runJavaScript("window.quillEditor.hasContentChanged();", function (result) {
                if (callback) {
                    callback(result);
                }
            });
        } else if (callback) {
            callback(false);
        }
    }

    // Watch for property changes
    onTextChanged: {
        setText(text);
    }

    onReadOnlyChanged: {
        setReadOnly(readOnly);
    }

    onDarkModeChanged: {
        // Reload the editor with new theme when dark mode changes
        if (_isLoaded) {
            webView.reload();
        }
    }

    // Periodic content sync (alternative approach for text changes)
    // Timer {
    //     id: contentSyncTimer
    //     interval: 500 // Check every 500ms
    //     running: _isLoaded && !readOnly
    //     repeat: true

    //     onTriggered: {
    //         getText(function (content) {
    //             if (content !== richTextEditor.text) {
    //                 richTextEditor.text = content;
    //                 richTextEditor.contentChanged(content);
    //             }
    //         });
    //     }
    // }

    // Loading indicator
    ActivityIndicator {
        id: loadingIndicator
        anchors.centerIn: parent
        running: !_isLoaded
        visible: running
    }

    // Error handling
    Rectangle {
        id: errorMessage
        anchors.fill: parent
        color: "#f5f5f5"
        visible: webView.loading === false && webView.url.toString() === ""

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
                    webView.reload();
                }
            }
        }
    }
}
