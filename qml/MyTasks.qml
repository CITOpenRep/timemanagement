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
    title: i18n.dtr("ubtms", "My Tasks")

    header: PageHeader {
        id: myTasksHeader
        StyleHints {
            foregroundColor: "white"
            backgroundColor: LomiriColors.orange
            dividerColor: LomiriColors.slate
        }
        title: myTasksPage.title

        trailingActionBar.numberOfSlots: 4

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
                iconName: myTasksList.flatViewMode ? "view-list-symbolic" : "view-grid-symbolic"
                text: myTasksList.flatViewMode ? i18n.dtr("ubtms", "Tree View") : i18n.dtr("ubtms", "Flat View")
                onTriggered: {
                    myTasksList.toggleFlatView();
                }
            },
            Action {
                iconName: "search"
                text: "Search"
                onTriggered: {
                    myTaskListHeader.toggleSearchVisibility();
                }
            },
            Action {
                iconName: showFoldedTasks ? "close" : "filters"
                text: showFoldedTasks ? "Hide Closed" : "Show Closed"
                onTriggered: {
                    showFoldedTasks = !showFoldedTasks;
                    // Refresh the task list with the new filter (paginated)
                    if (currentUserOdooId > 0) {
                        startPaginatedLoad();
                    }
                }
            }
        ]
    }

    // Properties for filter and search state
    property var personalStages: []
    property var currentPersonalStageId: undefined  // undefined = not initialized, null = "All", 0 = "No Stage", >0 = specific stage
    property string currentSearchQuery: ""
    property bool showFoldedTasks: false  // Toggle for showing closed/folded tasks

    // Properties for current user filtering
    property int currentUserOdooId: -1
    property int selectedAccountId: -1  // Tracks the currently selected account, -1 means use default

    // Loading state property
    property bool isLoading: false

    // Timer for deferred loading - gives UI time to render loading indicator
    Timer {
        id: loadingTimer
        interval: 50  // 50ms delay to ensure UI renders
        repeat: false
        property var loadingCallback: null
        onTriggered: {
            if (loadingCallback) {
                loadingCallback();
                loadingCallback = null;
            }
            isLoading = false;
        }
    }

    // Helper function to load tasks with loading indicator
    function loadTasksWithIndicator(callback) {
        isLoading = true;
        loadingTimer.loadingCallback = callback;
        loadingTimer.start();
    }

    // Paginated loading function: fetches a page of tasks from DB
    function loadPersonalStagesDelegate(limit, offset) {
        var effectiveAccountId = getEffectiveAccountId();
        if (currentUserOdooId <= 0) {
            myTasksList.hasMoreItems = false;
            myTasksList.isLoadingMore = false;
            myTasksList.isLoading = false;
            return;
        }

        var result = Task.getTasksByPersonalStagePaginated(
            currentPersonalStageId,
            [currentUserOdooId],
            effectiveAccountId,
            showFoldedTasks,
            currentSearchQuery && currentSearchQuery.trim() !== "" ? currentSearchQuery : null,
            limit,
            offset
        );

        var tasks = result.tasks;
        myTasksList.hasMoreItems = result.hasMore;

        var isAppend = (offset > 0);
        myTasksList.updateDisplayedTasks(tasks, isAppend);
        myTasksList.isLoadingMore = false;
        myTasksList.isLoading = false;
    }

    // Convenience function to reset pagination and load the first page
    function startPaginatedLoad() {
        myTasksList.currentOffset = 0;
        myTasksList.hasMoreItems = true;
        myTasksList.isLoadingMore = false;
        loadPersonalStagesDelegate(myTasksList.pageSize, 0);
    }

    // Function to get the effective account ID (handles -1 for "All Accounts")
    function getEffectiveAccountId() {
        if (selectedAccountId === -1 || selectedAccountId < 0) {
            var defaultId = Account.getDefaultAccountId();
            //console.log("MyTasks: selectedAccountId is", selectedAccountId, "- falling back to default account:", defaultId);
            return defaultId;
        }
        return selectedAccountId;
    }

    // Function to load personal stages for the current user
    function loadPersonalStages() {
        var effectiveAccountId = getEffectiveAccountId();
        if (currentUserOdooId <= 0 || effectiveAccountId < 0) {
            personalStages = [];
            return;
        }

        var stages = Task.getPersonalStagesForUser(currentUserOdooId, effectiveAccountId);                    // Start with loaded stages
        var allStages = [];
        for (var i = 0; i < stages.length; i++) {
            allStages.push(stages[i]);
        }

        // Add "All" option at the end
        allStages.push({
            odoo_record_id: null,
            name: "All",
            sequence: 9999
        });

        personalStages = allStages;

        // console.log("loadPersonalStages: personalStages.length =", personalStages.length);
        // for (var i = 0; i < personalStages.length; i++) {
        //     console.log("  Stage", i, ":", personalStages[i].name, "ID:", personalStages[i].odoo_record_id);
        // }

        // Update the ListHeader with dynamic labels (preserves current filter)
        updateListHeaderWithStages();

        // Only set initial filter on first load (when currentPersonalStageId is undefined)
        if (currentPersonalStageId === undefined && personalStages.length > 0) {
            currentPersonalStageId = personalStages[0].odoo_record_id;
            //   console.log("loadPersonalStages: Initial currentPersonalStageId set to", currentPersonalStageId, "(first stage)");
        }
    }

    // Function to update ListHeader with personal stage names
    function updateListHeaderWithStages() {
        if (personalStages.length === 0) {
            return;
        }

        // Build dynamic filter model for all stages
        var filterModel = [];
        for (var i = 0; i < personalStages.length; i++) {
            var stage = personalStages[i];
            filterModel.push({
                label: stage.name,
                filterKey: String(stage.odoo_record_id)
            });
        }

        // Update the filter model without resetting the current filter
        myTaskListHeader.filterModel = filterModel;

        // Only set currentFilter if it hasn't been set yet or if the current stage is valid
        if (currentPersonalStageId !== null && currentPersonalStageId !== undefined) {
            myTaskListHeader.currentFilter = String(currentPersonalStageId);
        } else if (myTaskListHeader.currentFilter === "" && filterModel.length > 0) {
            myTaskListHeader.currentFilter = filterModel[0].filterKey;
        }
    }

    // Function to get current user's odoo_record_id for the selected account
    function updateCurrentUser() {
        var effectiveAccountId = getEffectiveAccountId();
        if (effectiveAccountId >= 0) {
            currentUserOdooId = Account.getCurrentUserOdooId(effectiveAccountId);
        } else {
            currentUserOdooId = -1;
        }
    }

    // Function to handle account selection changes
    function handleAccountChange(accountId) {
        //console.log("MyTasks: Account changed to", accountId);

        // Normalize account ID to number
        var idNum = -1;
        try {
            if (typeof accountId !== "undefined" && accountId !== null) {
                var maybeNum = Number(accountId);
                idNum = isNaN(maybeNum) ? -1 : maybeNum;
            }
        } catch (e) {
            idNum = -1;
        }

        selectedAccountId = idNum;

        // Reset the personal stage selection
        currentPersonalStageId = undefined;

        // Update current user for the new account
        updateCurrentUser();

        // Reload personal stages for the new account
        loadPersonalStages();

        // Refresh the task list with the first personal stage (paginated)
        if (currentUserOdooId > 0 && personalStages.length > 0 && currentPersonalStageId !== undefined) {
            startPaginatedLoad();
        }
    }

    // Add the ListHeader component
    ListHeader {
        id: myTaskListHeader
        anchors.top: myTasksHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        // Dynamic filter model will be set by updateListHeaderWithStages()
        filterModel: []

        showSearchBox: false
        currentFilter: ""

        onFilterSelected: {
            // Update the ListHeader's currentFilter so the UI highlight moves
            myTaskListHeader.currentFilter = filterKey;

            // Parse filterKey to get personal stage ID
            // filterKey is string: "null" for All, "0" for No Stage, or actual stage ID
            var stageId;
            if (filterKey === "null") {
                stageId = null;  // Show all tasks
            } else {
                stageId = parseInt(filterKey);
            }

            myTasksPage.currentPersonalStageId = stageId;
            myTasksPage.currentSearchQuery = "";

            // Update current user before applying filter
            updateCurrentUser();

            if (currentUserOdooId > 0) {
                loadTasksWithIndicator(function() {
                    startPaginatedLoad();
                });
            }
        }

        onCustomSearch: {
            myTasksPage.currentSearchQuery = query;

            // Update current user before applying search
            updateCurrentUser();

            if (currentUserOdooId > 0) {
                // Search uses the paginated function with search query pushed to SQL
                loadTasksWithIndicator(function() {
                    startPaginatedLoad();
                });
            }
        }
    }

    // Visual indicator when showing folded tasks
    Rectangle {
        id: foldedTasksIndicator
        visible: showFoldedTasks
        anchors.top: myTaskListHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: units.gu(4)
        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#2d5016" : "#dff0d8"
        border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#4caf50" : "#5cb85c"
        border.width: 1

        Row {
            anchors.centerIn: parent
            spacing: units.gu(1)

            Icon {
                name: "info"
                width: units.gu(2)
                height: units.gu(2)
                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#4caf50" : "#3c763d"
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: i18n.dtr("ubtms", "Showing closed/completed tasks")
                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#4caf50" : "#3c763d"
                font.pixelSize: units.gu(1.5)
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    LomiriShape {
        anchors.top: showFoldedTasks ? foldedTasksIndicator.bottom : myTaskListHeader.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: units.gu(1)
        clip: true

        TaskList {
            id: myTasksList
            anchors.fill: parent
            clip: true
            
            // Delegate for pagination
            loadDelegate: loadPersonalStagesDelegate

            // MyTasks does NOT filter by account selection
            // It ALWAYS uses the default account set in Settings
            filterByAccount: false

            // Enable assignee filtering to show only current user's tasks
            filterByAssignees: true
            selectedAssigneeIds: []

            // Set context flag so TaskDetailsCard knows we're in MyTasks
            isMyTasksContext: true

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
            text:i18n.dtr("ubtms", "No Tasks Assigned to You")
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
                label: i18n.dtr("ubtms", "Create")
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



    // Also listen to TSApp signals for when MyTasks is already visible
    Connections {
        target: typeof mainView !== 'undefined' ? mainView : null

        function onAccountDataRefreshRequested(accountId) {
            // console.log("🔄 MyTasks: Refreshing data for account:", accountId);
            if (myTasksPage.visible && accountId >= 0) {
                handleAccountChange(accountId);
            }
        }

        function onGlobalAccountChanged(accountId, accountName) {
            //  console.log("🔄 MyTasks: Global account changed to:", accountId, accountName);
            if (myTasksPage.visible && accountId >= 0) {
                handleAccountChange(accountId);
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            // Update navigation tracking
            Global.setLastVisitedPage("MyTasks");

            // Sync with mainView's current account (primary source of truth)
            if (typeof mainView !== 'undefined' && mainView !== null) {
                if (typeof mainView.currentAccountId !== 'undefined') {
                    var acctId = mainView.currentAccountId;
                    if (acctId !== selectedAccountId && acctId >= -1) {
                        //console.log("MyTasks: Syncing with mainView.currentAccountId on visible:", acctId);
                        handleAccountChange(acctId);
                        return; // handleAccountChange will refresh everything
                    }
                }
            }

            // Refresh user data and personal stages when page becomes visible
            updateCurrentUser();
            loadPersonalStages();

            // Apply current personal stage filter (paginated)
            if (currentUserOdooId > 0) {
                startPaginatedLoad();
            }
        }
    }

    Component.onCompleted: {
        // Sync with mainView's current account (this persists across page loads)
        if (typeof mainView !== 'undefined' && mainView !== null) {
            if (typeof mainView.currentAccountId !== 'undefined') {
                selectedAccountId = mainView.currentAccountId;
                //console.log("MyTasks: Initialized with mainView.currentAccountId:", selectedAccountId);
            }
        }

     

        // Final fallback: use default account
        if (selectedAccountId === -1) {
            selectedAccountId = Account.getDefaultAccountId();
            //console.log("MyTasks: No account selection found, using default account:", selectedAccountId);
        }

        // Get current user from selected account
        updateCurrentUser();

        // Load personal stages for the current user
        if (currentUserOdooId > 0) {
            loadPersonalStages();

            // Apply initial personal stage filter (first stage in the list)
            // Note: "All" is now at the end, so first stage is a specific personal stage
            if (personalStages.length > 0 && currentPersonalStageId !== undefined) {
                loadTasksWithIndicator(function() {
                    startPaginatedLoad();
                });
            }
        }
    }

    // Loading indicator
    LoadingIndicator {
        anchors.fill: parent
        visible: isLoading
        message: i18n.dtr("ubtms", "Loading tasks...")
    }
}
