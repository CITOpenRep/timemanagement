import QtQuick 2.6
import Lomiri.Components 1.3
import Pparent.Notifications 1.0

Item {
    id: systemIntegrationManager
    
    // External References
    property var rootApp
    property var apLayout
    
    // Internal States
    property var pendingNavigation: null
    property alias notificationSystem: notificationSystem

    // Handle incoming URIs
    Connections {
        target: UriHandler
        onOpened: function(uris) {
            if (!uris || uris.length === 0) {
                return;
            }

            for (var i = 0; i < uris.length; i++) {
                handleDeepLink(uris[i]);
            }
        }
    }

    function normalizeDeepLink(rawUri) {
        var uri = String(rawUri || "");
        if (uri.indexOf("ubtms://") === 0) {
            return uri;
        }

        var deepLinkIndex = uri.indexOf("ubtms://");
        if (deepLinkIndex >= 0) {
            return uri.substring(deepLinkIndex);
        }

        return "";
    }
    
    function handleDeepLink(uri) {
        try {
            var deepLink = normalizeDeepLink(uri);
            if (!deepLink) {
                return;
            }

            console.log("System deep link received:", deepLink);

            var queryStart = deepLink.indexOf("?");
            if (queryStart === -1) return;
            var queryString = deepLink.substring(queryStart + 1);
            var params = {};
            var pairs = queryString.split("&");
            for (var i = 0; i < pairs.length; i++) {
                var pair = pairs[i].split("=");
                if (pair.length === 2) params[decodeURIComponent(pair[0])] = decodeURIComponent(pair[1]);
            }
            
            var navType = params["type"] || "";
            var recordId = parseInt(params["id"]) || -1;
            var accountId = parseInt(params["account_id"]) || 0;
            var isOdooId = (params["odoo_id"] === "1");
            
            if (!navType || recordId <= 0) return;
            
            if (rootApp && rootApp.init) {
                pendingNavigation = {type: navType, id: recordId, accountId: accountId, isOdooId: isOdooId};
                return;
            }
            navigateToRecord(navType, recordId, accountId, isOdooId);
        } catch (e) {
            console.warn("Failed to handle deep link:", uri, e);
        }
    }
    
    function navigateToRecord(navType, recordId, accountId, isOdooId) {
        if (!apLayout || !apLayout.primaryPage) return;
        
        var options = { "recordid": recordId, "isOdooRecordId": isOdooId || false, "isReadOnly": true };
        if (navType === "Task" && recordId > 0) {
            apLayout.addPageToNextColumn(apLayout.primaryPage, Qt.resolvedUrl("../Tasks.qml"), options);
        } else if (navType === "Activity" && recordId > 0) {
            options["accountid"] = accountId;
            apLayout.addPageToNextColumn(apLayout.primaryPage, Qt.resolvedUrl("../Activities.qml"), options);
        } else if (navType === "ProjectUpdate" && recordId > 0) {
            options["accountid"] = accountId;
            apLayout.addPageToNextColumn(apLayout.primaryPage, Qt.resolvedUrl("../Updates.qml"), options);
        } else if (navType === "Project" && recordId > 0) {
            apLayout.addPageToNextColumn(apLayout.primaryPage, Qt.resolvedUrl("../Projects.qml"), options);
        } else if (navType === "Timesheet" && recordId > 0) {
            apLayout.addPageToNextColumn(apLayout.primaryPage, Qt.resolvedUrl("../Timesheet.qml"), options);
        }
    }

    NotificationHelper {
        id: notificationSystem
        push_app_id: "ubtms_ubtms"
        Component.onCompleted: {
            startDaemon()
        }
    }
    
    Timer {
        id: daemonHealthCheckTimer
        interval: 120000 
        running: true
        repeat: true
        onTriggered: notificationSystem.ensureDaemonRunning()
    }
    
    Timer {
        id: delayedNavigationTimer
        interval: 500
        repeat: false
        onTriggered: {
            if (pendingNavigation) {
                navigateToRecord(pendingNavigation.type, pendingNavigation.id, pendingNavigation.accountId, pendingNavigation.isOdooId);
                pendingNavigation = null;
            }
        }
    }

    function startDelayedNavigation() {
        if (pendingNavigation) {
            delayedNavigationTimer.start();
        }
    }

    function showSystemNotification(title, message) {
        notificationSystem.showNotificationMessage(title, message);
    }
}
