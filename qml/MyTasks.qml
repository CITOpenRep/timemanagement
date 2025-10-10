/*
 * MIT License
 *
 * Copyright (c) 2025 CIT-Services
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software w            if (currentUserOdooId > 0) {
                console.log("✅ MyTasks: Applying personal stage filter:", stageId, "for user:", currentUserOdooId, "account:", defaultAccountId);
                console.log("✅ MyTasks: Filter params - stageId:", stageId, "assigneeIds:", JSON.stringify([currentUserOdooId]), "accountId:", defaultAccountId);
                
                // Get tasks by personal stage
                var stageTasks = Task.getTasksByPersonalStage(stageId, [currentUserOdooId], defaultAccountId);
                console.log("📋 MyTasks: Found", stageTasks.length, "tasks for personal stage");
                
                // Log first few tasks for debugging
                for (var i = 0; i < Math.min(3, stageTasks.length); i++) {
                    console.log("   Task", i + 1 + ":", stageTasks[i].name, "- Assignees:", stageTasks[i].user_id);
                }
                
                // Update the task list directly
                myTasksList.updateDisplayedTasks(stageTasks);
            } else {
                console.warn("⚠️ MyTasks: No valid user ID found for filtering!");
            }iction, including without limitation the rights
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
    id: myTasksPage
    title: "My Tasks"

    header: PageHeader {
        id: myTasksHeader
        StyleHints {
            foregroundColor: "white"
            backgroundColor: LomiriColors.orange
            dividerColor: LomiriColors.slate
        }
        title: myTasksPage.title

        trailingActionBar.actions: [
            Action {
                iconName: "add"
                text: "New"
                onTriggered: {
                    apLayout.addPageToNextColumn(myTasksPage, Qt.resolvedUrl("Tasks.qml"), {
                        "recordid": 0,
                        "isReadOnly": false
                    });
                }
            },
            Action {
                iconName: "search"
                text: "Search"
                onTriggered: {
                    myTaskListHeader.toggleSearchVisibility();
                }
            }
        ]
    }

    // Properties for filter and search state
    property var personalStages: []
    property var currentPersonalStageId: null  // null = "All", 0 = "No Stage", >0 = specific stage
    property string currentSearchQuery: ""

    // Properties for current user filtering
    property int currentUserOdooId: -1
    property int defaultAccountId: Account.getDefaultAccountId()

    // Function to load personal stages for the current user
    function loadPersonalStages() {
        console.log("🔄 MyTasks: Loading personal stages for user", currentUserOdooId, "account", defaultAccountId);
        
        if (currentUserOdooId <= 0 || defaultAccountId < 0) {
            console.warn("⚠️ MyTasks: Cannot load personal stages - invalid user or account");
            console.warn("   currentUserOdooId:", currentUserOdooId);
            console.warn("   defaultAccountId:", defaultAccountId);
            personalStages = [];
            return;
        }
        
        var stages = Task.getPersonalStagesForUser(currentUserOdooId, defaultAccountId);
        console.log("✅ MyTasks: Loaded", stages.length, "personal stages");
        
        if (stages.length === 0) {
            console.warn("⚠️ MyTasks: No personal stages found!");
            console.warn("   This could mean:");
            console.warn("   1. The user_id field in project_task_type_app is not populated");
            console.warn("   2. You need to sync from Odoo to populate the field");
            console.warn("   3. The user has no personal stages in Odoo");
        }
        
        // Add "All" option at the beginning
        var allStages = [{
            odoo_record_id: null,
            name: "All",
            sequence: -1
        }];
        
        // Add loaded stages
        for (var i = 0; i < stages.length; i++) {
            console.log("   Adding stage:", stages[i].name, "(ID:", stages[i].odoo_record_id + ")");
            allStages.push(stages[i]);
        }
        
        personalStages = allStages;
        console.log("📋 MyTasks: Total stages (including 'All'):", personalStages.length);
        
        // Update the ListHeader with dynamic labels
        updateListHeaderWithStages();
        
        // Set initial filter to first stage (or "All")
        if (personalStages.length > 0) {
            currentPersonalStageId = personalStages[0].odoo_record_id;
            console.log("📌 MyTasks: Set initial filter to:", personalStages[0].name);
        }
    }
    
    // Function to update ListHeader with personal stage names
    function updateListHeaderWithStages() {
        console.log("🎨 MyTasks: Updating ListHeader with", personalStages.length, "stages");
        
        if (personalStages.length === 0) {
            console.warn("⚠️ MyTasks: No stages to display in ListHeader");
            return;
        }
        
        // Update labels with stage names
        myTaskListHeader.label1 = personalStages.length > 0 ? personalStages[0].name : "";
        myTaskListHeader.label2 = personalStages.length > 1 ? personalStages[1].name : "";
        myTaskListHeader.label3 = personalStages.length > 2 ? personalStages[2].name : "";
        myTaskListHeader.label4 = personalStages.length > 3 ? personalStages[3].name : "";
        myTaskListHeader.label5 = personalStages.length > 4 ? personalStages[4].name : "";
        myTaskListHeader.label6 = personalStages.length > 5 ? personalStages[5].name : "";
        myTaskListHeader.label7 = personalStages.length > 6 ? personalStages[6].name : "";
        
        console.log("📝 ListHeader labels set:");
        console.log("   label1:", myTaskListHeader.label1);
        console.log("   label2:", myTaskListHeader.label2);
        console.log("   label3:", myTaskListHeader.label3);
        
        // Update filter keys with stage IDs (converted to strings for the filter system)
        myTaskListHeader.filter1 = personalStages.length > 0 ? String(personalStages[0].odoo_record_id) : "";
        myTaskListHeader.filter2 = personalStages.length > 1 ? String(personalStages[1].odoo_record_id) : "";
        myTaskListHeader.filter3 = personalStages.length > 2 ? String(personalStages[2].odoo_record_id) : "";
        myTaskListHeader.filter4 = personalStages.length > 3 ? String(personalStages[3].odoo_record_id) : "";
        myTaskListHeader.filter5 = personalStages.length > 4 ? String(personalStages[4].odoo_record_id) : "";
        myTaskListHeader.filter6 = personalStages.length > 5 ? String(personalStages[5].odoo_record_id) : "";
        myTaskListHeader.filter7 = personalStages.length > 6 ? String(personalStages[6].odoo_record_id) : "";
        
        // Set current filter to first stage
        if (personalStages.length > 0) {
            myTaskListHeader.currentFilter = myTaskListHeader.filter1;
            console.log("✅ ListHeader currentFilter set to:", myTaskListHeader.currentFilter);
        }
    }

    // Function to get current user's odoo_record_id for the DEFAULT account
    // MyTasks ALWAYS uses the default account set in Settings page
    function updateCurrentUser() {
        // ALWAYS use the default account from Settings
        var accountId = Account.getDefaultAccountId();
        
        console.log("🔍 MyTasks: Using DEFAULT account from Settings:", accountId);

        if (accountId >= 0) {
            currentUserOdooId = Account.getCurrentUserOdooId(accountId);
            console.log("✅ MyTasks: Current user odoo_record_id for account", accountId, "is", currentUserOdooId);
            
            if (currentUserOdooId && currentUserOdooId > 0) {
                console.log("✅ MyTasks: Setting up assignee filter with user ID:", currentUserOdooId);
                
                // DIAGNOSTIC: Check if any tasks have this assignee
                var allTasks = Task.getTasksForAccount(accountId);
                var matchingTasks = 0;
                for (var i = 0; i < allTasks.length; i++) {
                    var task = allTasks[i];
                    if (task.user_id) {
                        var taskUserIds = task.user_id.toString().split(',').map(function(id) {
                            return parseInt(id.trim());
                        });
                        if (taskUserIds.indexOf(currentUserOdooId) >= 0) {
                            matchingTasks++;
                        }
                    }
                }
                console.log("🔎 DIAGNOSTIC: Found", matchingTasks, "tasks out of", allTasks.length, "total tasks assigned to user", currentUserOdooId);
                
                if (matchingTasks === 0 && allTasks.length > 0) {
                    console.warn("⚠️ WARNING: No tasks found for current user! This might indicate a user ID mismatch.");
                    console.warn("⚠️ User ID we're looking for:", currentUserOdooId);
                    console.warn("⚠️ Sample task user_ids from first few tasks:");
                    for (var j = 0; j < Math.min(3, allTasks.length); j++) {
                        console.warn("   Task '" + allTasks[j].name + "' has user_id:", allTasks[j].user_id);
                    }
                }
            } else {
                console.warn("⚠️ MyTasks: getCurrentUserOdooId returned invalid ID:", currentUserOdooId);
            }
        } else {
            // For "All Accounts", we'll need to get users from all accounts
            currentUserOdooId = -1;
            console.log("ℹ️ MyTasks: All accounts selected, will filter by all current users");
        }
    }

    // Add the ListHeader component
    ListHeader {
        id: myTaskListHeader
        anchors.top: myTasksHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        // Labels and filters will be dynamically set by updateListHeaderWithStages()
        label1: ""
        label2: ""
        label3: ""
        label4: ""
        label5: ""
        label6: ""
        label7: ""

        filter1: ""
        filter2: ""
        filter3: ""
        filter4: ""
        filter5: ""
        filter6: ""
        filter7: ""

        showSearchBox: false
        currentFilter: ""

        onFilterSelected: {
            console.log("🔔 MyTasks: Personal Stage filter selected -", filterKey);
            
            // Parse filterKey to get personal stage ID
            // filterKey is string: "null" for All, "0" for No Stage, or actual stage ID
            var stageId;
            if (filterKey === "null") {
                stageId = null;  // Show all tasks
            } else {
                stageId = parseInt(filterKey);
            }
            
            myTasksPage.currentPersonalStageId = stageId;
            
            // Update current user before applying filter
            updateCurrentUser();
            
            if (currentUserOdooId > 0) {
                console.log("✅ MyTasks: Applying personal stage filter:", stageId, "for user:", currentUserOdooId);
                
                // Get tasks by personal stage
                var stageTasks = Task.getTasksByPersonalStage(stageId, [currentUserOdooId], defaultAccountId);
                console.log("� MyTasks: Found", stageTasks.length, "tasks for personal stage");
                
                // Update the task list directly
                myTasksList.updateDisplayedTasks(stageTasks);
            } else {
                console.warn("⚠️ MyTasks: No valid user ID found for filtering!");
            }
        }

        onCustomSearch: {
            myTasksPage.currentSearchQuery = query;
            
            // Update current user before applying search
            updateCurrentUser();
            
            if (currentUserOdooId > 0) {
                // For search, show all tasks (personal stage = null) that match search
                var stageTasks = Task.getTasksByPersonalStage(null, [currentUserOdooId], defaultAccountId);
                
                // Apply search filter
                if (query && query.trim() !== "") {
                    var searchLower = query.toLowerCase();
                    stageTasks = stageTasks.filter(function(task) {
                        return (task.name && task.name.toLowerCase().indexOf(searchLower) >= 0) ||
                               (task.description && task.description.toLowerCase().indexOf(searchLower) >= 0);
                    });
                }
                
                console.log("🔍 MyTasks: Search found", stageTasks.length, "tasks");
                myTasksList.updateDisplayedTasks(stageTasks);
            }
        }
    }

    LomiriShape {
        anchors.top: myTaskListHeader.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: units.gu(1)
        clip: true

        TaskList {
            id: myTasksList
            anchors.fill: parent
            clip: true

            // MyTasks does NOT filter by account selection
            // It ALWAYS uses the default account set in Settings
            filterByAccount: false
            
            // Enable assignee filtering to show only current user's tasks
            filterByAssignees: true
            selectedAssigneeIds: []

            onTaskEditRequested: {
                apLayout.addPageToNextColumn(myTasksPage, Qt.resolvedUrl("Tasks.qml"), {
                    "recordid": recordId,
                    "isReadOnly": false
                });
            }
            onTaskSelected: {
                apLayout.addPageToNextColumn(myTasksPage, Qt.resolvedUrl("Tasks.qml"), {
                    "recordid": recordId,
                    "isReadOnly": true
                });
            }
            onTaskTimesheetRequested: {
                let result = Timesheet.createTimesheetFromTask(localId);
                if (result.success) {
                    apLayout.addPageToNextColumn(myTasksPage, Qt.resolvedUrl("Timesheet.qml"), {
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
                        pageStack.removePages(myTasksPage);
                        apLayout.addPageToCurrentColumn(myTasksPage, Qt.resolvedUrl("MyTasks.qml"));
                    }
                }
            }
        }

        Text {
            id: labelNoTask
            anchors.centerIn: parent
            font.pixelSize: units.gu(2)
            visible: false
            text: 'No Tasks Assigned to You'
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
                apLayout.addPageToNextColumn(myTasksPage, Qt.resolvedUrl("Tasks.qml"), {
                    "recordid": 0,
                    "isReadOnly": false
                });
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            // Update navigation tracking
            Global.setLastVisitedPage("MyTasks");

            // Refresh user data and personal stages when page becomes visible
            updateCurrentUser();
            loadPersonalStages();
            
            // Apply current personal stage filter
            if (currentUserOdooId > 0) {
                var stageTasks = Task.getTasksByPersonalStage(currentPersonalStageId, [currentUserOdooId], defaultAccountId);
                myTasksList.updateDisplayedTasks(stageTasks);
            }
        }
    }

    // MyTasks IGNORES account selector changes
    // It ALWAYS uses the default account from Settings page
    // If user wants to see different account's tasks, they should:
    // 1. Go to Settings page
    // 2. Set that account as Default
    // 3. Return to MyTasks

    Component.onCompleted: {
        console.log("🚀 MyTasks: Component.onCompleted - Initial setup");
        console.log("📌 MyTasks: Using DEFAULT account from Settings");
        
        // Get current user from DEFAULT account
        updateCurrentUser();
        
        // Load personal stages for the current user
        if (currentUserOdooId > 0) {
            console.log("✅ MyTasks: Loading personal stages for user:", currentUserOdooId, "from default account:", defaultAccountId);
            loadPersonalStages();
            
            // Apply initial personal stage filter (first stage which is "All")
            if (personalStages.length > 0) {
                console.log("📋 MyTasks: Applying initial personal stage filter");
                var stageTasks = Task.getTasksByPersonalStage(currentPersonalStageId, [currentUserOdooId], defaultAccountId);
                myTasksList.updateDisplayedTasks(stageTasks);
            }
        } else {
            console.warn("⚠️ MyTasks: No valid user ID found for default account:", defaultAccountId);
        }
    }
}
