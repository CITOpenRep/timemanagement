import QtQuick 2.7
import Lomiri.Components 1.3
import "../models/global.js" as Global
import "components"

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

        // Rich Text Editor - shown when useRichText is true
        RichTextEditor {
            id: editor
            visible: useRichText
            text: Global.description_temporary_holder
            readOnly: isReadOnly
            width: parent.width - units.gu(4)
            height: (parent.height - header.height) - (saveButton.visible ? saveButton.height + units.gu(4) : 0)

            onContentChanged: {
                Global.description_temporary_holder = newText;
                
                // Track changes in parent form's draft handler
                if (parentDraftHandler && !isReadOnly) {
                    parentDraftHandler.markFieldChanged("description", newText);
                }
            }

            onContentLoaded: {
                // Set initial content once the editor is loaded
                if (Global.description_temporary_holder) {
                    editor.text = Global.description_temporary_holder;
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
                    Global.description_temporary_holder = simpleEditor.text;
                    
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

    // Handle page visibility changes to ensure content is saved
    onVisibleChanged: {
        if (!visible && !isReadOnly) {
            // Page is being hidden, ensure we save the current content
            if (useRichText && editor) {
                // Force immediate sync before page closes
                editor.syncContent();
                // Also get content as backup
                editor.getText(function (content) {
                    Global.description_temporary_holder = content;
                    // Save draft when leaving ReadMore page
                    if (parentDraftHandler) {
                        parentDraftHandler.markFieldChanged("description", content);
                        parentDraftHandler.saveDraft();
                    }
                });
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
                editor.syncContent();
            } else if (!useRichText && simpleEditor) {
                Global.description_temporary_holder = simpleEditor.text;
            }
            
            // Save draft one last time before page is destroyed
            if (parentDraftHandler) {
                parentDraftHandler.markFieldChanged("description", Global.description_temporary_holder);
                parentDraftHandler.saveDraft();
            }
        }
    }
}
