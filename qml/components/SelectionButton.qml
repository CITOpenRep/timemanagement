import QtQuick 2.7
import QtQuick.Controls 2.2
import Lomiri.Components 1.3
import "../../models/constants.js" as AppConst

/**
 * SelectionButton - Inline option selector wrapper
 * 
 * Uses InlineOptionSelector to display options directly on the page
 * without any popup dialog.
 */
Item {
    id: selectionButton
    width: parent.width
    height: inlineSelector.height

    // Public API
    property string selectorType: ""             // "Account", "Project", etc.
    property string labelText: "Label"
    property bool enabledState: true
    property bool readOnly: false
    property var modelData: []                   // Data to display in selector
    property int selectedId: -1
    signal selectionMade(int id, string name, string selectorType)

    // Styling properties (kept for compatibility)
    property color bgColor: enabledState ? AppConst.Colors.Button : AppConst.Colors.ButtonDisabled
    property color fgColor: AppConst.Colors.ButtonText
    property color hoverColor: AppConst.Colors.ButtonHover
    property int radius: units.gu(0.8)

    function update_label(text) {
        // Find and select item matching text (no signal emission)
        for (var i = 0; i < modelData.length; i++) {
            if (modelData[i].name === text) {
                inlineSelector.applyDeferredSelection(modelData[i].id, false);
                selectionButton.selectedId = modelData[i].id;
                return;
            }
        }
    }

    InlineOptionSelector {
        id: inlineSelector
        anchors.left: parent.left
        anchors.right: parent.right
        
        labelText: selectionButton.labelText
        selectorType: selectionButton.selectorType
        modelData: selectionButton.modelData
        enabledState: selectionButton.enabledState
        readOnly: selectionButton.readOnly
        
        onSelectionMade: {
            selectionButton.selectedId = id;
            selectionButton.selectionMade(id, name, selectorType);
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
        } else {
            enabledState = isEnabled;
        }
    }

    function applyDeferredSelection(selId, emitSignal) {
        // Default: don't emit signal during deferred selection to prevent loops
        var shouldEmit = (emitSignal === true);
        if (inlineSelector.applyDeferredSelection(selId, shouldEmit)) {
            selectionButton.selectedId = selId;
        }
    }
}
