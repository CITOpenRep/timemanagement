import QtQuick 2.7
import Lomiri.Components 1.3
import "../models/global.js" as Global

Page {
    id: readmepage
    anchors.fill: parent
    property var layout
    property var previousPage

    property bool useRichText: true

    property string textkey: ""
    property string text:""
    property bool isReadOnly: true

    header: PageHeader {
        id:header
        title: "Description"

          StyleHints {

            foregroundColor: "white"

            backgroundColor: LomiriColors.orange
            dividerColor: LomiriColors.slate
        }
    }

    Column {
        anchors.top:header.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right:parent.right
        spacing: units.gu(1)
        padding: units.gu(2)

        TextArea {
            id: editor
            text: Global.description_temporary_holder
            readOnly: isReadOnly
            textFormat: useRichText ? Text.RichText : Text.PlainText
            //wrapMode: TextArea.Wrap
            selectByMouse: true
            width: parent.width - units.gu(4)
            height: (parent.height -header.height) - (saveButton.visible ? saveButton.height + units.gu(4) : 0)
            clip: true
        }

        Button {
            id: saveButton
            visible: !isReadOnly
            text: "Save"
            anchors.horizontalCenter: parent.horizontalCenter
            onClicked: {
                Global.description_temporary_holder=editor.text
                pageStack.removePages(readmepage)
            }
        }
    }
    Component.onCompleted:
    {
        //console.log("Got full data")
        //console.log(Global.description_temporary_holder)
    }
}
