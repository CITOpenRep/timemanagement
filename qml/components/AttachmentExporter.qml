import QtQuick 2.7
import QtQuick.Controls 2.2
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.Content 1.3

Item {
    id: pickerPopup
    width: 0; height: 0

    property string filePath: ""
    property string mime: ""
    property string suggestedName: ""
    property var   activeTransfer: null
    signal completed()
    signal aborted()
    signal error(string message)
    signal cancelled()

    function open(pathArg, mimeArg, nameArg) {
        filePath = pathArg || filePath
        mime = mimeArg || mime
        suggestedName = nameArg || suggestedName
        if (!filePath || !mime) { error("Missing filePath or mime"); return }
        PopupUtils.open(sheetComponent)
    }

    Component {
        id: sheetComponent

         DefaultSheet  {
            id: fullSheet
            // Fullscreen by default on phone; still set explicit fill:
            anchors.fill: parent
            focus: true

            ContentPeerPicker {
                id: picker
                anchors.fill: parent
                headerText: "Choose destination"
                contentType: ContentType.All
                handler: ContentHandler.Destination

                onPeerSelected: {
                    if (!pickerPopup.filePath || !pickerPopup.mime) {
                        pickerPopup.error("Nothing to export")
                        PopupUtils.close(fullSheet)
                        return
                    }
                    var req = peer.request()
                    req.selectionType = ContentTransfer.Single

                    var item = Qt.createQmlObject('import Lomiri.Content 1.3; ContentItem {}', picker)
                    item.url = "file://" + pickerPopup.filePath
                    item.name = pickerPopup.suggestedName && pickerPopup.suggestedName.length
                                ? pickerPopup.suggestedName : "attachment"

                    req.items = [ item ]
                    pickerPopup.activeTransfer = req
                    req.state = ContentTransfer.Charged
                }

                onCancelPressed: {
                    PopupUtils.close(fullSheet)
                    pickerPopup.cancelled()
                }
            }

            ContentTransferHint {
                anchors.fill: parent
                activeTransfer: pickerPopup.activeTransfer
                visible: !!pickerPopup.activeTransfer
            }

            Connections {
                target: pickerPopup.activeTransfer
                onStateChanged: {
                    if (!pickerPopup.activeTransfer) return
                    switch (pickerPopup.activeTransfer.state) {
                    case ContentTransfer.Completed:
                        PopupUtils.close(fullSheet)
                        pickerPopup.completed()
                        break
                    case ContentTransfer.Aborted:
                        PopupUtils.close(fullSheet)
                        pickerPopup.aborted()
                        break
                    case ContentTransfer.Error:
                        PopupUtils.close(fullSheet)
                        pickerPopup.error("Export failed")
                        break
                    }
                }
            }
        }
    }
}
