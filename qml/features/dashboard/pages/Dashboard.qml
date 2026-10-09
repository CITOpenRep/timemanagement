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
import Lomiri.Components 1.3
import QtQuick.Controls 2.2 as Controls
import Lomiri.Components.Popups 1.3
import QtQuick.Layouts 1.3
import "../../../../models/timesheet.js" as TimesheetModel
import "../../../../models/accounts.js" as Account
import "../../../../models/global.js" as Global
import "../../../components"
import "../../../../models/logger.js" as Logger

Page {
    id: mainPage



    title: i18n.dtr("ubtms", "Time Manager - Time Management Dashboard")
    anchors.fill: parent
    property bool isMultiColumn: apLayout.columns > 1
    property bool isLoading: false
    property string loadingMessage: i18n.dtr("ubtms", "Loading dashboard...")
    property int refreshStage: -1
    property int lastRefreshAccountId: -999999
    property var selectedUserId: -1
    property string selectedUserName: i18n.dtr("ubtms", "All Users")
    property var availableUsers: []
    property bool isUserFilterVisible: false
    property int lastFilterAccountId: -999999

    function initUserFilterForCurrentAccount(targetAccountId) {
        var accId = (targetAccountId !== undefined && targetAccountId !== null)
            ? targetAccountId
            : ((typeof accountPicker !== "undefined" && accountPicker && accountPicker.selectedAccountId !== undefined)
                ? accountPicker.selectedAccountId
                : -1);
        lastFilterAccountId = accId;
        isUserFilterVisible = Account.hasManagerOrAdminAccess(accId);
        if (!isUserFilterVisible) {
            assigneeFilterMenu.expanded = false;
        }
        availableUsers = Account.getDashboardFilterUsers(accId);

        var menuAssignees = [];
        for (var i = 0; i < availableUsers.length; i++) {
            var u = availableUsers[i];
            var acctId = (u.accountId !== undefined && u.accountId !== null) ? u.accountId : ((u.account_id !== undefined) ? u.account_id : accId);
            menuAssignees.push({
                id: u.id,
                odoo_record_id: u.id,
                name: u.name,
                email: u.email || "",
                account_name: u.account_name || (u.account_names ? u.account_names.join(", ") : ""),
                account_id: acctId,
                allUserIds: u.allUserIds || [u.id],
                allAccountIds: u.allAccountIds || [acctId]
            });
        }
        assigneeFilterMenu.showAccountName = (accId === -1);
        assigneeFilterMenu.assigneeModel = menuAssignees;

        var defaultUser = Account.getDashboardSingleUserDefault(accId, availableUsers);
        if (defaultUser) {
            selectedUserId = defaultUser.id;
            selectedUserName = defaultUser.name;
            var defSelections = [];
            if (defaultUser.allUserIds && defaultUser.allAccountIds) {
                for (var d = 0; d < defaultUser.allUserIds.length; d++) {
                    defSelections.push(assigneeFilterMenu.createSelection(defaultUser.allUserIds[d], defaultUser.allAccountIds[d] || accId));
                }
            } else {
                var defAcctId = (defaultUser.accountId !== undefined) ? defaultUser.accountId : accId;
                defSelections.push(assigneeFilterMenu.createSelection(defaultUser.id, defAcctId));
            }
            assigneeFilterMenu.selectedAssigneeIds = defSelections;
        } else {
            selectedUserId = -1;
            selectedUserName = i18n.dtr("ubtms", "All Users");
            assigneeFilterMenu.selectedAssigneeIds = [assigneeFilterMenu.createSelection(-1, -1)];
        }
        Global.setDashboardUserFilter(selectedUserId, selectedUserName);
        var appObj = (typeof mainView !== "undefined" && mainView) ? mainView : ((typeof rootApp !== "undefined" && rootApp) ? rootApp : null);
        if (appObj && appObj.globalDashboardUserChanged) {
            appObj.globalDashboardUserChanged(selectedUserId, selectedUserName);
        }
    }

    // Timer for deferred loading - gives UI time to render loading indicator
    Timer {
        id: loadingTimer
        interval: 50  // 50ms delay to ensure UI renders
        repeat: false
        onTriggered: _doRefreshData()
    }

    onVisibleChanged: {
        if (visible) {
            // Update navigation tracking when Dashboard becomes visible
            Global.setLastVisitedPage("Dashboard");

            var currentAccId = (typeof accountPicker !== "undefined" && accountPicker && accountPicker.selectedAccountId !== undefined)
                ? accountPicker.selectedAccountId
                : -1;
            if (lastFilterAccountId !== currentAccId || availableUsers.length === 0) {
                initUserFilterForCurrentAccount(currentAccId);
            }

            refreshData();
        }
    }

    onIsMultiColumnChanged: {
        if (isMultiColumn) {
            if (typeof mobileChartTabBar !== "undefined") {
                mobileChartTabBar.currentIndex = 0;
            }
            if (typeof mobileChartsView !== "undefined") {
                mobileChartsView.currentIndex = 0;
            }
        }
    }


    header: PageHeader {
        id: header
        StyleHints {
            foregroundColor: "white"
            backgroundColor: LomiriColors.orange
            dividerColor: LomiriColors.slate
        }
        contents: FilterableHeaderContents {
            id: headerContents
            title: i18n.dtr("ubtms", "Dashboard")
            userLabel: selectedUserName
            onDateRangeChanged: refreshData()
            
            Component.onCompleted: {
                if (typeof headerContents.dateFilter !== "undefined") {
                    headerContents.dateFilter.clearFilter();
                }
            }
        }
        visible: true

        leadingActionBar.actions: [
            Action {
                id: drawerAction
                iconName: "navigation-menu"
                text: i18n.dtr("ubtms", "Menu")
                visible: !isMultiColumn
                onTriggered: {
                    globalDrawer.open()
                }
            }
        ]

        trailingActionBar.numberOfSlots: 6
        trailingActionBar.actions: [
            Action {
                id: infoAction
                iconName: "info"
                visible: !isMultiColumn && !headerContents.showDateFilter
                text: i18n.dtr("ubtms", "Chart Info")
                onTriggered: {
                    PopupUtils.open(Qt.resolvedUrl("../components/ChartInfoPopup.qml"))
                }
            },
            Action {
                id: notificationAction
                iconSource: notificationBell.totalCount > 0 ? "../../../images/notification_active.png" : "../../../images/notification.png"
                visible: !headerContents.showDateFilter
                text: notificationBell.totalCount > 0 ? 
                      i18n.dtr("ubtms", "Notifications") + " (" + notificationBell.totalCount + ")" : 
                      i18n.dtr("ubtms", "Notifications")
                onTriggered: {
                    notificationBell.loadNotifications();
                    if (notificationBell.totalCount > 0) {
                        notificationBell.openPopup();
                    } else {
                        notifPopup.open("No Notifications", "You have no new notifications", "info");
                    }
                }
            },
            Action {
                iconName: "reminder-new"
                text: i18n.dtr("ubtms", "New Timesheet")
                visible: !headerContents.showDateFilter
                onTriggered: {
                    openNewTimesheetPage(false);
                }
            },
            Action {
                id: userFilterAction
                iconName: (Array.isArray(selectedUserId) && selectedUserId.length > 1) ? "contact-group" : "contact"
                text: selectedUserName ? selectedUserName : i18n.dtr("ubtms", "All Users")
                visible: !headerContents.showDateFilter && isUserFilterVisible
                onTriggered: {
                    assigneeFilterMenu.expanded = !assigneeFilterMenu.expanded;
                }
            },
            Action {
                id: filterAction
                iconName: "filters"
                text: (typeof headerContents.dateFilter !== "undefined" && headerContents.dateFilter.isFiltered) ? 
                      i18n.dtr("ubtms", "Filter (Active)") : 
                      i18n.dtr("ubtms", "Filter")
                visible: !headerContents.showDateFilter
                onTriggered: {
                    headerContents.showDateFilter = true;
                }
            }
        ]
    }

    function openNewTimesheetPage(useNextColumn) {
        var targetAccountId = (accountPicker && accountPicker.selectedAccountId >= 0) ? accountPicker.selectedAccountId : Account.getDefaultAccountId();
        if (targetAccountId < 0) {
            targetAccountId = 0;
        }
        var targetUserId = Account.getCurrentUserOdooId(targetAccountId);
        if (targetAccountId === 0 && (!targetUserId || targetUserId <= 0)) {
            targetUserId = 1;
        }
        const result = TimesheetModel.createTimesheet(targetAccountId, targetUserId);
        if (result.success) {
            if (useNextColumn) {
                apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("../../timesheets/pages/Timesheet.qml"), {
                    "recordid": result.id,
                    "isReadOnly": false
                });
            } else {
                apLayout.addPageToCurrentColumn(mainPage, Qt.resolvedUrl("../../timesheets/pages/Timesheet.qml"), {
                    "recordid": result.id,
                    "isReadOnly": false
                });
            }
        } else {
            Logger.error("Dashboard", "Error creating timesheet: " + (result.error || result.message));
        }
    }

    function refreshData(force) {
        Logger.debug("Dashboard", "Refreshing Dashboard data...")
        var targetAccountId = (typeof accountPicker !== "undefined") ? accountPicker.selectedAccountId : -1;
        if (!force && isLoading && lastRefreshAccountId === targetAccountId) {
            return;
        }

        lastRefreshAccountId = targetAccountId;
        loadingTimer.stop();
        loadingMessage = targetAccountId === -1
            ? i18n.dtr("ubtms", "Preparing all-account dashboard...")
            : i18n.dtr("ubtms", "Preparing dashboard...");
        isLoading = true;
        // Use Timer to defer the actual data loading,
        // giving QML time to render the loading indicator first
        loadingTimer.interval = 50;
        loadingTimer.start();
    }

    function finishRefreshData() {
        loadingTimer.stop();
        refreshStage = -1;
        loadingMessage = i18n.dtr("ubtms", "Loading dashboard...");
        isLoading = false;
    }

    function _doRefreshData() {
        try {
            var filterData = Global.getDateRangeFilter();
            var sDate = (filterData && filterData.isFiltered) ? filterData.startDate : "";
            var eDate = (filterData && filterData.isFiltered) ? filterData.endDate : "";
            var activeAccId = (typeof accountPicker !== "undefined") ? accountPicker.selectedAccountId : -1;
            var uid = (selectedUserId !== undefined && selectedUserId !== null && selectedUserId !== -1) ? selectedUserId : (Global.getDashboardUserFilter() ? Global.getDashboardUserFilter().userId : -1);

            Logger.debug("Dashboard", "Executing Dashboard refresh for user: " + JSON.stringify(uid) + ", account: " + activeAccId);

            // 1. Priority Matrix (Eisenhower)
            if (typeof ehoverMatrix !== "undefined" && ehoverMatrix.refreshQuadrants) {
                ehoverMatrix.refreshQuadrants(sDate, eDate, uid, activeAccId);
            }

            // 2. Overview Pie Chart
            if (typeof projectchart !== "undefined" && typeof projectchart.refreshForAccount === "function") {
                projectchart.refreshForAccount(activeAccId, sDate, eDate, uid);
            }

            // 3. Mobile tab loaders (Projects & Tasks charts)
            if (mobileProjectChartLoader.item && typeof mobileProjectChartLoader.item.reloadData === "function") {
                mobileProjectChartLoader.item.selectedAccountId = activeAccId;
                mobileProjectChartLoader.item.selectedUserId = uid;
                mobileProjectChartLoader.item.reloadData(sDate, eDate, activeAccId, uid);
            }

            if (mobileTaskChartLoader.item && typeof mobileTaskChartLoader.item.reloadData === "function") {
                mobileTaskChartLoader.item.selectedAccountId = activeAccId;
                mobileTaskChartLoader.item.selectedUserId = uid;
                mobileTaskChartLoader.item.reloadData(sDate, eDate, activeAccId, uid);
            }
        } catch(e) {
            Logger.error("Dashboard", "_doRefreshData ERROR: ", e);
        }
        finishRefreshData();
    }

    DialerMenu {
        id: fabMenu
        anchors.fill: parent
        z: 9999
        menuModel: [
            {
                label: i18n.dtr("ubtms", "Task"),
                iconName: "scope-manager"
            },
            {
                label: i18n.dtr("ubtms", "Timesheet"),
                iconName: "alarm-clock"
            },
            {
                label: i18n.dtr("ubtms", "Activity"),
                iconName: "calendar"
            }
        ]
        onMenuItemSelected: {
            if (index === 0) {
                apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("../../tasks/pages/Tasks.qml"), {
                    "recordid": 0,
                    "isReadOnly": false
                });
            }
            if (index === 1) {
                openNewTimesheetPage(true);
            }
            if (index === 2) {
                apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("../../activities/pages/Activities.qml"), {
                    "isReadOnly": false
                });
            }
        }
    }

    Flickable {
        id: flick1
        width: parent.width
        height: parent.height - header.height
        anchors.top: header.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        contentWidth: parent.width
        contentHeight: quadrantColumn.height + units.gu(4)
        rebound: Transition {
            NumberAnimation {
                properties: "x,y"
                duration: 1000
                easing.type: Easing.OutBounce
            }
        }

        Column {
            id: quadrantColumn
            width: parent.width
            spacing: units.gu(3)
            anchors.top: parent.top
            anchors.margins: units.gu(1)

            Item {
                id: quadrantWrapper
                width: parent.width
                height: width
                anchors.horizontalCenter: parent.horizontalCenter

                Rectangle {
                    id: quadrantContainer
                    anchors.fill: parent
                    anchors.margins: units.gu(1)
                    color: "transparent"
                    radius: units.gu(1)
                    border.color: "transparent"
                    border.width: 0

                    EHower {
                        id: ehoverMatrix
                        width: parent.width * 0.98
                        height: width
                        autoRefreshOnAccountChange: false
                        anchors.centerIn: parent
                        onQuadrantClicked: {}
                    }
                }
            }

            Item {
                id: mobileChartsTabs
                width: parent.width - units.gu(2)
                height: mobileChartsColumn.height
                anchors.horizontalCenter: parent.horizontalCenter
                visible: true

                Column {
                    id: mobileChartsColumn
                    width: parent.width
                    spacing: units.gu(1)

                    Controls.TabBar {
                        id: mobileChartTabBar
                        width: parent.width
                        visible: !isMultiColumn
                        height: visible ? implicitHeight : 0
                        currentIndex: 0
                        onCurrentIndexChanged: {
                            if (mobileChartsView.currentIndex !== currentIndex)
                                mobileChartsView.currentIndex = currentIndex;
                        }

                        background: Rectangle {
                            color: Theme.palette.normal.background
                            radius: units.gu(1)
                            border.width: 1
                            border.color: Theme.palette.normal.base
                        }

                        Controls.TabButton {
                            text: i18n.dtr("ubtms", "Overview")
                            width: mobileChartTabBar.width / 3
                            contentItem: Text {
                                text: parent.text
                                font: parent.font
                                color: Theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Controls.TabButton {
                            text: i18n.dtr("ubtms", "Projects")
                            width: mobileChartTabBar.width / 3
                            contentItem: Text {
                                text: parent.text
                                font: parent.font
                                color: Theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Controls.TabButton {
                            text: i18n.dtr("ubtms", "Tasks")
                            width: mobileChartTabBar.width / 3
                            contentItem: Text {
                                text: parent.text
                                font: parent.font
                                color: Theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }

                    Controls.SwipeView {
                        id: mobileChartsView
                        width: parent.width
                        height: currentIndex === 0 ? projectchart.implicitHeight
                               : currentIndex === 1 && mobileProjectChartLoader.item ? mobileProjectChartLoader.item.implicitHeight
                               : currentIndex === 2 && mobileTaskChartLoader.item ? mobileTaskChartLoader.item.implicitHeight
                               : units.gu(40)
                        currentIndex: 0
                        interactive: !isMultiColumn
                        clip: true
                        onCurrentIndexChanged: {
                            if (mobileChartTabBar.currentIndex !== currentIndex)
                                mobileChartTabBar.currentIndex = currentIndex;

                            var filterData = Global.getDateRangeFilter();
                            var sDate = (filterData && filterData.isFiltered) ? filterData.startDate : "";
                            var eDate = (filterData && filterData.isFiltered) ? filterData.endDate : "";
                            var accId = typeof accountPicker !== "undefined" ? accountPicker.selectedAccountId : -1;
                            var uid = (selectedUserId !== undefined && selectedUserId !== null && selectedUserId !== -1) ? selectedUserId : (Global.getDashboardUserFilter() ? Global.getDashboardUserFilter().userId : -1);

                            if (currentIndex === 0) {
                                if (typeof projectchart !== "undefined" && typeof projectchart.refreshForAccount === "function") {
                                    projectchart.refreshForAccount(accId, sDate, eDate, uid);
                                }
                            } else if (currentIndex === 1) {
                                if (mobileProjectChartLoader.item && typeof mobileProjectChartLoader.item.reloadData === "function") {
                                    mobileProjectChartLoader.item.selectedAccountId = accId;
                                    mobileProjectChartLoader.item.selectedUserId = uid;
                                    mobileProjectChartLoader.item.reloadData(sDate, eDate, accId, uid);
                                }
                            } else if (currentIndex === 2) {
                                if (mobileTaskChartLoader.item && typeof mobileTaskChartLoader.item.reloadData === "function") {
                                    mobileTaskChartLoader.item.selectedAccountId = accId;
                                    mobileTaskChartLoader.item.selectedUserId = uid;
                                    mobileTaskChartLoader.item.reloadData(sDate, eDate, accId, uid);
                                }
                            }
                        }

                        Item {
                            ProjectPieChart {
                                id: projectchart
                                width: parent.width * 0.95
                                height: implicitHeight
                                autoRefreshOnAccountChange: false
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }

                        Item {
                            Loader {
                                id: mobileProjectChartLoader
                                anchors.fill: parent
                                active: !isMultiColumn
                                source: "../charts/Charts3.qml"
                                onLoaded: {
                                    if (item) {
                                        item.autoRefreshOnAccountChange = false;
                                        var accId = typeof accountPicker !== "undefined" ? accountPicker.selectedAccountId : -1;
                                        var uid = (selectedUserId !== undefined && selectedUserId !== null && selectedUserId !== -1) ? selectedUserId : (Global.getDashboardUserFilter() ? Global.getDashboardUserFilter().userId : -1);
                                        item.selectedAccountId = accId;
                                        item.selectedUserId = uid;
                                        var filterData = Global.getDateRangeFilter();
                                        var sDate = (filterData && filterData.isFiltered) ? filterData.startDate : "";
                                        var eDate = (filterData && filterData.isFiltered) ? filterData.endDate : "";
                                        item.reloadData(sDate, eDate, accId, uid);
                                    }
                                }
                            }
                        }

                        Item {
                            Loader {
                                id: mobileTaskChartLoader
                                anchors.fill: parent
                                active: !isMultiColumn
                                source: "../charts/Charts4.qml"
                                onLoaded: {
                                    if (item) {
                                        item.autoRefreshOnAccountChange = false;
                                        var accId = typeof accountPicker !== "undefined" ? accountPicker.selectedAccountId : -1;
                                        var uid = (selectedUserId !== undefined && selectedUserId !== null && selectedUserId !== -1) ? selectedUserId : (Global.getDashboardUserFilter() ? Global.getDashboardUserFilter().userId : -1);
                                        item.selectedAccountId = accId;
                                        item.selectedUserId = uid;
                                        var filterData = Global.getDateRangeFilter();
                                        var sDate = (filterData && filterData.isFiltered) ? filterData.startDate : "";
                                        var eDate = (filterData && filterData.isFiltered) ? filterData.endDate : "";
                                        item.reloadData(sDate, eDate, accId, uid);
                                    }
                                }
                            }
                        }
                    }
                }
            }

        } // end Column
    } // end Flickable

    Scrollbar {
        flickableItem: flick1
        align: Qt.AlignTrailing
    }

    Timer {
        interval: 100
        running: true
        repeat: false
        onTriggered: {
            if (apLayout.columns === 3) {
                apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("Dashboard2.qml"));
            }
        }
    }

    BottomEdge {
        id: bottomEdge
        enabled: !isMultiColumn
        height: parent.height

        hint {
            iconName: "add"
            text: i18n.dtr("ubtms", "New Timesheet")
            visible: !isMultiColumn
        }

        preloadContent: false

        contentComponent: Component {
            Item {
                width: bottomEdge.width
                height: bottomEdge.height
            }
        }

        onCommitCompleted: {
            openNewTimesheetPage(true);
            collapse();
        }
    }

    Connections {
        target: typeof accountPicker !== "undefined" ? accountPicker : null
        onSelectedAccountIdChanged: {
            if (accountPicker.selectedAccountName) {
                header.title = i18n.dtr("ubtms", "Account") + " [" + accountPicker.selectedAccountName + "]";
            }
            initUserFilterForCurrentAccount(accountPicker.selectedAccountId);
            refreshData();
        }
        onAccepted: function (accountId, accountName) {
            header.title = i18n.dtr("ubtms", "Account") + " [" + accountName + "]";
            initUserFilterForCurrentAccount(accountId);
            refreshData();
        }
    }

    Connections {
        target: (typeof mainView !== "undefined" && mainView) ? mainView : ((typeof rootApp !== "undefined" && rootApp) ? rootApp : null)
        onGlobalAccountChanged: function (accountId, accountName) {
            header.title = i18n.dtr("ubtms", "Account") + " [" + accountName + "]";
            initUserFilterForCurrentAccount(accountId);
            refreshData(true);
        }
        onAccountDataRefreshRequested: function (accountId) {
            initUserFilterForCurrentAccount(accountId);
            refreshData(true);
        }
        onGlobalDashboardUserChanged: function (userId, userName) {
            selectedUserId = userId;
            selectedUserName = userName;
            if (userId === -1 || userId === "-1") {
                assigneeFilterMenu.selectedAssigneeIds = [assigneeFilterMenu.createSelection(-1, -1)];
            } else if (Array.isArray(userId)) {
                assigneeFilterMenu.selectedAssigneeIds = userId.slice();
            } else {
                var accId = (typeof accountPicker !== "undefined") ? accountPicker.selectedAccountId : -1;
                assigneeFilterMenu.selectedAssigneeIds = [assigneeFilterMenu.createSelection(userId, accId)];
            }
            refreshData(true);
        }
    }

    Connections {
        target: typeof mainView !== "undefined" ? mainView : null
        onGlobalDateRangeChanged: function (presetId, startDate, endDate, presetLabel) {
            refreshData(true);
        }
    }

    function handleAssigneeFilterApplied(assigneeIds) {
        var rawIds = assigneeIds || [];
        var isAllUsers = false;
        for (var k = 0; k < rawIds.length; k++) {
            var itm = rawIds[k];
            var uidVal = (typeof itm === "object") ? itm.user_id : itm;
            if (uidVal === -1 || uidVal === "-1") {
                isAllUsers = true;
                break;
            }
        }

        if (isAllUsers) {
            selectedUserId = -1;
            selectedUserName = i18n.dtr("ubtms", "All Users");
            assigneeFilterMenu.selectedAssigneeIds = [assigneeFilterMenu.createSelection(-1, -1)];
            Global.setDashboardUserFilter(-1, selectedUserName);
            var appObj = (typeof mainView !== "undefined" && mainView) ? mainView : ((typeof rootApp !== "undefined" && rootApp) ? rootApp : null);
            if (appObj && appObj.globalDashboardUserChanged) {
                appObj.globalDashboardUserChanged(-1, selectedUserName);
            }
            refreshData(true);
            return;
        }

        // Match selected assignees against availableUsers
        var selectedUsersList = [];
        for (var i = 0; i < availableUsers.length; i++) {
            var u = availableUsers[i];
            var isSel = false;
            for (var j = 0; j < rawIds.length; j++) {
                var s = rawIds[j];
                var sUid = (typeof s === "object") ? s.user_id : s;
                if (sUid === u.id || (u.allUserIds && u.allUserIds.indexOf(sUid) !== -1)) {
                    isSel = true;
                    break;
                }
            }
            if (isSel) {
                selectedUsersList.push(u);
            }
        }

        if (selectedUsersList.length === 0) {
            handleAssigneeFilterCleared();
            return;
        }

        if (selectedUsersList.length === 1) {
            selectedUserId = selectedUsersList[0].id;
            selectedUserName = selectedUsersList[0].name;
        } else {
            selectedUserId = rawIds.slice();
            selectedUserName = selectedUsersList.length + " " + i18n.dtr("ubtms", "Employees");
        }

        Global.setDashboardUserFilter(selectedUserId, selectedUserName);
        var appObj = (typeof mainView !== "undefined" && mainView) ? mainView : ((typeof rootApp !== "undefined" && rootApp) ? rootApp : null);
        if (appObj && appObj.globalDashboardUserChanged) {
            appObj.globalDashboardUserChanged(selectedUserId, selectedUserName);
        }
        refreshData(true);
    }

    function handleAssigneeFilterCleared() {
        var accId = (typeof accountPicker !== "undefined") ? accountPicker.selectedAccountId : -1;
        var defaultUser = Account.getDashboardSingleUserDefault(accId, availableUsers);

        if (defaultUser) {
            selectedUserId = defaultUser.id;
            selectedUserName = defaultUser.name;
            var defSelections = [];
            if (defaultUser.allUserIds && defaultUser.allAccountIds) {
                for (var d = 0; d < defaultUser.allUserIds.length; d++) {
                    defSelections.push(assigneeFilterMenu.createSelection(defaultUser.allUserIds[d], defaultUser.allAccountIds[d] || accId));
                }
            } else {
                var defAcctId = (defaultUser.accountId !== undefined) ? defaultUser.accountId : accId;
                defSelections.push(assigneeFilterMenu.createSelection(defaultUser.id, defAcctId));
            }
            assigneeFilterMenu.selectedAssigneeIds = defSelections;
        } else {
            selectedUserId = -1;
            selectedUserName = i18n.dtr("ubtms", "All Users");
            assigneeFilterMenu.selectedAssigneeIds = [assigneeFilterMenu.createSelection(-1, -1)];
        }

        Global.setDashboardUserFilter(selectedUserId, selectedUserName);
        var appObj = (typeof mainView !== "undefined" && mainView) ? mainView : ((typeof rootApp !== "undefined" && rootApp) ? rootApp : null);
        if (appObj && appObj.globalDashboardUserChanged) {
            appObj.globalDashboardUserChanged(selectedUserId, selectedUserName);
        }
        refreshData(true);
    }

    AssigneeFilterMenu {
        id: assigneeFilterMenu
        anchors.fill: parent
        z: 1000
        showAllUsersOption: true

        onFilterApplied: function (assigneeIds) {
            handleAssigneeFilterApplied(assigneeIds);
        }

        onFilterCleared: function () {
            handleAssigneeFilterCleared();
        }
    }

    // NotificationBell component handles all notification UI
    NotificationBell {
        id: notificationBell
        visible: false
        parentWindow: mainPage
        
        // Track previous count to detect new notifications
        property int previousCount: 0
        
        onTotalCountChanged: {
            if (totalCount > previousCount && previousCount > 0) {
                var newCount = totalCount - previousCount;
                notifPopup.open(
                    i18n.dtr("ubtms", "New Notifications"),
                    i18n.dtr("ubtms", "You have %1 new notification(s)").arg(newCount),
                    "info"
                );
            }
            previousCount = totalCount;
        }
        
        // Handle navigation from notification clicks
        onNavigateToRecord: {
            if (navType === "Task" && recordId > 0) {
                apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("../../tasks/pages/Tasks.qml"), {
                    "recordid": recordId,
                    "isReadOnly": true
                });
            } else if (navType === "Activity" && recordId > 0) {
                apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("../../activities/pages/Activities.qml"), {
                    "recordid": recordId,
                    "accountid": accountId,
                    "isReadOnly": true
                });
            } else if (navType === "ProjectUpdate" && recordId > 0) {
                apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("../../updates/pages/Updates.qml"), {
                    "recordid": recordId,
                    "accountid": accountId,
                    "isOdooRecordId": true,
                    "isReadOnly": true
                });
            } else if (navType === "Project" && recordId > 0) {
                apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("../../projects/pages/Projects.qml"), {
                    "recordid": recordId,
                    "isReadOnly": true
                });
            } else if (navType === "Timesheet" && recordId > 0) {
                apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("../../timesheets/pages/Timesheet.qml"), {
                    "recordid": recordId,
                    "isReadOnly": true
                });
            }
        }
    }

    // Simple notification popup for messages
    NotificationPopup {
        id: notifPopup
    }

    Component.onCompleted: {
        Logger.debug("Dashboard", "Dashboard status is: " + mainPage.status)
        initUserFilterForCurrentAccount();
        // Load notifications on startup
        notificationBell.loadNotifications();
    }

    // Loading indicator overlay
    LoadingIndicator {
        anchors.fill: parent
        visible: isLoading
        message: loadingMessage
    }
}