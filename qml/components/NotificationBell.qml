import QtQuick 2.7
import QtQuick.Controls 2.2 as Controls
import QtQuick.Layouts 1.3
import Lomiri.Components 1.3
import "../../models/constants.js" as AppConst
import "../../models/notifications.js" as Notifications
import Pparent.Notifications 1.0

Item {
    id: bellWidget
    width: units.gu(3)
    height: units.gu(3)

    property int notificationCount: 0
    property var notificationList: []
    property Item parentWindow
    
    // Signal emitted when navigation is requested
    signal navigateToRecord(string navType, int recordId, int accountId)

    // NotificationHelper for updating system badge
    NotificationHelper {
        id: badgeHelper
        push_app_id: "ubtms_ubtms"
    }

    function loadNotifications() {
        var rawList = Notifications.getUnreadNotifications();
        
        // Debug: Log the raw data from database
        console.log("[NotificationBell] Raw notifications count: " + rawList.length);
        
        // Debug: Log unique IDs to check for database duplicates
        var ids = [];
        for (var i = 0; i < rawList.length; i++) {
            ids.push(rawList[i].id);
        }
        console.log("[NotificationBell] Notification IDs: " + JSON.stringify(ids));
        
        // Deduplicate by message content (keep only the most recent - highest ID)
        // This handles cases where the daemon creates duplicate entries
        var messageMap = {};
        for (var j = 0; j < rawList.length; j++) {
            var notif = rawList[j];
            var key = notif.type + "|" + notif.message;  // Unique key: type + message
            
            if (!messageMap[key] || notif.id > messageMap[key].id) {
                messageMap[key] = notif;  // Keep the newest (highest ID)
            }
        }
        
        // Convert map back to array
        var dedupedList = [];
        for (var msgKey in messageMap) {
            if (messageMap.hasOwnProperty(msgKey)) {
                dedupedList.push(messageMap[msgKey]);
            }
        }
        
        // Sort by ID descending (newest first)
        dedupedList.sort(function(a, b) { return b.id - a.id; });
        
        // Log deduplication results and clean up duplicates from database
        if (dedupedList.length !== rawList.length) {
            console.log("[NotificationBell] Deduplicated: " + rawList.length + " -> " + dedupedList.length + " notifications");
            
            // Delete duplicate entries from database (keep only the ones in dedupedList)
            var keepIds = {};
            for (var k = 0; k < dedupedList.length; k++) {
                keepIds[dedupedList[k].id] = true;
            }
            for (var m = 0; m < rawList.length; m++) {
                if (!keepIds[rawList[m].id]) {
                    console.log("[NotificationBell] Deleting duplicate notification ID: " + rawList[m].id);
                    Notifications.deleteNotification(rawList[m].id);
                }
            }
        }
        
        notificationList = dedupedList;
        notificationCount = notificationList.length;
        badgeHelper.updateCount(notificationCount);
        
        console.log("[NotificationBell] Final notificationList.length: " + notificationList.length);
    }
    
    function openPopup() {
        loadNotifications();
        notificationPopup.open();
    }
    
    // Helper function to format timestamp
    function formatTimestamp(timestamp) {
        if (!timestamp) return "";
        
        var date = new Date(timestamp);
        var now = new Date();
        var diffMs = now - date;
        var diffMins = Math.floor(diffMs / 60000);
        var diffHours = Math.floor(diffMs / 3600000);
        var diffDays = Math.floor(diffMs / 86400000);
        
        if (diffMins < 1) return i18n.dtr("ubtms", "Just now");
        if (diffMins < 60) return diffMins + i18n.dtr("ubtms", "m ago");
        if (diffHours < 24) return diffHours + i18n.dtr("ubtms", "h ago");
        if (diffDays < 7) return diffDays + i18n.dtr("ubtms", "d ago");
        
        return date.toLocaleDateString();
    }
    
    // Handle notification click
    function handleNotificationClick(modelData) {
        var payload = {};
        try {
            if (modelData.payload) {
                payload = typeof modelData.payload === 'string' 
                    ? JSON.parse(modelData.payload) 
                    : modelData.payload;
            }
        } catch (e) {
            console.error("Failed to parse notification payload:", e);
        }
        
        var recordId = payload.id || -1;
        var accountId = modelData.account_id || 0;
        var notifType = modelData.type || "";
        
        // Close popup before navigation
        notificationPopup.close();
        
        // Emit navigation signal
        if (recordId > 0) {
            navigateToRecord(notifType, recordId, accountId);
        }
        
        // Mark as read
        Notifications.deleteNotification(modelData.id);
        loadNotifications();
    }
    
    // Periodic refresh timer
    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: loadNotifications()
    }

    // Notification Popup Dialog
    Controls.Popup {
        id: notificationPopup
        modal: true
        focus: true
        width: parentWindow ? Math.min(parentWindow.width - units.gu(4), units.gu(50)) : units.gu(40)
        height: parentWindow ? Math.min(parentWindow.height * 0.7, units.gu(70)) : units.gu(60)
        x: parentWindow ? (parentWindow.width - width) / 2 : 0
        y: units.gu(8)
        
        background: Rectangle {
            color: theme.palette.normal.background
            radius: units.gu(1.5)
            border.color: theme.palette.normal.base
            border.width: 1
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: units.gu(1.5)
            spacing: units.gu(1)
            
            // Header
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: units.gu(5)
                spacing: units.gu(1)
                
                Label {
                    text: i18n.dtr("ubtms", "Notifications")
                    font.bold: true
                    font.pixelSize: units.gu(2.2)
                    color: theme.palette.normal.backgroundText
                    Layout.fillWidth: true
                }
                
                // Unread badge
                Rectangle {
                    visible: notificationCount > 0
                    Layout.preferredWidth: units.gu(3)
                    Layout.preferredHeight: units.gu(2.5)
                    radius: units.gu(1)
                    color: "#E53935"
                    
                    Label {
                        anchors.centerIn: parent
                        text: notificationCount
                        color: "white"
                        font.pixelSize: units.gu(1.3)
                        font.bold: true
                    }
                }
                
                // Close button
                AbstractButton {
                    Layout.preferredWidth: units.gu(4)
                    Layout.preferredHeight: units.gu(4)
                    
                    Rectangle {
                        anchors.fill: parent
                        radius: units.gu(2)
                        color: parent.pressed ? theme.palette.normal.base : "transparent"
                    }
                    
                    Label {
                        anchors.centerIn: parent
                        text: "✕"
                        font.pixelSize: units.gu(2)
                        color: theme.palette.normal.backgroundSecondaryText
                    }
                    
                    onClicked: notificationPopup.close()
                }
            }
            
            // Separator
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: theme.palette.normal.base
            }
            
            // Empty state
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: notificationCount === 0
                
                Column {
                    anchors.centerIn: parent
                    spacing: units.gu(2)
                    
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "🔔"
                        font.pixelSize: units.gu(6)
                        opacity: 0.5
                    }
                    
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: i18n.dtr("ubtms", "No notifications")
                        font.pixelSize: units.gu(2)
                        color: theme.palette.normal.backgroundSecondaryText
                    }
                    
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: i18n.dtr("ubtms", "You're all caught up!")
                        font.pixelSize: units.gu(1.5)
                        color: theme.palette.normal.backgroundTertiaryText
                    }
                }
            }

            // Notification list
            ListView {
                id: notificationListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: notificationCount > 0
                model: notificationList
                clip: true
                spacing: units.gu(0.5)
                
                // Debug: Log when model count changes
                onCountChanged: {
                    console.log("[NotificationBell] ListView count changed to: " + count + " (model length: " + (notificationList ? notificationList.length : 0) + ")");
                }

                delegate: ListItem {
                    id: delegateItem
                    width: notificationListView.width
                    height: units.gu(8)
                    
                    // Disable ListItem's default visual elements to prevent double rendering
                    divider.visible: false
                    color: "transparent"  // Make ListItem background transparent
                    highlightColor: "transparent"
                    
                    // Debug: Log when each delegate is created
                    Component.onCompleted: {
                        console.log("[NotificationBell] Delegate created for notification ID: " + (modelData ? modelData.id : "unknown") + " at index: " + index);
                    }
                    
                    // Standard Ubuntu Touch leading actions (swipe right to reveal)
                    leadingActions: ListItemActions {
                        actions: [
                            Action {
                                iconName: "delete"
                                text: i18n.dtr("ubtms", "Delete")
                                onTriggered: {
                                    console.log("[NotificationBell] Swipe delete triggered for ID: " + modelData.id);
                                    Notifications.deleteNotification(modelData.id);
                                    loadNotifications();
                                }
                            }
                        ]
                    }
                    
                    onClicked: handleNotificationClick(modelData)
                    
                    Rectangle {
                        id: notificationCard
                        anchors.fill: parent
                        anchors.margins: units.gu(0.5)
                        radius: units.gu(1)
                        color: delegateItem.pressed ? theme.palette.normal.base : theme.palette.normal.background
                        border.color: theme.palette.normal.base
                        border.width: 1
                        
                        Behavior on color {
                            ColorAnimation { duration: 100 }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: units.gu(1)
                            spacing: units.gu(1)
                            
                            // Assigner avatar or type-specific icon badge
                            Rectangle {
                                id: avatarContainer
                                Layout.preferredWidth: units.gu(5)
                                Layout.preferredHeight: units.gu(5)
                                
                                // Parse payload once for this delegate
                                property var parsedPayload: {
                                    try {
                                        if (modelData.payload) {
                                            return typeof modelData.payload === 'string' 
                                                ? JSON.parse(modelData.payload) 
                                                : modelData.payload;
                                        }
                                    } catch (e) {}
                                    return {};
                                }
                                
                                property bool hasAvatar: parsedPayload.assigner_avatar ? true : false
                                property bool hasAssignerName: parsedPayload.assigner_name ? true : false
                                property string assignerName: parsedPayload.assigner_name || ""
                                
                                // Get initials from name (e.g., "John Doe" -> "JD")
                                property string initials: {
                                    if (!assignerName) return "";
                                    var parts = assignerName.trim().split(/\s+/);
                                    if (parts.length >= 2) {
                                        return (parts[0].charAt(0) + parts[parts.length - 1].charAt(0)).toUpperCase();
                                    }
                                    return parts[0].substring(0, 2).toUpperCase();
                                }
                                
                                radius: (hasAvatar || hasAssignerName) ? units.gu(2.5) : units.gu(1)
                                color: {
                                    if (hasAvatar) return "transparent";
                                    
                                    // Use type color for background
                                    var notifType = modelData.type || "";
                                    switch(notifType) {
                                        case "Task": return "#4CAF50";
                                        case "Activity": return "#2196F3";
                                        case "Project": return "#FF9800";
                                        case "Timesheet": return "#9C27B0";
                                        default: return "#757575";
                                    }
                                }
                                clip: true
                                
                                // Assigner avatar image
                                Image {
                                    id: assignerAvatar
                                    anchors.fill: parent
                                    visible: avatarContainer.hasAvatar
                                    source: avatarContainer.hasAvatar 
                                        ? "data:image/png;base64," + avatarContainer.parsedPayload.assigner_avatar 
                                        : ""
                                    fillMode: Image.PreserveAspectCrop
                                }
                                
                                // Initials fallback (shown when name but no avatar)
                                Label {
                                    anchors.centerIn: parent
                                    visible: !avatarContainer.hasAvatar && avatarContainer.hasAssignerName
                                    text: avatarContainer.initials
                                    font.pixelSize: units.gu(1.8)
                                    font.bold: true
                                    color: "white"
                                }
                                
                                // Fallback type icon (shown when no avatar and no name)
                                Image {
                                    anchors.centerIn: parent
                                    width: units.gu(3)
                                    height: units.gu(3)
                                    visible: !avatarContainer.hasAvatar && !avatarContainer.hasAssignerName
                                    source: {
                                        var notifType = modelData.type || "";
                                        switch(notifType) {
                                            case "Task": return "../images/task.svg";
                                            case "Activity": return "../images/activity.svg";
                                            case "Project": return "../images/project.svg";
                                            case "Timesheet": return "../images/timesheet.svg";
                                            default: return "../images/notification.png";
                                        }
                                    }
                                    fillMode: Image.PreserveAspectFit
                                }
                                
                                // Small type indicator badge (shown when avatar or initials present)
                                Rectangle {
                                    visible: avatarContainer.hasAvatar || avatarContainer.hasAssignerName
                                    width: units.gu(2)
                                    height: units.gu(2)
                                    radius: units.gu(1)
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.rightMargin: -units.gu(0.3)
                                    anchors.bottomMargin: -units.gu(0.3)
                                    color: {
                                        var notifType = modelData.type || "";
                                        switch(notifType) {
                                            case "Task": return "#4CAF50";
                                            case "Activity": return "#2196F3";
                                            case "Project": return "#FF9800";
                                            case "Timesheet": return "#9C27B0";
                                            default: return "#757575";
                                        }
                                    }
                                    border.color: theme.palette.normal.background
                                    border.width: 1
                                    
                                    Image {
                                        anchors.centerIn: parent
                                        width: units.gu(1.2)
                                        height: units.gu(1.2)
                                        source: {
                                            var notifType = modelData.type || "";
                                            switch(notifType) {
                                                case "Task": return "../images/task.svg";
                                                case "Activity": return "../images/activity.svg";
                                                case "Project": return "../images/project.svg";
                                                case "Timesheet": return "../images/timesheet.svg";
                                                default: return "../images/notification.png";
                                            }
                                        }
                                        fillMode: Image.PreserveAspectFit
                                    }
                                }
                            }

                            // Content column
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: units.gu(0.3)
                                
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: units.gu(1)
                                    
                                    Label {
                                        text: {
                                            var notifType = modelData.type || "";
                                            switch(notifType) {
                                                case "Task": return i18n.dtr("ubtms", "Task");
                                                case "Activity": return i18n.dtr("ubtms", "Activity");
                                                case "Project": return i18n.dtr("ubtms", "Project");
                                                case "Timesheet": return i18n.dtr("ubtms", "Timesheet");
                                                default: return i18n.dtr("ubtms", "Update");
                                            }
                                        }
                                        font.pixelSize: units.gu(1.3)
                                        font.bold: true
                                        color: {
                                            var notifType = modelData.type || "";
                                            switch(notifType) {
                                                case "Task": return "#4CAF50";
                                                case "Activity": return "#2196F3";
                                                case "Project": return "#FF9800";
                                                case "Timesheet": return "#9C27B0";
                                                default: return theme.palette.normal.backgroundSecondaryText;
                                            }
                                        }
                                    }
                                    
                                    Item { Layout.fillWidth: true }
                                    
                                    Label {
                                        text: formatTimestamp(modelData.timestamp)
                                        font.pixelSize: units.gu(1.2)
                                        color: theme.palette.normal.backgroundTertiaryText
                                    }
                                }
                                
                                Label {
                                    Layout.fillWidth: true
                                    text: modelData.message || ""
                                    font.pixelSize: units.gu(1.5)
                                    color: theme.palette.normal.backgroundText
                                    elide: Text.ElideRight
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 2
                                }
                            }
                            
                            Label {
                                text: "›"
                                font.pixelSize: units.gu(2.5)
                                color: theme.palette.normal.backgroundSecondaryText
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                    }
                }
            }
            
            // Footer button
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: units.gu(5)
                spacing: units.gu(2)
                visible: notificationCount > 0
                
                AbstractButton {
                    Layout.fillWidth: true
                    Layout.preferredHeight: units.gu(4)
                    
                    Rectangle {
                        anchors.fill: parent
                        radius: units.gu(1)
                        color: parent.pressed ? theme.palette.normal.base : "transparent"
                        border.color: theme.palette.normal.base
                        border.width: 1
                        
                        Label {
                            anchors.centerIn: parent
                            text: i18n.dtr("ubtms", "Clear All")
                            color: theme.palette.normal.backgroundText
                        }
                    }
                    
                    onClicked: {
                        console.log("[NotificationBell] Clear All clicked - deleting all notifications");
                        Notifications.deleteAllNotifications();
                        loadNotifications();
                        notificationPopup.close();
                    }
                }
            }
        }
    }
    
    Component.onCompleted: {
        loadNotifications();
    }
}
