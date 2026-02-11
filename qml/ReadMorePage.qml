import QtQuick 2.7
import Lomiri.Components 1.3
import "../models/global.js" as Global
import "components"
import "components/richtext"

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

    // Live sync: track the last content we wrote/read from Global to avoid feedback loops
    property string _lastKnownHolder: ""

    header: PageHeader {
        id: header
        title: i18n.dtr("ubtms","Description")

        StyleHints {

            foregroundColor: "white"

            backgroundColor: LomiriColors.orange
            dividerColor: LomiriColors.slate
        }

        trailingActionBar.actions: [
            Action {
                visible: !isReadOnly
                iconName: "tick"
                onTriggered: {
                    if (useRichText) {
                        editor.getText(function (content) {
                            Global.description_temporary_holder = content;
                            pageStack.removePages(readmepage);
                        });
                    } else {
                        Global.description_temporary_holder = simpleEditor.text;
                        pageStack.removePages(readmepage);
                    }
                }
            }
        ]
    }

    Column {
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: units.gu(1)
        padding: units.gu(2)

        // Rich Text Editor with Toolbar - shown when useRichText is true
        HtmlEditorContainer {
            id: editor
            visible: useRichText
            text: Global.description_temporary_holder
            readOnly: isReadOnly
            showToolbar: !isReadOnly
            width: parent.width - units.gu(4)
            height: (parent.height - header.height) - (saveButton.visible ? saveButton.height + units.gu(4) : 0)

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
            readOnly: isReadOnly
            textFormat: Text.PlainText
            font.pixelSize: units.gu(2)
            wrapMode: TextArea.Wrap
            selectByMouse: true
            width: parent.width - units.gu(4)
            height: (parent.height - header.height) - (saveButton.visible ? saveButton.height + units.gu(4) : 0)
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
                if (useRichText) {
                    // Get the current content from the rich text editor
                    editor.getText(function (content) {
                        Global.description_temporary_holder = content;
                        pageStack.removePages(readmepage);
                    });
                } else {
                    // Get the current content from the simple text area
                    Global.description_temporary_holder = simpleEditor.text;
                    pageStack.removePages(readmepage);
                }
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

    // Handle page visibility changes to ensure content is saved
    onVisibleChanged: {
        if (!visible && !isReadOnly) {
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
    }

    Component.onCompleted: {
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
        if (!isReadOnly) {
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
    }
}
