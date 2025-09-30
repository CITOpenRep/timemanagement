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
import "components"
import "../models/timer_service.js" as TimerService

Page {
    id: timesheets
    title: "Timesheets"

    property string currentFilter: "all"
    property bool workpersonaSwitchState: true
    
    // SEPARATED CONCERNS:
    // 1. selectedAccountId - ONLY for filtering/viewing data (from account selector)
    // 2. defaultAccountId - ONLY for creating new records (from default account setting)
    property string selectedAccountId: "-1" // Start with "All accounts" for filtering
    property string defaultAccountId: Account.getDefaultAccountId() // For creating records

    header: PageHeader {
        id: timesheetsheader
        title: timesheets.title
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
                    const result = Model.createTimesheet(
                        defaultAccountId,
                        Account.getCurrentUserOdooId(defaultAccountId)
                    )
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
            // Action {
            //     iconName: "account"
            //     onTriggered: {
            //         accountFilterVisible = !accountFilterVisible
            //     }
            // }
        ]
    }

    // Listen to AccountFilter component changes (for filtering only)
    Connections {
        target: accountFilter // Make sure this targets your AccountFilter component
        onAccountChanged: function(accountId, accountName) {
            console.log("Account filter changed to:", accountName, "ID:", accountId);
            selectedAccountId = accountId; // Update filter selection
            fetch_timesheets_list(); // Refresh with new filter
        }
    }

    // Listen for default account changes (for creation only)
    Connections {
        target: mainView
        onDefaultAccountChanged: function(accountId) {
            console.log("Default account changed to:", accountId);
            defaultAccountId = accountId; // Update default for creation
            // Don't refresh list here - this is only for creation, not filtering
        }
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
        onAccountDataRefreshRequested: function(accountId) {
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

        label1: "All"
        label2: "Active"
        label3: "Draft"

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

    function fetch_timesheets_list() {
        // Use selectedAccountId for filtering (from account selector)
        var filterAccountId = selectedAccountId;
        console.log("Filtering timesheets for account:", filterAccountId, "filter:", currentFilter);
        console.log("Default account for creation:", defaultAccountId);

        var timesheets_list = [];

        // Use different fetch method depending on account selector choice
        // strict comparison to string "-1" so "-1" and -1 mismatch issues are avoided
        if (filterAccountId === "-1") {
            console.log("Account selector: All accounts selected — fetching all timesheets");
            timesheets_list = Model.fetchTimesheetsForAllAccounts(currentFilter);
        } else {
            console.log("Account selector: Single account selected — fetching timesheets for account", filterAccountId);
            timesheets_list = Model.fetchTimesheetsByStatus(currentFilter, filterAccountId);
        }

        timesheetModel.clear();

        if (!timesheets_list || !timesheets_list.length) {
            console.log("No timesheets returned from model (length 0 or undefined).");
        } else {
            console.log("Retrieved", timesheets_list.length, "timesheets");
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
                'color_pallet': (typeof t.color_pallet !== "undefined" ? t.color_pallet : "")
            });
        }

        console.log("Populated timesheetModel with", timesheetModel.count, "items");
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
                label: "Create"
            },
        ]
        onMenuItemSelected: {
            if (index === 0) {
                // Use DEFAULT account for creating new timesheets (not the filter selection)
                const result = Model.createTimesheet(
                    defaultAccountId,
                    Account.getCurrentUserOdooId(defaultAccountId)
                )
                if (result.success) {
                    apLayout.addPageToNextColumn(timesheets, Qt.resolvedUrl("Timesheet.qml"), {
                        "recordid": result.id,
                        "isReadOnly": false
                    })
                } else {
                    notifPopup.open("Error", result.message, "error")
                }
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            fetch_timesheets_list();
        }
    }

    // Update default account when it changes in settings
    Component.onCompleted: {
        // Initialize default account
        defaultAccountId = Account.getDefaultAccountId();

        // Try to read the account selector's current selection and use it as initial filter.
        // This will preserve color behavior and run initial filtered fetch.
        try {
            if (typeof accountFilter !== "undefined" && accountFilter !== null) {
                // try common property names — prefer explicit ID property if present
                if (typeof accountFilter.selectedAccountId !== "undefined" && accountFilter.selectedAccountId !== null) {
                    selectedAccountId = String(accountFilter.selectedAccountId);
                } else if (typeof accountFilter.currentAccountId !== "undefined" && accountFilter.currentAccountId !== null) {
                    selectedAccountId = String(accountFilter.currentAccountId);
                } else if (typeof accountFilter.currentIndex !== "undefined" && accountFilter.currentIndex >= 0) {
                    // fallback: if only index is available, keep "-1" or map index -> id here if you have mapping
                    selectedAccountId = String(accountFilter.currentIndex);
                } else {
                    selectedAccountId = "-1";
                }
            } else {
                // if accountFilter component not available at this time, fallback to "-1"
                selectedAccountId = "-1";
            }
        } catch (e) {
            console.error("Error reading accountFilter initial selection:", e);
            selectedAccountId = "-1";
        }

        console.log("Initial selectedAccountId on load:", selectedAccountId);
    }
}
