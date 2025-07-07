.import QtQuick.LocalStorage 2.7 as Sql
.import "database.js" as DBCommon
.import "utils.js" as Utils
.import "task.js" as Task
.import "project.js" as Project

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

        db.transaction(function (tx) {
            var query = `
            SELECT *
            FROM mail_activity_app
            WHERE state != 'done'
            ORDER BY due_date ASC
            `;

            var rs = tx.executeSql(query);

            for (var i = 0; i < rs.rows.length; i++) {
                activityList.push(DBCommon.rowToObject(rs.rows.item(i)));
            }
        });

    } catch (e) {
        DBCommon.logException("getAllActivities", e);
    }

    return activityList;
}

function getActivityById(record_id, account_id) {
    var activity = null;

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var query = `
                SELECT *
                FROM mail_activity_app
                WHERE id = ? AND account_id = ?
                LIMIT 1
            `;
            var rs = tx.executeSql(query, [record_id, account_id]);

            if (rs.rows.length > 0) {
                activity = DBCommon.rowToObject(rs.rows.item(0));

                // Initialize enrichment defaults
                activity.project_id = -1;
                activity.sub_project_id = -1;
                activity.parent_task_id = -1;
                activity.task_id = -1;
                activity.sub_task_id = -1;
                activity.linkedType = "other";

                console.log("Base activity loaded:", JSON.stringify(activity));

                if (activity.resModel === "project.task" && activity.link_id) {
                    console.log("Activity linked to project.task, link_id (Odoo ID):", activity.link_id);

                    // Retrieve local ID from odoo_record_id
                    var local_task_id = -1;
                    var rs_task = tx.executeSql(
                        'SELECT id FROM project_task_app WHERE odoo_record_id = ? AND account_id = ? LIMIT 1',
                        [activity.link_id, activity.account_id]
                    );
                    if (rs_task.rows.length > 0) {
                        local_task_id = rs_task.rows.item(0).id;
                    } else {
                        console.error("No local task found for odoo_record_id:", activity.link_id, "account_id:", activity.account_id);
                    }

                    if (local_task_id !== -1) {
                        let taskDetails = Task.getTaskDetails(local_task_id);
                        console.log("Task details fetched:", JSON.stringify(taskDetails));

                        if (taskDetails && taskDetails.id) {
                            var parent_task_id = (taskDetails.parent_task_id !== undefined && taskDetails.parent_task_id !== null) ? taskDetails.parent_task_id : -1;
                            var project_id = (taskDetails.project_id !== undefined && taskDetails.project_id !== null) ? taskDetails.project_id : -1;
                            var sub_project_id = (taskDetails.sub_project_id !== undefined && taskDetails.sub_project_id !== null) ? taskDetails.sub_project_id : -1;

                            if (parent_task_id > 0) {
                                // This is a subtask
                                activity.sub_task_id = activity.link_id;
                                activity.task_id = parent_task_id;
                            } else {
                                // This is a parent task
                                activity.task_id = activity.link_id;
                                activity.sub_task_id = -1;
                            }

                            activity.parent_task_id = parent_task_id;
                            activity.project_id = project_id;
                            activity.sub_project_id = sub_project_id;
                            activity.linkedType = "task";
                        } else {
                            console.error("Task details are empty for local_task_id:", local_task_id);
                        }
                    }

                } else if (activity.resModel === "project.project" && activity.link_id) {

                    // Retrieve local ID from odoo_record_id
                    var local_project_id = -1;
                    var rs_project = tx.executeSql(
                        'SELECT id FROM project_project_app WHERE odoo_record_id = ? AND account_id = ? LIMIT 1',
                        [activity.link_id, activity.account_id]
                    );
                    if (rs_project.rows.length > 0) {
                        local_project_id = rs_project.rows.item(0).id;
                    } else {
                        console.error("No local project found for odoo_record_id:", activity.link_id, "account_id:", activity.account_id);
                    }

                    if (local_project_id !== -1) {
                        let projectDetails = Project.getProjectDetails(local_project_id);
                        console.log("Project details fetched:", JSON.stringify(projectDetails));

                        if (projectDetails && projectDetails.id) {
                            var parent_project_id = (projectDetails.parent_id !== undefined && projectDetails.parent_id !== null) ? projectDetails.parent_id : -1;

                            if (parent_project_id > 0) {
                                // It is a subproject
                                activity.project_id = parent_project_id;
                                activity.sub_project_id = activity.link_id;
                            } else {
                                // It is a top-level project
                                activity.project_id = activity.link_id;
                                activity.sub_project_id = -1;
                            }
                            activity.linkedType = "project";
                        } else {
                            console.error("Project details are empty for local_project_id:", local_project_id);
                        }
                    }

                } else {
                    console.log("Activity not linked to recognized model, using defaults.");
                }
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
 * Saves a new activity record into the `mail_activity_app` table in the local SQLite database.
 *
 * @function saveActivityData
 * @param {Object} data - The activity data object containing all necessary fields to insert.
 * @returns {Object} - Returns an object with `{ success: true }` on success,
 *                     or `{ success: false, error: <message> }` on failure.
 *
 * @description
 * Opens a local SQLite database transaction and inserts a new record into the `mail_activity_app` table.
 * The fields inserted include account ID, activity type, summary, user ID, due date, notes,
 * related model and ID, task and project references, link ID, activity state, status,
 * and the current UTC timestamp (`last_modified`) for sync tracking.
 * Uses utility functions `Utils.extractDate()` for parsing the due date and
 * `Utils.getFormattedTimestampUTC()` for generating a UTC timestamp.
 * Logs any database exceptions to the console and returns an error object on failure.
 */
function saveActivityData(data) {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        db.transaction(function(tx) {
            tx.executeSql('INSERT INTO mail_activity_app ( \
            account_id, activity_type_id, summary, user_id, due_date, \
            notes, resModel, resId, task_id, project_id, link_id, state, last_modified,status) \
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,?)',
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
                              Utils.getFormattedTimestampUTC(),
                              data.status
                          ]
                          );

        });
        return { success: true };
    }catch (e) {
        console.error("Database operation failed:", e.message);
        return { success: false, error: e.message };
    }
}
