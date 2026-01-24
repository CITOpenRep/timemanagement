import QtQuick 2.7
import QtQuick.Controls 2.2
import Lomiri.Components 1.3
import "../../models/constants.js" as AppConst

/**
 * InlineOptionSelector - Displays options directly on the page without popup
 * 
 * A resizable component that shows a scrollable list of options inline.
 * Users can tap to select an option directly.
 */
Item {
    id: inlineSelector
    width: parent.width
    height: collapsed ? collapsedHeight : expandedHeight

    // Public API
    property string labelText: "Select"
    property string selectorType: ""
    property var modelData: []
    property int selectedId: -1
    property string selectedName: ""
    property bool enabledState: true
    property bool readOnly: false

    // Layout properties
    property real collapsedHeight: units.gu(5)
    property real expandedHeight: units.gu(25)
    property real maxExpandedHeight: units.gu(40)
    property bool collapsed: true
    property int visibleItemCount: 5  // Number of items visible when expanded

    // Styling
    property color bgColor: AppConst.Colors.CardBackground || "#ffffff"
    property color selectedColor: AppConst.Colors.Primary || "#3498db"
    property color borderColor: AppConst.Colors.Border || "#e0e0e0"
    property color textColor: AppConst.Colors.Text || "#333333"
    property color hoverColor: AppConst.Colors.ButtonHover || "#f5f5f5"

    signal selectionMade(int id, string name, string selectorType)

    // Internal model
    ListModel {
        id: optionsModel
    }

    // Update model when modelData changes
    onModelDataChanged: {
        optionsModel.clear();
        for (var i = 0; i < modelData.length; i++) {
            optionsModel.append({
                itemId: modelData[i].id,
                name: modelData[i].name
            });
        }
        // Auto-adjust expanded height based on item count
        var calculatedHeight = Math.min(modelData.length * units.gu(5) + units.gu(6), maxExpandedHeight);
        expandedHeight = Math.max(calculatedHeight, units.gu(15));
    }

    Behavior on height {
        NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
    }

    Rectangle {
        id: container
        anchors.fill: parent
        radius: units.gu(1)
        color: bgColor
        border.color: borderColor
        border.width: 1
        clip: true

        Column {
            anchors.fill: parent
            spacing: 0

            // Header row - always visible
            Rectangle {
                id: headerRow
                width: parent.width
                height: units.gu(5)
                color: "transparent"

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: units.gu(1.5)
                    anchors.rightMargin: units.gu(1.5)
                    spacing: units.gu(1)

                    // Label
                    Text {
                        width: parent.width * 0.35
                        height: parent.height
                        text: labelText
                        color: textColor
                        font.pixelSize: units.gu(1.6)
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    // Selected value display
                    Text {
                        width: parent.width * 0.5
                        height: parent.height
                        text: selectedName || i18n.dtr("ubtms", "Tap to select")
                        color: selectedName ? textColor : "#888888"
                        font.pixelSize: units.gu(1.5)
                        font.bold: selectedName ? true : false
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideRight
                    }

                    // Expand/collapse icon
                    Icon {
                        width: units.gu(2.5)
                        height: units.gu(2.5)
                        anchors.verticalCenter: parent.verticalCenter
                        name: collapsed ? "go-down" : "go-up"
                        color: textColor
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: enabledState && !readOnly
                    onClicked: {
                        if (modelData.length > 0) {
                            collapsed = !collapsed;
                        }
                    }
                }
            }

            // Separator
            Rectangle {
                width: parent.width
                height: 1
                color: borderColor
                visible: !collapsed
            }

            // Options list - visible when expanded
            ListView {
                id: optionsList
                width: parent.width
                height: parent.height - headerRow.height - 1
                visible: !collapsed
                clip: true
                model: optionsModel
                
                ScrollBar.vertical: ScrollBar {
                    active: true
                    policy: ScrollBar.AsNeeded
                }

                delegate: Rectangle {
                    width: optionsList.width
                    height: units.gu(5)
                    color: {
                        if (model.itemId === selectedId) return selectedColor + "30";
                        if (delegateMouseArea.containsMouse) return hoverColor;
                        return "transparent";
                    }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: units.gu(1.5)
                        anchors.rightMargin: units.gu(1.5)
                        spacing: units.gu(1)

                        // Selection indicator
                        Rectangle {
                            width: units.gu(2)
                            height: units.gu(2)
                            radius: units.gu(1)
                            anchors.verticalCenter: parent.verticalCenter
                            color: model.itemId === selectedId ? selectedColor : "transparent"
                            border.color: model.itemId === selectedId ? selectedColor : borderColor
                            border.width: 1

                            Icon {
                                anchors.centerIn: parent
                                width: units.gu(1.2)
                                height: units.gu(1.2)
                                name: "tick"
                                color: "white"
                                visible: model.itemId === selectedId
                            }
                        }

                        // Option text
                        Text {
                            width: parent.width - units.gu(4)
                            height: parent.height
                            text: model.name
                            color: textColor
                            font.pixelSize: units.gu(1.5)
                            font.bold: model.itemId === selectedId
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: delegateMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: enabledState && !readOnly
                        onClicked: {
                            selectedId = model.itemId;
                            selectedName = model.name;
                            inlineSelector.selectionMade(model.itemId, model.name, selectorType);
                            collapsed = true;
                        }
                    }

                    // Bottom border
                    Rectangle {
                        width: parent.width
                        height: 1
                        anchors.bottom: parent.bottom
                        color: borderColor
                        opacity: 0.5
                    }
                }
            }
        }
    }

    // Public functions
    function setData(dataArray) {
        modelData = dataArray;
    }

    function setEnabled(isEnabled) {
        if (readOnly) {
            enabledState = false;
        } else {
            enabledState = isEnabled;
        }
    }

    function applyDeferredSelection(id, emitSignal) {
        if (!modelData || modelData.length === 0) {
            return false;
        }

        for (var i = 0; i < modelData.length; i++) {
            if (modelData[i].id === id) {
                selectedId = id;
                selectedName = modelData[i].name;
                // Only emit signal if explicitly requested (default: false)
                if (emitSignal === true) {
                    selectionMade(id, modelData[i].name, selectorType);
                }
                return true;
            }
        }
        return false;
    }

    function expand() {
        collapsed = false;
    }

    function collapse() {
        collapsed = true;
    }

    function clear() {
        selectedId = -1;
        selectedName = "";
    }
}
