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
                    const result = Model.createTimesheet(Account.getDefaultAccountId(), Account.getCurrentUserOdooId(Account.getDefaultAccountId()));
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

        filter4: ""
        filter5: ""
        filter6: ""

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
        var timesheets_list;
        timesheets_list = Model.fetchTimesheetsByStatus(currentFilter);
        timesheetModel.clear();
        for (var timesheet = 0; timesheet < timesheets_list.length; timesheet++) {
            timesheetModel.append({
                'name': timesheets_list[timesheet].name,
                'id': timesheets_list[timesheet].id,
                'instance': timesheets_list[timesheet].instance,
                'project': timesheets_list[timesheet].project,
                'spentHours': timesheets_list[timesheet].spentHours,
                'quadrant': timesheets_list[timesheet].quadrant || "Do",
                'task': timesheets_list[timesheet].task || "Unknown Task",
                'date': timesheets_list[timesheet].date,
                'user': timesheets_list[timesheet].user,
                'status': timesheets_list[timesheet].status,
                'activetimer': (currentFilter === "active") && (TimerService.getActiveTimesheetId() === timesheets_list[timesheet].id)
            });
        }
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
                const result = Model.createTimesheet(Accounts.getDefaultAccountId(), Accounts.getCurrentUserOdooId(Accounts.getDefaultAccountId()));
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
            fetch_timesheets_list();
        }
    }
}
