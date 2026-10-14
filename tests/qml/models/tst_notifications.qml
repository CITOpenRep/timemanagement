import QtQuick 2.7
import QtTest 1.0
import QtQuick.LocalStorage 2.7 as Sql
import "../../../models/logger.js" as Logger
import "../../../models/database.js" as DBCommon
import "../../../models/dbinit.js" as DbInit
import "../../../models/notifications.js" as NotificationsModel

Item {
    width: 200
    height: 200

    TestCase {
        name: "NotificationsModelTests"
        when: windowShown

        function initTestCase() {
            Logger.setLogLevel(Logger.LogLevel.NONE);
            DbInit.initializeDatabase();
        }

        function cleanupTestCase() {
            Logger.setLogLevel(Logger.LogLevel.WARN);
        }

        function clearTestData() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function (tx) {
                tx.executeSql("DELETE FROM notification WHERE account_id = 999 OR id >= 90000");
            });
        }

        function init() {
            clearTestData();
        }

        function cleanup() {
            clearTestData();
        }

        // --- 1. Notification Creation and Details ---

        function test_addNotification_and_getDetails() {
            var payload = { taskId: 123, priority: "high" };
            NotificationsModel.addNotification(999, "Task", "New task assigned", payload);

            var unread = NotificationsModel.getUnreadNotifications();
            verify(unread.length > 0);

            var found = null;
            for (var i = 0; i < unread.length; i++) {
                if (unread[i].account_id === 999 && unread[i].message === "New task assigned") {
                    found = unread[i];
                    break;
                }
            }
            verify(found !== null);
            compare(found.type, "Task");
            compare(found.read_status, 0);

            var details = NotificationsModel.getDetailsOfNotification(found.id);
            verify(details !== null);
            compare(details.id, found.id);
            compare(details.message, "New task assigned");

            var parsedPayload = JSON.parse(details.payload);
            compare(parsedPayload.taskId, 123);
        }

        // --- 2. Read Status and Counts ---

        function test_readStatusAndCounts() {
            NotificationsModel.addNotification(999, "Project", "Project milestone met", { projectId: 10 });
            NotificationsModel.addNotification(999, "Activity", "Meeting scheduled", { activityId: 20 });

            var unreadCountBefore = NotificationsModel.getUnreadCount();
            verify(unreadCountBefore >= 2);

            var unreadList = NotificationsModel.getUnreadNotifications();
            var targetId = unreadList[0].id;

            NotificationsModel.markAsRead(targetId);
            var details = NotificationsModel.getDetailsOfNotification(targetId);
            compare(details.read_status, 1);

            NotificationsModel.markAllAsRead();
            compare(NotificationsModel.getUnreadCount(), 0);

            // Delete all read notifications
            NotificationsModel.deleteAllRead();
            var detailsAfterDelete = NotificationsModel.getDetailsOfNotification(targetId);
            compare(detailsAfterDelete, null);
        }

        // --- 3. Sync vs Normal Notifications ---

        function test_syncVsNormalNotifications() {
            NotificationsModel.addNotification(999, "Task", "Normal task notification", { id: 1 });
            NotificationsModel.addNotification(999, "Sync", "Sync failed on network timeout", { error: "timeout" });

            verify(NotificationsModel.hasSyncNotifications());

            var normalList = NotificationsModel.getUnreadNormalNotifications();
            verify(normalList.length >= 1);
            compare(normalList[0].type !== "Sync", true);

            var syncList = NotificationsModel.getUnreadSyncNotifications();
            verify(syncList.length >= 1);
            compare(syncList[0].type, "Sync");

            var normalCount = NotificationsModel.getUnreadNormalCount();
            var syncCount = NotificationsModel.getUnreadSyncCount();
            verify(normalCount >= 1);
            verify(syncCount >= 1);

            // Clear sync notifications for account 999
            var cleared = NotificationsModel.clearSyncNotifications(999);
            verify(cleared >= 1);
            compare(NotificationsModel.getUnreadSyncCount(), 0);

            // Normal notifications should remain
            compare(NotificationsModel.getUnreadNormalCount(), normalCount);
        }

        // --- 4. Deletion ---

        function test_deleteNotification_and_deleteAll() {
            NotificationsModel.addNotification(999, "Task", "Task to delete", {});
            var unread = NotificationsModel.getUnreadNotifications();
            verify(unread.length > 0);

            var noteId = unread[0].id;
            NotificationsModel.deleteNotification(noteId);
            compare(NotificationsModel.getDetailsOfNotification(noteId), null);

            NotificationsModel.addNotification(999, "Task", "Task A", {});
            NotificationsModel.addNotification(999, "Task", "Task B", {});
            NotificationsModel.deleteAllNotifications();
            compare(NotificationsModel.getUnreadCount(), 0);
        }
    }
}
