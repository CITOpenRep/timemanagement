import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import Lomiri.Components 1.3

Item {
    id: treeSelector
    width: parent.width
    height: implicitHeight

    property var dataList: [] // raw flat list
    property var treeModel: ListModel {} // flattened tree with indentations as a proper ListModel
    property int selectedId: -1
    signal itemSelected(int id, string name)
    property string currentText: "No"
    property string labelText: "Label"

    function reload() {
        selectedId = -1; //reset index
        buildTreeModel();
    }

    function buildTreeModel() {
        treeModel.clear();

        var roots = dataList.filter(function (p) {
            return !p.parent_id;
        });
        var children = dataList.filter(function (p) {
            return p.parent_id;
        });

        function addChildren(parent, level) {
            children.forEach(function (child) {
                if (child.parent_id === parent.id) {
                    treeModel.append({
                        id: child.id,
                        label: "  ".repeat(level) + "- " + child.name,
                        name: child.name,
                        parent_id: parent.id
                    });
                    addChildren(child, level + 1);
                }
            });
        }

        roots.forEach(function (root) {
            treeModel.append({
                id: root.id,
                label: root.name,
                name: root.name,
                parent_id: null
            });
            addChildren(root, 1);
        });
    }

    Column {
        width: parent.width
        spacing: units.gu(1)

        Row {
            width: parent.width
            spacing: units.gu(-1)
            height: units.gu(5)

            TSLabel {
                text: treeSelector.labelText
                verticalAlignment: Text.AlignVCenter
                width: parent.width * 0.3  // Adjust as needed
                anchors.verticalCenter: parent.verticalCenter
            }

            TSButton {
                id: triggerButton
                text: treeSelector.currentText || "Select Item"
                width: parent.width * 0.7  // Adjust as needed
                height: parent.height
                onClicked: {
                    if (treeModel.count > 0) {
                        popup.open();
                    } else {
                        console.log("No items to select");
                    }
                }
            }
        }

        Popup {
            id: popup
            modal: true
            width: treeSelector.width
            x: triggerButton.x
            y: triggerButton.y + triggerButton.height
            background: Rectangle {
                color: "transparent"
               
                radius: units.gu(0.8)
            }
            height: units.gu(38)

           ListView {
                anchors.fill: parent
                model: treeModel
                clip: true
                interactive: true
                boundsBehavior: Flickable.DragAndOvershootBounds
                delegate: ItemDelegate {
                    width: triggerButton.width 
                    height: units.gu(5)
                    hoverEnabled: true
                    background: Rectangle {
                        color: (hovered ? "skyblue" : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#444" : "#e2e0da"))
                        radius: units.gu(0.2)
                        border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#d3d1d1" : "#999"
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            treeSelector.selectedId = model.id;
                            treeSelector.currentText = model.name || "";
                            treeSelector.itemSelected(model.id, model.name || "");
                            popup.close();
                        }

                        Text {
                            text: model.label || ""
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: units.gu(1.2)
                            font.pixelSize: units.gu(1.4)
                            color : theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                         //   elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: buildTreeModel()
}

/*
  Example to use
TreeSelector {
   id: selector
   width: parent.width - units.gu(2)
   height: units.gu(29)

   dataList: [
           { id: 1, name: "Movies", parent_id: null },
           { id: 2, name: "Hollywood", parent_id: 1 },
           { id: 3, name: "Design", parent_id: null },
           { id: 4, name: "UI Overhaul", parent_id: 3 },
           { id: 5, name: "1Movies", parent_id: null },
           { id: 6, name: "2Hollywood", parent_id: 1 },
           { id: 7, name: "3Design", parent_id: null },
           { id: 8, name: "4UI Overhaul", parent_id: 3 }
       ]
       onItemSelected: (id, name) => console.log("Selected →", id, name)
}
*/
