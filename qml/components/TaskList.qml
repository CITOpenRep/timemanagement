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
import "../../models/task.js" as Task
import "../../models/project.js" as Project
import "." // Import the current directory to make TaskDetailsCard available

Item {
    id: taskNavigator
    anchors.fill: parent

    property int currentParentId: -1
    property ListModel navigationStackModel: ListModel {}
    property var childrenMap: ({})
    property bool childrenMapReady: false

    // Add properties for filtering and searching
    property string currentFilter: "today"  // Set default filter to "today"
    property string currentSearchQuery: ""

    signal taskSelected(int recordId)
    signal taskEditRequested(int recordId)
    signal taskDeleteRequested(int recordId)
    signal taskTimesheetRequested(int localId)

    Connections {
        target: globalTimerWidget

        onTimerStopped: {
            refreshWithFilter(); //lets refresh the list
        }
        onTimerStarted: {
            refreshWithFilter();
        }
    }

    // Add the applyFilter method
    function applyFilter(filterKey) {
        currentFilter = filterKey;
        refreshWithFilter();
    }

    // Add the applySearch method
    function applySearch(searchQuery) {
        currentSearchQuery = searchQuery;
        refreshWithFilter();
    }

    // New function to refresh with filter applied
    function refreshWithFilter() {
        if (currentFilter === "all" && !currentSearchQuery) {
            populateTaskChildrenMap(); // Use original function for "all" filter without search
        } else if (currentFilter && currentFilter !== "" || currentSearchQuery) {
            var filteredTasks = Task.getFilteredTasks(currentFilter, currentSearchQuery);
            updateDisplayedTasks(filteredTasks);
        } else {
            populateTaskChildrenMap(); // Use original function when no filters
        }
    }

    // New function to update displayed tasks with filtered data
    function updateDisplayedTasks(tasks) {
        childrenMap = {};
        childrenMapReady = false;

        if (tasks.length === 0) {
            childrenMapReady = true;
            return;
        }

        // Sort tasks by last_modified (most recent first)
        tasks.sort(function (a, b) {
            if (!a.last_modified || !b.last_modified) {
                return (a.name || "").localeCompare(b.name || "");
            }
            return new Date(b.last_modified) - new Date(a.last_modified);
        });

        var tempMap = {};

        tasks.forEach(function (row) {
            var odooId = row.odoo_record_id;
            var parentOdooId = (row.parent_id === null || row.parent_id === 0) ? -1 : row.parent_id;

            var projectIdToUse = row.project_id;

            if (!projectIdToUse || projectIdToUse === 0) {
                // console.log("Project ID is empty for row id", row.id, "- using sub_project_id:", row.sub_project_id);
                projectIdToUse = row.sub_project_id;
            }

            var projectName = Project.getProjectName(projectIdToUse, row.account_id);

            var item = {
                id_val: odooId,
                local_id: row.id,
                account_id: row.account_id,
                project: projectName,
                parent_id: parentOdooId,
                name: row.name || "Untitled",
                taskName: row.name || "Untitled",
                recordId: odooId,
                allocatedHours: row.initial_planned_hours ? row.initial_planned_hours : 0,
                spentHours: row.spent_hours ? row.spent_hours : 0,
                startDate: row.start_date || "",
                endDate: row.end_date || "",
                deadline: row.deadline || "",
                description: row.description || "",
                isFavorite: row.favorites === 1,
                hasChildren: false,
                color_pallet: row.color_pallet ? parseInt(row.color_pallet) : 0,
                last_modified: row.last_modified || ""
            };

            if (!tempMap[parentOdooId])
                tempMap[parentOdooId] = [];
            tempMap[parentOdooId].push(item);
        });

        // Mark children
        for (var parent in tempMap) {
            tempMap[parent].forEach(function (child) {
                var children = tempMap[child.id_val];
                child.hasChildren = !!children;
                child.childCount = children ? children.length : 0;
            });
        }

        // Create QML ListModels
        for (var key in tempMap) {
            var model = Qt.createQmlObject('import QtQuick 2.0; ListModel {}', taskNavigator);
            tempMap[key].forEach(function (entry) {
                model.append(entry);
            });
            childrenMap[key] = model;
        }

        childrenMapReady = true;
    }

    function refresh() {
        navigationStackModel.clear();
        currentParentId = -1;
        currentFilter = "today";  // Reset to default filter
        currentSearchQuery = "";
        refreshWithFilter();  // Use refreshWithFilter to apply the default filter
    }

    function populateTaskChildrenMap() {
        childrenMap = {};
        childrenMapReady = false;

        var allTasks = Task.getAllTasks(); // import tasks.js as Task

        if (allTasks.length === 0) {
            childrenMapReady = true;
            return;
        }

        // Tasks are already sorted by last_modified in the Task.getAllTasks() SQL query

        var tempMap = {};

        allTasks.forEach(function (row) {
            var odooId = row.odoo_record_id;
            var parentOdooId = (row.parent_id === null || row.parent_id === 0) ? -1 : row.parent_id;

            var projectName = Project.getProjectName(row.project_id, row.account_id); // import projects.js as Project

            var item = {
                id_val: odooId,
                local_id: row.id,
                account_id: row.account_id,
                project: projectName,
                parent_id: parentOdooId,
                name: row.name || "Untitled",
                taskName: row.name || "Untitled",
                recordId: odooId,
                allocatedHours: row.initial_planned_hours ? row.initial_planned_hours : 0,
                spentHours: row.spent_hours ? row.spent_hours : 0,
                startDate: row.start_date || "",
                endDate: row.end_date || "",
                deadline: row.deadline || "",
                description: row.description || "",
                isFavorite: row.favorites === 1,
                hasChildren: false,
                color_pallet: row.color_pallet ? parseInt(row.color_pallet) : 0,
                last_modified: row.last_modified || ""
            };

            if (!tempMap[parentOdooId])
                tempMap[parentOdooId] = [];
            tempMap[parentOdooId].push(item);
        });

        // Mark children
        for (var parent in tempMap) {
            tempMap[parent].forEach(function (child) {
                var children = tempMap[child.id_val];
                child.hasChildren = !!children;
                child.childCount = children ? children.length : 0;
            });
        }

        // Create QML ListModels
        for (var key in tempMap) {
            var model = Qt.createQmlObject('import QtQuick 2.0; ListModel {}', taskNavigator);
            tempMap[key].forEach(function (entry) {
                model.append(entry);
            });
            childrenMap[key] = model;
        }

        childrenMapReady = true;
    }

    function getCurrentModel() {
        var model = childrenMap[currentParentId];
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
                height: units.gu(12)

                TaskDetailsCard {
                    id: taskCard
                    localId: model.local_id
                    height: parent.height
                    width: parent.width
                    recordId: (model.recordId) ? (model.recordId) : -1
                    taskName: model.taskName
                    allocatedHours: model.allocatedHours
                    spentHours: model.spentHours
                    deadline: model.deadline
                    startDate: model.startDate
                    endDate: model.endDate
                    description: model.description
                    priority: model.priority // Use priority instead of isFavorite
                    hasChildren: model.hasChildren
                    childCount: model.childCount
                    projectName: model.project
                    colorPallet: model.color_pallet
                    //accountId:model.account_id

                    onEditRequested: id => {
                        taskEditRequested(local_id);
                    }
                    onDeleteRequested: d => {
                        taskDeleteRequested(local_id);
                    }
                    onViewRequested: d => {
                        taskSelected(local_id);
                    }
                    onTimesheetRequested: localId => {
                        taskTimesheetRequested(localId);
                    }

                    // MouseArea for task interaction - navigation for parent tasks, view for regular tasks
                    MouseArea {
                        // Only cover the text area, not the whole card
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: units.gu(15)  // Skip the star area
                        enabled: !taskCard.starInteractionActive
                        onClicked: {
                            if (model.hasChildren) {
                              
                                navigationStackModel.append({
                                    parentId: currentParentId
                                });
                                currentParentId = model.id_val;
                            } else {
                               
                                taskCard.viewRequested(model.local_id);
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
                taskListView.model = getCurrentModel();
            }
        }
    }

    onCurrentParentIdChanged: {
        if (childrenMapReady) {
            taskListView.model = getCurrentModel();
        }
    }

    Component.onCompleted: {
        refreshWithFilter();  // Use refreshWithFilter to apply default "today" filter
    }
}
