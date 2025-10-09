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
    property string currentFilter: "today"
    property string currentSearchQuery: ""

    // Properties for current user filtering
    property int currentUserOdooId: -1
    property int currentAccountId: -1

    // Use variant so we can hold number or string temporarily, but we will always set numeric values
    property variant selectedAccountId: -1
    property variant defaultAccountId: Account.getDefaultAccountId()

    // Function to get current user's odoo_record_id for the selected account
    function updateCurrentUser() {
        var accountId = myTasksList.selectedAccountId;
        if (typeof accountId === "undefined" || accountId === null)
            accountId = -1;
        
        // CRITICAL FIX: MyTasks doesn't support "All Accounts" (-1)
        // Force to default account if -1
        if (accountId < 0) {
            accountId = Account.getDefaultAccountId();
            myTasksList.selectedAccountId = accountId;
            console.log("⚠️ MyTasks: Forced account from -1 to default account:", accountId);
        }

        currentAccountId = accountId;

        console.log("🔍 MyTasks: updateCurrentUser called with accountId:", accountId);

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
        currentFilter: myTasksPage.currentFilter

        onFilterSelected: {
            console.log("🔔 MyTasks: Filter selected -", filterKey);
            myTasksPage.currentFilter = filterKey;
            
            // Update current user before applying filter
            updateCurrentUser();
            
            // Set up assignee filtering for current user
            if (currentUserOdooId > 0) {
                console.log("✅ MyTasks: Applying assignee filter with user ID:", currentUserOdooId);
                myTasksList.filterByAssignees = true;
                myTasksList.selectedAssigneeIds = [currentUserOdooId];
                console.log("✅ MyTasks: TaskList.filterByAssignees =", myTasksList.filterByAssignees);
                console.log("✅ MyTasks: TaskList.selectedAssigneeIds =", JSON.stringify(myTasksList.selectedAssigneeIds));
            } else if (currentAccountId >= 0) {
                // For specific account, filter by that account's current user
                var userOdooId = Account.getCurrentUserOdooId(currentAccountId);
                console.log("🔍 MyTasks: Fallback - Got userOdooId:", userOdooId);
                if (userOdooId > 0) {
                    console.log("✅ MyTasks: Applying assignee filter with fallback user ID:", userOdooId);
                    myTasksList.filterByAssignees = true;
                    myTasksList.selectedAssigneeIds = [userOdooId];
                }
            } else {
                console.warn("⚠️ MyTasks: No valid user ID found for filtering!");
            }
            
            console.log("📋 MyTasks: About to apply filter:", filterKey);
            myTasksList.applyFilter(filterKey);
        }

        onCustomSearch: {
            myTasksPage.currentSearchQuery = query;
            
            // Update current user before applying search
            updateCurrentUser();
            
            // Set up assignee filtering for current user
            if (currentUserOdooId > 0) {
                myTasksList.filterByAssignees = true;
                myTasksList.selectedAssigneeIds = [currentUserOdooId];
            } else if (currentAccountId >= 0) {
                // For specific account, filter by that account's current user
                var userOdooId = Account.getCurrentUserOdooId(currentAccountId);
                if (userOdooId > 0) {
                    myTasksList.filterByAssignees = true;
                    myTasksList.selectedAssigneeIds = [userOdooId];
                }
            }
            
            myTasksList.applySearch(query);
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

            filterByAccount: true
            selectedAccountId: -1
            
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

            if (currentSearchQuery) {
                // Reapply search if there was one
                updateCurrentUser();
                myTasksList.searchTasks(currentSearchQuery);
            } else {
                // Reapply current filter
                updateCurrentUser();
                myTasksList.applyFilter(currentFilter);
            }
        }
    }

    // Listen for account selector changes
    Connections {
        target: accountFilter
        onAccountChanged: function (accountId, accountName) {
            console.log("MyTasks: Account filter changed to:", accountName, "ID:", accountId);
            
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
            
            // CRITICAL FIX: If "All Accounts" selected, use default account instead
            if (idNum < 0) {
                idNum = Account.getDefaultAccountId();
                console.log("⚠️ MyTasks: Account changed to 'All Accounts', forcing to default account:", idNum);
            }

            myTasksList.selectedAccountId = idNum;
            
            // Update current user for the new account
            updateCurrentUser();
            
            // Set up assignee filtering for current user
            if (currentUserOdooId > 0) {
                myTasksList.filterByAssignees = true;
                myTasksList.selectedAssigneeIds = [currentUserOdooId];
            } else if (idNum >= 0) {
                var userOdooId = Account.getCurrentUserOdooId(idNum);
                if (userOdooId > 0) {
                    myTasksList.filterByAssignees = true;
                    myTasksList.selectedAssigneeIds = [userOdooId];
                }
            }

            // Reapply current filter/search
            if (currentSearchQuery) {
                myTasksList.applySearch(currentSearchQuery);
            } else {
                myTasksList.applyFilter(currentFilter);
            }
        }
    }

    Connections {
        target: mainView
        onGlobalAccountChanged: function (accountId, accountName) {
            console.log("MyTasks: GlobalAccountChanged →", accountId, accountName);
            
            var acctNum = -1;
            if (typeof accountId !== "undefined" && accountId !== null) {
                var maybe = Number(accountId);
                acctNum = isNaN(maybe) ? -1 : maybe;
            }
            
            // CRITICAL FIX: If "All Accounts" selected, use default account instead
            if (acctNum < 0) {
                acctNum = Account.getDefaultAccountId();
                console.log("⚠️ MyTasks: GlobalAccountChanged to 'All Accounts', forcing to default account:", acctNum);
            }
            
            myTasksList.selectedAccountId = acctNum;

            // Update current user for the new account
            updateCurrentUser();
            
            // Set up assignee filtering for current user
            if (currentUserOdooId > 0) {
                myTasksList.filterByAssignees = true;
                myTasksList.selectedAssigneeIds = [currentUserOdooId];
            } else if (acctNum >= 0) {
                var userOdooId = Account.getCurrentUserOdooId(acctNum);
                if (userOdooId > 0) {
                    myTasksList.filterByAssignees = true;
                    myTasksList.selectedAssigneeIds = [userOdooId];
                }
            }

            if (currentSearchQuery) {
                myTasksList.applySearch(currentSearchQuery);
            } else {
                myTasksList.applyFilter(currentFilter);
            }
        }
        onAccountDataRefreshRequested: function (accountId) {
            var acctNum = -1;
            if (typeof accountId !== "undefined" && accountId !== null) {
                var maybe2 = Number(accountId);
                acctNum = isNaN(maybe2) ? -1 : maybe2;
            }
            myTasksList.selectedAccountId = acctNum;

            // Update current user
            updateCurrentUser();
            
            // Set up assignee filtering for current user
            if (currentUserOdooId > 0) {
                myTasksList.filterByAssignees = true;
                myTasksList.selectedAssigneeIds = [currentUserOdooId];
            } else if (acctNum >= 0) {
                var userOdooId = Account.getCurrentUserOdooId(acctNum);
                if (userOdooId > 0) {
                    myTasksList.filterByAssignees = true;
                    myTasksList.selectedAssigneeIds = [userOdooId];
                }
            }

            if (currentSearchQuery) {
                myTasksList.applySearch(currentSearchQuery);
            } else {
                myTasksList.applyFilter(currentFilter);
            }
        }
    }

    Component.onCompleted: {
        // Determine initial account selection from accountFilter
        // CRITICAL: MyTasks MUST have a specific account selected, not "All Accounts" (-1)
        // because we need to know which user is logged in to that account
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
            
            // CRITICAL FIX: If "All Accounts" (-1) is selected, default to the default account
            // because MyTasks requires knowing the logged-in user
            if (initialAccountNum < 0) {
                initialAccountNum = Account.getDefaultAccountId();
                console.log("⚠️ MyTasks: 'All Accounts' not supported, defaulting to account:", initialAccountNum);
            }

            console.log("MyTasks initial account selection (numeric):", initialAccountNum);
            myTasksList.selectedAccountId = initialAccountNum;
        } catch (e) {
            console.error("MyTasks: error determining initial account:", e);
            // Fallback to default account instead of -1
            var fallbackAccountId = Account.getDefaultAccountId();
            console.log("⚠️ MyTasks: Error occurred, falling back to default account:", fallbackAccountId);
            myTasksList.selectedAccountId = fallbackAccountId >= 0 ? fallbackAccountId : 0;
        }

        console.log("🚀 MyTasks: Component.onCompleted - Initial setup");
        
        // Get current user and set up filtering
        updateCurrentUser();
        
        // Set up assignee filtering for current user
        if (currentUserOdooId > 0) {
            myTasksList.filterByAssignees = true;
            myTasksList.selectedAssigneeIds = [currentUserOdooId];
            console.log("✅ MyTasks: Component.onCompleted - Filtering by current user:", currentUserOdooId);
            console.log("✅ MyTasks: Component.onCompleted - TaskList.filterByAssignees =", myTasksList.filterByAssignees);
            console.log("✅ MyTasks: Component.onCompleted - TaskList.selectedAssigneeIds =", JSON.stringify(myTasksList.selectedAssigneeIds));
        } else if (currentAccountId >= 0) {
            var userOdooId = Account.getCurrentUserOdooId(currentAccountId);
            console.log("🔍 MyTasks: Component.onCompleted - Fallback userOdooId:", userOdooId);
            if (userOdooId > 0) {
                myTasksList.filterByAssignees = true;
                myTasksList.selectedAssigneeIds = [userOdooId];
                console.log("✅ MyTasks: Component.onCompleted - Filtering by current user (fallback):", userOdooId);
            } else {
                console.warn("⚠️ MyTasks: Component.onCompleted - No valid user ID found!");
            }
        } else {
            console.warn("⚠️ MyTasks: Component.onCompleted - currentAccountId is invalid:", currentAccountId);
        }
        
        // Apply initial filter
        console.log("📋 MyTasks: Component.onCompleted - Applying initial filter:", currentFilter);
        myTasksList.applyFilter(currentFilter);
    }
}
