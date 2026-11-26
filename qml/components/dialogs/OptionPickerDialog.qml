/*
 * MIT License
 *
 * Copyright (c) 2026 CIT-Services
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import QtQuick 2.7
import QtQuick.Controls 2.2
import Lomiri.Components 1.3
import "../../../models/constants.js" as AppConst
import "../base"

/**
 * OptionPickerDialog - Searchable single or multi-select modal picker.
 * Renders at the root window level to eliminate nested Flickable scroll conflicts.
 */
Item {
    id: pickerOverlay

    property var anchorItem: null
    property string titleText: i18n.dtr("ubtms", "Select Option")
    property var modelData: []
    property int selectedId: -1
    property var selectedIds: []
    property bool multiSelect: false
    property int searchThreshold: 6
    property bool autoFocusSearch: false
    property bool isOpen: false
    property alias searchText: searchBar.text

    property color selectedColor: AppConst.Colors.Primary || "#3498db"
    readonly property bool isDarkTheme: (typeof Theme !== "undefined" && Theme.name === "Ubuntu.Components.Themes.SuruDark") || (typeof theme !== "undefined" && theme.name === "Ubuntu.Components.Themes.SuruDark")
    readonly property color sheetBgColor: isDarkTheme ? "#1b1b1f" : "#ffffff"
    readonly property color borderColor: isDarkTheme ? "#3a3a3f" : "#d9d9de"
    readonly property color textColor: isDarkTheme ? "#ebebef" : "#222222"
    readonly property color mutedTextColor: isDarkTheme ? "#9a9aa2" : "#777777"
    readonly property color dividerColor: isDarkTheme ? "#2e2e34" : "#e6e6eb"
    readonly property color rowHoverColor: isDarkTheme ? "#2b2b31" : "#f5f5f5"
    readonly property real keyboardHeight: (typeof Qt !== "undefined" && Qt.inputMethod && Qt.inputMethod.visible && Qt.inputMethod.keyboardRectangle) ? Qt.inputMethod.keyboardRectangle.height : 0
    readonly property bool showSearchBar: _validOptionCount() > searchThreshold
    readonly property int filteredCount: filteredModel.count

    signal optionSelected(int id, string name)
    signal multiItemToggled(int id, string name, bool isSelected)
    signal multiCleared()
    signal closed()

    x: 0
    y: 0
    width: parent ? parent.width : 0
    height: parent ? parent.height : 0
    visible: isOpen
    z: 10000

    ListModel {
        id: filteredModel
    }

    function _resolveRootParent() {
        var root = anchorItem ? anchorItem : pickerOverlay.parent;
        var guard = 0;
        while (root && root.parent && guard < 32) {
            root = root.parent;
            guard++;
        }
        return root;
    }

    function _validOptionCount() {
        if (!modelData || !Array.isArray(modelData)) {
            return 0;
        }
        var count = 0;
        for (var i = 0; i < modelData.length; i++) {
            var item = modelData[i];
            if (item && item.name !== undefined && item.name !== null && String(item.name).trim() !== "") {
                count++;
            }
        }
        return count;
    }

    function _isSelected(itemId) {
        if (multiSelect) {
            if (!selectedIds || !Array.isArray(selectedIds)) {
                return false;
            }
            for (var i = 0; i < selectedIds.length; i++) {
                if (selectedIds[i] === itemId) {
                    return true;
                }
            }
            return false;
        }
        return itemId === selectedId;
    }

    function _rebuildFilteredModel() {
        filteredModel.clear();
        if (!modelData || !Array.isArray(modelData)) {
            return;
        }

        var query = String(searchBar.text || "").trim().toLowerCase();
        var hasQuery = query.length > 0;

        for (var i = 0; i < modelData.length; i++) {
            var item = modelData[i];
            if (!item || item.name === undefined || item.name === null) {
                continue;
            }
            var cleanName = String(item.name).trim();
            if (cleanName === "") {
                continue;
            }
            var itemId = item.id !== undefined ? item.id : (item.itemId !== undefined ? item.itemId : -1);

            if (hasQuery) {
                if (itemId === -1 && cleanName === "Select") {
                    continue;
                }
                if (cleanName.toLowerCase().indexOf(query) === -1) {
                    continue;
                }
            }

            filteredModel.append({
                itemId: itemId,
                name: cleanName
            });
        }
    }

    function _scrollToSelection() {
        if (filteredModel.count === 0) {
            return;
        }
        var targetId = multiSelect ? (selectedIds && selectedIds.length > 0 ? selectedIds[0] : -1) : selectedId;
        if (targetId === -1) {
            optionsListView.positionViewAtBeginning();
            return;
        }
        for (var i = 0; i < filteredModel.count; i++) {
            if (filteredModel.get(i).itemId === targetId) {
                optionsListView.positionViewAtIndex(i, ListView.Center);
                return;
            }
        }
    }

    function open() {
        var resolvedRoot = _resolveRootParent();
        if (resolvedRoot && pickerOverlay.parent !== resolvedRoot) {
            pickerOverlay.parent = resolvedRoot;
        }
        searchBar.clear();
        _rebuildFilteredModel();
        isOpen = true;
        Qt.callLater(function () {
            _scrollToSelection();
            if (autoFocusSearch && showSearchBar) {
                searchBar.forceActiveFocus();
            }
        });
    }

    Component.onDestruction: {
        isOpen = false;
    }

    function close() {
        if (!isOpen) {
            return;
        }
        searchBar.clear();
        isOpen = false;
        closed();
    }

    onModelDataChanged: {
        if (isOpen) {
            _rebuildFilteredModel();
        }
    }

    // Dimmed backdrop
    Rectangle {
        anchors.fill: parent
        color: isDarkTheme ? Qt.rgba(0, 0, 0, 0.72) : Qt.rgba(0, 0, 0, 0.5)

        MouseArea {
            anchors.fill: parent
            onClicked: pickerOverlay.close()
        }
    }

    // Picker card sheet
    Rectangle {
        id: sheetCard
        width: Math.min(pickerOverlay.width * 0.92, units.gu(58))
        height: Math.min(Math.max(units.gu(26), pickerOverlay.height - keyboardHeight - units.gu(6)), units.gu(68))
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(units.gu(2), (pickerOverlay.height - keyboardHeight - height) / 2)
        radius: units.gu(1.2)
        color: sheetBgColor
        border.color: borderColor
        border.width: 1
        clip: true

        // Prevent backdrop clicks when tapping inside sheet
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        Column {
            id: sheetLayout
            anchors.fill: parent
            spacing: 0

            // Header bar
            Rectangle {
                id: headerBar
                width: parent.width
                height: units.gu(5.5)
                color: "transparent"

                Item {
                    anchors.fill: parent
                    anchors.leftMargin: units.gu(1.5)
                    anchors.rightMargin: units.gu(1)

                    Text {
                        id: titleLabel
                        anchors.left: parent.left
                        anchors.right: headerActions.left
                        anchors.rightMargin: units.gu(1)
                        anchors.verticalCenter: parent.verticalCenter
                        text: multiSelect && selectedIds && selectedIds.length > 0
                            ? titleText + " (" + selectedIds.length + ")"
                            : titleText
                        font.pixelSize: units.gu(1.8)
                        font.bold: true
                        color: textColor
                        elide: Text.ElideRight
                    }

                    Row {
                        id: headerActions
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: units.gu(0.8)

                        TSButton {
                            visible: !multiSelect && selectedId > 0
                            text: i18n.dtr("ubtms", "Clear")
                            height: units.gu(3.6)
                            anchors.verticalCenter: parent.verticalCenter
                            onClicked: {
                                optionSelected(-1, "Select");
                                pickerOverlay.close();
                            }
                        }

                        MouseArea {
                            id: closeTapArea
                            width: units.gu(4)
                            height: units.gu(4)
                            anchors.verticalCenter: parent.verticalCenter
                            cursorShape: Qt.PointingHandCursor
                            onClicked: pickerOverlay.close()

                            Icon {
                                anchors.centerIn: parent
                                width: units.gu(2)
                                height: units.gu(2)
                                name: "close"
                                color: textColor
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    anchors.bottom: parent.bottom
                    color: dividerColor
                }
            }

            // Search bar (shown when option count exceeds threshold)
            TSSearchBar {
                id: searchBar
                width: parent.width
                visible: showSearchBar
                topPadding: units.gu(0.8)
                bottomPadding: units.gu(0.8)
                horizontalPadding: units.gu(1.2)
                placeholderText: i18n.dtr("ubtms", "Filter options...")
                onTextChanged: _rebuildFilteredModel()
                onCleared: _rebuildFilteredModel()
            }

            // Options list area
            Item {
                id: listArea
                width: parent.width
                height: Math.max(
                    units.gu(10),
                    sheetCard.height - headerBar.height - (searchBar.visible ? searchBar.height : 0) - (footerBar.visible ? footerBar.height : 0)
                )

                ListView {
                    id: optionsListView
                    anchors.fill: parent
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: filteredModel

                    ScrollBar.vertical: ScrollBar {
                        active: true
                        policy: ScrollBar.AsNeeded
                    }

                    delegate: Rectangle {
                        id: optionRow
                        width: optionsListView.width
                        height: units.gu(5.4)
                        readonly property bool rowSelected: pickerOverlay._isSelected(model.itemId)
                        color: rowSelected
                            ? Qt.rgba(selectedColor.r, selectedColor.g, selectedColor.b, 0.14)
                            : (rowTap.containsMouse ? rowHoverColor : "transparent")

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: units.gu(1.5)
                            anchors.rightMargin: units.gu(1.5)
                            spacing: units.gu(1.2)

                            Rectangle {
                                width: units.gu(2.4)
                                height: units.gu(2.4)
                                radius: multiSelect ? units.gu(0.4) : units.gu(1.2)
                                anchors.verticalCenter: parent.verticalCenter
                                color: rowSelected ? selectedColor : "transparent"
                                border.color: rowSelected ? selectedColor : dividerColor
                                border.width: 1

                                Icon {
                                    anchors.centerIn: parent
                                    width: units.gu(1.4)
                                    height: units.gu(1.4)
                                    name: "tick"
                                    color: "white"
                                    visible: rowSelected
                                }
                            }

                            Text {
                                width: parent.width - units.gu(4.2)
                                height: parent.height
                                text: model.name
                                color: rowSelected ? selectedColor : textColor
                                font.pixelSize: units.gu(1.6)
                                font.bold: rowSelected
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: rowTap
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                if (multiSelect) {
                                    multiItemToggled(model.itemId, model.name, !optionRow.rowSelected);
                                } else {
                                    optionSelected(model.itemId, model.name);
                                    pickerOverlay.close();
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            anchors.bottom: parent.bottom
                            color: dividerColor
                            opacity: 0.7
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    width: parent.width - units.gu(4)
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    visible: filteredModel.count === 0
                    text: i18n.dtr("ubtms", "No matching options")
                    font.pixelSize: units.gu(1.5)
                    color: mutedTextColor
                }
            }

            // Footer actions for multi-select mode
            Rectangle {
                id: footerBar
                width: parent.width
                height: units.gu(6)
                visible: multiSelect
                color: "transparent"

                Rectangle {
                    width: parent.width
                    height: 1
                    anchors.top: parent.top
                    color: dividerColor
                }

                Item {
                    anchors.fill: parent
                    anchors.leftMargin: units.gu(1.5)
                    anchors.rightMargin: units.gu(1.5)

                    TSButton {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: i18n.dtr("ubtms", "Clear All")
                        height: units.gu(4)
                        enabled: selectedIds && selectedIds.length > 0
                        onClicked: pickerOverlay.multiCleared()
                    }

                    TSButton {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: i18n.dtr("ubtms", "Done")
                        height: units.gu(4)
                        onClicked: pickerOverlay.close()
                    }
                }
            }
        }
    }
}
