import QtQuick 2.6
import QtQuick.LocalStorage 2.7 as Sql
import Lomiri.Components 1.3
import "../../models/draft_manager.js" as DraftManager
import "../../models/notifications.js" as Notifications
import "../../models/logger.js" as Logger

QtObject {
    id: startupManager

    property var notifPopup
    property var notificationSystem
    property var handleDeepLinkCallback

    function checkStartupArguments(args) {
        Logger.debug("StartupManager", "Startup arguments:", JSON.stringify(args))

        for (var i = 0; i < args.length; i++) {
            var arg = args[i];
            Logger.debug("StartupManager", "Checking argument:", arg)

            if (arg.indexOf("ubtms://") === 0) {
                Logger.debug("StartupManager", "Found deep link URL:", arg)
                if (handleDeepLinkCallback)
                    handleDeepLinkCallback(arg);
                return;
            }

            var deepLinkIndex = arg.indexOf("ubtms://");
            if (deepLinkIndex > 0) {
                var extractedDeepLink = arg.substring(deepLinkIndex);
                Logger.debug("StartupManager", "Extracted deep link URL:", extractedDeepLink)
                if (handleDeepLinkCallback)
                    handleDeepLinkCallback(extractedDeepLink);
                return;
            }
        }
    }

    function initializePushNotifications(backendBridge) {
        if (!notificationSystem || typeof notificationSystem.get_push_token !== "function")
            return;

        try {
            var token = notificationSystem.get_push_token();
            if (token && token.length > 0) {
                Logger.info("StartupManager", "Push token obtained, registering with backend: " + token.substring(0, 8) + "...");
                if (backendBridge) {
                    backendBridge.call("backend.save_push_token", [token], function (res) {
                        Logger.info("StartupManager", "Push token registered with backend: " + res);
                    });
                }
            } else {
                Logger.debug("StartupManager", "No push token returned by push service");
            }
        } catch (e) {
            Logger.warn("StartupManager", "Could not initialize push notifications:", e);
        }
    }

    function updateSystemBadge() {
        try {
            var unreadList = Notifications.getUnreadNotifications();
            var count = unreadList.length;
            if (notificationSystem)
                notificationSystem.updateCount(count);
        } catch (e) {
        }
    }

    function checkForUnsavedDrafts() {
        try {
            var summary = DraftManager.getDraftsSummary(-1);

            if (summary.total > 0) {
                var message = "You have unsaved work from a previous session:\n\n" +
                             formatDraftsMessage(summary) +
                             "\n\nOpen the respective forms to restore your changes.";
                if (notifPopup)
                    notifPopup.open("Unsaved Drafts Found", message, "info");
            }
        } catch (e) {
            Logger.error("StartupManager", "Error checking for unsaved drafts:", e.toString())
        }
    }

    function cleanupDeletedRecordDrafts() {
        try {
            DraftManager.cleanupDraftsForDeletedRecords("task");
            DraftManager.cleanupDraftsForDeletedRecords("timesheet");
            DraftManager.cleanupDraftsForDeletedRecords("project");
            DraftManager.cleanupDraftsForDeletedRecords("activity");
        } catch (e) {
        }
    }

    function formatDraftsMessage(summary) {
        if (!summary || !summary.byType)
            return "Loading drafts...";

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
            if (!summary.byType[type])
                continue;
            var count = summary.byType[type];
            var icon = typeIcons[type] || "•";
            var label = typeLabels[type] || type;
            message += icon + " " + count + " " + label;
            if (count > 1)
                message += "s";
            message += ",\t";
        }
        return message;
    }

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
                tx.executeSql("CREATE TABLE IF NOT EXISTS app_settings (key TEXT PRIMARY KEY, value TEXT)");
                var result = tx.executeSql("SELECT value FROM app_settings WHERE key = ?", ["theme_preference"]);
                if (result.rows.length > 0) {
                    themeName = result.rows.item(0).value;
                }
            });
            return themeName;
        } catch (e) {
            return "";
        }
    }

    function saveThemePreference(themeName) {
        try {
            var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
            db.transaction(function (tx) {
                tx.executeSql("CREATE TABLE IF NOT EXISTS app_settings (key TEXT PRIMARY KEY, value TEXT)");
                tx.executeSql("INSERT OR REPLACE INTO app_settings (key, value) VALUES (?, ?)", ["theme_preference", themeName]);
            });
        } catch (e) {
        }
    }
}