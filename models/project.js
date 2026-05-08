.import QtQuick.LocalStorage 2.7 as Sql
    .import "database.js" as DBCommon
        .import "utils.js" as Utils
            .import "accounts.js" as Account

/**
 * Get local project ID from Odoo record ID
 * @param {number} odooRecordId - The Odoo record ID of the project
 * @param {number} accountId - The account ID
 * @returns {number} Local project ID, or -1 if not found
 */
function getLocalIdFromOdooId(odooRecordId, accountId) {
    var localId = -1;

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var result = tx.executeSql(
                'SELECT id FROM project_project_app WHERE odoo_record_id = ? AND account_id = ? LIMIT 1',
                [odooRecordId, accountId]
            );

            if (result.rows.length > 0) {
                localId = result.rows.item(0).id;
            } else {
                console.warn("Project not found for odoo_record_id:", odooRecordId, "account_id:", accountId);
            }
        });
    } catch (e) {
        console.error("getLocalIdFromOdooId failed:", e);
    }

    return localId;
}

/**
 * Get local project update ID from Odoo record ID
 * @param {number} odooRecordId - The Odoo record ID of the project update
 * @param {number} accountId - The account ID
 * @returns {number} Local project update ID, or -1 if not found
 */
function getUpdateLocalIdFromOdooId(odooRecordId, accountId) {
    var localId = -1;

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var result = tx.executeSql(
                'SELECT id FROM project_update_app WHERE odoo_record_id = ? AND account_id = ? LIMIT 1',
                [odooRecordId, accountId]
            );

            if (result.rows.length > 0) {
                localId = result.rows.item(0).id;
            } else {
                console.warn("Project update not found for odoo_record_id:", odooRecordId, "account_id:", accountId);
            }
        });
    } catch (e) {
        console.error("getUpdateLocalIdFromOdooId failed:", e);
    }

    return localId;
}



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
                    user_id: row.user_id || null,
                    last_update_status: row.last_update_status,
                    description: row.description || "",
                    last_modified: row.last_modified,
                    color_pallet: row.color_pallet || "#FFFFFF",
                    stage: row.stage || 0,
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
 * Retrieves project details by Odoo record ID (stable identifier).
 * This is used for deep link navigation from notifications.
 *
 * @param {number} odoo_record_id - The Odoo record ID of the project.
 * @param {number} [account_id] - Optional account ID to narrow the search.
 * @returns {Object} - An object containing project details, or empty object if not found.
 */
function getProjectDetailsByOdooId(odoo_record_id, account_id) {
    var project_detail = {};

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var sql = 'SELECT * FROM project_project_app WHERE odoo_record_id = ?';
            var params = [odoo_record_id];

            if (account_id !== undefined && account_id !== null && account_id > 0) {
                sql += ' AND account_id = ?';
                params.push(account_id);
            }

            sql += ' LIMIT 1';
            var result = tx.executeSql(sql, params);

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
                    user_id: row.user_id || null,
                    last_update_status: row.last_update_status,
                    description: row.description || "",
                    last_modified: row.last_modified,
                    color_pallet: row.color_pallet || "#FFFFFF",
                    stage: row.stage || 0,
                    status: row.status || "",
                    odoo_record_id: row.odoo_record_id
                };

                console.log("getProjectDetailsByOdooId found project:", row.id, "for odoo_record_id:", odoo_record_id);
            } else {
                console.error("No project found for odoo_record_id:", odoo_record_id);
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
 * Now supports account filtering.
 *
 * @param {number} [accountId] - Optional account ID to filter by. If not provided, returns all updates.
 * @returns {Array<Object>} A list of project update objects with fields like id, name, status, etc.
 */
function getAllProjectUpdates(accountId) {
    var updateList = [];

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var query, result;

            if (accountId !== undefined && accountId !== null && accountId !== -1) {

                query = "SELECT * FROM project_update_app WHERE status != 'deleted' AND account_id = ? ORDER BY date DESC";
                result = tx.executeSql(query, [accountId]);
                console.log("Fetching project updates for account:", accountId);
            } else {

                query = "SELECT * FROM project_update_app WHERE status != 'deleted' ORDER BY date DESC";
                result = tx.executeSql(query);
                console.log("Fetching all project updates (no account filter)");
            }

            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);
                updateList.push(DBCommon.rowToObject(row));
            }
        });
    } catch (e) {
        console.error("❌ getAllProjectUpdates failed:", e);
    }

    console.log("Found", updateList.length, "project updates");
    return updateList;
}

function getProjectUpdatesByProject(projectOdooRecordId, accountId) {
    var updateList = [];

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var query = "SELECT * FROM project_update_app WHERE status != 'deleted' AND project_id = ? AND account_id = ? ORDER BY date DESC";
            var result = tx.executeSql(query, [projectOdooRecordId, accountId]);

            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);
                updateList.push(DBCommon.rowToObject(row));
            }
        });
    } catch (e) {
        console.error("❌ getProjectUpdatesByProject failed:", e);
    }

    return updateList;
}

function getProjectUpdateById(updateId, accountId) {
    var update = null;

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var query = "SELECT * FROM project_update_app WHERE id = ? AND account_id = ? LIMIT 1";
            var result = tx.executeSql(query, [updateId, accountId]);

            if (result.rows.length > 0) {
                update = DBCommon.rowToObject(result.rows.item(0));
            }
        });
    } catch (e) {
        console.error("❌ getProjectUpdateById failed:", e);
    }

    return update || {};
}

/**
 * Retrieves project update details by Odoo record ID (stable identifier).
 * This is used for deep link navigation from notifications.
 *
 * @param {number} odoo_record_id - The Odoo record ID of the project update.
 * @param {number} [accountId] - Optional account ID to narrow the search.
 * @returns {Object} - An object containing update details, or empty object if not found.
 */
function getProjectUpdateByOdooId(odoo_record_id, accountId) {
    var update = null;

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var sql = 'SELECT * FROM project_update_app WHERE odoo_record_id = ?';
            var params = [odoo_record_id];

            if (accountId !== undefined && accountId !== null && accountId > 0) {
                sql += ' AND account_id = ?';
                params.push(accountId);
            }

            sql += ' LIMIT 1';
            var result = tx.executeSql(sql, params);

            if (result.rows.length > 0) {
                update = DBCommon.rowToObject(result.rows.item(0));
                console.log("getProjectUpdateByOdooId found update:", update.id, "for odoo_record_id:", odoo_record_id);
            } else {
                console.error("No project update found for odoo_record_id:", odoo_record_id);
            }
        });
    } catch (e) {
        console.error("❌ getProjectUpdateByOdooId failed:", e);
    }

    return update || {};
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
            var query = "SELECT id, account_id, odoo_record_id, name, sequence, active, fold FROM project_project_stage_app ORDER BY sequence ASC, name COLLATE NOCASE ASC";
            var result = tx.executeSql(query);
            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);
                stages.push({
                    id: row.id,
                    account_id: row.account_id,
                    odoo_record_id: row.odoo_record_id,
                    name: row.name,
                    sequence: row.sequence,
                    active: row.active,
                    fold: row.fold
                });
            }
        });
    } catch (e) {
        console.error("getAllProjectStages failed:", e);
    }
    return stages;
}

/**
 * Retrieve project stages for a specific account from the local DB.
 * @param {number} accountId - The account ID to filter stages by
 * @returns {Array} Array of stage objects for the specified account
 */
function getProjectStagesForAccount(accountId) {
    var stages = [];
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        db.transaction(function (tx) {
            var query = "SELECT id, account_id, odoo_record_id, name, sequence, active, fold FROM project_project_stage_app WHERE account_id = ? ORDER BY sequence ASC, name COLLATE NOCASE ASC";
            var result = tx.executeSql(query, [accountId]);
            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);
                stages.push({
                    id: row.id,
                    account_id: row.account_id,
                    odoo_record_id: row.odoo_record_id,
                    name: row.name,
                    sequence: row.sequence,
                    active: row.active,
                    fold: row.fold
                });
            }
        });
    } catch (e) {
        console.error("getProjectStagesForAccount failed:", e);
    }
    return stages;
}

/**
 * Retrieve only open project stages (where fold = 0) from the local DB.
 * Returns an array of stage objects for filtering open projects.
 */
function getOpenProjectStages() {
    var openStages = [];
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        db.transaction(function (tx) {
            var query = "SELECT id, account_id, odoo_record_id, name, sequence, active, fold FROM project_project_stage_app WHERE fold = 0 ORDER BY sequence ASC, name COLLATE NOCASE ASC";
            var result = tx.executeSql(query);
            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);
                openStages.push({
                    id: row.id,
                    account_id: row.account_id,
                    odoo_record_id: row.odoo_record_id,
                    name: row.name,
                    sequence: row.sequence,
                    active: row.active,
                    fold: row.fold
                });
            }
        });
    } catch (e) {
        console.error("getOpenProjectStages failed:", e);
    }
    return openStages;
}

/**
 * Updates the stage of a project
 * @param {number} projectId - The local ID of the project
 * @param {number} stageOdooRecordId - The odoo_record_id of the new stage
 * @param {number} accountId - The account ID
 * @returns {Object} Success/error result
 */
function updateProjectStage(projectId, stageOdooRecordId, accountId) {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        var timestamp = Utils.getFormattedTimestampUTC();

        db.transaction(function (tx) {
            // Verify the project exists and belongs to the account
            var projectCheck = tx.executeSql(
                'SELECT id FROM project_project_app WHERE id = ? AND account_id = ?',
                [projectId, accountId]
            );

            if (projectCheck.rows.length === 0) {
                throw "Project not found or does not belong to this account";
            }

            // Verify the stage exists
            var stageCheck = tx.executeSql(
                'SELECT id FROM project_project_stage_app WHERE odoo_record_id = ?',
                [stageOdooRecordId]
            );

            if (stageCheck.rows.length === 0) {
                throw "Stage not found";
            }

            // Update the project's stage
            tx.executeSql(
                'UPDATE project_project_app SET stage = ?, last_modified = ?, status = ? WHERE id = ?',
                [stageOdooRecordId, timestamp, "updated", projectId]
            );
        });

        return { success: true };
    } catch (e) {
        console.error("updateProjectStage failed:", e);
        return { success: false, error: e.message || e };
    }
}

/**
 * Retrieves all attachments for a given project and account.
 *
 * Handles corner case: project record IDs can be same across multiple accounts.
 *
 * @param {int} accountId - Account ID to filter attachments.
 * @param {int} odooRecordId - Odoo record ID of the project.
 * @returns {Array<Object>} A list of attachment objects.
 */
function getAttachmentsForProject(odooRecordId, accountId) {
    var attachmentList = [];

    try {
        var db = Sql.LocalStorage.openDatabaseSync(
            DBCommon.NAME,
            DBCommon.VERSION,
            DBCommon.DISPLAY_NAME,
            DBCommon.SIZE
        );

        db.transaction(function (tx) {
            var query = `
                SELECT name, mimetype, account_id, odoo_record_id
                FROM ir_attachment_app
                WHERE res_model = 'project.project'
                  AND res_id = ?
                  AND account_id = ?
                ORDER BY name COLLATE NOCASE ASC
            `;

            var result = tx.executeSql(query, [odooRecordId, accountId]);

            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);

                attachmentList.push({
                    id: i,
                    name: row.name,
                    mimetype: row.mimetype,
                    account_id: row.account_id,
                    odoo_record_id: row.odoo_record_id,
                    url: "",        // placeholder for file path if added later
                    size: 0,        // unknown at this stage
                    created: ""     // optional, to be filled if available later
                });
            }
        });
    } catch (e) {
        DBCommon.logException("getAttachmentsForProject", e);
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



function getProjectsForAccount(accountId) {
    var projectList = [];

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var query = "SELECT * FROM project_project_app WHERE account_id = ? ORDER BY name COLLATE NOCASE ASC";
            var result = tx.executeSql(query, [accountId]);

            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);
                projectList.push(DBCommon.rowToObject(row));
            }
        });
    } catch (e) {
        console.error("❌ getProjectsForAccount failed:", e);
    }

    return projectList;
}

/**
 * Paginated version of getProjectsForAccount for infinite scroll.
 * 
 * @param {number} accountId - The account ID to filter projects by.
 * @param {number} limit - Maximum number of items to return.
 * @param {number} offset - Number of items to skip.
 * @returns {Array<Object>} A list of project objects.
 */
function getProjectsForAccountPaginated(accountId, limit, offset) {
    var projectList = [];
    limit = limit || 10;
    offset = offset || 0;

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var query = "SELECT * FROM project_project_app WHERE account_id = ? ORDER BY name COLLATE NOCASE ASC LIMIT ? OFFSET ?";
            var result = tx.executeSql(query, [accountId, limit, offset]);

            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);
                projectList.push(DBCommon.rowToObject(row));
            }
        });
    } catch (e) {
        console.error("getProjectsForAccountPaginated failed:", e);
    }

    return projectList;
}

/**
 * Paginated version of getAllProjects for infinite scroll (all accounts).
 * 
 * @param {number} limit - Maximum number of items to return.
 * @param {number} offset - Number of items to skip.
 * @returns {Array<Object>} A list of project objects.
 */
function getAllProjectsPaginated(limit, offset) {
    var projectList = [];
    limit = limit || 30;
    offset = offset || 0;

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var query = "SELECT * FROM project_project_app ORDER BY name COLLATE NOCASE ASC LIMIT ? OFFSET ?";
            var result = tx.executeSql(query, [limit, offset]);

            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);
                projectList.push(DBCommon.rowToObject(row));
            }
        });
    } catch (e) {
        console.error("getAllProjectsPaginated failed:", e);
    }

    return projectList;
}

/**
 * Paginated project query with optional search, stage, and account filters at SQL level.
 *
 * @param {Object} options
 * @param {number}  options.accountId      - Account ID (-1 for all)
 * @param {string}  [options.searchQuery]  - Search string for name/description
 * @param {number}  [options.stageId]      - Specific stage odoo_record_id (-2 = open stages, -1/undefined = all)
 * @param {Array}   [options.openStageIds] - Array of odoo_record_ids that count as "open" (used when stageId === -2)
 * @param {number}  options.limit
 * @param {number}  options.offset
 * @returns {{projects: Array, hasMore: boolean}}
 */
function getProjectsFilteredPaginated(options) {
    var projectList = [];
    var limit = options.limit || 30;
    var offset = options.offset || 0;
    var hasMore = false;

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var whereClauses = [];
            var params = [];

            // Account filter
            if (options.accountId !== undefined && options.accountId >= 0) {
                whereClauses.push("account_id = ?");
                params.push(options.accountId);
            }

            // Stage filter
            if (options.stageId !== undefined && options.stageId !== null) {
                if (options.stageId === -2 && options.openStageIds && options.openStageIds.length > 0) {
                    // "Open" filter — match any of the open stage IDs
                    var placeholders = options.openStageIds.map(function () { return "?"; }).join(",");
                    whereClauses.push("stage IN (" + placeholders + ")");
                    for (var s = 0; s < options.openStageIds.length; s++) {
                        params.push(options.openStageIds[s]);
                    }
                } else if (options.stageId >= 0) {
                    // Specific stage
                    whereClauses.push("stage = ?");
                    params.push(options.stageId);
                }
                // stageId === -1 means "All" → no stage filter needed
            }

            // Search filter
            if (options.searchQuery && options.searchQuery.trim() !== "") {
                var searchLower = "%" + options.searchQuery.toLowerCase() + "%";
                whereClauses.push("(LOWER(name) LIKE ? OR LOWER(description) LIKE ?)");
                params.push(searchLower, searchLower);
            }

            var query = "SELECT * FROM project_project_app";
            if (whereClauses.length > 0) {
                query += " WHERE " + whereClauses.join(" AND ");
            }
            query += " ORDER BY name COLLATE NOCASE ASC LIMIT ? OFFSET ?";
            params.push(limit + 1, offset);

            var result = tx.executeSql(query, params);

            hasMore = result.rows.length > limit;
            var count = Math.min(result.rows.length, limit);

            for (var i = 0; i < count; i++) {
                projectList.push(DBCommon.rowToObject(result.rows.item(i)));
            }
        });
    } catch (e) {
        console.error("getProjectsFilteredPaginated failed:", e);
    }

    return {
        projects: projectList,
        hasMore: hasMore
    };
}
/**
 * Paginated version of getProjectUpdatesByProject for infinite scroll.
 * 
 * @param {string} projectOdooRecordId - The project's Odoo record ID.
 * @param {number} accountId - The account ID.
 * @param {number} limit - Maximum number of items to return.
 * @param {number} offset - Number of items to skip.
 * @returns {Array<Object>} A list of project update objects.
 */
function getProjectUpdatesByProjectPaginated(projectOdooRecordId, accountId, limit, offset) {
    var updateList = [];
    limit = limit || 30;
    offset = offset || 0;

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var query = "SELECT * FROM project_update_app WHERE status != 'deleted' AND project_id = ? AND account_id = ? ORDER BY date DESC LIMIT ? OFFSET ?";
            var result = tx.executeSql(query, [projectOdooRecordId, accountId, limit, offset]);

            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);
                updateList.push(DBCommon.rowToObject(row));
            }
        });
    } catch (e) {
        console.error("getProjectUpdatesByProjectPaginated failed:", e);
    }

    return updateList;
}

/**
 * Paginated version of getAllProjectUpdates for infinite scroll.
 * 
 * @param {number} [accountId] - Optional account ID to filter by. If not provided, returns all updates.
 * @param {number} limit - Maximum number of items to return.
 * @param {number} offset - Number of items to skip.
 * @returns {Array<Object>} A list of project update objects.
 */
function getAllProjectUpdatesPaginated(accountId, limit, offset) {
    var updateList = [];
    limit = limit || 30;
    offset = offset || 0;

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var query, result;

            if (accountId !== undefined && accountId !== null && accountId !== -1) {
                query = "SELECT * FROM project_update_app WHERE status != 'deleted' AND account_id = ? ORDER BY date DESC LIMIT ? OFFSET ?";
                result = tx.executeSql(query, [accountId, limit, offset]);
            } else {
                query = "SELECT * FROM project_update_app WHERE status != 'deleted' ORDER BY date DESC LIMIT ? OFFSET ?";
                result = tx.executeSql(query, [limit, offset]);
            }

            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);
                updateList.push(DBCommon.rowToObject(row));
            }
        });
    } catch (e) {
        console.error("getAllProjectUpdatesPaginated failed:", e);
    }

    return updateList;
}

/**
 * Paginated project updates with SQL-level search and status filtering.
 *
 * @param {Object} options
 * @param {number}  options.accountId       - Account to filter by (-1 = all)
 * @param {number}  [options.projectId]     - Filter to a specific project odoo_record_id (optional)
 * @param {string}  [options.searchQuery]   - Free-text search against name/description/status
 * @param {string}  [options.statusFilter]  - project_status value, e.g. 'on_track' ('all' or '' = no filter)
 * @param {number}  options.limit
 * @param {number}  options.offset
 * @returns {{ updates: Array, hasMore: boolean }}
 */
function getProjectUpdatesFilteredPaginated(options) {
    var updateList = [];
    var limit = options.limit || 30;
    var offset = options.offset || 0;
    var hasMore = false;

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var whereClauses = ["u.status != 'deleted'"];
            var params = [];
            var needsJoin = false;

            // Account filter
            if (options.accountId !== undefined && options.accountId !== null && options.accountId >= 0) {
                whereClauses.push("u.account_id = ?");
                params.push(options.accountId);
            }

            // Project filter (when viewing updates for a specific project)
            if (options.projectId !== undefined && options.projectId !== null && options.projectId > 0) {
                whereClauses.push("u.project_id = ?");
                params.push(options.projectId);
            }

            // Status filter
            if (options.statusFilter && options.statusFilter !== "" && options.statusFilter !== "all") {
                whereClauses.push("u.project_status = ?");
                params.push(options.statusFilter);
            }

            // Search filter (name, description, project_status, and project name via JOIN)
            if (options.searchQuery && options.searchQuery.trim() !== "") {
                needsJoin = true;
                var searchLower = "%" + options.searchQuery.toLowerCase() + "%";
                whereClauses.push("(LOWER(u.name) LIKE ? OR LOWER(u.description) LIKE ? OR LOWER(u.project_status) LIKE ? OR LOWER(p.name) LIKE ?)");
                params.push(searchLower, searchLower, searchLower, searchLower);
            }

            var query = "SELECT u.* FROM project_update_app u";
            if (needsJoin) {
                query += " LEFT JOIN project_project_app p ON u.project_id = p.odoo_record_id AND u.account_id = p.account_id";
            }
            if (whereClauses.length > 0) {
                query += " WHERE " + whereClauses.join(" AND ");
            }
            query += " ORDER BY u.date DESC LIMIT ? OFFSET ?";
            params.push(limit + 1, offset);

            var result = tx.executeSql(query, params);

            hasMore = result.rows.length > limit;
            var count = Math.min(result.rows.length, limit);

            for (var i = 0; i < count; i++) {
                updateList.push(DBCommon.rowToObject(result.rows.item(i)));
            }
        });
    } catch (e) {
        console.error("getProjectUpdatesFilteredPaginated failed:", e);
    }

    return {
        updates: updateList,
        hasMore: hasMore
    };
}

/**
 * Gets accounts that have projects, with project counts
 * Similar to getAccountsWithTaskCounts() in task.js but for projects
 * 
 * @returns {Array<Object>} Array of account objects with project counts
 */
function getAccountsWithProjectCounts() {
    var accounts = [];
    console.log("🔍 getAccountsWithProjectCounts called");

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var query = `
                SELECT 
                    p.account_id,
                    COUNT(p.id) as project_count,
                    COUNT(CASE WHEN (p.status IS NULL OR p.status != 'deleted') THEN 1 END) as active_project_count
                FROM project_project_app p
                GROUP BY p.account_id
                ORDER BY p.account_id ASC
            `;

            var result = tx.executeSql(query);
            console.log("📊 Found", result.rows.length, "accounts with projects in database");

            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);
                console.log("📝 DB Account:", row.account_id, "Total projects:", row.project_count, "Active projects:", row.active_project_count);
                accounts.push({

                    // id: row.id,
                    // name: row.name,
                    // account_id: row.account_id,
                    // parent_id: row.parent_id,
                    // planned_start_date: row.planned_start_date,
                    // planned_end_date: row.planned_end_date,
                    // allocated_hours: row.allocated_hours,
                    // favorites: row.favorites,
                    // last_update_status: row.last_update_status,
                    // description: row.description,
                    // last_modified: row.last_modified,
                    // color_pallet: row.color_pallet,
                    // status: row.status,
                    // odoo_record_id: row.odoo_record_id


                    account_id: row.account_id,
                    account_name: row.account_id === 0 ? "Local Account" : "Account " + row.account_id,
                    project_count: row.project_count,
                    active_project_count: row.active_project_count
                });
            }
        });
    } catch (e) {
        console.error("❌ getAccountsWithProjectCounts failed:", e);
    }

    console.log("📊 Returning", accounts.length, "accounts with projects");
    return accounts;
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
                            allocated_hours, favorites, description, last_modified, color_pallet, stage, status, user_id)\
                            Values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                    [project_data.account_id, project_data.name, project_data.parent_id,
                    project_data.planned_start_date, project_data.planned_end_date, Utils.convertDurationToFloat(project_data.allocated_hours),
                    project_data.favorites, project_data.description, timestamp, project_data.color, project_data.stage || 0, project_data.status, project_data.user_id || null]);

                // Get the ID of the newly inserted project
                var result = tx.executeSql("SELECT last_insert_rowid() as id");
                if (result.rows.length > 0) {
                    newRecordId = result.rows.item(0).id;
                }
            } else {
                tx.executeSql('UPDATE project_project_app SET \
                            account_id = ?, name = ?, parent_id = ?, planned_start_date = ?, planned_end_date = ?, \
                            allocated_hours = ?, favorites = ?, description = ?, last_modified = ?, color_pallet = ?, stage = ?, status = ?, user_id = ?\
                            where id = ?',
                    [project_data.account_id, project_data.name, project_data.parent_id,
                    project_data.planned_start_date, project_data.planned_end_date, Utils.convertDurationToFloat(project_data.allocated_hours),
                    project_data.favorites, project_data.description, timestamp, project_data.color, project_data.stage || 0, project_data.status, project_data.user_id || null, recordid]);
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
 * Creates a new project update or updates an existing one in the local SQLite database.
 *
 * If `recordid` is 0 or undefined, a new project update is inserted. Otherwise, the existing
 * project update with the matching `id` is updated. Marks `status` as "updated" for sync tracking.
 *
 * @param {Object} update_data - The project update data (project_id, name, project_status, progress, description, account_id, user_id).
 * @param {number} recordid - The local ID of the project update to update. Use 0 to create a new project update.
 * @returns {Object} - { is_success: boolean, message: string, record_id: number }
 */
function createUpdateSnapShot(update_data, recordid) {
    var messageObj = { is_success: false };
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var timestamp = Utils.getFormattedTimestampUTC(); // e.g., 2025-08-04 11:45:00
    var createDate = timestamp.split(" ")[0];        // Extract yyyy-mm-dd format
    var newRecordId = recordid || 0;

    db.transaction(function (tx) {
        try {
            if (!recordid || recordid === 0) {
                // INSERT new project update
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

                messageObj.message = "Project Update created successfully!";
            } else {
                // UPDATE existing project update
                tx.executeSql(
                    `UPDATE project_update_app 
                     SET account_id = ?, project_id = ?, name = ?, project_status = ?, 
                         progress = ?, description = ?, user_id = ?, last_modified = ?, status = ?
                     WHERE id = ?`,
                    [
                        update_data.account_id,
                        update_data.project_id,
                        update_data.name,
                        update_data.project_status,
                        update_data.progress,
                        update_data.description,
                        update_data.user_id,
                        timestamp,    // full timestamp
                        "updated",    // sync tracking flag
                        recordid
                    ]
                );

                messageObj.message = "Project Update updated successfully!";
            }

            messageObj.is_success = true;
            messageObj.record_id = newRecordId;

        } catch (error) {
            console.error("createUpdateSnapShot failed:", error);
            messageObj.is_success = false;
            messageObj.message = "Project Update could not be saved!\n" + error;
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
 * New: accepts optional accountId parameter. If accountId is provided and is -1 => aggregate all accounts.
 * If accountId is provided and >= 0 => aggregate only that account.
 * If accountId is omitted, falls back to Account.getDefaultAccountId() (backwards compatible).
 *
 * @param {boolean} is_work_state - If true, includes remote (Odoo) entries (account_id != 0), else local entries (account_id = 0).
 * @param {number|string} [accountId] - Optional account id to filter by. Use -1 for all accounts.
 * @returns {Array<Object>} - A list of objects with `project_id`, `name`, and `spentHours`.
 */
function getProjectSpentHoursList(is_work_state, accountId) {
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var resultList = [];

    // Determine account to use.
    // If accountId explicitly passed (could be number or string), use it.
    // If omitted, fall back to existing Account.getDefaultAccountId() for backwards compatibility.
    var acctParam;
    try {
        if (typeof accountId !== "undefined" && accountId !== null) {
            // allow strings like "-1"
            var num = Number(accountId);
            acctParam = isNaN(num) ? accountId : num;
        } else {
            acctParam = Account.getDefaultAccountId();
        }
    } catch (e) {
        console.error("Error resolving account param, falling back to default account:", e);
        acctParam = Account.getDefaultAccountId();
    }

    db.transaction(function (tx) {
        var result;

        // treat -1 (string or number) as "all accounts"
        var isAllAccounts = (String(acctParam) === "-1");

        if (isAllAccounts) {
            console.log("   Aggregating spent hours for ALL accounts");

            result = tx.executeSql(
                "SELECT aal.project_id, aal.account_id, COALESCE(u.name, 'Unknown') AS account_name, " +
                "COALESCE(p.name, 'Unknown') AS project_name, SUM(aal.unit_amount) AS total_spent " +
                "FROM account_analytic_line_app aal " +
                "LEFT JOIN users u ON aal.account_id = u.id " +
                "LEFT JOIN project_project_app p ON p.odoo_record_id = aal.project_id AND p.account_id = aal.account_id " +
                "WHERE " + (is_work_state ? "aal.account_id != 0 " : "aal.account_id = 0 ") +
                "GROUP BY aal.project_id, aal.account_id, u.name, p.name " +
                "ORDER BY total_spent DESC"
            );

            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);
                var projectName = row.project_name || "Unknown";
                var accountName = row.account_name || "Unknown";
                resultList.push({
                    project_id: row.project_id,
                    name: projectName + " (" + accountName + ")",
                    spentHours: parseFloat((parseFloat(row.total_spent || 0)).toFixed(1)),
                    account_id: row.account_id,
                    account_name: accountName,
                    original_project_name: projectName
                });
            }

        } else {
            // Single account path — acctParam should be a numeric id (or something convertible)
            var acctNum = Number(acctParam);
            if (isNaN(acctNum)) {
                console.warn("getProjectSpentHoursList: accountId not numeric, falling back to default account id");
                acctNum = Number(Account.getDefaultAccountId());
            }

            console.log("   Aggregating spent hours for single account:", acctNum);

            result = tx.executeSql(
                "SELECT aal.project_id, COALESCE(p.name, 'Unknown') AS project_name, SUM(aal.unit_amount) AS total_spent " +
                "FROM account_analytic_line_app aal " +
                "LEFT JOIN project_project_app p ON p.odoo_record_id = aal.project_id AND p.account_id = aal.account_id " +
                "WHERE aal.account_id = ? " +
                "GROUP BY aal.project_id, p.name " +
                "ORDER BY total_spent DESC",
                [acctNum]
            );

            for (var j = 0; j < result.rows.length; j++) {
                var r = result.rows.item(j);
                var projectNameSingle = r.project_name || "Unknown";
                resultList.push({
                    project_id: r.project_id,
                    name: projectNameSingle,
                    spentHours: parseFloat((parseFloat(r.total_spent || 0)).toFixed(1)),
                    account_id: acctNum,
                    account_name: undefined,
                    original_project_name: projectNameSingle
                });
            }
        }
    });

    return resultList;
}

/**
 * Lightweight dashboard summary used by the project/task drilldown chart.
 * Computes task counts and spent hours in SQL instead of loading every task and
 * calculating totals one record at a time in QML.
 *
 * @param {number} accountId - Account ID, or -1 for all accounts.
 * @returns {Array<Object>} Project summary rows for dashboard charts.
 */
function getDashboardProjectTaskSummary(accountId) {
    var resultList = [];

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var params = [];
            var accountWhere = "";

            if (accountId !== -1 && accountId !== undefined && accountId !== null) {
                accountWhere = "WHERE p.account_id = ? ";
                params.push(accountId);
            }

            var query =
                "SELECT " +
                "p.account_id, p.odoo_record_id, p.id AS local_id, p.name, p.color_pallet, " +
                "COUNT(t.id) AS task_count, COALESCE(SUM(ts.total_hours), 0) AS total_hours " +
                "FROM project_project_app p " +
                "LEFT JOIN project_task_app t ON t.account_id = p.account_id " +
                "AND t.project_id = p.odoo_record_id " +
                "AND (t.status IS NULL OR t.status != 'deleted') " +
                "LEFT JOIN ( " +
                "SELECT account_id, task_id, SUM(unit_amount) AS total_hours " +
                "FROM account_analytic_line_app " +
                "WHERE status IS NULL OR status != 'deleted' " +
                "GROUP BY account_id, task_id " +
                ") ts ON ts.account_id = t.account_id AND ts.task_id = t.odoo_record_id " +
                accountWhere +
                "GROUP BY p.account_id, p.odoo_record_id, p.id, p.name, p.color_pallet " +
                "ORDER BY total_hours DESC, p.name COLLATE NOCASE ASC";

            var result = tx.executeSql(query, params);

            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);
                resultList.push({
                    id: String(row.account_id) + ":" + String(row.odoo_record_id),
                    accountId: row.account_id,
                    odooRecordId: row.odoo_record_id,
                    localId: row.local_id,
                    name: row.name || "Unnamed project",
                    colour: row.color_pallet,
                    taskCount: row.task_count || 0,
                    totalHours: Number(row.total_hours || 0),
                    tasks: [],
                    _tasksLoaded: false
                });
            }
        });
    } catch (e) {
        console.error("getDashboardProjectTaskSummary failed:", e);
    }

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
                'UPDATE project_project_app SET favorites = ?, last_modified = ?, status = ? WHERE id = ?',
                [favoriteValue, new Date().toISOString(), "updated", projectId]
            );

            if (updateResult.rowsAffected > 0) {
                result.success = true;
                result.message = isFavorite ? "Project marked as favorite" : "Project removed from favorites";
                //  console.log("✅ Project favorite status updated:", projectId, "favorite:", isFavorite);
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
