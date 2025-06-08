.import "database.js" as DBCommon
.import QtQuick.LocalStorage 2.7 as Sql

/**
 * Retrieves the list of all user accounts from the local SQLite database.
 *
 * Each account object strictly uses column names as defined in the 'users' table schema.
 *
 * @returns {Array<Object>} An array of account objects.
 */
function getAccountsList() {
    var accountsList = [];

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var accounts = tx.executeSql("SELECT * FROM users");

            for (var i = 0; i < accounts.rows.length; i++) {
                var row = accounts.rows.item(i);

                accountsList.push({
                    id: row.id,
                    name: row.name,
                    link: row.link,
                    last_modified: row.last_modified,
                    database: row.database,
                    connectwith_id: row.connectwith_id,
                    api_key: row.api_key,
                    username: row.username
                });
            }
        });

    } catch (e) {
        DBCommon.logException(e);
    }

    return accountsList;
}


/**
 * Fetches and parses the sync report logs for a specific account from the local SQLite database.
 *
 * This function queries the `sync_report` table for a given `accountId`, then parses each `message`
 * (which is expected to be a JSON array of log entries). It appends the corresponding timestamp
 * to each individual log entry before returning the full list of parsed logs.
 *
 * @param {number} accountId - The ID of the account for which to fetch logs.
 * @returns {Array<Object>} An array of parsed log objects with attached timestamps.
 */
function fetchParsedSyncLog(accountId) {
    var parsedLogs = [];

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var rs = tx.executeSql(
                "SELECT timestamp, message FROM sync_report WHERE account_id = ? ORDER BY timestamp DESC",
                [accountId]
            );

            for (var i = 0; i < rs.rows.length; i++) {
                var entry = rs.rows.item(i);

                try {
                    // Each 'message' field is a JSON string containing an array of log objects
                    var logs = JSON.parse(entry.message);

                    logs.forEach(function (log) {
                        log.timestamp = entry.timestamp; // Attach DB timestamp to each log
                        parsedLogs.push(log);
                    });

                } catch (e) {
                    DBCommon.logException("fetchParsedSyncLog", e)
                }
            }
        });

    } catch (e) {
        DBCommon.logException(e);
    }

    return parsedLogs;
}

/**
 * Deletes a user account and all related records from associated tables in the local SQLite database.
 *
 * This is a cascading delete utility that removes a user by their `id` from the `users` table,
 * and also deletes all related data from other tables using `account_id` as a foreign reference.
 *
 * @param {number} userId - The `id` of the user to delete.
 */
function deleteAccountAndRelatedData(userId) {

    try {
        const db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            const tables = [
                "sync_report",
                "project_project_app",
                "project_task_app",
                "account_analytic_line_app",
                "res_users_app",
                "mail_activity_type_app",
                "mail_activity_app"
            ];

            for (let i = 0; i < tables.length; i++) {
                const table = tables[i];
                DBCommon.log("Deleting data from account " + userId)
                tx.executeSql(`DELETE FROM ${table} WHERE account_id = ?`, [userId]);
            }

            DBCommon.log(`Deleting user from users table where id = ${userId}`);
            tx.executeSql("DELETE FROM users WHERE id = ?", [userId]);

            DBCommon.log(`Account and related data deleted for account_id: ${userId}`);
        });

    } catch (e) {
        logException(e);
    }
}
