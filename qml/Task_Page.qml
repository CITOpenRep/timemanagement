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

import QtQuick 2.9
import QtQuick.Controls 2.2
import Lomiri.Components 1.3
import QtQuick.Window 2.2
import QtQml.Models 2.3
import "../models/timesheet.js" as Model
import "../models/timesheet.js" as Timesheet
import "../models/project.js" as Project
import "../models/task.js" as Task
import "../models/utils.js" as Utils
import "../models/accounts.js" as Account
import "../models/global.js" as Global
import "components"

Page {
    id: task
    title: i18n.dtr("ubtms", "All Tasks")

    header: PageHeader {
        id: taskheader
        StyleHints {
            foregroundColor: "white"
            backgroundColor: LomiriColors.orange
            dividerColor: LomiriColors.slate
        }
        title: {
            var titleParts = ["Tasks"];
            if (filterByProject && projectName) {
                titleParts.push(projectName);
            }
            return titleParts.join(" - ");
        }

        trailingActionBar.numberOfSlots: 5

        trailingActionBar.actions: [
            Action {
                iconName: "add"
                text: "New"
                onTriggered: {
                    apLayout.addPageToNextColumn(task, Qt.resolvedUrl("Tasks.qml"), {
                        "recordid": 0,
                        "isReadOnly": false
                    });
                }
            },
             Action {
                iconName: tasklist.flatViewMode ? "view-list-symbolic" : "view-grid-symbolic"
                text: tasklist.flatViewMode ? i18n.dtr("ubtms", "Tree View") : i18n.dtr("ubtms", "Flat View")
                onTriggered: {
                    tasklist.toggleFlatView();
                }
            },
            Action {
                iconName: "search"
                text: "Search"
                onTriggered: {
                    taskListHeader.toggleSearchVisibility();
                }
            },
            Action {
                iconName: task.filterByMyItems ? "contact" : "contact-group"
                text: task.filterByMyItems
                    ? i18n.dtr("ubtms", "My Items")
                    : i18n.dtr("ubtms", "All Items")
                onTriggered: {
                    toggleMyItemsFilter();
                }
            },
            Action {
                
                iconSource: task.filterByAssignees ? Qt.resolvedUrl("images/filter.png") : Qt.resolvedUrl("images/filter-assignee.png")
                text: task.filterByAssignees
                    ? i18n.dtr("ubtms", "Assignees") + " (" + task.selectedAssigneeIds.length + ")"
                    : i18n.dtr("ubtms", "Filter by Assignees")
                onTriggered: {
                    assigneeFilterMenu.expanded = !assigneeFilterMenu.expanded;
                }
            }
          

        ]
    }

    // Add properties to track filter and search state
    property string currentFilter: "today"
    property string currentSearchQuery: ""

    // Properties for project filtering
    property bool filterByProject: false
    property int projectOdooRecordId: -1
    property int projectAccountId: -1
    property string projectName: ""

    // Properties for assignee filtering
    property bool filterByAssignees: false
    property var selectedAssigneeIds: []
    property var availableAssignees: []

    // Properties for "My Items" filter (shows items assigned to OR created by current user)
    property bool filterByMyItems: true  // ON by default
    property var myItemsUserIds: []  // Populated from getCurrentUserAssigneeIds

    // SEPARATED CONCERNS:
    // selectedAccountId - ONLY for filtering/viewing data (from account selector)
    // defaultAccountId - ONLY for creating new records (from default account setting)
    // Use variant so we can hold number or string temporarily, but we will always set numeric values
    property variant selectedAccountId: -1 // initialize with numeric -1 (All accounts)
    property variant defaultAccountId: Account.getDefaultAccountId() // For creating records (DO NOT use for filtering)

    // Function to load available assignees for the current account
    function loadAssignees() {
        try {
            var currentAccountId = tasklist.selectedAccountId;
            if (typeof currentAccountId === "undefined" || currentAccountId === null)
                currentAccountId = -1;

            // When filtering by project, use the project's account for assignee loading
            if (filterByProject && projectAccountId >= 0) {
                // Use the project's account to load assignees
                var rawAssignees = Account.getUsers(projectAccountId);

                // Filter and format assignees like MultiAssigneeSelector does
                var filteredAssignees = [];
                for (var i = 0; i < rawAssignees.length; i++) {
                    var assignee = rawAssignees[i];
                    var id = (projectAccountId === 0) ? assignee.id : assignee.odoo_record_id;
                    if (id > 0) {
                        // Skip invalid/placeholder entries
                        filteredAssignees.push({
                            id: id,
                            odoo_record_id: id,
                            name: assignee.name,
                            account_name: assignee.account_name || "",
                            account_id: projectAccountId
                        });
                    }
                }

                availableAssignees = filteredAssignees;
                assigneeFilterMenu.assigneeModel = availableAssignees;
            } else if (currentAccountId >= 0) {
                // Use the same method as MultiAssigneeSelector for specific account
                var rawAssignees = Account.getUsers(currentAccountId);

                // Filter and format assignees like MultiAssigneeSelector does
                var filteredAssignees = [];
                for (var i = 0; i < rawAssignees.length; i++) {
                    var assignee = rawAssignees[i];
                    var id = (currentAccountId === 0) ? assignee.id : assignee.odoo_record_id;
                    if (id > 0) {
                        // Skip invalid/placeholder entries
                        filteredAssignees.push({
                            id: id,
                            odoo_record_id: id,
                            name: assignee.name,
                            account_name: assignee.account_name || "",
                            account_id: currentAccountId
                        });
                    }
                }

                availableAssignees = filteredAssignees;
                assigneeFilterMenu.assigneeModel = availableAssignees;
            } else {
                // For "All Accounts" (-1), load assignees from all accounts that have tasks

                availableAssignees = Task.getAllTaskAssignees(-1); // -1 means all accounts
                assigneeFilterMenu.assigneeModel = availableAssignees;
            }
        } catch (e) {
            console.error("Error loading assignees:", e);
            availableAssignees = [];
            assigneeFilterMenu.assigneeModel = [];
        }
    }

    // Function to restore assignee filter state from global storage
    function restoreAssigneeFilterState() {
        var globalFilter = Global.getAssigneeFilter();

        if (globalFilter.enabled && globalFilter.assigneeIds.length > 0) {
            task.filterByAssignees = true;
            task.selectedAssigneeIds = globalFilter.assigneeIds;
            tasklist.filterByAssignees = true;
            tasklist.selectedAssigneeIds = globalFilter.assigneeIds;
        } else if (!globalFilter.enabled) {
            task.filterByAssignees = false;
            task.selectedAssigneeIds = [];
            tasklist.filterByAssignees = false;
            tasklist.selectedAssigneeIds = [];
        }
    }

    // Populate myItemsUserIds from the current user's account info
    function loadMyItemsUserIds() {
        var currentAccountId = tasklist.selectedAccountId;
        var userIds = Account.getCurrentUserAssigneeIds(
            (typeof currentAccountId !== "undefined" && currentAccountId !== null) ? currentAccountId : -1
        );
        myItemsUserIds = (userIds && userIds.length > 0) ? userIds : [];
    }

    // Toggle the "My Items" filter on/off. Mutually exclusive with Assignee Filter.
    function toggleMyItemsFilter() {
        if (task.filterByMyItems) {
            // Turning OFF My Items — show all items
            task.filterByMyItems = false;
            Global.setMyItemsFilter(false);

            // Update TaskList
            tasklist.filterByMyItems = false;
            tasklist.myItemsUserIds = [];
        } else {
            // Turning ON My Items — disable Assignee Filter first (mutually exclusive)
            task.filterByAssignees = false;
            task.selectedAssigneeIds = [];
            assigneeFilterMenu.selectedAssigneeIds = [];
            Global.clearAssigneeFilter();
            tasklist.filterByAssignees = false;
            tasklist.selectedAssigneeIds = [];

            // Enable My Items
            task.filterByMyItems = true;
            Global.setMyItemsFilter(true);
            loadMyItemsUserIds();

            tasklist.filterByMyItems = true;
            tasklist.myItemsUserIds = myItemsUserIds;
        }

        // Refresh task list
        _refreshTaskList();
    }

    // Restore My Items filter state from global storage
    function restoreMyItemsFilterState() {
        var enabled = Global.getMyItemsFilter();
        task.filterByMyItems = enabled;
        if (enabled) {
            loadMyItemsUserIds();
            tasklist.filterByMyItems = true;
            tasklist.myItemsUserIds = myItemsUserIds;
        } else {
            tasklist.filterByMyItems = false;
            tasklist.myItemsUserIds = [];
        }
    }

    // Helper to refresh the task list with the current filter/search/project state
    function _refreshTaskList() {
        if (filterByProject) {
            if (currentSearchQuery) {
                tasklist.applyProjectAndSearchFilter(projectOdooRecordId, projectAccountId, currentSearchQuery);
            } else {
                tasklist.applyProjectAndTimeFilter(projectOdooRecordId, projectAccountId, currentFilter);
            }
        } else {
            if (currentSearchQuery) {
                tasklist.applySearch(currentSearchQuery);
            } else {
                tasklist.applyFilter(currentFilter);
            }
        }
    }

    // Add the ListHeader component
    ListHeader {
        id: taskListHeader
        anchors.top: taskheader.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        label1: i18n.dtr("ubtms", "Today")
        label2: i18n.dtr("ubtms", "This Week")
        label3: i18n.dtr("ubtms", "This Month")
        label4: i18n.dtr("ubtms", "Later")
        label5: i18n.dtr("ubtms", "Done")
        label6: i18n.dtr("ubtms", "All")
        label7: ""

        filter1: "today"
        filter2: "this_week"
        filter3: "this_month"
        filter4: "later"
        filter5: "done"
        filter6: "all"
        filter7: ""

        showSearchBox: false
        currentFilter: task.currentFilter

        onFilterSelected: {
            task.currentFilter = filterKey;

            // Restore filter states from global storage
            restoreMyItemsFilterState();
            if (!task.filterByMyItems) {
                restoreAssigneeFilterState();
            }

            // Ensure TaskList properties are synchronized after restoration
            tasklist.filterByAssignees = task.filterByAssignees;
            tasklist.selectedAssigneeIds = task.selectedAssigneeIds;

            // Apply the appropriate filter with assignee filtering
            if (filterByProject) {
                tasklist.applyProjectAndTimeFilter(projectOdooRecordId, projectAccountId, filterKey);
            } else {
                tasklist.applyFilter(filterKey);
            }
        }

        onCustomSearch: {
            task.currentSearchQuery = query;

            // Restore filter states from global storage
            restoreMyItemsFilterState();
            if (!task.filterByMyItems) {
                restoreAssigneeFilterState();
            }

            // Ensure TaskList properties are synchronized after restoration
            tasklist.filterByAssignees = task.filterByAssignees;
            tasklist.selectedAssigneeIds = task.selectedAssigneeIds;

            //console.log("   Final TaskList state for search - filterByAssignees:", tasklist.filterByAssignees, "selectedAssigneeIds:", JSON.stringify(tasklist.selectedAssigneeIds));

            // Apply search with assignee filtering
            if (filterByProject) {
                //console.log("   Applying project and search filter:", query);
                tasklist.applyProjectAndSearchFilter(projectOdooRecordId, projectAccountId, query);
            } else {
                tasklist.applySearch(query);
            }
        }
    }

    LomiriShape {
        anchors.top: taskListHeader.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: units.gu(1)
        clip: true

        TaskList {
            id: tasklist
            anchors.fill: parent
            clip: true

            // Pass project filtering parameters
            filterByProject: task.filterByProject
            projectOdooRecordId: task.projectOdooRecordId
            projectAccountId: task.projectAccountId

            // NOTE: selectedAccountId is no longer initialized to default account.
            // It will be set on Component.onCompleted by probing accountFilter,
            // and when the user changes the account in the account selector.
            filterByAccount: true
            // Child component likely expects an int. Initialize to numeric -1.
            selectedAccountId: -1

            onTaskEditRequested: {
                apLayout.addPageToNextColumn(task, Qt.resolvedUrl("Tasks.qml"), {
                    "recordid": recordId,
                    "isReadOnly": false
                });
            }
            onTaskSelected: {
                apLayout.addPageToNextColumn(task, Qt.resolvedUrl("Tasks.qml"), {
                    "recordid": recordId,
                    "isReadOnly": true
                });
            }
            onTaskTimesheetRequested: {
                let result = Timesheet.createTimesheetFromTask(localId);
                if (result.success) {
                    apLayout.addPageToNextColumn(task, Qt.resolvedUrl("Timesheet.qml"), {
                        "recordid": result.id,
                        "isReadOnly": false
                    });
                } else {
                    notifPopup.open("Error", "Unable to create timesheet", "error");
                }
            }
            onTaskDeleteRequested: {
                var check = Task.checkTaskHasChildren(recordId);
                if (check.hasChildren) {
                    notifPopup.open("Blocked", "This task has child tasks. Please delete them first.", "warning");
                } else {
                    var result = Task.markTaskAsDeleted(recordId);
                    if (!result.success) {
                        notifPopup.open("Error", result.message, "error");
                    } else {
                        notifPopup.open("Deleted", result.message, "success");
                        pageStack.removePages(task);
                        apLayout.addPageToCurrentColumn(task, Qt.resolvedUrl("Task_Page.qml"));
                    }
                }
            }
        }

        Text {
            id: labelNoTask
            anchors.centerIn: parent
            font.pixelSize: units.gu(2)
            visible: false
            text: i18n.dtr("ubtms", "No tasks found.")
        }
    }

    NotificationPopup {
        id: notifPopup
        width: units.gu(80)
        height: units.gu(80)
    }

    DialerMenu {
        id: fabMenu
        anchors.fill: parent
        z: 9999
        menuModel: [
            {
                label: i18n.dtr("ubtms", "Task")
            }
        ]
        onMenuItemSelected: {
            if (index === 0) {
                apLayout.addPageToNextColumn(task, Qt.resolvedUrl("Tasks.qml"), {
                    "recordid": 0,
                    "isReadOnly": false
                });
            }
        }
    }

    // Assignee Filter Menu
    AssigneeFilterMenu {
        id: assigneeFilterMenu
        anchors.fill: parent
        z: 10

        onFilterApplied: function (assigneeIds) {
            // Read directly from AssigneeFilterMenu to avoid timing issues
            var actualSelectedIds = assigneeFilterMenu.selectedAssigneeIds;

            selectedAssigneeIds = actualSelectedIds;
            filterByAssignees = (actualSelectedIds && actualSelectedIds.length > 0);

            // Mutual exclusivity: disable My Items when Assignee Filter is applied
            if (filterByAssignees) {
                task.filterByMyItems = false;
                Global.setMyItemsFilter(false);
                tasklist.filterByMyItems = false;
                tasklist.myItemsUserIds = [];
            }

            // Save to global state for persistence across navigation
            Global.setAssigneeFilter(filterByAssignees, actualSelectedIds);

            // Update TaskList properties
            tasklist.filterByAssignees = filterByAssignees;
            tasklist.selectedAssigneeIds = actualSelectedIds;

            // Refresh task list with assignee filter
            _refreshTaskList();
        }

        onFilterCleared: function () {
            selectedAssigneeIds = [];
            filterByAssignees = false;

            // Clear global state
            Global.clearAssigneeFilter();

            // Update TaskList properties
            tasklist.filterByAssignees = false;
            tasklist.selectedAssigneeIds = [];

            // Refresh task list without assignee filter
            _refreshTaskList();
        }
    }

    onVisibleChanged: {
        if (visible) {
            // Check if we're coming from a task-related page
            var previousPage = Global.getLastVisitedPage();
            var shouldPreserve = Global.shouldPreserveFilters("Task_Page", previousPage);

            if (shouldPreserve) {
                // Restore both filter states from global when returning from Tasks detail page
                restoreMyItemsFilterState();
                if (!task.filterByMyItems) {
                    restoreAssigneeFilterState();
                }
                assigneeFilterMenu.selectedAssigneeIds = task.selectedAssigneeIds;
            } else {
                // Coming from non-task page: enable My Items by default, clear assignee filter
                task.filterByMyItems = true;
                Global.setMyItemsFilter(true);
                loadMyItemsUserIds();
                tasklist.filterByMyItems = true;
                tasklist.myItemsUserIds = myItemsUserIds;

                task.filterByAssignees = false;
                task.selectedAssigneeIds = [];
                assigneeFilterMenu.selectedAssigneeIds = [];
                Global.clearAssigneeFilter();
                tasklist.filterByAssignees = false;
                tasklist.selectedAssigneeIds = [];
            }

            // Update navigation tracking
            Global.setLastVisitedPage("Task_Page");

            _refreshTaskList();
        }
    }

    Component.onCompleted: {
        // Determine initial account selection from accountFilter (try common property names),
        // fall back to numeric -1 (All accounts) if none found. This ensures initial list is filtered.
        tasklist.selectedAccountId = accountPicker.selectedAccountId;

        // Load assignees for the assignee filter
        loadAssignees();

        // Apply "My Items" filter by default (replaces applyDefaultAssigneeFilter)
        task.filterByMyItems = true;
        Global.setMyItemsFilter(true);
        loadMyItemsUserIds();
        tasklist.filterByMyItems = true;
        tasklist.myItemsUserIds = myItemsUserIds;

        // Make sure assignee filter starts cleared
        task.filterByAssignees = false;
        task.selectedAssigneeIds = [];
        tasklist.filterByAssignees = false;
        tasklist.selectedAssigneeIds = [];

        if (filterByProject) {
            tasklist.applyProjectAndTimeFilter(projectOdooRecordId, projectAccountId, currentFilter);
        } else {
            tasklist.applyFilter(currentFilter);
        }
    }

    // Loading indicator - forward state from TaskList
    LoadingIndicator {
        anchors.fill: parent
        visible: tasklist.isLoading
        message: i18n.dtr("ubtms", "Loading tasks...")
    }
}
