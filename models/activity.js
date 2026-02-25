.import QtQuick.LocalStorage 2.7 as Sql
    .import "database.js" as DBCommon
        .import "utils.js" as Utils
            .import "task.js" as Task
                .import "project.js" as Project
                    .import "accounts.js" as Accounts

/**
 * Retrieves all activity records from the `mail_activity_app` table.
 *
 * This function opens a read-only SQLite transaction using the DBCommon configuration,
 * executes a query to fetch all rows from the `mail_activity_app` table without any filtering
 * (e.g., includes all statuses, states, and accounts), and returns the results as a list of objects.
 *
 * Each row is converted into a plain JavaScript object using `DBCommon.rowToObject`.
 *
 * @function
 * @returns {Array<Object>} A list of all activities stored in the local database, sorted by `due_date` ascending.
 *
 * @example
 * const allActivities = getAllActivities();
 * console.log(allActivities[0].summary); // Example usage
 */
function getAllActivities() {
    var activityList = [];

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        var projectColorMap = {};

        db.transaction(function (tx) {
            // Step 1: Build project color map
            var projectResult = tx.executeSql("SELECT odoo_record_id, color_pallet FROM project_project_app");
            for (var j = 0; j < projectResult.rows.length; j++) {
                var row = projectResult.rows.item(j);
                projectColorMap[row.odoo_record_id] = row.color_pallet;
            }

            // Step 2: Fetch activities
            var rs = tx.executeSql(`
                SELECT * FROM mail_activity_app
                WHERE LOWER(TRIM(COALESCE(state, ''))) != 'done'
                ORDER BY due_date ASC
            `);

            for (var i = 0; i < rs.rows.length; i++) {
                var row = rs.rows.item(i);
                var activity = DBCommon.rowToObject(row);

                // Step 3: Determine color_pallet
                let inheritedColor = 0;

                if (activity.resModel === "project.project" && activity.link_id) {
                    inheritedColor = projectColorMap[activity.link_id] || 0;

                } else if (activity.resModel === "project.task" && activity.link_id) {
                    // Fetch task's project_id
                    var taskRs = tx.executeSql(
                        "SELECT project_id FROM project_task_app WHERE odoo_record_id = ? LIMIT 1",
                        [activity.link_id]
                    );

                    if (taskRs.rows.length > 0) {
                        var taskProjectId = taskRs.rows.item(0).project_id;
                        inheritedColor = projectColorMap[taskProjectId] || 0;
                    }
                }

                // Convert to integer safely
                activity.color_pallet = parseInt(inheritedColor) || 0;

                activityList.push(activity);
            }
        });

    } catch (e) {
        DBCommon.logException("getAllActivities", e);
    }

    return activityList;
}

/**
 * Retrieves all activity records from the `mail_activity_app` table that are marked as done.
 *
 * This function opens a read-only SQLite transaction using the DBCommon configuration,
 * executes a query to fetch all rows from the `mail_activity_app` table where state = 'done',
 * and returns the results as a list of objects.
 *
 * Each row is converted into a plain JavaScript object using `DBCommon.rowToObject`.
 *
 * @function
 * @returns {Array<Object>} A list of all done activities stored in the local database, sorted by `due_date` descending (most recent first).
 */
function getDoneActivities() {
    var activityList = [];

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        var projectColorMap = {};

        db.transaction(function (tx) {
            // Step 1: Build project color map
            var projectResult = tx.executeSql("SELECT odoo_record_id, color_pallet FROM project_project_app");
            for (var j = 0; j < projectResult.rows.length; j++) {
                var row = projectResult.rows.item(j);
                projectColorMap[row.odoo_record_id] = row.color_pallet;
            }

            // Step 2: Fetch done activities
            var rs = tx.executeSql(`
                SELECT * FROM mail_activity_app
                WHERE LOWER(TRIM(COALESCE(state, ''))) = 'done'
                ORDER BY due_date DESC
            `);

            for (var i = 0; i < rs.rows.length; i++) {
                var row = rs.rows.item(i);
                var activity = DBCommon.rowToObject(row);

                // Step 3: Determine color_pallet
                let inheritedColor = 0;

                if (activity.resModel === "project.project" && activity.link_id) {
                    inheritedColor = projectColorMap[activity.link_id] || 0;

                } else if (activity.resModel === "project.task" && activity.link_id) {
                    // Fetch task's project_id
                    var taskRs = tx.executeSql(
                        "SELECT project_id FROM project_task_app WHERE odoo_record_id = ? LIMIT 1",
                        [activity.link_id]
                    );

                    if (taskRs.rows.length > 0) {
                        var taskProjectId = taskRs.rows.item(0).project_id;
                        inheritedColor = projectColorMap[taskProjectId] || 0;
                    }
                }

                // Convert to integer safely
                activity.color_pallet = parseInt(inheritedColor) || 0;

                activityList.push(activity);
            }
        });

    } catch (e) {
        DBCommon.logException("getDoneActivities", e);
    }

    return activityList;
}

//enrichment starts
/**
 * Fetches and enriches a local activity record from `mail_activity_app` using its record ID and account ID,
 * resolving task, subtask, project, and subproject relationships based on its `resModel`.
 *
 * Supports:
 *  - `project.task` activities: uses `resolveActivityLinkage` to determine task and project hierarchy.
 *  - `project.project` activities: uses `resolveProjectLinkage` to determine project and subproject hierarchy.
 *
 * Returns the enriched activity object with:
 *   - task_id: Odoo ID of the parent task (or -1 if not applicable).
 *   - sub_task_id: Odoo ID of the subtask (or -1 if not applicable).
 *   - project_id: Odoo ID of the parent project (or self if top-level).
 *   - sub_project_id: Odoo ID of the subproject (or -1 if not applicable).
 *   - linkedType: "task", "project", or "other".
 *
 * If the record is not found, returns null.
 *
 * @param {number} record_id - The local record ID of the activity in `mail_activity_app`.
 * @param {number} account_id - The account ID to scope the query within multi-account environments.
 * @returns {Object|null} Enriched activity object or null if not found.
 */

function getActivityById(record_id, account_id) {
    var activity = null;

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var rs = tx.executeSql(
                `SELECT * FROM mail_activity_app WHERE id = ? AND account_id = ? LIMIT 1`,
                [record_id, account_id]
            );

            if (rs.rows.length > 0) {
                activity = DBCommon.rowToObject(rs.rows.item(0));
                initializeEnrichmentDefaults(activity);

                if (activity.resModel === "project.task" && activity.link_id) {
                    // Using new robust pipeline
                    let linkage = resolveActivityLinkage(tx, activity.link_id, activity.account_id);
                    activity.task_id = linkage.task_id;
                    activity.sub_task_id = linkage.sub_task_id;
                    activity.project_id = linkage.project_id;
                    activity.sub_project_id = linkage.sub_project_id;
                    activity.linkedType = "task";

                } else if (activity.resModel === "project.project" && activity.link_id) {
                    // Using new robust pipeline
                    let linkage = resolveProjectLinkage(tx, activity.link_id, activity.account_id);
                    activity.task_id = linkage.task_id;
                    activity.sub_task_id = linkage.sub_task_id;
                    activity.project_id = linkage.project_id;
                    activity.sub_project_id = linkage.sub_project_id;
                    activity.linkedType = "project";
                } else if (activity.resModel === "project.update" && activity.link_id) {
                    // Project update linkage
                    activity.update_id = activity.link_id;
                    activity.linkedType = "update";
                } else {
                    console.log("Activity not linked to recognized model, using defaults.");
                }

                console.log("getActivityById complete:", JSON.stringify(activity));
            } else {
                console.error("No activity found for record_id:", record_id, "account_id:", account_id);
            }
        });

    } catch (e) {
        DBCommon.logException("getActivityById", e);
    }

    return activity;
}

/**
 * Retrieves an activity by its Odoo record ID (stable identifier).
 * This is used for deep link navigation from notifications.
 *
 * @param {number} odoo_record_id - The Odoo record ID of the activity.
 * @param {number} [account_id] - Optional account ID to narrow the search.
 * @returns {Object|null} Enriched activity object or null if not found.
 */
function getActivityByOdooId(odoo_record_id, account_id) {
    var activity = null;

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var sql = 'SELECT * FROM mail_activity_app WHERE odoo_record_id = ?';
            var params = [odoo_record_id];

            if (account_id !== undefined && account_id !== null && account_id > 0) {
                sql += ' AND account_id = ?';
                params.push(account_id);
            }

            sql += ' LIMIT 1';
            var rs = tx.executeSql(sql, params);

            if (rs.rows.length > 0) {
                activity = DBCommon.rowToObject(rs.rows.item(0));
                initializeEnrichmentDefaults(activity);

                if (activity.resModel === "project.task" && activity.link_id) {
                    let linkage = resolveActivityLinkage(tx, activity.link_id, activity.account_id);
                    activity.task_id = linkage.task_id;
                    activity.sub_task_id = linkage.sub_task_id;
                    activity.project_id = linkage.project_id;
                    activity.sub_project_id = linkage.sub_project_id;
                    activity.linkedType = "task";
                } else if (activity.resModel === "project.project" && activity.link_id) {
                    let linkage = resolveProjectLinkage(tx, activity.link_id, activity.account_id);
                    activity.task_id = linkage.task_id;
                    activity.sub_task_id = linkage.sub_task_id;
                    activity.project_id = linkage.project_id;
                    activity.sub_project_id = linkage.sub_project_id;
                    activity.linkedType = "project";
                } else if (activity.resModel === "project.update" && activity.link_id) {
                    activity.update_id = activity.link_id;
                    activity.linkedType = "update";
                }

                console.log("getActivityByOdooId found activity id:", activity.id, "for odoo_record_id:", odoo_record_id);
            } else {
                console.error("No activity found for odoo_record_id:", odoo_record_id);
            }
        });

    } catch (e) {
        DBCommon.logException("getActivityByOdooId", e);
    }

    return activity;
}


function initializeEnrichmentDefaults(activity) {
    activity.project_id = -1;
    activity.sub_project_id = -1;
    activity.task_id = -1;
    activity.sub_task_id = -1;
    activity.update_id = -1;
    activity.linkedType = "other";
}

function resolveProjectLinkage(tx, link_id, account_id) {
    let result = {
        task_id: -1,
        sub_task_id: -1,
        project_id: -1,
        sub_project_id: -1
    };

    try {
        let rs_project = tx.executeSql(
            `SELECT odoo_record_id, parent_id FROM project_project_app WHERE odoo_record_id = ? AND account_id = ? LIMIT 1`,
            [link_id, account_id]
        );

        if (rs_project.rows.length > 0) {
            let row = rs_project.rows.item(0);
            let parent_id = sanitizeId(row.parent_id);

            if (parent_id !== -1 && parent_id !== 0) {  // Has a valid parent (not -1 for invalid, not 0 for no parent)
                result.project_id = parent_id;
                result.sub_project_id = row.odoo_record_id;
            } else {
                result.project_id = row.odoo_record_id;
                result.sub_project_id = -1;
            }
        } else {
            console.warn("Project not found in resolveProjectLinkage for link_id:", link_id, "account_id:", account_id);
        }

        console.log("resolveProjectLinkage complete:", JSON.stringify(result));
    } catch (e) {
        console.error("Error in resolveProjectLinkage:", e);
    }

    return result;
}


function resolveActivityLinkage(tx, link_id, account_id) {
    let result = {
        task_id: -1,
        sub_task_id: -1,
        project_id: -1,
        sub_project_id: -1
    };

    try {
        console.log("resolveActivityLinkage: Starting with link_id:", link_id, "account_id:", account_id);

        // Step 1: Determine if link_id is subtask or task
        let rs_task = tx.executeSql(
            `SELECT odoo_record_id, parent_id, project_id FROM project_task_app WHERE odoo_record_id = ? AND account_id = ? LIMIT 1`,
            [link_id, account_id]
        );

        let resolved_task_id = -1;
        let resolved_sub_task_id = -1;
        let task_project_id = -1;

        if (rs_task.rows.length > 0) {
            let row_task = rs_task.rows.item(0);
            console.log("resolveActivityLinkage: Found task row:", JSON.stringify({
                odoo_record_id: row_task.odoo_record_id,
                parent_id: row_task.parent_id,
                project_id: row_task.project_id
            }));

            let parent_id = sanitizeId(row_task.parent_id);
            console.log("resolveActivityLinkage: Sanitized parent_id:", parent_id, "from raw value:", row_task.parent_id, "type:", typeof row_task.parent_id);

            if (parent_id !== -1 && parent_id !== 0) {  // Has a valid parent (not -1 for invalid, not 0 for no parent)
                // It is a subtask
                resolved_task_id = parent_id;
                resolved_sub_task_id = row_task.odoo_record_id;
                console.log("resolveActivityLinkage: Identified as SUBTASK. Parent task_id:", resolved_task_id, "Sub task_id:", resolved_sub_task_id);

                // For subtask, we need to get project_id from the parent task
                let rs_parent_task = tx.executeSql(
                    `SELECT project_id, odoo_record_id FROM project_task_app WHERE odoo_record_id = ? AND account_id = ? LIMIT 1`,
                    [resolved_task_id, account_id]
                );

                if (rs_parent_task.rows.length > 0) {
                    task_project_id = sanitizeId(rs_parent_task.rows.item(0).project_id);
                    console.log("resolveActivityLinkage: Found parent task with odoo_record_id:", rs_parent_task.rows.item(0).odoo_record_id, "project_id:", task_project_id);
                } else {
                    console.warn("resolveActivityLinkage: Parent task not found for resolved_task_id:", resolved_task_id);

                    // Fallback: try to find parent task by local database id (in case parent_id references local id instead of odoo_record_id)
                    let rs_parent_by_id = tx.executeSql(
                        `SELECT project_id, odoo_record_id FROM project_task_app WHERE id = ? AND account_id = ? LIMIT 1`,
                        [resolved_task_id, account_id]
                    );

                    if (rs_parent_by_id.rows.length > 0) {
                        task_project_id = sanitizeId(rs_parent_by_id.rows.item(0).project_id);
                        console.log("resolveActivityLinkage: Found parent task by local id:", resolved_task_id, "odoo_record_id:", rs_parent_by_id.rows.item(0).odoo_record_id, "project_id:", task_project_id);
                        // Update resolved_task_id to use the correct odoo_record_id
                        resolved_task_id = rs_parent_by_id.rows.item(0).odoo_record_id;
                        console.log("resolveActivityLinkage: Updated resolved_task_id to odoo_record_id:", resolved_task_id);
                    } else {
                        // FINAL FALLBACK: Maybe parent_id is negative (local record), try searching for negative values
                        let rs_parent_negative = tx.executeSql(
                            `SELECT project_id, odoo_record_id FROM project_task_app WHERE odoo_record_id = ? AND account_id = ? LIMIT 1`,
                            [resolved_task_id, account_id]
                        );

                        if (rs_parent_negative.rows.length > 0) {
                            task_project_id = sanitizeId(rs_parent_negative.rows.item(0).project_id);
                            console.log("resolveActivityLinkage: Found parent task with negative odoo_record_id:", resolved_task_id, "project_id:", task_project_id);
                        } else {
                            task_project_id = sanitizeId(row_task.project_id); // Final fallback to subtask's project_id
                            console.log("resolveActivityLinkage: Using final fallback project_id from subtask:", task_project_id);
                        }
                    }
                }
            } else {
                // It is a parent task
                resolved_task_id = row_task.odoo_record_id;
                resolved_sub_task_id = -1;
                task_project_id = sanitizeId(row_task.project_id);
                console.log("resolveActivityLinkage: Identified as PARENT TASK. Task_id:", resolved_task_id, "Project_id:", task_project_id);
            }
        } else {
            console.warn("Link_id is not a valid task in project_task_app:", link_id, "account_id:", account_id);
            return result; // early return if not found
        }

        // Step 2: Determine if project_id is subproject or top-level
        if (task_project_id !== -1) {  // Changed from > 0 to !== -1 to allow negative values
            let rs_project = tx.executeSql(
                `SELECT parent_id FROM project_project_app WHERE odoo_record_id = ? AND account_id = ? LIMIT 1`,
                [task_project_id, account_id]
            );

            if (rs_project.rows.length > 0) {
                let parent_project_id = sanitizeId(rs_project.rows.item(0).parent_id);
                console.log("resolveActivityLinkage: Project parent_id:", parent_project_id);

                if (parent_project_id !== -1 && parent_project_id !== 0) {  // Has a valid parent
                    result.project_id = parent_project_id;         // parent project
                    result.sub_project_id = task_project_id;  // subproject
                    console.log("resolveActivityLinkage: Project is SUBPROJECT. Parent:", parent_project_id, "Sub:", task_project_id);
                } else {
                    result.project_id = task_project_id;     // top-level project
                    result.sub_project_id = -1;
                    console.log("resolveActivityLinkage: Project is TOP-LEVEL:", task_project_id);
                }
            } else {
                console.warn("Project lookup failed for task_project_id:", task_project_id);
                result.project_id = task_project_id;
                result.sub_project_id = -1;
            }
        } else {
            console.warn("resolveActivityLinkage: Invalid task_project_id:", task_project_id);
            result.project_id = -1;
            result.sub_project_id = -1;
        }

        // Set resolved task and subtask IDs
        result.task_id = resolved_task_id;
        result.sub_task_id = resolved_sub_task_id;

        console.log("resolveActivityLinkage complete:", JSON.stringify(result));
    } catch (e) {
        console.error("Error in resolveActivityLinkage:", e);
    }

    return result;
}

function sanitizeId(value) {
    // Handle different data types that SQLite might return
    if (value === null || value === undefined || value === '') {
        return -1;
    }

    // Special case: 0 is valid for parent_id (means "no parent")
    if (value === 0) {
        return 0;
    }

    const numValue = typeof value === 'string' ? parseInt(value, 10) : Number(value);
    // Allow negative values (for locally created records) and positive values, but not NaN
    if (isNaN(numValue)) {
        return -1;
    }

    // Return the value if it's a valid number (positive, negative, or zero)
    return numValue;
}

//enrichment over

/**
 * Retrieves the name of an activity type from the local SQLite database
 * based on the provided Odoo record ID.
 *
 * @function getActivityTypeName
 * @param {number} odooRecordId - The ID of the activity type as stored in Odoo.
 * @returns {string} - Returns the name of the activity type if found, otherwise an empty string.
 *
 * @description
 * Opens a local SQLite database transaction and queries the `mail_activity_type_app` table
 * for a record matching the given `odooRecordId`.
 * Extracts the `name` field from the result and returns it.
 * Logs any exception encountered during the operation via `DBCommon.logException()`.
 */
function getActivityTypeName(odooRecordId) {
    var typeName = "";

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var query = `
            SELECT name FROM mail_activity_type_app
            WHERE odoo_record_id = ?
            LIMIT 1
            `;
            var rs = tx.executeSql(query, [odooRecordId]);

            if (rs.rows.length > 0) {
                typeName = rs.rows.item(0).name;
            }
        });

    } catch (e) {
        DBCommon.logException("getActivityTypeName", e);
    }

    return typeName;
}

/**
 * Marks a specific activity record as "done" in the local SQLite database
 * by updating its `state` and `status` fields.
 *
 * @function markAsDone
 * @param {number} accountId - The local account ID associated with the activity.
 * @param {number} id - The internal ID of the activity record in the local database.
 * @returns {void}
 *
 * @description
 * Opens a local SQLite database transaction and updates the `mail_activity_app` table
 * for the record matching the given `accountId` and `id`.
 * Sets the `state` to "done" and `status` to "updated" to reflect local changes
 * pending sync with Odoo.
 * Logs any exception encountered during the operation via `DBCommon.logException()`.
 */
function markAsDone(accountId, id) {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var query = `
            UPDATE mail_activity_app
            SET state = "done", status = "updated"
            WHERE account_id = ? AND id = ?
            `;
            tx.executeSql(query, [accountId, id]);
            //   console.log("✅ Marked as done: Account ID =", accountId, ", Record ID =", id);
        });

    } catch (e) {
        DBCommon.logException("markAsDone", e);
    }
}

/**
 * Updates the due date of an activity.
 *
 * @function updateActivityDate
 * @param {number} accountId - The local account ID associated with the activity.
 * @param {number} id - The internal ID of the activity record in the local database.
 * @param {string} newDate - The new due date in YYYY-MM-DD format.
 * @returns {void}
 *
 * @description
 * Opens a local SQLite database transaction and updates the `mail_activity_app` table
 * for the record matching the given `accountId` and `id`.
 * Sets the `due_date` to the new date and `status` to "updated" to reflect local changes
 * pending sync with Odoo.
 */
function updateActivityDate(accountId, id, newDate) {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var query = `
            UPDATE mail_activity_app
            SET due_date = ?, status = "updated"
            WHERE account_id = ? AND id = ?
            `;
            tx.executeSql(query, [newDate, accountId, id]);
            console.log("✅ Updated activity date: Account ID =", accountId, ", Record ID =", id, ", New Date =", newDate);
        });

    } catch (e) {
        DBCommon.logException("updateActivityDate", e);
    }
}

/**
 * Returns the appropriate icon filename for a given activity type name.
 *
 * @function getActivityIconForType
 * @param {string} typeName - The name of the activity type (e.g., "Call", "Mail", "Meeting").
 * @returns {string} - The filename of the icon corresponding to the activity type.
 *
 * @description
 * Normalizes the input `typeName` to lowercase and checks for keywords to determine
 * the matching icon:
 * - If it contains "mail", returns `"activity_mail.png"`
 * - If it contains "call", returns `"activity_call.png"`
 * - If it contains "meeting", returns `"activity_meeting.png"`
 * - For all other or missing types, returns `"activity_others.png"`
 */
function getActivityIconForType(typeName) {
    if (!typeName) return "activity_others.png";

    const normalized = typeName.trim().toLowerCase();

    if (normalized.includes("mail")) {
        return "activity_mail.png";
    } else if (normalized.includes("call")) {
        return "activity_call.png";
    } else if (normalized.includes("meeting")) {
        return "activity_meeting.png";
    }
    else {
        return "activity_others.png";
    }
}

/**
 * Retrieves all non-deleted activity types associated with a specific account
 * from the local SQLite database.
 *
 * @function getActivityTypesForAccount
 * @param {number} account_id - The local account ID for which to retrieve activity types.
 * @returns {Array<Object>} - An array of activity type objects linked to the account.
 *
 * @description
 * Opens a local SQLite database transaction and queries the `mail_activity_type_app` table
 * for all records matching the provided `account_id` where `status` is not `'deleted'` or is null.
 * Converts each result row into a JavaScript object using `DBCommon.rowToObject()` and
 * appends it to the `activityTypes` array.
 * Logs any exceptions encountered during the operation via `DBCommon.logException()`.
 */
function getActivityTypesForAccount(account_id) {
    var activityTypes = [];

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var query = `
            SELECT *
            FROM mail_activity_type_app
            WHERE account_id = ? AND (status IS NULL OR status != 'deleted')`;

            var rs = tx.executeSql(query, [account_id]);

            for (var i = 0; i < rs.rows.length; i++) {
                activityTypes.push(DBCommon.rowToObject(rs.rows.item(i)));
            }
        });

    } catch (e) {
        DBCommon.logException("getAllActivityType", e);
    }

    return activityTypes;
}

/**
 * Saves or updates an activity record in the `mail_activity_app` table.
 *
 * @function saveActivityData
 * @param {Object} data - The activity data object containing all necessary fields.
 * @param {number} recordId - The local ID of the activity record. If > 0, the record is updated; otherwise, a new record is inserted.
 * @returns {Object} - Returns { success: true } on success or { success: false, error: <message> } on failure.
 */
function saveActivityData(data, recordId) {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        var timestamp = Utils.getFormattedTimestampUTC();

        db.transaction(function (tx) {
            if (recordId > 0) {
                // UPDATE existing record
                tx.executeSql(
                    `UPDATE mail_activity_app SET
                        account_id = ?,
                        activity_type_id = ?,
                        summary = ?,
                        user_id = ?,
                        due_date = ?,
                        notes = ?,
                        resModel = ?,
                        resId = ?,
                        task_id = ?,
                        project_id = ?,
                        link_id = ?,
                        state = ?,
                        last_modified = ?,
                        status = ?
                     WHERE id = ?`,
                    [
                        data.updatedAccount,
                        data.updatedActivity,
                        data.updatedSummary,
                        data.updatedUserId,
                        Utils.extractDate(data.updatedDate),
                        data.updatedNote,
                        data.resModel,
                        data.resId,
                        data.task_id,
                        data.project_id,
                        data.link_id,
                        data.state,
                        timestamp,
                        data.status,
                        recordId
                    ]
                );
                console.log("✅ Activity record updated: ID " + recordId);
            } else {
                // INSERT new record
                tx.executeSql(
                    `INSERT INTO mail_activity_app (
                        account_id, activity_type_id, summary, user_id, due_date,
                        notes, resModel, resId, task_id, project_id, link_id,
                        state, last_modified, status
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
                    [
                        data.updatedAccount,
                        data.updatedActivity,
                        data.updatedSummary,
                        data.updatedUserId,
                        Utils.extractDate(data.updatedDate),
                        data.updatedNote,
                        data.resModel,
                        data.resId,
                        data.task_id,
                        data.project_id,
                        data.link_id,
                        data.state,
                        timestamp,
                        data.status
                    ]
                );
                console.log("✅ New activity record inserted");
            }
        });

        return { success: true };
    } catch (e) {
        console.error("❌ saveActivityData failed:", e.message);
        return { success: false, error: e.message };
    }
}


/**
 * Creates a new blank activity linked to a project or task and inserts it into the `mail_activity_app` table.
 *
 * @function createActivityFromProjectOrTask
 * @param {boolean} isProject - If true, links activity to a project; if false, links it to a task.
 * @param {number} account_id - The account ID for which the activity is created.
 * @param {number} link_id - The ID of the project or task to link.
 * @returns {Object} - Returns an object:
 *                     { success: true, record_id: <new ID> } on success,
 *                     or { success: false, error: <message> } on failure.
 *
 * @description
 * Creates an empty activity record with default fields. Sets `resModel` to `project.project` if `isProject`
 * is true, otherwise `project.task`. Marks the record's `status` as "new" for sync tracking.
 */
function createActivityFromProjectOrTask(isProject, account_id, link_id) {
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var recordId = 0;

    try {
        var resModel = isProject ? "project.project" : "project.task";
        var timestamp = Utils.getFormattedTimestampUTC();
        var createDate = timestamp.split(" ")[0];

        db.transaction(function (tx) {
            tx.executeSql(
                `INSERT INTO mail_activity_app (
                    account_id, activity_type_id, summary, user_id, due_date,
                    notes, resModel, resId, task_id, project_id, link_id,
                    state, last_modified, status
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
                [
                    account_id,
                    null,             // activity_type_id (empty initially)
                    "Untitled",               // summary (blank)
                    Accounts.getCurrentUserOdooId(account_id), // auto-fill user_id
                    createDate,             //
                    "No Notes",               // notes (blank)
                    resModel,
                    link_id,
                    isProject ? null : link_id,  // task_id if linking to task
                    isProject ? link_id : null,  // project_id if linking to project
                    link_id,
                    "planned",        // default activity state
                    timestamp,
                    "updated"         // mark for sync (must be 'updated' for sync_to_odoo to pick it up)
                ]
            );

            // Retrieve new record ID
            var result = tx.executeSql("SELECT last_insert_rowid() AS id");
            if (result.rows.length > 0) {
                recordId = result.rows.item(0).id;
            }
        });

        console.log("Created new blank activity with ID:", recordId);
        return { success: true, record_id: recordId };

    } catch (e) {
        console.error("createActivityFromProjectOrTask failed:", e.message);
        return { success: false, error: e.message };
    }
}

function createFollowupActivity(account_id, activityId) {
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var newRecordId = 0;

    try {
        var timestamp = Utils.getFormattedTimestampUTC();
        var createDate = timestamp.split(" ")[0];

        db.transaction(function (tx) {
            // 1. Fetch the existing activity
            var result = tx.executeSql(
                "SELECT * FROM mail_activity_app WHERE id = ? AND account_id = ?",
                [activityId, account_id]
            );

            if (result.rows.length === 0) {
                throw new Error("Activity not found for ID " + activityId);
            }

            var original = result.rows.item(0);

            // Validate that the original activity has valid resModel and link_id
            // Activities without proper linkage cannot be synced to Odoo
            if (!original.resModel || original.resModel === "" || original.resModel === null) {
                throw new Error("Cannot create follow-up: Original activity is not linked to any document (resModel is null)");
            }
            if (!original.link_id || original.link_id <= 0) {
                throw new Error("Cannot create follow-up: Original activity has no valid document link (link_id is " + original.link_id + ")");
            }

            // 2. Insert a new record with cloned values
            tx.executeSql(
                `INSERT INTO mail_activity_app (
                    account_id, activity_type_id, summary, user_id, due_date,
                    notes, resModel, resId, task_id, project_id, link_id,
                    state, last_modified, status
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
                [
                    account_id,
                    original.activity_type_id,
                    "Followup: " + (original.summary || "Untitled"),
                    original.user_id,
                    createDate,              // new due date = today
                    original.notes || "",
                    original.resModel,
                    original.resId,
                    original.task_id,
                    original.project_id,
                    original.link_id,
                    "planned",               // reset state
                    timestamp,
                    "updated"                       // unsynced
                ]
            );

            // 3. Get new record ID
            var inserted = tx.executeSql("SELECT last_insert_rowid() AS id");
            if (inserted.rows.length > 0) {
                newRecordId = inserted.rows.item(0).id;
            }
        });

        console.log("Cloned activity", activityId, "into new ID:", newRecordId);
        return { success: true, record_id: newRecordId };

    } catch (e) {
        console.error("cloneActivity failed:", e.message);
        return { success: false, error: e.message };
    }
}


/**
 * Retrieves all non-deleted activities linked to a specific project from the `mail_activity_app` table.
 *
 * @function getActivitiesForProject
 * @param {number} projectOdooRecordId - The odoo_record_id of the project
 * @param {number} accountId - The account ID
 * @returns {Array<Object>} A list of activity objects linked to the specified project.
 */
function getActivitiesForProject(projectOdooRecordId, accountId) {
    var activityList = [];

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        var projectColorMap = {};

        db.transaction(function (tx) {
            // Step 1: Build project color map
            var projectResult = tx.executeSql("SELECT odoo_record_id, color_pallet FROM project_project_app WHERE account_id = ?", [accountId]);
            for (var j = 0; j < projectResult.rows.length; j++) {
                var projectRow = projectResult.rows.item(j);
                projectColorMap[projectRow.odoo_record_id] = projectRow.color_pallet;
            }

            // Step 2: Fetch activities linked to the specific project
            // This includes activities linked directly to the project and activities linked to tasks within the project
            var rs = tx.executeSql(`
                SELECT DISTINCT a.* FROM mail_activity_app a
                WHERE a.account_id = ? 
                AND LOWER(TRIM(COALESCE(a.state, ''))) != 'done'
                AND (
                    (a.resModel = 'project.project' AND a.link_id = ?)
                    OR 
                    (a.resModel = 'project.task' AND a.link_id IN (
                        SELECT odoo_record_id FROM project_task_app 
                        WHERE project_id = ? AND account_id = ?
                    ))
                )
                ORDER BY a.due_date ASC
            `, [accountId, projectOdooRecordId, projectOdooRecordId, accountId]);

            for (var i = 0; i < rs.rows.length; i++) {
                var row = rs.rows.item(i);
                var activity = DBCommon.rowToObject(row);

                // Enrich the activity with project/task details
                if (activity.resModel === "project.task") {
                    var enrichedTask = resolveActivityLinkage(tx, activity.link_id, activity.account_id);
                    activity.task_id = enrichedTask.task_id;
                    activity.sub_task_id = enrichedTask.sub_task_id;
                    activity.project_id = enrichedTask.project_id;
                    activity.sub_project_id = enrichedTask.sub_project_id;
                    activity.linkedType = "task";
                } else if (activity.resModel === "project.project") {
                    var enrichedProject = resolveProjectLinkage(tx, activity.link_id, activity.account_id);
                    activity.task_id = enrichedProject.task_id;
                    activity.sub_task_id = enrichedProject.sub_task_id;
                    activity.project_id = enrichedProject.project_id;
                    activity.sub_project_id = enrichedProject.sub_project_id;
                    activity.linkedType = "project";
                } else if (activity.resModel === "project.update") {
                    initializeEnrichmentDefaults(activity);
                    activity.update_id = activity.link_id;
                    activity.linkedType = "update";
                } else {
                    initializeEnrichmentDefaults(activity);
                }

                // Add color inheritance
                var colorProjectId = activity.project_id !== -1 ? activity.project_id : activity.sub_project_id;
                if (colorProjectId !== -1 && projectColorMap[colorProjectId]) {
                    activity.color_pallet = projectColorMap[colorProjectId];
                } else {
                    activity.color_pallet = 0; // Default color
                }

                activityList.push(activity);
            }
        });

    } catch (e) {
        DBCommon.logException("getActivitiesForProject", e);
    }

    return activityList;
}

/**
 * Paginated version of getActivitiesForProject for infinite scroll.
 *
 * @param {number} projectOdooRecordId - The odoo_record_id of the project
 * @param {number} accountId - The account ID
 * @param {number} limit - Maximum number of items to return
 * @param {number} offset - Number of items to skip
 * @returns {Object} { activities: Array, hasMore: boolean }
 */
function getActivitiesForProjectPaginated(projectOdooRecordId, accountId, limit, offset) {
    var activityList = [];
    limit = limit || 30;
    offset = offset || 0;

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        var projectColorMap = {};

        db.transaction(function (tx) {
            // Step 1: Build project color map
            var projectResult = tx.executeSql("SELECT odoo_record_id, color_pallet FROM project_project_app WHERE account_id = ?", [accountId]);
            for (var j = 0; j < projectResult.rows.length; j++) {
                var projectRow = projectResult.rows.item(j);
                projectColorMap[projectRow.odoo_record_id] = projectRow.color_pallet;
            }

            // Step 2: Fetch activities linked to the specific project with LIMIT/OFFSET
            var rs = tx.executeSql(`
                SELECT DISTINCT a.* FROM mail_activity_app a
                WHERE a.account_id = ? 
                AND LOWER(TRIM(COALESCE(a.state, ''))) != 'done'
                AND (
                    (a.resModel = 'project.project' AND a.link_id = ?)
                    OR 
                    (a.resModel = 'project.task' AND a.link_id IN (
                        SELECT odoo_record_id FROM project_task_app 
                        WHERE project_id = ? AND account_id = ?
                    ))
                )
                ORDER BY a.due_date ASC
                LIMIT ? OFFSET ?
            `, [accountId, projectOdooRecordId, projectOdooRecordId, accountId, limit, offset]);

            for (var i = 0; i < rs.rows.length; i++) {
                var row = rs.rows.item(i);
                var activity = DBCommon.rowToObject(row);

                // Enrich the activity with project/task details
                if (activity.resModel === "project.task") {
                    var enrichedTask = resolveActivityLinkage(tx, activity.link_id, activity.account_id);
                    activity.task_id = enrichedTask.task_id;
                    activity.sub_task_id = enrichedTask.sub_task_id;
                    activity.project_id = enrichedTask.project_id;
                    activity.sub_project_id = enrichedTask.sub_project_id;
                    activity.linkedType = "task";
                } else if (activity.resModel === "project.project") {
                    var enrichedProject = resolveProjectLinkage(tx, activity.link_id, activity.account_id);
                    activity.task_id = enrichedProject.task_id;
                    activity.sub_task_id = enrichedProject.sub_task_id;
                    activity.project_id = enrichedProject.project_id;
                    activity.sub_project_id = enrichedProject.sub_project_id;
                    activity.linkedType = "project";
                } else if (activity.resModel === "project.update") {
                    initializeEnrichmentDefaults(activity);
                    activity.update_id = activity.link_id;
                    activity.linkedType = "update";
                } else {
                    initializeEnrichmentDefaults(activity);
                }

                // Add color inheritance
                var colorProjectId = activity.project_id !== -1 ? activity.project_id : activity.sub_project_id;
                if (colorProjectId !== -1 && projectColorMap[colorProjectId]) {
                    activity.color_pallet = projectColorMap[colorProjectId];
                } else {
                    activity.color_pallet = 0;
                }

                activityList.push(activity);
            }
        });

    } catch (e) {
        DBCommon.logException("getActivitiesForProjectPaginated", e);
    }

    return {
        activities: activityList,
        hasMore: activityList.length >= limit
    };
}

function getActivitiesForTask(taskOdooRecordId, accountId) {
    var activityList = [];

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        var projectColorMap = {};

        db.transaction(function (tx) {
            // Build project color map
            var projectResult = tx.executeSql("SELECT odoo_record_id, color_pallet FROM project_project_app");
            for (var j = 0; j < projectResult.rows.length; j++) {
                var projectRow = projectResult.rows.item(j);
                projectColorMap[projectRow.odoo_record_id] = projectRow.color_pallet;
            }

            // Get the task's project_id for color inheritance
            var taskProjectId = null;
            var taskRs = tx.executeSql(
                "SELECT project_id FROM project_task_app WHERE odoo_record_id = ? LIMIT 1",
                [taskOdooRecordId]
            );
            if (taskRs.rows.length > 0) {
                taskProjectId = taskRs.rows.item(0).project_id;
            }

            var query = `
                SELECT * FROM mail_activity_app
                WHERE resModel = 'project.task' 
                AND link_id = ?
                AND LOWER(TRIM(COALESCE(state, ''))) != 'done'
                AND (status IS NULL OR status != 'deleted')
                ORDER BY due_date ASC`;
            var params = [taskOdooRecordId];

            // If accountId is provided, filter by it
            if (accountId && accountId > 0) {
                query = `
                    SELECT * FROM mail_activity_app
                    WHERE resModel = 'project.task' 
                    AND link_id = ?
                    AND account_id = ?
                    AND LOWER(TRIM(COALESCE(state, ''))) != 'done'
                    AND (status IS NULL OR status != 'deleted')
                    ORDER BY due_date ASC`;
                params = [taskOdooRecordId, accountId];
            }

            var rs = tx.executeSql(query, params);
            console.log("getActivitiesForTask: Found", rs.rows.length, "activities for task:", taskOdooRecordId);

            for (var i = 0; i < rs.rows.length; i++) {
                var row = rs.rows.item(i);
                var activity = DBCommon.rowToObject(row);

                // Inherit color from task's project
                if (taskProjectId && projectColorMap[taskProjectId]) {
                    activity.color_pallet = parseInt(projectColorMap[taskProjectId]) || 0;
                } else {
                    activity.color_pallet = 0;
                }

                activityList.push(activity);
            }
        });

    } catch (e) {
        DBCommon.logException("getActivitiesForTask", e);
    }

    return activityList;
}

/**
 * Paginated version of getActivitiesForTask for infinite scroll.
 *
 * @param {number} taskOdooRecordId - The Odoo record ID of the task.
 * @param {number} accountId - The account ID (optional, if provided will filter by account).
 * @param {number} limit - Maximum number of items to return.
 * @param {number} offset - Number of items to skip.
 * @returns {Object} { activities: Array, hasMore: boolean }
 */
function getActivitiesForTaskPaginated(taskOdooRecordId, accountId, limit, offset) {
    var activityList = [];
    limit = limit || 30;
    offset = offset || 0;

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        var projectColorMap = {};

        db.transaction(function (tx) {
            // Build project color map
            var projectResult = tx.executeSql("SELECT odoo_record_id, color_pallet FROM project_project_app");
            for (var j = 0; j < projectResult.rows.length; j++) {
                var projectRow = projectResult.rows.item(j);
                projectColorMap[projectRow.odoo_record_id] = projectRow.color_pallet;
            }

            // Get the task's project_id for color inheritance
            var taskProjectId = null;
            var taskRs = tx.executeSql(
                "SELECT project_id FROM project_task_app WHERE odoo_record_id = ? LIMIT 1",
                [taskOdooRecordId]
            );
            if (taskRs.rows.length > 0) {
                taskProjectId = taskRs.rows.item(0).project_id;
            }

            var query = "";
            var params = [];

            // If accountId is provided, filter by it
            if (accountId && accountId > 0) {
                query = `
                    SELECT * FROM mail_activity_app
                    WHERE resModel = 'project.task' 
                    AND link_id = ?
                    AND account_id = ?
                    AND LOWER(TRIM(COALESCE(state, ''))) != 'done'
                    AND (status IS NULL OR status != 'deleted')
                    ORDER BY due_date ASC
                    LIMIT ? OFFSET ?`;
                params = [taskOdooRecordId, accountId, limit, offset];
            } else {
                query = `
                    SELECT * FROM mail_activity_app
                    WHERE resModel = 'project.task' 
                    AND link_id = ?
                    AND LOWER(TRIM(COALESCE(state, ''))) != 'done'
                    AND (status IS NULL OR status != 'deleted')
                    ORDER BY due_date ASC
                    LIMIT ? OFFSET ?`;
                params = [taskOdooRecordId, limit, offset];
            }

            var rs = tx.executeSql(query, params);

            for (var i = 0; i < rs.rows.length; i++) {
                var row = rs.rows.item(i);
                var activity = DBCommon.rowToObject(row);

                // Inherit color from task's project
                if (taskProjectId && projectColorMap[taskProjectId]) {
                    activity.color_pallet = parseInt(projectColorMap[taskProjectId]) || 0;
                } else {
                    activity.color_pallet = 0;
                }

                activityList.push(activity);
            }
        });

    } catch (e) {
        DBCommon.logException("getActivitiesForTaskPaginated", e);
    }

    return {
        activities: activityList,
        hasMore: activityList.length >= limit
    };
}

/**
 * Deletes an activity record from the local database.
 * This is useful for cleaning up activities that were created but never properly saved.
 *
 * @function deleteActivity
 * @param {number} accountId - The account ID associated with the activity.
 * @param {number} recordId - The local ID of the activity record to delete.
 * @returns {Object} - Returns { success: true } on success or { success: false, error: <message> } on failure.
 */
function deleteActivity(accountId, recordId) {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var query = `DELETE FROM mail_activity_app WHERE account_id = ? AND id = ?`;
            tx.executeSql(query, [accountId, recordId]);
            console.log("✅ Deleted activity: Account ID =", accountId, ", Record ID =", recordId);
        });

        return { success: true };
    } catch (e) {
        DBCommon.logException("deleteActivity", e);
        return { success: false, error: e.message };
    }
}

/**
 * Checks if an activity is still in its default "unsaved" state.
 * An activity is considered unsaved if it has default values for summary and notes.
 *
 * @function isActivityUnsaved
 * @param {number} accountId - The account ID associated with the activity.
 * @param {number} recordId - The local ID of the activity record to check.
 * @returns {boolean} - Returns true if the activity appears to be unsaved, false otherwise.
 */
function isActivityUnsaved(accountId, recordId) {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        var isUnsaved = false;

        db.transaction(function (tx) {
            var query = `SELECT summary, notes, activity_type_id FROM mail_activity_app WHERE account_id = ? AND id = ? LIMIT 1`;
            var rs = tx.executeSql(query, [accountId, recordId]);

            if (rs.rows.length > 0) {
                var row = rs.rows.item(0);
                var summary = (row.summary || "").trim();
                var notes = (row.notes || "").trim();
                var activityTypeId = row.activity_type_id;

                // Consider unsaved if:
                // 1. Summary is "Untitled" or empty
                // 2. Notes is "No Notes" or empty  
                // 3. No activity type selected (null or empty)
                isUnsaved = (summary === "Untitled" || summary === "") &&
                    (notes === "No Notes" || notes === "") &&
                    (activityTypeId === null || activityTypeId === "");
            }
        });

        return isUnsaved;
    } catch (e) {
        DBCommon.logException("isActivityUnsaved", e);
        return false;
    }
}

/**
* Retrieves activities for a specific account, similar to getTasksForAccount
* @param {number} accountId - The account identifier
* @returns {Array<Object>} Array of activity records for the specified account
*/
function getActivitiesForAccount(accountId) {
    var activityList = [];

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        var projectColorMap = {};

        db.transaction(function (tx) {

            var projectResult = tx.executeSql("SELECT odoo_record_id, color_pallet FROM project_project_app WHERE account_id = ?", [accountId]);
            for (var j = 0; j < projectResult.rows.length; j++) {
                var row = projectResult.rows.item(j);
                projectColorMap[row.odoo_record_id] = row.color_pallet;
            }


            var rs = tx.executeSql(`
                SELECT * FROM mail_activity_app
                WHERE LOWER(TRIM(COALESCE(state, ''))) != 'done' AND account_id = ?
                ORDER BY due_date ASC
            `, [accountId]);

            for (var i = 0; i < rs.rows.length; i++) {
                var row = rs.rows.item(i);
                var activity = DBCommon.rowToObject(row);


                let inheritedColor = 0;

                if (activity.resModel === "project.project" && activity.link_id) {
                    inheritedColor = projectColorMap[activity.link_id] || 0;

                } else if (activity.resModel === "project.task" && activity.link_id) {

                    var taskRs = tx.executeSql(
                        "SELECT project_id FROM project_task_app WHERE odoo_record_id = ? AND account_id = ? LIMIT 1",
                        [activity.link_id, accountId]
                    );

                    if (taskRs.rows.length > 0) {
                        var taskProjectId = taskRs.rows.item(0).project_id;
                        inheritedColor = projectColorMap[taskProjectId] || 0;
                    }
                }


                activity.color_pallet = parseInt(inheritedColor) || 0;

                activityList.push(activity);
            }
        });

    } catch (e) {
        DBCommon.logException("getActivitiesForAccount", e);
    }

    return activityList;
}

/**
* Retrieves done activities for a specific account
* @param {number} accountId - The account identifier
* @returns {Array<Object>} Array of done activity records for the specified account
*/
function getDoneActivitiesForAccount(accountId) {
    var activityList = [];

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        var projectColorMap = {};

        db.transaction(function (tx) {

            var projectResult = tx.executeSql("SELECT odoo_record_id, color_pallet FROM project_project_app WHERE account_id = ?", [accountId]);
            for (var j = 0; j < projectResult.rows.length; j++) {
                var row = projectResult.rows.item(j);
                projectColorMap[row.odoo_record_id] = row.color_pallet;
            }


            var rs = tx.executeSql(`
                SELECT * FROM mail_activity_app
                WHERE LOWER(TRIM(COALESCE(state, ''))) = 'done' AND account_id = ?
                ORDER BY due_date DESC
            `, [accountId]);

            for (var i = 0; i < rs.rows.length; i++) {
                var row = rs.rows.item(i);
                var activity = DBCommon.rowToObject(row);


                let inheritedColor = 0;

                if (activity.resModel === "project.project" && activity.link_id) {
                    inheritedColor = projectColorMap[activity.link_id] || 0;

                } else if (activity.resModel === "project.task" && activity.link_id) {

                    var taskRs = tx.executeSql(
                        "SELECT project_id FROM project_task_app WHERE odoo_record_id = ? AND account_id = ? LIMIT 1",
                        [activity.link_id, accountId]
                    );

                    if (taskRs.rows.length > 0) {
                        var taskProjectId = taskRs.rows.item(0).project_id;
                        inheritedColor = projectColorMap[taskProjectId] || 0;
                    }
                }


                activity.color_pallet = parseInt(inheritedColor) || 0;

                activityList.push(activity);
            }
        });

    } catch (e) {
        DBCommon.logException("getDoneActivitiesForAccount", e);
    }

    return activityList;
}

/**
 * Paginated version of getDoneActivitiesForAccount for infinite scroll.
 * 
 * @param {number} accountId - The account identifier
 * @param {number} limit - Maximum number of items to return
 * @param {number} offset - Number of items to skip
 * @returns {Array<Object>} Array of done activity records for the specified account
 */
function getDoneActivitiesForAccountPaginated(accountId, limit, offset) {
    var activityList = [];
    limit = limit || 30;
    offset = offset || 0;

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        var projectColorMap = {};

        db.transaction(function (tx) {
            var projectResult = tx.executeSql("SELECT odoo_record_id, color_pallet FROM project_project_app WHERE account_id = ?", [accountId]);
            for (var j = 0; j < projectResult.rows.length; j++) {
                var row = projectResult.rows.item(j);
                projectColorMap[row.odoo_record_id] = row.color_pallet;
            }

            var rs = tx.executeSql(`
                SELECT * FROM mail_activity_app
                WHERE LOWER(TRIM(COALESCE(state, ''))) = 'done' AND account_id = ?
                ORDER BY due_date ASC
                LIMIT ? OFFSET ?
            `, [accountId, limit, offset]);

            for (var i = 0; i < rs.rows.length; i++) {
                var row = rs.rows.item(i);
                var activity = DBCommon.rowToObject(row);

                let inheritedColor = 0;
                if (activity.resModel === "project.project" && activity.link_id) {
                    inheritedColor = projectColorMap[activity.link_id] || 0;
                } else if (activity.resModel === "project.task" && activity.link_id) {
                    var taskRs = tx.executeSql(
                        "SELECT project_id FROM project_task_app WHERE odoo_record_id = ? AND account_id = ? LIMIT 1",
                        [activity.link_id, accountId]
                    );
                    if (taskRs.rows.length > 0) {
                        var taskProjectId = taskRs.rows.item(0).project_id;
                        inheritedColor = projectColorMap[taskProjectId] || 0;
                    }
                }

                activity.color_pallet = parseInt(inheritedColor) || 0;
                activityList.push(activity);
            }
        });

    } catch (e) {
        DBCommon.logException("getDoneActivitiesForAccountPaginated", e);
    }

    return activityList;
}

/**
* Gets filtered activities with optional account filtering
* Similar to Task.getFilteredTasks() but for activities
* @param {string} filterType - The filter type: "today", "week", "month", "later", "overdue", "all", "done"
* @param {string} searchQuery - The search query string
* @param {number} accountId - Optional account ID to filter by
* @returns {Array<Object>} Filtered list of activities
*/
function getFilteredActivities(filterType, searchQuery, accountId) {
    var allActivities;

    // Handle "done" filter separately since done activities are excluded from normal queries
    if (filterType === "done") {
        if (accountId !== undefined && accountId >= 0) {
            allActivities = getDoneActivitiesForAccount(accountId);
        } else {
            allActivities = getDoneActivities(); // Assuming getDoneActivities() exists for all accounts
        }

        // For done activities, only apply search filter (no date filter needed)
        if (!searchQuery || searchQuery.trim() === "") {
            return allActivities;
        }

        var filteredDoneActivities = [];
        for (var i = 0; i < allActivities.length; i++) {
            if (passesActivitySearchFilter(allActivities[i], searchQuery)) {
                filteredDoneActivities.push(allActivities[i]);
            }
        }
        return filteredDoneActivities;
    }

    if (accountId !== undefined && accountId >= 0) {
        allActivities = getActivitiesForAccount(accountId);
    } else {
        allActivities = getAllActivities();
    }

    var filteredActivities = [];
    var currentDate = new Date();

    for (var i = 0; i < allActivities.length; i++) {
        var activity = allActivities[i];
        var passesFilter = true;


        if (!passesActivityDateFilter(activity, filterType, currentDate)) {
            passesFilter = false;
        }


        if (passesFilter && searchQuery && !passesActivitySearchFilter(activity, searchQuery)) {
            passesFilter = false;
        }

        if (passesFilter) {
            filteredActivities.push(activity);
        }
    }

    return filteredActivities;
}

/**
 * Paginated version of getFilteredActivities for infinite scroll with date/search filtering.
 * Fetches activities in batches, applies JS-based filtering, and returns paginated results.
 * 
 * @param {string} filterType - The filter type: "today", "this_week", "overdue", etc.
 * @param {string} searchQuery - The search query string
 * @param {number} accountId - Account ID to filter activities (-1 for all accounts)
 * @param {number} limit - Maximum number of filtered items to return
 * @param {number} offset - Number of filtered items to skip (virtual offset)
 * @returns {Object} { activities: Array, hasMore: boolean }
 */
function getFilteredActivitiesPaginated(filterType, searchQuery, accountId, limit, offset) {
    limit = limit || 30;
    offset = offset || 0;

    // Handle "done" filter separately
    if (filterType === "done") {
        // Ensure search is applied before pagination so matches are not missed.
        var doneActivities = getFilteredActivities("done", searchQuery, accountId);
        var donePage = doneActivities.slice(offset, offset + limit);
        return {
            activities: donePage,
            hasMore: (offset + limit) < doneActivities.length
        };
    }

    var filteredActivities = [];
    var currentDate = new Date();
    var batchSize = limit * 3; // Fetch 3x more raw items to account for filtering
    var dbOffset = 0;
    var skipped = 0;
    var foundAfterOffset = 0;
    var hasMore = true;

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        while (hasMore && foundAfterOffset < (limit + 1)) {
            var rawActivities = [];

            db.transaction(function (tx) {
                var query = "SELECT * FROM mail_activity_app WHERE LOWER(TRIM(COALESCE(state, ''))) != 'done'";
                var params = [];

                if (accountId !== undefined && accountId >= 0) {
                    query += " AND account_id = ?";
                    params.push(accountId);
                }

                query += " ORDER BY due_date ASC LIMIT ? OFFSET ?";
                params.push(batchSize, dbOffset);

                var result = tx.executeSql(query, params);
                for (var i = 0; i < result.rows.length; i++) {
                    rawActivities.push(DBCommon.rowToObject(result.rows.item(i)));
                }
            });

            // If we got fewer items than batch size, no more data in DB
            if (rawActivities.length < batchSize) {
                hasMore = false;
            }

            // Apply JS-based filtering
            for (var i = 0; i < rawActivities.length; i++) {
                var activity = rawActivities[i];
                var passesFilter = true;

                // Apply date filter using existing logic
                if (filterType && filterType !== "all" && !passesActivityDateFilter(activity, filterType, currentDate)) {
                    passesFilter = false;
                }

                // Apply search filter
                if (passesFilter && searchQuery && !passesActivitySearchFilter(activity, searchQuery)) {
                    passesFilter = false;
                }

                if (passesFilter) {
                    if (skipped < offset) {
                        // Skip items until we reach the offset
                        skipped++;
                    } else {
                        foundAfterOffset++;
                        // Collect only up to limit + 1 to derive hasMore correctly.
                        if (filteredActivities.length < (limit + 1)) {
                            filteredActivities.push(activity);
                        }
                    }

                    if (foundAfterOffset >= (limit + 1)) {
                        // We have enough items to build page + hasMore.
                        break;
                    }
                }
            }

            dbOffset += rawActivities.length;
        }

        // Add project colors to filtered activities
        db.transaction(function (tx) {
            var projectColorMap = {};
            var projectQuery = "SELECT odoo_record_id, color_pallet FROM project_project_app";
            var projectResult = tx.executeSql(projectQuery);
            for (var j = 0; j < projectResult.rows.length; j++) {
                projectColorMap[projectResult.rows.item(j).odoo_record_id] = projectResult.rows.item(j).color_pallet;
            }

            var pageSize = Math.min(filteredActivities.length, limit);
            for (var i = 0; i < pageSize; i++) {
                var activity = filteredActivities[i];

                // Inherit color from project
                var inheritedColor = 0;
                if (activity.resModel === "project.project" && activity.link_id) {
                    inheritedColor = projectColorMap[activity.link_id] || 0;
                } else if (activity.resModel === "project.task" && activity.link_id) {
                    var taskRs = tx.executeSql(
                        "SELECT project_id FROM project_task_app WHERE odoo_record_id = ? LIMIT 1",
                        [activity.link_id]
                    );
                    if (taskRs.rows.length > 0 && taskRs.rows.item(0).project_id) {
                        inheritedColor = projectColorMap[taskRs.rows.item(0).project_id] || 0;
                    }
                }
                activity.color_pallet = inheritedColor;
            }
        });

    } catch (e) {
        console.error("getFilteredActivitiesPaginated failed:", e);
    }

    var pageActivities = filteredActivities.slice(0, limit);
    return {
        activities: pageActivities,
        hasMore: foundAfterOffset > limit
    };
}

/**
* Gets account statistics for activities (similar to Task.getAccountsWithTaskCounts)
* @returns {Array<Object>} Array of account objects with activity counts
*/
function getAccountsWithActivityCounts() {
    var accounts = [];
    console.log("🔍 getAccountsWithActivityCounts called");

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var query = `
                SELECT
                    a.account_id,
                    COUNT(a.id) as activity_count,
                    COUNT(CASE WHEN LOWER(TRIM(COALESCE(a.state, ''))) != 'done' THEN 1 END) as active_activity_count
                FROM mail_activity_app a
                GROUP BY a.account_id
                ORDER BY a.account_id ASC
            `;

            var result = tx.executeSql(query);
            console.log("📊 Found", result.rows.length, "accounts with activities in database");

            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);
                console.log("📝 DB Account:", row.account_id, "Total activities:", row.activity_count, "Active activities:", row.active_activity_count);
                accounts.push({
                    account_id: row.account_id,
                    account_name: row.account_id === 0 ? "Local Account" : "Account " + row.account_id,
                    activity_count: row.activity_count,
                    active_activity_count: row.active_activity_count
                });
            }
        });
    } catch (e) {
        console.error("❌ getAccountsWithActivityCounts failed:", e);
    }

    console.log("📊 Returning", accounts.length, "accounts with activities");
    return accounts;
}

/**
* Helper function to check if activity passes date filter
* @param {Object} activity - The activity object
* @param {string} filter - The filter type
* @param {Date} currentDate - Current date for comparison
* @returns {boolean} True if activity passes the filter
*/
function passesActivityDateFilter(activity, filter, currentDate) {

    if (filter === "all") {
        return true;
    }


    if (!activity.due_date) {
        return false;
    }

    var dueDate = new Date(activity.due_date);
    var today = new Date(currentDate.getFullYear(), currentDate.getMonth(), currentDate.getDate());
    var itemDate = new Date(dueDate.getFullYear(), dueDate.getMonth(), dueDate.getDate());


    var isOverdue = itemDate < today;

    switch (filter) {
        case "today":

            return itemDate.getTime() <= today.getTime();
        case "week":
            var weekStart = new Date(today);

            weekStart.setDate(today.getDate() - today.getDay());
            var weekEnd = new Date(weekStart);
            weekEnd.setDate(weekStart.getDate() + 6);


            return (itemDate >= weekStart && itemDate <= weekEnd) && !isOverdue;
        case "month":
            var isThisMonth = itemDate.getFullYear() === today.getFullYear() && itemDate.getMonth() === today.getMonth();


            return isThisMonth && !isOverdue;
        case "later":

            var monthEnd = new Date(today.getFullYear(), today.getMonth() + 1, 0); // Last day of current month
            var monthEndDay = new Date(monthEnd.getFullYear(), monthEnd.getMonth(), monthEnd.getDate());


            return itemDate > monthEndDay && !isOverdue;
        case "overdue":

            return isOverdue;
        default:
            return true;
    }
}

/**
* Helper function to check if activity passes search filter
* @param {Object} activity - The activity object
* @param {string} searchQuery - The search query
* @returns {boolean} True if activity matches the search
*/
function passesActivitySearchFilter(activity, searchQuery) {
    if (!searchQuery || searchQuery.trim() === "") {
        return true;
    }

    var query = searchQuery.toLowerCase().trim();


    if (activity.summary && activity.summary.toLowerCase().indexOf(query) >= 0) {
        return true;
    }


    if (activity.notes && activity.notes.toLowerCase().indexOf(query) >= 0) {
        return true;
    }


    var activityTypeName = getActivityTypeName(activity.activity_type_id);
    if (activityTypeName && activityTypeName.toLowerCase().indexOf(query) >= 0) {
        return true;
    }

    // Search in assignee/user name
    try {
        var userName = Accounts.getUserNameByOdooId(activity.user_id, activity.account_id);
        if (userName && userName.toLowerCase().indexOf(query) >= 0) {
            return true;
        }
    } catch (e) {
    }

    // Search in project name
    try {
        if (activity.project_id && parseInt(activity.project_id) > 0) {
            var projectDetails = Project.getProjectDetails(activity.project_id);
            if (projectDetails && projectDetails.name && projectDetails.name.toLowerCase().indexOf(query) >= 0) {
                return true;
            }
        }
    } catch (e) {
    }

    // Search in task name
    try {
        var taskId = activity.task_id;
        if ((!taskId || parseInt(taskId) <= 0) && activity.resModel === "project.task") {
            taskId = activity.link_id;
        }
        if (taskId && parseInt(taskId) > 0) {
            var taskDetails = Task.getTaskDetails(taskId);
            if (taskDetails && taskDetails.name && taskDetails.name.toLowerCase().indexOf(query) >= 0) {
                return true;
            }
        }
    } catch (e) {
    }

    return false;
}

/**
 * Gets all unique assignees who have been assigned to activities in the given account
 * @param {number} accountId - The account ID to filter assignees by (use -1 for all accounts)
 * @returns {Array} Array of assignee objects with id, name, and odoo_record_id
 */
function getAllActivityAssignees(accountId) {
    var assignees = [];

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            // Get all unique user IDs from activities
            var activityQuery, activityParams;

            if (accountId === -1) {
                // Get from all accounts
                activityQuery = `
                    SELECT DISTINCT user_id, account_id
                    FROM mail_activity_app 
                    WHERE user_id IS NOT NULL AND user_id != '' AND user_id != 0
                `;
                activityParams = [];
            } else {
                // Get from specific account
                activityQuery = `
                    SELECT DISTINCT user_id, account_id
                    FROM mail_activity_app 
                    WHERE account_id = ? AND user_id IS NOT NULL AND user_id != '' AND user_id != 0
                `;
                activityParams = [accountId];
            }

            var activityResult = tx.executeSql(activityQuery, activityParams);

            var userAccountMap = {}; // Map user_id -> account_id for users

            // Parse user IDs from all activities
            for (var i = 0; i < activityResult.rows.length; i++) {
                var row = activityResult.rows.item(i);
                var userIdField = row.user_id;
                var activityAccountId = row.account_id;

                if (userIdField && parseInt(userIdField) > 0) {
                    userAccountMap[parseInt(userIdField)] = activityAccountId;
                }
            }

            var allUserIds = Object.keys(userAccountMap).map(function (key) { return parseInt(key); });

            if (allUserIds.length > 0) {
                // Group user IDs by account for efficient querying
                var accountUserMap = {};
                for (var userId in userAccountMap) {
                    var userAccountId = userAccountMap[userId];
                    if (!accountUserMap[userAccountId]) {
                        accountUserMap[userAccountId] = [];
                    }
                    accountUserMap[userAccountId].push(parseInt(userId));
                }

                // Query each account's users
                for (var acctId in accountUserMap) {
                    var userIds = accountUserMap[acctId];
                    var placeholders = userIds.map(function () { return '?'; }).join(',');

                    var userQuery = `
                        SELECT u.id, u.odoo_record_id, u.name, u.account_id, a.name as account_name
                        FROM res_users_app u
                        LEFT JOIN users a ON u.account_id = a.id
                        WHERE u.account_id = ? AND u.odoo_record_id IN (${placeholders})
                        ORDER BY u.name COLLATE NOCASE ASC
                    `;

                    var queryParams = [acctId].concat(userIds);
                    var userResult = tx.executeSql(userQuery, queryParams);

                    for (var k = 0; k < userResult.rows.length; k++) {
                        var userRow = userResult.rows.item(k);
                        console.log("Loading activity assignee:", userRow.name, "Account:", userRow.account_name, "ID:", userRow.odoo_record_id);
                        assignees.push({
                            id: userRow.id,
                            odoo_record_id: userRow.odoo_record_id,
                            name: userRow.name,
                            account_id: userRow.account_id,
                            account_name: userRow.account_name || "Unknown Account"
                        });
                    }
                }
            }
        });
    } catch (e) {
        console.error("getAllActivityAssignees failed:", e);
    }

    return assignees;
}

/**
 * Gets filtered activities with optional assignee filtering
 * @param {string} filterType - The date filter type
 * @param {string} searchQuery - The search query string
 * @param {number} accountId - Optional account ID to filter by
 * @param {Array} assigneeIds - Optional array of assignee IDs to filter by
 * @returns {Array<Object>} Filtered list of activities
 */
function getFilteredActivitiesWithAssignees(filterType, searchQuery, accountId, assigneeIds) {
    var allActivities;

    if (accountId !== undefined && accountId >= 0) {
        allActivities = getActivitiesForAccount(accountId);
    } else {
        allActivities = getAllActivities();
    }

    var filteredActivities = [];
    var currentDate = new Date();

    for (var i = 0; i < allActivities.length; i++) {
        var activity = allActivities[i];
        var passesFilter = true;

        // Apply date filter
        if (!passesActivityDateFilter(activity, filterType, currentDate)) {
            passesFilter = false;
        }

        // Apply search filter
        if (passesFilter && searchQuery && !passesActivitySearchFilter(activity, searchQuery)) {
            passesFilter = false;
        }

        // Apply assignee filter
        if (passesFilter && assigneeIds && assigneeIds.length > 0) {
            var activityUserId = parseInt(activity.user_id);
            if (!activityUserId || assigneeIds.indexOf(activityUserId) === -1) {
                passesFilter = false;
            }
        }

        if (passesFilter) {
            filteredActivities.push(activity);
        }
    }

    return filteredActivities;
}

/**
 * Paginated version of getDoneActivities (all accounts) for infinite scroll.
 * 
 * @param {number} limit - Maximum number of items to return
 * @param {number} offset - Number of items to skip
 * @returns {Array<Object>} Array of done activity records
 */
function getAllDoneActivitiesPaginated(limit, offset) {
    var activityList = [];
    limit = limit || 30;
    offset = offset || 0;

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        var projectColorMap = {};

        db.transaction(function (tx) {
            var projectResult = tx.executeSql("SELECT odoo_record_id, color_pallet FROM project_project_app");
            for (var j = 0; j < projectResult.rows.length; j++) {
                var row = projectResult.rows.item(j);
                projectColorMap[row.odoo_record_id] = row.color_pallet;
            }

            var rs = tx.executeSql(`
                SELECT * FROM mail_activity_app
                WHERE LOWER(TRIM(COALESCE(state, ''))) = 'done'
                ORDER BY due_date ASC
                LIMIT ? OFFSET ?
            `, [limit, offset]);

            for (var i = 0; i < rs.rows.length; i++) {
                var row = rs.rows.item(i);
                var activity = DBCommon.rowToObject(row);

                let inheritedColor = 0;
                if (activity.resModel === "project.project" && activity.link_id) {
                    inheritedColor = projectColorMap[activity.link_id] || 0;
                } else if (activity.resModel === "project.task" && activity.link_id) {
                    var taskRs = tx.executeSql(
                        "SELECT project_id FROM project_task_app WHERE odoo_record_id = ? LIMIT 1",
                        [activity.link_id]
                    );
                    if (taskRs.rows.length > 0) {
                        var taskProjectId = taskRs.rows.item(0).project_id;
                        inheritedColor = projectColorMap[taskProjectId] || 0;
                    }
                }

                activity.color_pallet = parseInt(inheritedColor) || 0;
                activityList.push(activity);
            }
        });

    } catch (e) {
        DBCommon.logException("getAllDoneActivitiesPaginated", e);
    }

    return activityList;
}

/**
 * Gets activities where the current user is the assignee (user_id) OR the creator (create_uid).
 * This is the "My Items" filter — shows items relevant to the current user.
 *
 * @param {Array} userIds - Array of composite {user_id, account_id} objects (from getCurrentUserAssigneeIds)
 * @param {string} filterType - Date filter: "today", "week", "month", "later", "overdue", "all", "done"
 * @param {string} searchQuery - Search text to filter by
 * @param {number} accountId - Account ID (-1 for all accounts)
 * @returns {Array<Object>} Filtered activities
 */
function getMyItemsActivities(userIds, filterType, searchQuery, accountId) {
    if (!userIds || userIds.length === 0) {
        return getFilteredActivities(filterType, searchQuery, accountId);
    }

    // For "done" filter, get done activities and filter by user
    if (filterType === "done") {
        var doneActivities;
        if (accountId !== undefined && accountId >= 0) {
            doneActivities = getDoneActivitiesForAccount(accountId);
        } else {
            doneActivities = getDoneActivities();
        }
        return _filterActivitiesByMyItems(doneActivities, userIds, null, searchQuery);
    }

    var allActivities;
    if (accountId !== undefined && accountId >= 0) {
        allActivities = getActivitiesForAccount(accountId);
    } else {
        allActivities = getAllActivities();
    }

    return _filterActivitiesByMyItems(allActivities, userIds, filterType, searchQuery);
}

/**
 * Paginated version of getMyItemsActivities for infinite scroll.
 * Uses SQL-level filtering for user_id/create_uid to reduce data loaded.
 *
 * @param {Array} userIds - Array of composite {user_id, account_id} objects
 * @param {string} filterType - Date filter type
 * @param {string} searchQuery - Search text
 * @param {number} accountId - Account ID (-1 for all)
 * @param {number} limit - Page size
 * @param {number} offset - Virtual offset (number of filtered items to skip)
 * @returns {Object} { activities: Array, hasMore: boolean }
 */
function getMyItemsActivitiesPaginated(userIds, filterType, searchQuery, accountId, limit, offset) {
    limit = limit || 30;
    offset = offset || 0;

    if (!userIds || userIds.length === 0) {
        return getFilteredActivitiesPaginated(filterType, searchQuery, accountId, limit, offset);
    }

    // Handle "done" filter separately
    if (filterType === "done") {
        var doneActivities = getMyItemsActivities(userIds, "done", searchQuery, accountId);
        var donePage = doneActivities.slice(offset, offset + limit);
        return {
            activities: donePage,
            hasMore: (offset + limit) < doneActivities.length
        };
    }

    // Build SQL user filter for user_id OR create_uid
    var userFilterParts = _buildMyItemsUserFilter(userIds);

    var filteredActivities = [];
    var currentDate = new Date();
    var batchSize = limit * 3;
    var dbOffset = 0;
    var skipped = 0;
    var foundAfterOffset = 0;
    var hasMore = true;

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        while (hasMore && foundAfterOffset < (limit + 1)) {
            var rawActivities = [];

            db.transaction(function (tx) {
                var query = "SELECT * FROM mail_activity_app WHERE LOWER(TRIM(COALESCE(state, ''))) != 'done'";
                var params = [];

                if (accountId !== undefined && accountId >= 0) {
                    query += " AND account_id = ?";
                    params.push(accountId);
                }

                // Add user_id OR create_uid filter
                query += " AND (" + userFilterParts.clause + ")";
                params = params.concat(userFilterParts.params);

                query += " ORDER BY due_date ASC LIMIT ? OFFSET ?";
                params.push(batchSize, dbOffset);

                var result = tx.executeSql(query, params);
                for (var i = 0; i < result.rows.length; i++) {
                    rawActivities.push(DBCommon.rowToObject(result.rows.item(i)));
                }
            });

            if (rawActivities.length < batchSize) {
                hasMore = false;
            }

            // Apply JS-based date and search filtering
            for (var i = 0; i < rawActivities.length; i++) {
                var activity = rawActivities[i];
                var passesFilter = true;

                if (filterType && filterType !== "all" && !passesActivityDateFilter(activity, filterType, currentDate)) {
                    passesFilter = false;
                }

                if (passesFilter && searchQuery && !passesActivitySearchFilter(activity, searchQuery)) {
                    passesFilter = false;
                }

                if (passesFilter) {
                    if (skipped < offset) {
                        skipped++;
                    } else {
                        foundAfterOffset++;
                        if (filteredActivities.length < (limit + 1)) {
                            filteredActivities.push(activity);
                        }
                    }

                    if (foundAfterOffset >= (limit + 1)) {
                        break;
                    }
                }
            }

            dbOffset += rawActivities.length;
        }

        // Add project colors
        db.transaction(function (tx) {
            var projectColorMap = {};
            var projectQuery = "SELECT odoo_record_id, color_pallet FROM project_project_app";
            var projectResult = tx.executeSql(projectQuery);
            for (var j = 0; j < projectResult.rows.length; j++) {
                projectColorMap[projectResult.rows.item(j).odoo_record_id] = projectResult.rows.item(j).color_pallet;
            }

            var pageSize = Math.min(filteredActivities.length, limit);
            for (var i = 0; i < pageSize; i++) {
                var activity = filteredActivities[i];
                var inheritedColor = 0;
                if (activity.resModel === "project.project" && activity.link_id) {
                    inheritedColor = projectColorMap[activity.link_id] || 0;
                } else if (activity.resModel === "project.task" && activity.link_id) {
                    var taskRs = tx.executeSql(
                        "SELECT project_id FROM project_task_app WHERE odoo_record_id = ? LIMIT 1",
                        [activity.link_id]
                    );
                    if (taskRs.rows.length > 0 && taskRs.rows.item(0).project_id) {
                        inheritedColor = projectColorMap[taskRs.rows.item(0).project_id] || 0;
                    }
                }
                activity.color_pallet = inheritedColor;
            }
        });

    } catch (e) {
        console.error("getMyItemsActivitiesPaginated failed:", e);
    }

    var pageActivities = filteredActivities.slice(0, limit);
    return {
        activities: pageActivities,
        hasMore: foundAfterOffset > limit
    };
}

/**
 * Internal helper: Builds SQL WHERE clause fragment for "My Items" filter.
 * Matches activities where user_id = uid OR create_uid = uid, scoped by account.
 *
 * @param {Array} userIds - Array of {user_id, account_id} objects
 * @returns {Object} { clause: string, params: Array }
 */
function _buildMyItemsUserFilter(userIds) {
    var parts = [];
    var params = [];

    for (var i = 0; i < userIds.length; i++) {
        var entry = userIds[i];
        var uid = -1;
        var acctId = null;

        if (typeof entry === 'object' && entry !== null && entry.user_id !== undefined) {
            uid = parseInt(entry.user_id);
            acctId = parseInt(entry.account_id);
        } else {
            uid = parseInt(entry);
        }

        if (acctId !== null && !isNaN(acctId)) {
            // Scoped by account: (user_id = ? OR create_uid = ?) AND account_id = ?
            parts.push("((user_id = ? OR create_uid = ?) AND account_id = ?)");
            params.push(uid, uid, acctId);
        } else {
            // No account scope
            parts.push("(user_id = ? OR create_uid = ?)");
            params.push(uid, uid);
        }
    }

    return {
        clause: parts.length > 0 ? parts.join(" OR ") : "1=1",
        params: params
    };
}

/**
 * Internal helper: Filters an already-loaded activities array by "My Items" criteria.
 * An activity matches if user_id or create_uid matches any of the provided userIds.
 *
 * @param {Array} activities - Array of activity objects
 * @param {Array} userIds - Array of composite {user_id, account_id} objects
 * @param {string|null} filterType - Date filter (null to skip)
 * @param {string} searchQuery - Search text (empty to skip)
 * @returns {Array} Filtered activities
 */
function _filterActivitiesByMyItems(activities, userIds, filterType, searchQuery) {
    var result = [];
    var currentDate = new Date();

    for (var i = 0; i < activities.length; i++) {
        var activity = activities[i];

        // Check if activity matches any of the user IDs (assignee OR creator)
        var matchesUser = false;
        var activityUserId = parseInt(activity.user_id) || 0;
        var activityCreateUid = parseInt(activity.create_uid) || 0;
        var activityAccountId = parseInt(activity.account_id);

        for (var j = 0; j < userIds.length; j++) {
            var selectedId = userIds[j];
            var targetUid = -1;
            var targetAccountId = null;

            if (typeof selectedId === 'object' && selectedId !== null && selectedId.user_id !== undefined) {
                targetUid = parseInt(selectedId.user_id);
                targetAccountId = parseInt(selectedId.account_id);
            } else {
                targetUid = parseInt(selectedId);
            }

            // Check account scope if applicable
            if (targetAccountId !== null && !isNaN(targetAccountId) && activityAccountId !== targetAccountId) {
                continue;
            }

            // Match by user_id (assignee) OR create_uid (creator)
            if (activityUserId === targetUid || activityCreateUid === targetUid) {
                matchesUser = true;
                break;
            }
        }

        if (!matchesUser) continue;

        // Apply date filter
        if (filterType && filterType !== "all" && !passesActivityDateFilter(activity, filterType, currentDate)) {
            continue;
        }

        // Apply search filter
        if (searchQuery && !passesActivitySearchFilter(activity, searchQuery)) {
            continue;
        }

        result.push(activity);
    }

    return result;
}