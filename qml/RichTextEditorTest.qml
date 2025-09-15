import QtQuick 2.7
import Lomiri.Components 1.3
import "components"

Page {
    id: testPage
    anchors.fill: parent

    header: PageHeader {
        title: "Rich Text Editor Test"
        StyleHints {
            foregroundColor: "white"
            backgroundColor: LomiriColors.orange
        }
    }

    Column {
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: units.gu(1)
        padding: units.gu(2)

        Label {
            text: "This is a test page for the Quill.js Rich Text Editor"
            fontSize: "large"
            wrapMode: Text.WordWrap
            width: parent.width
        }

        RichTextEditor {
            id: richEditor
            width: parent.width
            height: units.gu(30)
            readOnly: false
            text: "<h2>Welcome to the Rich Text Editor!</h2><p>You can format text with <strong>bold</strong>, <em>italic</em>, and <u>underline</u>.</p><ul><li>Create bullet lists</li><li>Add <a href='#'>links</a></li><li>And much more!</li></ul>"

            onContentChanged: {
                console.log("Text changed:", newText);
            }

            onContentLoaded: {
                console.log("Rich text editor loaded successfully");
            }
        }

        Row {
            spacing: units.gu(1)
            anchors.horizontalCenter: parent.horizontalCenter

            Button {
                text: "Get Content"
                onClicked: {
                    richEditor.getText(function (content) {
                        console.log("Current content:", content);
                    });
                }
            }

            Button {
                text: "Set Read Only"
                onClicked: {
                    richEditor.readOnly = !richEditor.readOnly;
                    this.text = richEditor.readOnly ? "Set Editable" : "Set Read Only";
                }
            }

            Button {
                text: "Clear Content"
                onClicked: {
                    richEditor.text = "";
                }
            }
        }
    }
}
