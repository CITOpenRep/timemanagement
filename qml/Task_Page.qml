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
            }
        ]
    }

    ListModel {
        id: taskModel
    }

    // Add properties to track filter and search state
    property string currentFilter: "today"
    property string currentSearchQuery: ""

    // Properties for project filtering
    property bool filterByProject: false
    property int projectOdooRecordId: -1
    property int projectAccountId: -1
    property string projectName: ""


    function getTaskList(filter, searchQuery) {
        taskModel.clear();

        try {
            var allTasks = [];
            var currentAccountId = Account.getDefaultAccountId();
            
            console.log("Fetching tasks for account:", currentAccountId, "filter:", filter);
            
            if (filterByProject) {
   
                allTasks = Task.getTasksForProject(projectOdooRecordId, projectAccountId);
            } else {

                if (filter || searchQuery) {
                    allTasks = Task.getFilteredTasks(filter, searchQuery, currentAccountId);
                } else {
                    allTasks = Task.getTasksForAccount(currentAccountId);
                }
            }

            console.log("Retrieved", allTasks.length, "tasks for account:", currentAccountId);

            for (var i = 0; i < allTasks.length; i++) {
                var taskItem = allTasks[i];
                var projectName = ""; // You can add project lookup here if needed

                taskModel.append({
                    id: taskItem.id,
                    name: taskItem.name,
                    description: taskItem.description,
                    deadline: taskItem.deadline,
                    start_date: taskItem.start_date,
                    end_date: taskItem.end_date,
                    status: taskItem.status,
                    initial_planned_hours: taskItem.initial_planned_hours,
                    spent_hours: taskItem.spent_hours || 0,
                    favorites: taskItem.favorites,
                    project_name: projectName,
                    account_id: taskItem.account_id,
                    project_id: taskItem.project_id,
                    user_id: taskItem.user_id,
                    odoo_record_id: taskItem.odoo_record_id,
                    color_pallet: taskItem.color_pallet || 0,
                    priority: taskItem.priority || "0"
                });
            }
            
            console.log("Populated taskModel with", taskModel.count, "items");
        } catch (e) {
            console.error("Error in getTaskList():", e);
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
            task.currentFilter = filterKey;
            if (filterByProject) {
                tasklist.applyProjectAndTimeFilter(projectOdooRecordId, projectAccountId, filterKey);
            } else {
                tasklist.applyFilter(filterKey);
            }
        }

        onCustomSearch: {
            task.currentSearchQuery = query;
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

           
            filterByAccount: true
            selectedAccountId: Account.getDefaultAccountId()

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

    Component.onCompleted: {
        if (filterByProject) {
            tasklist.applyProjectAndTimeFilter(projectOdooRecordId, projectAccountId, currentFilter);
        } else {
            tasklist.applyFilter(currentFilter);
        }
    }
}