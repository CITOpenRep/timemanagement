import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import Lomiri.Components 1.3

Item {
    id: treeSelector
    width: parent.width
    height: implicitHeight

    property var projectList: [] // raw flat list
    property var treeModel: ListModel {} // flattened tree with indentations as a proper ListModel
    property int selectedId: -1
    signal projectSelected(int id, string name)

    function buildTreeModel() {
        treeModel.clear();

        var roots = projectList.filter(function(p) { return !p.parent_id; });
        var children = projectList.filter(function(p) { return p.parent_id; });

        function addChildren(parent, level) {
            children.forEach(function(child) {
                if (child.parent_id === parent.id) {
                    treeModel.append({
                        id: child.id,
                        label: "  ".repeat(level) + "└─ " + child.name,
                        name: child.name,
                        parent_id: parent.id
                    });
                    addChildren(child, level + 1);
                }
            });
        }

        roots.forEach(function(root) {
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

        Button {
            id: triggerButton
            property string selectedLabel: "Select Project"

            text: selectedLabel || "Select Project"
            width: parent.width
            height: units.gu(5)
            onClicked: popup.open()
        }

        Popup {
            id: popup
            modal: true
            width: treeSelector.width
            x: triggerButton.x
            y: triggerButton.y + triggerButton.height
            background: Rectangle { color: "#ffffff"; radius: 6 }
            height: 300

            ListView {
                anchors.fill: parent
                model: treeModel
                clip: true
                interactive: true
                boundsBehavior: Flickable.DragAndOvershootBounds
                delegate: Item {
                    width: parent.width
                    height: 40

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            treeSelector.selectedId = model.id
                            triggerButton.selectedLabel = model.label || ""
                            treeSelector.projectSelected(model.id, model.label || "")
                            popup.close()
                        }

                        Text {
                            text: model.label || ""
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            font.pixelSize: 16
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: buildTreeModel()
}
