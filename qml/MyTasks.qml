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
        },
        Action {
            iconName: showFoldedTasks ? "close" : "filters"
            text: showFoldedTasks ? "Hide Closed" : "Show Closed"
            onTriggered: {
                showFoldedTasks = !showFoldedTasks;
                // Refresh the task list with the new filter
                if (currentUserOdooId > 0)
                {
                    var stageTasks = Task.getTasksByPersonalStage(currentPersonalStageId, [currentUserOdooId], defaultAccountId, showFoldedTasks);
                    myTasksList.updateDisplayedTasks(stageTasks);
                }
            }
        }
    ]
}

// Properties for filter and search state
property var personalStages: []
property var currentPersonalStageId: null  // null = "All", 0 = "No Stage", >0 = specific stage
    property string currentSearchQuery: ""
        property bool showFoldedTasks: false  // Toggle for showing closed/folded tasks

            // Properties for current user filtering
            property int currentUserOdooId: -1
                property int defaultAccountId: Account.getDefaultAccountId()

                // Function to load personal stages for the current user
                function loadPersonalStages()
                {
                    if (currentUserOdooId <= 0 || defaultAccountId < 0)
                    {
                        personalStages = [];
                        return;
                    }

                    var stages = Task.getPersonalStagesForUser(currentUserOdooId, defaultAccountId);

                    // Start with loaded stages
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

                personalStages = allStages;            // Update the ListHeader with dynamic labels (preserves current filter)
                updateListHeaderWithStages();

                // Only set initial filter on first load (when currentPersonalStageId is undefined)
                if (currentPersonalStageId === undefined && personalStages.length > 0)
                {
                    currentPersonalStageId = personalStages[0].odoo_record_id;
                }
            }

            // Function to update ListHeader with personal stage names
            function updateListHeaderWithStages()
            {
                if (personalStages.length === 0)
                {
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
            if (currentPersonalStageId !== null && currentPersonalStageId !== undefined)
            {
                myTaskListHeader.currentFilter = String(currentPersonalStageId);
            } else if (myTaskListHeader.currentFilter === "" && filterModel.length > 0) {
            myTaskListHeader.currentFilter = filterModel[0].filterKey;
        }
    }

    // Function to get current user's odoo_record_id for the DEFAULT account
    // MyTasks ALWAYS uses the default account set in Settings page
    function updateCurrentUser()
    {
        // ALWAYS use the default account from Settings
        var accountId = Account.getDefaultAccountId();

        if (accountId >= 0)
        {
            currentUserOdooId = Account.getCurrentUserOdooId(accountId);
        } else {
        currentUserOdooId = -1;
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
        // Parse filterKey to get personal stage ID
        // filterKey is string: "null" for All, "0" for No Stage, or actual stage ID
        var stageId;
        if (filterKey === "null")
        {
            stageId = null;  // Show all tasks
        } else {
        stageId = parseInt(filterKey);
    }

    myTasksPage.currentPersonalStageId = stageId;

    // Update current user before applying filter
    updateCurrentUser();

    if (currentUserOdooId > 0)
    {
        // Get tasks by personal stage, respecting folded task filter
        var stageTasks = Task.getTasksByPersonalStage(stageId, [currentUserOdooId], defaultAccountId, showFoldedTasks);

        // Update the task list directly
        myTasksList.updateDisplayedTasks(stageTasks);
    }
}

onCustomSearch: {
    myTasksPage.currentSearchQuery = query;

    // Update current user before applying search
    updateCurrentUser();

    if (currentUserOdooId > 0)
    {
        // For search, show all tasks (personal stage = null) that match search, respecting folded task filter
        var stageTasks = Task.getTasksByPersonalStage(null, [currentUserOdooId], defaultAccountId, showFoldedTasks);

        // Apply search filter
        if (query && query.trim() !== "")
        {
            var searchLower = query.toLowerCase();
            stageTasks = stageTasks.filter(function(task) {
            return (task.name && task.name.toLowerCase().indexOf(searchLower) >= 0) ||
            (task.description && task.description.toLowerCase().indexOf(searchLower) >= 0);
        });
    }

    myTasksList.updateDisplayedTasks(stageTasks);
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
            text: "Showing closed/completed tasks"
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
    if (result.success)
    {
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
    if (check.hasChildren)
    {
        notifPopup.open("Blocked", "This task has child tasks. Please delete them first.", "warning");
    } else {
    var result = Task.markTaskAsDeleted(recordId);
    if (!result.success)
    {
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
    if (index === 0)
    {
        apLayout.addPageToNextColumn(myTasksPage, Qt.resolvedUrl("Tasks.qml"), {
        "recordid": 0,
        "isReadOnly": false
    });
}
}
}

onVisibleChanged: {
    if (visible)
    {
        // Update navigation tracking
        Global.setLastVisitedPage("MyTasks");

        // Refresh user data and personal stages when page becomes visible
        updateCurrentUser();
        loadPersonalStages();

        // Apply current personal stage filter
        if (currentUserOdooId > 0)
        {
            var stageTasks = Task.getTasksByPersonalStage(currentPersonalStageId, [currentUserOdooId], defaultAccountId, showFoldedTasks);
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
    // Get current user from DEFAULT account
    updateCurrentUser();

    // Load personal stages for the current user
    if (currentUserOdooId > 0)
    {
        loadPersonalStages();

        // Apply initial personal stage filter (first stage which is "All")
        if (personalStages.length > 0)
        {
            var stageTasks = Task.getTasksByPersonalStage(currentPersonalStageId, [currentUserOdooId], defaultAccountId, showFoldedTasks);
            myTasksList.updateDisplayedTasks(stageTasks);
        }
    }
}
}
