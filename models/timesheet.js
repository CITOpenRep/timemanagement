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
    var result = { success: false, error: "" };

    try {
        db.transaction(function (tx) {
            var unitAmount = data.isManualTimeRecord
                    ? Utils.convertDurationToFloat(data.manualSpentHours)
                    : Utils.convertDurationToFloat(data.spenthours);

            if (data.id && data.id > 0) {
             //   console.log("✏Updating timesheet id:", data.id);
                tx.executeSql(`UPDATE account_analytic_line_app SET
                              account_id = ?, record_date = ?, project_id = ?, task_id = ?, name = ?,
                              sub_project_id = ?, sub_task_id = ?, quadrant_id = ?, unit_amount = ?,
                              last_modified = ?, status = ?, user_id = ? WHERE id = ?`,
                              [data.instance_id, data.record_date, data.project, data.task, data.description,
                               data.subprojectId, data.subTask, data.quadrant, unitAmount, timestamp,
                               data.status, data.user_id, data.id]);
            } else {
               // console.log("Inserting new timesheet entry");
                tx.executeSql(`INSERT INTO account_analytic_line_app
                              (account_id, record_date, project_id, task_id, name, sub_project_id,
                              sub_task_id, quadrant_id, unit_amount, last_modified, status, user_id)
                              VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
                              [data.instance_id, data.record_date, data.project, data.task, data.description,
                               data.subprojectId, data.subTask, data.quadrant, unitAmount, timestamp,
                               data.status, data.user_id]);
            }

            result.success = true;
        });
    } catch (err) {
        result.error = err.message;
    }

    return result;
}
