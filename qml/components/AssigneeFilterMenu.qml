/*
 * MIT License
 *
 * Copyright (c) 2025 CIT-Services
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
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.0
import Lomiri.Components 1.3
import "../../models/constants.js" as AppConst

Item {
    id: assigneeFilterMenu
    anchors.fill: parent

    // Cached data for display assignees (no-search case) to avoid
    // rebuilding the full list from bindings on every evaluation.
    property var cachedDisplayAssignees: []
    property int cachedDisplayAssigneeCount: 0
    property int cachedSelectedDisplayAssigneeCount: 0

    signal filterApplied(var selectedAssigneeIds)
    signal filterCleared

    property var assigneeModel: []
    property bool expanded: false
    property var selectedAssigneeIds: []
    property bool showAccountName: false
    property int maxMenuHeight: units.gu(50)

    // Helper function to check if an assignee is selected (handles both old and new format)
    function isAssigneeSelected(userId, accountId) {
        for (var i = 0; i < selectedAssigneeIds.length; i++) {
            var selectedId = selectedAssigneeIds[i];
            if (typeof selectedId === 'object') {
                if (selectedId.user_id === userId && selectedId.account_id === accountId) {
                    return true;
                }
            } else if (selectedId === userId) {
                // Legacy format - consider it selected for backward compatibility
                return true;
            }
        }
        return false;
    }

    function createSelection(userId, accountId) {
        return {
            user_id: userId,
            account_id: accountId
        };
    }

    function hasSelectedAssignee(selection) {
        return isAssigneeSelected(selection.user_id, selection.account_id);
    }

    function hasAnySelectedAssignee(selections) {
        for (var i = 0; i < selections.length; i++) {
            if (hasSelectedAssignee(selections[i])) {
                return true;
            }
        }
        return false;
    }

    function addSelectionIfMissing(selection) {
        if (!hasSelectedAssignee(selection)) {
            selectedAssigneeIds.push(createSelection(selection.user_id, selection.account_id));
        }
    }

    function removeSelectionIfPresent(selection) {
        for (var i = selectedAssigneeIds.length - 1; i >= 0; i--) {
            var existingId = selectedAssigneeIds[i];
            if (typeof existingId === 'object') {
                if (existingId.user_id === selection.user_id && existingId.account_id === selection.account_id) {
                    selectedAssigneeIds.splice(i, 1);
                }
            } else if (existingId === selection.user_id) {
                selectedAssigneeIds.splice(i, 1);
            }
        }
    }

    function uniqueAccountNames(names) {
        var seen = Object.create(null);
        var result = [];

        for (var i = 0; i < names.length; i++) {
            var value = names[i];
            if (!value || seen[value]) {
                continue;
            }

            seen[value] = true;
            result.push(value);
        }

        return result;
    }

    function buildDisplayAssignees(searchText) {
        var normalizedSearch = (searchText || "").toLowerCase();
        var groupedAssignees = {};
        var filteredAssignees = [];

        for (var i = 0; i < assigneeModel.length; i++) {
            var assignee = assigneeModel[i];
            var assigneeId = assignee.odoo_record_id || assignee.id;
            var accountId = (assignee.account_id === undefined || assignee.account_id === null) ? -1 : assignee.account_id;
            var emailText = (assignee.email || "").trim();
            var normalizedEmail = emailText.toLowerCase();
            var accountName = assignee.account_name || "";
            var name = assignee.name || "";
            var shouldGroupByEmail = showAccountName && normalizedEmail !== "";
            var groupKey = shouldGroupByEmail ? "email:" + normalizedEmail : "account:" + accountId + ":user:" + assigneeId;
            var group = groupedAssignees[groupKey];

            if (!group) {
                group = {
                    assigneeId: assigneeId,
                    name: name,
                    email: emailText,
                    account_name: accountName,
                    account_names: accountName ? [accountName] : [],
                    memberSelections: [],
                    groupedByEmail: shouldGroupByEmail
                };
                groupedAssignees[groupKey] = group;
                filteredAssignees.push(group);
            } else {
                if (!group.name && name) {
                    group.name = name;
                }
                if (!group.email && emailText) {
                    group.email = emailText;
                }
                if (!group.account_name && accountName) {
                    group.account_name = accountName;
                }
            }

            if (accountName) {
                group.account_names.push(accountName);
            }

            group.memberSelections.push(createSelection(assigneeId, accountId));
        }

        var visibleAssignees = [];
        for (var j = 0; j < filteredAssignees.length; j++) {
            var entry = filteredAssignees[j];
            var accountNames = uniqueAccountNames(entry.account_names);
            var titleText = entry.name;

            if (showAccountName && accountNames.length > 0) {
                titleText = entry.name + " (" + accountNames.join(", ") + ")";
            }

            var selected = hasAnySelectedAssignee(entry.memberSelections);
            var searchableText = (titleText + " " + (entry.email || "")).toLowerCase();

            if (!normalizedSearch || searchableText.indexOf(normalizedSearch) >= 0) {
                visibleAssignees.push({
                    assigneeId: entry.assigneeId,
                    name: entry.name,
                    email: entry.email,
                    account_name: entry.account_name,
                    titleText: entry.name,
                    showAccountChips: showAccountName && accountNames.length > 0,
                    accountNamesJson: JSON.stringify(accountNames),
                    memberSelectionsJson: JSON.stringify(entry.memberSelections),
                    selected: selected,
                    sectionLabel: selected ? "selected" : "others"
                });
            }
        }

        visibleAssignees.sort(function (a, b) {
            if (a.selected !== b.selected) {
                return a.selected ? -1 : 1;
            }

            var nameA = (a.titleText || a.name || "").toLowerCase();
            var nameB = (b.titleText || b.name || "").toLowerCase();
            if (nameA < nameB)
                return -1;
            if (nameA > nameB)
                return 1;
            return 0;
        });

        return visibleAssignees;
    }

    // Recompute and cache the display assignee list and derived counts
    // for the no-search-text case. This is called when the underlying
    // model or selection changes, so that bindings can read cached
    // values without triggering O(n) work on every evaluation.
    function recomputeDisplayAssigneeCache() {
        var displayAssignees = buildDisplayAssignees("");
        cachedDisplayAssignees = displayAssignees;
        cachedDisplayAssigneeCount = displayAssignees.length;

        var selectedCount = 0;
        for (var i = 0; i < displayAssignees.length; i++) {
            if (displayAssignees[i].selected) {
                selectedCount++;
            }
        }
        cachedSelectedDisplayAssigneeCount = selectedCount;
    }

    function getDisplayAssigneeCount() {
        // Lazily initialize cache in case it hasn't been recomputed yet.
        if (!cachedDisplayAssignees || cachedDisplayAssignees.length !== cachedDisplayAssigneeCount) {
            recomputeDisplayAssigneeCache();
        }
        return cachedDisplayAssigneeCount;
    }

    function getSelectedDisplayAssigneeCount() {
        // Lazily initialize cache in case it hasn't been recomputed yet.
        if (!cachedDisplayAssignees || cachedDisplayAssignees.length !== cachedDisplayAssigneeCount) {
            recomputeDisplayAssigneeCache();
        }
        return cachedSelectedDisplayAssigneeCount;
    }

    // Background overlay when expanded
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: expanded ? 0.3 : 0
        visible: expanded

        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: expanded = false
        }
    }

    // Filter menu container
    Rectangle {
        id: menuContainer
        visible: expanded
        width: units.gu(40)
        height: {
            // Calculate dynamic height: header + search + assignee list + buttons + margins
            var baseHeight = units.gu(22); // Header + search + buttons + margins
            var assigneeListHeight = Math.min(getDisplayAssigneeCount() * units.gu(6), units.gu(25)); // Max 25 units for list
            return Math.min(units.gu(50), baseHeight + assigneeListHeight);
        }

        anchors.top: parent.top
        //  anchors.right: parent.right
        anchors.margins: units.gu(3)
        anchors.horizontalCenter: parent.horizontalCenter

        radius: units.gu(2)
        color: theme.palette.normal.background
        border.color: theme.palette.normal.base
        border.width: 1

        z: 12

        // Drop shadow effect
        layer.enabled: true
        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: 4
            radius: 8
            samples: 17
            color: "#40000000"
        }

        // Scale and opacity animations
        scale: expanded ? 1 : 0.8
        opacity: expanded ? 1 : 0

        Behavior on scale {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutBack
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }

        Column {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: units.gu(1)
            spacing: units.gu(1)

            // Header
            Rectangle {
                width: parent.width
                height: units.gu(5)
                color: "transparent"

                Row {
                    anchors.fill: parent
                    anchors.margins: units.gu(1)
                    spacing: units.gu(1)

                    Icon {
                        name: "contact"
                        width: units.gu(2.5)
                        height: units.gu(2.5)
                        anchors.verticalCenter: parent.verticalCenter
                        color: theme.palette.normal.backgroundText
                    }

                    Text {
                        text: i18n.dtr("ubtms", "Filter by Assignees")
                        font.bold: true
                        font.pixelSize: units.gu(2.2)
                        color: theme.palette.normal.backgroundText
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // Separator
            Rectangle {
                width: parent.width
                height: 1
                color: theme.palette.normal.base
            }

            // Search bar for long lists
            Row {
                visible: getDisplayAssigneeCount() > 5
                width: parent.width
                height: units.gu(4)
                spacing: units.gu(0.5)

                TextField {
                    id: searchField
                    width: parent.width - clearSearchButton.width - parent.spacing
                    height: parent.height
                    placeholderText: i18n.dtr("ubtms", "Search assignees...")

                    onAccepted: {
                        filterModel.update(); // Handle enter key press
                    }

                    // onTextChanged: {
                    //     filterModel.update();
                    // }
                }

                // Custom clear search button (needed because native clear doesn't trigger filter update)
                Rectangle {
                    id: clearSearchButton
                    width: units.gu(3.5)
                    height: parent.height

                    color: clearMouseArea.pressed ? theme.palette.selected.background : "transparent"
                    radius: units.gu(0.5)
                    border.color: clearMouseArea.containsMouse ? theme.palette.normal.base : "transparent"
                    border.width: 1

                    Icon {
                        name: "edit-clear"
                        width: units.gu(2)
                        height: units.gu(2)
                        anchors.centerIn: parent
                        color: theme.palette.normal.backgroundText
                    }

                    MouseArea {
                        id: clearMouseArea
                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: {
                            searchField.text = "";
                            searchField.focus = false;
                            filterModel.update(); // This is why we need custom clear - native clear doesn't do this
                        }
                    }
                }
            }

            // Assignee list view
            ListView {
                id: assigneeListView
                width: parent.width
                height: Math.min(units.gu(25), Math.max(units.gu(12), filterModel.count * units.gu(6)))
                clip: true

                model: ListModel {
                    id: filterModel

                    function update() {
                        clear();
                        var filteredAssignees = buildDisplayAssignees(searchField.text);

                        for (var j = 0; j < filteredAssignees.length; j++) {
                            append(filteredAssignees[j]);
                        }
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    width: units.gu(1)
                }

                section.property: "sectionLabel"
                section.criteria: ViewSection.FullString
                section.delegate: Item {
                    width: assigneeListView.width
                    height: units.gu(2.2)

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        height: 1
                        color: theme.palette.normal.base
                        opacity: 0.45
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(1)
                        anchors.verticalCenter: parent.verticalCenter
                        text: section === "selected" ? i18n.dtr("ubtms", "Selected") : i18n.dtr("ubtms", "Others")
                        font.pixelSize: units.gu(1.35)
                        color: theme.palette.normal.backgroundSecondaryText
                        opacity: 0.75
                    }
                }

                delegate: Rectangle {
                    id: delegateRoot
                    property bool expandedAccounts: false
                    property var accountNames: model.accountNamesJson ? JSON.parse(model.accountNamesJson) : []
                    property bool showsAccountChips: model.showAccountChips && accountNames.length > 0
                    property real contentMargin: units.gu(1)
                    property real contentSpacing: units.gu(1.5)
                    property int visibleChipCount: {
                        if (!showsAccountChips)
                            return 0;
                        if (accountNames.length <= 1)
                            return accountNames.length;
                        if (expandedAccounts)
                            return accountNames.length;

                        var availableWidth = Math.max(0, headerFlow.width - nameLabel.width - headerFlow.spacing);
                        var usedWidth = 0;
                        var count = 0;
                        var moreChipWidth = units.gu(7);
                        for (var chipIndex = 0; chipIndex < accountNames.length; chipIndex++) {
                            var chipText = accountNames[chipIndex];
                            var estimatedWidth = Math.max(units.gu(7), Math.min(units.gu(16), chipText.length * units.gu(0.75) + units.gu(3.5)));
                            var spacingWidth = count > 0 ? headerFlow.spacing : 0;
                            var reserveWidth = chipIndex < accountNames.length - 1 ? moreChipWidth + headerFlow.spacing : 0;
                            if (usedWidth + spacingWidth + estimatedWidth + reserveWidth > availableWidth) {
                                break;
                            }
                            usedWidth += spacingWidth + estimatedWidth;
                            count++;
                            if (count === 2)
                                break;
                        }

                        return Math.max(1, count);
                    }
                    property bool hasHiddenChips: showsAccountChips && visibleChipCount < accountNames.length

                    width: parent.width
                    height: Math.max(units.gu(6), infoColumn.implicitHeight + contentMargin * 2)
                    color: mouseArea.pressed ? theme.palette.selected.background : "transparent"
                    radius: units.gu(0.5)

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: {
                            var memberSelections = [];
                            if (model.memberSelectionsJson) {
                                memberSelections = JSON.parse(model.memberSelectionsJson);
                            }
                            var shouldSelect = !hasAnySelectedAssignee(memberSelections);

                            for (var i = 0; i < memberSelections.length; i++) {
                                if (shouldSelect) {
                                    addSelectionIfMissing(memberSelections[i]);
                                } else {
                                    removeSelectionIfPresent(memberSelections[i]);
                                }
                            }

                            selectedAssigneeIds = selectedAssigneeIds.slice();
                        }
                    }

                    CheckBox {
                        id: checkbox
                        anchors.left: parent.left
                        anchors.leftMargin: delegateRoot.contentMargin
                        anchors.top: parent.top
                        anchors.topMargin: delegateRoot.contentMargin
                        checkable: false
                        checked: model.selected
                    }

                    Icon {
                        id: userIcon
                        name: "contact"
                        width: units.gu(2.5)
                        height: units.gu(2.5)
                        anchors.left: checkbox.right
                        anchors.leftMargin: delegateRoot.contentSpacing
                        anchors.verticalCenter: checkbox.verticalCenter
                        color: theme.palette.normal.backgroundText
                    }

                    Column {
                        id: infoColumn
                        anchors.left: userIcon.right
                        anchors.leftMargin: delegateRoot.contentSpacing
                        anchors.right: parent.right
                        anchors.rightMargin: delegateRoot.contentMargin
                        anchors.top: parent.top
                        anchors.topMargin: delegateRoot.contentMargin
                        spacing: units.gu(0.4)

                        Flow {
                            id: headerFlow
                            width: infoColumn.width
                            spacing: units.gu(0.5)

                            Text {
                                id: nameLabel
                                width: Math.min(headerFlow.width, Math.max(implicitWidth, units.gu(8)))
                                text: model.titleText || model.name
                                font.pixelSize: units.gu(2)
                                color: theme.palette.normal.backgroundText
                                wrapMode: Text.NoWrap
                                elide: Text.ElideRight
                            }

                            Repeater {
                                model: delegateRoot.accountNames.length

                                Rectangle {
                                    visible: delegateRoot.showsAccountChips && index < delegateRoot.visibleChipCount
                                    height: units.gu(2.6)
                                    radius: height / 2
                                    color: theme.palette.normal.base
                                    border.color: theme.palette.selected.background
                                    border.width: 1
                                    width: Math.min(Math.max(units.gu(7), infoColumn.width * 0.42), chipLabel.implicitWidth + units.gu(2.4))

                                    Text {
                                        id: chipLabel
                                        anchors.centerIn: parent
                                        width: parent.width - units.gu(1.6)
                                        text: delegateRoot.accountNames[index]
                                        font.pixelSize: units.gu(1.35)
                                        color: theme.palette.normal.backgroundText
                                        elide: Text.ElideRight
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }
                            }

                            Rectangle {
                                visible: delegateRoot.showsAccountChips && delegateRoot.hasHiddenChips && delegateRoot.accountNames.length > 1
                                height: units.gu(2.6)
                                radius: height / 2
                                color: theme.palette.highlighted.background
                                border.color: theme.palette.selected.background
                                border.width: 1
                                width: Math.max(units.gu(7), moreChipLabel.implicitWidth + units.gu(2.4))

                                Text {
                                    id: moreChipLabel
                                    anchors.centerIn: parent
                                    text: delegateRoot.expandedAccounts ? i18n.dtr("ubtms", "Less") : i18n.dtr("ubtms", "More")
                                    font.pixelSize: units.gu(1.35)
                                    color: theme.palette.normal.backgroundText
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        delegateRoot.expandedAccounts = !delegateRoot.expandedAccounts;
                                        mouse.accepted = true;
                                    }
                                }
                            }
                        }

                        Text {
                            visible: model.email !== ""
                            text: model.email
                            font.pixelSize: units.gu(1.5)
                            color: theme.palette.normal.backgroundSecondaryText
                            elide: Text.ElideRight
                            width: infoColumn.width
                            opacity: 0.7
                        }
                    }

                    // Hover effect
                    Rectangle {
                        anchors.fill: parent
                        color: theme.palette.highlighted.background
                        opacity: mouseArea.containsMouse ? 0.1 : 0
                        radius: parent.radius

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 150
                            }
                        }
                    }
                }
            }

            // Action buttons
            Rectangle {
                width: parent.width
                height: units.gu(8)
                color: "transparent"

                Rectangle {
                    width: parent.width
                    height: 1
                    color: theme.palette.normal.base
                    anchors.top: parent.top
                }

                Row {
                    anchors.centerIn: parent
                    spacing: units.gu(2)

                    // Apply Filter Button
                    TSButton {
                        text: i18n.dtr("ubtms", "Apply Filter")
                        enabled: selectedAssigneeIds.length > 0
                        width: units.gu(15)
                        height: units.gu(4)
                        bgColor: enabled ? LomiriColors.blue : LomiriColors.ash
                        fgColor: "white"

                        Component.onCompleted: {}

                        onClicked: {
                            if (selectedAssigneeIds.length > 0) {
                                expanded = false;
                                filterApplied(selectedAssigneeIds.slice());
                            } else {}
                        }
                    }

                    // Clear Filter Button
                    TSButton {
                        text: i18n.dtr("ubtms", "Clear Filter")
                        enabled: selectedAssigneeIds.length > 0
                        width: units.gu(15)
                        height: units.gu(4)
                        bgColor: enabled ? LomiriColors.orange : LomiriColors.ash
                        fgColor: "white"

                        Component.onCompleted: {}

                        onClicked: {
                            selectedAssigneeIds = [];
                            filterModel.update();
                            expanded = false;
                            filterCleared();
                        }
                    }
                }
            }

            // Footer with current selection count
            Rectangle {
                width: parent.width
                height: units.gu(3)
                color: "transparent"
                visible: selectedAssigneeIds.length > 0

                Rectangle {
                    width: parent.width
                    height: 1
                    color: theme.palette.normal.base
                    anchors.top: parent.top
                }

                Text {
                    property int selectedCount: getSelectedDisplayAssigneeCount()
                    text: selectedCount + " assignee" + (selectedCount === 1 ? "" : "s") + " selected"
                    font.pixelSize: units.gu(1.6)
                    color: theme.palette.normal.backgroundText
                    anchors.centerIn: parent
                    opacity: 0.7
                }
            }
        }
    }

    // Function to load assignees for the current account
    function loadAssignees(accountId) {
    // This will be called from the parent component
    // to populate the assigneeModel
    }

    // Initialize the filter model when assigneeModel changes
    onAssigneeModelChanged: {
        if (filterModel) {
            filterModel.update();
            // Keep cached display assignee data in sync with the model.
            recomputeDisplayAssigneeCache();
        }
    }

    // Update filter model when selectedAssigneeIds changes
    onSelectedAssigneeIdsChanged: {
        if (filterModel) {
            // Rebuild and sort so selected entries stay pinned at the top.
            filterModel.update();
            // Selection changed; update cached display counts accordingly.
            recomputeDisplayAssigneeCache();
        }
    }

    Component.onCompleted: {
        if (filterModel) {
            filterModel.update();
            // Ensure cache is initialized once the component is ready.
            recomputeDisplayAssigneeCache();
        }
    }
}
