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
                    // Use DEFAULT account for creating new activities (not the filter selection)
                    apLayout.addPageToNextColumn(activity, Qt.resolvedUrl("Activities.qml"), {
                        "isReadOnly": false
                    });
                }
            },
            Action {
                iconName: "account"
                onTriggered: {
                    accountFilterVisible = !accountFilterVisible
                }
            }
        ]
    }

    property string currentFilter: "today"
    property string currentSearchQuery: ""

    property bool filterByProject: false
    property int projectOdooRecordId: -1
    property int projectAccountId: -1
    property string projectName: ""

    // SEPARATED CONCERNS:
    // 1. selectedAccountId - ONLY for filtering/viewing data (from account selector)
    // 2. defaultAccountId - ONLY for creating new records (from default account setting)
    property string selectedAccountId: "-1" // Start with "All accounts" for filtering
    property string defaultAccountId: Accounts.getDefaultAccountId() // For creating records

    // Legacy properties - keeping for compatibility but not using for filtering
    property bool filterByAccount: true

    // Listen to AccountFilter component changes (for filtering only)
    Connections {
        target: accountFilter
        onAccountChanged: function(accountId, accountName) {
            console.log("Account filter changed to:", accountName, "ID:", accountId);
            selectedAccountId = String(accountId);
            get_activity_list();
        }
    }

    // Listen for default account changes (for creation only)
    Connections {
        target: mainView
        onDefaultAccountChanged: function(accountId) {
            console.log("Default account changed to:", accountId);
            defaultAccountId = String(accountId); // Update default for creation only
        }
    }

    // Keep account-data-refresh handler but accept permissive signature
    Connections {
        target: mainView
        onAccountDataRefreshRequested: function(accountId) {
            if (typeof accountId === "undefined" || accountId === null) {
                // no specific account provided — refresh
                get_activity_list();
            } else {
                if (selectedAccountId === String(accountId) || selectedAccountId === "-1") {
                    get_activity_list();
                }
            }
        }
    }

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

    function getTaskDetails(taskId) {
        try {
            return Task.getTaskDetails(taskId);
        } catch (e) {
            console.error("Error getting task details:", e);
            return { name: "Unknown Task" };
        }
    }

    function get_activity_list() {
        activityListModel.clear();

        try {
            var allActivities = [];
            // Use selectedAccountId for filtering (from account selector)
            var filterAccountId = selectedAccountId;
            console.log("Filtering activities for account:", filterAccountId, "filter:", currentFilter);
            console.log("Default account for creation:", defaultAccountId);

            // Normalize filterAccountId: treat -1, "-1", null, undefined as "all accounts"
            if (filterAccountId === -1) filterAccountId = "-1";
            if (filterAccountId === null || typeof filterAccountId === "undefined") filterAccountId = "-1";

            // Prepare parameter in the shape Activity APIs expect:
            // if "-1" -> pass -1, otherwise try to pass numeric id when possible
            var accountParam;
            if (filterAccountId === "-1") {
                accountParam = -1;
            } else {
                var num = Number(filterAccountId);
                accountParam = isNaN(num) ? filterAccountId : num;
            }

            // Decide which fetch to use.
            if ((currentFilter && currentFilter !== "") || (currentSearchQuery && currentSearchQuery.trim() !== "")) {
                // Use filtered fetch (accepts filter, search, account)
                allActivities = Activity.getFilteredActivities(currentFilter, currentSearchQuery, accountParam);
            } else {
                // No filter/search — fetch all or account-specific
                if (accountParam === -1) {
                    allActivities = Activity.getAllActivities();
                } else {
                    allActivities = Activity.getActivitiesForAccount(accountParam);
                }
            }

            if (!allActivities) allActivities = [];
            console.log("Retrieved", allActivities.length, "activities for account filter:", accountParam);

            var filteredActivities = [];

            for (let i = 0; i < allActivities.length; i++) {
                var item = allActivities[i] || {};
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
                    // preserve color_pallet exactly from the backend item
                    color_pallet: (typeof item.color_pallet !== "undefined" ? item.color_pallet : "")
                });
            }

            // Sort in ascending order (oldest first)
            filteredActivities.sort(function (a, b) {
                if (!a.due_date || !b.due_date) {
                    return (a.summary || "").localeCompare(b.summary || "");
                }
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

    // Legacy helpers (kept for compatibility)
    function applyAccountFilter(accountId) {
        console.log("Activity_Page.applyAccountFilter called with accountId:", accountId);
        selectedAccountId = String(accountId);
        get_activity_list();
    }

    function clearAccountFilter() {
        console.log("Activity_Page.clearAccountFilter called");
        selectedAccountId = "-1";
        get_activity_list();
    }

    function passesDateFilter(dueDateStr, filter, currentDate) {
        if (filter === "all") return true;
        if (!dueDateStr) return false;

        var dueDate = new Date(dueDateStr);
        var today = new Date(currentDate.getFullYear(), currentDate.getMonth(), currentDate.getDate());
        var itemDate = new Date(dueDate.getFullYear(), dueDate.getMonth(), dueDate.getDate());
        var isOverdue = itemDate < today;

        switch (filter) {
        case "today":
            return itemDate.getTime() <= today.getTime();
        case "week":
            var weekStart = new Date(today);
            weekStart.setDate(today.getDate() - today.getDay());
            var weekEnd = new Date(weekStart);
            weekEnd.setDate(weekStart.getDate() + 6);
            return (itemDate >= weekStart && itemDate <= weekEnd) && !isOverdue;
        case "month":
            var isThisMonth = itemDate.getFullYear() === today.getFullYear() && itemDate.getMonth() === today.getMonth();
            return isThisMonth && !isOverdue;
        case "later":
            var monthEnd = new Date(today.getFullYear(), today.getMonth() + 1, 0);
            var monthEndDay = new Date(monthEnd.getFullYear(), monthEnd.getMonth(), monthEnd.getDate());
            return itemDate > monthEndDay && !isOverdue;
        case "overdue":
            return isOverdue;
        default:
            return true;
        }
    }

    function passesSearchFilter(item, searchQuery) {
        if (!searchQuery || searchQuery.trim() === "") return true;

        var query = searchQuery.toLowerCase().trim();

        if (item.summary && item.summary.toLowerCase().indexOf(query) >= 0) return true;
        if (item.notes && item.notes.toLowerCase().indexOf(query) >= 0) return true;

        var activityTypeName = Activity.getActivityTypeName(item.activity_type_id);
        if (activityTypeName && activityTypeName.toLowerCase().indexOf(query) >= 0) return true;

        var user = Accounts.getUserNameByOdooId(item.user_id);
        if (user && user.toLowerCase().indexOf(query) >= 0) return true;

        var projectDetails = item.project_id ? getProjectDetails(item.project_id) : null;
        var projectName = projectDetails && projectDetails.name ? projectDetails.name : "";
        if (projectName && projectName.toLowerCase().indexOf(query) >= 0) return true;

        var taskName = item.task_id ? getTaskDetails(item.task_id).name : "";
        if (taskName && taskName.toLowerCase().indexOf(query) >= 0) return true;

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
                // pass the color pallet exactly as stored in model
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
                   Activity.markAsDone(accountid, recordid);
                   var result = Activity.createFollowupActivity(accountid, recordid)
                   if (result && result.success === true) {
                       console.log("Followup activity has been created")
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

    Component.onCompleted: {
        // Initialize default account for creation
        try {
            defaultAccountId = String(Accounts.getDefaultAccountId ? Accounts.getDefaultAccountId() : "");
        } catch (e) {
            console.error("Error reading default account:", e);
            defaultAccountId = "";
        }

        // Try to read the account selector's current selection and use it as initial filter.
        try {
            if (typeof accountFilter !== "undefined" && accountFilter !== null) {
                if (typeof accountFilter.selectedAccountId !== "undefined" && accountFilter.selectedAccountId !== null) {
                    selectedAccountId = String(accountFilter.selectedAccountId);
                } else if (typeof accountFilter.currentAccountId !== "undefined" && accountFilter.currentAccountId !== null) {
                    selectedAccountId = String(accountFilter.currentAccountId);
                } else if (typeof accountFilter.currentIndex !== "undefined" && accountFilter.currentIndex >= 0) {
                    selectedAccountId = String(accountFilter.currentIndex);
                } else {
                    selectedAccountId = "-1";
                }
            } else if (typeof Accounts.getSelectedAccountId === "function") {
                var acct = Accounts.getSelectedAccountId();
                selectedAccountId = (acct !== null && typeof acct !== "undefined") ? String(acct) : "-1";
            } else {
                selectedAccountId = "-1";
            }
        } catch (e) {
            console.error("Error reading accountFilter initial selection:", e);
            selectedAccountId = "-1";
        }

        console.log("Initial selectedAccountId on load:", selectedAccountId);

        // Load filtered list initially
        get_activity_list();
    }
}
