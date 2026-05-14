import QtQuick 2.6
import Lomiri.Components 1.3
import QtQuick.Window 2.2
import QtQuick.Layouts 1.11
import "../"
import "pages" as AppPages
import "../features/dashboard/pages" as DashboardPages
import "../features/settings/pages" as SettingsPages
import "../features/tasks/pages" as TaskPages
import "../features/timesheets/pages" as TimesheetPages
import "navigation/NavigationRoutes.js" as NavigationRoutes

AdaptivePageLayout {
    id: apLayout

    property var rootApp
    property var globalDrawer
    property var navigationController

    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom

    property bool isMultiColumn: true
    property Page currentPage: splash_page
    property Page thirdPage: dashboard_page2
    property string currentMenuPageUrl: "features/dashboard/pages/Dashboard.qml"

    primaryPage: splash_page

    function openGlobalDrawer() {
        if (typeof globalDrawer !== "undefined") {
            globalDrawer.open();
        }
    }

    layouts: [
        PageColumnsLayout {
            when: width > units.gu(80) && width < units.gu(130)

            PageColumn {
                minimumWidth: units.gu(30)
                maximumWidth: units.gu(50)
                preferredWidth: width > units.gu(90) ? units.gu(20) : units.gu(15)
            }

            PageColumn {
                minimumWidth: units.gu(50)
                maximumWidth: units.gu(80)
                preferredWidth: units.gu(80)
            }
        },

        PageColumnsLayout {
            when: width >= units.gu(130)

            PageColumn {
                minimumWidth: units.gu(30)
                maximumWidth: units.gu(50)
                preferredWidth: units.gu(40)
            }

            PageColumn {
                minimumWidth: units.gu(70)
                maximumWidth: units.gu(100)
                preferredWidth: units.gu(80)
            }

            PageColumn {
                fillWidth: true
            }
        }
    ]

    AppPages.Splash {
        id: splash_page
    }

    Menu {
        id: menu_page
        navigationController: apLayout.navigationController
    }

    DashboardPages.Dashboard {
        id: dashboard_page

        Connections {
            target: rootApp
            onAccountDataRefreshRequested: function (accountId) {
                if (dashboard_page.visible && typeof dashboard_page.refreshData === "function") {
                    dashboard_page.refreshData();
                }
            }
        }
    }

    DashboardPages.Dashboard2 {
        id: dashboard_page2

        Connections {
            target: rootApp
            onAccountDataRefreshRequested: function (accountId) {
                console.debug("🔄 Refreshing Dashboard2 data for account:", accountId);
                if (dashboard_page2.visible && typeof dashboard_page2.refreshData === "function") {
                    dashboard_page2.refreshData();
                }
            }
        }
    }

    TimesheetPages.Timesheet {
        id: timesheet_page

        Connections {
            target: rootApp
            onAccountDataRefreshRequested: function (accountId) {
                console.debug("🔄 Refreshing Timesheet data for account:", accountId);
                if (timesheet_page.visible && typeof timesheet_page.refreshData === "function") {
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
                console.debug("🔄 Refreshing Activity data for account:", accountId);
                if (activity_page.visible && typeof activity_page.get_activity_list === "function") {
                    activity_page.get_activity_list();
                }
            }
        }
    }

    TaskPages.Task_Page {
        id: task_page

        Connections {
            target: rootApp
            onAccountDataRefreshRequested: function (accountId) {
                console.debug("🔄 Refreshing Task data for account:", accountId);
                if (task_page.visible && typeof task_page.getTaskList === "function") {
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
                console.debug("🔄 Refreshing Project data for account:", accountId);
                if (project_page.visible && project_page.projectlist && typeof project_page.projectlist.refresh === "function") {
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

    SettingsPages.Settings_Page {
        id: settings_page
    }

    TimesheetPages.Timesheet_Page {
        id: timesheet_list

        Connections {
            target: rootApp
            onAccountDataRefreshRequested: function (accountId) {
                console.debug("🔄 Refreshing Timesheet List data for account:", accountId);
                if (timesheet_list.visible && typeof timesheet_list.fetch_timesheets_list === "function") {
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
            currentMenuPageUrl = "features/dashboard/pages/Dashboard.qml";
            break;
        case 2:
            primaryPage = menu_page;
            currentPage = dashboard_page;
            currentMenuPageUrl = "features/dashboard/pages/Dashboard.qml";
            addPageToNextColumn(primaryPage, currentPage);
            break;
        case 3:
            primaryPage = menu_page;
            currentPage = dashboard_page;
            currentMenuPageUrl = "features/dashboard/pages/Dashboard.qml";
            addPageToNextColumn(primaryPage, currentPage);
            addPageToNextColumn(currentPage, thirdPage);
            break;
        }

        init = false;

        if (systemIntegration.pendingNavigation) {
            console.debug("setFirstScreen: Pending navigation detected, scheduling with delay");
            systemIntegration.startDelayedNavigation();
        }
    }

    function setPageGlobal(url, pageNum) {
        var targetPage = null;
        var pageKey = NavigationRoutes.resolvePageKey(pageNum, url);

        if (pageKey === "dashboard")
            targetPage = dashboard_page;
        else if (pageKey === "timesheet_list")
            targetPage = timesheet_list || timesheet_page;
        else if (pageKey === "activity")
            targetPage = activity_page;
        else if (pageKey === "task")
            targetPage = task_page;
        else if (pageKey === "project")
            targetPage = project_page;
        else if (pageKey === "updates")
            targetPage = updates_page;
        else if (pageKey === "settings")
            targetPage = settings_page;
        else if (pageKey === "about")
            targetPage = aboutus_page;

        if (targetPage !== null) {
            apLayout.currentPage = targetPage;
        }

        currentMenuPageUrl = url;

        if (apLayout.columns === 1) {
            if (targetPage !== null) {
                if (apLayout.primaryPage === targetPage) {
                    if (typeof apLayout.removePages === "function") {
                        apLayout.removePages(targetPage);
                    }
                } else {
                    apLayout.primaryPage = targetPage;
                }
            } else {
                if (apLayout.primaryPage !== dashboard_page) {
                    apLayout.primaryPage = dashboard_page;
                } else if (typeof apLayout.removePages === "function") {
                    apLayout.removePages(dashboard_page);
                }

                apLayout.addPageToCurrentColumn(dashboard_page, Qt.resolvedUrl("../" + url));
            }
        } else {
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
        console.debug("📄 Setting current page to:", page);
        switch (page) {
        case 0:
            currentPage = dashboard_page;
            thirdPage = dashboard_page2;
            if (apLayout.columns === 3) {
                apLayout.addPageToNextColumn(currentPage, thirdPage);
            }
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
        console.debug("📐 Layout columns changed to:", columns);
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
                if (currentPage && thirdPage) {
                    addPageToNextColumn(currentPage, thirdPage);
                }
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
        console.debug("✅ Full application reload completed");
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
