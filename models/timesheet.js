.import QtQuick.LocalStorage 2.7 as Sql
.import "database.js" as DBCommon
.import "utils.js" as Utils



/* Name: fetch_timesheets
* This function will return timesheets based on work state, this function is returning
* for timesheet list view
* is_work_state -> in case of work mode is enable
*/

function fetch_timesheets(is_work_state) {
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    var timesheetList = [];

    db.transaction(function (tx) {
        let timesheets;

        if (is_work_state) {
            timesheets = tx.executeSql(
                        "SELECT * FROM account_analytic_line_app WHERE account_id IS NOT NULL AND (status IS NULL OR status != 'deleted') ORDER BY last_modified DESC"
                        );
        } else {
            timesheets = tx.executeSql(
                        "SELECT * FROM account_analytic_line_app WHERE parent_id = 0 AND account_id IS NULL AND (status IS NULL OR status != 'deleted') ORDER BY last_modified DESC"
                        );
        }

        for (var i = 0; i < timesheets.rows.length; i++) {
            var row = timesheets.rows.item(i);

            var quadrantObj = {
                0: "Unknown",
                1: "Do",
                2: "Plan",
                3: "Delegate",
                4: "Delete"
            };
            //console.log("PROJECT ID IS  " + row.project_id)
            var project = tx.executeSql("SELECT name FROM project_project_app WHERE odoo_record_id = ?", [row.project_id]);
            var instance = tx.executeSql("SELECT name FROM users WHERE id = ?", [row.account_id]);
            var user = tx.executeSql("SELECT name FROM res_users_app WHERE odoo_record_id = ?", [row.user_id]);
            var task = tx.executeSql("SELECT name FROM project_task_app WHERE odoo_record_id = ?", [row.task_id]);

            timesheetList.push({
                                   id: row.id,
                                   instance: instance.rows.length > 0 ? instance.rows.item(0).name : '',
                                   name: row.name || '',
                                   spentHours: Utils.convertFloatToTime(row.unit_amount),
                                   project: project.rows.length > 0 ? project.rows.item(0).name : 'Unknown Project',
                                   quadrant: quadrantObj[row.quadrant_id] || "Do",
                                   date: row.record_date,
                                   task: task.rows.length > 0 ? task.rows.item(0).name : 'Unknown Task',
                                   user: user.rows.length > 0 ? user.rows.item(0).name : '',
                               });
        }
    });

    return timesheetList;
}



function markTimesheetAsDeleted(taskId) {
    try {
        var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
        db.transaction(function (tx) {
            tx.executeSql(
                        "UPDATE account_analytic_line_app SET status = 'deleted' WHERE id = ?",
                        [taskId]
                        );
        });
        console.log("Marked timesheet as deleted with id " + taskId);
        return { success: true, message: "Timesheet marked as deleted." };
    } catch (e) {
        console.error("Failed to mark timesheet as deleted with id " + taskId + " - " + e);
        return { success: false, message: "Failed to mark as deleted: " + e };
    }
}

/* Name: getTimeSheetDetails
* This function will return timesheets details in form of object to fill in detail view of timesheet
* -> record_id -> for which timesheet details needs to be fetched
*/

function getTimeSheetDetails(record_id) {
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
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
                'record_date': formatDate(new Date(timesheet.rows.item(0).record_date))
            };
        }
    });
    function formatDate(date) {
        var month = date.getMonth() + 1;
        var day = date.getDate();
        var year = date.getFullYear();
        return month + '/' + day + '/' + year;
    }
    return timesheet_detail;
}

/* Name: create_timesheet
* This function will create timesheet based on passed data
* data -> object of details related to timesheet entry
*/

function createOrSaveTimesheet(data) {

    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    var timestamp = Utils.getFormattedTimestamp();
    var result = { success: false, error: "" };

    try {
        db.transaction(function (tx) {
            var unitAmount = data.isManualTimeRecord
                    ? Utils.convertDurationToFloat(data.manualSpentHours)
                    : Utils.convertDurationToFloat(data.spenthours);

            if (data.id && data.id > 0) {
                console.log("✏Updating timesheet id:", data.id);
                tx.executeSql(`UPDATE account_analytic_line_app SET
                              account_id = ?, record_date = ?, project_id = ?, task_id = ?, name = ?,
                              sub_project_id = ?, sub_task_id = ?, quadrant_id = ?, unit_amount = ?,
                              last_modified = ?, status = ?, user_id = ? WHERE id = ?`,
                              [data.instance_id, data.record_date, data.project, data.task, data.description,
                               data.subprojectId, data.subTask, data.quadrant, unitAmount, timestamp,
                               data.status, data.user_id, data.id]);
            } else {
                console.log("Inserting new timesheet entry");
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
