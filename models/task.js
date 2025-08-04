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
        let resolvedParentId = 0; // Default to 0 (no parent)

        // Handle parent_id for subtask creation
        if (data.parentId && data.parentId > 0) {
            resolvedParentId = data.parentId;
        } else {
            resolvedParentId = 0; // This is a parent task, not a subtask
        }

        // Handle project_id - if subproject is specified, use it; otherwise use main project
        let finalProjectId = data.projectId;
        if (data.subProjectId && data.subProjectId > 0) {
            finalProjectId = data.subProjectId;
        }
        
        var timestamp = Utils.getFormattedTimestampUTC();
        var taskRecordId = data.record_id;
        
        db.transaction(function (tx) {
            if (data.record_id) {
                // UPDATE
                tx.executeSql('UPDATE project_task_app SET \
                    account_id = ?, name = ?, project_id = ?, parent_id = ?, initial_planned_hours = ?, favorites = ?, description = ?, user_id = ?, sub_project_id = ?, \
                    start_date = ?, end_date = ?, deadline = ?, last_modified = ?, status = ? WHERE id = ?',
                              [
                                  data.accountId, data.name, finalProjectId,
                                  resolvedParentId, data.plannedHours, data.favorites,
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
                                  data.accountId, data.name, finalProjectId,
                                   resolvedParentId, data.startDate, data.endDate,
                                  data.deadline, data.favorites, data.plannedHours,
                                  data.description, data.assigneeUserId,
                                  data.subProjectId, timestamp, data.status
                              ]
                              );
                              
                // Get the newly inserted task ID
                var result = tx.executeSql("SELECT last_insert_rowid() as id");
                if (result.rows.length > 0) {
                    taskRecordId = result.rows.item(0).id;
                }
            }
            
            // Handle multiple assignees if provided
            if (data.multipleAssignees && data.multipleAssignees.length > 0) {
                // First, clear existing assignees for this task (soft delete)
                tx.executeSql(
                    "UPDATE project_task_assignee_app SET status = 'deleted', last_modified = ? WHERE task_id = ? AND account_id = ?",
                    [timestamp, taskRecordId, data.accountId]
                );
                
                // Insert new assignees
                for (let i = 0; i < data.multipleAssignees.length; i++) {
                    let assignee = data.multipleAssignees[i];
                    tx.executeSql(
                        'INSERT OR REPLACE INTO project_task_assignee_app (task_id, account_id, user_id, last_modified, status) VALUES (?, ?, ?, ?, ?)',
                        [taskRecordId, data.accountId, assignee.id, timestamp, "active"]
                    );
                }
            }
        });

        return { success: true, taskId: taskRecordId };
    } catch (e) {
        console.error("Database operation failed:", e.message);
        return { success: false, error: e.message };
    }
}

function getAttachmentsForTask(odooRecordId) {
    var attachmentList = [];

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var query = `
                SELECT name, mimetype, datas
                FROM ir_attachment_app
                WHERE res_model = 'project.task' AND res_id = ?
                ORDER BY name COLLATE NOCASE ASC
            `;

            var result = tx.executeSql(query, [odooRecordId]);

            for (var i = 0; i < result.rows.length; i++) {
                attachmentList.push({
                    name: result.rows.item(i).name,
                    mimetype: result.rows.item(i).mimetype,
                    datas: result.rows.item(i).datas
                });
            }
        });
    } catch (e) {
        console.error("getAttachmentsForTask failed:", e);
    }

    return attachmentList;
}

/**
 * Gets the assignees for a specific task
 * @param {number} taskId - The local task ID
 * @param {number} accountId - The account ID
 * @returns {Array} Array of assignee objects with id and name
 */
function getTaskAssignees(taskId, accountId) {
    var assignees = [];
    
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        
        db.transaction(function (tx) {
            var query = `
                SELECT ta.user_id, u.name
                FROM project_task_assignee_app ta
                JOIN res_users_app u ON ta.user_id = u.odoo_record_id AND ta.account_id = u.account_id
                WHERE ta.task_id = ? AND ta.account_id = ? AND (ta.status IS NULL OR ta.status != 'deleted')
                ORDER BY u.name COLLATE NOCASE ASC
            `;
            
            var result = tx.executeSql(query, [taskId, accountId]);
            
            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);
                assignees.push({
                    id: row.user_id,
                    name: row.name
                });
            }
        });
    } catch (e) {
        console.error("getTaskAssignees failed:", e);
    }
    
    return assignees;
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

                // Extract initial project_id
                var project_id = (row.project_id !== undefined && row.project_id !== null && row.project_id > 0) ? row.project_id : -1;
                var sub_project_id = -1;

                if (project_id > 0) {
                    // Look up project_project_app to check if this project has a parent_id (indicating it is a subproject)
                    var rs_project = tx.executeSql(
                        'SELECT parent_id FROM project_project_app WHERE odoo_record_id = ? LIMIT 1',
                        [project_id]
                    );

                    if (rs_project.rows.length > 0) {
                        var parent_id = rs_project.rows.item(0).parent_id;
                        if (parent_id !== undefined && parent_id !== null && parent_id > 0) {
                            // This project is a subproject
                            sub_project_id = project_id;
                            project_id = parent_id;
                            console.log("Subproject detected: sub_project_id =", sub_project_id, ", parent project_id =", project_id);
                        } else {
                            // Top-level project
                            sub_project_id = row.sub_project_id;
                            console.log("Top-level project detected, project_id =", project_id);
                        }
                    } else {
                        console.error("Project lookup failed for project_id:", project_id);
                    }
                }

                task_detail = {
                    id: row.id,
                    name: row.name,
                    account_id: row.account_id,
                    project_id: project_id,
                    sub_project_id: sub_project_id,
                    parent_id: row.parent_id, // remains for parent task reference
                    start_date: row.start_date || "",  // Keep original date format from database
                    end_date: row.end_date || "",      // Keep original date format from database
                    deadline: row.deadline || "",      // Keep original date format from database
                    initial_planned_hours: row.initial_planned_hours || 0,  // Ensure it's not null/undefined
                    favorites: row.favorites || 0,
                    state: row.state || "",
                    description: row.description || "",
                    last_modified: row.last_modified,
                    user_id: row.user_id,
                    status: row.status || "",
                    odoo_record_id: row.odoo_record_id
                };

                console.log("getTaskDetails enriched task:", JSON.stringify(task_detail));
            } else {
                console.error("No task found for local task_id:", task_id);
            }
        });

    } catch (e) {
        DBCommon.logException("getTaskDetails", e);
    }

    return task_detail;
}

/**
 * Retrieves all non-deleted tasks from the `project_task_app` table,
 * and adds inherited color and total hours spent from timesheet entries.
 *
 * @returns {Array<Object>} A list of task objects with color and spentHours.
 */
function getAllTasks() {
    var taskList = [];

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        var projectColorMap = {};

        db.transaction(function (tx) {
            // Step 1: Build map of odoo_record_id -> color_pallet
            var projectQuery = "SELECT odoo_record_id, color_pallet FROM project_project_app";
            var projectResult = tx.executeSql(projectQuery);
            for (var j = 0; j < projectResult.rows.length; j++) {
                var projectRow = projectResult.rows.item(j);
                projectColorMap[projectRow.odoo_record_id] = projectRow.color_pallet;
            }

            // Step 2: Fetch tasks and attach inherited color and total hours
            var query = "SELECT * FROM project_task_app WHERE status IS NULL OR status != 'deleted' ORDER BY last_modified DESC";
            var result = tx.executeSql(query);

            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);
                var task = DBCommon.rowToObject(row);

                // Inherit color from sub_project or project
                var inheritedColor = 0;
                if (projectColorMap[task.sub_project_id]) {
                    inheritedColor = projectColorMap[task.sub_project_id];
                } else if (projectColorMap[task.project_id]) {
                    inheritedColor = projectColorMap[task.project_id];
                }
                task.color_pallet = inheritedColor;

                // Step 3: Calculate total hours spent from timesheet entries
                var timeQuery = "SELECT SUM(unit_amount) as total_hours FROM account_analytic_line_app WHERE task_id = ? AND account_id = ?";
                var timeResult = tx.executeSql(timeQuery, [task.odoo_record_id, task.account_id]);  // or task.task_account_id
                if (timeResult.rows.length > 0 && timeResult.rows.item(0).total_hours !== null) {
                    task.spent_hours = timeResult.rows.item(0).total_hours;
                } else {
                    task.spent_hours = 0;
                }
                taskList.push(task);
            }
        });
    } catch (e) {
        console.error("getAllTasks failed:", e);
    }

    return taskList;
}


/**
 * Filters tasks based on date criteria and search query while preserving parent-child hierarchy
 * @param {string} filterType - The filter type: "today", "this_week", "next_week", "later", "completed"
 * @param {string} searchQuery - The search query string
 * @returns {Array<Object>} Filtered list of tasks with hierarchy preserved
 */
function getFilteredTasks(filterType, searchQuery) {
    var allTasks = getAllTasks();
    var filteredTasks = [];
    var currentDate = new Date();
    var includedTaskIds = new Map(); // Changed to Map to store composite keys of odoo_record_id and account_id
    var taskById = {};
    
    // Create a map of tasks by a composite key of odoo_record_id and account_id for quick lookup
    for (var i = 0; i < allTasks.length; i++) {
        var task = allTasks[i];
        var compositeKey = task.odoo_record_id + '_' + task.account_id;
        taskById[compositeKey] = task;
    }
    
    // First pass: identify tasks that match the filter criteria
    for (var i = 0; i < allTasks.length; i++) {
        var task = allTasks[i];
        
        var passesFilter = true;
        
        // Apply date filter
        if (!passesDateFilter(task, filterType, currentDate)) {
            passesFilter = false;
        }
        
        // Apply search filter
        if (passesFilter && searchQuery && !passesSearchFilter(task, searchQuery)) {
            passesFilter = false;
        }
        
        if (passesFilter) {
            var compositeKey = task.odoo_record_id + '_' + task.account_id;
            includedTaskIds.set(compositeKey, task);
        }
    }
    
    // Second pass: include parent tasks if they have children that match the filter
    for (var i = 0; i < allTasks.length; i++) {
        var task = allTasks[i];
        
        // Check if this task has children that are included
        var hasIncludedChildren = false;
        for (var j = 0; j < allTasks.length; j++) {
            var potentialChild = allTasks[j];
            var childKey = potentialChild.odoo_record_id + '_' + potentialChild.account_id;
            // Match parent-child relationship and ensure they are in the same account
            if (potentialChild.parent_id === task.odoo_record_id && 
                potentialChild.account_id === task.account_id && 
                includedTaskIds.has(childKey)) {
                hasIncludedChildren = true;
                break;
            }
        }
        
        if (hasIncludedChildren) {
            var compositeKey = task.odoo_record_id + '_' + task.account_id;
            includedTaskIds.set(compositeKey, task);
        }
    }
    
    // Third pass: include parent chain for included tasks to maintain hierarchy
    var toProcess = Array.from(includedTaskIds.values());
    for (var i = 0; i < toProcess.length; i++) {
        var task = toProcess[i];
        
        if (task && task.parent_id && task.parent_id > 0) {
            // Look for parent with matching account_id
            for (var j = 0; j < allTasks.length; j++) {
                var parentCandidate = allTasks[j];
                if (parentCandidate.odoo_record_id === task.parent_id && 
                    parentCandidate.account_id === task.account_id) {
                    
                    var parentKey = parentCandidate.odoo_record_id + '_' + parentCandidate.account_id;
                    if (!includedTaskIds.has(parentKey)) {
                        includedTaskIds.set(parentKey, parentCandidate);
                        toProcess.push(parentCandidate);
                    }
                    break;
                }
            }
        }
    }
    
    // Fourth pass: include all children of included parent tasks to maintain hierarchy
    for (var i = 0; i < allTasks.length; i++) {
        var task = allTasks[i];
        
        // If this task has a parent that is included, include this task too
        // But only if the parent is from the same account
        if (task.parent_id && task.parent_id > 0) {
            // Check if any parent with matching account_id is included
            for (var j = 0; j < allTasks.length; j++) {
                var parentCandidate = allTasks[j];
                if (parentCandidate.odoo_record_id === task.parent_id && 
                    parentCandidate.account_id === task.account_id) {
                    
                    var parentKey = parentCandidate.odoo_record_id + '_' + parentCandidate.account_id;
                    if (includedTaskIds.has(parentKey)) {
                        var taskKey = task.odoo_record_id + '_' + task.account_id;
                        includedTaskIds.set(taskKey, task);
                        break;
                    }
                }
            }
        }
    }
    
    // Final pass: build the filtered tasks list
    for (var i = 0; i < allTasks.length; i++) {
        var task = allTasks[i];
        var taskKey = task.odoo_record_id + '_' + task.account_id;
        if (includedTaskIds.has(taskKey)) {
            filteredTasks.push(task);
        }
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
    // Safety check for task object
    if (!task) return false;
    
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

