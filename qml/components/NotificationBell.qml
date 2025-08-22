import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.0
import "../../models/constants.js" as AppConst
import "../../models/notifications.js" as Notifications

Item {
    id: bellWidget
    anchors {
        top: parent.top
        horizontalCenter: parent.horizontalCenter
        topMargin: units.gu(0.5)
    }
    width: units.gu(3.5)
    height: units.gu(3.5)
    z: 999

    property int notificationCount: 0
    signal clicked
    property Item parentWindow
    property var notificationList: []
    property bool isHovered: false

    // Bell icon with hover effects
    Rectangle {
        id: bellBackground
        width: units.gu(3.5)
        height: units.gu(3.5)
        radius: width / 2
        color: isHovered ? "#f0f0f0" : "transparent"
        border.color: isHovered ? "#e0e0e0" : "transparent"
        border.width: 1
        
        Behavior on color {
            ColorAnimation { duration: 200 }
        }
        
        Behavior on border.color {
            ColorAnimation { duration: 200 }
        }
    }

    Image {
        id: bellIcon
        source: "../images/notification.png"
        width: units.gu(2.5)
        height: units.gu(2.5)
        fillMode: Image.PreserveAspectFit
        anchors.centerIn: parent
        opacity: isHovered ? 0.8 : 1.0
        
        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }
        
        // Subtle shake animation when new notifications arrive
        SequentialAnimation {
            id: shakeAnimation
            loops: 3
            NumberAnimation {
                target: bellIcon
                property: "rotation"
                from: 0; to: -15
                duration: 100
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: bellIcon
                property: "rotation"
                from: -15; to: 15
                duration: 100
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: bellIcon
                property: "rotation"
                from: 15; to: 0
                duration: 100
                easing.type: Easing.InQuad
            }
        }
    }

    // Enhanced notification badge
    Rectangle {
        id: notificationBadge
        visible: notificationCount > 0
        width: units.gu(2.2)
        height: units.gu(2.2)
        radius: width / 2
        color: "#ff4757"
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: -units.gu(0.3)
        border.color: "white"
        border.width: 2
        
        // Pulsing animation for new notifications
        SequentialAnimation {
            id: pulseAnimation
            running: notificationCount > 0
            loops: Animation.Infinite
            NumberAnimation {
                target: notificationBadge
                property: "scale"
                from: 1.0; to: 1.1
                duration: 1000
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: notificationBadge
                property: "scale"
                from: 1.1; to: 1.0
                duration: 1000
                easing.type: Easing.InOutQuad
            }
        }

        Text {
            anchors.centerIn: parent
            text: notificationCount > 99 ? "99+" : notificationCount
            color: "white"
            font.pixelSize: units.gu(1.0)
            font.bold: true
            font.family: "Roboto"
        }
        
        // Glow effect
        DropShadow {
            anchors.fill: parent
            horizontalOffset: 0
            verticalOffset: 0
            radius: 8.0
            samples: 17
            color: "#80ff4757"
            source: parent
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            bellWidget.clicked()
            if (notificationCount === 0) {
                return
            }
            loadNotifications()
            notificationPopup.open()
        }
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
        onEntered: {
            isHovered = true
        }
        
        onExited: {
            isHovered = false
        }
    }

    function loadNotifications() {
        notificationList = Notifications.getUnreadNotifications()
        var previousCount = notificationCount
        notificationCount = notificationList.length
        
        // Trigger shake animation for new notifications
        if (notificationCount > previousCount) {
            shakeAnimation.start()
        }
        
        console.log("NotificationBell: Loaded", notificationCount, "unread notifications")
        notificationModel.clear()
        for (var i = 0; i < notificationList.length; i++) {
            notificationModel.append(notificationList[i])
        }
    }

    ListModel {
        id: notificationModel
    }

    // Enhanced popup with better positioning and styling
    Popup {
        id: notificationPopup
        modal: true
        focus: true
        width: Math.min(parentWindow ? parentWindow.width * 0.9 : units.gu(40), units.gu(45))
        height: Math.min(parentWindow ? parentWindow.height * 0.7 : units.gu(60), units.gu(50))
        
        // Better positioning logic
        property real targetX: {
            var bellGlobalPos = bellWidget.mapToItem(null, 0, 0)
            var popupX = bellGlobalPos.x + bellWidget.width - width
            
            // Ensure popup stays within screen bounds
            if (parentWindow) {
                popupX = Math.max(units.gu(1), Math.min(popupX, parentWindow.width - width - units.gu(1)))
            }
            return popupX
        }
        
        property real targetY: {
            var bellGlobalPos = bellWidget.mapToItem(null, 0, 0)
            return bellGlobalPos.y + bellWidget.height + units.gu(1)
        }
        
        x: targetX - height / 2.35  // Slight offset for better alignment
        y: targetY  - height / 2.5 // Center vertically relative to bell
        // Smooth opening animation
        enter: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: 300
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "scale"
                from: 0.8
                to: 1.0
                duration: 300
                easing.type: Easing.OutCubic
            }
        }
        
        exit: Transition {
            NumberAnimation {
                property: "opacity"
                from: 1.0
                to: 0.0
                duration: 200
                easing.type: Easing.InCubic
            }
        }

        background: Rectangle {
            color: "white"
            radius: units.gu(1.5)
            border.color: "#e0e0e0"
            border.width: 1
            
            // Drop shadow effect
            DropShadow {
                anchors.fill: parent
                horizontalOffset: 0
                verticalOffset: 4
                radius: 12.0
                samples: 25
                color: "#40000000"
                source: parent
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: units.gu(1.5)
            spacing: units.gu(1)

            // Header
            Rectangle {
                id : header
                Layout.fillWidth: true
                Layout.preferredHeight: units.gu(4)
                color: "#f8f9fa"
                radius: units.gu(0.5)
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: units.gu(1)
                    
                    Text {
                        text: "Notifications"
                        font.pixelSize: units.gu(1.8)
                        font.bold: true
                        color: "#2c3e50"
                        Layout.fillWidth: true
                    }
                    
                    Text {
                        text: notificationCount + " unread"
                        font.pixelSize: units.gu(1.2)
                        color: "#7f8c8d"
                    }
                }
            }

            // Notification list
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                anchors.top : header.bottom - units.gu(0.5)
                clip: true
                
                ListView {
                    id: notificationListView
                    model: notificationModel
                    spacing: units.gu(0.5)
                    
                    delegate: Rectangle {
                        width: notificationListView.width
                        height: units.gu(7)
                        color: notificationMouseArea.containsMouse ? "#f1f2f6" : "transparent"
                        radius: units.gu(0.8)
                        border.color: "#e0e0e0"
                        border.width: 1
                        
                        Behavior on color {
                            ColorAnimation { duration: 200 }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: units.gu(1)
                            spacing: units.gu(1)
                            
                            // Notification icon
                            Rectangle {
                                Layout.preferredWidth: units.gu(4)
                                Layout.preferredHeight: units.gu(4)
                                radius: width / 2
                                color: "#3498db"
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "!"
                                    color: "white"
                                    font.pixelSize: units.gu(1.8)
                                    font.bold: true
                                }
                            }
                            
                            // Notification content
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: units.gu(0.2)
                                
                                Text {
                                    Layout.fillWidth: true
                                    text: model.message || "New notification"
                                    font.pixelSize: units.gu(1.4)
                                    color: "#2c3e50"
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                }
                                
                                Text {
                                    text: model.timestamp || "Just now"
                                    font.pixelSize: units.gu(1.0)
                                    color: "#95a5a6"
                                }
                            }
                            
                            // Delete button
                            Rectangle {
                                Layout.preferredWidth: units.gu(3)
                                Layout.preferredHeight: units.gu(3)
                                radius: width / 2
                                color: deleteMouseArea.containsMouse ? "#e74c3c" : "#ecf0f1"
                                
                                Behavior on color {
                                    ColorAnimation { duration: 200 }
                                }
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "×"
                                    font.pixelSize: units.gu(1.5)
                                    color: deleteMouseArea.containsMouse ? "white" : "#7f8c8d"
                                    font.bold: true
                                }
                                
                                MouseArea {
                                    id: deleteMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    
                                    onClicked: {
                                        Notifications.deleteNotification(model.id)
                                        notificationModel.remove(index)
                                        notificationCount = notificationModel.count
                                        if (notificationCount === 0) {
                                            notificationPopup.close()
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: notificationMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            
                            onClicked: {
                                // Handle notification click (e.g., navigate to relevant screen)
                                console.log("Notification clicked:", model.message)
                            }
                        }
                    }
                }
            }

            // Action buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: units.gu(1)
                
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: units.gu(4)
                    color: clearAllMouseArea.containsMouse ? "#e74c3c" : "#ecf0f1"
                    radius: units.gu(0.5)
                    border.color: "#bdc3c7"
                    border.width: 1
                    
                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }
                    
                    Text {
                        anchors.centerIn: parent
                        text: "Clear All"
                        font.pixelSize: units.gu(1.3)
                        color: clearAllMouseArea.containsMouse ? "white" : "#7f8c8d"
                        font.bold: true
                    }
                    
                    MouseArea {
                        id: clearAllMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        
                        onClicked: {
                            for (var i = 0; i < notificationModel.count; i++) {
                                Notifications.deleteNotification(notificationModel.get(i).id)
                            }
                            notificationModel.clear()
                            notificationCount = 0
                            notificationPopup.close()
                        }
                    }
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: units.gu(4)
                    color: closeMouseArea.containsMouse ? "#3498db" : "#ecf0f1"
                    radius: units.gu(0.5)
                    border.color: "#bdc3c7"
                    border.width: 1
                    
                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }
                    
                    Text {
                        anchors.centerIn: parent
                        text: "Close"
                        font.pixelSize: units.gu(1.3)
                        color: closeMouseArea.containsMouse ? "white" : "#7f8c8d"
                        font.bold: true
                    }
                    
                    MouseArea {
                        id: closeMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        
                        onClicked: notificationPopup.close()
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        loadNotifications()
    }
}