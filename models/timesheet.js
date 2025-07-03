.import QtQuick.LocalStorage 2.7 as Sql
.import "database.js" as DBCommon
.import "utils.js" as Utils


/**
 * Retrieves all non-deleted timesheet entries from the local SQLite database.
 *
 * Joins related data from `project_project_app`, `users`, `res_users_app`, and `project_task_app`
 * to enrich the timesheet list with human-readable project, task, instance, and user names.
 *
 * @returns {Array<Object>} - A list of enriched timesheet entries.
 */
function fetch_timesheets() {
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var timesheetList = [];

    try {
        db.transaction(function (tx) {
            var result = tx.executeSql(
                        "SELECT * FROM account_analytic_line_app WHERE (status IS NULL OR status != 'deleted') ORDER BY last_modified DESC"
                        );

            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);

                var quadrantMap = {
                    0: "Unknown",
                    1: "Do",
                    2: "Plan",
                    3: "Delegate",
                    4: "Delete"
                };

                var projectResult = tx.executeSql("SELECT name FROM project_project_app WHERE odoo_record_id = ?", [row.project_id]);
                var taskResult = tx.executeSql("SELECT name FROM project_task_app WHERE odoo_record_id = ?", [row.task_id]);
                var instanceResult = tx.executeSql("SELECT name FROM users WHERE id = ?", [row.account_id]);
                var userResult = tx.executeSql("SELECT name FROM res_users_app WHERE odoo_record_id = ?", [row.user_id]);

                timesheetList.push({
                                       id: row.id,
                                       instance: instanceResult.rows.length > 0 ? instanceResult.rows.item(0).name : '',
                                       name: row.name || '',
                                       spentHours: Utils.convertFloatToTime(row.unit_amount),
                                       project: projectResult.rows.length > 0 ? projectResult.rows.item(0).name : 'Unknown Project',
                                       quadrant: quadrantMap[row.quadrant_id] || "Unknown",
                                       date: row.record_date,
                                       status: row.status,
                                       task: taskResult.rows.length > 0 ? taskResult.rows.item(0).name : 'Unknown Task',
                                       user: userResult.rows.length > 0 ? userResult.rows.item(0).name : ''
                                   });
            }
        });
    } catch (e) {
        DBCommon.logException("fetch_timesheets", e);
    }

    return timesheetList;
}

function fetch_active_timesheets() {
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var timesheetList = [];

    try {
        db.transaction(function (tx) {
            var result = tx.executeSql(
                "SELECT * FROM account_analytic_line_app " +
                "WHERE (status = 'draft') " +
                "ORDER BY last_modified DESC"
            );

            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);

                var quadrantMap = {
                    0: "Unknown",
                    1: "Do",
                    2: "Plan",
                    3: "Delegate",
                    4: "Delete"
                };

                var projectResult = tx.executeSql(
                    "SELECT name FROM project_project_app WHERE odoo_record_id = ?",
                    [row.project_id]
                );
                var taskResult = tx.executeSql(
                    "SELECT name FROM project_task_app WHERE odoo_record_id = ?",
                    [row.task_id]
                );
                var instanceResult = tx.executeSql(
                    "SELECT name FROM users WHERE id = ?",
                    [row.account_id]
                );
                var userResult = tx.executeSql(
                    "SELECT name FROM res_users_app WHERE odoo_record_id = ?",
                    [row.user_id]
                );

                timesheetList.push({
                    id: row.id,
                    instance: instanceResult.rows.length > 0 ? instanceResult.rows.item(0).name : '',
                    name: row.name || '',
                    spentHours: Utils.convertFloatToTime(row.unit_amount),
                    project: projectResult.rows.length > 0 ? projectResult.rows.item(0).name : 'Unknown Project',
                    quadrant: quadrantMap[row.quadrant_id] || "Unknown",
                    date: row.record_date,
                    status: row.status,
                    task: taskResult.rows.length > 0 ? taskResult.rows.item(0).name : 'Unknown Task',
                    user: userResult.rows.length > 0 ? userResult.rows.item(0).name : ''
                });
            }
        });
    } catch (e) {
        DBCommon.logException("fetch_active_timesheets", e);
    }

    return timesheetList;
}

function getTimesheetNameById(timesheetId) {
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var name = "";
    try {
        db.transaction(function (tx) {
            var rs = tx.executeSql("SELECT name FROM account_analytic_line_app WHERE id = ?", [timesheetId]);
            if (rs.rows.length > 0) {
                name = rs.rows.item(0).name;
            }
        });
    } catch (e) {
        DBCommon.logException("getTimesheetNameById", e);
    }
    return name;
}


/**
 * Marks a timesheet entry as deleted in the local SQLite database by setting its `status` to `'deleted'`.
 *
 * This is a soft delete and does not remove the record from the database.
 *
 * @param {number} taskId - The ID of the timesheet entry to be marked as deleted.
 * @returns {Object} - An object with `success` (boolean) and `message` (string) indicating the result.
 */
function markTimesheetAsDeleted(taskId) {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            tx.executeSql(
                        "UPDATE account_analytic_line_app SET status = 'deleted' WHERE id = ?",
                        [taskId]
                        );
        });

        DBCommon.log("Timesheet marked as deleted (id: " + taskId + ")");
        return { success: true, message: "Timesheet marked as deleted." };

    } catch (e) {
        DBCommon.logException("markTimesheetAsDeleted", e);
        return { success: false, message: "Failed to mark as deleted: " + e.message };
    }
}

/**
 * Retrieves details of a specific timesheet entry by its local database ID.
 *
 * The returned object includes project/task associations, recorded hours,
 * quadrant classification, and a formatted record date.
 *
 * @param {number} record_id - The local database ID of the timesheet entry.
 * @returns {Object} - A timesheet detail object, or an empty object if not found.
 */
function getTimeSheetDetails(record_id) {
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var timesheet_detail = {};
    db.transaction(function (tx) {
        var timesheet = tx.executeSql('SELECT * FROM account_analytic_line_app\
                                    WHERE id = ?', [record_id]);
        if (timesheet.rows.length) {
            timesheet_detail = {
                'instance_id': timesheet.rows.item(0).account_id,
                'project_id': timesheet.rows.item(0).project_id,
                'sub_project_id': timesheet.rows.item(0).sub_project_id,
                'task_id': timesheet.rows.item(0).task_id,
                'sub_task_id': timesheet.rows.item(0).sub_task_id,
                'name': timesheet.rows.item(0).name,
                'spentHours': Utils.convertFloatToTime(timesheet.rows.item(0).unit_amount),
                'quadrant_id': timesheet.rows.item(0).quadrant_id,
                'record_date': Utils.formatDate(new Date(timesheet.rows.item(0).record_date))
            };
        }
    });
    return timesheet_detail;
}

/**
 * Creates a new timesheet entry or updates an existing one in the local SQLite database.
 *
 * The function decides whether to insert or update based on the presence of a valid `id` in `data`.
 * Duration is parsed based on whether the entry is manually recorded or tracked automatically.
 *
 * @param {Object} data - An object representing the timesheet fields:
 *                        - `id`, `instance_id`, `record_date`, `project`, `task`, `description`,
 *                        - `subprojectId`, `subTask`, `quadrant`, `spenthours`, `manualSpentHours`,
 *                        - `isManualTimeRecord`, `status`, `user_id`
 * @returns {Object} - An object containing `success` (boolean) and `error` (string, if any).
 */
function createOrSaveTimesheet(data) {
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var timestamp = Utils.getFormattedTimestampUTC();
    var result = { success: false, error: "", id: null };

    try {
        db.transaction(function (tx) {
            var unitAmount = data.isManualTimeRecord
                ? Utils.convertDurationToFloat(data.manualSpentHours)
                : Utils.convertDurationToFloat(data.spenthours);

            if (data.id && data.id > 0) {
                // Updating existing timesheet
                tx.executeSql(`UPDATE account_analytic_line_app SET
                              account_id = ?, record_date = ?, project_id = ?, task_id = ?, name = ?,
                              sub_project_id = ?, sub_task_id = ?, quadrant_id = ?, unit_amount = ?,
                              last_modified = ?, status = ?, user_id = ? WHERE id = ?`,
                    [data.instance_id, data.record_date, data.project, data.task, data.description,
                        data.subprojectId, data.subTask, data.quadrant, unitAmount, timestamp,
                        data.status, data.user_id, data.id]);

                result.success = true;
                result.id = data.id; // return the updated ID
            } else {
                // Inserting new timesheet entry
                tx.executeSql(`INSERT INTO account_analytic_line_app
                              (account_id, record_date, project_id, task_id, name, sub_project_id,
                              sub_task_id, quadrant_id, unit_amount, last_modified, status, user_id)
                              VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
                    [data.instance_id, data.record_date, data.project, data.task, data.description,
                        data.subprojectId, data.subTask, data.quadrant, unitAmount, timestamp,
                        data.status, data.user_id]);

                // Retrieve the last inserted ID
                var rs = tx.executeSql("SELECT last_insert_rowid() as id");
                if (rs.rows.length > 0) {
                    result.id = rs.rows.item(0).id;
                }

                result.success = true;
            }
        });
    } catch (err) {
        result.error = err.message;
    }

    return result;
}

/**
 * Creates a new timesheet entry from a given task by directly querying the local SQLite task table,
 * then inserting using createOrSaveTimesheet.
 *
 * @param {number} taskRecordId - The ID of the task to link to the new timesheet.
 * @returns {Object} - { success: boolean, id: number | null, error: string }
 */
function createTimesheetFromTask(taskRecordId) {
    console.log("Creating time sheet for "+ taskRecordId)
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var result = { success: false, id: null, error: "" };

    try {
        if (!taskRecordId || taskRecordId <= 0) {
            result.error = "Invalid taskRecordId provided.";
            return result;
        }

        var task = null;
        db.readTransaction(function(tx) {
            var rs = tx.executeSql("SELECT * FROM project_task_app WHERE id = ?", [taskRecordId]);
            if (rs.rows.length > 0) {
                task = rs.rows.item(0);
            }
        });

        if (!task) {
            result.error = "Task not found in local DB.";
            return result;
        }
        console.log("Content of tasks")
        for (var key in task) {
               console.log("   " + key + ": " + task[key]);
           }

        if (!task.project_id || !task.account_id) {
            result.error = "Task missing required project/account linkage.";
            return result;
        }

        var today = Qt.formatDate(new Date(), "yyyy-MM-dd");

        var timesheet_data = {
            'instance_id': task.account_id,
            'record_date': today,
            'project': task.project_id,
            'task': task.odoo_record_id || -1,
            'subprojectId': -1,
            'subTask': -1,
            'description': "Timesheet (" + today + ") " + (task.name || ""),
            'manualSpentHours': "00:00",
            'spenthours': "00:00",
            'isManualTimeRecord': false,
            'quadrant': 0,
            'status': "draft",
            'user_id': task.user_id
        };

        console.log("Prepared timesheet_data for creation:");
        for (var key in timesheet_data) {
            console.log("   " + key + ": " + timesheet_data[key]);
        }

        var tsResult = createOrSaveTimesheet(timesheet_data);

        if (tsResult.success) {
            result.success = true;
            result.id = tsResult.id;
        } else {
            result.error = tsResult.error || "Unknown error during timesheet creation.";
        }
    } catch (e) {
        result.error = e.toString();
    }

    return result;
}

function updateTimesheetWithDuration(timesheetId, durationHours) {
    console.log("Updating time sheet " + timesheetId + "with the hours" + durationHours)
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var timestamp = Utils.getFormattedTimestampUTC();
    try {
        db.transaction(function(tx) {
            tx.executeSql("UPDATE account_analytic_line_app SET unit_amount = ?, last_modified = ? WHERE id = ?",
                          [durationHours, timestamp, timesheetId]);
        });
    } catch (e) {
        console.log("updateTimesheetWithDuration failed:", e);
    }
}


function getTimesheetUnitAmount(timesheetId) {
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var unitAmount = 0;
    try {
        db.transaction(function(tx) {
            var rs = tx.executeSql("SELECT unit_amount FROM account_analytic_line_app WHERE id = ?", [timesheetId]);
            if (rs.rows.length > 0 && rs.rows.item(0).unit_amount !== null) {
                unitAmount = parseFloat(rs.rows.item(0).unit_amount);
            }
        });
    } catch (e) {
        DBCommon.logException("getTimesheetUnitAmount", e);
    }
    return unitAmount;
}
