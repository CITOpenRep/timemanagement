import QtQuick 2.7
import Lomiri.Components 1.3
import QtWebEngine 1.5

Item {
    id: richTextEditor

    // Public properties
    property string text: ""
    property bool readOnly: false
    property int fontSize: 16
    property string placeholder: "Start typing..."

    // Signals
    signal contentChanged(string newText)
    signal contentLoaded

    // Private properties
    property bool _isLoaded: false
    property string _pendingText: ""

    WebEngineView {
        id: webView
        anchors.fill: parent

        // Load the Quill.js HTML file
        url: Qt.resolvedUrl("quill-editor.html") + (readOnly ? "?readonly=true" : "")

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

        // Enable JavaScript
        settings.javascriptEnabled: true
    }

    // Function to set text content
    function setText(htmlText) {
        if (_isLoaded) {
            webView.runJavaScript("window.quillEditor.setContent('" + htmlText.replace(/'/g, "\\'").replace(/\n/g, "\\n") + "');");
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
