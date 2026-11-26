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
.import "logger.js" as Logger

/*Database Constants*/
const NAME = "myDatabase";
const VERSION = "1.0";
const DISPLAY_NAME = "My Database";
const SIZE = 1000000;

// Helpers
function logException(tag, error) {
    var errMsg = (error && error.message ? error.message : error);
    Logger.error("Database", "[" + tag + "] " + errMsg);
}

function log(message) {
    Logger.debug("Database", message);
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
                "SELECT id FROM users WHERE id = 0 OR name = ? OR name = ?",
                ["Local Account", "Local"]
            );

            if (result.rows.length === 0) {
                tx.executeSql(
                    "INSERT INTO users (id, name, link, last_modified, database, connectwith_id, api_key, username, is_default) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                    [
                        0,
                        "Local",
                        "local://",
                        new Date().toISOString(),
                        "local",
                        null,
                        null,
                        "local_user",
                        1
                    ]
                );
            } else {
                tx.executeSql(
                    "UPDATE users SET name = 'Local' WHERE id = 0 AND name = 'Local Account'"
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

        ensureDefaultLocalProjectStages();
        ensureDefaultLocalTaskStages();
    } catch (e) {
        logException(e);
    }
}

/**
 * Ensures default activity types exist for the Local Account.
 *
 * Local accounts do not sync activity types from Odoo, so provide
 * a predefined set of activity types during database initialization.
 */
function ensureDefaultLocalActivityTypes() {
    const defaultTypes = ["To Do", "Call", "Email", "Meeting"];

    try {
        const db = Sql.LocalStorage.openDatabaseSync(NAME, VERSION, DISPLAY_NAME, SIZE);

        db.transaction(function (tx) {
            defaultTypes.forEach(function (typeName, index) {
                const result = tx.executeSql(
                    "SELECT id FROM mail_activity_type_app WHERE account_id = ? AND name = ? AND (status IS NULL OR status != 'deleted')",
                    [0, typeName]
                );

                if (result.rows.length === 0) {
                    tx.executeSql(
                        "INSERT INTO mail_activity_type_app (account_id, name, status, odoo_record_id) VALUES (?, ?, ?, ?)",
                        [0, typeName, "", -(index + 1)]
                    );
                }
            });
        });
    } catch (e) {
        logException("ensureDefaultLocalActivityTypes", e);
    }
}

/**
 * Ensures default project stages exist for the Local Account.
 *
 * Local accounts do not sync project stages from Odoo, so provide
 * a predefined set of project stages during database initialization.
 */
function ensureDefaultLocalProjectStages() {
    const defaultStages = [
        { name: "Planning", sequence: 10, fold: 0, odoo_record_id: -1 },
        { name: "In Progress", sequence: 20, fold: 0, odoo_record_id: -2 },
        { name: "Completed", sequence: 30, fold: 1, odoo_record_id: -3 },
        { name: "Cancelled", sequence: 40, fold: 1, odoo_record_id: -4 }
    ];

    try {
        const db = Sql.LocalStorage.openDatabaseSync(NAME, VERSION, DISPLAY_NAME, SIZE);
        const timestamp = new Date().toISOString();

        db.transaction(function (tx) {
            defaultStages.forEach(function (stage) {
                const result = tx.executeSql(
                    "SELECT id FROM project_project_stage_app WHERE account_id = ? AND odoo_record_id = ?",
                    [0, stage.odoo_record_id]
                );

                if (result.rows.length === 0) {
                    tx.executeSql(
                        "INSERT INTO project_project_stage_app (account_id, odoo_record_id, name, sequence, fold, active, create_date, write_date, status) VALUES (?, ?, ?, ?, ?, 1, ?, ?, '')",
                        [0, stage.odoo_record_id, stage.name, stage.sequence, stage.fold, timestamp, timestamp]
                    );
                }
            });

            // Safe migration: Set initial stage (-1, Planning) for local projects without stage
            tx.executeSql(
                "UPDATE project_project_app SET stage = -1 WHERE account_id = 0 AND (stage IS NULL OR stage = 0)"
            );
        });
    } catch (e) {
        logException("ensureDefaultLocalProjectStages", e);
    }
}

/**
 * Ensures default task stages exist for the Local Account.
 *
 * Local accounts do not sync task types/stages from Odoo, so provide
 * a predefined set of global task stages during database initialization.
 */
function ensureDefaultLocalTaskStages() {
    const defaultStages = [
        { name: "New", sequence: 1, fold: 0, odoo_record_id: -1 },
        { name: "In Progress", sequence: 2, fold: 0, odoo_record_id: -2 },
        { name: "Done", sequence: 3, fold: 1, odoo_record_id: -3 },
        { name: "Cancelled", sequence: 4, fold: 1, odoo_record_id: -4 }
    ];

    try {
        const db = Sql.LocalStorage.openDatabaseSync(NAME, VERSION, DISPLAY_NAME, SIZE);
        const timestamp = new Date().toISOString();

        db.transaction(function (tx) {
            defaultStages.forEach(function (stage) {
                const result = tx.executeSql(
                    "SELECT id FROM project_task_type_app WHERE account_id = ? AND odoo_record_id = ?",
                    [0, stage.odoo_record_id]
                );

                if (result.rows.length === 0) {
                    tx.executeSql(
                        "INSERT INTO project_task_type_app (account_id, odoo_record_id, name, sequence, fold, is_global, active, create_date, write_date, status) VALUES (?, ?, ?, ?, ?, 1, 1, ?, ?, '')",
                        [0, stage.odoo_record_id, stage.name, stage.sequence, stage.fold, timestamp, timestamp]
                    );
                }
            });

            // Safe migration: Set initial stage (-1, New) for local tasks without state
            tx.executeSql(
                "UPDATE project_task_app SET state = -1 WHERE account_id = 0 AND (state IS NULL OR state = 0 OR state = '' OR state = '0')"
            );
        });
    } catch (e) {
        logException("ensureDefaultLocalTaskStages", e);
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
        console.warn("rowToObject: Invalid row input", row);
        return obj;
    }

    for (var key in row) {
        if (Object.prototype.hasOwnProperty.call(row, key)) {
            obj[key] = row[key] === undefined ? null : row[key];
        }
    }

    return obj;
}

function _isEmptySyncValue(val) {
    return val === null || val === undefined || val === "";
}

/**
 * Compares existing persisted row values against incoming column values and
 * returns the list of columns that actually changed.
 *
 * @param {object} oldRow - Existing SQLite row before UPDATE
 * @param {object} newValues - Map of sqliteColumnName -> newValue
 * @returns {Array<string>|null}
 */
function computeDirtyFields(oldRow, newValues) {
    if (!oldRow || !newValues) {
        return null;
    }
    var dirty = [];
    for (var col in newValues) {
        if (!Object.prototype.hasOwnProperty.call(newValues, col)) {
            continue;
        }
        var oldVal = oldRow[col];
        var newVal = newValues[col];
        if (_isEmptySyncValue(oldVal) && _isEmptySyncValue(newVal)) {
            continue;
        }
        if (oldVal === newVal) {
            continue;
        }
        if (oldVal !== null && oldVal !== undefined && newVal !== null && newVal !== undefined) {
            if (typeof oldVal === "number" || typeof newVal === "number") {
                var oldNum = Number(oldVal);
                var newNum = Number(newVal);
                if (!isNaN(oldNum) && !isNaN(newNum) && oldNum === newNum) {
                    continue;
                }
            }
            if (String(oldVal) === String(newVal)) {
                continue;
            }
        }
        dirty.push(col);
    }
    return dirty;
}

function _normalizeDirtyInput(dirtyInput) {
    if (!dirtyInput) {
        return { fields: null, base: null };
    }
    if (Array.isArray(dirtyInput)) {
        return { fields: dirtyInput, base: null };
    }
    if (typeof dirtyInput === "object" && Array.isArray(dirtyInput.fields)) {
        return {
            fields: dirtyInput.fields,
            base: (dirtyInput.base && typeof dirtyInput.base === "object") ? dirtyInput.base : null
        };
    }
    return { fields: null, base: null };
}

/**
 * Atomically increments mutation_seq on the target table and inserts or coalesces
 * a pending outbox job in sync_queue inside the caller's active transaction.
 *
 * Supports 3-way merge by preserving the earliest pre-edit baseline value for each dirty field.
 *
 * @param {object} tx - Active Sql.LocalStorage transaction object
 * @param {object} params - { accountId, modelName, tableName, localId, operation, dirtyFields, baseValues, odooRecordId }
 */
function enqueueSyncOperation(tx, params) {
    if (!tx || !params) {
        return;
    }
    var accountId = parseInt(params.accountId, 10);
    if (isNaN(accountId) || accountId <= 0) {
        return;
    }
    var localId = parseInt(params.localId, 10);
    if (isNaN(localId) || localId <= 0) {
        return;
    }

    var modelName = params.modelName;
    var tableName = params.tableName;
    var operation = params.operation || "upsert";
    var normInput = _normalizeDirtyInput(params.dirtyFields);
    var incomingFields = normInput.fields;
    var incomingBase = (params.baseValues && typeof params.baseValues === "object") ? params.baseValues : normInput.base;

    try {
        tx.executeSql(
            "UPDATE " + tableName + " SET mutation_seq = COALESCE(mutation_seq, 0) + 1 WHERE id = ?",
            [localId]
        );

        var rowRs = tx.executeSql(
            "SELECT odoo_record_id, base_write_date, COALESCE(mutation_seq, 1) AS seq FROM " + tableName + " WHERE id = ? LIMIT 1",
            [localId]
        );
        if (rowRs.rows.length === 0) {
            return;
        }
        var row = rowRs.rows.item(0);
        var odooRecordId = row.odoo_record_id || params.odooRecordId || null;
        var baseWriteDate = row.base_write_date || null;
        var queuedSeq = row.seq || 1;

        // If deleting an item that never reached Odoo, drop any pending queue entry cleanly.
        if (operation === "delete" && (!odooRecordId || odooRecordId <= 0)) {
            tx.executeSql(
                "DELETE FROM sync_queue WHERE account_id = ? AND model_name = ? AND local_id = ?",
                [accountId, modelName, localId]
            );
            return;
        }

        var existingRs = tx.executeSql(
            "SELECT operation, dirty_fields, base_write_date, status FROM sync_queue WHERE account_id = ? AND model_name = ? AND local_id = ? LIMIT 1",
            [accountId, modelName, localId]
        );

        var mergedDirtyJson = null;
        var fieldSet = {};
        var mergedBase = {};
        var hasMergedBase = false;
        var keepAllFields = false;

        if (existingRs.rows.length > 0) {
            var existing = existingRs.rows.item(0);
            if (!baseWriteDate && existing.base_write_date) {
                baseWriteDate = existing.base_write_date;
            }
            if (operation === "delete") {
                mergedDirtyJson = null;
            } else if (incomingFields !== null) {
                if (existing.dirty_fields) {
                    try {
                        var prevParsed = JSON.parse(existing.dirty_fields);
                        if (Array.isArray(prevParsed)) {
                            for (var p = 0; p < prevParsed.length; p++) {
                                fieldSet[prevParsed[p]] = true;
                            }
                        } else if (prevParsed && typeof prevParsed === "object" && Array.isArray(prevParsed.fields)) {
                            for (var pf = 0; pf < prevParsed.fields.length; pf++) {
                                fieldSet[prevParsed.fields[pf]] = true;
                            }
                            if (prevParsed.base && typeof prevParsed.base === "object") {
                                for (var bk in prevParsed.base) {
                                    if (Object.prototype.hasOwnProperty.call(prevParsed.base, bk)) {
                                        mergedBase[bk] = prevParsed.base[bk];
                                        hasMergedBase = true;
                                    }
                                }
                            }
                        } else {
                            keepAllFields = true;
                        }
                    } catch (parseErr) {
                        keepAllFields = true;
                    }
                } else if (existing.status === "pending" || existing.status === "in_flight" || existing.status === "failed") {
                    keepAllFields = true;
                }

                if (!keepAllFields) {
                    for (var i = 0; i < incomingFields.length; i++) {
                        var fName = incomingFields[i];
                        fieldSet[fName] = true;
                        // Keep earliest baseline value if this field was already edited offline earlier
                        if (incomingBase && Object.prototype.hasOwnProperty.call(incomingBase, fName) &&
                            !Object.prototype.hasOwnProperty.call(mergedBase, fName)) {
                            mergedBase[fName] = incomingBase[fName];
                            hasMergedBase = true;
                        }
                    }
                    var mergedKeys = Object.keys(fieldSet);
                    mergedDirtyJson = hasMergedBase
                        ? JSON.stringify({ fields: mergedKeys, base: mergedBase })
                        : JSON.stringify(mergedKeys);
                }
            }

            tx.executeSql(
                "UPDATE sync_queue SET odoo_record_id = COALESCE(?, odoo_record_id), operation = ?, dirty_fields = ?, " +
                "base_write_date = COALESCE(?, base_write_date), queued_seq = ?, status = 'pending', " +
                "retry_count = 0, next_retry_at = NULL, last_error = NULL, updated_at = datetime('now') " +
                "WHERE account_id = ? AND model_name = ? AND local_id = ?",
                [odooRecordId, operation, mergedDirtyJson, baseWriteDate, queuedSeq, accountId, modelName, localId]
            );
        } else {
            if (operation !== "delete" && incomingFields !== null) {
                if (incomingBase) {
                    var initBase = {};
                    var anyBase = false;
                    for (var j = 0; j < incomingFields.length; j++) {
                        var colKey = incomingFields[j];
                        if (Object.prototype.hasOwnProperty.call(incomingBase, colKey)) {
                            initBase[colKey] = incomingBase[colKey];
                            anyBase = true;
                        }
                    }
                    mergedDirtyJson = anyBase
                        ? JSON.stringify({ fields: incomingFields, base: initBase })
                        : JSON.stringify(incomingFields);
                } else {
                    mergedDirtyJson = JSON.stringify(incomingFields);
                }
            }
            tx.executeSql(
                "INSERT INTO sync_queue (account_id, model_name, table_name, local_id, odoo_record_id, operation, dirty_fields, base_write_date, queued_seq, status, retry_count, next_retry_at, last_error, created_at, updated_at) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', 0, NULL, NULL, datetime('now'), datetime('now'))",
                [accountId, modelName, tableName, localId, odooRecordId, operation, mergedDirtyJson, baseWriteDate, queuedSeq]
            );
        }
    } catch (e) {
        Logger.warn("Database", "enqueueSyncOperation failed for " + tableName + "#" + localId + ": " + e);
    }
}
