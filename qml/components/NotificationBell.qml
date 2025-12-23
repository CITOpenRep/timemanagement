import QtQuick 2.7
import QtQuick.Layouts 1.3
import Lomiri.Components 1.3
import "../../models/constants.js" as AppConst
import "../../models/notifications.js" as Notifications
import Pparent.Notifications 1.0

// NotificationBell: Data component for managing notifications
// Note: The visual popup is defined in Dashboard.qml (notificationPopupDialog)
// This component provides: loadNotifications(), notificationList, notificationCount

Item {
    id: bellWidget
    width: units.gu(3)
    height: units.gu(3)

    property int notificationCount: 0
    property var notificationList: []
    property Item parentWindow

    // NotificationHelper for updating system badge
    NotificationHelper {
        id: badgeHelper
        push_app_id: "ubtms_ubtms"
    }

    function loadNotifications() {
        notificationList = Notifications.getUnreadNotifications();
        notificationCount = notificationList.length;
        // Update system badge to match current unread count
        badgeHelper.updateCount(notificationCount);
    }
    
    // Periodic refresh timer to check for new notifications while app is open
    Timer {
        id: notificationRefreshTimer
        interval: 30000  // Check every 30 seconds
        running: true
        repeat: true
        onTriggered: {
            var oldCount = notificationCount;
            loadNotifications();
            if (notificationCount > oldCount) {
                console.log("New notifications arrived:", notificationCount - oldCount);
            }
        }
    }
    
    Component.onCompleted: {
        loadNotifications();
    }
}
