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
                WHERE state != 'done'
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


function initializeEnrichmentDefaults(activity) {
    activity.project_id = -1;
    activity.sub_project_id = -1;
    activity.task_id = -1;
    activity.sub_task_id = -1;
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
    }else if (normalized.includes("meeting")) {
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

        db.transaction(function(tx) {
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
                    ""             // mark as unsynced/new
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

function createFollowupActivity(account_id,activityId) {
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var newRecordId = 0;

    try {
        var timestamp = Utils.getFormattedTimestampUTC();
        var createDate = timestamp.split(" ")[0];

        db.transaction(function(tx) {
            // 1. Fetch the existing activity
            var result = tx.executeSql(
                "SELECT * FROM mail_activity_app WHERE id = ? AND account_id = ?",
                [activityId, account_id]
            );

            if (result.rows.length === 0) {
                throw new Error("Activity not found for ID " + activityId);
            }

            var original = result.rows.item(0);

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
                AND a.state != 'done'
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
