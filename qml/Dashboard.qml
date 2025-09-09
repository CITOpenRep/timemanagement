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
import Qt.labs.settings 1.0
import "../models/Main.js" as Model
import "../models/project.js" as Project
import "../models/notifications.js" as Notifications
import "../models/utils.js" as Utils
import "../models/timesheet.js" as TimesheetModel
import "../models/accounts.js" as Account
import io.thp.pyotherside 1.4
import "components"

Page {
    id: mainPage
    title: "Time Manager - Time Management Dashboard"
    anchors.fill: parent
    property bool isMultiColumn: apLayout.columns > 1
    property var page: 0
    onVisibleChanged: {
        if (visible) {
            //update graph etc
            var data = Project.getProjectSpentHoursList(true);
            projectchart.load(data);
            // For testing notifications
            // simulateTestNotifications();
        }
    }

    function simulateTestNotifications() {
        Notifications.addNotification(1, "Task", "Task 'Write Report' is due today", {
            id: 1026
        });
        Notifications.addNotification(1, "Project", "Project 'Website Revamp' deadline is tomorrow", {
            id: 3001
        });
        Notifications.addNotification(1, "Sync", "Sync failed for task 'Client Meeting'", [
            {
                id: 1014,
                error: "Missing project_id"
            },
            {
                id: 1025,
                error: "Unknown task_id"
            }
        ]);
        Notifications.addNotification(1, "Activity", "Meeting with John at 3 PM", {
            id: 45
        });
        Notifications.addNotification(1, "Timesheet", "No timesheet logged today", {
            date: "2025-06-13"
        });
    }

    header: PageHeader {
        id: header
        StyleHints {
            foregroundColor: "white"

            backgroundColor: LomiriColors.orange
            dividerColor: LomiriColors.slate
        }
        title: "Time Management"
        visible: true

        //Later we can merge all these with Global Timer as a taskbar
        /*NotificationBell {
            z: 9999
            anchors.centerIn: parent
            parentWindow: mainPage
            visible: false // Set to true if you want to show the notification bell
        }*/

        // ActionBar {

        //     id: actionbar
        //     visible: isMultiColumn ? false : true
        //     numberOfSlots: 2
        //     anchors.right: parent.right
        trailingActionBar.visible: isMultiColumn ? false : true
        trailingActionBar.numberOfSlots: 3

        trailingActionBar.actions: [
            Action {
                iconName: "help"
                text: "About"
                onTriggered: {
                    apLayout.addPageToCurrentColumn(mainPage, Qt.resolvedUrl("Aboutus.qml"));
                    //  console.log("Calling setCurrentPage Primarypage is " + apLayout.primaryPage);
                    page = 7;
                    apLayout.setCurrentPage(page);
                }
            },
            Action {
                iconSource: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "images/daymode.png" : "images/darkmode.png"
                text: theme.name === "Ubuntu.Components.Themes.SuruDark" ? i18n.tr("Light Mode") : i18n.tr("Dark Mode")
                onTriggered: {
                    Theme.name = theme.name === "Ubuntu.Components.Themes.SuruDark" ? "Ubuntu.Components.Themes.Ambiance" : "Ubuntu.Components.Themes.SuruDark";

                    // // Save theme preference to persist across app restarts
                    // if (typeof mainView !== 'undefined' && mainView.saveThemePreference) {
                    //     mainView.saveThemePreference(newTheme);
                    // }
                }
            },
            Action {
                iconName: "clock"
                text: "Timesheet"
                onTriggered: {
                    apLayout.addPageToCurrentColumn(mainPage, Qt.resolvedUrl("Timesheet_Page.qml"));
                    //  console.log("Calling setCurrentPage Primarypage is " + apLayout.primaryPage);
                    page = 7;
                    apLayout.setCurrentPage(page);
                }
            },
            Action {
                iconName: "calendar"
                text: "Activities"
                onTriggered: {
                    apLayout.addPageToCurrentColumn(mainPage, Qt.resolvedUrl("Activity_Page.qml"));
                    page = 2;
                    apLayout.setCurrentPage(page);
                }
            },
            Action {
                iconName: "view-list-symbolic"
                text: "Tasks"
                onTriggered: {
                    apLayout.addPageToCurrentColumn(mainPage, Qt.resolvedUrl("Task_Page.qml"));
                    page = 3;
                    apLayout.setCurrentPage(page);
                }
            },
            Action {
                iconName: "folder-symbolic"
                text: "Projects"
                onTriggered: {
                    apLayout.addPageToCurrentColumn(mainPage, Qt.resolvedUrl("Project_Page.qml"));
                    page = 4;
                    apLayout.setCurrentPage(page);
                }
            },
            Action {
                iconName: "history"
                text: "Project Updates"
                onTriggered: {
                    apLayout.addPageToCurrentColumn(mainPage, Qt.resolvedUrl("Updates_Page.qml"));
                    page = 5;
                    apLayout.setCurrentPage(page);
                }
            },
            Action {
                iconName: "settings"
                text: "Settings"
                onTriggered: {
                    apLayout.addPageToCurrentColumn(mainPage, Qt.resolvedUrl("Settings_Page.qml"));
                    page = 6;
                    apLayout.setCurrentPage(page);
                }
            }
        ]
    }

    /*    function handle_convergence(){
            console.log(" In Dashboard convergence: " + apLayout.columns)
        if (apLayout.columns === 3){
            apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("Dashboard2.qml"))
        }

    }*/

    property variant project_timecat: []
    property variant project: []
    property variant project_data: []

    property variant task_timecat: []
    property variant task: []
    property variant task_data: []

    function get_project_chart_data() {
        //   console.log("get_project_chart_data called");
        project_data = Model.get_projects_spent_hours();
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
        //  console.log("get_task_chart_data called");
        task_data = Model.get_tasks_spent_hours();
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
        get_project_chart_data();
        get_task_chart_data();
        
        // Refresh project chart if it exists
        if (typeof projectchart !== 'undefined') {
            var data = Project.getProjectSpentHoursList(true);
            projectchart.load(data);
        }
    }
    
    DialerMenu {
        id: fabMenu
        anchors.fill: parent
        z: 9999
        menuModel: [
            {
                label: "Task"
            },
            {
                label: "Timesheet"
            },
            {
                label: "Activity"
            },
        ]
        onMenuItemSelected: {
            if (index === 0) {
                // console.log("add task");
                apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("Tasks.qml"), {
                    "recordid": 0,
                    "isReadOnly": false
                });
            }
            if (index === 1) {
                // console.log("add time sheet");
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
                //   console.log("add activity");
                apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("Activities.qml"), {
                    // "recordid": 0,
                    "isReadOnly": false
                });
            }
        }
    }

    Flickable {
        id: flick1
        //z: 888 //Set it to Zero or just remove it to avoid flickable being on top of the header
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
                height: width  // Maintain square layout
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
                        onQuadrantClicked:
                        //  console.log("Quadrant clicked:", quadrant);
                        {}
                    }
                }
            }

            /*  The below widget is useful for getting an overview of tasks . For future integration, please note that thereis a bug in the odooid we get , to be fixed.
            Item {
                id: tasksForTheDay
                width: parent.width
                height: width/2  // Maintain square layout
                anchors.horizontalCenter: parent.horizontalCenter

                TasksForDayWidget {
                    id: tasks_widget
                    width: parent.width * 0.98
                    height: parent.height
                    anchors.centerIn: parent
                    onTaskSelected: {
                        if (odooId > 0) {
                            console.log("---> Record ID received:", odooId, typeof odooId);
                            apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("Tasks.qml"), {
                                                             "recordid": String(odooId),
                                                             "isReadOnly": true
                                                         });
                        }
                    }
                }
            }*/

            ProjectPieChart {
                id: projectchart
                width: parent.width * 0.95
                height: width  // Also square
                anchors.horizontalCenter: parent.horizontalCenter
                Component.onCompleted: {
                    var data = Project.getProjectSpentHoursList(true);
                    projectchart.load(data);
                }
            }
        }

        onFlickEnded: {
            //load not defined: Commented by Gokul
            //load.active = false;
            //load2.active = false;
            if (apLayout.columns === 1)
            // load3.active = false;
            // load4.active = false;
            {}
            //  console.log("Flickable flick ended");
            //load.active = true;
            // load2.active = true;
            if (apLayout.columns === 1)
            //  load3.active = true;
            //  load4.active = true;
            {} else
            //                    apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("Dashboard2.qml"))
            {}
        }
    }

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
                // console.log("In Dashboard timer columns: " + apLayout.columns);
                apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("Dashboard2.qml"));
            }
        }
    }

    // Rectangle {

    //     visible: !isMultiColumn
    //     id: swipeIndicator
    //     width: units.gu(6)
    //     height: units.gu(0.7)
    //     radius: height / 2
    //     color: theme.name === "Ubuntu.Components.Themes.SuruDark" ?  LomiriColors.orange : "#0cc0df"
    //   //  opacity: 0.7
    //     anchors.horizontalCenter: parent.horizontalCenter
    //     anchors.bottom: swipeUpArea.top
    //     anchors.bottomMargin: units.gu(0.5)
    //     z: 1000
    // }

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

    Component.onCompleted: {
        console.log("Dashboard status is: " + mainPage.status);
    }
}
