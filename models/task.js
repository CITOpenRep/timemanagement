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
        var timestamp =  Utils.getFormattedTimestampUTC();
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
     //   console.log(" Task marked as deleted: ID " + taskId);
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

/**
 * Filters tasks based on date criteria and search query
 * @param {string} filterType - The filter type: "today", "this_week", "next_week", "later", "completed"
 * @param {string} searchQuery - The search query string
 * @returns {Array<Object>} Filtered list of tasks
 */
function getFilteredTasks(filterType, searchQuery) {
    var allTasks = getAllTasks();
    var filteredTasks = [];
    var currentDate = new Date();
    
    for (var i = 0; i < allTasks.length; i++) {
        var task = allTasks[i];
        
        // Apply date filter
        if (!passesDateFilter(task, filterType, currentDate)) {
            continue;
        }
        
        // Apply search filter
        if (searchQuery && !passesSearchFilter(task, searchQuery)) {
            continue;
        }
        
        filteredTasks.push(task);
    }
    
    return filteredTasks;
}

/**
 * Checks if a task passes the date filter criteria
 * @param {Object} task - The task object
 * @param {string} filterType - The filter type
 * @param {Date} currentDate - Current date for comparison
 * @returns {boolean} True if task passes the filter
 */
function passesDateFilter(task, filterType, currentDate) {
    if (!filterType || filterType === "all") {
        return true;
    }
    
    // Tasks without any dates should only appear in "all" filter
    if (!task.deadline && !task.end_date && !task.start_date) {
        return false;
    }
    
    var today = new Date(currentDate.getFullYear(), currentDate.getMonth(), currentDate.getDate());
    
    switch (filterType) {
        case "all":
            return true;
        case "today":
            return isTaskDueToday(task, today);
        case "this_week":
            return isTaskDueThisWeek(task, today);
        case "this_month":
            return isTaskDueThisMonth(task, today);
        case "later":
            return isTaskDueLater(task, today);
        case "completed":
            return isTaskCompleted(task);
        default:
            return true;
    }
}

/**
 * Checks if a task passes the search filter
 * @param {Object} task - The task object
 * @param {string} searchQuery - The search query
 * @returns {boolean} True if task matches the search
 */
function passesSearchFilter(task, searchQuery) {
    if (!searchQuery || searchQuery.trim() === "") {
        return true;
    }
    
    var query = searchQuery.toLowerCase().trim();
    
    // Search in task name
    if (task.name && task.name.toLowerCase().indexOf(query) >= 0) {
        return true;
    }
    
    // Search in description
    if (task.description && task.description.toLowerCase().indexOf(query) >= 0) {
        return true;
    }
    
    // Search in status
    if (task.status && task.status.toLowerCase().indexOf(query) >= 0) {
        return true;
    }
    
    return false;
}

/**
 * Check if task is due today (includes overdue tasks)
 */
function isTaskDueToday(task, today) {
    if (!task.deadline && !task.end_date && !task.start_date) {
        return false;
    }
    
    var taskDate = getTaskRelevantDate(task);
    if (!taskDate) return false;
    
    var taskDay = new Date(taskDate.getFullYear(), taskDate.getMonth(), taskDate.getDate());
    // Show tasks due today OR overdue tasks (past due dates)
    return taskDay.getTime() <= today.getTime();
}

/**
 * Check if task is due this week
 */
function isTaskDueThisWeek(task, today) {
    if (!task.deadline && !task.end_date && !task.start_date) {
        return false;
    }
    
    var taskDate = getTaskRelevantDate(task);
    if (!taskDate) return false;
    
    var weekStart = new Date(today);
    weekStart.setDate(today.getDate() - today.getDay());
    var weekEnd = new Date(weekStart);
    weekEnd.setDate(weekStart.getDate() + 6);
    
    var taskDay = new Date(taskDate.getFullYear(), taskDate.getMonth(), taskDate.getDate());
    return taskDay >= weekStart && taskDay <= weekEnd;
}

/**
 * Check if task is due next week
 */
/**
 * Check if task is due this month
 */
function isTaskDueThisMonth(task, today) {
    if (!task.deadline && !task.end_date && !task.start_date) {
        return false;
    }
    
    var taskDate = getTaskRelevantDate(task);
    if (!taskDate) return false;
    
    var taskDay = new Date(taskDate.getFullYear(), taskDate.getMonth(), taskDate.getDate());
    return taskDay.getFullYear() === today.getFullYear() && taskDay.getMonth() === today.getMonth();
}

/**
 * Check if task is due later (beyond this month)
 */
function isTaskDueLater(task, today) {
    if (!task.deadline && !task.end_date && !task.start_date) {
        return false; // Tasks without dates should only appear in "all" filter
    }
    
    var taskDate = getTaskRelevantDate(task);
    if (!taskDate) return false;
    
    // Calculate end of this month
    var endOfMonth = new Date(today.getFullYear(), today.getMonth() + 1, 0); // Last day of current month
    
    var taskDay = new Date(taskDate.getFullYear(), taskDate.getMonth(), taskDate.getDate());
    return taskDay > endOfMonth;
}

/**
 * Check if task is completed
 */
function isTaskCompleted(task) {
    return task.status === "completed" || task.status === "done" || task.state === "done";
}

/**
 * Get the most relevant date for a task (priority: deadline > end_date > start_date)
 */
function getTaskRelevantDate(task) {
    if (task.deadline) {
        return new Date(task.deadline);
    }
    if (task.end_date) {
        return new Date(task.end_date);
    }
    if (task.start_date) {
        return new Date(task.start_date);
    }
    return null;
}

