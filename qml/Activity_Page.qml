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
import Lomiri.Components 1.3
import QtQuick.Window 2.2
import "../models/timesheet.js" as Model
import "../models/project.js" as Project
import "../models/task.js" as Task
import "../models/activity.js" as Activity
import "../models/utils.js" as Utils
import "../models/accounts.js" as Accounts
import "components"

Page {
    id: activity
    title: "Activities"
    header: PageHeader {
        id: taskheader
        title: filterByProject ? "Activities - " + projectName : activity.title
        StyleHints {
            foregroundColor: "white"
            backgroundColor: LomiriColors.orange
            dividerColor: LomiriColors.slate
        }

        trailingActionBar.actions: [
            Action {
                iconName: "search"
                text: "Search"
                onTriggered: {
                    listheader.toggleSearchVisibility();
                }
            },
            Action {
                iconName: "add"
                text: "New"
                onTriggered: {
                    apLayout.addPageToNextColumn(activity, Qt.resolvedUrl("Activities.qml"), {
                        "isReadOnly": false
                    });
                }
            },
            Action {
                iconName: "contact"
                text: "Filter by Assignees"
                onTriggered: {
                    assigneeFilterMenu.expanded = !assigneeFilterMenu.expanded;
                }
            }
            // Action {
            //     iconName: "account"
            //     text: "Filter by Account"
            //     onTriggered: {
            //         accountFilter.expanded = !accountFilter.expanded;
            //     }
            // }


        ]
    }

    property string currentFilter: "today"
    property string currentSearchQuery: ""

    property bool filterByProject: false
    property int projectOdooRecordId: -1
    property int projectAccountId: -1
    property string projectName: ""

    property bool filterByAccount: false
    property int selectedAccountId: -1

    // Properties for assignee filtering
    property bool filterByAssignees: false
    property var selectedAssigneeIds: []
    property var availableAssignees: []

    NotificationPopup {
        id: notifPopup
        width: units.gu(80)
        height: units.gu(80)
    }

    function shouldIncludeItem(item) {
        const filter = activity.currentFilter || "all";
        const searchQuery = activity.currentSearchQuery || "";
        const currentDate = new Date();

        const dueDateOk = (filter === "all") || passesDateFilter(item.due_date, filter, currentDate);
        const searchOk = (!searchQuery) || passesSearchFilter(item, searchQuery);

        return dueDateOk && searchOk;
    }

    function getProjectDetails(projectId) {
        try {
            return Project.getProjectDetails(projectId);
        } catch (e) {
            console.error("Error getting project details:", e);
            return null;
        }
    }

    // Helper function to get task details
    function getTaskDetails(taskId) {
        try {
            return Task.getTaskDetails(taskId);
        } catch (e) {
            console.error("Error getting task details:", e);
            return {
                name: "Unknown Task"
            };
        }
    }

    function get_activity_list() {
        activityListModel.clear();

        try {
            var allActivities = [];
            var currentAccountId = selectedAccountId;

            console.log("Fetching activities - filterByProject:", filterByProject, "projectOdooRecordId:", projectOdooRecordId, "account:", currentAccountId, "filter:", currentFilter);

            if (filterByProject) {
                // When filtering by project, get activities for that specific project
                allActivities = Activity.getActivitiesForProject(projectOdooRecordId, projectAccountId);
                console.log("Retrieved", allActivities.length, "activities for project:", projectOdooRecordId);
            } else {
                // Normal account-based filtering
                if (currentFilter && currentFilter !== "" || currentSearchQuery) {
                    // Pass currentAccountId only if filterByAccount is true and selectedAccountId >= 0
                    var accountIdForFilter = (filterByAccount && currentAccountId >= 0) ? currentAccountId : -1;
                    allActivities = Activity.getFilteredActivities(currentFilter, currentSearchQuery, accountIdForFilter);
                } else {
                    if (filterByAccount && currentAccountId >= 0) {
                        allActivities = Activity.getActivitiesForAccount(currentAccountId);
                    } else {
                        allActivities = Activity.getAllActivities();
                    }
                }
                console.log("Retrieved", allActivities.length, "activities for account:", currentAccountId >= 0 ? currentAccountId : "all");
            }

            // Apply assignee filtering if enabled
            var menuSelectedIds = assigneeFilterMenu.selectedAssigneeIds || [];
            if (filterByAssignees && menuSelectedIds && menuSelectedIds.length > 0) {
                var assigneeFilteredActivities = [];
                for (let i = 0; i < allActivities.length; i++) {
                    var item = allActivities[i];
                    // Check if the activity matches any selected assignee (considering both user_id and account_id)
                    var matchesSelectedAssignee = false;
                    for (let j = 0; j < menuSelectedIds.length; j++) {
                        var selectedId = menuSelectedIds[j];
                        // Handle both simple ID (old format) and composite format
                        if (typeof selectedId === 'object') {
                            // New format: {user_id: X, account_id: Y}
                            if (item.user_id && item.account_id && parseInt(item.user_id) === selectedId.user_id && parseInt(item.account_id) === selectedId.account_id) {
                                matchesSelectedAssignee = true;
                                break;
                            }
                        } else {
                            // Legacy format: just user_id (for backward compatibility)
                            if (item.user_id && parseInt(item.user_id) === parseInt(selectedId)) {
                                matchesSelectedAssignee = true;
                                break;
                            }
                        }
                    }
                    if (matchesSelectedAssignee) {
                        assigneeFilteredActivities.push(item);
                    }
                }
                allActivities = assigneeFilteredActivities;
            }

            var filteredActivities = [];

            // Apply additional filtering (date/search) when using project filtering
            for (let i = 0; i < allActivities.length; i++) {
                var item = allActivities[i];

                // When filtering by project, still apply date and search filters
                if (filterByProject && !shouldIncludeItem(item)) {
                    continue;
                }

                var projectDetails = item.project_id ? getProjectDetails(item.project_id) : null;
                var projectName = projectDetails && projectDetails.name ? projectDetails.name : "No Project";
                var taskName = item.task_id ? getTaskDetails(item.task_id).name : "No Task";
                var user = Accounts.getUserNameByOdooId(item.user_id);

                filteredActivities.push({
                    id: item.id,
                    summary: item.summary,
                    due_date: item.due_date,
                    notes: item.notes,
                    activity_type_name: Activity.getActivityTypeName(item.activity_type_id),
                    state: item.state,
                    task_id: item.task_id,
                    task_name: taskName,
                    project_name: projectName,
                    odoo_record_id: item.odoo_record_id || 0,
                    user: user,
                    account_id: item.account_id,
                    resId: item.resId,
                    resModel: item.resModel,
                    last_modified: item.last_modified,
                    color_pallet: item.color_pallet
                });
            }

            filteredActivities.sort(function (a, b) {
                if (!a.due_date || !b.due_date) {
                    return (a.summary || "").localeCompare(b.summary || "");
                }
                // Sort in acending order (oldest first)
                return new Date(a.due_date) - new Date(b.due_date);
            });

            for (let j = 0; j < filteredActivities.length; j++) {
                activityListModel.append(filteredActivities[j]);
            }

            console.log("Populated activityListModel with", activityListModel.count, "items");
        } catch (e) {
            console.error("Error in get_activity_list():", e);
        }
    }

    function applyAccountFilter(accountId) {
        console.log("Activity_Page.applyAccountFilter called with accountId:", accountId);

        filterByAccount = true;
        selectedAccountId = accountId;

        get_activity_list();
    }

    function clearAccountFilter() {
        console.log("Activity_Page.clearAccountFilter called");

        filterByAccount = false;
        selectedAccountId = -1;

        get_activity_list();
    }

    // Function to load available assignees for the current account
    function loadAssignees() {
        try {
            var currentAccountId = selectedAccountId;
            if (typeof currentAccountId === "undefined" || currentAccountId === null)
                currentAccountId = -1;

            if (filterByAccount && currentAccountId >= 0) {
                // Use the same method as MultiAssigneeSelector for specific account
                var rawAssignees = Accounts.getUsers(currentAccountId);

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
            } else {
                // For "All Accounts" (-1), load assignees from all accounts that have activities
                availableAssignees = Activity.getAllActivityAssignees(-1); // -1 means all accounts
                assigneeFilterMenu.assigneeModel = availableAssignees;
            }
        } catch (e) {
            console.error("Error loading assignees:", e);
            availableAssignees = [];
            assigneeFilterMenu.assigneeModel = [];
        }
    }

    /*
    Todo :   - Refactor the date filter logic to be more modular and reusable. And Move to Activity.js
    */

    function passesDateFilter(dueDateStr, filter, currentDate) {
        // Handle "all" filter - show everything
        if (filter === "all") {
            return true;
        }

        // Activities without dates should only appear in "all" filter
        if (!dueDateStr) {
            return false;
        }

        var dueDate = new Date(dueDateStr);
        var today = new Date(currentDate.getFullYear(), currentDate.getMonth(), currentDate.getDate());
        var itemDate = new Date(dueDate.getFullYear(), dueDate.getMonth(), dueDate.getDate());

        // Check if item is overdue
        var isOverdue = itemDate < today;

        switch (filter) {
        case "today":
            // Show activities due today only
            return itemDate.getTime() <= today.getTime();
        case "week":
            var weekStart = new Date(today);
            // JavaScript getDay(): 0=Sunday, 1=Monday, 2=Tuesday, 3=Wednesday, 4=Thursday, 5=Friday, 6=Saturday
            weekStart.setDate(today.getDate() - today.getDay());
            var weekEnd = new Date(weekStart);
            weekEnd.setDate(weekStart.getDate() + 6);

            // Show if due this week (excluding overdue activities)
            return (itemDate >= weekStart && itemDate <= weekEnd) && !isOverdue;
        case "month":
            var isThisMonth = itemDate.getFullYear() === today.getFullYear() && itemDate.getMonth() === today.getMonth();

            // Show if due this month (excluding overdue activities)
            return isThisMonth && !isOverdue;
        case "later":
            // Show activities due after this month (and not overdue)
            var monthEnd = new Date(today.getFullYear(), today.getMonth() + 1, 0); // Last day of current month
            var monthEndDay = new Date(monthEnd.getFullYear(), monthEnd.getMonth(), monthEnd.getDate());

            // Show if due after this month and not overdue
            return itemDate > monthEndDay && !isOverdue;
        case "overdue":
            // Show only overdue activities
            return isOverdue;
        default:
            return true;
        }
    }

    function passesSearchFilter(item, searchQuery) {
        if (!searchQuery || searchQuery.trim() === "")
            return true;

        var query = searchQuery.toLowerCase().trim();

        // Search in summary
        if (item.summary && item.summary.toLowerCase().indexOf(query) >= 0) {
            return true;
        }

        // Search in notes
        if (item.notes && item.notes.toLowerCase().indexOf(query) >= 0) {
            return true;
        }

        // Search in activity type name
        var activityTypeName = Activity.getActivityTypeName(item.activity_type_id);
        if (activityTypeName && activityTypeName.toLowerCase().indexOf(query) >= 0) {
            return true;
        }

        // Search in user name
        var user = Accounts.getUserNameByOdooId(item.user_id);
        if (user && user.toLowerCase().indexOf(query) >= 0) {
            return true;
        }

        // Search in project name
        var projectDetails = item.project_id ? getProjectDetails(item.project_id) : null;
        var projectName = projectDetails && projectDetails.name ? projectDetails.name : "";
        if (projectName && projectName.toLowerCase().indexOf(query) >= 0) {
            return true;
        }

        // Search in task name
        var taskName = item.task_id ? getTaskDetails(item.task_id).name : "";
        if (taskName && taskName.toLowerCase().indexOf(query) >= 0) {
            return true;
        }

        return false;
    }

    ListModel {
        id: activityListModel
    }

    ListHeader {
        id: listheader
        anchors.top: taskheader.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        label1: "Today"
        label2: "This Week"
        label3: "This Month"
        label4: "Later"
        label5: "OverDue"
        label6: "All"
        label7: ""

        showSearchBox: false
        currentFilter: activity.currentFilter

        filter1: "today"
        filter2: "week"
        filter3: "month"
        filter4: "later"
        filter5: "overdue"
        filter6: "all"
        filter7: ""

        onFilterSelected: {
            activity.currentFilter = filterKey;
            get_activity_list();
        }
        onCustomSearch: {
            activity.currentSearchQuery = query;
            get_activity_list();
        }
    }

    LomiriShape {
        anchors.top: listheader.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        clip: true

        LomiriListView {
            id: activitylist
            anchors.fill: parent
            clip: true
            model: activityListModel
            delegate: ActivityDetailsCard {
                id: activityCard
                odoo_record_id: model.id
                notes: model.notes
                activity_type_name: model.activity_type_name
                summary: model.summary
                user: model.user
                account_id: model.account_id
                due_date: model.due_date
                state: model.state
                colorPallet: model.color_pallet

                onCardClicked: function (accountid, recordid) {
                    apLayout.addPageToNextColumn(activity, Qt.resolvedUrl("Activities.qml"), {
                        "recordid": recordid,
                        "accountid": accountid,
                        "isReadOnly": true
                    });
                }
                onMarkAsDone: function (accountid, recordid) {
                    Activity.markAsDone(accountid, recordid);
                    get_activity_list();
                }
                onDateChanged: function (accountid, recordid, newDate) {
                    console.log("Activity_Page: Changing activity date for record ID:", recordid, "to:", newDate);
                    Activity.updateActivityDate(accountid, recordid, newDate);
                    get_activity_list();
                }

                onCreateFollowup: function (accountid, recordid) {
                    //first mark this activity as Done and create a followup activity
                    Activity.markAsDone(accountid, recordid);
                    var result = Activity.createFollowupActivity(accountid, recordid);
                    if (result.success === true) {
                        console.log("Followup activity has been created");
                        apLayout.addPageToNextColumn(activity, Qt.resolvedUrl("Activities.qml"), {
                            "recordid": result.record_id,
                            "accountid": accountid,
                            "isReadOnly": false
                        });
                    } else {
                        notifPopup.open("Error", "Failed to create a followup activity.", "error");
                    }

                    get_activity_list();
                }
            }
            currentIndex: 0
            onCurrentIndexChanged: {}

            Component.onCompleted: {
                get_activity_list();
            }
        }

        Text {
            id: labelNoActivity
            anchors.centerIn: parent
            font.pixelSize: units.gu(2)
            visible: activityListModel.count === 0
            text: 'No Activities Available'
        }
    }

    onVisibleChanged: {
        if (visible) {
            get_activity_list();
        }
    }

    // Assignee Filter Menu
    AssigneeFilterMenu {
        id: assigneeFilterMenu
        anchors.fill: parent
        z: 10

        onFilterApplied: function (assigneeIds) {
            selectedAssigneeIds = assigneeIds;
            filterByAssignees = true;
            get_activity_list();
        }

        onFilterCleared: function () {
            selectedAssigneeIds = [];
            filterByAssignees = false;
            get_activity_list();
        }
    }

    // Account Filter component removed to prevent interference with PageHeader clicks
    // Account filtering is now handled through global mainView connections

    Connections {
        target: mainView
        onAccountDataRefreshRequested: function (accountId) {
            // Only reload assignees, don't force account filtering
            loadAssignees();

            // Refresh the activity list to show updated data
            get_activity_list();
        }
        onGlobalAccountChanged: function (accountId, accountName) {
            // Only reload assignees, don't force account filtering
            loadAssignees();

            // Refresh the activity list to show updated data
            get_activity_list();
        }
    }

    Component.onCompleted: {
        // Load assignees for the assignee filter
        loadAssignees();
        get_activity_list();
    }
}
