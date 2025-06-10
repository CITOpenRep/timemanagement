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

    function populateProjectChildrenMap(isWorkProfile) {
        childrenMap = {};
        childrenMapReady = false;

        var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);

        db.transaction(function (tx) {
            var query = isWorkProfile ? 'SELECT * FROM project_project_app WHERE account_id IS NOT NULL ORDER BY name COLLATE NOCASE ASC' : 'SELECT * FROM project_project_app WHERE account_id IS NULL ORDER BY name COLLATE NOCASE ASC';

            var result = tx.executeSql(query);
            if (result.rows.length === 0) {
                console.log("⚠ No project data found");
                return;
            }

            var tempMap = {};

            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);
                var odooId = row.odoo_record_id;
                var parentOdooId = (row.parent_id === null || row.parent_id === 0) ? -1 : row.parent_id;
                var accountName = "";
                if (row.account_id !== null) {
                    var accResult = tx.executeSql("SELECT name FROM users WHERE id = ?", [row.account_id]);
                    if (accResult.rows.length > 0) {
                        accountName = accResult.rows.item(0).name;
                    }
                }
                var item = {
                    id_val: odooId,
                    local_id: row.id,
                    parent_id: parentOdooId,
                    name: row.name || "Untitled",
                    projectName: row.name || "Untitled",
                    accountName: accountName,
                    recordId: odooId,
                    allocatedHours: row.allocated_hours ? String(row.allocated_hours) : "0",
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
            }

            for (var parent in tempMap) {
                tempMap[parent].forEach(function (child) {
                    if (tempMap[child.id_val]) {
                        child.hasChildren = true;
                        child.childCount = children ? children.length : 0;
                    }
                });
            }

            for (var key in tempMap) {
                var model = Qt.createQmlObject('import QtQuick 2.0; ListModel {}', projectNavigator);
                tempMap[key].forEach(function (entry) {
                    model.append(entry);
                });
                childrenMap[key] = model;
            }

            childrenMapReady = true;

            console.log("childrenMap created with", Object.keys(childrenMap).length, "entries");
            for (var key in childrenMap) {
                var m = childrenMap[key];
                console.log("childrenMap[" + key + "] → count:", m.count);
                for (var j = 0; j < m.count; j++) {
                    var it = m.get(j);
                    console.log("   →", it.projectName, "| id_val:", it.id_val, "| parent_id:", it.parent_id, "| hasChildren:", it.hasChildren);
                }
            }
        });
    }

    function getCurrentModel() {
        var model = childrenMap[currentParentId];
        console.log("ListView loading model for parent:", currentParentId, ", count:", model ? model.count : 0);
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

            Component.onCompleted: {
                console.log("Initial ListView model for parent:", currentParentId, "→ count:", model.count);
            }

            onModelChanged: {
                console.log("Model changed for parent:", currentParentId, "→ count:", model.count);
            }

            delegate: Item {
                width: parent.width
                height: units.gu(10)

                Component.onCompleted: {
                    console.log("Showing:", model.projectName, "id:", model.id_val);
                }

                ProjectDetailsCard {
                    id: projectCard
                    height: parent.height
                    width: parent.width
                    recordId: model.recordId
                    projectName: model.projectName
                    allocatedHours: model.allocatedHours
                    deadline: model.deadline
                    startDate: model.startDate
                    endDate: model.endDate
                    accountName: model.accountName
                    description: model.description
                    colorPallet: model.colorPallet
                    isFavorite: model.isFavorite
                    hasChildren: model.hasChildren
                    childCount: model.childCount
                    localId: model.local_id

                    onEditRequested: id => {
                        console.log("Edit:", local_id);
                        projectEditRequested(local_id);
                    }
                    onViewRequested: id => {
                        console.log("Selected:", local_id);
                        projectSelected(local_id);
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: model.hasChildren
                        onClicked: {
                            if (model.hasChildren) {
                                console.log("Navigating into:", model.projectName, "→", model.id_val);
                                navigationStackModel.append({
                                    parentId: currentParentId
                                });
                                currentParentId = model.id_val;
                            } else {
                                console.log("Selecting:", model.projectName);
                                //projectNavigator.projectSelected(model.id_val, model.name);
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
                console.log("childrenMap is ready → assigning model");
                projectListView.model = getCurrentModel();
            }
        }
    }

    onCurrentParentIdChanged: {
        if (childrenMapReady) {
            console.log("currentParentId changed →", currentParentId);
            projectListView.model = getCurrentModel();
        }
    }

    Component.onCompleted: {
        populateProjectChildrenMap(true);
    }
}
