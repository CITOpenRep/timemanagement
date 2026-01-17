.import "database.js" as DBCommon
.import QtQuick.LocalStorage 2.7 as Sql

/* Name: get_quadrant_current_week
    * This function will return total of spent time for current week based on quadrants from timesheet entries
    * 4 quadrants are as following
    * 0 -> Urgent and Important
    * 1 -> Import but not Urgent
    * 2 -> Not Important but Urgent
    * 3 -> Not Important and Not Urgent
    */

.import "../models/dbinit.js" as DbInit
DbInit.initializeDatabase();

function get_quadrant_difference() {
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    var quadrant_data = { 0: 0, 1: 0, 2: 0, 3: 0 };
    db.transaction(function (tx) {
        var fetch_quadrant = tx.executeSql('select quadrant_id, sum(unit_amount) as total from account_analytic_line_app group by quadrant_id');
        for (var quad = 0; quad < fetch_quadrant.rows.length; quad++) {
            quadrant_data[fetch_quadrant.rows.item(quad).quadrant_id] = fetch_quadrant.rows.item(quad).total
        }
    });
    return quadrant_data;
}

/**
 * Retrieves the total spent hours for each time management quadrant (0–3)
 * for the current week, starting from Monday.
 *
 * @function get_quadrant_current_week
 * @returns {Object} - An object mapping quadrant IDs (0 to 3) to their respective total spent hours.
 *                     Example: { 0: 5, 1: 8, 2: 2, 3: 0 }
 *
 * @description
 * Initializes a data structure to hold totals for each quadrant.
 * Calculates the date of the Monday of the current week using `getMondayOfCurrentWeek()`.
 * Calls `get_spent_hours()` with a filter to group results by `quadrant_id` and limit data to the current week.
 * Populates the `quadrant_data` object with the total hours spent per quadrant based on the returned data.
 */

function get_quadrant_current_week() {
    var quadrant_data = { 0: 0, 1: 0, 2: 0, 3: 0 };
    var first_day_of_week = getMondayOfCurrentWeek();
    var spent_hours = get_spent_hours({ 'group_by': 'quadrant_id', 'dateFilter': first_day_of_week });
    for (var fetch = 0; fetch < spent_hours.length; fetch++) {
        quadrant_data[spent_hours[fetch].quadrant_id] = spent_hours[fetch].total;
    }
    return quadrant_data;
}

/* Name: get_quadrant_current_month
* This function will return total of spent time for current month based on quadrants from timesheet entries
* 4 quadrants are as following
* 0 -> Urgent and Important
* 1 -> Import but not Urgent
* 2 -> Not Important but Urgent
* 3 -> Not Important and Not Urgent
*/

function get_quadrant_current_month() {
    var quadrant_data = { 0: 0, 1: 0, 2: 0, 3: 0 };
    var first_day_of_week = getFirstDayOfCurrentMonth();
    var spent_hours = get_spent_hours({ 'group_by': 'quadrant_id', 'dateFilter': first_day_of_week });
    for (var fetch = 0; fetch < spent_hours.length; fetch++) {
        quadrant_data[spent_hours[fetch].quadrant_id] = spent_hours[fetch].total;
    }
    return quadrant_data;
}

/* Name: get_projects_spent_hours
* This function will return total of spent time based on project from timesheet entries
* return format {<project name>: <spent hours>}
*/

function get_projects_spent_hours(account) {
    var spent_hours = get_spent_hours({ 'group_by': 'project_id' },account);
    var project_details = {};
    for (var fetch = 0; fetch < spent_hours.length; fetch++) {
        var project = get_project_name(spent_hours[fetch].project_id)
        project_details[project] = spent_hours[fetch].total;
        //        console.log("In get_projects_spent_hours, project is: " + project)
    }
    return project_details;
}

/* Name: get_tasks_spent_hours
* This function will return total of spent time based on task from timesheet entries
* return format {<task name>: <spent hours>}
*/

function get_tasks_spent_hours(account) {
    var spent_hours = get_spent_hours({ 'group_by': 'task_id' },account);
    var task_details = {};
    for (var fetch = 0; fetch < spent_hours.length; fetch++) {
        var task = get_task_name(spent_hours[fetch].task_id)
        task_details[task] = spent_hours[fetch].total;
    }
    return task_details;
}

/* Name: get_project_name
* This function will return project name based project id
* project_id -> id of project to get name of project
* return format <project name>
*/

function get_project_name(project_id) {
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    var project_name = '';
    db.transaction(function (tx) {
        var project = tx.executeSql('select name from project_project_app where id = ?', [project_id]);
        if (project.rows.length) {
            project_name = project.rows.item(0).name;
        }
    });
    return project_name;
}

/* Name: get_task_name
* This function will return task name based task id
* task_id -> id of task to get name of task
* return format <task name>
*/

function get_task_name(task_id) {
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    var task_name = '';
    db.transaction(function (tx) {
        var task = tx.executeSql('select name from project_task_app where id = ?', [task_id]);
        if (task.rows.length) {
            task_name = task.rows.item(0).name;
        }
    });
    return task_name;
}

/**
 * Returns spent hours from the local database for the given account.
 *
 * @param {Object} [options={}] - Optional parameters.
 * @param {string|false} [options.group_by=false] - Column name to group results by (e.g., 'project_id').
 * @param {string|false} [options.dateFilter=false] - ISO date string (YYYY-MM-DD) to filter records after this date.
 * @param {number} account_id - Account ID to filter spent hours for. Use -1 to include all accounts.
 * @returns {Array<Object>} List of spent-hour objects.
 */
function get_spent_hours({ group_by = false, dateFilter = false } = {}, account_id) {
    var spentList = [];

    try {
        var db = Sql.LocalStorage.openDatabaseSync(
            DBCommon.NAME,
            DBCommon.VERSION,
            DBCommon.DISPLAY_NAME,
            DBCommon.SIZE
        );

        db.transaction(function (tx) {
            var params = [];
            var query = "";
            var whereClause = "";

            // Build account filter - if account_id is -1 (All Accounts), don't filter by account
            if (account_id !== -1 && account_id !== undefined && account_id !== null) {
                whereClause = "WHERE account_id = ?";
                params.push(account_id);
            }

            // Base query
            if (group_by) {
                query = `SELECT ${group_by}, SUM(unit_amount) AS total
                         FROM account_analytic_line_app
                         ${whereClause}`;
            } else {
                query = `SELECT *
                         FROM account_analytic_line_app
                         ${whereClause}`;
            }

            // Optional date filter
            if (dateFilter) {
                if (whereClause) {
                    query += ` AND record_date >= ?`;
                } else {
                    query += ` WHERE record_date >= ?`;
                }
                params.push(dateFilter);
            }

            // Optional group_by
            if (group_by) {
                query += ` GROUP BY ${group_by}`;
            }

            var result = tx.executeSql(query, params);
            for (var i = 0; i < result.rows.length; i++) {
                spentList.push(DBCommon.rowToObject(result.rows.item(i)));
            }
        });
    } catch (e) {
        DBCommon.logException("get_spent_hours", e);
    }

    return spentList;
}


/* Name: getMondayOfCurrentWeek
* This function will return first day of week
* return format YYYY-MM-DD
*/

function getMondayOfCurrentWeek() {
    let today = new Date();
    let day = today.getDay();
    let diff = today.getDate() - day + (day === 0 ? -6 : 1);
    let monday = new Date(today.setDate(diff));

    return monday.toISOString().split('T')[0]; // Format as YYYY-MM-DD
}

/* Name: getFirstDayOfCurrentMonth
* This function will return first day of month
* return format YYYY-MM-DD
*/

function getFirstDayOfCurrentMonth() {
    let today = new Date();
    let firstDay = new Date(today.getFullYear(), today.getMonth(), 1);
    return firstDay.toISOString().split('T')[0]; // Format as YYYY-MM-DD
}
