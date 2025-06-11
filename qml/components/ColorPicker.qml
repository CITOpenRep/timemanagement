import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1
import Lomiri.Components.Popups 1.3

Item {
    id: colorPopupWrapper
    width: 0
    height: 0

    // Public state
    property int selectedColorIndex: -1
    property string selectedColor: ""
    property var odooColors: ["#FFFFFF", "#EB6E67", "#F39C5A", "#F6C342", "#6CC1E1", "#854D76", "#ED8888", "#2C8397", "#49597C", "#DE3F7C", "#45C486", "#9B6CC3"]

    signal colorPicked(int colorIndex, string colorValue)

    Component {
        id: dialogComponent

        Dialog {
            id: colorDialog
            title: "Select Color"
            modal: true
            focus: true
            anchors.centerIn: parent

            // Internal property passed from wrapper
            property int preselected: -1

            ColumnLayout {
                spacing: 10
                width: parent.width

                GridLayout {
                    id: colorGrid
                    columns: 3
                    Layout.alignment: Qt.AlignHCenter

                    Repeater {
                        model: colorPopupWrapper.odooColors.length
                        Rectangle {
                            width: 64
                            height: 64
                            color: colorPopupWrapper.odooColors[index]
                            border.color: Qt.darker(color, 1.3)
                            border.width: index === colorDialog.preselected ? 3 : 1
                            radius: 4

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    colorPopupWrapper.selectedColorIndex = index;
                                    colorPopupWrapper.selectedColor = colorPopupWrapper.odooColors[index];
                                    colorPopupWrapper.colorPicked(index, colorPopupWrapper.selectedColor);
                                    PopupUtils.close(colorDialog);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function open(preselectIndex) {
        if (preselectIndex !== undefined && preselectIndex >= 0)
            dialogComponent.createObject(null, {
                preselected: preselectIndex
            });
        else
            PopupUtils.open(dialogComponent);
    }
    function getColorByIndex(index) {
        if (index >= 0 && index < odooColors.length) {
            return odooColors[index];
        }
        return "#FFFFFF";  // default fallback
    }
}
