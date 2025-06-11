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
                accountsList.push(DBCommon.rowToObject(row));
            }
        });

    } catch (e) {
        DBCommon.logException("getAccountsList", e);
    }

    return accountsList;
}


/**
 * Sets the specified account as the default in the local SQLite database.
 *
 * This function ensures that only one account is marked as the default at any time.
 * It first resets the `is_default` flag to 0 for all accounts, and then sets it to 1
 * for the account matching the given ID.
 *
 * The `is_default` flag is stored as an INTEGER (0 or 1) in the `users` table.
 *
 * Usage:
 *     setDefaultAccount(3); // Marks account with ID 3 as default
 *
 * Preconditions:
 * - The `users` table must exist and include the `is_default` column.
 * - The provided `id` must match an existing account ID.
 *
 * Postconditions:
 * - All other accounts will have `is_default = 0`.
 * - One account will have `is_default = 1`.
 *
 * @param {number} id - The ID of the account to mark as default.
 */

function setDefaultAccount(id) {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            // Reset all accounts to is_default = 0
            tx.executeSql("UPDATE users SET is_default = 0");

            // Set the selected account to is_default = 1
            tx.executeSql("UPDATE users SET is_default = 1 WHERE id = ?", [id]);

            console.log("Default account set to ID:", id);
        });

    } catch (e) {
        DBCommon.logException(e);
    }
}

/**
 * Retrieves the ID of the currently marked default account from the database.
 *
 * @returns {number} The account ID marked as default, or 0 if none found.
 */
function getDefaultAccountId() {
    var defaultId = 0;

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var res = tx.executeSql("SELECT id FROM users WHERE is_default = 1 LIMIT 1");
            if (res.rows.length > 0) {
                defaultId = res.rows.item(0).id;
            }
        });

    } catch (e) {
        DBCommon.logException(e);
    }

    return defaultId;
}

/**
 * Retrieves a list of Odoo users associated with the given account ID.
 *
 * @param {number} accountId - The ID of the account to filter users by.
 * @returns {Array<Object>} A list of user objects with fields: id, name, remoteid.
 */
/**
 * Retrieves a list of Odoo users associated with the given account ID.
 *
 * @param {number} accountId - The ID of the account to filter users by.
 * @returns {Array<Object>} A list of user objects with fields: id, name, remoteid.
 */
function getUsers(accountId) {
    var assigneeList = [];

    try {
        var db = Sql.LocalStorage.openDatabaseSync(
            DBCommon.NAME,
            DBCommon.VERSION,
            DBCommon.DISPLAY_NAME,
            DBCommon.SIZE
        );

        db.transaction(function(tx) {
            var result = tx.executeSql(
                "SELECT id, name, odoo_record_id FROM res_users_app WHERE account_id = ?",
                [accountId]
            );

            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);
                assigneeList.push(DBCommon.rowToObject(row));
            }
        });

    } catch (e) {
        DBCommon.logException("getUsers", e);
    }

    return assigneeList;
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


/**
 * Retrieves the `odoo_record_id` for the current user based on the username from the `users` table.
 * It looks up the `username` for the given `accountId` in the `users` table,
 * and then finds the corresponding user in the `res_users_app` table by matching the `name` field.
 *
 * @param {number} accountId - The ID of the account in the `users` table.
 * @returns {number|null} The `odoo_record_id` of the matched user, or `null` if not found.
 */
function getCurrentUserOdooId(accountId) {
    if (accountId === 0) {
        return 1; // Local account
    }
    let odooId = null;

    try {
        const db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            DBCommon.log(`Looking up username for account_id: ${accountId}`);
            const result = tx.executeSql("SELECT username FROM users WHERE id = ?", [accountId]);

            if (result.rows.length === 0) {
                DBCommon.log("No user found with given account ID.");
                return;
            }

            const username = result.rows.item(0).username;

            DBCommon.log(`Found username: ${username}, now checking res_users_app`);

            const userResult = tx.executeSql("SELECT odoo_record_id FROM res_users_app WHERE login = ?", [username]);

            if (userResult.rows.length > 0) {
                odooId = userResult.rows.item(0).odoo_record_id;
                DBCommon.log(`Found odoo_record_id: ${odooId}`);
            } else {
                DBCommon.log(`No match found in res_users_app for username: ${username}`);
            }
        });
    } catch (e) {
        logException(e);
    }

    return odooId;
}
