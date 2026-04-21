import QtQuick 2.6
import Lomiri.Components 1.3
import QtQuick.Window 2.2
import QtQuick.Layouts 1.11
import "../"
import "../settings"

AdaptivePageLayout {
    id: apLayout

    property var rootApp
    property var globalDrawer
    
    

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        property bool isMultiColumn: true
        property Page currentPage: splash_page
        property Page thirdPage: dashboard_page2
        property string currentMenuPageUrl: "Dashboard.qml"
        primaryPage: splash_page

        function openGlobalDrawer() {
            if (typeof globalDrawer !== "undefined") {
                globalDrawer.open();
            }
        }

        layouts: [
            //Tablet Layout
            PageColumnsLayout {
                when: width > units.gu(80) && width < units.gu(130)
                // column #0
                PageColumn {
                    minimumWidth: units.gu(30)
                    maximumWidth: units.gu(50)
                    preferredWidth: width > units.gu(90) ? units.gu(20) : units.gu(15)
                }
                // column #1
                PageColumn {
                    minimumWidth: units.gu(50)
                    maximumWidth: units.gu(80)
                    preferredWidth: units.gu(80)
                }
            },

            //Desktop Layout
            PageColumnsLayout {
                when: width >= units.gu(130)
                // column #0
                PageColumn {
                    minimumWidth: units.gu(30)
                    maximumWidth: units.gu(50)
                    preferredWidth: units.gu(40)
                }
                // column #1
                PageColumn {
                    minimumWidth: units.gu(70)
                    maximumWidth: units.gu(100)
                    preferredWidth: units.gu(80)
                }
                // column #2
                PageColumn {
                    fillWidth: true
                }
            }
        ]

        Splash {
            id: splash_page
        }
        Menu {
            id: menu_page
        }
        Dashboard {
            id: dashboard_page

            Connections {
                target: rootApp
                onAccountDataRefreshRequested: function (accountId) {
                    if (dashboard_page.visible && typeof dashboard_page.refreshData === 'function') {
                        dashboard_page.refreshData();
                    }
                }
            }
        }
        Dashboard2 {
            id: dashboard_page2

            Connections {
                target: rootApp
                onAccountDataRefreshRequested: function (accountId) {
                    console.log("🔄 Refreshing Dashboard2 data for account:", accountId);
                    if (dashboard_page2.visible && typeof dashboard_page2.refreshData === 'function') {
                        dashboard_page2.refreshData();
                    }
                }
            }
        }
        Timesheet {
            id: timesheet_page

            Connections {
                target: rootApp
                onAccountDataRefreshRequested: function (accountId) {
                    console.log("🔄 Refreshing Timesheet data for account:", accountId);
                    if (timesheet_page.visible && typeof timesheet_page.refreshData === 'function') {
                        timesheet_page.refreshData();
                    }
                }
            }
        }
        Activity_Page {
            id: activity_page

            Connections {
                target: rootApp
                onAccountDataRefreshRequested: function (accountId) {
                    console.log("🔄 Refreshing Activity data for account:", accountId);
                    if (activity_page.visible && typeof activity_page.get_activity_list === 'function') {
                        activity_page.get_activity_list();
                    }
                }
            }
        }
        Task_Page {
            id: task_page

            Connections {
                target: rootApp
                onAccountDataRefreshRequested: function (accountId) {
                    console.log("🔄 Refreshing Task data for account:", accountId);
                    if (task_page.visible && typeof task_page.getTaskList === 'function') {
                        task_page.getTaskList(task_page.currentFilter || "today", "");
                    }
                }
            }
        }
        Project_Page {
            id: project_page

            Connections {
                target: rootApp
                onAccountDataRefreshRequested: function (accountId) {
                    console.log("🔄 Refreshing Project data for account:", accountId);
                    if (project_page.visible && project_page.projectlist && typeof project_page.projectlist.refresh === 'function') {
                        project_page.projectlist.refresh();
                    }
                }
            }
        }
        Updates_Page {
            id: updates_page
        }
        Aboutus {
            id: aboutus_page
        }
        Settings_Page {
            id: settings_page
        }
        Timesheet_Page {
            id: timesheet_list

            Connections {
                target: rootApp
                onAccountDataRefreshRequested: function (accountId) {
                    console.log("🔄 Refreshing Timesheet List data for account:", accountId);
                    if (timesheet_list.visible && typeof timesheet_list.fetch_timesheets_list === 'function') {
                        timesheet_list.fetch_timesheets_list();
                    }
                }
            }
        }

        function setFirstScreen() {
            switch (columns) {
            case 1:
                primaryPage = dashboard_page;
                currentPage = dashboard_page;
                currentMenuPageUrl = "Dashboard.qml";
                break;
            case 2:
                primaryPage = menu_page;
                currentPage = dashboard_page;
                currentMenuPageUrl = "Dashboard.qml";
                addPageToNextColumn(primaryPage, currentPage);
                break;
            case 3:
                primaryPage = menu_page;
                currentPage = dashboard_page;
                currentMenuPageUrl = "Dashboard.qml";
                addPageToNextColumn(primaryPage, currentPage);
                addPageToNextColumn(currentPage, thirdPage);
                break;
            }
            init = false;
            
            // Process any pending deep link navigation
            // Use a Timer to ensure all UI components are fully loaded on cold start
            if (systemIntegration.pendingNavigation) {
                console.log("setFirstScreen: Pending navigation detected, scheduling with delay");
                systemIntegration.startDelayedNavigation();
            }
        }

        
    function setPageGlobal(url, pageNum) {
        // Map URLs to pre-instantiated root pages if they exist
        var targetPage = null;
        if (pageNum === 0) targetPage = dashboard_page;
        else if (pageNum === 1) targetPage = timesheet_list || timesheet_page;
        else if (pageNum === 2) targetPage = activity_page;
        else if (pageNum === 3 && url.indexOf("MyTasks") === -1) targetPage = task_page;
        else if (pageNum === 4) targetPage = project_page;
        else if (pageNum === 5) targetPage = updates_page;
        else if (pageNum === 6) targetPage = settings_page;
        else if (pageNum === 7) targetPage = aboutus_page;
        
        if (targetPage !== null) {
            apLayout.currentPage = targetPage;
        }
        currentMenuPageUrl = url;
        
        if (apLayout.columns === 1) {
            // For single column, replace primary page to dodge back-stack
            if (targetPage !== null) {
                if (apLayout.primaryPage === targetPage) {
                    if (typeof apLayout.removePages === 'function') {
                        apLayout.removePages(targetPage);
                    }
                } else {
                    apLayout.primaryPage = targetPage;
                }
            } else {
                // Unmapped pages need to be added to the dashboard dynamically
                if (apLayout.primaryPage !== dashboard_page) {
                    apLayout.primaryPage = dashboard_page;
                } else {
                    if (typeof apLayout.removePages === 'function') {
                        apLayout.removePages(dashboard_page);
                    }
                }
                apLayout.addPageToCurrentColumn(dashboard_page, Qt.resolvedUrl("../" + url));
            }
        } else {
            // For multiple columns, Menu is the primary page
            apLayout.primaryPage = menu_page;
            if (targetPage !== null) {
                apLayout.addPageToNextColumn(menu_page, targetPage);
            } else {
                apLayout.addPageToNextColumn(menu_page, Qt.resolvedUrl("../" + url));
            }
        }
        setCurrentPage(pageNum);
        if (globalDrawer) {
            globalDrawer.close();
        }
    }

        function setCurrentPage(page) {
            console.log("📄 Setting current page to:", page);
            switch (page) {
            case 0:
                currentPage = dashboard_page;
                thirdPage = dashboard_page2;
                if (apLayout.columns === 3)
                // Could add third page logic here if needed
                {}
                break;
            case 1:
                currentPage = timesheet_list || timesheet_page;
                thirdPage = null;
                break;
            case 2:
                currentPage = activity_page;
                thirdPage = null;
                break;
            case 3:
                currentPage = task_page;
                thirdPage = null;
                break;
            case 4:
                currentPage = project_page;
                thirdPage = null;
                break;
            case 5:
                currentPage = updates_page;
                thirdPage = null;
                break;
            case 6:
                currentPage = settings_page;
                thirdPage = null;
                break;
            case 7:
                currentPage = aboutus_page;
                thirdPage = null;
                break;
            }
        }

        onColumnsChanged: {
            console.log("📐 Layout columns changed to:", columns);
            if (init === false) {
                switch (columns) {
                case 1:
                    primaryPage = dashboard_page;
                    if (currentPage) {
                        addPageToCurrentColumn(primaryPage, currentPage);
                    }
                    break;
                case 2:
                    primaryPage = menu_page;
                    if (currentPage) {
                        addPageToNextColumn(primaryPage, currentPage);
                    }
                    break;
                case 3:
                    primaryPage = menu_page;
                    if (currentPage) {
                        addPageToNextColumn(primaryPage, currentPage);
                    }
                    if (currentPage && thirdPage)
                        addPageToNextColumn(currentPage, thirdPage);
                    break;
                }
            }
        }
    
    function reloadApplication() {
        try {
            if (typeof apLayout.removePages === "function") {
                apLayout.removePages(apLayout.primaryPage);
            }

            apLayout.primaryPage = splash_page;
            apLayout.currentPage = splash_page;
            apLayout.thirdPage = dashboard_page2;

            rootApp.init = true;

            Qt.callLater(function () {
                try {
                    apLayout.setFirstScreen();
                    Qt.callLater(function () {
                        refreshAppData();
                    });
                } catch (layoutError) {
                    console.error("❌ ERROR during setFirstScreen():", layoutError);
                    refreshAppData();
                }
            });
        } catch (e) {
            console.error("❌ ERROR during application reload:", e);
            refreshAppData();
        }
        console.log("✅ Full application reload completed");
    }

    function refreshAppData() {
        if (dashboard_page && typeof dashboard_page.refreshData === "function") {
            dashboard_page.refreshData();
        }
        if (dashboard_page2 && typeof dashboard_page2.refreshData === "function") {
            dashboard_page2.refreshData();
        }
        if (timesheet_list && typeof timesheet_list.fetch_timesheets_list === "function") {
            timesheet_list.fetch_timesheets_list();
        }
        if (timesheet_page && typeof timesheet_page.refreshData === "function") {
            timesheet_page.refreshData();
        }
        if (activity_page && typeof activity_page.get_activity_list === "function") {
            activity_page.get_activity_list();
        }
        if (task_page && typeof task_page.getTaskList === "function") {
            task_page.getTaskList(task_page.currentFilter || "today", "");
        }
        if (project_page && project_page.projectlist && typeof project_page.projectlist.refresh === "function") {
            project_page.projectlist.refresh();
        }
        Qt.callLater(function () {
            forceAllPagesUIRefresh();
        });
    }

    function forceAllPagesUIRefresh() {
        if (timesheet_list && timesheet_list.timesheetlist) {
            timesheet_list.timesheetlist.forceLayout();
        }
        if (task_page && task_page.tasklist) {
            task_page.tasklist.forceLayout();
        }
        if (project_page && project_page.projectlist) {
            project_page.projectlist.forceLayout();
        }
        if (activity_page && activity_page.activitylist) {
            activity_page.activitylist.forceLayout();
        }
    }

}
