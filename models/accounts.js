.import "database.js" as DBCommon
    .import "logger.js" as Logger
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
                var obj = DBCommon.rowToObject(row);
                if (obj.id === 0 || obj.name === "Local Account") {
                    obj.name = "Local";
                }
                accountsList.push(obj);
            }
        });

    } catch (e) {
        DBCommon.logException("getAccountsList", e);
    }

    return accountsList;
}


function markAttachmentDownloaded(accountId, recordId, fileName) {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        db.transaction(function (tx) {
            tx.executeSql(
                "INSERT OR REPLACE INTO attachment_download_app (account_id, record_id, file_name, downloaded) VALUES (?, ?, ?, 1)",
                [accountId, recordId, fileName]
            );
        });
    } catch (e) {
        Logger.error("Accounts", "markAttachmentDownloaded failed:", e)
    }
}

function isAttachmentDownloaded(accountId, recordId) {
    var result = false;
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        db.transaction(function (tx) {
            var rs = tx.executeSql(
                "SELECT downloaded FROM attachment_download_app WHERE account_id = ? AND record_id = ?",
                [accountId, recordId]
            );
            if (rs.rows.length > 0 && rs.rows.item(0).downloaded === 1)
                result = true;
        });
    } catch (e) {
        Logger.error("Accounts", "isAttachmentDownloaded failed:", e)
    }
    return result;
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

            if (id !== -1) {
                // Set the selected account to is_default = 1
                tx.executeSql("UPDATE users SET is_default = 1 WHERE id = ?", [id]);
            }
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
    var defaultId = -1;  // Default to -1 instead of 0

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var res = tx.executeSql("SELECT id FROM users WHERE is_default = 1 LIMIT 1");
            if (res.rows.length > 0) {
                defaultId = res.rows.item(0).id;
            } else {
                var fallback = tx.executeSql("SELECT id FROM users ORDER BY id ASC LIMIT 1");
                if (fallback.rows.length > 0) {
                    defaultId = fallback.rows.item(0).id;
                }
            }
        });

    } catch (e) {
        DBCommon.logException(e);
    }

    return defaultId;
}


/**
 * Retrieves the ID of the default remote account (id > 0), or the first remote account.
 *
 * @returns {number} The remote account ID, or -1 if no remote account exists.
 */
function getDefaultRemoteAccountId() {
    var remoteId = -1;

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var res = tx.executeSql("SELECT id FROM users WHERE is_default = 1 AND id > 0 LIMIT 1");
            if (res.rows.length > 0) {
                remoteId = res.rows.item(0).id;
            } else {
                var fallback = tx.executeSql("SELECT id FROM users WHERE id > 0 ORDER BY id ASC LIMIT 1");
                if (fallback.rows.length > 0) {
                    remoteId = fallback.rows.item(0).id;
                }
            }
        });

    } catch (e) {
        DBCommon.logException(e);
    }

    return remoteId;
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

        db.transaction(function (tx) {
            var result = tx.executeSql(
                "SELECT u.id, u.name, COALESCE(NULLIF(u.login, ''), NULLIF(u.email, ''), NULLIF(u.work_email, ''), '') as email, u.odoo_record_id, u.account_id, a.name as account_name " +
                "FROM res_users_app u LEFT JOIN users a ON u.account_id = a.id " +
                "WHERE u.account_id = ? AND (u.active IS NULL OR u.active = 1) AND u.name IS NOT NULL AND TRIM(u.name) != '' " +
                "ORDER BY u.name COLLATE NOCASE ASC",
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
 * Creates a new user account in the local SQLite database if no duplicate exists.
 *
 * @param {string} name - The name of the user.
 * @param {string} link - The Odoo server link (or local server reference).
 * @param {string} database - The Odoo database name.
 * @param {string} username - The username for the account.
 * @param {number} selectedConnectWithId - The connection type identifier (e.g., 1 for API key).
 * @param {string} apikey - The API key if the connection type requires it.
 * @returns {object} - Returns result object with duplicateFound, message, and duplicateType.
 */
function createAccount(name, link, database, username, selectedConnectWithId, apikey) {
    let result = {
        duplicateFound: false,
        message: "",
        duplicateType: null
    };

    try {
        const db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {


            const nameCheckResult = tx.executeSql(
                'SELECT COUNT(*) AS count FROM users WHERE LOWER(name) = LOWER(?)',
                [name]
            );

            if (nameCheckResult.rows.item(0).count > 0) {
                DBCommon.log("Duplicate account name found (case-insensitive): " + name);
                result.duplicateFound = true;
                result.duplicateType = "name";
                result.message = "An account with this name already exists.";
                return;
            }


            const connectionCheckResult = tx.executeSql(
                'SELECT COUNT(*) AS count FROM users WHERE link = ? AND database = ? AND username = ? COLLATE BINARY',
                [link, database, username]
            );

            if (connectionCheckResult.rows.item(0).count > 0) {
                DBCommon.log("Duplicate connection found for: " + link + "/" + database + "/" + username);
                result.duplicateFound = true;
                result.duplicateType = "connection";
                result.message = "An account with this server connection already exists.";
                return;
            }


            const apiKeyToStore = (selectedConnectWithId === 1) ? apikey : '';
            tx.executeSql(
                'INSERT INTO users (name, link, database, username, connectwith_id, api_key) VALUES (?, ?, ?, ?, ?, ?)',
                [name, link, database, username, selectedConnectWithId, apiKeyToStore]
            );

            DBCommon.log("New user account created successfully: " + name);
            result.message = "Account created successfully.";
        });

    } catch (e) {
        DBCommon.logException("createAccount", e);
        result.duplicateFound = true;
        result.message = "Error creating account: " + e.message;
    }

    return result;
}

/**
 * Updates an existing user account in the local SQLite database.
 *
 * @param {number} accountId - The ID of the account to update.
 * @param {string} name - The new name of the user.
 * @param {string} link - The new Odoo server link.
 * @param {string} database - The new Odoo database name.
 * @param {string} username - The new username for the account.
 * @param {number} selectedConnectWithId - The connection type identifier.
 * @param {string} apikey - The new API key if the connection type requires it.
 * @returns {object} - Returns result object with success, message, and duplicateType.
 */
function updateAccount(accountId, name, link, database, username, selectedConnectWithId, apikey) {
    let result = {
        success: false,
        message: "",
        duplicateType: null
    };

    try {
        const db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            // Check for duplicate account name (excluding current account)
            const nameCheckResult = tx.executeSql(
                'SELECT COUNT(*) AS count FROM users WHERE LOWER(name) = LOWER(?) AND id != ?',
                [name, accountId]
            );

            if (nameCheckResult.rows.item(0).count > 0) {
                DBCommon.log("Duplicate account name found (case-insensitive): " + name);
                result.duplicateType = "name";
                result.message = "An account with this name already exists.";
                return;
            }

            // Check for duplicate connection (excluding current account)
            const connectionCheckResult = tx.executeSql(
                'SELECT COUNT(*) AS count FROM users WHERE link = ? AND database = ? AND username = ? COLLATE BINARY AND id != ?',
                [link, database, username, accountId]
            );

            if (connectionCheckResult.rows.item(0).count > 0) {
                DBCommon.log("Duplicate connection found for: " + link + "/" + database + "/" + username);
                result.duplicateType = "connection";
                result.message = "An account with this server connection already exists.";
                return;
            }

            // Update the account
            const apiKeyToStore = (selectedConnectWithId === 1) ? apikey : '';
            tx.executeSql(
                'UPDATE users SET name = ?, link = ?, database = ?, username = ?, connectwith_id = ?, api_key = ? WHERE id = ?',
                [name, link, database, username, selectedConnectWithId, apiKeyToStore, accountId]
            );

            DBCommon.log("User account updated successfully: " + name);
            result.success = true;
            result.message = "Account updated successfully.";
        });

    } catch (e) {
        DBCommon.logException("updateAccount", e);
        result.message = "Error updating account: " + e.message;
    }

    return result;
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
    if (userId === 0 || userId === "0") {
        console.warn("Cannot delete Local Account");
        return;
    }

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
                "ir_model_app",
                "mail_activity_app",
                "ir_attachment_app",
                "project_task_assignee_app",
                "project_update_app",
                "project_task_type_app",
                "project_project_stage_app",
                "attachment_download_app",
                "form_drafts",
                "notification"
            ];

            var numericUserId = parseInt(userId, 10);
            for (let i = 0; i < tables.length; i++) {
                const table = tables[i];
                DBCommon.log("Deleting data from account " + numericUserId);
                try {
                    tx.executeSql(`DELETE FROM ${table} WHERE account_id = ?`, [numericUserId]);
                } catch (tableErr) {
                    DBCommon.log("Could not delete from table " + table + ": " + tableErr);
                }
            }

            DBCommon.log(`Deleting user from users table where id = ${numericUserId}`);
            tx.executeSql("DELETE FROM users WHERE id = ?", [numericUserId]);

            // Ensure a valid default account exists
            var defaultCheck = tx.executeSql("SELECT id FROM users WHERE is_default = 1 LIMIT 1");
            if (defaultCheck.rows.length === 0) {
                var firstAccount = tx.executeSql("SELECT id FROM users ORDER BY id ASC LIMIT 1");
                if (firstAccount.rows.length > 0) {
                    tx.executeSql("UPDATE users SET is_default = 1 WHERE id = ?", [firstAccount.rows.item(0).id]);
                }
            }

            // Post-deletion sweep across all tables to purge any unlinked records
            for (let j = 0; j < tables.length; j++) {
                try {
                    tx.executeSql(`DELETE FROM ${tables[j]} WHERE account_id NOT IN (SELECT id FROM users)`);
                } catch (sweepErr) {
                    // Ignore sweep errors for optional tables
                }
            }

            DBCommon.log(`Account and related data deleted for account_id: ${numericUserId}`);
        });

    } catch (e) {
        DBCommon.logException("Accounts", e);
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
    var parsedAccountId = (accountId !== undefined && accountId !== null) ? parseInt(accountId) : -1;
    if (parsedAccountId === 0) {
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

            const userResult = tx.executeSql("SELECT odoo_record_id FROM res_users_app WHERE (login = ? OR email = ? OR work_email = ?) AND account_id = ? LIMIT 1", [username, username, username, accountId]);

            if (userResult.rows.length > 0) {
                odooId = userResult.rows.item(0).odoo_record_id;
                DBCommon.log(`Found odoo_record_id: ${odooId}`);
            } else {
                DBCommon.log(`No match found in res_users_app for username: ${username}`);
            }
        });
    } catch (e) {
        DBCommon.logException("getCurrentUserOdooId", e);
    }

    return odooId;
}

/**
 * Gets the current logged-in user's assignee IDs as composite {user_id, account_id} objects.
 * When accountId is -1 (All Accounts), returns IDs for ALL logged-in accounts.
 * When accountId is specific, returns only the ID for that account.
 *
 * @param {number} accountId - The account ID (-1 for all accounts)
 * @returns {Array<Object>} Array of {user_id: number, account_id: number} objects
 */
function getCurrentUserAssigneeIds(accountId) {
    var assigneeIds = [];

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            if (accountId === -1) {
                // All accounts mode: get current user IDs for ALL logged-in accounts
                var accountsResult = tx.executeSql("SELECT id, username FROM users");

                for (var i = 0; i < accountsResult.rows.length; i++) {
                    var account = accountsResult.rows.item(i);
                    var acctId = account.id;
                    var username = account.username;

                    if (acctId === 0) {
                        // Local account
                        assigneeIds.push({ user_id: 1, account_id: 0 });
                        continue;
                    }

                    // Find the odoo_record_id for this account's logged-in user
                    var userResult = tx.executeSql(
                        "SELECT odoo_record_id FROM res_users_app WHERE login = ? AND account_id = ?",
                        [username, acctId]
                    );

                    if (userResult.rows.length > 0) {
                        var odooId = userResult.rows.item(0).odoo_record_id;
                        if (odooId && odooId > 0) {
                            assigneeIds.push({ user_id: odooId, account_id: acctId });
                        }
                    }
                }
            } else {
                // Specific account mode
                if (accountId === 0) {
                    assigneeIds.push({ user_id: 1, account_id: 0 });
                } else {
                    var usernameResult = tx.executeSql("SELECT username FROM users WHERE id = ?", [accountId]);

                    if (usernameResult.rows.length > 0) {
                        var username = usernameResult.rows.item(0).username;
                        var userResult = tx.executeSql(
                            "SELECT odoo_record_id FROM res_users_app WHERE login = ? AND account_id = ?",
                            [username, accountId]
                        );

                        if (userResult.rows.length > 0) {
                            var odooId = userResult.rows.item(0).odoo_record_id;
                            if (odooId && odooId > 0) {
                                assigneeIds.push({ user_id: odooId, account_id: accountId });
                            }
                        }
                    }
                }
            }
        });
    } catch (e) {
        DBCommon.logException("getCurrentUserAssigneeIds", e);
    }

    return assigneeIds;
}

/**
 * Fetches the account name for a given account ID from the `users` table.
 *
 * @param {number} accountId - The ID of the account to look up.
 * @returns {string} - The name of the account, or an empty string if not found.
 */
function getAccountName(accountId) {
    if (accountId === null || accountId === undefined) {
        return "";
    }

    if (Number(accountId) === 0) {
        return "Local";
    }

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        var name = "";

        db.transaction(function (tx) {
            var result = tx.executeSql("SELECT name FROM users WHERE id = ?", [accountId]);
            if (result.rows.length > 0) {
                name = result.rows.item(0).name;
            }
        });

        if (name === "Local Account") {
            return "Local";
        }

        return name;
    } catch (e) {
        Logger.error("Accounts", "getAccountName failed:", e)
        return "";
    }
}

/**
 * Retrieves the username associated with a specific Odoo user ID
 * from the local SQLite database.
 *
 * @function getUserNameByOdooId
 * @param {number} odoo_record_id - The user ID from Odoo (remote system).
 * @returns {string} - The user's name if found; otherwise, an empty string.
 *
 * @description
 * Opens a local SQLite database transaction and queries the `res_users_app` table
 * to find a record matching the provided `odoo_record_id`.
 * If a match is found, extracts and returns the `name` field.
 * Logs any exceptions using `DBCommon.logException()` to ensure safe failure handling.
 */
function getUserNameByOdooId(odoo_record_id) {
    var userName = "";

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var query = "SELECT name FROM res_users_app WHERE (odoo_record_id = ? OR id = ?) LIMIT 1";
            var result = tx.executeSql(query, [odoo_record_id, odoo_record_id]);

            if (result.rows.length > 0) {
                userName = result.rows.item(0).name;
            }
        });

    } catch (e) {
        DBCommon.logException("getUserNameByOdooId", e);
    }

    return userName;
}

/**
 * Combines user objects that share the same email or login across different accounts.
 *
 * @param {Array<Object>} userList - The list of user objects.
 * @param {Object} [tx] - Active SQLite transaction.
 * @returns {Array<Object>} Combined user list with duplicate accounts merged.
 */
function combineUsersByEmail(userList, tx) {
    if (!userList || userList.length <= 1) {
        return userList || [];
    }

    var groups = {};
    var groupOrder = [];

    for (var i = 0; i < userList.length; i++) {
        var u = userList[i];
        var email = (u.email || u.work_email || "").trim().toLowerCase();
        var login = (u.login || "").trim().toLowerCase();

        var key = "";
        if (email !== "") {
            key = "email:" + email;
        } else if (login !== "") {
            key = "login:" + login;
        } else {
            key = "id:" + u.id;
        }

        if (!groups[key]) {
            groups[key] = {
                items: [u],
                emails: email !== "" ? [email] : [],
                logins: login !== "" ? [login] : [],
                allUserIds: [u.id],
                allAccountIds: (u.accountId !== undefined && u.accountId !== null) ? [u.accountId] : []
            };
            groupOrder.push(key);
        } else {
            var g = groups[key];
            g.items.push(u);
            if (g.allUserIds.indexOf(u.id) === -1) {
                g.allUserIds.push(u.id);
            }
            if (u.accountId !== undefined && u.accountId !== null && g.allAccountIds.indexOf(u.accountId) === -1) {
                g.allAccountIds.push(u.accountId);
            }
            if (email !== "" && g.emails.indexOf(email) === -1) {
                g.emails.push(email);
            }
            if (login !== "" && g.logins.indexOf(login) === -1) {
                g.logins.push(login);
            }
        }
    }

    var combined = [];
    for (var j = 0; j < groupOrder.length; j++) {
        var grp = groups[groupOrder[j]];
        var items = grp.items;

        // Pick best name: longest non-placeholder name
        var bestName = items[0].name || "";
        var bestAvatar = items[0].avatar || "";
        for (var k = 0; k < items.length; k++) {
            var candName = (items[k].name || "").trim();
            if (candName !== "" && !/^User #\d+$/i.test(candName)) {
                if (bestName === "" || /^User #\d+$/i.test(bestName) || candName.length > bestName.length) {
                    bestName = candName;
                }
            }
            if (!bestAvatar && items[k].avatar) {
                bestAvatar = items[k].avatar;
            }
        }

        // Query res_users_app for any other account/user IDs for these emails
        if (tx && grp.emails.length > 0) {
            try {
                var emPlaceholders = grp.emails.map(function () { return "?"; }).join(",");
                var qRes = tx.executeSql(
                    "SELECT account_id, (CASE WHEN account_id = 0 OR odoo_record_id IS NULL OR odoo_record_id <= 0 THEN id ELSE odoo_record_id END) AS uid " +
                    "FROM res_users_app WHERE (LOWER(TRIM(email)) IN (" + emPlaceholders + ") OR LOWER(TRIM(work_email)) IN (" + emPlaceholders + "))",
                    grp.emails.concat(grp.emails)
                );
                for (var m = 0; m < qRes.rows.length; m++) {
                    var rowUid = Number(qRes.rows.item(m).uid);
                    var rowAccId = Number(qRes.rows.item(m).account_id);
                    if (grp.allUserIds.indexOf(rowUid) === -1) {
                        grp.allUserIds.push(rowUid);
                    }
                    if (grp.allAccountIds.indexOf(rowAccId) === -1) {
                        grp.allAccountIds.push(rowAccId);
                    }
                }
            } catch (err) {
                // Ignore query error, fall back to known items
            }
        }

        var accountNames = [];
        if (tx && grp.allAccountIds && grp.allAccountIds.length > 0) {
            try {
                var aPl = grp.allAccountIds.map(function () { return "?"; }).join(",");
                var aRes = tx.executeSql("SELECT id, name FROM users WHERE id IN (" + aPl + ")", grp.allAccountIds);
                for (var an = 0; an < aRes.rows.length; an++) {
                    var aRow = aRes.rows.item(an);
                    if (aRow.name && accountNames.indexOf(aRow.name) === -1) {
                        accountNames.push(aRow.name);
                    }
                }
            } catch (aErr) {
                // Ignore query error
            }
        }

        var primaryItem = items[0];
        combined.push({
            id: primaryItem.id,
            name: bestName || primaryItem.name || ("User #" + primaryItem.id),
            login: primaryItem.login || (grp.logins.length > 0 ? grp.logins[0] : ""),
            email: primaryItem.email || (grp.emails.length > 0 ? grp.emails[0] : ""),
            avatar: bestAvatar,
            accountId: primaryItem.accountId,
            account_id: primaryItem.accountId,
            account_names: accountNames,
            account_name: accountNames.join(", "),
            allUserIds: grp.allUserIds,
            allAccountIds: grp.allAccountIds
        });
    }

    return combined;
}

/**
 * Resolves all { accountId, userId } pairs corresponding to a user filter.
 * When accountId is -1 (All Accounts), users with the same email or login across
 * different accounts are combined, and their corresponding user IDs in each account are returned.
 * When accountId is specific (> -1), it resolves the user ID valid for that specific account.
 *
 * @param {number|string} userId - The selected user ID (-1 for all users).
 * @param {number|string} [accountId=-1] - The active account ID (-1 for all accounts).
 * @returns {Array<Object>} List of { accountId: number, userId: number } pairs.
 */
function getUserFilterAccountPairs(userId, accountId) {
    var pairs = [];
    if (userId === undefined || userId === null || userId === -1 || userId === "-1") {
        return pairs;
    }

    var numAccountId = (accountId !== undefined && accountId !== null) ? Number(accountId) : -1;

    // Handle single selection object as array
    if (typeof userId === "object" && !Array.isArray(userId)) {
        var objUid = (userId.user_id !== undefined) ? userId.user_id : userId.userId;
        if (objUid === -1 || objUid === "-1") {
            return pairs;
        }
        userId = [userId];
    }

    // Handle Array of users/selections
    if (Array.isArray(userId)) {
        if (userId.length === 0) {
            return pairs;
        }
        var seenMapArr = {};
        for (var a = 0; a < userId.length; a++) {
            var item = userId[a];
            if (item === undefined || item === null || item === -1 || item === "-1") {
                continue;
            }
            if (typeof item === "object") {
                var itemUid = (item.user_id !== undefined) ? item.user_id : item.userId;
                var itemAccId = (item.account_id !== undefined) ? item.account_id : item.accountId;
                if (itemUid === undefined || itemUid === null || itemUid === -1 || itemUid === "-1") {
                    continue;
                }
                var nItemUid = Number(itemUid);
                var nItemAccId = (itemAccId !== undefined && itemAccId !== null) ? Number(itemAccId) : -1;
                if (nItemAccId >= 0 && (numAccountId === -1 || numAccountId === nItemAccId)) {
                    var k = nItemAccId + ":" + nItemUid;
                    if (!seenMapArr[k]) {
                        seenMapArr[k] = true;
                        pairs.push({ accountId: nItemAccId, userId: nItemUid });
                    }
                } else {
                    var subPairs = getUserFilterAccountPairs(nItemUid, accountId);
                    for (var s = 0; s < subPairs.length; s++) {
                        var kSub = subPairs[s].accountId + ":" + subPairs[s].userId;
                        if (!seenMapArr[kSub]) {
                            seenMapArr[kSub] = true;
                            pairs.push(subPairs[s]);
                        }
                    }
                }
            } else {
                var subPairsScalar = getUserFilterAccountPairs(item, accountId);
                for (var ss = 0; ss < subPairsScalar.length; ss++) {
                    var kSubSc = subPairsScalar[ss].accountId + ":" + subPairsScalar[ss].userId;
                    if (!seenMapArr[kSubSc]) {
                        seenMapArr[kSubSc] = true;
                        pairs.push(subPairsScalar[ss]);
                    }
                }
            }
        }
        return pairs;
    }

    var numUserId = Number(userId);
    if (isNaN(numUserId) || numUserId < 0) {
        return pairs;
    }

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            // 1. Look up res_users_app records for the given numUserId
            var userRecords = [];
            var findSql = "SELECT account_id, (CASE WHEN account_id = 0 OR odoo_record_id IS NULL OR odoo_record_id <= 0 THEN id ELSE odoo_record_id END) AS uid, email, work_email, login " +
                "FROM res_users_app WHERE (odoo_record_id = ? OR (account_id = 0 AND id = ?))";
            var findRes = tx.executeSql(findSql, [numUserId, numUserId]);
            for (var i = 0; i < findRes.rows.length; i++) {
                userRecords.push(findRes.rows.item(i));
            }

            // Collect non-empty emails and logins
            var emails = [];
            var logins = [];
            for (var j = 0; j < userRecords.length; j++) {
                var r = userRecords[j];
                var em = (r.email || r.work_email || "").trim().toLowerCase();
                var lg = (r.login || "").trim().toLowerCase();
                if (em !== "" && emails.indexOf(em) === -1) {
                    emails.push(em);
                }
                if (lg !== "" && logins.indexOf(lg) === -1) {
                    logins.push(lg);
                }
            }

            // 2. If single account target (numAccountId !== -1):
            if (numAccountId !== -1) {
                for (var k = 0; k < userRecords.length; k++) {
                    if (Number(userRecords[k].account_id) === numAccountId) {
                        pairs.push({ accountId: numAccountId, userId: Number(userRecords[k].uid) });
                        return;
                    }
                }

                // If not directly matching this account by ID, match by email or login within this account
                if (emails.length > 0 || logins.length > 0) {
                    var matchConds = [];
                    var matchParams = [];
                    if (emails.length > 0) {
                        var emPl = emails.map(function () { return "?"; }).join(",");
                        matchConds.push("(NULLIF(TRIM(email), '') IS NOT NULL AND LOWER(TRIM(email)) IN (" + emPl + "))");
                        matchConds.push("(NULLIF(TRIM(work_email), '') IS NOT NULL AND LOWER(TRIM(work_email)) IN (" + emPl + "))");
                        matchParams = matchParams.concat(emails).concat(emails);
                    }
                    if (logins.length > 0) {
                        var lgPl = logins.map(function () { return "?"; }).join(",");
                        matchConds.push("LOWER(TRIM(login)) IN (" + lgPl + ")");
                        matchParams = matchParams.concat(logins);
                    }

                    var accSql = "SELECT account_id, (CASE WHEN account_id = 0 OR odoo_record_id IS NULL OR odoo_record_id <= 0 THEN id ELSE odoo_record_id END) AS uid " +
                        "FROM res_users_app WHERE account_id = ? AND (" + matchConds.join(" OR ") + ") LIMIT 1";
                    var accRes = tx.executeSql(accSql, [numAccountId].concat(matchParams));
                    if (accRes.rows.length > 0) {
                        pairs.push({ accountId: numAccountId, userId: Number(accRes.rows.item(0).uid) });
                        return;
                    }
                }

                // Fallback for single account
                pairs.push({ accountId: numAccountId, userId: numUserId });
                return;
            }

            // 3. All accounts (numAccountId === -1):
            var seenMap = {};
            if (emails.length > 0 || logins.length > 0) {
                var allConds = [];
                var allParams = [];
                if (emails.length > 0) {
                    var emPlAll = emails.map(function () { return "?"; }).join(",");
                    allConds.push("(NULLIF(TRIM(email), '') IS NOT NULL AND LOWER(TRIM(email)) IN (" + emPlAll + "))");
                    allConds.push("(NULLIF(TRIM(work_email), '') IS NOT NULL AND LOWER(TRIM(work_email)) IN (" + emPlAll + "))");
                    allParams = allParams.concat(emails).concat(emails);
                }
                if (logins.length > 0) {
                    var lgPlAll = logins.map(function () { return "?"; }).join(",");
                    allConds.push("LOWER(TRIM(login)) IN (" + lgPlAll + ")");
                    allParams = allParams.concat(logins);
                }

                var allSql = "SELECT account_id, (CASE WHEN account_id = 0 OR odoo_record_id IS NULL OR odoo_record_id <= 0 THEN id ELSE odoo_record_id END) AS uid " +
                    "FROM res_users_app WHERE " + allConds.join(" OR ");
                var allRes = tx.executeSql(allSql, allParams);
                for (var m = 0; m < allRes.rows.length; m++) {
                    var itm = allRes.rows.item(m);
                    var acctId = Number(itm.account_id);
                    var uId = Number(itm.uid);
                    var key = acctId + ":" + uId;
                    if (!seenMap[key]) {
                        seenMap[key] = true;
                        pairs.push({ accountId: acctId, userId: uId });
                    }
                }
            }

            // If no pairs found via email/login, include records from initial lookup
            if (pairs.length === 0 && userRecords.length > 0) {
                for (var n = 0; n < userRecords.length; n++) {
                    var uRec = userRecords[n];
                    var keyU = Number(uRec.account_id) + ":" + Number(uRec.uid);
                    if (!seenMap[keyU]) {
                        seenMap[keyU] = true;
                        pairs.push({ accountId: Number(uRec.account_id), userId: Number(uRec.uid) });
                    }
                }
            }
        });
    } catch (e) {
        DBCommon.logException("getUserFilterAccountPairs", e);
    }

    if (pairs.length === 0) {
        pairs.push({ accountId: numAccountId, userId: numUserId });
    }

    return pairs;
}

/**
 * Builds a SQL WHERE clause fragment and parameters array for filtering timesheets by user.
 * Supports scalar user ID (-1 for all users), array of user IDs, or array of selection objects.
 *
 * @param {number|string|Array} userId - The user ID or array of IDs/selection objects.
 * @param {number|string} [accountId=-1] - The active account ID (-1 for all accounts).
 * @param {string} [tableAlias=""] - Optional table alias (e.g. "aal" or "a").
 * @returns {{ clause: string, params: Array }}
 */
function buildUserFilterSQL(userId, accountId, tableAlias) {
    if (userId === undefined || userId === null || userId === -1 || userId === "-1") {
        return { clause: "", params: [] };
    }
    if (typeof userId === "object" && !Array.isArray(userId)) {
        var singleObjUid = (userId.user_id !== undefined) ? userId.user_id : userId.userId;
        if (singleObjUid === -1 || singleObjUid === "-1") {
            return { clause: "", params: [] };
        }
        userId = [userId];
    }
    if (Array.isArray(userId)) {
        if (userId.length === 0) {
            return { clause: "", params: [] };
        }
        if (userId.length === 1 && (userId[0] === -1 || userId[0] === "-1" || (typeof userId[0] === "object" && (userId[0].user_id === -1 || userId[0].userId === -1)))) {
            return { clause: "", params: [] };
        }
    }

    var numAccountId = (accountId !== undefined && accountId !== null) ? Number(accountId) : -1;
    var pairs = getUserFilterAccountPairs(userId, accountId);
    var prefix = tableAlias ? (tableAlias + ".") : "";

    if (pairs.length === 0) {
        return { clause: "", params: [] };
    }

    if (numAccountId !== -1) {
        var userIdsInAccount = [];
        for (var p = 0; p < pairs.length; p++) {
            if (userIdsInAccount.indexOf(pairs[p].userId) === -1) {
                userIdsInAccount.push(pairs[p].userId);
            }
        }
        if (userIdsInAccount.length === 0) {
            return { clause: "", params: [] };
        }
        if (userIdsInAccount.length === 1) {
            return { clause: prefix + "user_id = ?", params: [userIdsInAccount[0]] };
        }
        var placeholders = userIdsInAccount.map(function () { return "?"; }).join(", ");
        return {
            clause: prefix + "user_id IN (" + placeholders + ")",
            params: userIdsInAccount
        };
    }

    if (pairs.length === 1) {
        if (pairs[0].accountId >= 0) {
            return {
                clause: "(" + prefix + "account_id = ? AND " + prefix + "user_id = ?)",
                params: [pairs[0].accountId, pairs[0].userId]
            };
        } else {
            return { clause: prefix + "user_id = ?", params: [pairs[0].userId] };
        }
    }

    var byAccount = {};
    var accList = [];
    for (var i = 0; i < pairs.length; i++) {
        var acct = pairs[i].accountId;
        var u = pairs[i].userId;
        if (!byAccount[acct]) {
            byAccount[acct] = [];
            accList.push(acct);
        }
        if (byAccount[acct].indexOf(u) === -1) {
            byAccount[acct].push(u);
        }
    }

    var clauses = [];
    var params = [];
    for (var aIdx = 0; aIdx < accList.length; aIdx++) {
        var aId = accList[aIdx];
        var uIds = byAccount[aId];
        if (aId >= 0) {
            if (uIds.length === 1) {
                clauses.push("(" + prefix + "account_id = ? AND " + prefix + "user_id = ?)");
                params.push(aId);
                params.push(uIds[0]);
            } else {
                var inPlaceholders = uIds.map(function () { return "?"; }).join(", ");
                clauses.push("(" + prefix + "account_id = ? AND " + prefix + "user_id IN (" + inPlaceholders + "))");
                params.push(aId);
                params = params.concat(uIds);
            }
        } else {
            if (uIds.length === 1) {
                clauses.push(prefix + "user_id = ?");
                params.push(uIds[0]);
            } else {
                var inPl = uIds.map(function () { return "?"; }).join(", ");
                clauses.push(prefix + "user_id IN (" + inPl + ")");
                params = params.concat(uIds);
            }
        }
    }

    return {
        clause: "(" + clauses.join(" OR ") + ")",
        params: params
    };
}

/**
 * Retrieves active users available for filtering in the dashboard for a given account.
 * When accountId is -1 (All Accounts), users with the same email or login across
 * different accounts are combined into a single entry with combined metrics.
 *
 * @param {number} accountId - The account ID (-1 for all accounts).
 * @returns {Array<Object>} List of users: [{ id, name, login, email, avatar, accountId, allUserIds }]
 */
function getDashboardFilterUsers(accountId) {
    var users = [];
    var seenIds = {};

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            // Local Account (account_id = 0)
            if (accountId === 0 || accountId === "0") {
                users.push({
                    id: 1,
                    name: "Local User",
                    login: "local_user",
                    email: "",
                    avatar: "",
                    accountId: 0,
                    allUserIds: [1]
                });
                return;
            }

            // 1. Find distinct user IDs that have timesheet records in the local database
            var tsQuery = "SELECT DISTINCT account_id, user_id FROM account_analytic_line_app WHERE (status IS NULL OR status != 'deleted') AND user_id IS NOT NULL AND user_id > 0 ";
            var tsParams = [];
            if (accountId !== -1 && accountId !== undefined && accountId !== null) {
                tsQuery += "AND account_id = ? ";
                tsParams.push(accountId);
            }

            var tsResult = tx.executeSql(tsQuery, tsParams);
            var localUsers = [];
            for (var i = 0; i < tsResult.rows.length; i++) {
                var rowItem = tsResult.rows.item(i);
                var uKey = rowItem.account_id + ":" + rowItem.user_id;
                if (!seenIds[uKey]) {
                    seenIds[uKey] = true;
                    localUsers.push({ accountId: rowItem.account_id, userId: rowItem.user_id });
                }
            }

            // 2. Ensure current logged-in user for this account is included ("including own name")
            if (accountId !== -1 && accountId !== undefined && accountId !== null) {
                var loggedInUid = getCurrentUserOdooId(accountId);
                var lKey = accountId + ":" + loggedInUid;
                if (loggedInUid && loggedInUid > 0 && !seenIds[lKey]) {
                    seenIds[lKey] = true;
                    localUsers.push({ accountId: accountId, userId: loggedInUid });
                }
            } else {
                // For all accounts, include logged in user of every active account
                var accRes = tx.executeSql("SELECT id FROM users WHERE id > 0");
                for (var a = 0; a < accRes.rows.length; a++) {
                    var instAccId = accRes.rows.item(a).id;
                    var instLoggedInUid = getCurrentUserOdooId(instAccId);
                    var instKey = instAccId + ":" + instLoggedInUid;
                    if (instLoggedInUid && instLoggedInUid > 0 && !seenIds[instKey]) {
                        seenIds[instKey] = true;
                        localUsers.push({ accountId: instAccId, userId: instLoggedInUid });
                    }
                }
            }

            // 3. If user records were found from timesheets or logged-in user, enrich from res_users_app
            if (localUsers.length > 0) {
                for (var j = 0; j < localUsers.length; j++) {
                    var target = localUsers[j];
                    var uQuery = "SELECT (CASE WHEN account_id = 0 OR odoo_record_id IS NULL OR odoo_record_id <= 0 THEN id ELSE odoo_record_id END) AS user_id, " +
                        "name, login, email, work_email, avatar_128, account_id " +
                        "FROM res_users_app " +
                        "WHERE (odoo_record_id = ? OR (account_id = 0 AND id = ?)) ";
                    var uParams = [target.userId, target.userId];
                    if (target.accountId !== undefined && target.accountId !== null && target.accountId !== -1) {
                        uQuery += "AND account_id = ? ";
                        uParams.push(target.accountId);
                    }
                    uQuery += "LIMIT 1";

                    var uRes = tx.executeSql(uQuery, uParams);
                    if (uRes.rows.length > 0) {
                        var row = uRes.rows.item(0);
                        var accIdVal = row.account_id !== undefined ? row.account_id : target.accountId;
                        users.push({
                            id: target.userId,
                            name: row.name || row.login || getUserNameByOdooId(target.userId) || ("User #" + target.userId),
                            login: row.login || "",
                            email: row.email || row.work_email || "",
                            avatar: row.avatar_128 || "",
                            accountId: accIdVal,
                            account_id: accIdVal,
                            allUserIds: [target.userId]
                        });
                    } else {
                        users.push({
                            id: target.userId,
                            name: getUserNameByOdooId(target.userId) || ("User #" + target.userId),
                            login: "",
                            email: "",
                            avatar: "",
                            accountId: target.accountId,
                            account_id: target.accountId,
                            allUserIds: [target.userId]
                        });
                    }
                }
            } else {
                // 4. Fallback: If no timesheet records exist yet, fall back to active users from res_users_app
                var fallbackQuery = "SELECT (CASE WHEN account_id = 0 OR odoo_record_id IS NULL OR odoo_record_id <= 0 THEN id ELSE odoo_record_id END) AS user_id, " +
                    "name, login, email, work_email, avatar_128, account_id " +
                    "FROM res_users_app " +
                    "WHERE (active = 1 OR active IS NULL) ";
                var fallbackParams = [];
                if (accountId !== -1 && accountId !== undefined && accountId !== null) {
                    fallbackQuery += "AND account_id = ? ";
                    fallbackParams.push(accountId);
                }
                fallbackQuery += "ORDER BY name COLLATE NOCASE ASC";

                var fallbackRes = tx.executeSql(fallbackQuery, fallbackParams);
                for (var k = 0; k < fallbackRes.rows.length; k++) {
                    var fRow = fallbackRes.rows.item(k);
                    var fUid = fRow.user_id;
                    var fbKey = fRow.account_id + ":" + fUid;
                    if (!seenIds[fbKey]) {
                        seenIds[fbKey] = true;
                        users.push({
                            id: fUid,
                            name: fRow.name || fRow.login || ("User #" + fUid),
                            login: fRow.login || "",
                            email: fRow.email || fRow.work_email || "",
                            avatar: fRow.avatar_128 || "",
                            accountId: fRow.account_id,
                            account_id: fRow.account_id,
                            allUserIds: [fUid]
                        });
                    }
                }
            }

            // 5. If all accounts (-1), combine users by email across accounts
            if (accountId === -1 || accountId === "-1" || accountId === undefined || accountId === null) {
                users = combineUsersByEmail(users, tx);
            }

            // Sort alphabetically by name
            users.sort(function (a, b) {
                return (a.name || "").localeCompare(b.name || "", undefined, { sensitivity: "base" });
            });
        });
    } catch (e) {
        DBCommon.logException("getDashboardFilterUsers", e);
    }

    return users;
}

/**
 * Resolves the default user to display on the dashboard for a given account.
 * By default, the dashboard must display the currently logged-in user's personal metrics upon initial load,
 * regardless of access level (standard employee, manager, or admin).
 * Aggregated team data ("All Users") is only displayed when explicitly selected from the filter dropdown.
 *
 * @param {number} accountId - The account ID.
 * @param {Array<Object>} [availableUsers] - Optional pre-fetched users list.
 * @returns {Object|null} The default user object ({ id, name }), or null if none can be resolved.
 */
function getDashboardSingleUserDefault(accountId, availableUsers) {
    if (!availableUsers) {
        availableUsers = getDashboardFilterUsers(accountId);
    }

    var parsedAccountId = (accountId !== undefined && accountId !== null) ? parseInt(accountId, 10) : -1;

    // Local Account (0)
    if (parsedAccountId === 0) {
        if (availableUsers && availableUsers.length > 0) {
            return availableUsers[0];
        }
        return { id: 1, name: "Local User" };
    }

    // Instance Account (> 0): Always default to currently logged-in user
    if (parsedAccountId > 0) {
        var loggedInUid = getCurrentUserOdooId(parsedAccountId);
        if (loggedInUid && loggedInUid > 0) {
            if (availableUsers && availableUsers.length > 0) {
                for (var i = 0; i < availableUsers.length; i++) {
                    if (availableUsers[i].id === loggedInUid) {
                        return availableUsers[i];
                    }
                }
            }
            var userName = getUserNameByOdooId(loggedInUid);
            return {
                id: loggedInUid,
                name: userName || ("User #" + loggedInUid)
            };
        }
    }

    // All Accounts (-1): Try to default to currently logged-in user of default account or any active account
    if (parsedAccountId === -1) {
        var targetUid = -1;
        var defAccId = getDefaultRemoteAccountId();
        if (defAccId > 0) {
            targetUid = getCurrentUserOdooId(defAccId);
        }
        if (targetUid <= 0) {
            var allAccs = getActiveAccounts();
            for (var a = 0; a < allAccs.length; a++) {
                var aUid = getCurrentUserOdooId(allAccs[a].id);
                if (aUid > 0) {
                    targetUid = aUid;
                    break;
                }
            }
        }
        if (targetUid > 0 && availableUsers && availableUsers.length > 0) {
            for (var m = 0; m < availableUsers.length; m++) {
                var cand = availableUsers[m];
                if (cand.id === targetUid || (cand.allUserIds && cand.allUserIds.indexOf(targetUid) !== -1)) {
                    return cand;
                }
            }
        }
    }

    // Fallback if exactly one user's data exists
    if (availableUsers && availableUsers.length === 1) {
        return availableUsers[0];
    }

    return null;
}

/**
 * Checks whether the specified account grants manager or admin access.
 *
 * An account grants manager or admin access if:
 * 1. The account is an admin account (username or login is 'admin', or Odoo UID is 2).
 * 2. The user is a Project Manager on at least one active project in the account.
 * 3. The user has Timesheet/Team Manager access (timesheets belonging to other employees exist in the account).
 *
 * Standard access accounts (e.g. standard employees with no PM/admin rights,
 * and local offline accounts) return false.
 * For All Accounts (-1), returns true if any configured remote account grants manager/admin access.
 *
 * @param {number} accountId - The account ID (-1 for all accounts, 0 for local account).
 * @param {Object} [transaction] - Optional SQLite transaction to reuse.
 * @returns {boolean} True if manager or admin access is granted, false otherwise.
 */
function hasManagerOrAdminAccess(accountId, transaction) {
    var parsedAccountId = (accountId !== undefined && accountId !== null) ? parseInt(accountId, 10) : -1;
    if (parsedAccountId === 0) {
        return false;
    }

    if (transaction) {
        return _checkManagerOrAdminAccessTx(parsedAccountId, transaction);
    }

    var hasAccess = false;
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        db.transaction(function (tx) {
            hasAccess = _checkManagerOrAdminAccessTx(parsedAccountId, tx);
        });
    } catch (e) {
        DBCommon.logException("hasManagerOrAdminAccess", e);
    }
    return hasAccess;
}

function _checkManagerOrAdminAccessTx(accountId, tx) {
    if (accountId === 0) {
        return false;
    }

    // All Accounts (-1): Check if any active remote account grants manager/admin access
    if (accountId === -1) {
        var allAccs = tx.executeSql("SELECT id FROM users WHERE id > 0");
        for (var a = 0; a < allAccs.rows.length; a++) {
            var instId = allAccs.rows.item(a).id;
            if (_checkManagerOrAdminAccessTx(instId, tx)) {
                return true;
            }
        }
        return false;
    }

    // 1. Check if username on the account is 'admin'
    var accRes = tx.executeSql("SELECT username FROM users WHERE id = ?", [accountId]);
    var username = "";
    if (accRes.rows.length > 0) {
        username = accRes.rows.item(0).username || "";
        if (username.toLowerCase() === "admin") {
            return true;
        }
    }

    // 2. Resolve current user's Odoo UID and check if user login is 'admin' or UID is 2
    var currentUid = null;
    if (username) {
        var uRes = tx.executeSql(
            "SELECT odoo_record_id, login FROM res_users_app WHERE (login = ? OR email = ? OR work_email = ?) AND account_id = ? LIMIT 1",
            [username, username, username, accountId]
        );
        if (uRes.rows.length > 0) {
            var uRow = uRes.rows.item(0);
            currentUid = uRow.odoo_record_id;
            var uLogin = uRow.login || "";
            if (uLogin.toLowerCase() === "admin") {
                return true;
            }
        }
    }

    if (!currentUid) {
        currentUid = getCurrentUserOdooId(accountId);
    }

    if (currentUid === 2) {
        return true;
    }

    // 3. Check if user is a Project Manager on any active project for this account
    if (currentUid && currentUid > 0) {
        var pmRes = tx.executeSql(
            "SELECT COUNT(*) AS cnt FROM project_project_app WHERE account_id = ? AND (status IS NULL OR status != 'deleted') AND (user_id = ? OR user_id = CAST(? AS TEXT))",
            [accountId, currentUid, currentUid]
        );
        if (pmRes.rows.length > 0 && pmRes.rows.item(0).cnt > 0) {
            return true;
        }
    }

    // 4. Check if user has Timesheet/Team Manager access (timesheets of other employees exist)
    if (currentUid && currentUid > 0) {
        var teamRes = tx.executeSql(
            "SELECT COUNT(*) AS cnt FROM account_analytic_line_app WHERE account_id = ? AND (status IS NULL OR status != 'deleted') AND user_id IS NOT NULL AND user_id > 0 AND user_id != ?",
            [accountId, currentUid]
        );
        if (teamRes.rows.length > 0 && teamRes.rows.item(0).cnt > 0) {
            return true;
        }
    } else {
        var tsRes = tx.executeSql(
            "SELECT COUNT(DISTINCT user_id) AS cnt FROM account_analytic_line_app WHERE account_id = ? AND (status IS NULL OR status != 'deleted') AND user_id IS NOT NULL AND user_id > 0",
            [accountId]
        );
        if (tsRes.rows.length > 0 && tsRes.rows.item(0).cnt > 1) {
            return true;
        }
    }

    return false;
}

/**
 * Retrieves the Odoo model ID (`odoo_record_id`) from the local SQLite database
 * based on the given account ID and technical model name.
 *
 * @function getOdooModelId
 * @param {number} accountId - The local account ID associated with the Odoo connection.
 * @param {string} technicalName - The technical name of the Odoo model (e.g., "project.task").
 * @returns {number|null} - Returns the Odoo model ID if found, or null if not found or on error.
 *
 * @description
 * Opens a local SQLite database transaction and queries the `ir_model_app` table
 * for a record matching the provided `accountId` and `technicalName`.
 * If a matching record is found, the function returns the `odoo_record_id`.
 * Logs a warning if no matching record is found, and logs any exceptions
 * via `DBCommon.logException()` for error tracking.
 */
function getOdooModelId(accountId, technicalName) {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        var odooRecordId = null;

        db.transaction(function (tx) {
            var rs = tx.executeSql(
                "SELECT odoo_record_id FROM ir_model_app WHERE account_id = ? AND technical_name = ?",
                [accountId, technicalName]
            );

            if (rs.rows.length > 0) {
                odooRecordId = rs.rows.item(0).odoo_record_id;
                //  console.log("Found Odoo Model ID:", odooRecordId);
            } else {
                Logger.warn("Accounts", "No matching ir.model found for:", technicalName)
            }
        });

        return odooRecordId;
    } catch (e) {
        DBCommon.logException("getOdooModelId", e);
        return null;
    }
}
function clearDefaultAccount() {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        db.transaction(function (tx) {
            tx.executeSql("UPDATE users SET is_default = 0");
        });
    } catch (e) {
        DBCommon.logException(e);
    }
}

/**
 * Updates the per-account sync settings for a given account.
 * Pass null to reset a value to the global default.
 *
 * @param {number} accountId - The ID of the account to update.
 * @param {number|null} intervalMinutes - Sync interval in minutes, or null for global default.
 * @param {string|null} direction - "both", "download_only", "upload_only", or null for global default.
 * @param {number|null} enabled - 1 (enabled), 0 (disabled), or null for global default.
 */
function updateAccountSyncSettings(accountId, intervalMinutes, direction, enabled) {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        db.transaction(function (tx) {
            tx.executeSql(
                'UPDATE users SET sync_interval_minutes = ?, sync_direction = ?, autosync_enabled = ? WHERE id = ?',
                [intervalMinutes, direction, enabled, accountId]
            );
        });
        DBCommon.log("Updated sync settings for account " + accountId +
            ": interval=" + intervalMinutes + ", direction=" + direction + ", enabled=" + enabled);
    } catch (e) {
        DBCommon.logException("updateAccountSyncSettings", e);
    }
}

/**
 * Retrieves the per-account sync settings for a given account.
 *
 * @param {number} accountId - The ID of the account.
 * @returns {object} - Object with sync_interval_minutes, sync_direction, autosync_enabled (null if using global defaults).
 */
function getAccountSyncSettings(accountId) {
    var result = {
        sync_interval_minutes: null,
        sync_direction: null,
        autosync_enabled: null
    };

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        db.transaction(function (tx) {
            var rs = tx.executeSql(
                'SELECT sync_interval_minutes, sync_direction, autosync_enabled FROM users WHERE id = ?',
                [accountId]
            );
            if (rs.rows.length > 0) {
                var row = rs.rows.item(0);
                result.sync_interval_minutes = row.sync_interval_minutes;
                result.sync_direction = row.sync_direction;
                result.autosync_enabled = row.autosync_enabled;
            }
        });
    } catch (e) {
        DBCommon.logException("getAccountSyncSettings", e);
    }

    return result;
}

/**
 * Updates the last_synced_at timestamp for a given account.
 *
 * @param {number} accountId - The ID of the account.
 */
function updateLastSyncedAt(accountId) {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        db.transaction(function (tx) {
            tx.executeSql(
                "UPDATE users SET last_synced_at = datetime('now') WHERE id = ?",
                [accountId]
            );
        });
    } catch (e) {
        DBCommon.logException("updateLastSyncedAt", e);
    }
}
