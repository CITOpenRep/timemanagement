import QtQuick 2.7
import QtQuick.Controls 2.2
import Lomiri.Components 1.3
import "../../models/constants.js" as AppConst

Item {
    id: selectionButton
    width: parent.width
    height: units.gu(6)

    // Public API
    property string selectorType: ""             // "Account", "Project", etc.
    property string labelText: "Label"
    property bool enabledState: true
    property bool readOnly: false
    property var modelData: []                   // Data to display in dialog
    property int selectedId: -1
    signal selectionMade(int id, string name, string selectorType)

    // Styling properties (reference TSButton)
    property color bgColor: enabledState ? AppConst.Colors.Button : AppConst.Colors.ButtonDisabled
    property color fgColor: AppConst.Colors.ButtonText
    property color hoverColor: AppConst.Colors.ButtonHover
    property int radius: units.gu(0.8)

    function update_label(text) {
        entity_btn_label.text = text;
    }

    // Internal DialogComboSelector
    DialogComboSelector {
        id: comboSelectorDialog
        width: units.gu(80)
        height: units.gu(10)

        onSelectionMade: {
            console.log("[SelectionButton] Selected:", id, name, "for", selectorType);
            selectionButton.selectionMade(id, name, selectorType);
            selectionButton.selectedId = id;
            entity_btn_label.text = name;
        }
    }

    Row {
        anchors.fill: parent
        spacing: units.gu(1)

        TSLabel {
            text: labelText
            width: parent.width * 0.4
            height: units.gu(5)
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
            elide: Text.ElideRight
            maximumLineCount: 2
        }

        // Custom styled button (reference TSButton)
        Item {
            id: entity_btn
            width: parent.width * 0.5
            height: units.gu(5)
            property alias text: entity_btn_label.text
            clip: true

            Rectangle {
                id: buttonRect
                anchors.fill: parent
                anchors.margins: units.gu(0.25)
                radius: selectionButton.radius
                color: mouseArea.containsMouse && selectionButton.enabledState ? selectionButton.hoverColor : selectionButton.bgColor
                opacity: selectionButton.enabledState ? 1.0 : 0.6
                clip: true

                Text {
                    id: entity_btn_label
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: units.gu(1.0)
                    anchors.rightMargin: units.gu(1.0)
                    color: selectionButton.fgColor
                    font.bold: false
                    font.pixelSize: units.gu(1.5)
                    text: "Select"
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.NoWrap
                    clip: true
                    maximumLineCount: 1
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: selectionButton.enabledState && !selectionButton.readOnly
                    onClicked: {
                        if (!selectionButton.enabledState || selectionButton.readOnly) {
                            return;
                        }
                        if (modelData.length === 0) {
                            console.log("[SelectionButton] No data set for", selectorType);
                            return;
                        }
                        comboSelectorDialog.open(labelText, modelData);
                    }
                }
            }
        }
    }

    // API for parent to control
    function setData(dataArray) {
        modelData = dataArray;
    }

    function setEnabled(isEnabled) {
        // Only enable if not in read-only mode
        if (readOnly) {
            enabledState = false;
            console.log("[SelectionButton] Ignoring setEnabled(" + isEnabled + ") because readOnly is true for", selectorType);
        } else {
            enabledState = isEnabled;
            console.log("[SelectionButton] setEnabled(" + isEnabled + ") for", selectorType);
        }
    }

    function applyDeferredSelection(selectedId) {
        if (!modelData || modelData.length === 0) {
            console.log("[SelectionButton] No model data loaded for applyDeferredSelection for", selectorType);
            return;
        }

        for (var i = 0; i < modelData.length; i++) {
            if (modelData[i].id === selectedId) {
                entity_btn.text = modelData[i].name;
                selectionButton.selectedId = selectedId;
                console.log("[SelectionButton] Deferred selection applied for", selectorType, ":", selectedId, modelData[i].name);
                return;
            }
        }

        console.log("[SelectionButton] ID", selectedId, "not found in modelData for", selectorType);
    }
}
