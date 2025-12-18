import QtQuick 2.7
import QtQuick.Controls 2.2
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import "../../models/constants.js" as AppConst

/**
 * OptionSelectorPopover - Direct list selection without intermediate ComboBox
 * 
 * Shows a dialog with a scrollable list of options that users can select
 * directly with a single tap, eliminating the need for a ComboBox.
 */
Item {
    id: optionSelectorWrapper

    property string titleText: "Select Item"
    property var modelData: []
    property var callerItem: null

    signal selectionMade(int id, string name)

    Component {
        id: dialogComponent

        Dialog {
            id: optionDialog
            title: optionSelectorWrapper.titleText

            ListView {
                id: optionsList
                width: parent.width
                height: units.gu(40)
                clip: true
                
                model: ListModel {
                    id: optionsModel
                }

                delegate: ListItem {
                    height: units.gu(6)
                    
                    ListItemLayout {
                        title.text: model.name
                        title.elide: Text.ElideRight
                    }
                    
                    onClicked: {
                        optionSelectorWrapper.selectionMade(model.itemId, model.name);
                        PopupUtils.close(optionDialog);
                    }
                }
            }

            Button {
                text: i18n.dtr("ubtms", "Cancel")
                width: parent.width
                onClicked: PopupUtils.close(optionDialog)
            }

            Component.onCompleted: {
                optionsModel.clear();
                for (var i = 0; i < optionSelectorWrapper.modelData.length; i++) {
                    optionsModel.append({
                        itemId: optionSelectorWrapper.modelData[i].id,
                        name: optionSelectorWrapper.modelData[i].name
                    });
                }
            }
        }
    }

    function open(titleArg, modelDataArg, caller) {
        if (titleArg)
            titleText = titleArg;
        if (modelDataArg)
            modelData = modelDataArg;
        if (caller)
            callerItem = caller;
        
        PopupUtils.open(dialogComponent);
    }
}
