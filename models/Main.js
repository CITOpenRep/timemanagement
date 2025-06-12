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

function get_projects_spent_hours() {
    var spent_hours = get_spent_hours({ 'group_by': 'project_id' });
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

function get_tasks_spent_hours() {
    var spent_hours = get_spent_hours({ 'group_by': 'task_id' });
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

/* Name: get_spent_hours
* This function will return spent hours based on given parameters
* group_by -> given column will be used for group by against spent hours
* dateFilter -> given date will be used for finding spent hours after this date
* return format Array[query result]
*/

function get_spent_hours({ group_by = false, dateFilter = false } = {}) {
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    var query_string = `select * from account_analytic_line_app`;
    if (group_by) {
        query_string = `select ${group_by}, sum(unit_amount) as total from account_analytic_line_app`;
    }
    if (dateFilter) {
        query_string += ` where record_date >= '${dateFilter}'`;
    }
    if (group_by) {
        query_string += ` group by ${group_by}`;
    }
    var result = [];
    db.transaction(function (tx) {
        var fetched_details = tx.executeSql(query_string);
        for (var fetch = 0; fetch < fetched_details.rows.length; fetch++) {
            result.push(fetched_details.rows.item(fetch));
        }
    });
    return result;
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
