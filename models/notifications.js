.import "database.js" as DBCommon
    .import QtQuick.LocalStorage 2.7 as Sql

const TABLE_NAME = "notification";

/**
 * Adds a new notification to the database.
 *
 * @param {int} accountId
 * @param {string} type - One of: 'Activity', 'Task', 'Project', 'Timesheet', 'Sync'
 * @param {string} message - Short summary message
 * @param {object} payload - A JSON-compatible object
 */
function addNotification(accountId, type, message, payload) {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        db.transaction(function (tx) {
            tx.executeSql(
                `INSERT INTO ${TABLE_NAME} (account_id, message, type, payload, read_status) VALUES (?, ?, ?, ?, 0)`,
                [accountId, message, type, JSON.stringify(payload)]
            );
        });
    } catch (e) {
        DBCommon.logException("addNotification", e);
    }
}

/**
 * Deletes a notification by ID.
 *
 * @param {int} id - Notification ID
 */
function deleteNotification(id) {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        db.transaction(function (tx) {
            tx.executeSql(`DELETE FROM ${TABLE_NAME} WHERE id = ?`, [id]);
        });
    } catch (e) {
        DBCommon.logException("deleteNotification", e);
    }
}

/**
 * Deletes all notifications (for testing/clearing).
 */
function deleteAllNotifications() {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        db.transaction(function (tx) {
            tx.executeSql(`DELETE FROM ${TABLE_NAME}`);
        });
        console.log("All notifications deleted");
    } catch (e) {
        DBCommon.logException("deleteAllNotifications", e);
    }
}

/**
 * Gets full details of a single notification.
 *
 * @param {int} id - Notification ID
 * @returns {object|null}
 */
function getDetailsOfNotification(id) {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        var result = null;

        db.transaction(function (tx) {
            var rs = tx.executeSql(`SELECT * FROM ${TABLE_NAME} WHERE id = ?`, [id]);
            if (rs.rows.length > 0) {
                result = DBCommon.rowToObject(rs.rows.item(0));
            }
        });

        return result;
    } catch (e) {
        DBCommon.logException("getDetailsOfNotification", e);
        return null;
    }
}

/**
 * Retrieves all unread notifications.
 *
 * @returns {Array<object>}
 */
function getUnreadNotifications() {
    var list = [];

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var rs = tx.executeSql(`SELECT * FROM ${TABLE_NAME} WHERE read_status = 0 ORDER BY timestamp DESC`);
            for (var i = 0; i < rs.rows.length; i++) {
                list.push(DBCommon.rowToObject(rs.rows.item(i)));
            }
        });

    } catch (e) {
        DBCommon.logException("getUnreadNotifications", e);
    }

    return list;
}

/**
 * Marks a notification as read.
 *
 * @param {int} id - Notification ID
 */
function markAsRead(id) {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        db.transaction(function (tx) {
            tx.executeSql(`UPDATE ${TABLE_NAME} SET read_status = 1 WHERE id = ?`, [id]);
        });
    } catch (e) {
        DBCommon.logException("markAsRead", e);
    }
}

/**
 * Marks all notifications as read.
 */
function markAllAsRead() {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        db.transaction(function (tx) {
            tx.executeSql(`UPDATE ${TABLE_NAME} SET read_status = 1 WHERE read_status = 0`);
        });
    } catch (e) {
        DBCommon.logException("markAllAsRead", e);
    }
}

/**
 * Deletes all read notifications.
 */
function deleteAllRead() {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        db.transaction(function (tx) {
            tx.executeSql(`DELETE FROM ${TABLE_NAME} WHERE read_status = 1`);
        });
    } catch (e) {
        DBCommon.logException("deleteAllRead", e);
    }
}

/**
 * Gets count of unread notifications.
 *
 * @returns {int} Count of unread notifications
 */
function getUnreadCount() {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        var count = 0;
        db.transaction(function (tx) {
            var rs = tx.executeSql(`SELECT COUNT(*) as cnt FROM ${TABLE_NAME} WHERE read_status = 0`);
            if (rs.rows.length > 0) {
                count = rs.rows.item(0).cnt;
            }
        });
        return count;
    } catch (e) {
        DBCommon.logException("getUnreadCount", e);
        return 0;
    }
}

/**
 * Deletes all unread Sync-type notifications.
 * Used to clear stale sync error notifications without affecting
 * assignment notifications (Task, Activity, Project, Timesheet).
 *
 * @param {int} [accountId] - Optional account ID to scope deletion.
 *                            If omitted, clears Sync notifications for all accounts.
 * @returns {int} Number of deleted notifications
 */
function clearSyncNotifications(accountId) {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        var deleted = 0;
        db.transaction(function (tx) {
            var sql, params;
            if (accountId !== undefined && accountId !== null) {
                sql = "DELETE FROM " + TABLE_NAME + " WHERE type = 'Sync' AND read_status = 0 AND account_id = ?";
                params = [accountId];
            } else {
                sql = "DELETE FROM " + TABLE_NAME + " WHERE type = 'Sync' AND read_status = 0";
                params = [];
            }
            var rs = tx.executeSql(sql, params);
            deleted = rs.rowsAffected || 0;
        });
        console.log("Cleared " + deleted + " sync notifications");
        return deleted;
    } catch (e) {
        DBCommon.logException("clearSyncNotifications", e);
        return 0;
    }
}

/**
 * Checks if there are any unread Sync-type notifications.
 *
 * @returns {bool} True if there are unread Sync notifications
 */
function hasSyncNotifications() {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        var hasSync = false;
        db.transaction(function (tx) {
            var rs = tx.executeSql("SELECT COUNT(*) as cnt FROM " + TABLE_NAME + " WHERE type = 'Sync' AND read_status = 0");
            if (rs.rows.length > 0) {
                hasSync = rs.rows.item(0).cnt > 0;
            }
        });
        return hasSync;
    } catch (e) {
        DBCommon.logException("hasSyncNotifications", e);
        return false;
    }
}
