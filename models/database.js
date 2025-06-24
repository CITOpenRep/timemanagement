/*
 * MIT License
 *
 * Copyright (c) 2025 CIT-Services
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

/*
 * database.js
 * -----------------------------------------------------------------------------
 * This module provides a centralized, reusable set of database utility functions
 * for interacting with the local SQLite database in the Ubuntu Touch Time Management App.
 *
 * PURPOSE:
 * - Encapsulate all SQLite access logic in one place for consistency and maintainability.
 * - Reduce redundancy by reusing a shared, globally-initialized database connection.
 * - Promote safe and error-tolerant data access patterns using try/catch wrappers.
 * - Standardize logging for easier debugging.
 *
 * USAGE:
 * - Call utility functions like `getTasksForAccountAndProject()` or `getProjects()`
 *   directly from QML or JavaScript modules.
 * - All database functions must use the global `db` instance and handle exceptions internally.
 * - Use `logException()` and `logQueryResult()` for consistent debug output.
 * - Always validate input parameters before executing SQL.
 *
 * CONTRIBUTION GUIDELINES:
 * - Use camelCase naming for all functions (e.g., `getTasksForProject()`).
 * - Wrap all database operations in try/catch and log errors using `logException(e)`.
 * - If returning result sets, format them into plain JS objects before returning.
 * - Add a JSDoc-style comment above each function describing its purpose, parameters, and return value.
 * - Do not directly expose raw SQL query strings outside this module.
 *
 * DATABASE CONFIG:
 * - The SQLite connection is initialized once globally using:
 *     const db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DISPLAY_NAME, DB_SIZE);
 *   These constants are defined at the top of this file for easy configuration.
 *
 * -----------------------------------------------------------------------------
 */

.import QtQuick.LocalStorage 2.7 as Sql

/*Database Constants*/
const NAME = "myDatabase";
const VERSION = "1.0";
const DISPLAY_NAME = "My Database";
const SIZE = 1000000;

// Helpers
function getTimestamp() {
    return new Date().toISOString();
}

function logException(tag, error) {
    console.warn("[" + getTimestamp() + "][ERROR][" + tag + "] " + (error && error.message ? error.message : error));
    if (error && error.stack) {
    //    console.log("   ↪ Stack Trace:\n" + error.stack);
    }
}

function log(message) {
    console.log("[" + getTimestamp() + "][Log] " + message);
}

function logQueryResult(tag, resultSet) {
    if (!resultSet || resultSet.rows.length === 0) {
        console.log("[" + tag + "] No rows returned.");
        return;
    }

    console.log("[" + tag + "] Rows: " + resultSet.rows.length);

    for (var i = 0; i < resultSet.rows.length; i++) {
        var row = resultSet.rows.item(i);
        var rowDetails = [];

        for (var key in row) {
            if (row.hasOwnProperty(key)) {
                rowDetails.push(key + ": " + JSON.stringify(row[key]));
            }
        }

        console.log("Row " + (i + 1) + ": { " + rowDetails.join(", ") + " }");
    }
}

//Helper End

/**
 * Ensures that the default "Local Account" (id: 0, name: "Local Account") exists in the users table.
 * If not found, it inserts a predefined local account entry.
 *
 * This account is used when working in personal/offline mode without any external Odoo instance.
 */
function ensureDefaultLocalAccountExists() {
    try {
        const db = Sql.LocalStorage.openDatabaseSync(NAME, VERSION, DISPLAY_NAME, SIZE);

        db.transaction(function (tx) {
            // Step 1: Ensure Local Account Exists
            const result = tx.executeSql(
                "SELECT id FROM users WHERE id = 0 OR name = ?",
                ["Local Account"]
            );

            if (result.rows.length === 0) {
                tx.executeSql(
                    "INSERT INTO users (id, name, link, last_modified, database, connectwith_id, api_key, username, is_default) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                    [
                        0,
                        "Local Account",
                        "local://",
                        new Date().toISOString(),
                        "local",
                        null,
                        null,
                        "local_user",
                        1
                    ]
                );
            }

            // Step 2: Ensure Local User Exists in res_users_app
            const userResult = tx.executeSql(
                "SELECT id FROM res_users_app WHERE account_id = ? AND odoo_record_id = ?",
                [0, -1]
            );

            if (userResult.rows.length === 0) {
                tx.executeSql(
                    "INSERT INTO res_users_app (account_id, name, login, email, work_email, mobile_phone, job_title, company_id, share, active, status, odoo_record_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                    [
                        0,                          // account_id
                        "Local User",               // name
                        "local_user",               // login
                        "",                         // email
                        "",                         // work_email
                        "",                         // mobile_phone
                        "Personal",                 // job_title
                        null,                       // company_id
                        0,                          // share
                        1,                          // active
                        "",                         // status
                        -1                          // odoo_record_id
                    ]
                );
            }
        });

    } catch (e) {
        logException(e);
    }
}

/**
 * Creates a table if it doesn't exist, and ensures all expected columns are present.
 *
 * - Executes the given `CREATE TABLE IF NOT EXISTS` SQL.
 * - Then compares existing columns against the `match_column_list`.
 * - Adds any missing columns using `ALTER TABLE`.
 *
 * @param {string} label - Logical name of the table (used for logging).
 * @param {string} createSQL - The full CREATE TABLE SQL statement.
 * @param {Array<string>} match_column_list - List of column definitions (e.g., "name TEXT").
 */
function createOrUpdateTable(label, createSQL, match_column_list) {
    try {
        const db = Sql.LocalStorage.openDatabaseSync(NAME, VERSION, DISPLAY_NAME, SIZE);

        db.transaction(function (tx) {
            tx.executeSql(createSQL);

            const result = tx.executeSql("PRAGMA table_info(" + label + ")");
            const existing_columns = [];

            for (let i = 0; i < result.rows.length; i++) {
                existing_columns.push(result.rows.item(i).name);
            }

            for (let j = 0; j < match_column_list.length; j++) {
                const column_name = match_column_list[j].split(" ")[0];
                if (!existing_columns.includes(column_name)) {
                    tx.executeSql("ALTER TABLE " + label + " ADD COLUMN " + match_column_list[j]);
                }
            }
        });

    } catch (e) {
        logException(e);
    }
}


/**
 * Converts a SQLite result row into a plain JS object dynamically.
 * @param {object} row - A row object from tx.executeSql().rows.item(i)
 * @returns {object} - Mapped plain object with all key-value pairs
 */
function rowToObject(row) {
    var obj = {};

    if (!row || typeof row !== 'object') {
        console.warn("⚠️ rowToObject: Invalid row input", row);
        return obj;
    }

    for (var key in row) {
        if (Object.prototype.hasOwnProperty.call(row, key)) {
            obj[key] = row[key] === undefined ? null : row[key];
        }
    }

    return obj;
}
