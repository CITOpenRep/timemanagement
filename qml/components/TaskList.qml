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

    // Properties for project filtering
    property bool filterByProject: false
    property int projectOdooRecordId: -1
    property int projectAccountId: -1

    property bool filterByAccount: false
    property int selectedAccountId: -1

    // Properties for assignee filtering
    property bool filterByAssignees: false
    property var selectedAssigneeIds: []

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

    // Add the applyProjectFilter method
    function applyProjectFilter(projectOdooId, projectAccountId) {
        filterByProject = true;
        projectOdooRecordId = projectOdooId;
        projectAccountId = projectAccountId;
        var projectTasks = getTasksForProject(projectOdooId, projectAccountId);
        updateDisplayedTasks(projectTasks);
    }

    // Add combined project and time filter method
    function applyProjectAndTimeFilter(projectOdooId, accountId, timeFilter) {
        filterByProject = true;
        projectOdooRecordId = projectOdooId;
        projectAccountId = accountId;
        currentFilter = timeFilter;

        // Get project tasks first, then apply filtering
        var projectTasks = getTasksForProject(projectOdooId, accountId);

        // Create a map for quick lookup
        var projectTasksMap = {};
        for (var i = 0; i < projectTasks.length; i++) {
            var key = projectTasks[i].odoo_record_id + "_" + projectTasks[i].account_id;
            projectTasksMap[key] = projectTasks[i];
        }

        // Get filtered tasks and intersect with project tasks
        var allFilteredTasks = Task.getFilteredTasks(timeFilter, "");
        var filteredProjectTasks = [];

        for (var j = 0; j < allFilteredTasks.length; j++) {
            var filteredTask = allFilteredTasks[j];
            var taskKey = filteredTask.odoo_record_id + "_" + filteredTask.account_id;
            if (projectTasksMap[taskKey]) {
                filteredProjectTasks.push(filteredTask);
            }
        }

        updateDisplayedTasks(filteredProjectTasks);
    }

    // Add combined project and search filter method
    function applyProjectAndSearchFilter(projectOdooId, accountId, searchQuery) {
        filterByProject = true;
        projectOdooRecordId = projectOdooId;
        projectAccountId = accountId;
        currentSearchQuery = searchQuery;

        // Get project tasks first, then apply search filtering
        var projectTasks = getTasksForProject(projectOdooId, accountId);

        // Create a map for quick lookup
        var projectTasksMap = {};
        for (var i = 0; i < projectTasks.length; i++) {
            var key = projectTasks[i].odoo_record_id + "_" + projectTasks[i].account_id;
            projectTasksMap[key] = projectTasks[i];
        }

        // Get search filtered tasks and intersect with project tasks
        var allSearchedTasks = Task.getFilteredTasks("all", searchQuery);
        var searchedProjectTasks = [];

        for (var j = 0; j < allSearchedTasks.length; j++) {
            var searchedTask = allSearchedTasks[j];
            var taskKey = searchedTask.odoo_record_id + "_" + searchedTask.account_id;
            if (projectTasksMap[taskKey]) {
                searchedProjectTasks.push(searchedTask);
            }
        }

        updateDisplayedTasks(searchedProjectTasks);
    }

    // New function to get tasks for a specific project
    function getTasksForProject(projectOdooId, accountId) {
        return Task.getTasksForProject(projectOdooId, accountId);
    }

    function refreshWithFilter() {
        if (filterByAssignees && selectedAssigneeIds.length > 0) {
            // Filter by assignees
            var assigneeTasks;
            var accountParam = filterByAccount && selectedAccountId >= 0 ? selectedAccountId : -1;
            assigneeTasks = Task.getTasksByAssignees(selectedAssigneeIds, accountParam, currentFilter, currentSearchQuery);
            updateDisplayedTasks(assigneeTasks);
        } else if (filterByAccount && selectedAccountId >= 0) {
            var accountTasks;
            if (currentFilter === "all" && !currentSearchQuery) {
                accountTasks = Task.getTasksForAccount(selectedAccountId);
            } else {
                accountTasks = Task.getFilteredTasks(currentFilter, currentSearchQuery, selectedAccountId);
            }
            updateDisplayedTasks(accountTasks);
        } else if (currentFilter === "all" && !currentSearchQuery) {
            populateTaskChildrenMap();
        } else if (currentFilter && currentFilter !== "" || currentSearchQuery) {
            var filteredTasks = Task.getFilteredTasks(currentFilter, currentSearchQuery);
            updateDisplayedTasks(filteredTasks);
        } else {
            populateTaskChildrenMap();
        }
    }

    function applyAccountFilter(accountId) {
        console.log("🔍 TaskList.applyAccountFilter called with accountId:", accountId);

        filterByAccount = (accountId >= 0);
        selectedAccountId = accountId;
        filterByProject = false;

        refreshWithFilter();
    }

    function clearAccountFilter() {
        filterByAccount = false;
        selectedAccountId = -1;

        refreshWithFilter();
    }

    // New function to update displayed tasks with filtered data
    function updateDisplayedTasks(tasks) {
        childrenMap = {};
        childrenMapReady = false;

        if (tasks.length === 0) {
            childrenMapReady = true;
            return;
        }

        // Sort tasks by end Date (most recent first)
        tasks.sort(function (a, b) {
            if (!a.end_date || !b.end_date) {
                return (a.name || "").localeCompare(b.name || "");
            }
            return new Date(a.end_date) - new Date(b.end_date);
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
                hasChildren: false,
                stage: row.state || -1,
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
                hasChildren: false,
                stage: row.state || -1,
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
                height: units.gu(15)

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
                    stage: model.stage
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
        if (filterByProject && projectOdooRecordId !== -1) {
            applyProjectFilter(projectOdooRecordId, projectAccountId);
        } else {
            refreshWithFilter();  // Use refreshWithFilter to apply default "today" filter
        }
    }
}
