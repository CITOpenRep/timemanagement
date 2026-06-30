import QtQuick 2.7
import Lomiri.Components 1.3
import QtQuick.LocalStorage 2.7 as Sql
import "../../../models/global.js" as Global
import "../system"

Page {
    id: readmepage
    anchors.fill: parent
    property var layout
    property var previousPage

    property bool useRichText: true

    property string textkey: ""
    property string text: ""
    property bool isReadOnly: true
    
    // Reference to parent form's draft handler (for tracking changes)
    property var parentDraftHandler: null
    property var parentFormPage: null
    property var parentSaveHandler: null

    // Live sync: track the last content we wrote/read from Global to avoid feedback loops
    property string _lastKnownHolder: ""
    property bool _parentSaveCommitted: false

    property bool listening: false
    property bool processing: false
    property bool ignoreNextResult: false
    property string textBeforeRecording: ""
    property bool isVoiceInputEnabled: true
    property string _partialRecognizedText: ""
    property string _currentVoiceStatus: ""

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

    Connections {
        target: mainView.backend_bridge
        onMessageReceived: {
            if (!readmepage.listening && !readmepage.processing) return;

            if (data.event === "voice_recognition_partial") {
                var partialText = data.payload
                if (partialText) {
                    readmepage._currentVoiceStatus = i18n.dtr("ubtms", "Listening...");
                    
                    var prefix = "";
                    if (readmepage.textBeforeRecording.length > 0) {
                        var lastChar = readmepage.textBeforeRecording.charAt(readmepage.textBeforeRecording.length - 1);
                        if (lastChar !== '\n' && lastChar !== '\r') {
                            prefix = "\n";
                        }
                    }
                    simpleEditor.text = readmepage.textBeforeRecording + prefix + partialText;
                    cursorTimer.start();
                }
            } else if (data.event === "voice_recognition_status") {
                var statusText = data.payload;
                if (statusText) {
                    readmepage._currentVoiceStatus = statusText;
                }
            } else if (data.event === "voice_recognition_result") {
                if (readmepage.ignoreNextResult) {
                    readmepage.ignoreNextResult = false;
                    readmepage.listening = false;
                    readmepage.processing = false;
                    readmepage._currentVoiceStatus = "";
                    readmepage.textBeforeRecording = simpleEditor.text;
                    cursorTimer.start();
                    return;
                }
                
                readmepage.listening = false
                readmepage.processing = false
                var recognizedText = data.payload
                readmepage._currentVoiceStatus = "";
                
                if (recognizedText) {
                    var prefix = "";
                    if (readmepage.textBeforeRecording.length > 0) {
                        var lastChar = readmepage.textBeforeRecording.charAt(readmepage.textBeforeRecording.length - 1);
                        if (lastChar !== '\n' && lastChar !== '\r') {
                            prefix = "\n";
                        }
                    }
                    simpleEditor.text = readmepage.textBeforeRecording + prefix + recognizedText;
                    readmepage.textBeforeRecording = simpleEditor.text;
                    cursorTimer.start();
                }
            } else if (data.event === "voice_recognition_error") {
                readmepage.listening = false
                readmepage.processing = false
                readmepage._currentVoiceStatus = "";
                readmepage.textBeforeRecording = simpleEditor.text;
                if (data.payload && (data.payload.indexOf("Please download one") !== -1 || data.payload.indexOf("No language model") !== -1)) {
                    if (typeof notifPopup !== "undefined") notifPopup.open(i18n.dtr("ubtms", "Action Required"), data.payload, "warning");
                } else {
                    if (typeof notifPopup !== "undefined") notifPopup.open(i18n.dtr("ubtms", "Error"), data.payload ? data.payload : "Unknown error", "error");
                }
                cursorTimer.start()
            }
        }
    }

    Timer {
        id: cursorTimer
        interval: 100
        repeat: false
        onTriggered: {
            if (simpleEditor) {
                simpleEditor.cursorPosition = simpleEditor.length;
                if (simpleEditor.flickableItem) {
                    simpleEditor.flickableItem.contentY = Math.max(0, simpleEditor.flickableItem.contentHeight - simpleEditor.flickableItem.height);
                } else if (simpleEditor.flickable) {
                    simpleEditor.flickable.contentY = Math.max(0, simpleEditor.flickable.contentHeight - simpleEditor.flickable.height);
                }
            }
        }
    }

    header: PageHeader {
        id: header
        title: i18n.dtr("ubtms","Description")

        StyleHints {

            foregroundColor: "white"

            backgroundColor: LomiriColors.orange
            dividerColor: LomiriColors.slate
        }

        trailingActionBar.numberOfSlots: 3
        trailingActionBar.actions: [
            Action {
                visible: !isReadOnly
                iconName: "tick"
                onTriggered: {
                    saveAndClose()
                }
            },
            Action {
                visible: !isReadOnly && readmepage.isVoiceInputEnabled && !useRichText
                iconName: "microphone"
                text: readmepage.listening ? i18n.dtr("ubtms", "Stop Recording") : i18n.dtr("ubtms", "Start Recording")
                onTriggered: {
                    if (readmepage.listening) {
                        readmepage.listening = false
                        readmepage.processing = true
                        readmepage._currentVoiceStatus = i18n.dtr("ubtms", "Processing...");
                        
                        backend_bridge.call("backend.stop_voice_recognition", [])
                        return;
                    }
                    if (readmepage.processing) return;
                    
                    readmepage.textBeforeRecording = simpleEditor.text
                    readmepage._partialRecognizedText = "";
                    readmepage._currentVoiceStatus = i18n.dtr("ubtms", "Starting...");
                    
                    readmepage.listening = true
                    readmepage.processing = false
                    backend_bridge.call("backend.run_voice_recognition", [])
                }
            },
            Action {
                visible: !isReadOnly && useRichText && (!readmepage.listening && !readmepage.processing)
                iconName: editor.toolbarExpanded ? "view-collapse" : "view-expand"
                text: editor.toolbarExpanded ? i18n.dtr("ubtms", "Hide Toolbar") : i18n.dtr("ubtms", "Show Toolbar")
                onTriggered: {
                    editor.toolbarExpanded = !editor.toolbarExpanded
                }
            }
        ]
    }

    function commitContent(content) {
        Global.description_temporary_holder = content || "";
        var saveWasExpected = parentFormPage || parentSaveHandler || Global.richTextSaveCallback;

        if (parentDraftHandler && !isReadOnly) {
            parentDraftHandler.markFieldChanged("description", Global.description_temporary_holder);
        }

        if (parentFormPage && parentFormPage.saveProjectDescriptionFromEditor) {
            try {
                var pageSaveSucceeded = parentFormPage.saveProjectDescriptionFromEditor(Global.description_temporary_holder);
                if (pageSaveSucceeded) {
                    _parentSaveCommitted = true;
                    Global.richTextSaveCallback = null;
                }
                return pageSaveSucceeded;
            } catch (e) {
                console.warn("[ReadMorePage] parentFormPage save failed:", e);
            }
        }

        if (parentSaveHandler && typeof parentSaveHandler === "function") {
            try {
                var saveSucceeded = parentSaveHandler(Global.description_temporary_holder);
                if (saveSucceeded) {
                    _parentSaveCommitted = true;
                    Global.richTextSaveCallback = null;
                }
                return saveSucceeded;
            } catch (e) {
                console.warn("[ReadMorePage] parentSaveHandler save failed:", e);
            }
        }

        if (Global.richTextSaveCallback && typeof Global.richTextSaveCallback === "function") {
            try {
                var globalSaveSucceeded = Global.richTextSaveCallback(Global.description_temporary_holder);
                if (globalSaveSucceeded) {
                    _parentSaveCommitted = true;
                    Global.richTextSaveCallback = null;
                }
                return globalSaveSucceeded;
            } catch (e) {
                console.warn("[ReadMorePage] global rich-text save failed:", e);
            }
        }

        return !saveWasExpected;
    }

    function closePage() {
        pageStack.removePages(readmepage);
    }

    function saveAndClose() {
        // Auto-stop voice recognition if it's still running
        if (readmepage.listening || readmepage.processing) {
            readmepage.ignoreNextResult = true;
            readmepage.listening = false;
            readmepage.processing = false;
            readmepage._currentVoiceStatus = "";
            backend_bridge.call("backend.stop_voice_recognition", []);
        }
        
        if (useRichText) {
            // Finalize voice span in RichTextEditor if needed
            if (editor.editor && editor.editor.listening || editor.editor && editor.editor.processing) {
                editor.editor.stopAndFinalizeVoice();
            }
            editor.getText(function (content) {
                if (commitContent(content)) {
                    closePage();
                }
            });
        } else {
            // For plain text, textBeforeRecording is already updated
            readmepage.textBeforeRecording = simpleEditor.text;
            if (commitContent(simpleEditor.text)) {
                closePage();
            }
        }
    }

    Item {
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        // Rich Text Editor with Toolbar - shown when useRichText is true
        HtmlEditorContainer {
            id: editor
            visible: useRichText
            text: Global.description_temporary_holder
            readOnly: isReadOnly || readmepage.listening || readmepage.processing
            showToolbar: !isReadOnly && !readmepage.listening && !readmepage.processing
            anchors.fill: parent

            onContentChanged: {
             //   console.log("[ReadMorePage] onContentChanged - PUSHING to Global, length:", newText.length);
                Global.description_temporary_holder = newText;
                readmepage._lastKnownHolder = newText;
             //   console.log("[ReadMorePage] Updated _lastKnownHolder, length:", readmepage._lastKnownHolder.length);
                
                // Track changes in parent form's draft handler
                if (parentDraftHandler && !isReadOnly) {
                    parentDraftHandler.markFieldChanged("description", newText);
                }
            }

            onContentLoaded: {
                // Set initial content once the editor is loaded
              //  console.log("[ReadMorePage] onContentLoaded, holder full content:");
             //   console.log(Global.description_temporary_holder);
                if (Global.description_temporary_holder) {
                    editor.text = Global.description_temporary_holder;
                    readmepage._lastKnownHolder = Global.description_temporary_holder;
                }
            }
        }

        // Simple Text Area - shown when useRichText is false
        TextArea {
            id: simpleEditor
            visible: !useRichText
            text: Global.description_temporary_holder
            readOnly: isReadOnly || readmepage.listening || readmepage.processing
            textFormat: Text.PlainText
            font.pixelSize: units.gu(2)
            wrapMode: TextArea.Wrap
            selectByMouse: true
            anchors.fill: parent
            clip: true

            onTextChanged: {
                if (!readOnly) {
                   // console.log("[ReadMorePage] simpleEditor typing - PUSHING to Global, length:", simpleEditor.text.length);
                    Global.description_temporary_holder = simpleEditor.text;
                    readmepage._lastKnownHolder = simpleEditor.text;
                    
                    // Track changes in parent form's draft handler
                    if (parentDraftHandler) {
                        parentDraftHandler.markFieldChanged("description", simpleEditor.text);
                    }
                }
            }
        }

        Button {
            id: saveButton
            visible: false
            text: "Save"
            anchors.horizontalCenter: parent.horizontalCenter
            onClicked: {
                saveAndClose()
            }
        }
    }

    /**
     * Live sync timer — polls Global.description_temporary_holder every 300ms
     * to pick up changes pushed by RichTextPreview (user typing in the inline preview).
     * Skips changes that originated from this editor (tracked via _lastKnownHolder).
     */
    Timer {
        id: liveSyncTimer
        interval: 300
        repeat: true
        running: !isReadOnly
        onTriggered: {
            var holderContent = Global.description_temporary_holder;
            if (holderContent !== "" && holderContent !== readmepage._lastKnownHolder) {
               // console.log("[ReadMorePage] External change detected - PULLING from Global, length:", holderContent.length);
                readmepage._lastKnownHolder = holderContent;
                if (useRichText && editor) {
                    editor.setText(holderContent);
                } else if (!useRichText && simpleEditor) {
                    simpleEditor.text = holderContent;
                }
            }
        }
    }

    VoiceTimerWidget {
        id: voiceTimerWidget
        parent: readmepage
        
        isListening: readmepage.listening
        isProcessing: readmepage.processing
        partialText: "" // Don't show partial text in the widget anymore
        voiceStatus: readmepage._currentVoiceStatus
        
        onStopClicked: {
            readmepage.ignoreNextResult = true;
            readmepage.listening = false
            readmepage.processing = false
            readmepage.textBeforeRecording = simpleEditor.text;
            
            readmepage._currentVoiceStatus = "";
            
            backend_bridge.call("backend.stop_voice_recognition", [])
        }
    }

    // Handle page visibility changes to ensure content is saved
    onVisibleChanged: {
        if (!visible && !isReadOnly && !_parentSaveCommitted) {
            // Page is being hidden, ensure we save the current content
            if (useRichText && editor) {
                // Use syncContent which returns the cached text immediately
                // The text property is kept in sync via contentChanged events
                var currentContent = editor.syncContent();
              //  console.log("[ReadMorePage] onVisibleChanged - saving content length:", currentContent ? currentContent.length : 0);
                
                // Use the cached text property which is updated via contentChanged
                Global.description_temporary_holder = currentContent || editor.text || "";
                
                // Save draft when leaving ReadMore page
                if (parentDraftHandler) {
                    parentDraftHandler.markFieldChanged("description", Global.description_temporary_holder);
                    parentDraftHandler.saveDraft();
                }
            } else if (!useRichText && simpleEditor) {
                Global.description_temporary_holder = simpleEditor.text;
                // Save draft when leaving ReadMore page
                if (parentDraftHandler) {
                    parentDraftHandler.markFieldChanged("description", simpleEditor.text);
                    parentDraftHandler.saveDraft();
                }
            }
        }
        
        if (!visible && (listening || processing)) {
            console.log("[ReadMorePage] visibility changed: Stopping voice recognition...")
            mainView.backend_bridge.call("backend.stop_voice_recognition", [])
        }
    }

    Component.onCompleted: {
        checkVoiceInputEnabled();
        // Initialize tracking to avoid false external-change detection
        _lastKnownHolder = Global.description_temporary_holder || "";
        
        // Ensure the editors are properly initialized with the current content
        if (!useRichText && simpleEditor) {
            simpleEditor.text = Global.description_temporary_holder;
        } else if (useRichText && editor) {
            editor.text = Global.description_temporary_holder;
        }
    }

    Component.onDestruction: {
        // Save content when page is destroyed
        if (!isReadOnly && !_parentSaveCommitted) {
            if (useRichText && editor) {
                // Use the cached text property which is kept in sync via contentChanged
                var currentContent = editor.getFormattedText();
               // console.log("[ReadMorePage] onDestruction - saving content length:", currentContent ? currentContent.length : 0);
                Global.description_temporary_holder = currentContent;
            } else if (!useRichText && simpleEditor) {
                Global.description_temporary_holder = simpleEditor.text;
            }
            
            // Save draft one last time before page is destroyed
            if (parentDraftHandler && Global.description_temporary_holder) {
                parentDraftHandler.markFieldChanged("description", Global.description_temporary_holder);
                parentDraftHandler.saveDraft();
            }
        }
        
        if (listening || processing) {
            console.log("[ReadMorePage] destruction: Stopping voice recognition...")
            mainView.backend_bridge.call("backend.stop_voice_recognition", [])
        }
    }
}
