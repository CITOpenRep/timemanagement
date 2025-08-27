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
                    allocated_hours: Utils.convertDecimalHoursToHHMM(row.allocated_hours),
                    favorites: row.favorites || 0,
                    last_update_status: row.last_update_status,
                    description: row.description || "",
                    last_modified: row.last_modified,
                    color_pallet: row.color_pallet || "#FFFFFF",
                    stage: row.stage || 0,
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
 * Retrieves all project update records from the local SQLite DB as plain objects.
 *
 * @returns {Array<Object>} A list of project update objects with fields like id, name, status, etc.
 */
function getAllProjectUpdates() {
    var updateList = [];

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var query = "SELECT * FROM project_update_app WHERE status != 'deleted' ORDER BY date DESC";
            var result = tx.executeSql(query);

            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);
                updateList.push(DBCommon.rowToObject(row));
            }
        });
    } catch (e) {
        console.error("❌ getAllProjectUpdates failed:", e);
    }

    return updateList;
}

function getProjectStageName(odooRecordId) {
    var stageName = null;

    try {
        var db = Sql.LocalStorage.openDatabaseSync(
            DBCommon.NAME,
            DBCommon.VERSION,
            DBCommon.DISPLAY_NAME,
            DBCommon.SIZE
        );

        db.transaction(function (tx) {
            var query = `
                SELECT name
                FROM project_project_stage_app
                WHERE odoo_record_id = ?
                LIMIT 1
            `;

            var result = tx.executeSql(query, [odooRecordId]);

            if (result.rows.length > 0) {
                stageName = result.rows.item(0).name;
            }
        });
    } catch (e) {
        console.error("getProjectStageName failed:", e);
    }

    return stageName;
}


/**
 * Retrieve all project stages from the local DB for use as filters in UI.
 * Returns an array of objects: { id: local_id, odoo_record_id: odoo_record_id, name: name, account_id: account_id }
 */
function getAllProjectStages() {
    var stages = [];
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        db.transaction(function (tx) {
            var query = "SELECT id, account_id, odoo_record_id, name, sequence, active FROM project_project_stage_app ORDER BY sequence ASC, name COLLATE NOCASE ASC";
            var result = tx.executeSql(query);
            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);
                stages.push({
                    id: row.id,
                    account_id: row.account_id,
                    odoo_record_id: row.odoo_record_id,
                    name: row.name,
                    sequence: row.sequence,
                    active: row.active
                });
            }
        });
    } catch (e) {
        console.error("getAllProjectStages failed:", e);
    }
    return stages;
}



function getAttachmentsForProject(odooRecordId) {
    var attachmentList = [];

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var query = `
                SELECT name, mimetype, account_id,odoo_record_id
                FROM ir_attachment_app
                WHERE res_model = 'project.project' AND res_id = ?
                ORDER BY name COLLATE NOCASE ASC
            `;

            var result = tx.executeSql(query, [odooRecordId]);

            for (var i = 0; i < result.rows.length; i++) {
                attachmentList.push({
                    name: result.rows.item(i).name,
                    mimetype: result.rows.item(i).mimetype,
                    account_id:result.rows.item(i).account_id,
                    odoo_record_id:result.rows.item(i).odoo_record_id,
                });
            }
        });
    } catch (e) {
        console.error("getAttachmentsForProject failed:", e);
    }

    return attachmentList;
}

function getFromCache(recordId) {
    var data = null;
    try {
        var db = Sql.LocalStorage.openDatabaseSync(
            DBCommon.NAME,
            DBCommon.VERSION,
            DBCommon.DISPLAY_NAME,
            DBCommon.SIZE
        );
        db.transaction(function (tx) {
            var result = tx.executeSql(
                "SELECT data_base64 FROM dl_cache_app WHERE record_id = ? LIMIT 1",
                [recordId]
            );
            if (result.rows.length > 0) {
                data = result.rows.item(0).data_base64;
            }
        });
    } catch (e) {
        console.error("getFromCache failed:", e);
    }
    return data; // null if not found
}

function putInCache(recordId, base64Data) {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(
            DBCommon.NAME,
            DBCommon.VERSION,
            DBCommon.DISPLAY_NAME,
            DBCommon.SIZE
        );
        db.transaction(function (tx) {
            tx.executeSql(
                "INSERT OR REPLACE INTO dl_cache_app (record_id, data_base64) VALUES (?, ?)",
                [recordId, base64Data]
            );
        });
    } catch (e) {
        console.error("putInCache failed:", e);
    }
}

function isPresentInCache(recordId) {
    var exists = false;
    try {
        var db = Sql.LocalStorage.openDatabaseSync(
            DBCommon.NAME,
            DBCommon.VERSION,
            DBCommon.DISPLAY_NAME,
            DBCommon.SIZE
        );
        db.transaction(function (tx) {
            var result = tx.executeSql(
                "SELECT 1 FROM dl_cache_app WHERE record_id = ? LIMIT 1",
                [recordId]
            );
            if (result.rows.length > 0) {
                exists = true;
            }
        });
    } catch (e) {
        console.error("isPresentInCache failed:", e);
    }
    return exists;
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
    var newRecordId = recordid; // Keep track of the record ID
    
    db.transaction(function (tx) {
        try {
            if (recordid === 0) {
                tx.executeSql('INSERT INTO project_project_app \
                            (account_id, name, parent_id, planned_start_date, planned_end_date, \
                            allocated_hours, favorites, description, last_modified, color_pallet,status)\
                            Values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?,?)',
                              [project_data.account_id, project_data.name, project_data.parent_id,
                               project_data.planned_start_date, project_data.planned_end_date, Utils.convertDurationToFloat(project_data.allocated_hours),
                               project_data.favorites, project_data.description, timestamp, project_data.color, project_data.status]);
                
                // Get the ID of the newly inserted project
                var result = tx.executeSql("SELECT last_insert_rowid() as id");
                if (result.rows.length > 0) {
                    newRecordId = result.rows.item(0).id;
                }
            } else {
                tx.executeSql('UPDATE project_project_app SET \
                            account_id = ?, name = ?, parent_id = ?, planned_start_date = ?, planned_end_date = ?, \
                            allocated_hours = ?, favorites = ?, description = ?, last_modified = ?, color_pallet = ?, status=?\
                            where id = ?',
                              [project_data.account_id, project_data.name, project_data.parent_id,
                               project_data.planned_start_date, project_data.planned_end_date, Utils.convertDurationToFloat(project_data.allocated_hours),
                               project_data.favorites, project_data.description, timestamp, project_data.color, project_data.status, recordid]);
            }
            messageObj['is_success'] = true;
            messageObj['message'] = 'Project saved Successfully!';
            messageObj['record_id'] = newRecordId; // Return the record ID
        } catch (error) {
            messageObj['is_success'] = false;
            messageObj['message'] = 'Project could not be saved!\n' + error;
        }
    });
    return messageObj;
}
/**
 * Creates a new project update in the local SQLite database.
 *
 * Always inserts a new record and marks `status` as "updated" for sync tracking.
 *
 * @param {Object} update_data - The project update data (project_id, name, project_status, progress, description, account_id, user_id).
 * @returns {Object} - { is_success: boolean, message: string, record_id: number }
 */
function createUpdateSnapShot(update_data) {
    var messageObj = { is_success: false };
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var timestamp = Utils.getFormattedTimestampUTC(); // e.g., 2025-08-04 11:45:00
    var createDate = timestamp.split(" ")[0];        // Extract yyyy-mm-dd format
    var newRecordId = 0;

    db.transaction(function (tx) {
        try {
            console.log("Creating Project Update:");
            console.log("Account ID:", update_data.account_id);
            console.log("Project ID:", update_data.project_id);
            console.log("Name:", update_data.name);
            console.log("Project Status:", update_data.project_status);
            console.log("Progress:", update_data.progress);
            console.log("Description:", update_data.description);
            console.log("User ID:", update_data.user_id);
            console.log("Create Date:", createDate);

            // INSERT new project update with user_id and create_date
            tx.executeSql(
                `INSERT INTO project_update_app
                 (account_id, project_id, name, project_status, progress, description, user_id, date, last_modified, status)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
                [
                    update_data.account_id,
                    update_data.project_id,
                    update_data.name,
                    update_data.project_status,
                    update_data.progress,
                    update_data.description,
                    update_data.user_id,
                    createDate,   // yyyy-mm-dd
                    timestamp,    // full timestamp
                    "updated"     // sync tracking flag
                ]
            );

            // Retrieve the newly inserted record ID
            var result = tx.executeSql("SELECT last_insert_rowid() AS id");
            if (result.rows.length > 0) {
                newRecordId = result.rows.item(0).id;
            }

            messageObj.is_success = true;
            messageObj.message = "Project Update created successfully!";
            messageObj.record_id = newRecordId;

        } catch (error) {
            console.error("createUpdateSnapShot failed:", error);
            messageObj.is_success = false;
            messageObj.message = "Project Update could not be created!\n" + error;
        }
    });

    return messageObj;
}

/**
 * Marks a project update as deleted in the local database.
 *
 * @param {number} updateId - The ID of the project update to be marked as deleted.
 * @returns {Object} - { success: boolean, message: string }
 */
function markProjectUpdateAsDeleted(updateId) {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            tx.executeSql(
                "UPDATE project_update_app SET status = 'deleted' WHERE id = ?",
                [updateId]
            );
        });

        DBCommon.log("Project update marked as deleted (id: " + updateId + ")");
        return { success: true, message: "Project update marked as deleted." };

    } catch (e) {
        DBCommon.logException("markProjectUpdateAsDeleted", e);
        return { success: false, message: "Failed to mark project update as deleted: " + e.message };
    }
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

/**
 * Toggles the favorite status of a project in the local database.
 *
 * @param {number} projectId - The local ID of the project to toggle favorite status.
 * @param {boolean} isFavorite - The new favorite status (true for favorite, false for not favorite).
 * @returns {Object} - Result object with success status and message.
 */
function toggleProjectFavorite(projectId, isFavorite, status) {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        var result = { success: false, message: "" };

        db.transaction(function (tx) {
            var favoriteValue = isFavorite ? 1 : 0;
            var updateResult = tx.executeSql(
                'UPDATE project_project_app SET favorites = ?, last_modified = ? WHERE id = ?',
                [favoriteValue, new Date().toISOString(), projectId]
            );

            if (updateResult.rowsAffected > 0) {
                result.success = true;
                result.message = isFavorite ? "Project marked as favorite" : "Project removed from favorites";
                console.log("✅ Project favorite status updated:", projectId, "favorite:", isFavorite);
            } else {
                result.message = "Project not found or no changes made";
                console.warn("⚠️ No project updated with ID:", projectId);
            }
        });

        return result;
    } catch (e) {
        console.error("❌ toggleProjectFavorite failed:", e);
        return { success: false, message: "Failed to update project favorite status: " + e.message };
    }
}

