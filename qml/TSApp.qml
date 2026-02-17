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

import QtQuick 2.6
import Lomiri.Components 1.3
import QtQuick.Window 2.2
import QtQuick.Layouts 1.11
import QtQuick.LocalStorage 2.7 as Sql
import "../models/dbinit.js" as DbInit
import "../models/draft_manager.js" as DraftManager
import "../models/notifications.js" as Notifications
import Pparent.Notifications 1.0
import "components"
import "."
import "settings"

/*
Todo: Need to Visit this Page Again and Refactor it.
This is the Main View of the Application.
It contains the AdaptivePageLayout which is used to switch between different layouts based on the screen size

*/
MainView {
    id: mainView

    objectName: "TS"
    applicationName: "ubtms"
    property bool init: true
    property alias globalTimerWidget: globalTimerWidget
    property alias backend_bridge: backend_bridge

    property int currentAccountId: -1
    property string currentAccountName: ""

    width: units.gu(50)
    //  width: Screen.desktopAvailableWidth < units.gu(130) ? units.gu(40) : units.gu(130)
    // width: units.gu(50) //GM: for testing with only one column
    // height: units.gu(95)

    signal globalAccountChanged(int accountId, string accountName)
    signal accountDataRefreshRequested(int accountId)
    
    // Deep link handling for system notification navigation
    // Pending navigation data (used when app needs to initialize first)
    property var pendingNavigation: null
    
    // Handle incoming URI from system notifications
    Connections {
        target: UriHandler
        onOpened: function(uris) {
            console.log("UriHandler: Received URIs:", JSON.stringify(uris));
            if (uris.length > 0) {
                handleDeepLink(uris[0]);
            }
        }
    }
    
    // Function to handle deep link navigation
    function handleDeepLink(uri) {
        console.log("handleDeepLink: Processing URI:", uri);
        
        try {
            // Parse URI manually: ubtms://navigate?type=Task&id=123&account_id=1&odoo_id=1
            // The URL object is not available in QML, so we parse manually
            var queryStart = uri.indexOf("?");
            if (queryStart === -1) {
                console.log("handleDeepLink: No query parameters found");
                return;
            }
            
            var queryString = uri.substring(queryStart + 1);
            var params = {};
            var pairs = queryString.split("&");
            for (var i = 0; i < pairs.length; i++) {
                var pair = pairs[i].split("=");
                if (pair.length === 2) {
                    params[decodeURIComponent(pair[0])] = decodeURIComponent(pair[1]);
                }
            }
            
            var navType = params["type"] || "";
            var recordId = parseInt(params["id"]) || -1;
            var accountId = parseInt(params["account_id"]) || 0;
            // Check if this is an odoo_record_id (stable ID) vs local id
            var isOdooId = (params["odoo_id"] === "1");
            
            console.log("handleDeepLink: type=" + navType + ", recordId=" + recordId + ", accountId=" + accountId + ", isOdooId=" + isOdooId);
            
            if (!navType || recordId <= 0) {
                console.log("handleDeepLink: Missing required parameters");
                return;
            }
            
            // Wait for app to be ready before navigating
            if (init) {
                pendingNavigation = {type: navType, id: recordId, accountId: accountId, isOdooId: isOdooId};
                console.log("handleDeepLink: App not ready, queuing navigation");
                return;
            }
            
            navigateToRecord(navType, recordId, accountId, isOdooId);
        } catch (e) {
            console.error("handleDeepLink: Error parsing URI:", e);
        }
    }
    
    // Navigate to a specific record based on type
    // isOdooId: if true, recordId is an odoo_record_id (stable), otherwise it's a local id
    function navigateToRecord(navType, recordId, accountId, isOdooId) {
        console.log("navigateToRecord: type=" + navType + ", id=" + recordId + ", isOdooId=" + isOdooId);
        
        if (navType === "Task" && recordId > 0) {
            apLayout.addPageToNextColumn(apLayout.primaryPage, Qt.resolvedUrl("Tasks.qml"), {
                "recordid": recordId,
                "isOdooRecordId": isOdooId || false,
                "isReadOnly": true
            });
        } else if (navType === "Activity" && recordId > 0) {
            apLayout.addPageToNextColumn(apLayout.primaryPage, Qt.resolvedUrl("Activities.qml"), {
                "recordid": recordId,
                "accountid": accountId,
                "isOdooRecordId": isOdooId || false,
                "isReadOnly": true
            });
        } else if (navType === "Project" && recordId > 0) {
            apLayout.addPageToNextColumn(apLayout.primaryPage, Qt.resolvedUrl("Projects.qml"), {
                "recordid": recordId,
                "isOdooRecordId": isOdooId || false,
                "isReadOnly": true
            });
        } else if (navType === "Timesheet" && recordId > 0) {
            apLayout.addPageToNextColumn(apLayout.primaryPage, Qt.resolvedUrl("Timesheet.qml"), {
                "recordid": recordId,
                "isOdooRecordId": isOdooId || false,
                "isReadOnly": true
            });
        } else {
            console.log("navigateToRecord: Unknown type or invalid recordId");
        }
    }

    NotificationHelper {
        id: notificationSystem
        push_app_id: "ubtms_ubtms"
        Component.onCompleted: {
            console.log("Starting background daemon...")
            startDaemon()
        }
    }
    
    // NOTE: PushClient removed - using Qt.application.arguments approach instead
    // for handling notification click navigation
    
    // Periodic daemon health check timer - check more frequently to catch crashes
    Timer {
        id: daemonHealthCheckTimer
        interval: 120000  // Check every 2 minutes to catch daemon crashes quickly
        running: true
        repeat: true
        onTriggered: {
            console.log("Checking daemon health...")
            notificationSystem.ensureDaemonRunning()
        }
    }
    
    // Timer for delayed deep link navigation on cold start
    // This ensures all UI components are fully loaded before navigating
    Timer {
        id: delayedNavigationTimer
        interval: 500  // 500ms delay to ensure pages are loaded
        repeat: false
        onTriggered: {
            if (pendingNavigation) {
                console.log("delayedNavigationTimer: Executing pending navigation - type:", pendingNavigation.type, "id:", pendingNavigation.id, "isOdooId:", pendingNavigation.isOdooId);
                navigateToRecord(pendingNavigation.type, pendingNavigation.id, pendingNavigation.accountId, pendingNavigation.isOdooId);
                pendingNavigation = null;
            }
        }
    }

    function showSystemNotification(title, message) {
        notificationSystem.showNotificationMessage(title, message)
    }

    GlobalTimerWidget {
        id: globalTimerWidget
        z: 9999
        anchors.bottom: parent.bottom
        visible: false
        showNotification: function (title, message, type) {
            notifPopup.open(title, message, type);
        }
    }

    BackendBridge {
        id: backend_bridge

        onMessageReceived: function (data) {}

        onPythonError: function (tb) {
            console.error("[FAILURE] Critical Error from backend");
        }

        onReadyChanged: if (ready) {
            console.log("Backend ready");
        }
    }

    //used by attachment manager for example
    ImagePreviewer
    {
        id: imagePreviewer
        anchors.fill: parent
    }


    AccountSelectorDialog {
        id: accountPicker
        titleText: i18n.dtr("ubtms", "Switch account")
        restrictToLocalOnly: false

        onAccepted: function (id, name) {
            // persist selection, refresh views, trigger sync, etc.
            console.log("Account chosen:", id, name);

            // Update mainView's current account
            currentAccountId = id;
            currentAccountName = name;

        // Emit signals to notify other components
        //globalAccountChanged(id, name);
        //accountDataRefreshRequested(id);
        }
        onCanceled: console.log("Account selection canceled")
    }

    // Global notification popup
    NotificationPopup {
        id: notifPopup
    }

    InfoBar {
        id: infobar
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: parent.width
        height: units.gu(10)
    }

    AdaptivePageLayout {
        id: apLayout
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        property bool isMultiColumn: true
        property Page currentPage: splash_page
        property Page thirdPage: dashboard_page2
        primaryPage: splash_page

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
                target: mainView
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
                target: mainView
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
                target: mainView
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
                target: mainView
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
                target: mainView
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
                target: mainView
                onAccountDataRefreshRequested: function (accountId) {
                    console.log("🔄 Refreshing Project data for account:", accountId);
                    if (project_page.visible && project_page.projectlist && typeof project_page.projectlist.refresh === 'function') {
                        project_page.projectlist.refresh();
                    }
                }
            }
        }
        Settings_Page {
            id: settings_page
        }
        Timesheet_Page {
            id: timesheet_list

            Connections {
                target: mainView
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
                break;
            case 2:
                primaryPage = menu_page;
                currentPage = dashboard_page;
                addPageToNextColumn(primaryPage, currentPage);
                break;
            case 3:
                primaryPage = menu_page;
                currentPage = dashboard_page;
                addPageToNextColumn(primaryPage, currentPage);
                addPageToNextColumn(currentPage, thirdPage);
                break;
            }
            init = false;
            
            // Process any pending deep link navigation
            // Use a Timer to ensure all UI components are fully loaded on cold start
            if (pendingNavigation) {
                console.log("setFirstScreen: Pending navigation detected, scheduling with delay");
                delayedNavigationTimer.start();
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
                currentPage = timesheet_page;
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
                currentPage = sync_page;
                thirdPage = null;
                break;
            case 6:
                currentPage = settings_page;
                thirdPage = null;
                break;
            case 7:
                currentPage = timesheet_list;
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
                    addPageToCurrentColumn(primaryPage, currentPage);
                    break;
                case 2:
                    primaryPage = menu_page;
                    addPageToNextColumn(primaryPage, currentPage);
                    break;
                case 3:
                    primaryPage = menu_page;
                    addPageToNextColumn(primaryPage, currentPage);
                    if (thirdPage != "")
                        addPageToNextColumn(currentPage, thirdPage);
                    break;
                }
            }
        }
    }

    function reloadApplication() {
        try {
            if (typeof apLayout.removePages === 'function') {
                apLayout.removePages(apLayout.primaryPage);
            }

            apLayout.primaryPage = splash_page;
            apLayout.currentPage = splash_page;
            apLayout.thirdPage = dashboard_page2;

            init = true;

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
        if (dashboard_page && typeof dashboard_page.refreshData === 'function') {
            dashboard_page.refreshData();
        }

        if (dashboard_page2 && typeof dashboard_page2.refreshData === 'function') {
            dashboard_page2.refreshData();
        }

        if (timesheet_list && typeof timesheet_list.fetch_timesheets_list === 'function') {
            timesheet_list.fetch_timesheets_list();
        }

        if (timesheet_page && typeof timesheet_page.refreshData === 'function') {
            timesheet_page.refreshData();
        }

        if (activity_page && typeof activity_page.get_activity_list === 'function') {
            activity_page.get_activity_list();
        }

        if (task_page && typeof task_page.getTaskList === 'function') {
            task_page.getTaskList(task_page.currentFilter || "today", "");
        }

        if (project_page && project_page.projectlist && typeof project_page.projectlist.refresh === 'function') {
            project_page.projectlist.refresh();
        }
        
     
        // Force UI layout refresh
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

 

    Component.onCompleted: {
        DbInit.initializeDatabase();

        // Load and apply saved theme preference
        loadAndApplyTheme();
        
        // Update system badge to reflect current unread notifications
        updateSystemBadge();
        
        // Check if daemon setup is needed (missing dependencies)
        checkDaemonSetupNeeded();
        
        // Check for unsaved drafts from previous session (crash recovery)
        checkForUnsavedDrafts();
        
        // Clean up drafts for deleted records
        cleanupDeletedRecordDrafts();
        
        // Check for deep link URL in command line arguments (notification click)
        checkStartupArguments();

        Qt.callLater(function () {
            apLayout.setFirstScreen(); // Delay page setup until after DB init

        });
    }
    
    // Check if app was launched with a deep link URL (via notification click)
    function checkStartupArguments() {
        var args = Qt.application.arguments;
        console.log("Startup arguments:", JSON.stringify(args));
        
        for (var i = 0; i < args.length; i++) {
            var arg = args[i];
            console.log("Checking argument:", arg);
            
            // Check for ubtms:// or appid:// URLs
            if (arg.indexOf("ubtms://") === 0) {
                console.log("Found deep link URL:", arg);
                handleDeepLink(arg);
                return;
            }
        }
    }
    
    // Function to check if background sync daemon needs setup
    function checkDaemonSetupNeeded() {
        try {
            // Check for the marker file that daemon creates when dependencies are missing
            var xhr = new XMLHttpRequest();
            var setupFile = "/home/phablet/.ubtms_needs_setup";
            xhr.open("GET", "file://" + setupFile, false);
            try {
                xhr.send();
                if (xhr.status === 200 && xhr.responseText.length > 0) {
                    var missingDeps = xhr.responseText;
                    console.log("Daemon setup needed - missing: " + missingDeps);
                    
                    var message = "Background sync requires additional packages.\n\n" +
                                 "To enable push notifications, connect via adb and run:\n\n" +
                                 "sudo apt install python3-dbus python3-gi gir1.2-glib-2.0\n\n" +
                                 "Then restart the app.";
                    
                    notifPopup.open("⚠️ Setup Required", message, "warning");
                }
            } catch (fileError) {
                // File doesn't exist = setup is complete, this is normal
                console.log("Daemon setup check: OK (no setup needed)");
            }
        } catch (e) {
            console.log("Daemon setup check skipped:", e);
        }
    }
    
    // Function to update the system badge with current unread notification count
    function updateSystemBadge() {
        try {
            var unreadList = Notifications.getUnreadNotifications();
            var count = unreadList.length;
            notificationSystem.updateCount(count);
            console.log("System badge updated to:", count);
        } catch (e) {
            console.error("Failed to update system badge:", e);
        }
    }
    
    // Function to check for unsaved drafts on app startup (crash recovery)
    function checkForUnsavedDrafts() {
        try {
            var summary = DraftManager.getDraftsSummary(-1);  // Get summary for all accounts
            
            if (summary.total > 0) {
                var message = "You have unsaved work from a previous session:\n\n" + 
                             formatDraftsMessage(summary) + 
                             "\n\nOpen the respective forms to restore your changes.";
                
                notifPopup.open("📂 Unsaved Drafts Found", message, "info");
            }
            
            // Cleanup old drafts (older than 7 days)
            DraftManager.cleanupOldDrafts(7);
            
        } catch (e) {
            console.error("❌ Error checking for unsaved drafts:", e.toString());
        }
    }
    
    // Function to clean up drafts for deleted records on app startup
    function cleanupDeletedRecordDrafts() {
        try {
            // Clean up task drafts for deleted tasks
            var taskResult = DraftManager.cleanupDraftsForDeletedRecords("task");
            if (taskResult.deletedCount > 0) {
                console.log("🗑️ Cleaned up " + taskResult.deletedCount + " draft(s) for deleted tasks");
            }
            
            // Clean up timesheet drafts for deleted timesheets
            var timesheetResult = DraftManager.cleanupDraftsForDeletedRecords("timesheet");
            if (timesheetResult.deletedCount > 0) {
                console.log("🗑️ Cleaned up " + timesheetResult.deletedCount + " draft(s) for deleted timesheets");
            }
            
            // Clean up project drafts for deleted projects
            var projectResult = DraftManager.cleanupDraftsForDeletedRecords("project");
            if (projectResult.deletedCount > 0) {
                console.log("🗑️ Cleaned up " + projectResult.deletedCount + " draft(s) for deleted projects");
            }
            
            // Clean up activity drafts for deleted activities
            var activityResult = DraftManager.cleanupDraftsForDeletedRecords("activity");
            if (activityResult.deletedCount > 0) {
                console.log("🗑️ Cleaned up " + activityResult.deletedCount + " draft(s) for deleted activities");
            }
            
            // Note: project_update drafts are always for new records (recordId = null)
            // so they don't need cleanup based on deleted records
            
        } catch (e) {
            console.error("❌ Error cleaning up deleted record drafts:", e.toString());
        }
    }
    
    // Helper function to format drafts message with icons and grouping
    function formatDraftsMessage(summary) {
        if (!summary || !summary.byType) {
            return "Loading drafts...";
        }
        
        var message = "";
        var typeIcons = {
            "timesheet": "⏱️",
            "task": "🗒",
            "project": "📁",
            "activity": "📝",
            "project_update": "📊"
        };
        
        var typeLabels = {
            "timesheet": "Timesheet",
            "task": "Task",
            "project": "Project",
            "activity": "Activity",
            "project_update": "Project Update"
        };
        
        var typeOrder = ["timesheet", "task", "project", "activity", "project_update"];
        
        for (var i = 0; i < typeOrder.length; i++) {
            var type = typeOrder[i];
            if (!summary.byType[type]) continue;
            
            var count = summary.byType[type];
            var icon = typeIcons[type] || "•";
            var label = typeLabels[type] || type;
            
            message += icon + " " + count + " " + label;
            if (count > 1) message += "s";
            message += ",\t";
        }
        
        return message;
    }

    // Function to load saved theme preference and apply it
    function loadAndApplyTheme() {
        try {
            var savedTheme = getSavedThemePreference();

            if (savedTheme !== "" && savedTheme !== null && savedTheme !== undefined) {
                Theme.name = savedTheme;
            } else {
                // No saved theme found, set and save a default theme
                var defaultTheme = "Ubuntu.Components.Themes.Ambiance";
                Theme.name = defaultTheme;
                saveThemePreference(defaultTheme);
            }
        } catch (e) {
            // Fallback to light theme if there's an error
            Theme.name = "Ubuntu.Components.Themes.Ambiance";
            console.warn("⚠️  Theme loading failed, using fallback:", e);
        }
    }

    // Function to get saved theme preference from database
    function getSavedThemePreference() {
        try {
            var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
            var themeName = "";

            db.transaction(function (tx) {
                // Create settings table if it doesn't exist
                tx.executeSql('CREATE TABLE IF NOT EXISTS app_settings (key TEXT PRIMARY KEY, value TEXT)');

                // Get saved theme
                var result = tx.executeSql('SELECT value FROM app_settings WHERE key = ?', ['theme_preference']);
                if (result.rows.length > 0) {
                    themeName = result.rows.item(0).value;
                }
            });

            return themeName;
        } catch (e) {
            console.warn("⚠️  Error getting saved theme preference:", e);
            return "";
        }
    }

    // Function to save theme preference to database
    function saveThemePreference(themeName) {
        try {
            var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);

            db.transaction(function (tx) {
                // Create settings table if it doesn't exist
                tx.executeSql('CREATE TABLE IF NOT EXISTS app_settings (key TEXT PRIMARY KEY, value TEXT)');

                // Save theme preference (INSERT OR REPLACE)
                tx.executeSql('INSERT OR REPLACE INTO app_settings (key, value) VALUES (?, ?)', ['theme_preference', themeName]);
            });

            console.log("💾 Theme preference saved:", themeName);
        } catch (e) {
            console.warn("⚠️  Error saving theme preference:", e);
        }
    }
}
