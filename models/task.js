.import QtQuick.LocalStorage 2.7 as Sql
.import "database.js" as DBCommon
.import "utils.js" as Utils

// Helper to handle -1/null
function validId(value) {
    return (value !== undefined && value > 0) ? value : null;
}

function saveOrUpdateTask(data) {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        var timestamp = Utils.getFormattedTimestamp();
        db.transaction(function (tx) {
            if (data.record_id) {
                // UPDATE
                tx.executeSql('UPDATE project_task_app SET \
                    account_id = ?, name = ?, project_id = ?, parent_id = ?, initial_planned_hours = ?, favorites = ?, description = ?, user_id = ?, sub_project_id = ?, \
                    start_date = ?, end_date = ?, deadline = ?, last_modified = ?, status = ? WHERE id = ?',
                              [
                                  data.accountId, data.name, data.projectId,
                                  validId(data.parentId), data.plannedHours, data.favorites,
                                  data.description, data.assigneeUserId, data.subProjectId,
                                  data.startDate, data.endDate, data.deadline,
                                  timestamp, data.status, data.record_id
                              ]
                              );
            } else {
                // INSERT
                tx.executeSql('INSERT INTO project_task_app (account_id, name, project_id, parent_id, start_date, end_date, deadline, favorites, initial_planned_hours, description, user_id, sub_project_id, last_modified, status) \
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                              [
                                  data.accountId, data.name, data.projectId,
                                  validId(data.parentId), data.startDate, data.endDate,
                                  data.deadline, data.favorites, data.plannedHours,
                                  data.description, data.assigneeUserId,
                                  data.subProjectId, timestamp, data.status
                              ]
                              );
            }
        });

        return { success: true };
    } catch (e) {
        console.error("Database operation failed:", e.message);
        return { success: false, error: e.message };
    }
}


function markTaskAsDeleted(taskId) {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        db.transaction(function (tx) {
            tx.executeSql("UPDATE project_task_app SET status = 'deleted', last_modified = datetime('now') WHERE id = ?", [taskId]);
        });
        console.log(" Task marked as deleted: ID " + taskId);
        return {
            success: true,
            message: "Task marked as deleted."
        };
    } catch (e) {
        console.error("❌ Error marking timesheet as deleted (ID " + taskId + "): " + e);
        return {
            success: false,
            message: "Failed to mark as deleted: " + e
        };
    }
}


function edittaskData(data) {
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

    db.transaction(function (tx) {
        tx.executeSql('UPDATE project_task_app SET \
            account_id = ?, name = ?, project_id = ?, parent_id = ?, initial_planned_hours = ?, favorites = ?, description = ?, user_id = ?, sub_project_id = ?, \
            start_date = ?, end_date = ?, deadline = ?, last_modified = ? WHERE id = ?',
                      [data.selectedAccountUserId, data.nameInput, data.selectedProjectId, data.selectedparentId, data.initialInput, data.img_star, data.editdescription, data.selectedassigneesUserId, data.editselectedSubProjectId,
                       data.startdateInput, data.enddateInput, data.deadlineInput, new Date().toISOString(), data.rowId]
                      );
        fetch_tasks_lists()
    });
}

/**
 * Fetches all tasks for a specific account from the SQLite DB.
 * Matches exact DB column names from the project_task_app schema.
 *
 * @param {int} accountId - The account identifier (0 for local).
 * @returns {Array<Object>} - List of task records.
 */
function getTasksForAccount(accountId) {
    const taskList = [];
    try {
        const db = Sql.LocalStorage.openDatabaseSync(
                     DBCommon.NAME,
                     DBCommon.VERSION,
                     DBCommon.DISPLAY_NAME,
                     DBCommon.SIZE
                     );

        db.transaction(function (tx) {
            const results = tx.executeSql(
                              "SELECT * FROM project_task_app WHERE account_id = ? ORDER BY name COLLATE NOCASE ASC",
                              [accountId]
                              );

            for (let i = 0; i < results.rows.length; i++) {
                const row = results.rows.item(i);
                taskList.push({
                                  id: row.id,
                                  name: row.name,
                                  account_id: row.account_id,
                                  project_id: row.project_id,
                                  sub_project_id: row.sub_project_id,
                                  parent_id: row.parent_id,
                                  start_date: row.start_date,
                                  end_date: row.end_date,
                                  deadline: row.deadline,
                                  initial_planned_hours: row.initial_planned_hours,
                                  favorites: row.favorites,
                                  state: row.state,
                                  description: row.description,
                                  last_modified: row.last_modified,
                                  user_id: row.user_id,
                                  status: row.status,
                                  odoo_record_id: row.odoo_record_id
                              });
            }
        });
    } catch (e) {
        DBCommon.logException(e);
    }
    return taskList;
}

/**
 * Fetches all tasks for a specific account from the SQLite DB.
 * Matches exact DB column names from the project_task_app schema.
 *
 * @param {number} accountId - The account identifier (0 for local).
 * @returns {Array<Object>} - Array of task records with fields from project_task_app.
 */
function getTaskDetails(task_id) {
    var task_detail = {};

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var result = tx.executeSql('SELECT * FROM project_task_app WHERE id = ?', [task_id]);

            if (result.rows.length > 0) {
                var row = result.rows.item(0);

                task_detail = {
                    id: row.id,
                    name: row.name,
                    account_id: row.account_id,
                    project_id: row.project_id,
                    sub_project_id: row.sub_project_id,
                    parent_id: row.parent_id,
                    start_date: row.start_date ? Utils.formatDate(new Date(row.start_date)) : "",
                    end_date: row.end_date ? Utils.formatDate(new Date(row.end_date)) : "",
                    deadline: row.deadline ? Utils.formatDate(new Date(row.deadline)) : "",
                    initial_planned_hours: row.initial_planned_hours,
                    favorites: row.favorites || 0,
                    state: row.state || "",
                    description: row.description || "",
                    last_modified: row.last_modified,
                    user_id: row.user_id,
                    status: row.status || "",
                    odoo_record_id: row.odoo_record_id
                };
            }
        });

    } catch (e) {
        DBCommon.logException(e);
    }

    return task_detail;
}


/**
 * Retrieves all non-deleted tasks from the `project_task_app` table.
 *
 * @returns {Array<Object>} A list of task objects as plain JS objects.
 */
function getAllTasks() {
    var taskList = [];

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var query = "SELECT * FROM project_task_app WHERE status IS NULL OR status != 'deleted' ORDER BY name COLLATE NOCASE ASC";
            var result = tx.executeSql(query);

            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);
                taskList.push(DBCommon.rowToObject(row));
            }
        });
    } catch (e) {
        console.error("❌ getAllTasks failed:", e);
    }

    return taskList;
}

