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
import Lomiri.Components 1.3
import "./" as Components
import QtQuick.LocalStorage 2.7 as Sql
import "../../models/accounts.js" as Accounts
import "../../models/project.js" as Project

/*
    ProjectNavigator.qml - Logic Overview
    --------------------------------------

    PURPOSE:
    A recursive project navigation component for Ubuntu Touch that displays
    nested projects using a ListView and enables forward/backward traversal
    through parent-child project relationships.

    COMPONENTS:
    - `currentParentId`: Tracks the currently viewed parent project.
    - `navigationStackModel`: A ListModel used as a stack to remember previous parentIds for "Back" navigation.
    - `childrenMap`: A dictionary mapping parent_id to a ListModel of its child projects.
    - `projectSelected`: Signal emitted when a leaf (no children) project is selected.

    WORKFLOW:

    1. `populateProjectChildrenMap(isWorkProfile)`:
       - Fetches project records from SQLite using the given profile mode.
       - Groups projects by their parent_id in `tempMap`.
       - Marks items as `hasChildren` if their own id exists as a parent_id in `tempMap`.
       - Converts each entry in `tempMap` into a QML `ListModel` and stores it in `childrenMap`.
       - Logs the full hierarchy and sets `childrenMapReady = true`.

    2. `getCurrentModel()`:
       - Returns the `ListModel` corresponding to the current `currentParentId`.
       - If no model is found, returns an empty ListModel.

    3. UI Layout:
       - A `Column` contains:
         - A `Back` button (`TSButton`) shown only if the navigation stack has entries.
           - On click, it pops the last parentId from `navigationStackModel` and sets `currentParentId` to it.
         - A `ListView` displaying all child projects of `currentParentId`.

    4. `ListView` Delegate:
       - Displays a `ProjectDetailsCard` for each project.
       - On click:
         - If the project has children: pushes current id to stack and navigates deeper.
         - Else: emits `projectSelected()`.

    5. Reactive Updates:
       - `Connections` to `childrenMapReady` ensure the model is updated when the children map is first ready.
       - `onCurrentParentIdChanged` also reloads the ListView with the corresponding child list.

    6. Visual Adjustments:
       - Project cards have fixed height based on 1/6th of list view height.
       - Delegate height fallback ensures minimum space if the card has no defined height.

    RESULT:
    A smooth hierarchical project browser with deep navigation and backtracking using pure QML + SQLite + ListModels.

    Be CAREFUL when changing this code :)
*/

Item {
    id: projectList
    anchors.fill: parent

    property bool filterByAccount: false
    property int selectedAccountId: -1

    property int currentParentId: -1
    property int currentAccountId: -1
    property ListModel navigationStackModel: ListModel {}
    property var childrenMap: ({})
    property bool childrenMapReady: false
    property var stageFilter: ({
            enabled: true,
            odoo_record_id: -2,
            name: "Open"
        })
    property var stageList: []
    property var openStagesList: []

    // Search properties
    property string searchQuery: ""
    property bool showSearchBox: true

    // Signals
    signal projectSelected(int recordId)
    signal projectEditRequested(int recordId)
    signal projectDeleteRequested(int recordId)
    signal projectTimesheetRequested(int localId)
    signal customSearch(string query)

    function navigateToProject(projectId, accountId) {
        // Ensure we have valid IDs before proceeding
        if (projectId === undefined || accountId === undefined) {
            console.error("navigateToProject called with undefined values:", projectId, accountId);
            return;
        }

        navigationStackModel.append({
            parentId: currentParentId !== undefined ? currentParentId : -1,
            accountId: currentAccountId !== undefined ? currentAccountId : -1
        });
        currentParentId = projectId;
        currentAccountId = accountId;
    }

    function selectProject(localId) {
        projectSelected(localId);
    }

    function editProject(localId) {
        projectEditRequested(localId);
    }

    function requestTimesheet(localId) {
        projectTimesheetRequested(localId);
    }

    function refresh() {
        navigationStackModel.clear();
        currentParentId = -1;
        currentAccountId = -1;

        // Reset to default "Open" filter
        stageFilter.enabled = true;
        stageFilter.odoo_record_id = -2;
        stageFilter.name = "Open";

        // Clear search
        searchQuery = "";

        populateProjectChildrenMap();
    }

    // Search functions
    function toggleSearchVisibility() {
        showSearchBox = !showSearchBox;
    }

    function clearSearch() {
        searchField.text = "";
        searchQuery = "";
        customSearch("");
    }

    function performSearch(query) {
        searchQuery = query;
        customSearch(query);
        // Refresh the model with search filter applied
        if (childrenMapReady) {
            projectListView.model = getCurrentModel();
        }
    }

    function populateProjectChildrenMap() {
        childrenMap = {};
        childrenMapReady = false;

        var allProjects;

        if (filterByAccount && selectedAccountId >= 0) {
            allProjects = Project.getProjectsForAccount(selectedAccountId);
            console.log("Loading projects from default account", selectedAccountId + ":", allProjects.length, "projects");
        } else {
            allProjects = Project.getAllProjects();
            console.log("Loading projects from ALL accounts:", allProjects.length, "projects");
        }

        if (allProjects.length === 0) {
            childrenMapReady = true;
            return;
        }

        var tempMap = {};

        // First pass: Create project color map for inheritance lookup
        var projectColorMap = {};
        allProjects.forEach(function (row) {
            projectColorMap[row.odoo_record_id] = row.color_pallet ? parseInt(row.color_pallet) : 0;
        });

        allProjects.forEach(function (row) {
            var odooId = row.odoo_record_id;
            var parentOdooId = (row.parent_id === null || row.parent_id === 0) ? -1 : row.parent_id;
            var accountId = row.account_id;

            var accountName = Accounts.getAccountName(accountId);

            // Determine color with inheritance logic
            var inheritedColor = row.color_pallet ? parseInt(row.color_pallet) : 0;

            // If this is a subproject (has parent) and doesn't have its own color, inherit from parent
            if (parentOdooId !== -1 && (!row.color_pallet || parseInt(row.color_pallet) === 0)) {
                inheritedColor = projectColorMap[parentOdooId] || 0;
            }

            var item = {
                id_val: odooId,
                local_id: row.id,
                parent_id: parentOdooId,
                account_id: accountId,
                name: row.name || "Untitled",
                projectName: row.name || "Untitled",
                accountName: accountName,
                recordId: odooId,
                allocatedHours: row.allocated_hours ? row.allocated_hours : 0,
                remainingHours: row.remaining_hours ? row.remaining_hours : 0,
                startDate: row.planned_start_date || "",
                endDate: row.planned_end_date || "",
                deadline: row.planned_end_date || "",
                description: row.description || "",
                colorPallet: inheritedColor,
                stage: row.stage,
                isFavorite: row.favorites === 1,
                hasChildren: false
            };

            // Use compound key: parent_id + account_id for proper hierarchy grouping
            var hierarchyKey = parentOdooId + "_" + accountId;

            if (!tempMap[hierarchyKey])
                tempMap[hierarchyKey] = [];

            tempMap[hierarchyKey].push(item);
        });

        // Tag children info - updated to work with compound keys
        for (var hierarchyKey in tempMap) {
            tempMap[hierarchyKey].forEach(function (child) {
                // Check if this project has children by looking for compound key
                var childHierarchyKey = child.id_val + "_" + child.account_id;
                if (tempMap[childHierarchyKey]) {
                    child.hasChildren = true;
                    child.childCount = tempMap[childHierarchyKey].length;
                }
            });
        }

        // Convert to QML ListModels with sorting
        for (var key in tempMap) {
            var model = Qt.createQmlObject('import QtQuick 2.0; ListModel {}', projectList);

            // Sort the projects by name before adding to model
            tempMap[key].sort(function (a, b) {
                return a.projectName.localeCompare(b.projectName);
            });

            tempMap[key].forEach(function (entry) {
                model.append(entry);
            });
            childrenMap[key] = model;
        }

        childrenMapReady = true;
        console.log("Project children map populated for account filter:", selectedAccountId);
    }

    function getCurrentModel() {
        // Helper function to check if a project matches the stage filter
        function matchesStageFilter(project) {
            if (!stageFilter.enabled) {
                return true;
            }

            // Special case for "Open" filter (odoo_record_id = -2)
            if (stageFilter.odoo_record_id === -2) {
                // Check if the project's stage is in the list of open stages (fold = 0)
                for (var i = 0; i < openStagesList.length; i++) {
                    if (openStagesList[i].odoo_record_id === project.stage) {
                        return true;
                    }
                }
                return false;
            }

            return project.stage == stageFilter.odoo_record_id;
        }

        // Helper function to check if a project matches the search query
        function matchesSearchQuery(project) {
            if (!searchQuery || searchQuery.trim() === "") {
                return true;
            }

            var query = searchQuery.toLowerCase().trim();
            var projectName = (project.projectName || "").toLowerCase();
            var description = (project.description || "").toLowerCase();
            var accountName = (project.accountName || "").toLowerCase();

            return projectName.indexOf(query) !== -1 || description.indexOf(query) !== -1 || accountName.indexOf(query) !== -1;
        }

        // Find the model that matches current parent and account
        // For root level (currentParentId = -1), we need to find models for all accounts
        if (currentParentId === -1) {
            // Combine all root level projects from all accounts
            var combinedModel = Qt.createQmlObject('import QtQuick 2.0; ListModel {}', projectList);
            var allRootProjects = [];

            // If a filter is enabled, we need to find all children that match the filter
            // to determine which parents to include
            var includeParentIds = {};

            if (stageFilter.enabled) {
                // First pass: find all projects (at any level) that match the filter
                // and gather their parent IDs
                for (var mapKey in childrenMap) {
                    var childModel = childrenMap[mapKey];
                    for (var j = 0; j < childModel.count; j++) {
                        var childProject = childModel.get(j);
                        if (matchesStageFilter(childProject)) {
                            // Mark its parent to be included
                            var parentId = childProject.parent_id;
                            if (parentId !== -1) {
                                var parentKey = parentId + "_" + childProject.account_id;
                                includeParentIds[parentKey] = true;
                            }
                        }
                    }
                }

                // Recursive function to find all ancestor IDs
                function findAllAncestorIds(projectId, accountId) {
                    // If we hit root level, stop recursion
                    if (projectId === -1)
                        return;

                    var key = projectId + "_" + accountId;
                    // Find the parent of this project
                    for (var mapKey in childrenMap) {
                        var model = childrenMap[mapKey];
                        for (var i = 0; i < model.count; i++) {
                            var project = model.get(i);
                            if (project.id_val === projectId && project.account_id === accountId) {
                                // Mark the parent ID to be included
                                var parentId = project.parent_id;
                                if (parentId !== -1) {
                                    var parentKey = parentId + "_" + accountId;
                                    includeParentIds[parentKey] = true;
                                    // Recursively find grandparents
                                    findAllAncestorIds(parentId, accountId);
                                }
                                break;
                            }
                        }
                    }
                }

                // Process each direct parent to find all ancestors
                for (var parentKey in includeParentIds) {
                    var parts = parentKey.split("_");
                    if (parts.length === 2) {
                        findAllAncestorIds(parseInt(parts[0]), parseInt(parts[1]));
                    }
                }
            }

            // Gather all root level projects
            for (var key in childrenMap) {
                if (key.startsWith("-1_")) {
                    // Root level projects
                    var model = childrenMap[key];
                    for (var i = 0; i < model.count; i++) {
                        allRootProjects.push(model.get(i));
                    }
                }
            }

            // Sort all root projects alphabetically by project name
            allRootProjects.sort(function (a, b) {
                return a.projectName.localeCompare(b.projectName);
            });

            // Apply filter or include if it's a parent of a matching project
            allRootProjects.forEach(function (project) {
                if ((!stageFilter.enabled || matchesStageFilter(project) || includeParentIds[project.id_val + "_" + project.account_id]) && matchesSearchQuery(project)) {
                    combinedModel.append(project);
                }
            });

            return combinedModel;
        } else {
            // For specific parent, we need to find the account context
            // This will be set when navigating into a project
            var targetKey = currentParentId + "_" + currentAccountId;
            var model = childrenMap[targetKey];

            // For specific parent, gather projects that either match the filter
            // or are parents of matching projects
            var finalModel = Qt.createQmlObject('import QtQuick 2.0; ListModel {}', projectList);

            // Find children that match the filter criteria
            var includeParentIds = {};

            if (stageFilter.enabled) {
                // Find all children of this parent that match the filter
                for (var mapKey in childrenMap) {
                    var childModel = childrenMap[mapKey];
                    for (var j = 0; j < childModel.count; j++) {
                        var childProject = childModel.get(j);
                        // Check if this is a descendant of our current parent
                        if (matchesStageFilter(childProject)) {
                            // Check if this is a direct child of our current parent
                            if (childProject.parent_id === currentParentId && childProject.account_id === currentAccountId)
                            // Already a direct child, will be included
                            {} else {
                                // Check if it's a deeper descendant
                                var ancestorId = childProject.parent_id;
                                var ancestorAccountId = childProject.account_id;

                                // Trace up the hierarchy to see if current parent is an ancestor
                                while (ancestorId !== -1) {
                                    if (ancestorId === currentParentId && ancestorAccountId === currentAccountId) {
                                        // Current parent is an ancestor, mark all intermediate parents to be included
                                        var parentId = childProject.parent_id;
                                        var parentAccountId = childProject.account_id;
                                        var parentKey = parentId + "_" + parentAccountId;
                                        includeParentIds[parentKey] = true;
                                        break;
                                    }

                                    // Move up to next level
                                    var found = false;
                                    for (var k in childrenMap) {
                                        var ancestorModel = childrenMap[k];
                                        for (var m = 0; m < ancestorModel.count; m++) {
                                            var ancestorProject = ancestorModel.get(m);
                                            if (ancestorProject.id_val === ancestorId && ancestorProject.account_id === ancestorAccountId) {
                                                // Found the ancestor, move up one more level
                                                ancestorId = ancestorProject.parent_id;
                                                ancestorAccountId = ancestorProject.account_id;
                                                found = true;
                                                break;
                                            }
                                        }
                                        if (found)
                                            break;
                                    }
                                    if (!found) {
                                        // Cannot find the ancestor, break out
                                        ancestorId = -1;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            if (model) {
                for (var i = 0; i < model.count; i++) {
                    var item = model.get(i);
                    if ((!stageFilter.enabled || matchesStageFilter(item) || includeParentIds[item.id_val + "_" + item.account_id]) && matchesSearchQuery(item)) {
                        finalModel.append(item);
                    }
                }
            }
            return finalModel;
        }
    }

    function loadStages() {
        try {
            stageList = Project.getAllProjectStages();
            openStagesList = Project.getOpenProjectStages(); // Load open stages (fold = 0)

            // stageList = Project.getAllProjectStages();
            // openStagesList = Project.getOpenProjectStages(); // Load open stages (fold = 0)

            // // Build menu model for DialerMenu
            // var menuModel = [];

            // // Add "Open" as the first and default option
            // menuModel.push({
            //     label: "Open Projects",
            //     value: -2 // Special value for "Open" filter
            // });

            // menuModel.push({
            //     label: "All Stages",
            //     value: -1,
            //     account_id: -1 // Special value for "All"
            // });

            // // Track unique combinations of odoo_record_id + name + account_id
            // var uniqueCombinations = {};

            // for (var i = 0; i < stageList.length; i++) {
            //     var s = stageList[i];
            //     var odooId = s.odoo_record_id || 0;
            //     var stageName = s.name || "";
            //     var accountId = s.account_id || 0;

            //     // Create a unique key using odoo_record_id, name, and account_id
            //     var combinationKey = odooId + "_" + stageName + "_" + accountId;

            //     // Skip if we've already included this exact combination
            //     if (uniqueCombinations[combinationKey])
            //         continue;

            //     var label = stageName;

            //     // Add account name for context
            //     if (s.account_id) {
            //         // Append account name to make the label unique
            //         var acct = Accounts.getAccountName(s.account_id) || "Local";
            //         label = label + " (" + acct + ")";
            //     }

            //     // Mark this combination as seen
            //     uniqueCombinations[combinationKey] = true;

            //     // Add stage to menu model with its odoo_record_id and account_id as values
            //     menuModel.push({
            //         label: label,
            //         value: s.odoo_record_id,
            //         account_id: s.account_id
            //     });
            // }
            // dialer.menuModel = menuModel;
        } catch (e) {
            console.error("Failed to load stages:", e);
        }
    }

    // Timer for debounced search
    Timer {
        id: searchTimer
        interval: 300 // 300ms delay
        repeat: false
        onTriggered: performSearch(searchField.text)
    }

    Column {
        anchors.fill: parent
        spacing: units.gu(1)

        // Search field

        TextField {
            id: searchField
            visible: showSearchBox
            height: units.gu(5)
                width: parent.width
        //    anchors.rightMargin: units.gu(4) // Space for clear button
            placeholderText: "Search projects..."
            color: "#333333"
            selectByMouse: true
            onAccepted: performSearch(text)
            onTextChanged: {
                searchQuery = text;
                // Debounced search - only search after user stops typing
                searchTimer.restart();
            }

            Rectangle {

                height: parent.height
                width: parent.width
                anchors.left: parent.left
                anchors.right: parent.right
                color: "transparent"
                border.color: searchField.activeFocus ? "#FF6B35" : "#CCCCCC"
                border.width: searchField.activeFocus ? 2 : 1

                Button {
                    id: clearSearchButton
                    visible: searchField.text.length > 0
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: units.gu(0.5)
                    width: units.gu(3)
                    height: units.gu(3)
                    text: "×"
                    onClicked: clearSearch()
                }
            }
        }

        // Header row with back button
        TSButton {
            id: backbutton
            text: "← Back"
            width: parent.width
            height: units.gu(4)
            visible: navigationStackModel.count
            onClicked: {
                if (navigationStackModel.count > 0) {
                    var last = navigationStackModel.get(navigationStackModel.count - 1);
                    navigationStackModel.remove(navigationStackModel.count - 1);
                    currentParentId = last.parentId !== undefined ? last.parentId : -1;
                    currentAccountId = last.accountId !== undefined ? last.accountId : -1;
                }
            }
        }
        LomiriListView {
            id: projectListView
            width: parent.width
            height: parent.height - (backbutton.visible ? units.gu(4) : 0) - (showSearchBox ? units.gu(6) : 0) // Account for back button and search field heights
            clip: true
            model: getCurrentModel()

            delegate: Item {
                width: parent.width
                height: units.gu(13)

                ProjectDetailsCard {
                    id: projectCard
                    height: parent.height
                    width: parent.width
                    recordId: model.recordId
                    projectName: model.projectName
                    allocatedHours: model.allocatedHours
                    remainingHours: model.remainingHours
                    deadline: model.deadline
                    startDate: model.startDate
                    endDate: model.endDate
                    accountName: model.accountName
                    accountId: model.account_id
                    description: model.description
                    colorPallet: model.colorPallet
                    isFavorite: model.isFavorite
                    hasChildren: model.hasChildren
                    stage: model.stage
                    childCount: (model.hasChildren) ? model.childCount : 0
                    localId: model.local_id

                    // Store model properties in the delegate scope for signal handlers
                    property bool projectHasChildren: model.hasChildren || false
                    property int projectIdVal: model.id_val || 0
                    property int projectAccountId: model.account_id || 0
                    property int projectLocalId: model.local_id || 0

                    onEditRequested: id => {
                        editProject(projectLocalId);
                    }
                    onViewRequested: id => {
                        selectProject(projectLocalId);
                    }

                    onNavigationRequested: (projectId, accountId) => {
                        console.log("Navigation requested - projectId:", projectId, "accountId:", accountId);
                        navigateToProject(projectId, accountId);
                    }
                    onTimesheetRequested: localId => {
                        // Forward the signal to the parent page
                        requestTimesheet(localId);
                    }
                }
            }
        }
    }

    // Floating stage filter menu using StageFilterMenu component
    Components.StageFilterMenu {
        id: stageFilterMenu
        anchors.fill: parent
        menuModel: {
            var menuModel = [];

            // Add "Open" as the first option
            menuModel.push({
                label: "Open Projects",
                value: -2
            });

            menuModel.push({
                label: "All Stages",
                value: -1
            });

            // Track both unique odoo_record_id+name combinations
            var uniqueCombinations = {};

            for (var i = 0; i < stageList.length; i++) {
                var s = stageList[i];
                var odooId = s.odoo_record_id || 0;
                var stageName = s.name || "";

                // Create a unique key using both odoo_record_id and name
                var combinationKey = odooId + "_" + stageName;

                // Skip if we've already included this exact combination
                if (uniqueCombinations[combinationKey])
                    continue;

                var label = stageName;

                // Mark this combination as seen
                uniqueCombinations[combinationKey] = true;

                // Add stage to menu model with its odoo_record_id as value
                menuModel.push({
                    label: label,
                    value: s.odoo_record_id
                });
            }
            return menuModel;
        }

        onMenuItemSelected: function (index) {
            // menuModel entries carry value for odoo_record_id and account_id
            var selectedItem = stageFilterMenu.menuModel[index];
            if (!selectedItem)
                return;

            if (selectedItem.value === -2) {
                // Open Projects filter
                stageFilter.enabled = true;
                stageFilter.odoo_record_id = -2;
                stageFilter.name = "Open";
            } else if (selectedItem.value === -1) {
                stageFilter.enabled = false;
                stageFilter.odoo_record_id = -1;
                stageFilter.account_id = -1;
                stageFilter.name = "";
            } else {
                stageFilter.enabled = true;
                stageFilter.odoo_record_id = selectedItem.value;
                stageFilter.account_id = selectedItem.account_id || 0;
                stageFilter.name = selectedItem.label;
            }

            // Refresh listView model
            projectListView.model = getCurrentModel();
        }

        onFilterCleared: {
            // Reset to default "Open" filter
            stageFilter.enabled = true;
            stageFilter.odoo_record_id = -2;
            stageFilter.name = "Open";
            projectListView.model = getCurrentModel();
        }
    }

    Connections {
        target: projectList
        onChildrenMapReadyChanged: {
            if (childrenMapReady) {
                projectListView.model = getCurrentModel();
            }
        }
    }

    onCurrentParentIdChanged: {
        if (childrenMapReady) {
            projectListView.model = getCurrentModel();
        }
    }

    onCurrentAccountIdChanged: {
        if (childrenMapReady) {
            projectListView.model = getCurrentModel();
        }
    }

    onSearchQueryChanged: {
        if (childrenMapReady) {
            projectListView.model = getCurrentModel();
        }
    }

    Component.onCompleted: {
        populateProjectChildrenMap();
        // Load available project stages to populate filter menu
        loadStages();
    }
}
