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
    title: "Tasks"

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
                iconName: "search"
                text: "Search"
                onTriggered: {
                    taskListHeader.toggleSearchVisibility();
                }
            },
            Action {
                iconName: "account"
                onTriggered: {
                    accountFilterVisible = !accountFilterVisible;
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

            console.log("Loading assignees for account ID:", currentAccountId);

            if (currentAccountId >= 0) {
                // Use the same method as MultiAssigneeSelector for specific account
                var rawAssignees = Account.getUsers(currentAccountId);
                console.log("Raw assignees from Account.getUsers:", rawAssignees.length);

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
                            account_id: currentAccountId
                        });
                    }
                }

                availableAssignees = filteredAssignees;
                assigneeFilterMenu.assigneeModel = availableAssignees;
                console.log("Loaded", availableAssignees.length, "assignees for account:", currentAccountId);
            } else {
                // For "All Accounts" (-1), load assignees from all accounts that have tasks
                console.log("Loading assignees from all accounts with tasks");
                availableAssignees = Task.getAllTaskAssignees(-1); // -1 means all accounts
                assigneeFilterMenu.assigneeModel = availableAssignees;
                console.log("Loaded", availableAssignees.length, "assignees from all accounts");
            }
        } catch (e) {
            console.error("Error loading assignees:", e);
            availableAssignees = [];
            assigneeFilterMenu.assigneeModel = [];
        }
    }

    // Function to restore assignee filter state from global storage
    function restoreAssigneeFilterState() {
        if (task.filterByAssignees && task.selectedAssigneeIds.length === 0) {
            var globalFilter = Global.getAssigneeFilter();
            if (globalFilter.enabled && globalFilter.assigneeIds.length > 0) {
                console.log("🔄 Restoring assignee filter from global state:", globalFilter.assigneeIds.length, "assignees");
                task.selectedAssigneeIds = globalFilter.assigneeIds;
                tasklist.selectedAssigneeIds = globalFilter.assigneeIds;
                console.log("   Restored IDs:", JSON.stringify(task.selectedAssigneeIds));
            }
        }
    }

    // Add the ListHeader component
    ListHeader {
        id: taskListHeader
        anchors.top: taskheader.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        label1: "Today"
        label2: "This Week"
        label3: "This Month"
        label4: "Later"
        label5: "Done"
        label6: "All"
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
            console.log("🔄 TAB SWITCH DETECTED - Filter:", filterKey);
            console.log("   Current assignee filter state - enabled:", task.filterByAssignees, "IDs:", JSON.stringify(task.selectedAssigneeIds));

            task.currentFilter = filterKey;

            // Restore assignee filter state if needed
            restoreAssigneeFilterState();

            // Update TaskList properties and apply filter
            tasklist.filterByAssignees = task.filterByAssignees;
            tasklist.selectedAssigneeIds = task.selectedAssigneeIds;

            console.log("   TaskList updated - filterByAssignees:", tasklist.filterByAssignees, "selectedAssigneeIds:", JSON.stringify(tasklist.selectedAssigneeIds));

            if (filterByProject) {
                console.log("   Applying project and time filter:", filterKey);
                tasklist.applyProjectAndTimeFilter(projectOdooRecordId, projectAccountId, filterKey);
            } else {
                console.log("   Applying time filter:", filterKey);
                tasklist.applyFilter(filterKey);
            }
        }

        onCustomSearch: {
            task.currentSearchQuery = query;

            // Restore assignee filter state if needed
            restoreAssigneeFilterState();

            // Update TaskList properties and apply search
            tasklist.filterByAssignees = task.filterByAssignees;
            tasklist.selectedAssigneeIds = task.selectedAssigneeIds;

            if (filterByProject) {
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
            text: 'No Task Available'
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
                label: "Create"
            },
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
            console.log("Assignee filter applied:", assigneeIds.length, "assignees selected");
            console.log("Selected assignee IDs:", JSON.stringify(assigneeIds));
            selectedAssigneeIds = assigneeIds;
            filterByAssignees = true;

            // Save to global state for persistence across navigation
            Global.setAssigneeFilter(true, assigneeIds);
            console.log("Assignee filter saved to global state");

            // Update TaskList properties
            tasklist.filterByAssignees = true;
            tasklist.selectedAssigneeIds = assigneeIds;

            console.log("TaskList properties updated - filterByAssignees:", tasklist.filterByAssignees, "selectedAssigneeIds:", JSON.stringify(tasklist.selectedAssigneeIds));

            // Refresh task list with assignee filter
            if (currentSearchQuery) {
                tasklist.applySearch(currentSearchQuery);
            } else {
                tasklist.applyFilter(currentFilter);
            }
        }

        onFilterCleared: function () {
            console.log("Assignee filter cleared");
            selectedAssigneeIds = [];
            filterByAssignees = false;

            // Clear global state
            Global.clearAssigneeFilter();
            console.log("Assignee filter cleared from global state");

            // Update TaskList properties
            tasklist.filterByAssignees = false;
            tasklist.selectedAssigneeIds = [];

            // Refresh task list without assignee filter
            if (currentSearchQuery) {
                tasklist.applySearch(currentSearchQuery);
            } else {
                tasklist.applyFilter(currentFilter);
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
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
    }

    // Listen for account selector changes directly (so filter updates immediately)
    Connections {
        target: accountFilter
        onAccountChanged: function (accountId, accountName) {
            console.log("Task_Page: Account filter changed to:", accountName, "ID:", accountId);
            // Normalize id to number, fallback to -1
            var idNum = -1;
            try {
                if (typeof accountId !== "undefined" && accountId !== null) {
                    var maybeNum = Number(accountId);
                    idNum = isNaN(maybeNum) ? -1 : maybeNum;
                } else {
                    idNum = -1;
                }
            } catch (e) {
                idNum = -1;
            }

            tasklist.selectedAccountId = idNum;

            // Reload assignees for the new account
            loadAssignees();

            // Clear assignee filter when account changes
            if (filterByAssignees) {
                selectedAssigneeIds = [];
                filterByAssignees = false;
                assigneeFilterMenu.selectedAssigneeIds = [];
            }

            // Reapply current filter/search depending on project mode
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
    }

    Connections {
        target: mainView
        onGlobalAccountChanged: function (accountId, accountName) {
            console.log("Task_Page: GlobalAccountChanged →", accountId, accountName);
            var acctNum = -1;
            if (typeof accountId !== "undefined" && accountId !== null) {
                var maybe = Number(accountId);
                acctNum = isNaN(maybe) ? -1 : maybe;
            }
            tasklist.selectedAccountId = acctNum;

            // Reload assignees for the new account
            loadAssignees();

            // Clear assignee filter when account changes
            if (filterByAssignees) {
                selectedAssigneeIds = [];
                filterByAssignees = false;
                assigneeFilterMenu.selectedAssigneeIds = [];
            }

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
        onAccountDataRefreshRequested: function (accountId) {
            var acctNum = -1;
            if (typeof accountId !== "undefined" && accountId !== null) {
                var maybe2 = Number(accountId);
                acctNum = isNaN(maybe2) ? -1 : maybe2;
            }
            tasklist.selectedAccountId = acctNum;

            // Reload assignees for the current account
            loadAssignees();

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
    }

    Component.onCompleted: {
        // Determine initial account selection from accountFilter (try common property names),
        // fall back to numeric -1 (All accounts) if none found. This ensures initial list is filtered.
        try {
            var initialAccountNum = -1;
            if (typeof accountFilter !== "undefined" && accountFilter !== null) {
                if (typeof accountFilter.selectedAccountId !== "undefined" && accountFilter.selectedAccountId !== null) {
                    var maybe = Number(accountFilter.selectedAccountId);
                    initialAccountNum = isNaN(maybe) ? -1 : maybe;
                } else if (typeof accountFilter.currentAccountId !== "undefined" && accountFilter.currentAccountId !== null) {
                    var maybe2 = Number(accountFilter.currentAccountId);
                    initialAccountNum = isNaN(maybe2) ? -1 : maybe2;
                } else if (typeof accountFilter.currentIndex !== "undefined" && accountFilter.currentIndex >= 0) {
                    // index mapping may not equate to account id — default to -1 unless you map index -> id
                    initialAccountNum = -1;
                } else {
                    initialAccountNum = -1;
                }
            } else if (typeof Account.getSelectedAccountId === "function") {
                var acct = Account.getSelectedAccountId();
                var acctNum = Number(acct);
                initialAccountNum = (acct !== null && typeof acct !== "undefined" && !isNaN(acctNum)) ? acctNum : -1;
            } else {
                initialAccountNum = -1;
            }

            console.log("Task_Page initial account selection (numeric):", initialAccountNum);
            tasklist.selectedAccountId = initialAccountNum;
        } catch (e) {
            console.error("Task_Page: error determining initial account:", e);
            tasklist.selectedAccountId = -1;
        }

        // Load assignees for the assignee filter
        loadAssignees();

        // Restore global assignee filter state if no local state is set
        if (!task.filterByAssignees || task.selectedAssigneeIds.length === 0) {
            var globalFilter = Global.getAssigneeFilter();
            if (globalFilter.enabled && globalFilter.assigneeIds.length > 0) {
                console.log("Restoring global assignee filter:", globalFilter.assigneeIds.length, "assignees");
                task.filterByAssignees = true;
                task.selectedAssigneeIds = globalFilter.assigneeIds;
            }
        }

        // Apply the filter/search that you want to show initially
        // Preserve any existing assignee filter state
        tasklist.filterByAssignees = task.filterByAssignees;
        tasklist.selectedAssigneeIds = task.selectedAssigneeIds;

        if (filterByProject) {
            tasklist.applyProjectAndTimeFilter(projectOdooRecordId, projectAccountId, currentFilter);
        } else {
            tasklist.applyFilter(currentFilter);
        }
    }
}
