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
    property int pickerThreshold: 6
    property bool useModalPicker: true
    property var optionPickerOverride: null
    property int optionCount: 0
    property bool _inlineModelDirty: false
    property bool _ownsOpenPicker: false
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
    property var headerBgColor: undefined
    property var headerTextColor: undefined

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
    readonly property color effectiveHeaderBgColor: headerBgColor !== undefined ? headerBgColor : (collapsed ? effectiveBgColor : effectiveDropdownBgColor)
    readonly property color effectiveHeaderTextColor: headerTextColor !== undefined ? headerTextColor : (collapsed ? effectiveTextColor : effectiveDropdownTextColor)

    signal selectionMade(int id, string name, string selectorType)
    signal aboutToExpand()

    // Internal model (populated lazily when expanded inline)
    ListModel {
        id: optionsModel
    }

    function _getPicker() {
        if (optionPickerOverride) {
            return optionPickerOverride;
        }
        if (typeof mainView !== "undefined" && mainView && mainView.optionPicker) {
            return mainView.optionPicker;
        }
        return null;
    }

    function _populateInlineModel() {
        if (!_inlineModelDirty) {
            return;
        }
        optionsModel.clear();
        if (modelData && Array.isArray(modelData)) {
            for (var i = 0; i < modelData.length; i++) {
                var item = modelData[i];
                if (!item || item.name === undefined || item.name === null) {
                    continue;
                }
                var cleanName = String(item.name).trim();
                if (cleanName === "") {
                    continue;
                }
                optionsModel.append({
                    itemId: item.id !== undefined ? item.id : -1,
                    name: cleanName
                });
            }
        }
        _inlineModelDirty = false;
    }

    // Update metadata without populating inline ListModel while collapsed
    onModelDataChanged: {
        if (optionsModel.count > 0) {
            optionsModel.clear();
        }
        if (!modelData || !Array.isArray(modelData)) {
            optionCount = 0;
            _inlineModelDirty = false;
            expandedHeight = units.gu(15);
            return;
        }

        var validCount = 0;
        var resolvedName = "";
        var foundSelected = false;
        for (var i = 0; i < modelData.length; i++) {
            var item = modelData[i];
            if (!item || item.name === undefined || item.name === null) {
                continue;
            }
            var cleanName = String(item.name).trim();
            if (cleanName === "") {
                continue;
            }
            validCount++;
            if (selectedId !== -1 && !foundSelected && item.id === selectedId) {
                resolvedName = cleanName;
                foundSelected = true;
            }
        }

        optionCount = validCount;
        _inlineModelDirty = true;

        // Auto-adjust expanded height based on valid item count
        var calculatedHeight = Math.min(validCount * units.gu(5) + units.gu(6), maxExpandedHeight);
        expandedHeight = Math.max(calculatedHeight, units.gu(15));

        if (foundSelected) {
            selectedName = resolvedName;
        }

        if (!collapsed) {
            _populateInlineModel();
        }
    }

    // Resolve selectedName when selectedId is assigned and modelData is already loaded
    onSelectedIdChanged: {
        if (selectedId !== -1 && modelData && modelData.length > 0) {
            for (var i = 0; i < modelData.length; i++) {
                if (modelData[i] && modelData[i].id === selectedId) {
                    selectedName = modelData[i].name;
                    break;
                }
            }
        }
    }

    Behavior on height {
        NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
    }

    onCollapsedChanged: {
        if (!collapsed) {
            _populateInlineModel();
            Qt.callLater(_scrollToSelected);
        }
    }

    function _scrollToSelected() {
        _populateInlineModel();
        if (optionsModel.count === 0) {
            return;
        }
        if (selectedId === -1) {
            optionsList.positionViewAtBeginning();
            return;
        }
        for (var i = 0; i < optionsModel.count; i++) {
            if (optionsModel.get(i).itemId === selectedId) {
                optionsList.positionViewAtIndex(i, ListView.Center);
                return;
            }
        }
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
                color: collapsed ? "transparent" : effectiveHeaderBgColor

                Row {
                    id: headerLayoutRow
                    anchors.fill: parent
                    anchors.leftMargin: units.gu(1.5)
                    anchors.rightMargin: units.gu(1.5)
                    spacing: units.gu(1)

                    // Label
                    Text {
                        id: labelItem
                        width: Math.min(implicitWidth, parent.width * 0.4)
                        height: parent.height
                        text: labelText
                        color: collapsed ? effectiveTextColor : effectiveHeaderTextColor
                        font.pixelSize: units.gu(1.6)
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    // Selected value display
                    Text {
                        id: selectedItem
                        width: parent.width - labelItem.width - expandIcon.width - headerLayoutRow.spacing * 2
                        height: parent.height
                        text: selectedName || i18n.dtr("ubtms", "Tap to select")
                        color: collapsed ? (selectedName ? effectiveTextColor : effectiveMutedTextColor) : (selectedName ? effectiveHeaderTextColor : effectiveDropdownMutedTextColor)
                        font.pixelSize: units.gu(1.5)
                        font.bold: selectedName ? true : false
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideRight
                    }

                    // Expand/collapse icon
                    Icon {
                        id: expandIcon
                        width: units.gu(2.5)
                        height: units.gu(2.5)
                        anchors.verticalCenter: parent.verticalCenter
                        name: collapsed ? "go-down" : "go-up"
                        color: collapsed ? effectiveTextColor : effectiveHeaderTextColor
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: enabledState && !readOnly
                    onClicked: {
                        if (optionCount > 0) {
                            aboutToExpand();
                            if (useModalPicker && optionCount > pickerThreshold && _getPicker() !== null) {
                                openPicker();
                            } else {
                                collapsed = !collapsed;
                            }
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
                height: Math.max(0, parent.height - headerRow.height - 1)
                visible: !collapsed
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: optionsModel
                
                ScrollBar.vertical: ScrollBar {
                    active: true
                    policy: ScrollBar.AsNeeded
                }

                delegate: Rectangle {
                    width: optionsList.width
                    height: (model.name && String(model.name).trim().length > 0) ? units.gu(5) : 0
                    visible: (model.name && String(model.name).trim().length > 0)
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

        // Outer border overlay - drawn on top of children so border is never painted over
        Rectangle {
            anchors.fill: parent
            radius: container.radius
            color: "transparent"
            border.color: collapsed ? effectiveBorderColor : effectiveDropdownBorderColor
            border.width: (collapsed && (effectiveBorderColor == "transparent" || effectiveBorderColor == "#00000000")) ? 0 : 1
            z: 9999
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
            if (modelData[i] && modelData[i].id === id) {
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
        aboutToExpand();
        collapsed = false;
    }

    function openPicker() {
        if (optionCount <= 0) {
            return;
        }
        aboutToExpand();
        collapsed = true;
        var picker = _getPicker();
        if (picker) {
            _ownsOpenPicker = true;
            picker.open({
                titleText: inlineSelector.labelText,
                modelData: inlineSelector.modelData,
                multiSelect: false,
                selectedId: inlineSelector.selectedId,
                searchThreshold: inlineSelector.pickerThreshold,
                onSelected: function (id, name) {
                    inlineSelector.selectedId = id;
                    inlineSelector.selectedName = name;
                    inlineSelector.selectionMade(id, name, inlineSelector.selectorType);
                    inlineSelector.collapsed = true;
                },
                onClosed: function () {
                    inlineSelector._ownsOpenPicker = false;
                }
            });
        }
    }

    function collapse() {
        collapsed = true;
        if (_ownsOpenPicker) {
            var picker = _getPicker();
            if (picker && picker.isOpen) {
                picker.close();
            }
            _ownsOpenPicker = false;
        }
    }

    function clear() {
        selectedId = -1;
        selectedName = "";
    }
}
