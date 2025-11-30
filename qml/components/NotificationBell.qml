import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import "../../models/constants.js" as AppConst
import "../../models/notifications.js" as Notifications
import Pparent.Notifications 1.0

Item {
    id: bellWidget
    anchors {
        top: parent.top
        horizontalCenter: parent.horizontalCenter
        topMargin: units.gu(0.5)
    }
    width: units.gu(3)
    height: units.gu(3)
    z: 999

    property int notificationCount: 0
    signal clicked
    property Item parentWindow

    property var notificationList: []

    // NotificationHelper for updating badge
    NotificationHelper {
        id: badgeHelper
        push_app_id: "ubtms_ubtms"
    }

    Image {
        source: "../images/notification.png"
        width: units.gu(3)
        height: units.gu(3)
        fillMode: Image.PreserveAspectFit
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Rectangle {
        visible: notificationCount > 0
        width: units.gu(2)
        height: units.gu(2)
        radius: width / 2
        color: "red"
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: -units.gu(0.5)
        border.color: "white"
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: notificationCount > 9 ? "9+" : notificationCount
            color: "white"
            font.pixelSize: units.gu(1.2)
            font.bold: true
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (notificationCount === 0) {
                return;
            }

            loadNotifications();
            notificationPopup.open();
        }
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
    }

    function loadNotifications() {
        notificationList = Notifications.getUnreadNotifications();
        notificationCount = notificationList.length;
        notificationModel.clear();
        for (var i = 0; i < notificationList.length; i++) {
            notificationModel.append(notificationList[i]);
        }
        // Update system badge to match current unread count
        badgeHelper.updateCount(notificationCount);
    }

    ListModel {
        id: notificationModel
    }

    Popup {
        id: notificationPopup
        modal: true
        focus: true
        width: parentWindow ? parentWindow.width : units.gu(40)
        height: parentWindow ? parentWindow.height * 0.6 : units.gu(60)

        // Compute real position relative to screen
        x: bellWidget.mapToItem(null, 0, 0).x + bellWidget.width - width
        y: bellWidget.mapToItem(null, 0, 0).y + bellWidget.height + units.gu(1)
        background: Rectangle {
            color: "white"
            radius: units.gu(1)
        }

        ColumnLayout {
            anchors.fill: parent
            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: notificationModel
                delegate: Item {
                    width: parent.width
                    height: units.gu(5)

                    TSLabel {
                        anchors.fill: parent
                        text: model.message

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                Notifications.deleteNotification(model.id);
                                notificationModel.remove(index);
                                notificationCount = notificationModel.count;
                                // Update system badge after removing notification
                                badgeHelper.updateCount(notificationCount);
                                if (notificationCount === 0)
                                    notificationPopup.close();
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: units.gu(2)
                
                TSButton {
                    text: "Clear All"
                    visible: notificationModel.count > 0
                    onClicked: {
                        // Delete all displayed notifications
                        for (var i = 0; i < notificationList.length; i++) {
                            Notifications.deleteNotification(notificationList[i].id);
                        }
                        notificationModel.clear();
                        notificationCount = 0;
                        badgeHelper.updateCount(0);
                        notificationPopup.close();
                    }
                }
                
                TSButton {
                    text: "Close"
                    onClicked: notificationPopup.close()
                }
            }
        }
    }
    Component.onCompleted: {
        loadNotifications();
    }
}
