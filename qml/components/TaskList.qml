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

Item {
    id: taskNavigator
    anchors.fill: parent

    property int currentParentId: -1
    property ListModel navigationStackModel: ListModel {}
    property var childrenMap: ({})
    property bool childrenMapReady: false

    signal taskSelected(int recordId)
    signal taskEditRequested(int recordId)
    signal taskDeleteRequested(int recordId)

    function refresh() {
        console.log("🔄 Refreshing taskNavigator...");
        navigationStackModel.clear();
        currentParentId = -1;
        populateTaskChildrenMap(true);
    }

    function populateTaskChildrenMap(isWorkProfile) {
        childrenMap = {};
        childrenMapReady = false;

        var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);

        db.transaction(function (tx) {
            var query = isWorkProfile ? "SELECT * FROM project_task_app WHERE account_id IS NOT NULL AND (status IS NULL OR status != 'deleted') ORDER BY name COLLATE NOCASE ASC" : "SELECT * FROM project_task_app WHERE account_id IS NULL AND (status IS NULL OR status != 'deleted') ORDER BY name COLLATE NOCASE ASC";

            var result = tx.executeSql(query);
            if (result.rows.length === 0) {
                console.log("⚠ No task data found");
                return;
            }

            var tempMap = {};

            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);
                var odooId = row.odoo_record_id;
                var parentOdooId = (row.parent_id === null || row.parent_id === 0) ? -1 : row.parent_id;
                var project = tx.executeSql("SELECT name FROM project_project_app WHERE odoo_record_id = ? AND account_id = ?", [row.project_id, row.account_id]);
                if (project.rows.length > 0) //found a valid project
                {
                    var item = {
                        id_val: odooId,
                        local_id: row.id,
                        account_id: row.account_id,
                        project: project.rows.item(0).name,
                        parent_id: parentOdooId,
                        name: row.name || "Untitled",
                        taskName: row.name || "Untitled",
                        recordId: odooId,
                        allocatedHours: row.initial_planned_hours ? String(row.initial_planned_hours) : "0",
                        startDate: row.start_date || "",
                        endDate: row.end_date || "",
                        deadline: row.deadline || "",
                        description: row.description || "",
                        isFavorite: row.favorites === 1,
                        hasChildren: false
                    };

                    if (!tempMap[parentOdooId])
                        tempMap[parentOdooId] = [];
                    tempMap[parentOdooId].push(item);
                }
            } //TODO : If an account has two projects with the exact same name , we are screwed , improve the logic

            for (var parent in tempMap) {
                tempMap[parent].forEach(function (child) {
                    var children = tempMap[child.id_val];
                    child.hasChildren = !!children;
                    child.childCount = children ? children.length : 0;
                });
            }

            for (var key in tempMap) {
                var model = Qt.createQmlObject('import QtQuick 2.0; ListModel {}', taskNavigator);
                tempMap[key].forEach(function (entry) {
                    model.append(entry);
                });
                childrenMap[key] = model;
            }

            childrenMapReady = true;

            console.log("Task childrenMap created with", Object.keys(childrenMap).length, "entries");
        });
    }

    function getCurrentModel() {
        var model = childrenMap[currentParentId];
        console.log("ListView loading task model for parent:", currentParentId, ", count:", model ? model.count : 0);
        return model || Qt.createQmlObject('import QtQuick 2.0; ListModel {}', taskNavigator);
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
            id: taskListView
            width: parent.width
            height: parent.height - backbutton.height
            clip: true
            model: getCurrentModel()

            delegate: Item {
                width: parent.width
                height: units.gu(10)

                TaskDetailsCard {
                    id: taskCard
                    localId: model.local_id
                    height: parent.height
                    width: parent.width
                    recordId: model.recordId
                    taskName: model.taskName
                    allocatedHours: model.allocatedHours
                    deadline: model.deadline
                    startDate: model.startDate
                    endDate: model.endDate
                    description: model.description
                    isFavorite: model.isFavorite
                    hasChildren: model.hasChildren
                    childCount: model.childCount
                    projectName: model.project
                    //accountId:model.account_id

                    onEditRequested: id => {
                        console.log("Edit Task:", local_id);
                        taskEditRequested(local_id);
                    }
                    onDeleteRequested: d => {
                        console.log("Edit Task:", local_id);
                        taskDeleteRequested(local_id);
                    }
                    onViewRequested: d => {
                        console.log("View Task:", local_id);
                        taskSelected(local_id);
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: model.hasChildren
                        onClicked: {
                            if (model.hasChildren) {
                                console.log("Navigating into task:", model.taskName, "→", model.id_val);
                                navigationStackModel.append({
                                    parentId: currentParentId
                                });
                                currentParentId = model.id_val;
                            } else {
                                console.log("Selecting task:", model.taskName);
                                // taskNavigator.taskSelected(model.id_val, model.name);
                            }
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: taskNavigator
        onChildrenMapReadyChanged: {
            if (childrenMapReady) {
                console.log("childrenMap is ready → assigning task model");
                taskListView.model = getCurrentModel();
            }
        }
    }

    onCurrentParentIdChanged: {
        if (childrenMapReady) {
            console.log("currentParentId changed →", currentParentId);
            taskListView.model = getCurrentModel();
        }
    }

    Component.onCompleted: {
        populateTaskChildrenMap(true);
    }
}
