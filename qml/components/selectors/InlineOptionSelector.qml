import QtQuick 2.7
import QtQuick.Controls 2.2
import Lomiri.Components 1.3
import "../../../models/constants.js" as AppConst
import ".."

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
    property real collapsedHeight: units.gu(4)
    property real expandedHeight: units.gu(25)
    property real maxExpandedHeight: units.gu(40)
    property bool collapsed: true
    property int visibleItemCount: 5  // Number of items visible when expanded
    z: !collapsed ? 9999 : 1

    readonly property bool isDarkTheme: (typeof Theme !== "undefined" && Theme.name === "Ubuntu.Components.Themes.SuruDark") || (typeof theme !== "undefined" && theme.name === "Ubuntu.Components.Themes.SuruDark")

    // Styling properties (callers can assign custom colors or rely on theme defaults)
    property var bgColor: undefined
    property var dropdownBgColor: undefined
    property var disabledBgColor: undefined
    property color selectedColor: AppConst.Colors.Primary || "#3498db"
    property var borderColor: undefined
    property var textColor: undefined
    property var mutedTextColor: undefined
    property var hoverColor: undefined
    property var dropdownTextColor: undefined
    property var dropdownMutedTextColor: undefined
    property var dropdownBorderColor: undefined
    property var dividerColor: undefined
    property var selectedTickColor: undefined

    // Effective resolved colors
    readonly property color effectiveBgColor: bgColor !== undefined ? bgColor : (isDarkTheme ? "#1b1b1f" : "#ffffff")
    readonly property color effectiveDropdownBgColor: dropdownBgColor !== undefined ? dropdownBgColor : (isDarkTheme ? "#1b1b1f" : "#ffffff")
    readonly property color effectiveDisabledBgColor: disabledBgColor !== undefined ? disabledBgColor : (isDarkTheme ? "#2a2a2a" : "#eeeeee")
    readonly property color effectiveBorderColor: borderColor !== undefined ? borderColor : (isDarkTheme ? "#3a3a3f" : "#e0e0e0")
    readonly property color effectiveTextColor: textColor !== undefined ? textColor : (isDarkTheme ? "#ebebef" : "#333333")
    readonly property color effectiveMutedTextColor: mutedTextColor !== undefined ? mutedTextColor : (isDarkTheme ? "#9a9aa2" : "#888888")
    readonly property color effectiveHoverColor: hoverColor !== undefined ? hoverColor : (isDarkTheme ? "#2b2b31" : "#f5f5f5")
    readonly property color effectiveDropdownTextColor: dropdownTextColor !== undefined ? dropdownTextColor : (isDarkTheme ? "#ebebef" : "#333333")
    readonly property color effectiveDropdownMutedTextColor: dropdownMutedTextColor !== undefined ? dropdownMutedTextColor : (isDarkTheme ? "#9a9aa2" : "#888888")
    readonly property color effectiveDropdownBorderColor: dropdownBorderColor !== undefined ? dropdownBorderColor : (isDarkTheme ? "#3a3a3f" : "#e0e0e0")
    readonly property color effectiveDividerColor: dividerColor !== undefined ? dividerColor : (isDarkTheme ? "#3a3a3f" : "#e0e0e0")
    readonly property color effectiveSelectedTickColor: (selectedTickColor !== undefined && selectedTickColor != "transparent" && selectedTickColor != "#00000000") ? selectedTickColor : "white"

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

        // If selectedId is already set, resolve its name from the new data
        if (selectedId !== -1) {
            for (var j = 0; j < modelData.length; j++) {
                if (modelData[j].id === selectedId) {
                    selectedName = modelData[j].name;
                    break;
                }
            }
        }
    }

    // Resolve selectedName when selectedId is assigned and modelData is already loaded
    onSelectedIdChanged: {
        if (selectedId !== -1 && modelData && modelData.length > 0) {
            for (var i = 0; i < modelData.length; i++) {
                if (modelData[i].id === selectedId) {
                    selectedName = modelData[i].name;
                    break;
                }
            }
        }
    }

    Behavior on height {
        NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
    }

    Rectangle {
        id: container
        anchors.fill: parent
        radius: units.gu(1)
        color: (enabledState && !readOnly) ? (collapsed ? effectiveBgColor : effectiveDropdownBgColor) : effectiveDisabledBgColor
        border.color: collapsed ? effectiveBorderColor : effectiveDropdownBorderColor
        border.width: (collapsed && (effectiveBorderColor == "transparent" || effectiveBorderColor == "#00000000")) ? 0 : 1
        clip: true

        Column {
            anchors.fill: parent
            spacing: 0

            // Header row - always visible
            Rectangle {
                id: headerRow
                width: parent.width
                height: units.gu(4)
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
                        color: collapsed ? effectiveTextColor : effectiveDropdownTextColor
                        font.pixelSize: units.gu(1.6)
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    // Selected value display
                    Text {
                        width: parent.width * 0.5
                        height: parent.height
                        text: selectedName || i18n.dtr("ubtms", "Tap to select")
                        color: collapsed ? (selectedName ? effectiveTextColor : effectiveMutedTextColor) : (selectedName ? effectiveDropdownTextColor : effectiveDropdownMutedTextColor)
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
                        color: collapsed ? effectiveTextColor : effectiveDropdownTextColor
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
                color: effectiveDividerColor
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
                        if (model.itemId === selectedId) {
                            return Qt.rgba(selectedColor.r, selectedColor.g, selectedColor.b, 0.15);
                        }
                        if (delegateMouseArea.containsMouse) return effectiveHoverColor;
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
                            border.color: model.itemId === selectedId ? selectedColor : effectiveDividerColor
                            border.width: 1

                            Icon {
                                anchors.centerIn: parent
                                width: units.gu(1.2)
                                height: units.gu(1.2)
                                name: "tick"
                                color: effectiveSelectedTickColor
                                visible: model.itemId === selectedId
                            }
                        }

                        // Option text
                        Text {
                            width: parent.width - units.gu(4)
                            height: parent.height
                            text: model.name
                            color: collapsed ? effectiveTextColor : (model.itemId === selectedId ? selectedColor : effectiveDropdownTextColor)
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

                    // Bottom border (Divider between options)
                    Rectangle {
                        width: parent.width
                        height: 1
                        anchors.bottom: parent.bottom
                        color: effectiveDividerColor
                        opacity: 0.6
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
