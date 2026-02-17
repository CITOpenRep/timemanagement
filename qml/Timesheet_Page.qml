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
import Ubuntu.Components 1.3 as Ubuntu
import QtQuick.LocalStorage 2.7
import "../models/timesheet.js" as Model
import "../models/project.js" as Project
import "../models/accounts.js" as Account
import "../models/global.js" as Global
import "components"
import "../models/timer_service.js" as TimerService

Page {
    id: timesheets
    title: i18n.dtr("ubtms", "Timesheets")

    property string currentFilter: "all"
    property bool workpersonaSwitchState: true

    // SEPARATED CONCERNS:
    // 1. selectedAccountId - ONLY for filtering/viewing data (from account selector)
    // 2. defaultAccountId - ONLY for creating new records (from default account setting)
    property string selectedAccountId: accountPicker.selectedAccountId // Start with "All accounts" for filtering
    property string defaultAccountId: accountPicker.selectedAccountId // For creating records

    // Properties for filtering by task
    property bool filterByTask: false
    property int taskOdooRecordId: -1
    property int taskAccountId: -1
    property string taskName: ""

    // Loading state property
    property bool isLoading: false

    // Pagination properties
    property int pageSize: 30
    property int currentOffset: 0
    property bool hasMoreItems: true
    property bool isLoadingMore: false

    header: PageHeader {
        id: timesheetsheader
        title: filterByTask ? i18n.dtr("ubtms", "Timesheets") + " - " + taskName : timesheets.title
        StyleHints {
            foregroundColor: "white"
            backgroundColor: LomiriColors.orange
            dividerColor: LomiriColors.slate
        }

        trailingActionBar.actions: [
            Action {
                iconName: "reminder-new"
                text: "New"
                onTriggered: {
                    // Use DEFAULT account for creating new timesheets (not the filter selection)
                    const result = Model.createTimesheet(defaultAccountId, Account.getCurrentUserOdooId(defaultAccountId));
                    if (result.success) {
                        apLayout.addPageToNextColumn(timesheets, Qt.resolvedUrl("Timesheet.qml"), {
                            "recordid": result.id,
                            "isReadOnly": false
                        });
                    } else {
                        notifPopup.open("Error", result.message, "error");
                    }
                }
            }
         


        ]
    }

    Connections {
        target: globalTimerWidget
        onTimerStopped: {
            fetch_timesheets_list();
        }
        onTimerStarted: {
            fetch_timesheets_list();
        }
        onTimerPaused: {
            fetch_timesheets_list();
        }
        onTimerResumed: {
            fetch_timesheets_list();
        }
    }

    // Keep account-data-refresh handler but accept permissive signal signature
    Connections {
        target: mainView
        onAccountDataRefreshRequested: function (accountId) {
            // If accountId isn't passed by signal, accountId will be undefined -> refresh if our filter is "-1" or always refresh
            if (typeof accountId === "undefined" || accountId === null) {
                fetch_timesheets_list();
            } else {
                if (selectedAccountId === accountId || selectedAccountId === "-1") {
                    fetch_timesheets_list();
                }
            }
        }
    }

    NotificationPopup {
        id: notifPopup
        width: units.gu(80)
        height: units.gu(80)
    }

    // Add ListHeader filter here
    ListHeader {
        id: timesheetListHeader
        anchors.top: timesheetsheader.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        label1: i18n.dtr("ubtms","All")
        label2: i18n.dtr("ubtms","Active")
        label3: i18n.dtr("ubtms","Draft")

        filter1: "all"
        filter2: "active"
        filter3: "draft"
        // Hide unused labels/filters
        label4: ""
        label5: ""
        label6: ""
        label7: ""

        filter4: ""
        filter5: ""
        filter6: ""
        filter7: ""

        showSearchBox: false
        currentFilter: timesheets.currentFilter

        onFilterSelected: {
            timesheets.currentFilter = filterKey;
            fetch_timesheets_list();
        }
    }

    ListModel {
        id: timesheetModel
    }

    // Timer for deferred loading - gives UI time to render loading indicator
    Timer {
        id: loadingTimer
        interval: 50  // 50ms delay to ensure UI renders
        repeat: false
        onTriggered: _doLoadTimesheets()
    }

    function fetch_timesheets_list() {
        isLoading = true;
        currentOffset = 0;  // Reset offset for fresh load
        hasMoreItems = true; // Reset hasMore flag
        timesheetModel.clear();
        // Use Timer to defer the actual data loading,
        // giving QML time to render the loading indicator first
        loadingTimer.start();
    }

    function _doLoadTimesheets() {
        // Use selectedAccountId for filtering (from account selector)
        var filterAccountId = selectedAccountId;
        console.log("Filtering timesheets for account:", filterAccountId, "filter:", currentFilter);
        console.log("Default account for creation:", defaultAccountId);

        var timesheets_list = [];

        // Check if we're filtering by task
        if (filterByTask && taskOdooRecordId > 0) {
            console.log("Filtering timesheets by task:", taskOdooRecordId, "account:", taskAccountId, "status:", currentFilter);
            timesheets_list = Model.getTimesheetsForTask(taskOdooRecordId, taskAccountId, currentFilter);
            hasMoreItems = false; // Task-specific view doesn't paginate
        }
        // Use paginated fetch method depending on account selector choice
        else if (filterAccountId === "-1") {
            console.log("Account selector: All accounts selected — fetching paginated timesheets");
            timesheets_list = Model.fetchTimesheetsForAllAccountsPaginated(currentFilter, pageSize, currentOffset);
        } else {
            console.log("Account selector: Single account selected — fetching paginated timesheets for account", filterAccountId);
            timesheets_list = Model.fetchTimesheetsByStatusPaginated(currentFilter, filterAccountId, pageSize, currentOffset);
        }

        if (!timesheets_list || !timesheets_list.length) {
            console.log("No timesheets returned from model (length 0 or undefined).");
            hasMoreItems = false;
        } else {
            console.log("Retrieved", timesheets_list.length, "timesheets");
            // If we got fewer items than pageSize, there are no more items
            hasMoreItems = timesheets_list.length >= pageSize;
        }

        for (var timesheet = 0; timesheet < (timesheets_list ? timesheets_list.length : 0); timesheet++) {
            var t = timesheets_list[timesheet] || {};
            timesheetModel.append({
                'name': t.name,
                'id': t.id,
                'instance': t.instance,
                'project': t.project,
                'spentHours': t.spentHours,
                'quadrant': t.quadrant || "Do",
                'task': t.task || "Unknown Task",
                'date': t.date,
                'user': t.user,
                'status': t.status,
                // preserve timer behavior (normalize comparison to string to be safe)
                'activetimer': (currentFilter === "active") && (String(TimerService.getActiveTimesheetId()) === String(t.id)),
                // IMPORTANT: keep the same key name that your delegate expects
                'color_pallet': (typeof t.color_pallet !== "undefined" ? t.color_pallet : ""),
                'has_draft': t.has_draft || 0
            });
        }

        console.log("Populated timesheetModel with", timesheetModel.count, "items");
        isLoading = false;
        isLoadingMore = false;
    }

    // Function to load more items for infinite scroll
    function loadMoreTimesheets() {
        if (isLoadingMore || !hasMoreItems) return;
        isLoadingMore = true;
        currentOffset += pageSize;
        console.log("Loading more timesheets, offset:", currentOffset);
        _doLoadTimesheets();
    }

    ListView {
        id: timesheetlist
        anchors.top: timesheetListHeader.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: units.gu(1)
        model: timesheetModel
        clip: true

        footer: LoadMoreFooter {
            isLoading: isLoadingMore
            hasMore: hasMoreItems
            onLoadMore: loadMoreTimesheets()
        }

        onAtYEndChanged: {
            if (timesheetlist.atYEnd && !isLoadingMore && hasMoreItems) {
                console.log("Reached end of list, loading more timesheets...");
                loadMoreTimesheets();
            }
        }

        delegate: TimeSheetDetailsCard {
            width: parent.width
            name: model.name
            instance: model.instance
            project: model.project
            spentHours: model.spentHours
            date: model.date || ""
            quadrant: model.quadrant
            task: model.task
            recordId: model.id
            user: model.user
            status: model.status
            timer_on: model.activetimer
            colorPallet: model.color_pallet
            hasDraft: model.has_draft === 1

            onEditRequested: {
                apLayout.addPageToNextColumn(timesheets, Qt.resolvedUrl("Timesheet.qml"), {
                    "recordid": model.id,
                    "isReadOnly": false
                });
            }
            onViewRequested: {
                apLayout.addPageToNextColumn(timesheets, Qt.resolvedUrl("Timesheet.qml"), {
                    "recordid": model.id,
                    "isReadOnly": true
                });
            }
            onDeleteRequested: {
                var result = Model.markTimesheetAsDeleted(model.id);
                if (!result.success) {
                    notifPopup.open("Error", result.message, "error");
                } else {
                    notifPopup.open("Deleted", result.message, "success");
                    fetch_timesheets_list();
                }
            }
            onRefresh: {
                fetch_timesheets_list();
            }
        }

        Component.onCompleted: fetch_timesheets_list()
    }

    DialerMenu {
        id: fabMenu
        anchors.fill: parent
        z: 9999
        menuModel: [
            {
                label: i18n.dtr("ubtms", "Create"),
            },
        ]
        onMenuItemSelected: {
            if (index === 0) {
                // Use DEFAULT account for creating new timesheets (not the filter selection)
                const result = Model.createTimesheet(defaultAccountId, Account.getCurrentUserOdooId(defaultAccountId));
                if (result.success) {
                    apLayout.addPageToNextColumn(timesheets, Qt.resolvedUrl("Timesheet.qml"), {
                        "recordid": result.id,
                        "isReadOnly": false
                    });
                } else {
                    notifPopup.open("Error", result.message, "error");
                }
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            // Update navigation tracking when Timesheet_Page becomes visible
            Global.setLastVisitedPage("Timesheet_Page");

            fetch_timesheets_list();
        }
    }

    // Update default account when it changes in settings
    Component.onCompleted: {
        // Initialize default account
        defaultAccountId = accountPicker.selectedAccountId;
        selectedAccountId = accountPicker.selectedAccountId;
    }

    // Loading indicator overlay
    LoadingIndicator {
        anchors.fill: parent
        visible: isLoading
        message: i18n.dtr("ubtms", "Loading timesheets...")
    }
}
