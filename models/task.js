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
        case "overdue":
            return isTaskOverdue(task, today);
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
 * Check if task should appear in today filter (tasks active today but NOT overdue)
 */
function isTaskDueToday(task, today) {
    if (!task.deadline && !task.end_date && !task.start_date) {
        return false;
    }
    
    var dateStatus = getTaskDateStatus(task, today);
    
    // Show if task is in range today but NOT overdue
    return dateStatus.isInRange && !dateStatus.isOverdue;
}

/**
 * Check if task should appear in this week filter (date range overlaps with this week)
 */
function isTaskDueThisWeek(task, today) {
    if (!task.deadline && !task.end_date && !task.start_date) {
        return false;
    }
    
    var weekStart = new Date(today);
    weekStart.setDate(today.getDate() - today.getDay());
    var weekEnd = new Date(weekStart);
    weekEnd.setDate(weekStart.getDate() + 6);
    
    // Normalize to remove time component
    var weekStartDay = new Date(weekStart.getFullYear(), weekStart.getMonth(), weekStart.getDate());
    var weekEndDay = new Date(weekEnd.getFullYear(), weekEnd.getMonth(), weekEnd.getDate());
    
    // Check if any day in this week falls within the task's date range
    for (var day = new Date(weekStartDay); day <= weekEndDay; day.setDate(day.getDate() + 1)) {
        var dateStatus = getTaskDateStatus(task, day);
        if (dateStatus.isInRange) {
            return true;
        }
    }
    
    return false;
}

/**
 * Check if task is due next week
 */
/**
 * Check if task should appear in this month filter (date range overlaps with this month)
 */
function isTaskDueThisMonth(task, today) {
    if (!task.deadline && !task.end_date && !task.start_date) {
        return false;
    }
    
    var monthStart = new Date(today.getFullYear(), today.getMonth(), 1);
    var monthEnd = new Date(today.getFullYear(), today.getMonth() + 1, 0); // Last day of current month
    
    // Check if any day in this month falls within the task's date range
    for (var day = new Date(monthStart); day <= monthEnd; day.setDate(day.getDate() + 1)) {
        var dateStatus = getTaskDateStatus(task, day);
        if (dateStatus.isInRange) {
            return true;
        }
    }
    
    return false;
}

/**
 * Check if task should appear in later filter (starts after this month and not overdue)
 */
function isTaskDueLater(task, today) {
    if (!task.deadline && !task.end_date && !task.start_date) {
        return false; // Tasks without dates should only appear in "all" filter
    }
    
    var monthEnd = new Date(today.getFullYear(), today.getMonth() + 1, 0); // Last day of current month
    
    // Get task start date (or end date if no start date)
    var taskStartDate = null;
    if (task.start_date) {
        taskStartDate = new Date(task.start_date);
    } else if (task.end_date) {
        taskStartDate = new Date(task.end_date);
    } else if (task.deadline) {
        taskStartDate = new Date(task.deadline);
    }
    
    if (!taskStartDate) return false;
    
    var taskStartDay = new Date(taskStartDate.getFullYear(), taskStartDate.getMonth(), taskStartDate.getDate());
    var monthEndDay = new Date(monthEnd.getFullYear(), monthEnd.getMonth(), monthEnd.getDate());
    
    // Check if not overdue
    var dateStatus = getTaskDateStatus(task, today);
    if (dateStatus.isOverdue) {
        return false; // Overdue tasks should appear in "overdue" filter
    }
    
    // Show if task starts after this month
    return taskStartDay > monthEndDay;
}

/**
 * Check if task is completed
 */
function isTaskCompleted(task) {
    return task.status === "completed" || task.status === "done" || task.state === "done";
}

/**
 * Check if task is overdue
 * @param {Object} task - The task object
 * @param {Date} today - Current date for comparison
 * @returns {boolean} True if task is overdue
 */
function isTaskOverdue(task, today) {
    if (!task.deadline && !task.end_date && !task.start_date) {
        return false;
    }
    
    var dateStatus = getTaskDateStatus(task, today);
    return dateStatus.isOverdue;
}

/**
 * Check if a date falls within the task's date range or if task is overdue
 * @param {Object} task - The task object
 * @param {Date} checkDate - The date to check against
 * @returns {Object} Object with isInRange, isOverdue, hasStartDate, hasEndDate, hasDeadline
 */
function getTaskDateStatus(task, checkDate) {
    var hasStartDate = !!(task.start_date);
    var hasEndDate = !!(task.end_date);
    var hasDeadline = !!(task.deadline);
    
    // If no dates at all, return false for everything
    if (!hasStartDate && !hasEndDate && !hasDeadline) {
        return {
            isInRange: false,
            isOverdue: false,
            hasStartDate: false,
            hasEndDate: false,
            hasDeadline: false
        };
    }
    
    var startDate = hasStartDate ? new Date(task.start_date) : null;
    var endDate = hasEndDate ? new Date(task.end_date) : null;
    var deadline = hasDeadline ? new Date(task.deadline) : null;
    
    // Normalize dates to remove time component
    var checkDay = new Date(checkDate.getFullYear(), checkDate.getMonth(), checkDate.getDate());
    var startDay = startDate ? new Date(startDate.getFullYear(), startDate.getMonth(), startDate.getDate()) : null;
    var endDay = endDate ? new Date(endDate.getFullYear(), endDate.getMonth(), endDate.getDate()) : null;
    var deadlineDay = deadline ? new Date(deadline.getFullYear(), deadline.getMonth(), deadline.getDate()) : null;
    
    var isInRange = false;
    var isOverdue = false;
    
    // Check if current date is in the task's date range (start_date to end_date)
    if (startDay && endDay) {
        // Both start and end dates exist
        isInRange = checkDay >= startDay && checkDay <= endDay;
    } else if (startDay && !endDay) {
        // Only start date exists, check if current date is on or after start date
        isInRange = checkDay >= startDay;
    } else if (!startDay && endDay) {
        // Only end date exists, check if current date is on or before end date
        isInRange = checkDay <= endDay;
    }
    
    // Check if deadline is missed (overdue)
    if (deadlineDay) {
        isOverdue = checkDay > deadlineDay;
    }
    
    // Also check if end_date is passed (task should be overdue if past end_date)
    if (!isOverdue && endDay) {
        isOverdue = checkDay > endDay;
    }
    
    return {
        isInRange: isInRange,
        isOverdue: isOverdue,
        hasStartDate: hasStartDate,
        hasEndDate: hasEndDate,
        hasDeadline: hasDeadline
    };
}

