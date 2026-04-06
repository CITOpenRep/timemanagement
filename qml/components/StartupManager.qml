import QtQuick 2.6
import QtQuick.LocalStorage 2.7 as Sql
import Lomiri.Components 1.3
import "../../models/draft_manager.js" as DraftManager
import "../../models/notifications.js" as Notifications

QtObject {
    id: startupManager

    property var notifPopup
    property var notificationSystem
    property var handleDeepLinkCallback

    // Check if app was launched with a deep link URL (via notification click)
    function checkStartupArguments(args) {
        console.log("Startup arguments:", JSON.stringify(args));

        for (var i = 0; i < args.length; i++) {
            var arg = args[i];
            console.log("Checking argument:", arg);

            if (arg.indexOf("ubtms://") === 0) {
                console.log("Found deep link URL:", arg);
                if (handleDeepLinkCallback) handleDeepLinkCallback(arg);
                return;
            }

            // Some launchers prepend appid:// and still include a deep-link payload.
            var deepLinkIndex = arg.indexOf("ubtms://");
            if (deepLinkIndex > 0) {
                var extractedDeepLink = arg.substring(deepLinkIndex);
                console.log("Extracted deep link URL:", extractedDeepLink);
                if (handleDeepLinkCallback) handleDeepLinkCallback(extractedDeepLink);
                return;
            }
        }
    }
    
    // Function to check if background sync daemon needs setup
    function checkDaemonSetupNeeded() {
        try {
            var xhr = new XMLHttpRequest();
            var setupFile = "/home/phablet/.ubtms_needs_setup";
            xhr.open("GET", "file://" + setupFile, false);
            try {
                xhr.send();
                if (xhr.status === 200 && xhr.responseText.length > 0) {
                    var missingDeps = xhr.responseText;
                    var message = "Background sync requires additional packages.\n\n" +
                                 "To enable push notifications, connect via adb and run:\n\n" +
                                 "sudo apt install python3-dbus python3-gi gir1.2-glib-2.0\n\n" +
                                 "Then restart the app.";
                    if (notifPopup) notifPopup.open("⚠️ Setup Required", message, "warning");
                }
            } catch (fileError) {
                // File doesn't exist = setup is complete, this is normal
            }
        } catch (e) { }
    }
    
    // Function to update the system badge with current unread notification count
    function updateSystemBadge() {
        try {
            var unreadList = Notifications.getUnreadNotifications();
            var count = unreadList.length;
            if (notificationSystem) notificationSystem.updateCount(count);
        } catch (e) {}
    }
    
    // Function to check for unsaved drafts on app startup (crash recovery)
    function checkForUnsavedDrafts() {
        try {
            var summary = DraftManager.getDraftsSummary(-1);  // Get summary for all accounts
            
            if (summary.total > 0) {
                var message = "You have unsaved work from a previous session:\n\n" + 
                             formatDraftsMessage(summary) + 
                             "\n\nOpen the respective forms to restore your changes.";
                if (notifPopup) notifPopup.open("📂 Unsaved Drafts Found", message, "info");
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
            DraftManager.cleanupDraftsForDeletedRecords("task");
            DraftManager.cleanupDraftsForDeletedRecords("timesheet");
            DraftManager.cleanupDraftsForDeletedRecords("project");
            DraftManager.cleanupDraftsForDeletedRecords("activity");
        } catch (e) {}
    }
    
    // Helper function to format drafts message with icons and grouping
    function formatDraftsMessage(summary) {
        if (!summary || !summary.byType) return "Loading drafts...";
        
        var message = "";
        var typeIcons = {
            "timesheet": "⏱️", "task": "🗒", "project": "📁",
            "activity": "📝", "project_update": "📊"
        };
        var typeLabels = {
            "timesheet": "Timesheet", "task": "Task", "project": "Project",
            "activity": "Activity", "project_update": "Project Update"
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
                var defaultTheme = "Ubuntu.Components.Themes.Ambiance";
                Theme.name = defaultTheme;
                saveThemePreference(defaultTheme);
            }
        } catch (e) {
            Theme.name = "Ubuntu.Components.Themes.Ambiance";
        }
    }

    function getSavedThemePreference() {
        try {
            var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
            var themeName = "";
            db.transaction(function (tx) {
                tx.executeSql('CREATE TABLE IF NOT EXISTS app_settings (key TEXT PRIMARY KEY, value TEXT)');
                var result = tx.executeSql('SELECT value FROM app_settings WHERE key = ?', ['theme_preference']);
                if (result.rows.length > 0) {
                    themeName = result.rows.item(0).value;
                }
            });
            return themeName;
        } catch (e) { return ""; }
    }

    function saveThemePreference(themeName) {
        try {
            var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
            db.transaction(function (tx) {
                tx.executeSql('CREATE TABLE IF NOT EXISTS app_settings (key TEXT PRIMARY KEY, value TEXT)');
                tx.executeSql('INSERT OR REPLACE INTO app_settings (key, value) VALUES (?, ?)', ['theme_preference', themeName]);
            });
        } catch (e) { }
    }
}
