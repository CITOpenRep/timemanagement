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
