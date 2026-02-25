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
    
    // Pagination properties
    property int pageSize: 30
    property int currentOffset: 0
    property bool hasMoreItems: true
    property bool isLoadingMore: false

    onCurrentParentIdChanged: {
        currentOffset = 0;
        hasMoreItems = true;
        _doPopulateTaskChildrenMap();
    }

    // Optional delegate for external data loading (function(limit, offset))
    property var loadDelegate: null

    // Add properties for filtering and searching
    property string currentFilter: "today"  // Set default filter to "today"
    property string currentSearchQuery: ""

    // Properties for project filtering
    property bool filterByProject: false
    property int projectOdooRecordId: -1
    property int projectAccountId: -1

    property bool filterByAccount: false
    property int selectedAccountId: accountPicker.selectedAccountId

    // Properties for assignee filtering
    property bool filterByAssignees: false
    property var selectedAssigneeIds: []

    // Properties for "My Items" filter (assigned to OR created by current user)
    property bool filterByMyItems: false
    property var myItemsUserIds: []

    // Property to indicate if we're in MyTasks context
    property bool isMyTasksContext: false

    // View mode properties
    property bool flatViewMode: false

    // Loading state property
    property bool isLoading: false

    signal taskSelected(int recordId)
    signal taskEditRequested(int recordId)
    signal taskDeleteRequested(int recordId)
    signal taskTimesheetRequested(int localId)

    Connections {
        target: accountPicker

        onAccepted: function (id, name) {
            selectedAccountId = id;
            refresh();
        }
    }

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
        currentFilter = "all";
        currentSearchQuery = "";

        refreshWithFilter();
    }

    // Add combined project and time filter method
    function applyProjectAndTimeFilter(projectOdooId, accountId, timeFilter) {
        filterByProject = true;
        projectOdooRecordId = projectOdooId;
        projectAccountId = accountId;
        currentFilter = timeFilter;
        currentSearchQuery = "";

        refreshWithFilter();
    }

    // Add combined project and search filter method
    function applyProjectAndSearchFilter(projectOdooId, accountId, searchQuery) {
        filterByProject = true;
        projectOdooRecordId = projectOdooId;
        projectAccountId = accountId;
        currentSearchQuery = searchQuery;

        refreshWithFilter();
    }

    // Paginated loading function for assignee-filtered tasks (with optional project filter)
    function _doPaginatedAssigneeLoad() {
        var filterType = (currentFilter && currentFilter !== "") ? currentFilter : "all";
        var searchQuery = (currentSearchQuery && currentSearchQuery.trim() !== "") ? currentSearchQuery : "";
        var accountParam = filterByAccount && selectedAccountId >= 0 ? selectedAccountId : -1;
        var projectParam = (filterByProject && projectOdooRecordId > 0) ? projectOdooRecordId : undefined;

        var result = Task.getTasksByAssigneesPaginated(
            selectedAssigneeIds, accountParam, filterType, searchQuery,
            pageSize, currentOffset, projectParam);

        var tasks = result.tasks;
        hasMoreItems = result.hasMore;

        updateDisplayedTasks(tasks, isLoadingMore);
        isLoadingMore = false;
        isLoading = false;
    }

    // Paginated loading function for "My Items" filter (assigned to OR created by current user)
    function _doPaginatedMyItemsLoad() {
        var filterType = (currentFilter && currentFilter !== "") ? currentFilter : "all";
        var searchQuery = (currentSearchQuery && currentSearchQuery.trim() !== "") ? currentSearchQuery : "";
        var accountParam = filterByAccount && selectedAccountId >= 0 ? selectedAccountId : -1;
        var projectParam = (filterByProject && projectOdooRecordId > 0) ? projectOdooRecordId : undefined;

        var result = Task.getMyItemsTasksPaginated(
            myItemsUserIds, accountParam, filterType, searchQuery,
            pageSize, currentOffset, projectParam);

        var tasks = result.tasks;
        hasMoreItems = result.hasMore;

        updateDisplayedTasks(tasks, isLoadingMore);
        isLoadingMore = false;
        isLoading = false;
    }

    // Paginated loading function for project-filtered tasks
    function _doPaginatedProjectLoad() {
        var filterType = (currentFilter && currentFilter !== "") ? currentFilter : "all";
        var searchQuery = (currentSearchQuery && currentSearchQuery.trim() !== "") ? currentSearchQuery : "";

        var result = Task.getTasksForProjectPaginated(
            projectOdooRecordId, projectAccountId, pageSize, currentOffset,
            filterType, searchQuery);
        
        var tasks = result.tasks;
        hasMoreItems = result.hasMore;

        updateDisplayedTasks(tasks, isLoadingMore);
        isLoadingMore = false;
        isLoading = false;
    }

    // New function to get tasks for a specific project
    function getTasksForProject(projectOdooId, accountId) {
        return Task.getTasksForProject(projectOdooId, accountId);
    }

    // Helper function to parse comma-separated user IDs
    function parseUserIds(userIdValue) {
        var userIds = [];
        if (userIdValue) {
            if (typeof userIdValue === 'string' && userIdValue.indexOf(',') >= 0) {
                // Handle comma-separated IDs like "9,13" or "13,11"
                var userIdParts = userIdValue.split(',');
                for (var i = 0; i < userIdParts.length; i++) {
                    var parsedId = parseInt(userIdParts[i].trim());
                    if (!isNaN(parsedId)) {
                        userIds.push(parsedId);
                    }
                }
            } else {
                // Single ID (number or string)
                var parsedId = parseInt(userIdValue);
                if (!isNaN(parsedId)) {
                    userIds.push(parsedId);
                }
            }
        }
        return userIds;
    }

    // Helper function to apply assignee filter with hierarchy preservation
    function applyAssigneeFilterWithHierarchy(tasks, selectedAssigneeIds) {
        var matchingTaskIds = new Set();
        var taskById = {};
        var tasksByParent = {};

        // Create lookup maps
        for (var i = 0; i < tasks.length; i++) {
            var task = tasks[i];
            var compositeId = task.odoo_record_id + "_" + task.account_id;
            taskById[compositeId] = task;

            var parentId = (task.parent_id === null || task.parent_id === 0) ? -1 : task.parent_id;
            var parentCompositeId = parentId + "_" + task.account_id;

            if (!tasksByParent[parentCompositeId]) {
                tasksByParent[parentCompositeId] = [];
            }
            tasksByParent[parentCompositeId].push(task);
        }

        // First pass: Find tasks that directly match the assignee filter
        for (var i = 0; i < tasks.length; i++) {
            var task = tasks[i];
            var matchesSelectedAssignee = false;

            for (var j = 0; j < selectedAssigneeIds.length; j++) {
                var selectedId = selectedAssigneeIds[j];

                // Handle both simple ID (old format) and composite format
                if (typeof selectedId === 'object' && selectedId !== null) {
                    // New format: {user_id: X, account_id: Y}
                    var taskUserIds = parseUserIds(task.user_id);
                    var taskAccountId = task.account_id ? parseInt(task.account_id) : null;
                    var selectedUserId = selectedId.user_id ? parseInt(selectedId.user_id) : null;
                    var selectedAccountId = selectedId.account_id ? parseInt(selectedId.account_id) : null;

                    if (taskUserIds.length > 0 && taskAccountId !== null && selectedUserId !== null && selectedAccountId !== null && taskUserIds.indexOf(selectedUserId) >= 0 && taskAccountId === selectedAccountId) {
                        matchesSelectedAssignee = true;
                        break;
                    }
                } else {
                    // Legacy format: just user_id (for backward compatibility)
                    var taskUserIds = parseUserIds(task.user_id);
                    var selectedUserId = selectedId ? parseInt(selectedId) : null;

                    if (taskUserIds.length > 0 && selectedUserId !== null && taskUserIds.indexOf(selectedUserId) >= 0) {
                        matchesSelectedAssignee = true;
                        break;
                    }
                }
            }

            if (matchesSelectedAssignee) {
                var compositeId = task.odoo_record_id + "_" + task.account_id;
                matchingTaskIds.add(compositeId);
                //console.log("TaskList: Direct match found for task:", task.name, "ID:", compositeId);
            }
        }

        // Second pass: Include parent tasks for matched tasks to maintain hierarchy
        var toProcess = Array.from(matchingTaskIds);
        for (var i = 0; i < toProcess.length; i++) {
            var compositeId = toProcess[i];
            var task = taskById[compositeId];

            if (task && task.parent_id && task.parent_id !== 0) {
                var parentCompositeId = task.parent_id + "_" + task.account_id;
                var parentTask = taskById[parentCompositeId];

                if (parentTask && !matchingTaskIds.has(parentCompositeId)) {
                    matchingTaskIds.add(parentCompositeId);
                    toProcess.push(parentCompositeId); // Continue up the hierarchy
                    //console.log("TaskList: Adding parent task for hierarchy:", parentTask.name, "ID:", parentCompositeId);
                }
            }
        }

        // Build final filtered tasks list
        var filteredTasks = [];
        for (var i = 0; i < tasks.length; i++) {
            var task = tasks[i];
            var compositeId = task.odoo_record_id + "_" + task.account_id;

            if (matchingTaskIds.has(compositeId)) {
                filteredTasks.push(task);
            }
        }

        //console.log("TaskList: Hierarchical filter result - matched tasks:", matchingTaskIds.size, "final count:", filteredTasks.length);
        return filteredTasks;
    }

    // Timer for deferred loading - gives UI time to render loading indicator
    Timer {
        id: refreshTimer
        interval: 50  // 50ms delay to ensure UI renders
        repeat: false
        onTriggered: _doRefreshWithFilter()
    }

    function refreshWithFilter() {
        isLoading = true;
        // Use Timer to defer the actual data loading,
        // giving QML time to render the loading indicator first
        refreshTimer.start();
    }

    function _doRefreshWithFilter() {
        // Reset pagination state for a fresh load (filter/search changed)
        currentOffset = 0;
        hasMoreItems = true;
        isLoadingMore = false;

        // Restore from global state if assignee filter is enabled but IDs are missing
        if (filterByAssignees && selectedAssigneeIds.length === 0) {
            // Try to restore from global state - we need to access the Global object from TaskList
            // Since TaskList doesn't import Global, we'll let Task_Page handle this restoration
        }

        if (filterByMyItems && myItemsUserIds.length > 0) {
            // My Items filter takes priority — uses user_id OR create_uid matching
            _doPaginatedMyItemsLoad();
        } else if (filterByAssignees && selectedAssigneeIds.length > 0) {
            // Use paginated assignee filtering (SQL-level LIMIT/OFFSET)
            _doPaginatedAssigneeLoad();
        } else if (filterByProject) {
            // Use paginated project loading
            _doPaginatedProjectLoad();
        } else {
            // Use paginated loading with proper date/search filtering for all other cases
            _doPaginatedLoad();
        }
    }

    // New function for paginated loading with date/search filtering
    function _doPaginatedLoad() {
        // Use delegate if provided
        if (loadDelegate) {
            loadDelegate(pageSize, currentOffset);
            return;
        }

        var acc = filterByAccount && selectedAccountId >= 0 ? selectedAccountId : (accountPicker.selectedAccountId >= 0 ? accountPicker.selectedAccountId : -1);
        
        // Use the new paginated function that handles date/search filtering correctly
        var result = Task.getFilteredTasksPaginated(currentFilter, currentSearchQuery, acc, pageSize, currentOffset);
        
        var tasks = result.tasks;
        hasMoreItems = result.hasMore && tasks.length >= pageSize;
        
        // Pass isLoadingMore as 'append' argument
        updateDisplayedTasks(tasks, isLoadingMore);
        
        isLoadingMore = false;
    }

    function applyAccountFilter(accountId) {
        filterByAccount = (accountId >= 0);
        selectedAccountId = accountId;
        filterByProject = false;

        refreshWithFilter();
    }

    function toggleFlatView() {
        flatViewMode = !flatViewMode;
        
        // Reset navigation when switching modes
        if (flatViewMode) {
            navigationStackModel.clear();
            currentParentId = -1;
        }
        
        // Refresh the model
        if (childrenMapReady) {
            taskListView.model = getCurrentModel();
        }
    }

    // Function to remove a task from the displayed list
    function removeTaskFromList(localId) {
        // Find the task in the current parent's children
        var currentModel = childrenMap[currentParentId];
        if (!currentModel)
            return;

        // childrenMap contains ListModel objects, not arrays
        // Use ListModel.count and ListModel.get() to iterate
        var indexToRemove = -1;
        for (var i = 0; i < currentModel.count; i++) {
            var item = currentModel.get(i);
            if (item.local_id === localId) {
                indexToRemove = i;
                break;
            }
        }

        if (indexToRemove >= 0) {
            // Remove from the ListModel using its API
            currentModel.remove(indexToRemove);
        }
    }

    // New function to update displayed tasks with filtered data
    function updateDisplayedTasks(tasks, append) {
        if (!append) {
            childrenMap = {};
            childrenMapReady = false;
        }

        if (tasks.length === 0) {
            if (!append) childrenMapReady = true;
            isLoading = false;
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
                last_modified: row.last_modified || "",
                has_draft: row.has_draft === 1
            };

            if (!tempMap[parentOdooId])
                tempMap[parentOdooId] = [];
            tempMap[parentOdooId].push(item);
        });

        // Build a set of all task IDs present in this batch (and existing data for append)
        var knownTaskIds = {};
        for (var parentKey in tempMap) {
            tempMap[parentKey].forEach(function (item) {
                knownTaskIds[item.id_val] = true;
            });
        }
        if (append) {
            // In append mode, parents from previous pages are already in childrenMap
            for (var existingKey in childrenMap) {
                var existingModel = childrenMap[existingKey];
                for (var m = 0; m < existingModel.count; m++) {
                    knownTaskIds[existingModel.get(m).id_val] = true;
                }
            }
        }

        // Promote orphaned children to root level:
        // If a task's parent is not in the known set, display it at root (-1)
        var orphanedParentKeys = [];
        for (var pKey in tempMap) {
            var numKey = parseInt(pKey);
            if (numKey !== -1 && !knownTaskIds[numKey]) {
                orphanedParentKeys.push(pKey);
            }
        }
        for (var oi = 0; oi < orphanedParentKeys.length; oi++) {
            var opKey = orphanedParentKeys[oi];
            if (!tempMap[-1]) tempMap[-1] = [];
            for (var ci = 0; ci < tempMap[opKey].length; ci++) {
                tempMap[opKey][ci].parent_id = -1;
                tempMap[-1].push(tempMap[opKey][ci]);
            }
            delete tempMap[opKey];
        }

        // Mark children
        for (var parent in tempMap) {
            tempMap[parent].forEach(function (child) {
                var children = tempMap[child.id_val];
                child.hasChildren = !!children;
                child.childCount = children ? children.length : 0;
            });
        }

        // Create or Update QML ListModels
        for (var key in tempMap) {
            var model = childrenMap[key];
            if (!model) {
                model = Qt.createQmlObject('import QtQuick 2.0; ListModel {}', taskNavigator);
                childrenMap[key] = model;
            }
            tempMap[key].forEach(function (entry) {
                model.append(entry);
            });
        }

        childrenMapReady = true;
        
        // Force update of the ListView model binding
        taskListView.model = getCurrentModel();
        
        isLoading = false;
    }

    function refresh() {
        isLoading = true;
        navigationStackModel.clear();
        currentParentId = -1;
        
        // Reset pagination
        currentOffset = 0;
        hasMoreItems = true;
        isLoadingMore = false;

        currentFilter = "today";  // Reset to default filter
        currentSearchQuery = "";
        refreshWithFilter();  // Use refreshWithFilter to apply the default filter
    }

    // Timer for populating task children map
    Timer {
        id: populateTimer
        interval: 50  // 50ms delay to ensure UI renders
        repeat: false
        onTriggered: _doPopulateTaskChildrenMap()
    }

    function populateTaskChildrenMap() {
        isLoading = true;
        childrenMap = {};
        childrenMapReady = false;
        // Use Timer to defer the actual data loading
        populateTimer.start();
    }

    function loadMoreTasks() {
        if (isLoadingMore || !hasMoreItems) return;
        isLoadingMore = true;
        currentOffset += pageSize;
        // Route to proper paginated loader based on context
        if (filterByMyItems && myItemsUserIds && myItemsUserIds.length > 0) {
            _doPaginatedMyItemsLoad();
        } else if (filterByAssignees && selectedAssigneeIds && selectedAssigneeIds.length > 0) {
            _doPaginatedAssigneeLoad();
        } else if (filterByProject) {
            _doPaginatedProjectLoad();
        } else {
            _doPaginatedLoad();
        }
    }

    function _doPopulateTaskChildrenMap() {
        // If not loading more, we are resetting/refreshing
        // updateDisplayedTasks will handle clearing if append=false
        
        // Use delegate if provided
        if (loadDelegate) {
            loadDelegate(pageSize, currentOffset);
            // Delegate is responsible for calling updateDisplayedTasks and managing hasMoreItems/isLoading flags
            return;
        }
        
        var tasks = [];
        // This function is now only called for "all" filter or when no date filter is active
        // So we can always paginate when we reach this point
        var canPaginate = !currentSearchQuery && (!selectedAssigneeIds || selectedAssigneeIds.length === 0) && !filterByProject;

        if (canPaginate) {
             // Pagination Logic - no date filter needed since we only paginate for "all" filter
             if (flatViewMode) {
                 var acc = accountPicker.selectedAccountId;
                 if (acc >= 0) tasks = Task.getAllTasksForAccountPaginated(acc, pageSize, currentOffset);
                 else tasks = Task.getAllTasksPaginated(pageSize, currentOffset);
             } else {
                 var acc = accountPicker.selectedAccountId;
                 if (typeof acc === "undefined") acc = -1;
                 // Handle Parent ID
                 var pid = currentParentId;
                 tasks = Task.getTasksByParentIdPaginated(pid, acc, pageSize, currentOffset);
             }
             
             if (tasks.length < pageSize) hasMoreItems = false;
             
             // Pass isLoadingMore as 'append' argument
             updateDisplayedTasks(tasks, isLoadingMore);
             
             // If we loaded a page and got NOTHING, but we are supposed to be paginating...
             // It implies empty folder or empty account.
             // hasMoreItems set to false correctly.
             
        } else {
             // Legacy / Full Load path
             hasMoreItems = false;
             
             // Revert to original logic: Load all tasks for account (or all accounts)
             // Note: Original code used Task.getAllTasksForAccount(accountPicker.selectedAccountId)
             // But we suspect it might have issues with -1. We'll use the robust logic from Task.js
             
             var allTasks;
             var acc = accountPicker.selectedAccountId;
             
             if (acc >= 0) {
                 allTasks = Task.getAllTasksForAccount(acc);
             } else {
                 allTasks = Task.getAllTasks();
             }
             
             updateDisplayedTasks(allTasks, false); // Always reset in legacy mode
        }
        
        isLoadingMore = false;
        // isLoading = false; // handled in updateDisplayedTasks
    }

    function getCurrentModel() {
        // Flat view mode: return all tasks in a single flat list
        if (flatViewMode) {
            var flatModel = Qt.createQmlObject('import QtQuick 2.0; ListModel {}', taskNavigator);
            var allFlatTasks = [];
            
            // Collect all tasks from childrenMap
            for (var key in childrenMap) {
                var model = childrenMap[key];
                for (var i = 0; i < model.count; i++) {
                    allFlatTasks.push(model.get(i));
                }
            }
            
            // Sort by end date (most recent first), then alphabetically by name
            allFlatTasks.sort(function(a, b) {
                if (a.endDate && b.endDate) {
                    return new Date(a.endDate) - new Date(b.endDate);
                }
                if (a.endDate && !b.endDate) return -1;
                if (!a.endDate && b.endDate) return 1;
                return a.taskName.localeCompare(b.taskName);
            });
            
            // Add all tasks to the flat model
            allFlatTasks.forEach(function(task) {
                flatModel.append(task);
            });
            
            return flatModel;
        }
        
        // Hierarchical view: return tasks for current parent
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
            visible: !flatViewMode && navigationStackModel.count
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

            footer: LoadMoreFooter {
                isLoading: isLoadingMore
                hasMore: hasMoreItems
                onLoadMore: loadMoreTasks()
            }

            onAtYEndChanged: {
                if (taskListView.atYEnd && !isLoadingMore && hasMoreItems) {
                    loadMoreTasks();
                }
            }

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
                    // Hide children navigation in flat view mode
                    hasChildren: flatViewMode ? false : (model.hasChildren || false)
                    childCount: flatViewMode ? 0 : (model.childCount || 0)
                    projectName: model.project
                    colorPallet: model.color_pallet
                    stage: model.stage
                    accountId: model.account_id
                    isMyTasksContext: taskNavigator.isMyTasksContext
                    hasDraft: model.has_draft || false

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
                    onTaskStageChanged: localId => {
                        // Remove the task from the current list display
                        removeTaskFromList(localId);
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
                            // In flat view mode, always go to task view (no navigation)
                            if (flatViewMode) {
                                taskCard.viewRequested(model.local_id);
                            } else if (model.hasChildren) {
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



    Component.onCompleted: {
        if (filterByProject && projectOdooRecordId !== -1) {
            applyProjectFilter(projectOdooRecordId, projectAccountId);
        } else {
            refreshWithFilter();  // Use refreshWithFilter to apply default "today" filter
        }
    }
}
