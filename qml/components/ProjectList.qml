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
    id: projectNavigator
    anchors.fill: parent

    property int currentParentId: -1
    property int currentAccountId: -1
    property ListModel navigationStackModel: ListModel {}
    property var childrenMap: ({})
    property bool childrenMapReady: false
    property var stageFilter: ({
            enabled: false,
            odoo_record_id: -1,
            name: ""
        })
    property var stageList: []

    signal projectSelected(int recordId)
    signal projectEditRequested(int recordId)
    signal projectDeleteRequested(int recordId)
    signal projectTimesheetRequested(int localId)

    function navigateToProject(projectId, accountId) {
        // Ensure we have valid IDs before proceeding
        if (projectId === undefined || accountId === undefined) {
            console.error("navigateToProject called with undefined values:", projectId, accountId);
            return;
        }

        //  console.log("Navigating to subprojects - from parent:", currentParentId, "account:", currentAccountId, "to parent:", projectId, "account:", accountId);
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
        populateProjectChildrenMap(true);
    }

    function populateProjectChildrenMap() {
        childrenMap = {};
        childrenMapReady = false;

        var allProjects = Project.getAllProjects();

        if (allProjects.length === 0) {
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
            var model = Qt.createQmlObject('import QtQuick 2.0; ListModel {}', projectNavigator);

            // Sort the projects by name before adding to model
            tempMap[key].sort(function (a, b) {
                return a.projectName.localeCompare(b.projectName);
            });

            tempMap[key].forEach(function (entry) {
                model.append(entry);
            });
            childrenMap[key] = model;
            //
        }

        childrenMapReady = true;
    }

    function getCurrentModel() {

        // Find the model that matches current parent and account
        // For root level (currentParentId = -1), we need to find models for all accounts
        if (currentParentId === -1) {
            // Combine all root level projects from all accounts
            var combinedModel = Qt.createQmlObject('import QtQuick 2.0; ListModel {}', projectNavigator);
            var allRootProjects = [];

            for (var key in childrenMap) {
                if (key.startsWith("-1_")) {
                    // Root level projects
                    var model = childrenMap[key];
                    //  console.log("Adding root level projects from key:", key, "count:", model.count);
                    for (var i = 0; i < model.count; i++) {
                        allRootProjects.push(model.get(i));
                    }
                }
            }

            // Sort all root projects alphabetically by project name
            allRootProjects.sort(function (a, b) {
                return a.projectName.localeCompare(b.projectName);
            });

            // Optionally apply stage filter when building combined model
            allRootProjects.forEach(function (project) {
                if (stageFilter.enabled) {
                    // project.stage holds odoo_record_id of the stage
                    if (project.stage == stageFilter.odoo_record_id) {
                        combinedModel.append(project);
                    }
                } else {
                    combinedModel.append(project);
                }
            });

            // console.log("Root level combined model count:", combinedModel.count);
            return combinedModel;
        } else {
            // For specific parent, we need to find the account context
            // This will be set when navigating into a project
            var targetKey = currentParentId + "_" + currentAccountId;
            //  console.log("Looking for target key:", targetKey);
            var model = childrenMap[targetKey];

            // For specific parent, optionally filter by stage as well
            var finalModel = Qt.createQmlObject('import QtQuick 2.0; ListModel {}', projectNavigator);
            if (model) {
                for (var i = 0; i < model.count; i++) {
                    var item = model.get(i);
                    if (stageFilter.enabled) {
                        if (item.stage == stageFilter.odoo_record_id)
                            finalModel.append(item);
                    } else {
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
            // Build menu model for DialerMenu
            var menuModel = [];
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

                // Add account name for context
                if (s.account_id) {
                    // Append account name to make the label unique
                    var acct = Accounts.getAccountName(s.account_id) || "Local";
                    label = label + " (" + acct + ")";
                }

                // Mark this combination as seen
                uniqueCombinations[combinationKey] = true;

                // Add stage to menu model with its odoo_record_id as value
                menuModel.push({
                    label: label,
                    value: s.odoo_record_id
                });
            }
            dialer.menuModel = menuModel;
        } catch (e) {
            console.error("Failed to load stages:", e);
        }
    }

    Column {
        anchors.fill: parent
        spacing: units.gu(1)

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
                    //  console.log("Back navigation - restored parent:", currentParentId, "account:", currentAccountId);
                }
            }
        }
        LomiriListView {
            id: projectListView
            width: parent.width
            height: parent.height - backbutton.height
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

    // Floating filter menu using DialerMenu component
    // Floating stage filter menu using StageFilterMenu component
    Components.StageFilterMenu {
        id: stageFilterMenu
        anchors.fill: parent
        menuModel: {
            var menuModel = [];
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

                // Add account name for context
                if (s.account_id) {
                    // Append account name to make the label unique
                    var acct = Accounts.getAccountName(s.account_id) || "Local";
                    label = label + " (" + acct + ")";
                }

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
            // menuModel entries carry value for odoo_record_id
            var selectedItem = stageFilterMenu.menuModel[index];
            if (!selectedItem)
                return;

            if (selectedItem.value === -1) {
                stageFilter.enabled = false;
                stageFilter.odoo_record_id = -1;
                stageFilter.name = "";
            } else {
                stageFilter.enabled = true;
                stageFilter.odoo_record_id = selectedItem.value;
                stageFilter.name = selectedItem.label;
            }

            // Refresh listView model
            projectListView.model = getCurrentModel();
        }

        onFilterCleared: {
            stageFilter.enabled = false;
            stageFilter.odoo_record_id = -1;
            stageFilter.name = "";
            projectListView.model = getCurrentModel();
        }
    }
    Connections {
        target: projectNavigator
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

    Component.onCompleted: {
        populateProjectChildrenMap(true);
        // Load available project stages to populate FAB menu
        loadStages();
    }
}
