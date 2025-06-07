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
    console.log("[" + getTimestamp() + "][ERROR][" + tag + "] " + (error && error.message ? error.message : error));
    if (error && error.stack) {
        console.log("   ↪ Stack Trace:\n" + error.stack);
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
