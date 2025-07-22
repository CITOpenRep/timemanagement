import QtQuick 2.7
import Lomiri.Components 1.3

Page {
    id: readmepage
    anchors.fill: parent

    property string fullText: ""
    property bool isReadOnly: true

    header: PageHeader {
        title: "Rich Text Editor"
    }

    Column {
        anchors.fill: parent
        spacing: units.gu(1)
        padding: units.gu(2)

        TextArea {
            id: editor
            text: fullText
            readOnly: isReadOnly
            textFormat: Text.RichText
            wrapMode: TextArea.Wrap
            selectByMouse: true
            width: parent.width - units.gu(4)
            height: parent.height - (saveButton.visible ? saveButton.height + units.gu(4) : 0)
            clip: true
        }

        Button {
            id: saveButton
            visible: !isReadOnly
            text: "Save"
            anchors.horizontalCenter: parent.horizontalCenter
            onClicked: {
                console.log("Edited text:", fullText)
                // Save logic here
            }
        }
    }
}
