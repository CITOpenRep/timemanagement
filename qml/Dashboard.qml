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
import Ubuntu.Components 1.3 as Ubuntu
import QtCharts 2.0
import QtQuick.Layouts 1.11
import QtQuick.Controls 2.2 as Controls
import Qt.labs.settings 1.0
import "../models/Main.js" as Model
import "../models/project.js" as Project
import "../models/notifications.js" as Notifications
import "../models/utils.js" as Utils
import "../models/timesheet.js" as TimesheetModel
import "../models/accounts.js" as Account
import "../models/global.js" as Global
import io.thp.pyotherside 1.4
import "components"

Page {
    id: mainPage
    title: i18n.dtr("ubtms", "Time Manager - Time Management Dashboard")
    anchors.fill: parent
    property bool isMultiColumn: apLayout.columns > 1
    property var page: 0
    property bool isLoading: false

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

            // Prefer the selected account from the account selector (NOT the default account)
            var selected = accountPicker.selectedAccountId;
            if (typeof projectchart !== "undefined")
                projectchart.refreshForAccount(selected);
            // Also refresh other dashboard data
            refreshData();
        }
    }

    function simulateTestNotifications() {
        // First clear all existing notifications
        Notifications.deleteAllNotifications();
        console.log("Cleared all notifications");
        
        // Add test notifications with valid record IDs (id: 1 should exist for each type)
        Notifications.addNotification(1, "Task", "Task 'Write Report' is due today", {
            id: 1
        });
        Notifications.addNotification(1, "Project", "Project 'Website Revamp' deadline is tomorrow", {
            id: 1
        });
        Notifications.addNotification(1, "Activity", "Meeting with John at 3 PM", {
            id: 1
        });
        Notifications.addNotification(1, "Timesheet", "Timesheet entry updated", {
            id: 1
        });
        
        console.log("Created 4 test notifications with record IDs");
        
        // Refresh the notification list
        notificationBell.loadNotifications();
    }

    header: PageHeader {
        id: header
        StyleHints {
            foregroundColor: "white"
            backgroundColor: LomiriColors.orange
            dividerColor: LomiriColors.slate
        }
        title: i18n.dtr("ubtms", "Account") + " [" + accountPicker.selectedAccountName + "]"
        visible: true

        // Notification Bell in header
        leadingActionBar.actions: [
            Action {
                id: notificationAction
                //todo : Fix the Icons visibility based on notification count
                iconSource: notificationBell.notificationCount > 0 ? "images/notification_active.png" : "images/notification.png"
                text: notificationBell.notificationCount > 0 ? 
                      i18n.dtr("ubtms", "Notifications") + " (" + notificationBell.notificationCount + ")" : 
                      i18n.dtr("ubtms", "Notifications")
                onTriggered: {
                    if (notificationBell.notificationCount > 0) {
                        notificationBell.openPopup();
                    } else {
                        notifPopup.open("No Notifications", "You have no new notifications", "info");
                    }
                }
            }
        ]

        trailingActionBar.visible: isMultiColumn ? false : true
        trailingActionBar.numberOfSlots: 4

        trailingActionBar.actions: [
         
            Action {
                iconName: "account"
                text: i18n.dtr("ubtms", "Switch Accounts")
                onTriggered: {
                    accountPicker.open(accountPicker.selectedAccountId);
                }
            },
            Action {
                iconName: "help"
                text: i18n.dtr("ubtms", "About")
                onTriggered: {
                    apLayout.addPageToCurrentColumn(mainPage, Qt.resolvedUrl("Aboutus.qml"));
                    page = 7;
                    apLayout.setCurrentPage(page);
                }
            },
            Action {
                iconSource: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "images/daymode.png" : "images/darkmode.png"
                text: theme.name === "Ubuntu.Components.Themes.SuruDark" ? i18n.dtr("ubtms", "Light Mode") : i18n.dtr("ubtms","Dark Mode")
                onTriggered: {
                    Theme.name = theme.name === "Ubuntu.Components.Themes.SuruDark" ? "Ubuntu.Components.Themes.Ambiance" : "Ubuntu.Components.Themes.SuruDark";
                }
            },
            Action {
                iconName: "clock"
                text: i18n.dtr("ubtms", "Timesheet")
                onTriggered: {
                    apLayout.addPageToCurrentColumn(mainPage, Qt.resolvedUrl("Timesheet_Page.qml"));
                    page = 7;
                    apLayout.setCurrentPage(page);
                }
            },
            Action {
                iconName: "calendar"
                text: i18n.dtr("ubtms", "Activities")
                onTriggered: {
                    apLayout.addPageToCurrentColumn(mainPage, Qt.resolvedUrl("Activity_Page.qml"));
                    page = 2;
                    apLayout.setCurrentPage(page);
                }
            },
            Action {
                iconName: "scope-manager"
                text: i18n.dtr("ubtms", "My Tasks")
                onTriggered: {
                    apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("MyTasks.qml"));
                    page = 3;
                    apLayout.setCurrentPage(page);
                }
            },
            Action {
                iconName: "view-list-symbolic"
                text: i18n.dtr("ubtms", "All Tasks")
                onTriggered: {
                    apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("Task_Page.qml"));
                    page = 3;
                    apLayout.setCurrentPage(page);
                }
            },
            Action {
                iconName: "folder-symbolic"
                text: i18n.dtr("ubtms", "Projects")
                onTriggered: {
                    apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("Project_Page.qml"));
                    page = 4;
                    apLayout.setCurrentPage(page);
                }
            },
            Action {
                iconName: "history"
                text: i18n.dtr("ubtms", "Project Updates")
                onTriggered: {
                    apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("Updates_Page.qml"));
                    page = 5;
                    apLayout.setCurrentPage(page);
                }
            },
            Action {
                iconName: "settings"
                text: i18n.dtr("ubtms", "Settings")
                onTriggered: {
                    apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("settings/Settings_Page.qml"));
                    page = 6;
                    apLayout.setCurrentPage(page);
                }
            }
        ]
    }

    property variant project_timecat: []
    property variant project: []
    property variant project_data: []

    property variant task_timecat: []
    property variant task: []
    property variant task_data: []

    function get_project_chart_data() {
        var account = accountPicker.selectedAccountId;
        project_data = Model.get_projects_spent_hours(account);
        var count = 0;
        var timeval;
        for (var key in project_data) {
            project[count] = key;
            timeval = project_data[key];
            count = count + 1;
        }
        var count2 = Object.keys(project_data).length;
        for (count = 0; count < count2; count++) {
            project_timecat[count] = project_data[project[count]];
        }
    }

    function get_task_chart_data() {
        var account = accountPicker.selectedAccountId;
        task_data = Model.get_tasks_spent_hours(account);
        var count = 0;
        var timeval;
        for (var key in task_data) {
            task[count] = key;
            timeval = task_data[key];
            count = count + 1;
        }
        var count2 = Object.keys(task_data).length;
        for (count = 0; count < count2; count++) {
            task_timecat[count] = task_data[task[count]];
        }
    }

    function refreshData() {
        console.log("🔄 Refreshing Dashboard data...");
        isLoading = true;
        // Use Timer to defer the actual data loading,
        // giving QML time to render the loading indicator first
        loadingTimer.start();
    }

    function _doRefreshData() {
        get_project_chart_data();
        get_task_chart_data();
        // Refresh project chart using the account selector's selection (not default account)
        if (typeof projectchart !== 'undefined') {
            var selected = accountPicker.selectedAccountId;
            projectchart.refreshForAccount(selected);
        }
        isLoading = false;
    }

    DialerMenu {
        id: fabMenu
        anchors.fill: parent
        z: 9999
        menuModel: [
            {
                label: i18n.dtr("ubtms", "Task")
            },
            {
                label: i18n.dtr("ubtms", "Timesheet")
            },
            {
                label: i18n.dtr("ubtms", "Activity")
            }
        ]
        onMenuItemSelected: {
            if (index === 0) {
                apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("Tasks.qml"), {
                    "recordid": 0,
                    "isReadOnly": false
                });
            }
            if (index === 1) {
                const result = TimesheetModel.createTimesheet(Account.getDefaultAccountId(), Account.getCurrentUserOdooId(Account.getDefaultAccountId()));
                if (result.success) {
                    apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("Timesheet.qml"), {
                        "recordid": result.id,
                        "isReadOnly": false
                    });
                } else {
                    console.error("Error creating timesheet: " + result.message);
                }
            }
            if (index === 2) {
                apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("Activities.qml"), {
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
        contentHeight: 4000
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
                        anchors.centerIn: parent
                        quadrant1Hours: "120.2"
                        quadrant2Hours: "65.5"
                        quadrant3Hours: "55.0"
                        quadrant4Hours: "178.1"
                        onQuadrantClicked: {}
                    }
                }
            }

            ProjectPieChart {
                id: projectchart
                width: parent.width * 0.95
                height: width
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Component.onCompleted: {
                try {
                    projectchart.refreshForAccount(accountPicker.selectedAccountId);
                } catch (e) {
                    console.error("Dashboard: error determining initial account for project chart:", e);
                    projectchart.refreshForAccount(-1);
                }
            }
        } // end Column

        onFlickEnded: {
            if (apLayout.columns === 1) {}
        }
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

    Icon {
        visible: !isMultiColumn
        width: units.gu(5)
        height: units.gu(4)
        z: 1000
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: swipeUpArea.top
        name: 'toolkit_chevron-up_3gu'
        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? LomiriColors.orange : LomiriColors.slate
    }

    MultiPointTouchArea {
        id: swipeUpArea
        enabled: !isMultiColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: units.gu(1)
        minimumTouchPoints: 1
        maximumTouchPoints: 1

        property real startY: 0

        onPressed: {
            startY = touchPoints[0].y;
        }
        onReleased: {
            var endY = touchPoints[0].y;
            // Detect upward swipe (swipe up: startY > endY)
            if (startY - endY > units.gu(2)) {
                // threshold for swipe - open new timesheet
                const result = TimesheetModel.createTimesheet(Account.getDefaultAccountId(), Account.getCurrentUserOdooId(Account.getDefaultAccountId()));
                if (result.success) {
                    apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("Timesheet.qml"), {
                        "recordid": result.id,
                        "isReadOnly": false
                    });
                } else {
                    console.error("Error creating timesheet: " + result.message);
                }
            }
        }
        z: 999 // Ensure it's above other content

        Rectangle {
            anchors.fill: parent
            color: "lightgray"
            opacity: 0.0 // Make it invisible but still interactive
        }
    }

    Connections {
        target: accountPicker
        onAccepted: function (accountId, accountName) {
            refreshData();
            header.title = i18n.dtr("ubtms", "Account") + " [" + accountPicker.selectedAccountName + "]";
        }
    }

    // NotificationBell component handles all notification UI
    NotificationBell {
        id: notificationBell
        visible: false
        parentWindow: mainPage
        
        // Track previous count to detect new notifications
        property int previousCount: 0
        
        onNotificationCountChanged: {
            if (notificationCount > previousCount && previousCount > 0) {
                var newCount = notificationCount - previousCount;
                notifPopup.open(
                    i18n.dtr("ubtms", "New Notifications"),
                    i18n.dtr("ubtms", "You have %1 new notification(s)").arg(newCount),
                    "info"
                );
            }
            previousCount = notificationCount;
        }
        
        // Handle navigation from notification clicks
        onNavigateToRecord: {
            if (navType === "Task" && recordId > 0) {
                apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("Tasks.qml"), {
                    "recordid": recordId,
                    "isReadOnly": true
                });
            } else if (navType === "Activity" && recordId > 0) {
                apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("Activities.qml"), {
                    "recordid": recordId,
                    "accountid": accountId,
                    "isReadOnly": true
                });
            } else if (navType === "Project" && recordId > 0) {
                apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("Projects.qml"), {
                    "recordid": recordId,
                    "isReadOnly": true
                });
            } else if (navType === "Timesheet" && recordId > 0) {
                apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("Timesheet.qml"), {
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
        console.log("Dashboard status is: " + mainPage.status);
        // Load notifications on startup
        notificationBell.loadNotifications();
        // Trigger initial data load with loading indicator
        refreshData();
    }

    // Loading indicator overlay
    LoadingIndicator {
        anchors.fill: parent
        visible: isLoading
        message: i18n.dtr("ubtms", "Loading dashboard...")
    }
}
