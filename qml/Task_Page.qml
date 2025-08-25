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
        title: task.title

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

    // Function to get tasks based on current filter and search
    function getTaskList(filter, searchQuery) {
        taskModel.clear();

        try {
            var allTasks;
            if (filter || searchQuery) {
                allTasks = Task.getFilteredTasks(filter, searchQuery);
            } else {
                allTasks = Task.getAllTasks();
            }

            for (var i = 0; i < allTasks.length; i++) {
                var task = allTasks[i];
                var projectName = ""; // You can add project lookup here if needed

                taskModel.append({
                    id: task.id,
                    name: task.name,
                    description: task.description,
                    deadline: task.deadline,
                    start_date: task.start_date,
                    end_date: task.end_date,
                    status: task.status,
                    initial_planned_hours: task.initial_planned_hours,
                    favorites: task.favorites,
                    project_name: projectName,
                    account_id: task.account_id,
                    project_id: task.project_id,
                    user_id: task.user_id,
                    odoo_record_id: task.odoo_record_id
                });
            }
        } catch (e) {
            console.error("❌ Error in getTaskList():", e);
        }
    }

    // Add the ListHeader component outside LomiriShape
    ListHeader {
        id: taskListHeader
        anchors.top: taskheader.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        label1: "Today"
        label2: "This Week"
        label3: "This Month"
        label4: "Later"
        label5: "OverDue"
        label6: "All"
        label7: "Done"

        filter1: "today"
        filter2: "this_week"
        filter3: "this_month"
        filter4: "later"
        filter5: "overdue"
        filter6: "all"
        filter7: "done"

        showSearchBox: false
        currentFilter: task.currentFilter

        onFilterSelected: {
            task.currentFilter = filterKey;
            tasklist.applyFilter(filterKey);
        }

        onCustomSearch: {
            task.currentSearchQuery = query;
            tasklist.applySearch(query);
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
                    //We got the result success, lets open the record with the id
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
        //text:""
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
            // Apply the current filter when page becomes visible
            tasklist.applyFilter(currentFilter);
        }
    }
    Component.onCompleted: {
        // Apply default "today" filter on completion
        tasklist.applyFilter(currentFilter);
    }
}
