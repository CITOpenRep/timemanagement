import QtQuick 2.7
import QtQuick.Controls 2.2
import Lomiri.Components 1.3

Item {
    id: selectionButton
    width: parent.width
    height: units.gu(6)

    // Public API
    property string selectorType: ""             // "Account", "Project", etc.
    property string labelText: "Label"
    property bool enabledState: true
    property var modelData: []                   // Data to display in dialog
    property int selectedId: -1
    signal selectionMade(int id, string name, string selectorType)

    // Internal DialogComboSelector
    DialogComboSelector {
        id: comboSelectorDialog
        width: units.gu(80)
        height: units.gu(10)

        onSelectionMade: {
            console.log("[SelectionButton] Selected:", id, name, "for", selectorType);
            selectionButton.selectionMade(id, name, selectorType);
            selectionButton.selectedId = id;
            entity_btn.text = name;
        }
    }

    Row {
        anchors.fill: parent
        spacing: units.gu(1)

        TSLabel {
            text: labelText
            width: parent.width * 0.45
            height: units.gu(5)
            verticalAlignment: Text.AlignVCenter
        }

        Button {
            id: entity_btn
            text: "Select"
            width: parent.width * 0.45
            height: units.gu(5)
            enabled: enabledState

            onClicked: {
                if (modelData.length === 0) {
                    console.log("[SelectionButton] No data set for", selectorType);
                    return;
                }
                comboSelectorDialog.open(labelText, modelData);
            }
        }
    }

    // API for parent to control
    function setData(dataArray) {
        modelData = dataArray;
    }

    function setEnabled(isEnabled) {
        enabledState = isEnabled;
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
