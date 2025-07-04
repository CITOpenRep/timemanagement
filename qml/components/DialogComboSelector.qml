import QtQuick 2.7
import QtQuick.Controls 2.2
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3

Item {
    id: dialogWrapper

    width: parent ? parent.width : units.gu(80)
    height: parent ? parent.height : units.gu(60)

    property string titleText: "Select Item"
    property var modelData: []

    signal selectionMade(int id, string name)

    Component {
        id: dialogComponent

        Dialog {
            id: dialog
            width: dialogWrapper.width
            title: dialogWrapper.titleText

            Column {
                width: dialogWrapper.width
                height: dialogWrapper.height
                spacing: units.gu(1)

                ComboBox {
                    id: comboBox
                    width: parent.width
                    height: parent.height * 0.4

                    model: ListModel {
                        id: comboModel
                    }
                    textRole: "text"

                    onActivated: {
                        if (currentIndex >= 0 && currentIndex < comboModel.count) {
                            var selectedItem = comboModel.get(currentIndex);
                            dialogWrapper.selectionMade(selectedItem.id, selectedItem.name);
                            PopupUtils.close(dialog);
                        }
                    }
                }

                Button {
                    id: cancelbutton
                    text: "Cancel"
                    width: parent.width
                    height: parent.height * 0.4
                    onClicked: PopupUtils.close(dialog)
                }
            }

            Component.onCompleted: loadModel()

            function loadModel() {
                comboModel.clear();
                for (var i = 0; i < dialogWrapper.modelData.length; i++) {
                    comboModel.append({
                        id: dialogWrapper.modelData[i].id,
                        name: dialogWrapper.modelData[i].name,
                        text: dialogWrapper.modelData[i].name
                    });
                }

                if (comboModel.count > 0) {
                    comboBox.currentIndex = 0; // Auto-select first item
                }
            }
        }
    }

    function open(titleArg, modelDataArg) {
        if (titleArg)
            titleText = titleArg;
        if (modelDataArg)
            modelData = modelDataArg;
        PopupUtils.open(dialogComponent);
    }
}
