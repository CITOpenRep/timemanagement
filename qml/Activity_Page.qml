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
            }
        ]
    }


    property string currentFilter: "today"
    property string currentSearchQuery: ""

    property bool filterByProject: false
    property int projectOdooRecordId: -1
    property int projectAccountId: -1
    property string projectName: ""

    property bool filterByAccount: true
    property int selectedAccountId: Accounts.getDefaultAccountId()

 
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
            // const allActivities = filterByProject ? Activity.getActivitiesForProject(projectOdooRecordId, projectAccountId) : Activity.getAllActivities();
            var currentAccountId = selectedAccountId;
            
            console.log("Fetching activities for account:", currentAccountId, "filter:", currentFilter);
            
            if (currentFilter && currentFilter !== "" || currentSearchQuery) {
                
                allActivities = Activity.getFilteredActivities(currentFilter, currentSearchQuery, currentAccountId);
            } else {
              
                allActivities = Activity.getActivitiesForAccount(currentAccountId);
            }

            console.log("Retrieved", allActivities.length, "activities for account:", currentAccountId);

            var filteredActivities = [];

            
            for (let i = 0; i < allActivities.length; i++) {
                var item = allActivities[i];
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
        
        filterByAccount = (accountId >= 0);
        selectedAccountId = accountId;
        
        get_activity_list();
    }

    function clearAccountFilter() {
        console.log("Activity_Page.clearAccountFilter called");
        
        filterByAccount = false;
        selectedAccountId = -1;
        
        get_activity_list();
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
        get_activity_list();
    }
}