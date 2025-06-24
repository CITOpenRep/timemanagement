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
        title: activity.title
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
                   // console.log("Search clicked");
                    listheader.toggleSearchVisibility();
                }
            },
            Action {
                iconName: "add"
                text: "New"
                onTriggered: {
                 //   console.log("Create Activity clicked");
                    apLayout.addPageToNextColumn(activity, Qt.resolvedUrl("Activities.qml"), {
                        // "recordid": recordid,
                        "isReadOnly": false
                    });
                }
            }
        ]
    }

    function shouldIncludeItem(item) {
        const filter = activity.currentFilter || "all";
        const searchQuery = activity.currentSearchQuery || "";
        const currentDate = new Date();

        const dueDateOk = (filter === "all") || passesDateFilter(item.due_date, filter, currentDate);
        const searchOk = (!searchQuery) || passesSearchFilter(item, searchQuery);

        return dueDateOk && searchOk;
    }

    function get_activity_list() {
        activityListModel.clear();

        try {
            const allActivities = Activity.getAllActivities();

            for (let i = 0; i < allActivities.length; i++) {
                var item = allActivities[i];
                if (shouldIncludeItem(item)) {
                    var projectDetails = item.project_id ? getProjectDetails(item.project_id) : null;
                    var projectName = projectDetails && projectDetails.name ? projectDetails.name : "No Project";
                    var taskName = item.task_id ? getTaskDetails(item.task_id).name : "No Task";  // Assuming you have getTaskDetails()
                    var user = Accounts.getUserNameByOdooId(item.user_id);

                    activityListModel.append({
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
                        last_modified: item.last_modified
                    });
                }
            }
        } catch (e) {
            console.error("❌ Error in get_activity_list():", e);
        }
    }

    function passesDateFilter(dueDateStr, filter, currentDate) {
        if (!dueDateStr)
            return false;

        var dueDate = new Date(dueDateStr);
        var today = new Date(currentDate.getFullYear(), currentDate.getMonth(), currentDate.getDate());
        var itemDate = new Date(dueDate.getFullYear(), dueDate.getMonth(), dueDate.getDate());

        switch (filter) {
        case "today":
            return itemDate.getTime() === today.getTime();
        case "week":
            var weekStart = new Date(today);
            weekStart.setDate(today.getDate() - today.getDay());
            var weekEnd = new Date(weekStart);
            weekEnd.setDate(weekStart.getDate() + 6);
            return itemDate >= weekStart && itemDate <= weekEnd;
        case "month":
            return itemDate.getFullYear() === today.getFullYear() && itemDate.getMonth() === today.getMonth();
        case "favorites":
            // Assuming favorites are marked by a specific state or flag
            return item.state === "favorite"; // Adjust this condition based on your model
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
        label2: "This week"
        label3: "This Month"
        label4: "All"
        label5: "Favorites"

        showSearchBox: false
        currentFilter: activity.currentFilter  // Bind to page's current filter

        filter1: "today"
        filter2: "week"
        filter3: "month"
        filter4: "all"
        filter5: "favorites"

        onFilterSelected: {
            activity.currentFilter = filterKey;
          //  console.log("Filter key is " + activity.currentFilter);
            get_activity_list();
        }
        onCustomSearch: {
            activity.currentSearchQuery = query;
           // console.log("Search key is " + activity.currentSearchQuery);
            get_activity_list();
        }
    }

    LomiriShape {
        anchors.top: listheader.bottom
        height: parent.height
        width: parent.width

        LomiriListView {
            id: activitylist
            anchors.fill: parent
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

                onCardClicked: function (accountid, recordid) {
                  //  console.log("Page : Loading record " + recordid + " account id " + accountid);
                    apLayout.addPageToNextColumn(activity, Qt.resolvedUrl("Activities.qml"), {
                        "recordid": recordid,
                        "accountid": accountid,
                        "isReadOnly": true
                    });
                }
                onMarkAsDone: function (accountid, recordid) {
                   // console.log("Requesting to Make done activity with id " + recordid);
                    //Here we need to delete the record and see? if it get synced
                    Activity.markAsDone(accountid, recordid);
                    get_activity_list("today", "");
                }
            }
            currentIndex: 0
            onCurrentIndexChanged: {
               // console.log("currentIndex changed");
            }

            Component.onCompleted: {
                get_activity_list("today", "");
            }
        }
    }

    // Store current filter and search state
    property string currentFilter: "today"
    property string currentSearchQuery: ""
}
// Store current filter and search state

