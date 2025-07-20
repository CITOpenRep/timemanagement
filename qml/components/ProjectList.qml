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
    property ListModel navigationStackModel: ListModel {}
    property var childrenMap: ({})
    property bool childrenMapReady: false

    signal projectSelected(int recordId)
    signal projectEditRequested(int recordId)
    signal projectDeleteRequested(int recordId)
    signal projectTimesheetRequested(int localId)

    function refresh() {
        navigationStackModel.clear();
        currentParentId = -1;
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

        allProjects.forEach(function (row) {
            var odooId = row.odoo_record_id;
            var parentOdooId = (row.parent_id === null || row.parent_id === 0) ? -1 : row.parent_id;

            var accountName = Accounts.getAccountName(row.account_id);

            var item = {
                id_val: odooId,
                local_id: row.id,
                parent_id: parentOdooId,
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
                colorPallet: row.color_pallet ? parseInt(row.color_pallet) : 0,
                isFavorite: row.favorites === 1,
                hasChildren: false
            };

            if (!tempMap[parentOdooId])
                tempMap[parentOdooId] = [];

            tempMap[parentOdooId].push(item);
        });

        // Tag children info
        for (var parent in tempMap) {
            tempMap[parent].forEach(function (child) {
                if (tempMap[child.id_val]) {
                    child.hasChildren = true;
                    child.childCount = tempMap[child.id_val].length;
                }
            });
        }

        // Convert to QML ListModels
        for (var key in tempMap) {
            var model = Qt.createQmlObject('import QtQuick 2.0; ListModel {}', projectNavigator);
            tempMap[key].forEach(function (entry) {
                model.append(entry);
            });
            childrenMap[key] = model;
        }

        childrenMapReady = true;
    }

    function getCurrentModel() {
        var model = childrenMap[currentParentId];
        return model || Qt.createQmlObject('import QtQuick 2.0; ListModel {}', projectNavigator);
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
                    var last = navigationStackModel.get(navigationStackModel.count - 1).parentId;
                    navigationStackModel.remove(navigationStackModel.count - 1);
                    currentParentId = last;
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
                    description: model.description
                    colorPallet: model.colorPallet
                    isFavorite: model.isFavorite
                    hasChildren: model.hasChildren
                    childCount: (model.hasChildren) ? model.childCount : 0
                    localId: model.local_id

                    onEditRequested: id => {
                        projectEditRequested(local_id);
                    }
                    onViewRequested: id => {
                        projectSelected(local_id);
                    }
                    onTimesheetRequested: localId => {
                        // Forward the signal to the parent page
                        projectTimesheetRequested(localId);
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: model.hasChildren
                        onClicked: {
                            if (model.hasChildren) {
                                navigationStackModel.append({
                                    parentId: currentParentId
                                });
                                currentParentId = model.id_val;
                            }
                        }
                    }
                }
            }
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

    Component.onCompleted: {
        populateProjectChildrenMap(true);
    }
}
