.import QtQuick.LocalStorage 2.7 as Sql
.import "database.js" as DBCommon
.import "utils.js" as Utils



/**
 * Retrieves detailed information for a specific project from the local SQLite database.
 *
 * This function queries the `project_project_app` table using the provided project ID
 * and returns a structured object with relevant project details. If the project is not found,
 * an empty object is returned.
 *
 * @param {number} project_id - The unique local ID of the project.
 * @returns {Object} - An object containing project details such as name, dates, hours, and metadata.
 *                     Returns an empty object if no matching project is found.
 */
function getProjectDetails(project_id) {
    var project_detail = {};

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var result = tx.executeSql('SELECT * FROM project_project_app WHERE id = ?', [project_id]);

            if (result.rows.length > 0) {
                var row = result.rows.item(0);

                project_detail = {
                    id: row.id,
                    name: row.name,
                    account_id: row.account_id,
                    parent_id: row.parent_id,
                    planned_start_date: row.planned_start_date ? Utils.formatDate(new Date(row.planned_start_date)) : "",
                    planned_end_date: row.planned_end_date ? Utils.formatDate(new Date(row.planned_end_date)) : "",
                    allocated_hours: Utils.convertFloatToTime(row.allocated_hours),
                    favorites: row.favorites || 0,
                    last_update_status: row.last_update_status,
                    description: row.description || "",
                    last_modified: row.last_modified,
                    color_pallet: row.color_pallet || "#FFFFFF",
                    status: row.status || "",
                    odoo_record_id: row.odoo_record_id
                };
            }
        });

    } catch (e) {
        DBCommon.logException(e);
    }
    return project_detail;
}

/**
 * Retrieves all project records from the local SQLite DB as plain objects.
 *
 * @returns {Array<Object>} A list of project objects with fields like id, name, etc.
 */
function getAllProjects() {
    var projectList = [];

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var query = "SELECT * FROM project_project_app ORDER BY name COLLATE NOCASE ASC";
            var result = tx.executeSql(query);

            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);
                projectList.push(DBCommon.rowToObject(row));
            }
        });
    } catch (e) {
        console.error("❌ getAllProjects failed:", e);
    }

    return projectList;
}

/**
 * Retrieves all projects associated with a specific user account from the local SQLite database.
 *
 * Projects are fetched from the `project_project_app` table where the `account_id` matches,
 * and are sorted alphabetically by name (case-insensitive).
 *
 * @param {number} accountId - The ID of the account whose projects are to be retrieved.
 * @returns {Array<Object>} - An array of project objects with properties like name, dates, hours, and metadata.
 */
function getProjectsForAccount(accountId) {
    var projects = [];

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var result = tx.executeSql(
                        "SELECT * FROM project_project_app WHERE account_id = ? ORDER BY name COLLATE NOCASE ASC",
                        [accountId]
                        );

            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);

                projects.push({
                                  id: row.id,
                                  name: row.name,
                                  account_id: row.account_id,
                                  parent_id: row.parent_id,
                                  planned_start_date: row.planned_start_date,
                                  planned_end_date: row.planned_end_date,
                                  allocated_hours: row.allocated_hours,
                                  favorites: row.favorites,
                                  last_update_status: row.last_update_status,
                                  description: row.description,
                                  last_modified: row.last_modified,
                                  color_pallet: row.color_pallet,
                                  status: row.status,
                                  odoo_record_id: row.odoo_record_id
                              });
            }
        });

    } catch (e) {
        DBCommon.logException("getProjectsForAccount", e);
    }

    return projects;
}


/**
 * Creates a new project or updates an existing one in the local SQLite database.
 *
 * If `recordid` is 0, a new project is inserted. Otherwise, the existing project
 * with the matching `id` is updated. The function returns a message object indicating
 * success or failure.
 *
 * @param {Object} project_data - The project data containing all fields to be saved.
 * @param {number} recordid - The local ID of the project to update. Use 0 to create a new project.
 * @returns {Object} - An object with `is_success` (boolean) and `message` (string) indicating the result.
 */
function createUpdateProject(project_data, recordid) {
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var messageObj = {};
    var timestamp = Utils.getFormattedTimestampUTC();
    db.transaction(function (tx) {
        try {
            if (recordid == 0) {
                tx.executeSql('INSERT INTO project_project_app \
                            (account_id, name, parent_id, planned_start_date, planned_end_date, \
                            allocated_hours, favorites, description, last_modified, color_pallet,status)\
                            Values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?,?)',
                              [project_data.account_id, project_data.name, project_data.parent_id,
                               project_data.planned_start_date, project_data.planned_end_date, Utils.convertDurationToFloat(project_data.allocated_hours),
                               project_data.favorites, project_data.description, timestamp, project_data.color, project_data.status])
            } else {
                tx.executeSql('UPDATE project_project_app SET \
                            account_id = ?, name = ?, parent_id = ?, planned_start_date = ?, planned_end_date = ?, \
                            allocated_hours = ?, favorites = ?, description = ?, last_modified = ?, color_pallet = ?, status=?\
                            where id = ?',
                              [project_data.account_id, project_data.name, project_data.parent_id,
                               project_data.planned_start_date, project_data.planned_end_date, Utils.convertDurationToFloat(project_data.allocated_hours),
                               project_data.favorites, project_data.description, timestamp, project_data.color, project_data.status, recordid])
            }
            messageObj['is_success'] = true;
            messageObj['message'] = 'Project saved Successfully!';
        } catch (error) {
            messageObj['is_success'] = false;
            messageObj['message'] = 'Project could not be saved!\n' + error;
        }
    });
    return messageObj;
}

/**
 * Calculates and returns a list of projects with their total spent hours.
 *
 * It aggregates the `unit_amount` from the `account_analytic_line_app` table for either work (remote)
 * or personal (local) entries based on the `account_id` filter. Then it resolves each project name
 * from the `project_project_app` table using `odoo_record_id`.
 *
 * @param {boolean} is_work_state - If true, includes remote (Odoo) entries (account_id != 0), else local entries (account_id = 0).
 * @returns {Array<Object>} - A list of objects with `project_id`, `name`, and `spentHours`.
 */
function getProjectSpentHoursList(is_work_state) {
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var resultList = [];
    var projectSpentMap = {};

    db.transaction(function (tx) {
        var filter = is_work_state ? "account_id != 0" : "account_id = 0";
        var result = tx.executeSql("SELECT project_id, unit_amount FROM account_analytic_line_app WHERE " + filter);

        for (var i = 0; i < result.rows.length; i++) {
            var row = result.rows.item(i);
            var projectId = row.project_id;
            var spent = parseFloat(row.unit_amount || 0);

            if (!projectSpentMap[projectId]) {
                projectSpentMap[projectId] = 0;
            }
            projectSpentMap[projectId] += spent;
            // console.log("project is " + projectId)
            // console.log(" Spent is " + spent)
        }

        for (var projectId in projectSpentMap) {
            var intProjectId = parseInt(projectId);  // ✅ ensure it's an integer
            var pname = tx.executeSql("SELECT name FROM project_project_app WHERE odoo_record_id = ?", [intProjectId]);
            var projectName = pname.rows.length ? pname.rows.item(0).name : "Unknown";

            resultList.push({
                                project_id: intProjectId,
                                name: projectName,
                                spentHours: parseFloat(projectSpentMap[projectId].toFixed(1))
                            });
        }

    });

    return resultList;
}

/**
 * Gets the name of a project by its Odoo ID and account.
 *
 * @param {number} projectId - Odoo record ID of the project.
 * @param {number} accountId - Account ID to scope the lookup.
 * @returns {string} - Project name if found, else "Unknown Project".
 */
function getProjectName(projectId, accountId) {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        var projectName = "Unknown Project";

        db.transaction(function (tx) {
            var result = tx.executeSql(
                "SELECT name FROM project_project_app WHERE odoo_record_id = ? AND account_id = ?",
                [projectId, accountId]
            );
            if (result.rows.length > 0) {
                projectName = result.rows.item(0).name;
            }
        });

        return projectName;
    } catch (e) {
        console.error("❌ getProjectName failed:", e);
        return "Unknown Project";
    }
}
