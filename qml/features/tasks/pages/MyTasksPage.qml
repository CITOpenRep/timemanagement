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
import "../../../../models/timesheet.js" as Timesheet
import "../../../../models/task.js" as Task
import "../../../../models/accounts.js" as Account
import "../../../../models/global.js" as Global
import "../../../components"
import "../components"

Page {
    id: myTasksPage

    property bool isMultiColumn: typeof apLayout !== "undefined" ? apLayout.columns > 1 : false
    property var personalStages: []
    property var currentPersonalStageId: undefined
    property string currentSearchQuery: ""
    property bool showFoldedTasks: false
    property int currentUserOdooId: -1
    property int selectedAccountId: -1
    property bool isLoading: false

    title: i18n.dtr("ubtms", "My Tasks")

    header: PageHeader {
        id: myTasksHeader

        StyleHints {
            foregroundColor: "white"
            backgroundColor: LomiriColors.orange
            dividerColor: LomiriColors.slate
        }

        leadingActionBar.actions: [
            Action {
                id: drawerAction
                iconName: "navigation-menu"
                text: i18n.dtr("ubtms", "Menu")
                visible: !isMultiColumn
                onTriggered: apLayout.openGlobalDrawer()
            }
        ]

        title: myTasksPage.title
        trailingActionBar.numberOfSlots: 5
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
                onTriggered: myTasksList.toggleFlatView()
            },
            Action {
                iconName: "search"
                text: "Search"
                onTriggered: myTaskListHeader.toggleSearchVisibility()
            },
            Action {
                iconName: "help"
                text: i18n.dtr("ubtms", "Stage Help")
                onTriggered: {
                    notifPopup.open(
                        i18n.dtr("ubtms", "Personal Stages Help"),
                        i18n.dtr("ubtms", "If personal stages are not visible, please check the following:<br><br><b>1) Ensure stages exist in CURQ:</b><br>Ensure the stages are available in the CURQ instance under 'My Tasks'.<br><br><b>2) Verify the app's Default DB:</b><br>In the app, confirm that you are checked in to the correct database as Default, as My Tasks displays tasks based on the selected Default DB."),
                        "info"
                    );
                }
            },
            Action {
                iconName: showFoldedTasks ? "close" : "filters"
                text: showFoldedTasks ? "Hide Closed" : "Show Closed"
                onTriggered: {
                    showFoldedTasks = !showFoldedTasks;
                    if (currentUserOdooId > 0) {
                        startPaginatedLoad();
                    }
                }
            }
        ]
    }

    Timer {
        id: loadingTimer
        interval: 50
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

    function loadTasksWithIndicator(callback) {
        isLoading = true;
        loadingTimer.loadingCallback = callback;
        loadingTimer.start();
    }

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

        myTasksList.hasMoreItems = result.hasMore;
        myTasksList.updateDisplayedTasks(result.tasks, offset > 0);
        myTasksList.isLoadingMore = false;
        myTasksList.isLoading = false;
    }

    function startPaginatedLoad() {
        myTasksList.currentOffset = 0;
        myTasksList.hasMoreItems = true;
        myTasksList.isLoadingMore = false;
        loadPersonalStagesDelegate(myTasksList.pageSize, 0);
    }

    function getEffectiveAccountId() {
        if (selectedAccountId === -1 || selectedAccountId < 0) {
            return Account.getDefaultAccountId();
        }
        return selectedAccountId;
    }

    function loadPersonalStages() {
        var effectiveAccountId = getEffectiveAccountId();
        if (currentUserOdooId <= 0 || effectiveAccountId < 0) {
            personalStages = [];
            return;
        }

        var stages = Task.getPersonalStagesForUser(currentUserOdooId, effectiveAccountId);
        var allStages = [];
        for (var i = 0; i < stages.length; i++) {
            allStages.push(stages[i]);
        }

        allStages.push({
            odoo_record_id: null,
            name: "All",
            sequence: 9999
        });

        personalStages = allStages;
        updateListHeaderWithStages();

        if (currentPersonalStageId === undefined && personalStages.length > 0) {
            currentPersonalStageId = personalStages[0].odoo_record_id;
        }
    }

    function updateListHeaderWithStages() {
        if (personalStages.length === 0) {
            return;
        }

        var filterModel = [];
        for (var i = 0; i < personalStages.length; i++) {
            var stage = personalStages[i];
            filterModel.push({
                label: stage.name,
                filterKey: String(stage.odoo_record_id)
            });
        }

        myTaskListHeader.filterModel = filterModel;

        if (currentPersonalStageId !== null && currentPersonalStageId !== undefined) {
            myTaskListHeader.currentFilter = String(currentPersonalStageId);
        } else if (myTaskListHeader.currentFilter === "" && filterModel.length > 0) {
            myTaskListHeader.currentFilter = filterModel[0].filterKey;
        }
    }

    function updateCurrentUser() {
        var effectiveAccountId = getEffectiveAccountId();
        currentUserOdooId = effectiveAccountId >= 0 ? Account.getCurrentUserOdooId(effectiveAccountId) : -1;
    }

    function clearCurrentTasks() {
        personalStages = [];
        currentPersonalStageId = undefined;
        myTaskListHeader.filterModel = [];
        myTaskListHeader.currentFilter = "";
        myTasksList.currentOffset = 0;
        myTasksList.hasMoreItems = false;
        myTasksList.isLoadingMore = false;
        myTasksList.isLoading = false;
        myTasksList.updateDisplayedTasks([], false);
    }

    function handleAccountChange(accountId) {
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
        currentPersonalStageId = undefined;
        updateCurrentUser();

        if (currentUserOdooId <= 0) {
            clearCurrentTasks();
            return;
        }

        loadPersonalStages();

        if (currentUserOdooId > 0 && personalStages.length > 0 && currentPersonalStageId !== undefined) {
            loadTasksWithIndicator(function() {
                startPaginatedLoad();
            });
        } else {
            clearCurrentTasks();
        }
    }

    function refreshData() {
        if (typeof mainView !== "undefined" && mainView !== null && typeof mainView.currentAccountId !== "undefined") {
            var acctId = mainView.currentAccountId;
            if (acctId !== selectedAccountId && acctId >= -1) {
                handleAccountChange(acctId);
                return;
            }
        }

        updateCurrentUser();
        loadPersonalStages();

        if (currentUserOdooId > 0) {
            startPaginatedLoad();
        } else {
            clearCurrentTasks();
        }
    }

    ListHeader {
        id: myTaskListHeader
        anchors.top: myTasksHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        filterModel: []
        showSearchBox: false
        currentFilter: ""

        onFilterSelected: {
            myTaskListHeader.currentFilter = filterKey;

            var stageId = filterKey === "null" ? null : parseInt(filterKey);
            myTasksPage.currentPersonalStageId = stageId;
            myTasksPage.currentSearchQuery = "";

            updateCurrentUser();
            if (currentUserOdooId > 0) {
                loadTasksWithIndicator(function() {
                    startPaginatedLoad();
                });
            }
        }

        onCustomSearch: {
            myTasksPage.currentSearchQuery = query;
            updateCurrentUser();

            if (currentUserOdooId > 0) {
                loadTasksWithIndicator(function() {
                    startPaginatedLoad();
                });
            }
        }
    }

    MyTasksClosedIndicator {
        id: foldedTasksIndicator
        visible: showFoldedTasks
        anchors.top: myTaskListHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: units.gu(4)
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
            loadDelegate: loadPersonalStagesDelegate
            filterByAccount: false
            filterByAssignees: true
            selectedAssigneeIds: []
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
                var result = Timesheet.createTimesheetFromTask(localId);
                if (result.success) {
                    apLayout.addPageToNextColumn(myTasksPage, Qt.resolvedUrl("../../timesheets/pages/Timesheet.qml"), {
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
                        apLayout.addPageToCurrentColumn(myTasksPage, Qt.resolvedUrl("MyTasksPage.qml"));
                    }
                }
            }
        }

        Text {
            id: labelNoTask
            anchors.centerIn: parent
            font.pixelSize: units.gu(2)
            visible: false
            text: i18n.dtr("ubtms", "No Tasks Assigned to You")
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
            }
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

    Connections {
        target: accountPicker

        onAccepted: function(id, name) {
            handleAccountChange(id);
        }
    }

    Connections {
        target: typeof mainView !== "undefined" ? mainView : null

        function onAccountDataRefreshRequested(accountId) {
            if (accountId >= -1 && accountId !== selectedAccountId) {
                handleAccountChange(accountId);
            }
        }

        function onGlobalAccountChanged(accountId, accountName) {
            if (accountId >= -1 && accountId !== selectedAccountId) {
                handleAccountChange(accountId);
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            Global.setLastVisitedPage("MyTasks");
            refreshData();
        }
    }

    Component.onCompleted: {
        if (typeof mainView !== "undefined" && mainView !== null && typeof mainView.currentAccountId !== "undefined") {
            selectedAccountId = mainView.currentAccountId;
        }

        if (selectedAccountId === -1) {
            selectedAccountId = Account.getDefaultAccountId();
        }

        updateCurrentUser();

        if (currentUserOdooId > 0) {
            loadPersonalStages();
            if (personalStages.length > 0 && currentPersonalStageId !== undefined) {
                loadTasksWithIndicator(function() {
                    startPaginatedLoad();
                });
            }
        }
    }

    LoadingIndicator {
        anchors.fill: parent
        visible: isLoading
        message: i18n.dtr("ubtms", "Loading tasks...")
    }
}
