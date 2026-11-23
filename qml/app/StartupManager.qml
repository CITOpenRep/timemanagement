import QtQuick 2.6
import QtQuick.LocalStorage 2.7 as Sql
import Lomiri.Components 1.3
import "../../models/draft_manager.js" as DraftManager
import "../../models/notifications.js" as Notifications
import "../../models/logger.js" as Logger

Item {
    id: startupManager
    visible: false

    property var notifPopup
    property var notificationSystem
    property var handleDeepLinkCallback
    property var backendBridge: null

    property bool isStartingUp: false
    property bool isStartupComplete: false
    property string statusMessage: ""
    property real syncProgress: 0.0
    property bool syncFailed: false
    property bool splashCompleted: false
    property bool _connectedToBridge: false
    property bool _pendingDismissal: false
    property int _pendingDismissalDelay: 2000

    property var startupSyncQueue: []
    property int startupSyncQueueIndex: 0
    property int startupSyncSuccessCount: 0
    property int startupSyncFailCount: 0

    signal startupStarted()
    signal startupFinished()

    Timer {
        id: startupDismissTimer
        repeat: false
        onTriggered: {
            startupManager.isStartingUp = false;
            startupManager.isStartupComplete = false;
            startupSafetyTimer.stop();
            splashWatchdogTimer.stop();
            startupManager.startupFinished();
        }
    }

    Timer {
        id: splashWatchdogTimer
        interval: 3500
        repeat: false
        onTriggered: {
            if (!startupManager.splashCompleted) {
                startupManager.notifySplashDismissed();
            }
        }
    }

    Timer {
        id: startupSafetyTimer
        interval: 15000
        repeat: false
        onTriggered: {
            Logger.debug("StartupManager", "Startup safety timeout reached, fading out status indicator");
            scheduleStartupFinish(false, 300);
        }
    }

    function notifySplashDismissed() {
        splashCompleted = true;
        if (_pendingDismissal) {
            _pendingDismissal = false;
            startupDismissTimer.interval = _pendingDismissalDelay;
            startupDismissTimer.restart();
        }
    }

    function startStartup(bridge) {
        isStartingUp = true;
        isStartupComplete = false;
        syncFailed = false;
        syncProgress = 0.0;
        splashCompleted = false;
        _pendingDismissal = false;
        _pendingDismissalDelay = 2000;
        startupSyncQueue = [];
        startupSyncQueueIndex = 0;
        startupSyncSuccessCount = 0;
        startupSyncFailCount = 0;
        statusMessage = i18n.dtr("ubtms", "Connecting...");
        startupSafetyTimer.restart();
        splashWatchdogTimer.restart();
        startupStarted();

        if (bridge) {
            connectToBridge(bridge);
        }
    }

    function scheduleStartupFinish(success, delayMs) {
        var delay = delayMs || 2000;
        if (!splashCompleted) {
            _pendingDismissal = true;
            _pendingDismissalDelay = delay;
            return;
        }
        startupDismissTimer.interval = delay;
        startupDismissTimer.restart();
    }

    function connectToBridge(bridge) {
        if (!bridge || _connectedToBridge)
            return;

        backendBridge = bridge;
        try {
            if (typeof bridge.messageReceived !== "undefined") {
                bridge.messageReceived.connect(handleSyncMessage);
                _connectedToBridge = true;
            }
        } catch (e) {
            Logger.warn("StartupManager", "Could not connect to bridge messages:", e);
        }
    }

    function syncNextAccountInQueue() {
        if (!backendBridge || startupSyncQueueIndex >= startupSyncQueue.length) {
            finishStartupSyncQueue();
            return;
        }

        var currentAcc = startupSyncQueue[startupSyncQueueIndex];
        var total = startupSyncQueue.length;
        var currentNum = startupSyncQueueIndex + 1;

        if (total > 1) {
            statusMessage = i18n.dtr("ubtms", "Syncing") + " " + currentAcc.name + " (" + currentNum + "/" + total + ")...";
        } else {
            statusMessage = i18n.dtr("ubtms", "Syncing...");
        }

        syncProgress = total > 1 ? (startupSyncQueueIndex / total) : 0.0;

        backendBridge.call("backend.resolve_qml_db_path", ["ubtms"], function (dbPath) {
            var targetDb = dbPath || "app_settings.db";
            backendBridge.call("backend.start_sync_in_background", [targetDb, currentAcc.id], function (res) {
                Logger.info("StartupManager", "Startup sync initiated for account " + currentAcc.id + " (" + currentAcc.name + "): " + res);
                if (res === false) {
                    onCurrentAccountSyncCompleted(false);
                }
            });
        });
    }

    function onCurrentAccountSyncCompleted(success) {
        if (!isStartingUp)
            return;

        if (success) {
            startupSyncSuccessCount++;
        } else {
            startupSyncFailCount++;
        }

        startupSyncQueueIndex++;

        if (startupSyncQueueIndex < startupSyncQueue.length) {
            syncNextAccountInQueue();
        } else {
            finishStartupSyncQueue();
        }
    }

    function finishStartupSyncQueue() {
        var total = startupSyncQueue.length;
        if (total === 0) {
            isStartupComplete = true;
            syncFailed = false;
            statusMessage = i18n.dtr("ubtms", "Ready");
            scheduleStartupFinish(true, 2000);
            return;
        }

        if (startupSyncFailCount === 0) {
            isStartupComplete = true;
            syncFailed = false;
            syncProgress = 1.0;
            statusMessage = i18n.dtr("ubtms", "Updated");
            scheduleStartupFinish(true, 2000);
        } else if (startupSyncSuccessCount > 0) {
            isStartupComplete = true;
            syncFailed = false;
            syncProgress = 1.0;
            if (startupSyncFailCount === 1) {
                statusMessage = i18n.dtr("ubtms", "Updated (1 failed)");
            } else {
                statusMessage = i18n.dtr("ubtms", "Updated (" + startupSyncFailCount + " failed)");
            }
            scheduleStartupFinish(true, 2500);
        } else {
            syncFailed = true;
            syncProgress = 0.0;
            statusMessage = i18n.dtr("ubtms", "Sync failed");
            scheduleStartupFinish(false, 2500);
        }
    }

    function handleSyncMessage(data) {
        if (!isStartingUp || !data || !data.event)
            return;

        switch (data.event) {
        case "sync_progress":
            var progress = (data.payload || 0) / 100.0;
            if (startupSyncQueue.length > 1) {
                var overallProgress = (startupSyncQueueIndex + Math.max(0.0, Math.min(1.0, progress))) / startupSyncQueue.length;
                syncProgress = Math.max(0.0, Math.min(1.0, overallProgress));
            } else {
                syncProgress = Math.max(0.0, Math.min(1.0, progress));
            }
            break;
        case "sync_completed":
            var isSuccess = (data.payload === true);
            onCurrentAccountSyncCompleted(isSuccess);
            break;
        case "sync_error":
            onCurrentAccountSyncCompleted(false);
            break;
        }
    }

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

    property int pushRetryCount: 0

    Timer {
        id: pushRetryTimer
        interval: 2500
        repeat: false
        onTriggered: {
            if (startupManager.pushRetryCount < 3) {
                startupManager.pushRetryCount++;
                Logger.info("StartupManager", "Retrying push token retrieval (attempt " + startupManager.pushRetryCount + ")...");
                var bridge = (typeof mainView !== "undefined" && mainView.backend_bridge) ? mainView.backend_bridge : null;
                startupManager.initializePushNotifications(bridge);
            }
        }
    }

    function initializePushNotifications(backendBridge) {
        if (!backendBridge || !backendBridge.ready)
            return;

        connectToBridge(backendBridge);

        try {
            var token = (notificationSystem && typeof notificationSystem.get_push_token === "function") ? notificationSystem.get_push_token() : "";
            if (token && token.length > 0) {
                Logger.info("StartupManager", "Push token obtained, registering with backend: " + token.substring(0, 8) + "...");
                backendBridge.call("backend.save_push_token_background", [token], function (res) {
                    Logger.info("StartupManager", "Push token background registration initiated: " + res);
                });
            } else {
                Logger.debug("StartupManager", "No immediate push token returned, registering with saved settings fallback");
                backendBridge.call("backend.save_push_token_background", [""], function (res) {
                    Logger.info("StartupManager", "Push registration fallback initiated: " + res);
                });
                if (pushRetryCount < 3) {
                    pushRetryTimer.start();
                }
            }
        } catch (e) {
            Logger.warn("StartupManager", "Could not initialize push notifications:", e);
        }
    }

    function triggerAutoSync(backendBridge, onSyncConfiguredCallback) {
        if (!backendBridge)
            return;

        connectToBridge(backendBridge);

        try {
            var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
            var autoSyncEnabled = "true";
            var syncIntervalMinutes = 15;
            var accountsToSync = [];

            db.transaction(function (tx) {
                tx.executeSql("CREATE TABLE IF NOT EXISTS app_settings (key TEXT PRIMARY KEY, value TEXT)");
                var res = tx.executeSql("SELECT value FROM app_settings WHERE key = ?", ["autosync_enabled"]);
                if (res.rows.length > 0) {
                    autoSyncEnabled = res.rows.item(0).value;
                }
                var intRes = tx.executeSql("SELECT value FROM app_settings WHERE key = ?", ["sync_interval_minutes"]);
                if (intRes.rows.length > 0 && parseInt(intRes.rows.item(0).value) > 0) {
                    syncIntervalMinutes = parseInt(intRes.rows.item(0).value);
                }

                if (autoSyncEnabled !== "false") {
                    var accListRes = tx.executeSql("SELECT id, name, is_default, autosync_enabled FROM users WHERE id > 0 ORDER BY is_default DESC, id ASC");
                    for (var i = 0; i < accListRes.rows.length; i++) {
                        var item = accListRes.rows.item(i);
                        var isExplicitlyDisabled = (item.autosync_enabled === 0 || item.autosync_enabled === "0" || item.autosync_enabled === "false" || item.autosync_enabled === false);
                        if (!isExplicitlyDisabled) {
                            accountsToSync.push({
                                id: item.id,
                                name: item.name || ("Account " + item.id),
                                isDefault: item.is_default === 1
                            });
                        }
                    }
                }
            });

            if (autoSyncEnabled === "false" || accountsToSync.length === 0) {
                Logger.debug("StartupManager", "AutoSync disabled or no eligible accounts found");
                if (typeof onSyncConfiguredCallback === "function") {
                    onSyncConfiguredCallback(false, 0, -1);
                }
                if (isStartingUp) {
                    isStartupComplete = true;
                    syncFailed = false;
                    statusMessage = i18n.dtr("ubtms", "Ready");
                    scheduleStartupFinish(true, 2000);
                }
                return;
            }

            var primaryAccountId = accountsToSync[0].id;
            Logger.info("StartupManager", "Configuring AutoSync for " + accountsToSync.length + " accounts (primary ID=" + primaryAccountId + ", interval=" + syncIntervalMinutes + "m)");
            if (typeof onSyncConfiguredCallback === "function") {
                onSyncConfiguredCallback(true, syncIntervalMinutes, primaryAccountId);
            }

            startupSyncQueue = accountsToSync;
            startupSyncQueueIndex = 0;
            startupSyncSuccessCount = 0;
            startupSyncFailCount = 0;

            if (isStartingUp) {
                syncNextAccountInQueue();
            }
        } catch (e) {
            Logger.warn("StartupManager", "Failed to initialize startup sync queue:", e);
            if (isStartingUp) {
                syncFailed = true;
                statusMessage = i18n.dtr("ubtms", "Sync failed");
                scheduleStartupFinish(false, 2500);
            }
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