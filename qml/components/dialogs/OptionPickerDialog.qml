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
import QtQuick.Layouts 1.3
import Lomiri.Components 1.3
import "../../../models/constants.js" as AppConst
import "../base"

/**
 * OptionPickerDialog - Single shared searchable overlay picker.
 * Uses plain JS array models, debounced filtering above 80 items, and
 * discrete keyboard sizing to avoid ListModel churn and 60fps relayouts.
 */
Item {
    id: pickerOverlay

    property string titleText: i18n.dtr("ubtms", "Select Option")
    property var modelData: []
    property int selectedId: -1
    property var selectedIds: []
    property bool multiSelect: false
    property int searchThreshold: 6
    property int maxFilteredResults: 200
    property bool isOpen: false
    property alias searchText: searchBar.text

    property var _normalizedOptions: []
    property var filteredOptions: []
    property bool _hasMoreMatches: false
    property int _totalMatchCount: 0
    property bool _showSearchBar: false
    property bool _updatingQuery: false
    property real _frozenKeyboardHeight: 0

    property var _onSelectedCallback: null
    property var _onMultiToggleCallback: null
    property var _onMultiClearCallback: null
    property var _onClosedCallback: null

    property color selectedColor: AppConst.Colors.Primary || "#3498db"
    readonly property bool isDarkTheme: (typeof Theme !== "undefined" && Theme.name === "Ubuntu.Components.Themes.SuruDark") || (typeof theme !== "undefined" && theme.name === "Ubuntu.Components.Themes.SuruDark")
    readonly property color sheetBgColor: isDarkTheme ? "#1b1b1f" : "#ffffff"
    readonly property color borderColor: isDarkTheme ? "#3a3a3f" : "#d9d9de"
    readonly property color textColor: isDarkTheme ? "#ebebef" : "#222222"
    readonly property color mutedTextColor: isDarkTheme ? "#9a9aa2" : "#777777"
    readonly property color dividerColor: isDarkTheme ? "#2e2e34" : "#e6e6eb"
    readonly property bool showSearchBar: _showSearchBar
    readonly property int filteredCount: filteredOptions.length

    signal optionSelected(int id, string name)
    signal multiItemToggled(int id, string name, bool isSelected)
    signal multiCleared()
    signal closed()

    anchors.fill: parent
    visible: isOpen
    z: 10050

    function _updateKeyboardOffset() {
        if (!isOpen || typeof Qt === "undefined" || !Qt.inputMethod || !Qt.inputMethod.visible) {
            _frozenKeyboardHeight = 0;
            return;
        }
        var rectH = (Qt.inputMethod.keyboardRectangle && Qt.inputMethod.keyboardRectangle.height > 0)
            ? Qt.inputMethod.keyboardRectangle.height
            : pickerOverlay.height * 0.42;
        _frozenKeyboardHeight = rectH;
    }

    Connections {
        target: (typeof Qt !== "undefined" && Qt.inputMethod) ? Qt.inputMethod : null
        onVisibleChanged: {
            if (pickerOverlay.isOpen) {
                pickerOverlay._updateKeyboardOffset();
            }
        }
        onKeyboardRectangleChanged: {
            if (pickerOverlay.isOpen) {
                pickerOverlay._updateKeyboardOffset();
            }
        }
        onAnimatingChanged: {
            if (pickerOverlay.isOpen && !Qt.inputMethod.animating) {
                pickerOverlay._updateKeyboardOffset();
            }
        }
    }

    Timer {
        id: filterDebounceTimer
        interval: 90
        repeat: false
        onTriggered: pickerOverlay._applyFilter()
    }

    function _normalizeOptions(rawArray) {
        if (!rawArray || !Array.isArray(rawArray)) {
            return [];
        }
        var out = [];
        for (var i = 0; i < rawArray.length; i++) {
            var item = rawArray[i];
            if (!item || item.name === undefined || item.name === null) {
                continue;
            }
            var cleanName = String(item.name).trim();
            if (cleanName === "") {
                continue;
            }
            var itemId = item.id !== undefined ? item.id : (item.itemId !== undefined ? item.itemId : -1);
            out.push({
                id: itemId,
                name: cleanName,
                lower: cleanName.toLowerCase()
            });
        }
        return out;
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

    function _applyFilter() {
        var source = _normalizedOptions;
        var query = String(searchBar.text || "").trim().toLowerCase();
        var hasQuery = query.length > 0;

        if (!hasQuery) {
            _totalMatchCount = source.length;
            _hasMoreMatches = false;
            filteredOptions = source;
            return;
        }

        var matched = [];
        var total = 0;
        var cap = maxFilteredResults > 0 ? maxFilteredResults : 200;
        for (var i = 0; i < source.length; i++) {
            var opt = source[i];
            if (opt.id === -1 && opt.name === "Select") {
                continue;
            }
            if (opt.lower.indexOf(query) !== -1) {
                total++;
                if (matched.length < cap) {
                    matched.push(opt);
                }
            }
        }
        _totalMatchCount = total;
        _hasMoreMatches = total > cap;
        filteredOptions = matched;
        if (optionsListView.count > 0) {
            optionsListView.positionViewAtBeginning();
        }
    }

    function _scheduleFilter() {
        if (_updatingQuery) {
            return;
        }
        if (_normalizedOptions.length <= 80) {
            filterDebounceTimer.stop();
            _applyFilter();
        } else {
            filterDebounceTimer.restart();
        }
    }

    function _scrollToSelection() {
        if (filteredOptions.length === 0) {
            return;
        }
        var targetId = multiSelect ? (selectedIds && selectedIds.length > 0 ? selectedIds[0] : -1) : selectedId;
        if (targetId === -1) {
            optionsListView.positionViewAtBeginning();
            return;
        }
        for (var i = 0; i < filteredOptions.length; i++) {
            if (filteredOptions[i].id === targetId) {
                optionsListView.positionViewAtIndex(i, ListView.Center);
                return;
            }
        }
    }

    function open(config) {
        filterDebounceTimer.stop();
        if (_onClosedCallback) {
            var prevClosed = _onClosedCallback;
            _onClosedCallback = null;
            prevClosed();
        }
        if (config && typeof config === "object") {
            if (config.titleText !== undefined) titleText = config.titleText;
            if (config.modelData !== undefined) modelData = config.modelData;
            multiSelect = !!config.multiSelect;
            selectedId = config.selectedId !== undefined ? config.selectedId : -1;
            selectedIds = Array.isArray(config.selectedIds) ? config.selectedIds.slice() : [];
            if (config.searchThreshold !== undefined) searchThreshold = config.searchThreshold;
            _onSelectedCallback = typeof config.onSelected === "function" ? config.onSelected : null;
            _onMultiToggleCallback = typeof config.onMultiToggled === "function" ? config.onMultiToggled : null;
            _onMultiClearCallback = typeof config.onMultiCleared === "function" ? config.onMultiCleared : null;
            _onClosedCallback = typeof config.onClosed === "function" ? config.onClosed : null;
        } else {
            _onSelectedCallback = null;
            _onMultiToggleCallback = null;
            _onMultiClearCallback = null;
            _onClosedCallback = null;
        }

        _updatingQuery = true;
        searchBar.clear();
        _updatingQuery = false;

        _normalizedOptions = _normalizeOptions(modelData);
        _showSearchBar = _normalizedOptions.length > searchThreshold;
        _applyFilter();
        _updateKeyboardOffset();
        isOpen = true;
        Qt.callLater(_scrollToSelection);
    }

    function close() {
        if (!isOpen) {
            return;
        }
        filterDebounceTimer.stop();
        _updatingQuery = true;
        searchBar.clear();
        _updatingQuery = false;
        isOpen = false;
        _frozenKeyboardHeight = 0;
        _normalizedOptions = [];
        filteredOptions = [];
        var closedCb = _onClosedCallback;
        _onSelectedCallback = null;
        _onMultiToggleCallback = null;
        _onMultiClearCallback = null;
        _onClosedCallback = null;
        if (typeof Qt !== "undefined" && Qt.inputMethod) {
            Qt.inputMethod.hide();
        }
        if (closedCb) {
            closedCb();
        }
        closed();
    }

    onModelDataChanged: {
        if (isOpen) {
            _normalizedOptions = _normalizeOptions(modelData);
            _showSearchBar = _normalizedOptions.length > searchThreshold;
            _applyFilter();
        } else {
            _showSearchBar = (modelData && modelData.length > searchThreshold);
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
        readonly property real availableHeight: Math.max(units.gu(18), pickerOverlay.height - pickerOverlay._frozenKeyboardHeight - units.gu(3))
        width: Math.min(pickerOverlay.width * 0.92, units.gu(58))
        height: Math.min(availableHeight, units.gu(66))
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(units.gu(1.5), (pickerOverlay.height - pickerOverlay._frozenKeyboardHeight - height) / 2)
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

                    RowLayout {
                        id: headerActions
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: units.gu(0.8)

                        TSButton {
                            id: clearHeaderButton
                            visible: !multiSelect && selectedId > 0
                            text: i18n.dtr("ubtms", "Clear")
                            Layout.preferredWidth: units.gu(9)
                            Layout.preferredHeight: units.gu(3.6)
                            Layout.alignment: Qt.AlignVCenter
                            onClicked: {
                                if (_onSelectedCallback) {
                                    _onSelectedCallback(-1, "Select");
                                }
                                optionSelected(-1, "Select");
                                pickerOverlay.close();
                            }
                        }

                        TSButton {
                            id: clearAllHeaderButton
                            visible: multiSelect
                            enabled: selectedIds && selectedIds.length > 0
                            text: i18n.dtr("ubtms", "Clear All")
                            Layout.preferredWidth: units.gu(10)
                            Layout.preferredHeight: units.gu(3.6)
                            Layout.alignment: Qt.AlignVCenter
                            onClicked: {
                                pickerOverlay.selectedIds = [];
                                if (_onMultiClearCallback) {
                                    _onMultiClearCallback();
                                }
                                pickerOverlay.multiCleared();
                            }
                        }

                        TSButton {
                            id: doneHeaderButton
                            visible: multiSelect
                            text: i18n.dtr("ubtms", "Done")
                            Layout.preferredWidth: units.gu(8)
                            Layout.preferredHeight: units.gu(3.6)
                            Layout.alignment: Qt.AlignVCenter
                            onClicked: pickerOverlay.close()
                        }

                        MouseArea {
                            id: closeTapArea
                            visible: !multiSelect
                            Layout.preferredWidth: units.gu(4)
                            Layout.preferredHeight: units.gu(3.6)
                            Layout.alignment: Qt.AlignVCenter
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
                height: visible ? implicitHeight : 0
                visible: _showSearchBar
                topPadding: units.gu(0.8)
                bottomPadding: units.gu(0.8)
                horizontalPadding: units.gu(1.2)
                placeholderText: i18n.dtr("ubtms", "Filter options...")
                onTextChanged: pickerOverlay._scheduleFilter()
            }

            // Narrow-down hint when search matches exceed render cap
            Rectangle {
                id: capBanner
                width: parent.width
                height: visible ? units.gu(3.2) : 0
                visible: _hasMoreMatches
                color: isDarkTheme ? "#25252b" : "#f3f4f6"

                Text {
                    anchors.centerIn: parent
                    text: i18n.dtr("ubtms", "Showing top %1 of %2 matches").arg(maxFilteredResults).arg(_totalMatchCount)
                    font.pixelSize: units.gu(1.2)
                    color: mutedTextColor
                }
            }

            // Options list area
            Item {
                id: listArea
                width: parent.width
                height: Math.max(
                    0,
                    sheetCard.height - headerBar.height - searchBar.height - capBanner.height
                )

                ListView {
                    id: optionsListView
                    anchors.fill: parent
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    cacheBuffer: units.gu(24)
                    model: pickerOverlay.filteredOptions

                    ScrollBar.vertical: ScrollBar {
                        active: true
                        policy: ScrollBar.AsNeeded
                    }

                    delegate: Rectangle {
                        id: optionRow
                        width: optionsListView.width
                        height: units.gu(5.4)
                        readonly property var optItem: modelData
                        readonly property int optId: optItem ? optItem.id : -1
                        readonly property string optName: optItem ? optItem.name : ""
                        readonly property bool rowSelected: pickerOverlay._isSelected(optId)
                        color: rowSelected
                            ? Qt.rgba(selectedColor.r, selectedColor.g, selectedColor.b, 0.14)
                            : "transparent"

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
                                text: optionRow.optName
                                color: rowSelected ? selectedColor : textColor
                                font.pixelSize: units.gu(1.6)
                                font.bold: rowSelected
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (multiSelect) {
                                    var nextSel = !optionRow.rowSelected;
                                    var updated = pickerOverlay.selectedIds ? pickerOverlay.selectedIds.slice() : [];
                                    var idx = updated.indexOf(optionRow.optId);
                                    if (nextSel && idx === -1) {
                                        updated.push(optionRow.optId);
                                    } else if (!nextSel && idx !== -1) {
                                        updated.splice(idx, 1);
                                    }
                                    pickerOverlay.selectedIds = updated;
                                    if (_onMultiToggleCallback) {
                                        _onMultiToggleCallback(optionRow.optId, optionRow.optName, nextSel);
                                    }
                                    multiItemToggled(optionRow.optId, optionRow.optName, nextSel);
                                } else {
                                    if (_onSelectedCallback) {
                                        _onSelectedCallback(optionRow.optId, optionRow.optName);
                                    }
                                    optionSelected(optionRow.optId, optionRow.optName);
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
                    visible: pickerOverlay.filteredOptions.length === 0
                    text: i18n.dtr("ubtms", "No matching options")
                    font.pixelSize: units.gu(1.5)
                    color: mutedTextColor
                }
            }
        }
    }
}
