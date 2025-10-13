/*
 * MULTIPLE ASSIGNEES IMPLEMENTATION
 * =================================
 * 
 * This module now supports multiple assignees per task by storing them as comma-separated 
 * user IDs in the user_id field of the project_task_app table.
 * 
 * Key changes:
 * - Multiple assignee IDs are stored as comma-separated string in user_id field
 * - getTaskAssignees() parses the comma-separated IDs and returns assignee objects
 * - setTaskAssignees() updates task with multiple assignees
 * - saveOrUpdateTask() handles both single and multiple assignees
 * - migrateTaskAssignees() provides backward compatibility
 * 
 * Usage:
 * - For single assignee: store single ID in user_id field (backward compatible)
 * - For multiple assignees: store comma-separated IDs like "123,456,789" in user_id field
 * - Use getTaskAssignees(taskId, accountId) to get array of assignee objects
 * - Use setTaskAssignees(taskId, accountId, assignees) to update assignees
 */

.import QtQuick.LocalStorage 2.7 as Sql
.import "database.js" as DBCommon
.import "utils.js" as Utils

// Helper to handle -1/null
function validId(value) {
    return (value !== undefined && value > 0) ? value : null;
}

// Helper to parse comma-separated user IDs from user_id field
function parseAssigneeIds(userIdField) {
    if (!userIdField) {
        return [];
    }
    return userIdField.toString().split(',').map(function(id) {
        return parseInt(id.trim());
    }).filter(function(id) {
        return !isNaN(id) && id > 0;
    });
}

// Helper to convert assignee array to comma-separated string
function formatAssigneeIds(assignees) {
    if (!assignees || assignees.length === 0) {
        return "";
    }
    return assignees.map(function(assignee) {
        return assignee.id;
    }).join(',');
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
        
        // Determine the user_id value (single assignee or comma-separated multiple assignees)
        var userIdValue = data.assigneeUserId;
        if (data.multipleAssignees && data.multipleAssignees.length > 0) {
            userIdValue = formatAssigneeIds(data.multipleAssignees);
        }
        
        db.transaction(function (tx) {
            if (data.record_id) {
                // UPDATE
                tx.executeSql('UPDATE project_task_app SET \
                    account_id = ?, name = ?, project_id = ?, parent_id = ?, initial_planned_hours = ?, priority = ?, description = ?, user_id = ?, sub_project_id = ?, \
                    start_date = ?, end_date = ?, deadline = ?, state = ?, personal_stage = ?, last_modified = ?, status = ? WHERE id = ?',
                              [
                                  data.accountId, data.name, finalProjectId,
                                  resolvedParentId, data.plannedHours, data.priority,
                                  data.description, userIdValue, data.subProjectId,
                                  data.startDate, data.endDate, data.deadline,
                                  data.stageOdooRecordId || null,
                                  data.personalStageOdooRecordId || null,
                                  timestamp, data.status, data.record_id
                              ]
                              );
                              
            } else {
                // INSERT
                tx.executeSql('INSERT INTO project_task_app (account_id, name, project_id, parent_id, start_date, end_date, deadline, priority, initial_planned_hours, description, user_id, sub_project_id, state, personal_stage, last_modified, status) \
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                              [
                                  data.accountId, data.name, finalProjectId,
                                   resolvedParentId, data.startDate, data.endDate,
                                  data.deadline, data.priority, data.plannedHours,
                                  data.description, userIdValue,
                                  data.subProjectId, data.stageOdooRecordId || null,
                                  data.personalStageOdooRecordId || null,
                                  timestamp, data.status
                              ]
                              );
                              
                // Get the newly inserted task ID
                var result = tx.executeSql("SELECT last_insert_rowid() as id");
                if (result.rows.length > 0) {
                    taskRecordId = result.rows.item(0).id;
                }
            }
        });

        return { success: true, taskId: taskRecordId };
    } catch (e) {
        console.error("Database operation failed:", e.message);
        return { success: false, error: e.message };
    }
}


function getTaskStageName(odooRecordId) {
    var stageName = "Undefined";

    try {
        if (odooRecordId === -1) {
            return "Undefined";   // special case
        }

        var db = Sql.LocalStorage.openDatabaseSync(
            DBCommon.NAME,
            DBCommon.VERSION,
            DBCommon.DISPLAY_NAME,
            DBCommon.SIZE
        );

        db.transaction(function (tx) {
            var query = `
                SELECT name
                FROM project_task_type_app
                WHERE odoo_record_id = ?
                LIMIT 1
            `;

            var result = tx.executeSql(query, [odooRecordId]);

            if (result.rows.length > 0) {
                stageName = result.rows.item(0).name;
            }
        });
    } catch (e) {
        console.error("getTaskStageName failed:", e);
    }

    return stageName;
}

/**
 * Check if a task's stage has fold == 1
 * @param {number} stageId - The odoo_record_id of the task stage
 * @returns {boolean} True if the stage has fold == 1
 */
function isTaskStageFolded(stageId) {
    try {
        if (!stageId || stageId === -1) {
            return false;
        }

        var db = Sql.LocalStorage.openDatabaseSync(
            DBCommon.NAME,
            DBCommon.VERSION,
            DBCommon.DISPLAY_NAME,
            DBCommon.SIZE
        );

        var isFolded = false;

        db.transaction(function (tx) {
            var query = `
                SELECT fold
                FROM project_task_type_app
                WHERE odoo_record_id = ?
                LIMIT 1
            `;

            var result = tx.executeSql(query, [stageId]);

            if (result.rows.length > 0) {
                isFolded = result.rows.item(0).fold === 1;
            }
        });

        return isFolded;
    } catch (e) {
        console.error("isTaskStageFolded failed:", e);
        return false;
    }
}


function getAttachmentsForTask(odooRecordId) {
    var attachmentList = [];

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var query = `
                SELECT name, mimetype, account_id,odoo_record_id
                FROM ir_attachment_app
                WHERE res_model = 'project.task' AND res_id = ?
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
            // First get the user_id field from project_task_app
            var taskQuery = "SELECT user_id FROM project_task_app WHERE id = ? AND account_id = ?";
            var taskResult = tx.executeSql(taskQuery, [taskId, accountId]);
            
            if (taskResult.rows.length > 0) {
                var userIdField = taskResult.rows.item(0).user_id;
                
                if (userIdField) {
                    // Parse the comma-separated user IDs
                    var userIds = parseAssigneeIds(userIdField);
                    
                    if (userIds.length > 0) {
                        // Create placeholders for IN clause
                        var placeholders = userIds.map(function() { return '?'; }).join(',');
                        
                        // Get user details for each ID
                        var userQuery = `
                            SELECT odoo_record_id as user_id, name
                            FROM res_users_app 
                            WHERE account_id = ? AND odoo_record_id IN (${placeholders})
                            ORDER BY name COLLATE NOCASE ASC
                        `;
                        
                        var queryParams = [accountId].concat(userIds);
                        var userResult = tx.executeSql(userQuery, queryParams);
                        
                        for (var i = 0; i < userResult.rows.length; i++) {
                            var row = userResult.rows.item(i);
                            assignees.push({
                                id: row.user_id,
                                name: row.name
                            });
                        }
                    }
                }
            }
        });
    } catch (e) {
        console.error("getTaskAssignees failed:", e);
    }
    
    return assignees;
}

/**
 * Sets multiple assignees for a task using the user_id field
 * @param {number} taskId - The local task ID
 * @param {number} accountId - The account ID
 * @param {Array} assignees - Array of assignee objects with id property
 * @returns {Object} Success/error result
 */
function setTaskAssignees(taskId, accountId, assignees) {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        var timestamp = Utils.getFormattedTimestampUTC();
        
        db.transaction(function (tx) {
            var assigneeIds = formatAssigneeIds(assignees);
            
            // Update the user_id field with the comma-separated assignee IDs
            tx.executeSql(
                'UPDATE project_task_app SET user_id = ?, last_modified = ? WHERE id = ? AND account_id = ?',
                [assigneeIds, timestamp, taskId, accountId]
            );
        });
        
        return { success: true };
    } catch (e) {
        console.error("setTaskAssignees failed:", e);
        return { success: false, error: e.message };
    }
}

/**
 * Migrates task assignees from project_task_assignee_app table to user_id field in project_task_app
 * This is for backward compatibility with existing data
 */
function migrateTaskAssignees() {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        var timestamp = Utils.getFormattedTimestampUTC();
        
        console.log("Starting task assignee migration...");
        
        db.transaction(function (tx) {
            // Get all tasks that have assignees in the old table but empty user_id in the main table
            var query = `
                SELECT ta.task_id, ta.account_id, GROUP_CONCAT(ta.user_id) as assignee_ids
                FROM project_task_assignee_app ta
                JOIN project_task_app t ON ta.task_id = t.id AND ta.account_id = t.account_id
                WHERE (ta.status IS NULL OR ta.status != 'deleted') 
                  AND (t.user_id IS NULL OR t.user_id = '' OR t.user_id = '0')
                GROUP BY ta.task_id, ta.account_id
            `;
            
            var result = tx.executeSql(query);
            
            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);
                
                // Update the task with the migrated assignee IDs
                tx.executeSql(
                    'UPDATE project_task_app SET user_id = ?, last_modified = ? WHERE id = ? AND account_id = ?',
                    [row.assignee_ids, timestamp, row.task_id, row.account_id]
                );
                
                console.log("Migrated task", row.task_id, "with assignees:", row.assignee_ids);
            }
            
            console.log("Migration completed. Migrated", result.rows.length, "tasks.");
        });
        
        return { success: true, migratedCount: result.rows.length };
    } catch (e) {
        console.error("Task assignee migration failed:", e);
        return { success: false, error: e.message };
    }
}


/**
 * Safely marks a task as deleted, but prevents deletion if task has children
 * @param {number} taskId - The local ID of the task to delete
 * @param {boolean} forceDelete - Optional flag to override child protection (use with caution)
 * @returns {Object} Result object with success status and message
 */
function markTaskAsDeleted(taskId, forceDelete = false) {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        var timestamp = Utils.getFormattedTimestampUTC();
        
        var result = { success: false, message: "", deletedTaskIds: [] };
        
        db.transaction(function (tx) {
            // First, get the task details
            var taskResult = tx.executeSql(
                "SELECT id, name, project_id, odoo_record_id FROM project_task_app WHERE id = ? AND (status IS NULL OR status != 'deleted')", 
                [taskId]
            );
            
            if (taskResult.rows.length === 0) {
                throw new Error("Task not found with ID: " + taskId + " or task is already deleted");
            }
            
            var taskRow = taskResult.rows.item(0);
            var taskName = taskRow.name;
            var taskOdooRecordId = taskRow.odoo_record_id;
            
            console.log("Attempting to delete task: '" + taskName + "' (Local ID: " + taskId + ", Odoo ID: " + taskOdooRecordId + ")");
            
            // Check for child tasks using both possible parent reference methods
            var childTasks = getChildTasks(tx, taskId, taskOdooRecordId);
            
            if (childTasks.length > 0 && !forceDelete) {
                // Prevent deletion - task has children
                var childNames = childTasks.map(function(child) { return "'" + child.name + "'"; }).join(", ");
                
                result.success = false;
                result.message = "Cannot delete task '" + taskName + "' because it has " + childTasks.length + " child task(s): " + childNames + ". Please delete or move the child tasks first.";
                result.hasChildren = true;
                result.childTasks = childTasks;
                
                console.warn("❌ Deletion blocked: Task has " + childTasks.length + " child tasks");
                return;
            }
            
            // Safe to delete - no children or force delete is enabled
            tx.executeSql(
                "UPDATE project_task_app SET status = 'deleted', last_modified = ? WHERE id = ?", 
                [timestamp, taskId]
            );
            
            // Mark related timesheets as deleted
            markRelatedTimesheetsAsDeleted(tx, [taskId], timestamp);
            
            if (forceDelete && childTasks.length > 0) {
                console.warn("⚠️  Force delete enabled - deleted parent task with " + childTasks.length + " children");
                result.message = "Task '" + taskName + "' deleted (forced deletion with " + childTasks.length + " child tasks remaining)";
            } else {
                result.message = "Task '" + taskName + "' successfully deleted";
            }
            
            result.success = true;
            result.deletedTaskIds = [taskId];
            
            console.info("✅ Task deleted successfully: " + taskName);
        });
        
        return result;
        
    } catch (e) {
        console.error("❌ Error marking task as deleted (ID " + taskId + "): " + e);
        return {
            success: false,
            message: "Failed to delete task: " + e.message,
            deletedTaskIds: []
        };
    }
}

/**
 * Deletes multiple tasks safely, checking each for children
 * @param {Array<number>} taskIds - Array of local task IDs to delete
 * @param {boolean} forceDelete - Optional flag to override child protection
 * @returns {Object} Result object with detailed deletion results
 */
function markMultipleTasksAsDeleted(taskIds, forceDelete = false) {
    var results = {
        success: true,
        totalRequested: taskIds.length,
        successfulDeletions: [],
        blockedDeletions: [],
        failedDeletions: [],
        message: ""
    };
    
    for (var i = 0; i < taskIds.length; i++) {
        var result = markTaskAsDeleted(taskIds[i], forceDelete);
        
        if (result.success) {
            results.successfulDeletions.push({
                taskId: taskIds[i],
                message: result.message
            });
        } else if (result.hasChildren) {
            results.blockedDeletions.push({
                taskId: taskIds[i],
                message: result.message,
                childTasks: result.childTasks
            });
        } else {
            results.failedDeletions.push({
                taskId: taskIds[i],
                message: result.message
            });
        }
    }
    
    // Generate summary message
    var messages = [];
    if (results.successfulDeletions.length > 0) {
        messages.push(results.successfulDeletions.length + " task(s) deleted successfully");
    }
    if (results.blockedDeletions.length > 0) {
        messages.push(results.blockedDeletions.length + " task(s) blocked (have children)");
    }
    if (results.failedDeletions.length > 0) {
        messages.push(results.failedDeletions.length + " task(s) failed to delete");
        results.success = false;
    }
    
    results.message = messages.join(", ");
    
    return results;
}

/**
 * Gets all direct child tasks for a given parent task
 * @param {Object} tx - Database transaction object
 * @param {number} parentLocalId - The local 'id' of the parent task
 * @param {number} parentOdooRecordId - The 'odoo_record_id' of the parent task
 * @returns {Array<Object>} Array of child task objects
 */
function getChildTasks(tx, parentLocalId, parentOdooRecordId) {
    var childTasks = [];
    var seenIds = new Set(); // To prevent duplicates
    
    try {
        // Method 1: Check if parent_id references local 'id' field
        var childResult1 = tx.executeSql(
            "SELECT id, name, odoo_record_id FROM project_task_app WHERE parent_id = ? AND (status IS NULL OR status != 'deleted')", 
            [parentLocalId]
        );
        
        for (var i = 0; i < childResult1.rows.length; i++) {
            var row = childResult1.rows.item(i);
            if (!seenIds.has(row.id)) {
                childTasks.push({
                    id: row.id,
                    name: row.name,
                    odoo_record_id: row.odoo_record_id
                });
                seenIds.add(row.id);
            }
        }
        
        // Method 2: Check if parent_id references 'odoo_record_id' field
        if (parentOdooRecordId && parentOdooRecordId > 0) {
            var childResult2 = tx.executeSql(
                "SELECT id, name, odoo_record_id FROM project_task_app WHERE parent_id = ? AND (status IS NULL OR status != 'deleted')", 
                [parentOdooRecordId]
            );
            
            for (var j = 0; j < childResult2.rows.length; j++) {
                var row2 = childResult2.rows.item(j);
                if (!seenIds.has(row2.id)) {
                    childTasks.push({
                        id: row2.id,
                        name: row2.name,
                        odoo_record_id: row2.odoo_record_id
                    });
                    seenIds.add(row2.id);
                }
            }
        }
        
    } catch (e) {
        console.error("Error getting child tasks:", e);
    }
    
    return childTasks;
}

/**
 * Checks if a task has any child tasks (non-recursive check)
 * @param {number} taskId - The local ID of the task to check
 * @returns {Object} Result object with hasChildren boolean and child task details
 */
function checkTaskHasChildren(taskId) {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        var result = { hasChildren: false, childCount: 0, childTasks: [] };
        
        db.transaction(function (tx) {
            var taskResult = tx.executeSql(
                "SELECT id, name, odoo_record_id FROM project_task_app WHERE id = ?", 
                [taskId]
            );
            
            if (taskResult.rows.length > 0) {
                var taskRow = taskResult.rows.item(0);
                var childTasks = getChildTasks(tx, taskRow.id, taskRow.odoo_record_id);
                
                result.hasChildren = childTasks.length > 0;
                result.childCount = childTasks.length;
                result.childTasks = childTasks;
            }
        });
        
        return result;
        
    } catch (e) {
        console.error("Error checking task children:", e);
        return { hasChildren: false, childCount: 0, childTasks: [], error: e.message };
    }
}

/**
 * Marks related timesheets as deleted when tasks are deleted
 * @param {Object} tx - Database transaction object
 * @param {Array<number>} taskIds - Array of local task IDs from project_task_app
 * @param {string} timestamp - Timestamp for last_modified
 */
function markRelatedTimesheetsAsDeleted(tx, taskIds, timestamp) {
    if (taskIds.length === 0) return;
    
    try {
        // Get the odoo_record_id values for the local task IDs
        var placeholders = taskIds.map(() => '?').join(',');
        var taskRecordIds = [];
        
        var taskQuery = tx.executeSql(
            "SELECT odoo_record_id FROM project_task_app WHERE id IN (" + placeholders + ") AND odoo_record_id IS NOT NULL",
            taskIds
        );
        
        // Collect all odoo_record_id values
        for (var i = 0; i < taskQuery.rows.length; i++) {
            var odooRecordId = taskQuery.rows.item(i).odoo_record_id;
            if (odooRecordId && odooRecordId > 0) {
                taskRecordIds.push(odooRecordId);
            }
        }
        
        // If we have odoo_record_ids, mark related timesheets as deleted
        if (taskRecordIds.length > 0) {
            var timesheetPlaceholders = taskRecordIds.map(() => '?').join(',');
            var updateParams = [timestamp].concat(taskRecordIds);
            
            var result = tx.executeSql(
                "UPDATE account_analytic_line_app SET status = 'deleted', last_modified = ? WHERE task_id IN (" + timesheetPlaceholders + ") AND (status IS NULL OR status != 'deleted')",
                updateParams
            );
            
            if (result.rowsAffected > 0) {
               // console.log("Marked " + result.rowsAffected + " related timesheet entries as deleted");
            }
        }
        
    } catch (e) {
        console.error("Error marking related timesheets as deleted:", e);
    }
}

function edittaskData(data) {
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

    db.transaction(function (tx) {
        tx.executeSql('UPDATE project_task_app SET \
            account_id = ?, name = ?, project_id = ?, parent_id = ?, initial_planned_hours = ?, priority =? , description = ?, user_id = ?, sub_project_id = ?, \
            start_date = ?, end_date = ?, deadline = ?, last_modified = ? WHERE id = ?',
                      [data.selectedAccountUserId, data.nameInput, data.selectedProjectId, data.selectedparentId, data.initialInput, data.priority, data.editdescription, data.selectedassigneesUserId, data.editselectedSubProjectId,
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

        var projectColorMap = {};

        db.transaction(function (tx) {
            // Build map of project colors for this account
            var projectQuery = "SELECT odoo_record_id, color_pallet FROM project_project_app WHERE account_id = ?";
            var projectResult = tx.executeSql(projectQuery, [accountId]);
            for (var j = 0; j < projectResult.rows.length; j++) {
                var projectRow = projectResult.rows.item(j);
                projectColorMap[projectRow.odoo_record_id] = projectRow.color_pallet;
            }

            const results = tx.executeSql(
                              "SELECT * FROM project_task_app WHERE account_id = ? AND (status IS NULL OR status != 'deleted') ORDER BY name COLLATE NOCASE ASC",
                              [accountId]
                              );

            for (let i = 0; i < results.rows.length; i++) {
                const row = results.rows.item(i);
                var task = {
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
                    priority: row.priority,
                    state: row.state,
                    personal_stage: row.personal_stage,  // Include personal_stage field
                    description: row.description,
                    last_modified: row.last_modified,
                    user_id: row.user_id,
                    status: row.status,
                    odoo_record_id: row.odoo_record_id
                };

                // Inherit color from sub_project or project
                var inheritedColor = 0;
                if (task.sub_project_id) {
                    inheritedColor = resolveProjectColor(task.sub_project_id, projectColorMap, tx);
                }
                if (!inheritedColor && task.project_id) {
                    inheritedColor = resolveProjectColor(task.project_id, projectColorMap, tx);
                }
                task.color_pallet = inheritedColor;

                // Calculate total hours spent from timesheet entries
                var timeQuery = `
                    SELECT SUM(unit_amount) as total_hours 
                    FROM account_analytic_line_app 
                    WHERE task_id = ? AND account_id = ? AND (status IS NULL OR status != 'deleted')
                `;
                var timeResult = tx.executeSql(timeQuery, [task.odoo_record_id, accountId]);
                if (timeResult.rows.length > 0 && timeResult.rows.item(0).total_hours !== null) {
                    task.spent_hours = timeResult.rows.item(0).total_hours;
                } else {
                    task.spent_hours = 0;
                }

                taskList.push(task);
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
              //  console.log("getTaskDetails initial project_id:", project_id);
                var sub_project_id = -1;

                if (project_id > 0) {
                    // Look up project_project_app to check if this project has a parent_id (indicating it is a subproject)
                    // Include account_id check to ensure project is from the same account
                    var rs_project = tx.executeSql(
                        'SELECT parent_id FROM project_project_app WHERE odoo_record_id = ? AND account_id = ? LIMIT 1',
                        [project_id, row.account_id]
                    );

                    if (rs_project.rows.length > 0) {
                        var parent_id = rs_project.rows.item(0).parent_id;
                       // console.log("#####->>>>", rs_project.rows.item(0).parent_id)
                        if (parent_id !== undefined && parent_id !== null && parent_id > 0) {
                            // This project is a subproject
                            sub_project_id = project_id;
                            project_id = parent_id;
                         //   console.log("@@@@@@@@@Subproject detected: sub_project_id =", sub_project_id, ", parent project_id =", project_id);
                        } else {
                            // Top-level project
                            sub_project_id = row.sub_project_id;
                            //console.log("Top-level project detected, project_id =", project_id);
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
                    priority :row.priority,
                    state: row.state || "",
                    personal_stage: row.personal_stage || null,
                    description: row.description || "",
                    last_modified: row.last_modified,
                    user_id: row.user_id,
                    status: row.status || "",
                    odoo_record_id: row.odoo_record_id
                };

              //  console.log("getTaskDetails enriched task:", JSON.stringify(task_detail));
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
            var query = "SELECT * FROM project_task_app WHERE status IS NULL OR status != 'deleted' ORDER BY end_date ASC";
            var result = tx.executeSql(query);

            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);
                var task = DBCommon.rowToObject(row);

                 // Inherit color from sub_project, project, or walk up hierarchy
                var inheritedColor = 0;
                if (task.sub_project_id) {
                    inheritedColor = resolveProjectColor(task.sub_project_id, projectColorMap, tx);
                }
                if (!inheritedColor && task.project_id) {
                    inheritedColor = resolveProjectColor(task.project_id, projectColorMap, tx);
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
 // Recursive function to resolve project color by walking up the hierarchy
    function resolveProjectColor(projectId, projectMap, tx) {
        var color = projectMap[projectId];
        // If color is found AND not zero → return it
        if (color && color !== "0" && color !== 0) {
          //  console.log("✅ Found non-zero color for projectId:", projectId, "color:", color);
            return color;
        }
        // Otherwise, check the parent
        var parentQuery = "SELECT parent_id FROM project_project_app WHERE odoo_record_id = ?";
        var parentResult = tx.executeSql(parentQuery, [projectId]);
 
        if (parentResult.rows.length > 0) {
            var parentId = parentResult.rows.item(0).parent_id;
         //   console.log("🔄 projectId", projectId, "has parent:", parentId);
 
            if (parentId && parentId !== 0) {
                return resolveProjectColor(parentId, projectMap, tx); // recurse to parent
            }
        }
     //   console.log("⚠️ No non-zero color found for projectId:", projectId);
        return 0;
    }
 

/**
 * Filters tasks based on date criteria and search query while preserving parent-child hierarchy
 * @param {string} filterType - The filter type: "today", "this_week", "next_week", "this_month", "later", "completed"
 * @param {string} searchQuery - The search query string
 * @returns {Array<Object>} Filtered list of tasks with hierarchy preserved
 */
function getFilteredTasks(filterType, searchQuery, accountId) {
    var allTasks;
    
    // If accountId is provided, filter by account first
    if (accountId !== undefined && accountId >= 0) {
        allTasks = getTasksForAccount(accountId);
    } else {
        allTasks = getAllTasks();
    }
    
    var filteredTasks = [];
    var currentDate = new Date();
    var includedTaskIds = new Map();
    var taskById = {};
    
    // Create a map of tasks by composite key for quick lookup
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
        
        var hasIncludedChildren = false;
        for (var j = 0; j < allTasks.length; j++) {
            var potentialChild = allTasks[j];
            var childKey = potentialChild.odoo_record_id + '_' + potentialChild.account_id;
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
    // Execute this pass when:
    // 1. Filter is "all" and there's a search query, OR
    // 2. The child task itself matches the filter criteria (date range)
    if ((filterType === "all" && searchQuery && searchQuery.trim() !== "") || filterType !== "all") {
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
                            // For "all" filter with search, include all children
                            // For other filters, only include if child matches the filter criteria
                            var shouldInclude = (filterType === "all" && searchQuery && searchQuery.trim() !== "") || 
                                              passesDateFilter(task, filterType, currentDate);
                            
                            if (shouldInclude) {
                                var taskKey = task.odoo_record_id + '_' + task.account_id;
                                includedTaskIds.set(taskKey, task);
                            }
                            break;
                        }
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
 * Gets filtered tasks by assignees
 * @param {Array} assigneeIds - Array of assignee IDs to filter by
 * @param {number} accountId - Account ID to filter tasks
 * @param {string} filterType - Date filter type (optional)
 * @param {string} searchQuery - Search query (optional)
 * @returns {Array<Object>} Filtered list of tasks
 */
function getTasksByAssignees(assigneeIds, accountId, filterType, searchQuery) {

    var allTasks;
    
    // If accountId is provided, filter by account first
    if (accountId !== undefined && accountId >= 0) {
        allTasks = getTasksForAccount(accountId);

    } else {
        allTasks = getAllTasks();

    }
    
    var filteredTasks = [];
    var currentDate = new Date();
    
    if (!assigneeIds || assigneeIds.length === 0) {

        return filteredTasks;
    }
    
    // Filter tasks by assignees
    for (var i = 0; i < allTasks.length; i++) {
        var task = allTasks[i];
        
        // Check if task has any of the selected assignees
        var hasMatchingAssignee = false;
        
        if (task.user_id) {
            var taskAssigneeIds = parseAssigneeIds(task.user_id);
            
            for (var j = 0; j < assigneeIds.length; j++) {
                var selectedAssignee = assigneeIds[j];
                
                // Handle both legacy format (simple IDs) and new format (composite objects)
                if (typeof selectedAssignee === 'object' && selectedAssignee.user_id !== undefined) {
                    // New composite ID format: check both user_id and account_id
                    var userIdMatches = taskAssigneeIds.indexOf(selectedAssignee.user_id) !== -1;
                    var accountMatches = (task.account_id === selectedAssignee.account_id);
                    
                    if (userIdMatches && accountMatches) {
                        hasMatchingAssignee = true;
                        break;
                    }
                } else {
                    // Legacy format: simple ID matching with account verification
                    if (taskAssigneeIds.indexOf(selectedAssignee) !== -1) {
                        // Additional check: When filtering across multiple accounts,
                        // ensure the assignee belongs to the same account as the task
                        if (accountId === -1) {
                            // For "All Accounts" view, verify assignee-task account match
                            var assigneeAccountId = getAssigneeAccountId(selectedAssignee);
                            if (assigneeAccountId !== -1 && task.account_id !== assigneeAccountId) {
                                continue;
                            }
                        }
                        hasMatchingAssignee = true;
                        break;
                    }
                }
            }
        }
        
        if (hasMatchingAssignee) {
            var passesFilter = true;
            
            // Apply date filter if specified
            if (filterType && !passesDateFilter(task, filterType, currentDate)) {
                passesFilter = false;
            }
            
            // Apply search filter if specified
            if (passesFilter && searchQuery && !passesSearchFilter(task, searchQuery)) {
                passesFilter = false;
            }
            
            if (passesFilter) {
                filteredTasks.push(task);
            }
        }
    }
    

    return filteredTasks;
}

/**
 * Gets filtered tasks by assignees with hierarchical support
 * If a subtask matches the assignee filter, its parent task is also included
 * to maintain parent-child hierarchy for navigation
 * @param {Array} assigneeIds - Array of assignee IDs to filter by
 * @param {number} accountId - Account ID to filter tasks
 * @param {string} filterType - Date filter type (optional)
 * @param {string} searchQuery - Search query (optional)
 * @returns {Array<Object>} Filtered list of tasks with hierarchy preserved
 */
function getTasksByAssigneesHierarchical(assigneeIds, accountId, filterType, searchQuery) {
    var allTasks;
    
    // If accountId is provided, filter by account first
    if (accountId !== undefined && accountId >= 0) {
        allTasks = getTasksForAccount(accountId);
    } else {
        allTasks = getAllTasks();
    }
    
    if (!assigneeIds || assigneeIds.length === 0) {
        return [];
    }
    
    var currentDate = new Date();
    var matchingTaskIds = new Set();
    var taskById = {};
    var tasksByParent = {};
    
    // Create lookup maps
    for (var i = 0; i < allTasks.length; i++) {
        var task = allTasks[i];
        var compositeId = task.odoo_record_id + "_" + task.account_id;
        taskById[compositeId] = task;
        
        var parentId = (task.parent_id === null || task.parent_id === 0) ? -1 : task.parent_id;
        var parentCompositeId = parentId + "_" + task.account_id;
        
        if (!tasksByParent[parentCompositeId]) {
            tasksByParent[parentCompositeId] = [];
        }
        tasksByParent[parentCompositeId].push(task);
    }
    
    // First pass: Find tasks that directly match the assignee filter
    for (var i = 0; i < allTasks.length; i++) {
        var task = allTasks[i];
        var hasMatchingAssignee = false;
        
        if (task.user_id) {
            var taskAssigneeIds = parseAssigneeIds(task.user_id);
            
            for (var j = 0; j < assigneeIds.length; j++) {
                var selectedAssignee = assigneeIds[j];
                
                // Handle both legacy format (simple IDs) and new format (composite objects)
                if (typeof selectedAssignee === 'object' && selectedAssignee.user_id !== undefined) {
                    // New composite ID format: check both user_id and account_id
                    var userIdMatches = taskAssigneeIds.indexOf(selectedAssignee.user_id) !== -1;
                    var accountMatches = (task.account_id === selectedAssignee.account_id);
                    
                    if (userIdMatches && accountMatches) {
                        hasMatchingAssignee = true;
                        break;
                    }
                } else {
                    // Legacy format: simple ID matching with account verification
                    if (taskAssigneeIds.indexOf(selectedAssignee) !== -1) {
                        // Additional check: When filtering across multiple accounts,
                        // ensure the assignee belongs to the same account as the task
                        if (accountId === -1) {
                            // For "All Accounts" view, verify assignee-task account match
                            var assigneeAccountId = getAssigneeAccountId(selectedAssignee);
                            if (assigneeAccountId !== -1 && task.account_id !== assigneeAccountId) {
                                continue;
                            }
                        }
                        hasMatchingAssignee = true;
                        break;
                    }
                }
            }
        }
        
        if (hasMatchingAssignee) {
            var passesFilter = true;
            
            // Apply date filter if specified
            if (filterType && !passesDateFilter(task, filterType, currentDate)) {
                passesFilter = false;
            }
            
            // Apply search filter if specified
            if (passesFilter && searchQuery && !passesSearchFilter(task, searchQuery)) {
                passesFilter = false;
            }
            
            if (passesFilter) {
                var compositeId = task.odoo_record_id + "_" + task.account_id;
                matchingTaskIds.add(compositeId);
            }
        }
    }
    
    // Second pass: Include parent tasks for matched tasks to maintain hierarchy
    var toProcess = Array.from(matchingTaskIds);
    for (var i = 0; i < toProcess.length; i++) {
        var compositeId = toProcess[i];
        var task = taskById[compositeId];
        
        if (task && task.parent_id && task.parent_id !== 0) {
            var parentCompositeId = task.parent_id + "_" + task.account_id;
            var parentTask = taskById[parentCompositeId];
            
            if (parentTask && !matchingTaskIds.has(parentCompositeId)) {
                matchingTaskIds.add(parentCompositeId);
                toProcess.push(parentCompositeId); // Continue up the hierarchy
            }
        }
    }
    
    // Build final filtered tasks list
    var filteredTasks = [];
    for (var i = 0; i < allTasks.length; i++) {
        var task = allTasks[i];
        var compositeId = task.odoo_record_id + "_" + task.account_id;
        
        if (matchingTaskIds.has(compositeId)) {
            filteredTasks.push(task);
        }
    }
    
    return filteredTasks;
}

/**
 * Helper function to get the account ID for a given assignee ID
 * This is used to ensure proper account matching in multi-account filtering
 */
function getAssigneeAccountId(assigneeId) {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        var accountId = -1;
        
        db.transaction(function (tx) {
            var result = tx.executeSql(
                "SELECT account_id FROM res_users_app WHERE odoo_record_id = ? LIMIT 1", 
                [assigneeId]
            );
            if (result.rows.length > 0) {
                accountId = result.rows.item(0).account_id;
            }
        });
        
        return accountId;
    } catch (e) {
        console.error("getAssigneeAccountId failed for assignee", assigneeId, ":", e);
        return -1;
    }
}

function getAccountsWithTaskCounts() {
    var accounts = [];

    
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        
        db.transaction(function (tx) {
            var query = `
                SELECT 
                    t.account_id,
                    COUNT(t.id) as task_count,
                    COUNT(CASE WHEN (t.status IS NULL OR t.status != 'deleted') THEN 1 END) as active_task_count
                FROM project_task_app t
                GROUP BY t.account_id
                ORDER BY t.account_id ASC
            `;
            
            var result = tx.executeSql(query);

            
            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);
                console.log("📝 DB Account:", row.account_id, "Total tasks:", row.task_count, "Active tasks:", row.active_task_count);
                accounts.push({
                    account_id: row.account_id,
                    account_name: row.account_id === 0 ? "Local Account" : "Account " + row.account_id,
                    task_count: row.task_count,
                    active_task_count: row.active_task_count
                });
            }
        });
    } catch (e) {
        console.error("❌ getAccountsWithTaskCounts failed:", e);
    }
    
    console.log("📊 Returning", accounts.length, "accounts");
    return accounts;
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
    
    // Check if task's stage has fold == 1
    // If fold == 1, task should only be displayed in "all" or "done" filters
    // However, exclude cancelled tasks from done filter even if they have fold == 1
    if (task.state && isTaskStageFolded(task.state)) {
        if (filterType === "done" && isTaskInCancelledStage(task)) {
            return false; // Don't show cancelled tasks in done filter
        }
        return filterType === "all" || filterType === "done";
    }
    
    // Tasks without start_date or end_date should only appear in "all" filter
    if (!task.end_date && !task.start_date) {
        return false;
    }
    
    var today = new Date(currentDate.getFullYear(), currentDate.getMonth(), currentDate.getDate());
    
    switch (filterType) {
        case "all":
            return true;
        case "today":
            if (isTaskInDoneStage(task)) return false;
            return isTaskDueToday(task, today);
        case "this_week":
            if (isTaskInDoneStage(task)) return false;
            return isTaskDueThisWeek(task, today);
        case "next_week":
            if (isTaskInDoneStage(task)) return false;
            return isTaskDueNextWeek(task, today);
        case "this_month":
            if (isTaskInDoneStage(task)) return false;
            return isTaskDueThisMonth(task, today);
        case "overdue":
            // Exclude tasks which are in the Done stage from showing as overdue
            if (isTaskInDoneStage(task)) return false;
            return isTaskOverdue(task, today);
        case "later":
            if (isTaskInDoneStage(task)) return false;
            return isTaskDueLater(task, today);
        case "done":
            // Show tasks which have their stage name set to "Done" but exclude cancelled tasks
            return isTaskInDoneStage(task) && !isTaskInCancelledStage(task);
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
    if (!task.end_date && !task.start_date) {
        return false;
    }
    
    var dateStatus = getTaskDateStatus(task, today);
    
    // Show if task is in range today or NOT overdue
    return dateStatus.isInRange || dateStatus.isOverdue;
}

/**
 * Check if task should appear in this week filter (date range overlaps with this week)
 */
function isTaskDueThisWeek(task, today) {
    if (!task.end_date && !task.start_date) {
        return false;
    }
    
    // Calculate this week's start (Monday) and end (Sunday)
    var currentDow = today.getDay();
    var daysFromMonday = currentDow === 0 ? 6 : currentDow - 1; // If Sunday, 6 days from Monday; otherwise, day - 1
    
    var weekStart = new Date(today);
    weekStart.setDate(today.getDate() - daysFromMonday);
    
    var weekEnd = new Date(weekStart);
    weekEnd.setDate(weekStart.getDate() + 6); // Sunday of current week
    
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
function isTaskDueNextWeek(task, today) {
    if (!task.end_date && !task.start_date) {
        return false;
    }
    
    // Calculate next week's start (Monday) and end (Sunday)
    var currentDow = today.getDay();
    var daysUntilNextMonday = currentDow === 0 ? 1 : (8 - currentDow);
    
    var nextWeekStart = new Date(today);
    nextWeekStart.setDate(today.getDate() + daysUntilNextMonday);
    
    var nextWeekEnd = new Date(nextWeekStart);
    nextWeekEnd.setDate(nextWeekStart.getDate() + 6); // Sunday of next week
    
    // Normalize to remove time component
    var nextWeekStartDay = new Date(nextWeekStart.getFullYear(), nextWeekStart.getMonth(), nextWeekStart.getDate());
    var nextWeekEndDay = new Date(nextWeekEnd.getFullYear(), nextWeekEnd.getMonth(), nextWeekEnd.getDate());
    
    // Check if any day in next week falls within the task's date range
    for (var day = new Date(nextWeekStartDay); day <= nextWeekEndDay; day.setDate(day.getDate() + 1)) {
        var dateStatus = getTaskDateStatus(task, day);
        if (dateStatus.isInRange) {
            return true;
        }
    }
    
    return false;
}

/**
 * Check if task should appear in this month filter (date range overlaps with this month)
 */
function isTaskDueThisMonth(task, today) {
    if (!task.end_date && !task.start_date) {
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
    if (!task.end_date && !task.start_date) {
        return false; // Tasks without start/end dates should only appear in "all" filter
    }
    
    var monthEnd = new Date(today.getFullYear(), today.getMonth() + 1, 0); // Last day of current month
    
    // Get task start date (or end date if no start date)
    var taskStartDate = null;
    if (task.start_date) {
        taskStartDate = new Date(task.start_date);
    } else if (task.end_date) {
        taskStartDate = new Date(task.end_date);
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
 * Check if task is overdue
 * @param {Object} task - The task object
 * @param {Date} today - Current date for comparison
 * @returns {boolean} True if task is overdue
 */
function isTaskOverdue(task, today) {
    if (!task.end_date && !task.start_date) {
        return false;
    }
    
    var dateStatus = getTaskDateStatus(task, today);
    // If task is in Done stage, treat as not overdue
    if (isTaskInDoneStage(task)) return false;
    return dateStatus.isOverdue;
}

/**
 * Checks whether the task's stage (project_task_type_app) name is "Done" (case-insensitive)
 * @param {Object} task
 * @returns {boolean}
 */
function isTaskInDoneStage(task) {
    try {
        if (!task) return false;

        // task.state is expected to be the odoo_record_id for the task type/stage
        var stageId = task.state;
        if (!stageId) return false;

        var stageName = getTaskStageName(stageId);
        if (!stageName) return false;

        return stageName.toString().toLowerCase() === "done" || stageName.toString().toLowerCase() === "completed" || stageName.toString().toLowerCase() === "finished" || stageName.toString().toLowerCase() === "closed" || stageName.toString().toLowerCase() === "verified";
    } catch (e) {
        console.error("isTaskInDoneStage failed:", e);
        return false;
    }
}

/**
 * Checks whether the task's stage (project_task_type_app) name is "Cancelled" (case-insensitive)
 * @param {Object} task
 * @returns {boolean}
 */
function isTaskInCancelledStage(task) {
    try {
        if (!task) return false;

        // task.state is expected to be the odoo_record_id for the task type/stage
        var stageId = task.state;
        if (!stageId) return false;

        var stageName = getTaskStageName(stageId);
        if (!stageName) return false;

        return stageName.toString().toLowerCase() === "cancelled" || stageName.toString().toLowerCase() === "canceled";
    } catch (e) {
        console.error("isTaskInCancelledStage failed:", e);
        return false;
    }
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
    
    // Check if task is overdue - prioritize deadline first, then end_date
    if (deadlineDay) {
        isOverdue = checkDay > deadlineDay;
    } else if (endDay) {
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

/**
 * Sets the priority level of a task in the local database.
 *
 * @param {number} taskId - The local ID of the task.
 * @param {number} priority - The priority level (0-3, where 0 is lowest and 3 is highest).
 * @param {string} status - The status update type.
 * @returns {Object} - Result object with success status and message.
 */
function setTaskPriority(taskId, priority, status) {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        var result = { success: false, message: "" };
        
        // Ensure priority is within valid range (0-3) and convert to string
      //  var numericPriority = Math.max(0, Math.min(3, parseInt(priority) || 0));
        priority.toString(); // Store as string to match Odoo format
        
        db.transaction(function (tx) {
            var updateResult = tx.executeSql(
                'UPDATE project_task_app SET priority = ?, last_modified = ?, status = ? WHERE id = ?',
                [priority, Utils.getFormattedTimestampUTC(), status, taskId]
            );
            
            if (updateResult.rowsAffected > 0) {
                result.success = true;
                result.message = "Task priority set to " + priority;
              //  console.log("Task priority updated:", taskId, "priority:", priority);
            } else {
                result.message = "Task not found or no changes made";
                console.warn("⚠️ No task updated with ID:", taskId);
            }
        });
        
        return result;
    } catch (e) {
        console.error("❌ setTaskPriority failed:", e);
        return { success: false, message: "Failed to set task priority: " + e.message };
    }
}

/**
 * Retrieves all non-deleted tasks for a specific project from the `project_task_app` table,
 * and adds inherited color and total hours spent from timesheet entries.
 *
 * @param {number} projectOdooRecordId - The odoo_record_id of the project
 * @param {number} accountId - The account ID
 * @returns {Array<Object>} A list of task objects with color and spentHours for the specified project.
 */
function getTasksForProject(projectOdooRecordId, accountId) {
    var taskList = [];

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            // Get all tasks for the specific project and account
            var query = `
                SELECT 
                    id,
                    odoo_record_id,
                    account_id,
                    name,
                    description,
                    project_id,
                    sub_project_id,
                    parent_id,
                    user_id,
                    start_date,
                    end_date,
                    deadline,
                    initial_planned_hours,
                    state,
                    priority,
                    last_modified,
                    status
                FROM project_task_app 
                WHERE project_id = ? 
                AND account_id = ? 
                AND (status != 'deleted' OR status IS NULL)
                ORDER BY last_modified DESC
            `;

            var result = tx.executeSql(query, [projectOdooRecordId, accountId]);
            
            // Build a map of project colors for efficient lookup
            var projectColorQuery = "SELECT odoo_record_id, color_pallet FROM project_project_app WHERE account_id = ?";
            var projectColorResult = tx.executeSql(projectColorQuery, [accountId]);
            var projectMap = {};
            for (var j = 0; j < projectColorResult.rows.length; j++) {
                var projectRow = projectColorResult.rows.item(j);
                projectMap[projectRow.odoo_record_id] = projectRow.color_pallet;
            }

            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);

                // Calculate spent hours for this task
                var spentHoursQuery = `
                    SELECT COALESCE(SUM(unit_amount), 0) as spent_hours 
                    FROM account_analytic_line_app 
                    WHERE task_id = ? AND account_id = ? AND (status != 'deleted' OR status IS NULL)
                `;
                var spentResult = tx.executeSql(spentHoursQuery, [row.odoo_record_id, accountId]);
                var spentHours = spentResult.rows.length > 0 ? spentResult.rows.item(0).spent_hours : 0;

                // Resolve project color
                var projectIdToCheck = row.project_id || row.sub_project_id;
                var inheritedColor = resolveProjectColor(projectIdToCheck, projectMap, tx);

                var task = {
                    id: row.id,
                    odoo_record_id: row.odoo_record_id,
                    account_id: row.account_id,
                    name: row.name,
                    description: row.description,
                    project_id: row.project_id,
                    sub_project_id: row.sub_project_id,
                    parent_id: row.parent_id,
                    user_id: row.user_id,
                    start_date: row.start_date,
                    end_date: row.end_date,
                    deadline: row.deadline,
                    initial_planned_hours: row.initial_planned_hours,
                    state: row.state,
                    priority: row.priority,
                    last_modified: row.last_modified,
                    status: row.status,
                    color_pallet: inheritedColor,
                    spent_hours: spentHours
                };

                taskList.push(task);
            }
        });
    } catch (e) {
        console.error("❌ getTasksForProject failed:", e);
    }

    return taskList;
}

/**
 * Gets all unique assignees who have been assigned to tasks in the given account
 * @param {number} accountId - The account ID to filter assignees by (use -1 for all accounts)
 * @returns {Array} Array of assignee objects with id, name, and odoo_record_id
 */
function getAllTaskAssignees(accountId) {
    var assignees = [];
    
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        
        db.transaction(function (tx) {
            // Get all unique user IDs from tasks (handling comma-separated values)
            var taskQuery, taskParams;
            
            if (accountId === -1) {
                // Get from all accounts
                taskQuery = `
                    SELECT DISTINCT user_id, account_id
                    FROM project_task_app 
                    WHERE user_id IS NOT NULL AND user_id != ''
                `;
                taskParams = [];
            } else {
                // Get from specific account
                taskQuery = `
                    SELECT DISTINCT user_id, account_id
                    FROM project_task_app 
                    WHERE account_id = ? AND user_id IS NOT NULL AND user_id != ''
                `;
                taskParams = [accountId];
            }
            
            var taskResult = tx.executeSql(taskQuery, taskParams);
            
            var userAccountMap = {}; // Map user_id -> account_id for users
            
            // Parse comma-separated user IDs from all tasks
            for (var i = 0; i < taskResult.rows.length; i++) {
                var row = taskResult.rows.item(i);
                var userIdField = row.user_id;
                var taskAccountId = row.account_id;
                
                if (userIdField) {
                    var userIds = parseAssigneeIds(userIdField);
                    for (var j = 0; j < userIds.length; j++) {
                        userAccountMap[userIds[j]] = taskAccountId;
                    }
                }
            }
            
            var allUserIds = Object.keys(userAccountMap).map(function(key) { return parseInt(key); });
            
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
                    var placeholders = userIds.map(function() { return '?'; }).join(',');
                    
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
                        console.log("Loading assignee:", userRow.name, "Account:", userRow.account_name, "ID:", userRow.odoo_record_id);
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
        console.error("getAllTaskAssignees failed:", e);
    }
    
    return assignees;
}

/**
 * Gets all task stages (types) for a specific project and account
 * Returns all active stages for the account (both global and project-specific)
 * @param {number} projectOdooRecordId - The odoo_record_id of the project
 * @param {number} accountId - The account ID
 * @returns {Array} Array of stage objects with id, odoo_record_id, name, sequence, fold
 */
function getTaskStagesForProject(projectOdooRecordId, accountId) {
    var stages = [];
    
    console.log("🔍 getTaskStagesForProject called with projectOdooRecordId:", projectOdooRecordId, "accountId:", accountId);
    
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        
        db.transaction(function (tx) {
            // Get all active PROJECT stages for this account
            // Filter out personal stages which have empty is_global
            // Personal stages have is_global stored as '[]' (empty array from Odoo)
            // Project stages either:
            //   1. Have is_global = 1 (available to all projects)
            //   2. Have is_global containing project IDs like "3,4,5" (specific to certain projects)
            // Personal user stages have is_global = NULL, empty string, or '[]' and should be excluded
            var result = tx.executeSql(
                'SELECT id, odoo_record_id, name, sequence, fold, description, is_global \
                 FROM project_task_type_app \
                 WHERE account_id = ? AND active = 1 \
                 AND (is_global IS NOT NULL AND is_global != "" AND is_global != "[]") \
                 ORDER BY sequence ASC, name COLLATE NOCASE ASC',
                [accountId]
            );
            
            console.log("🔍 getTaskStagesForProject: Found " + result.rows.length + " PROJECT stages for account " + accountId + " (before project filter)");
            
            // Filter stages to show only:
            // 1. Global stages (is_global = 1 or is_global = "1" - available to ALL projects)
            // 2. Stages specific to this project (is_global contains the projectOdooRecordId)
            // 
            // IMPORTANT: In Odoo's project.task.type model:
            // - If project_ids field is EMPTY (False/null), the stage is available to ALL projects
            // - If project_ids contains specific IDs, the stage is only available to those projects
            // - The personal_stage_type_ids are different and have is_global = '[]'
            //
            // However, when syncing from Odoo:
            // - Empty project_ids might come as NULL, empty string, or the number 1
            // - Specific project_ids come as comma-separated string like "3,4,5"
            // - We already filtered out personal stages (is_global = '[]')
            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);
                var isGlobalValue = row.is_global;
                var isGlobalType = typeof isGlobalValue;
                
                // Skip the "Internal" stage - it should not be shown to users
                if (row.name === "Internal") {
                    console.log("  ⊗ Stage 'Internal' is HIDDEN (excluded by filter)");
                    continue;
                }
                
                // Convert to string for comparison
                var isGlobalStr = String(isGlobalValue);
                
                // Check if this stage is available for this project
                var isAvailable = false;
                
                // Check if it's a global stage (available to all projects)
                // Global stages have is_global = 1 (number) or "1" (string) or might be empty/NULL
                // Since we're checking stages that passed the SQL filter (is_global IS NOT NULL AND != "" AND != "[]")
                // If is_global = 1, it's definitely global
                if (isGlobalValue === 1 || isGlobalStr === "1") {
                    // Global stage - available to all projects
                    isAvailable = true;
                    console.log("  ✓ Stage '" + row.name + "' is GLOBAL (is_global: " + isGlobalValue + " [" + isGlobalType + "])");
                } else if (isGlobalStr.indexOf(",") !== -1) {
                    // Project-specific stage - check if this project is in the comma-separated list
                    var projectIds = isGlobalStr.split(",");
                    var projectIdStr = String(projectOdooRecordId);
                    
                    for (var j = 0; j < projectIds.length; j++) {
                        if (projectIds[j].trim() === projectIdStr) {
                            isAvailable = true;
                            break;
                        }
                    }
                    
                    if (isAvailable) {
                        console.log("  ✓ Stage '" + row.name + "' is available for project " + projectOdooRecordId + " (is_global: '" + isGlobalValue + "' contains project ID)");
                    } else {
                        console.log("  ✗ Stage '" + row.name + "' NOT available for project " + projectOdooRecordId + " (is_global: '" + isGlobalValue + "' does not contain project ID)");
                    }
                } else {
                    // Could be a single project ID (no comma) - check if it matches
                    if (isGlobalStr === String(projectOdooRecordId)) {
                        isAvailable = true;
                        console.log("  ✓ Stage '" + row.name + "' is available ONLY for project " + projectOdooRecordId + " (is_global: '" + isGlobalValue + "')");
                    } else {
                        // This stage is for a different single project
                        console.log("  ✗ Stage '" + row.name + "' is for a DIFFERENT project (is_global: '" + isGlobalValue + "', need: " + projectOdooRecordId + ")");
                    }
                }
                
                if (isAvailable) {
                    stages.push({
                        id: row.id,
                        odoo_record_id: row.odoo_record_id,
                        name: row.name,
                        sequence: row.sequence,
                        fold: row.fold,
                        description: row.description || "",
                        is_global: row.is_global
                    });
                }
            }
            
            console.log("🔍 getTaskStagesForProject: " + stages.length + " stages available for project " + projectOdooRecordId);
            
            if (stages.length === 0) {
                console.warn("⚠️ No stages available for project " + projectOdooRecordId + " in account " + accountId);
                console.warn("   This might indicate the project has no assigned stages in Odoo");
            }
        });
    } catch (e) {
        console.error("getTaskStagesForProject failed:", e);
    }
    
    return stages;
}

/**
 * Updates the stage of a task
 * @param {number} taskId - The local ID of the task
 * @param {number} stageOdooRecordId - The odoo_record_id of the new stage
 * @param {number} accountId - The account ID
 * @returns {Object} Success/error result
 */
function updateTaskStage(taskId, stageOdooRecordId, accountId) {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        var timestamp = Utils.getFormattedTimestampUTC();
        
        db.transaction(function (tx) {
            // Verify the task exists and belongs to the account
            var taskCheck = tx.executeSql(
                'SELECT id FROM project_task_app WHERE id = ? AND account_id = ?',
                [taskId, accountId]
            );
            
            if (taskCheck.rows.length === 0) {
                throw "Task not found or does not belong to this account";
            }
            
            // Verify the stage exists and belongs to the account
            var stageCheck = tx.executeSql(
                'SELECT id FROM project_task_type_app WHERE odoo_record_id = ? AND account_id = ?',
                [stageOdooRecordId, accountId]
            );
            
            if (stageCheck.rows.length === 0) {
                throw "Stage not found or does not belong to this account";
            }
            
            // Update the task's stage
            tx.executeSql(
                'UPDATE project_task_app SET state = ?, last_modified = ?, status = ? WHERE id = ?',
                [stageOdooRecordId, timestamp, "updated", taskId]
            );
        });
        
        return { success: true };
    } catch (e) {
        console.error("updateTaskStage failed:", e);
        return { success: false, error: e.message || e };
    }
}

/**
 * Gets personal stages for a specific user
 * Personal stages are identified by is_global = '[]' (empty array)
 * @param {number} userId - The odoo_record_id of the user from res_users_app
 * @param {number} accountId - The account ID
 * @returns {Array} Array of personal stage objects
 */
function getPersonalStagesForUser(userId, accountId) {
    var personalStages = [];
    
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        
        db.transaction(function (tx) {
            // Personal stages are identified by user_id = current user
            // NOT by is_global = '[]' (which includes shared stages like "Merge")
            var result = tx.executeSql(
                'SELECT odoo_record_id, name, sequence, fold, user_id ' +
                'FROM project_task_type_app ' +
                'WHERE account_id = ? AND user_id = ? ' +
                'ORDER BY sequence, name',
                [accountId, userId]
            );
            
            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);
                personalStages.push({
                    odoo_record_id: row.odoo_record_id,
                    name: row.name,
                    sequence: row.sequence,
                    fold: row.fold
                });
            }
        });
    } catch (e) {
        console.error("getPersonalStagesForUser failed:", e);
    }
    
    return personalStages;
}

/**
 * Updates the personal stage of a task
 * Personal stage is independent from regular stage
 * @param {number} taskId - The local ID of the task
 * @param {number} personalStageOdooRecordId - The odoo_record_id of the new personal stage (can be null to clear)
 * @param {number} accountId - The account ID
 * @returns {Object} Success/error result
 */
function updateTaskPersonalStage(taskId, personalStageOdooRecordId, accountId) {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        var timestamp = Utils.getFormattedTimestampUTC();
        
        db.transaction(function (tx) {
            // Verify the task exists and belongs to the account
            var taskCheck = tx.executeSql(
                'SELECT id FROM project_task_app WHERE id = ? AND account_id = ?',
                [taskId, accountId]
            );
            
            if (taskCheck.rows.length === 0) {
                throw "Task not found or does not belong to this account";
            }
            
            // If personalStageOdooRecordId is provided, verify it exists and is a personal stage
            if (personalStageOdooRecordId !== null && personalStageOdooRecordId !== undefined) {
                var stageCheck = tx.executeSql(
                    'SELECT odoo_record_id FROM project_task_type_app ' +
                    'WHERE odoo_record_id = ? AND account_id = ? AND is_global = ?',
                    [personalStageOdooRecordId, accountId, '[]']
                );
                
                if (stageCheck.rows.length === 0) {
                    throw "Personal stage not found or does not belong to this account";
                }
            }
            
            // Update the task's personal stage
            tx.executeSql(
                'UPDATE project_task_app SET personal_stage = ?, last_modified = ?, status = ? WHERE id = ?',
                [personalStageOdooRecordId, timestamp, "updated", taskId]
            );
        });
        
        return { success: true };
    } catch (e) {
        console.error("updateTaskPersonalStage failed:", e);
        return { success: false, error: e.message || e };
    }
}

/**
 * Gets tasks filtered by personal stage with hierarchy support
 * @param {number} personalStageOdooRecordId - The odoo_record_id of the personal stage (0 for "No Stage", null for "All")
 * @param {Array<number>} assigneeIds - Array of user IDs to filter by assignees
 * @param {number} accountId - The account ID (or -1 for all accounts)
 * @param {boolean} includeFoldedTasks - If false (default), exclude tasks with folded stages (fold=1)
 * @returns {Array} List of tasks matching the personal stage and assignee filter
 */
function getTasksByPersonalStage(personalStageOdooRecordId, assigneeIds, accountId, includeFoldedTasks) {
    // Default to hiding folded tasks
    if (includeFoldedTasks === undefined) {
        includeFoldedTasks = false;
    }
    
    var allTasks;
    
    // Get base tasks
    if (accountId !== undefined && accountId >= 0) {
        allTasks = getTasksForAccount(accountId);
    } else {
        allTasks = getAllTasks();
    }
    
    var filteredTasks = [];
    var includedTaskIds = new Map();
    
    // First pass: identify tasks that match BOTH the personal stage AND assignee criteria
    var matchCount = 0;
    for (var i = 0; i < allTasks.length; i++) {
        var task = allTasks[i];
        var matchesStage = false;
        var matchesAssignee = false;
        
        // Check personal stage match
        if (personalStageOdooRecordId === null) {
            // "All" - show all tasks
            matchesStage = true;
        } else if (personalStageOdooRecordId === 0) {
            // "No Stage" - show tasks without personal stage
            matchesStage = !task.personal_stage || task.personal_stage === 0;
        } else {
            // Specific stage - show tasks with matching personal stage
            // Convert both to integers for comparison to handle type mismatches
            var taskStage = parseInt(task.personal_stage);
            var filterStage = parseInt(personalStageOdooRecordId);
            matchesStage = (taskStage === filterStage);
        }
        
        // Check assignee match
        if (assigneeIds && assigneeIds.length > 0) {
            if (task.user_id) {
                var taskAssigneeIds = parseAssigneeIds(task.user_id);
                for (var j = 0; j < assigneeIds.length; j++) {
                    if (taskAssigneeIds.indexOf(assigneeIds[j]) !== -1) {
                        matchesAssignee = true;
                        break;
                    }
                }
            }
        } else {
            // No assignee filter specified, include all
            matchesAssignee = true;
        }
        
        // Task must match BOTH criteria (or have no assignee filter)
        if (matchesStage && matchesAssignee) {
            // Filter out folded tasks unless includeFoldedTasks is true
            if (!includeFoldedTasks && task.state && isTaskStageFolded(task.state)) {
                // Skip this task - it's in a folded stage and we don't want to show it
                continue;
            }
            
            var compositeKey = task.odoo_record_id + '_' + task.account_id;
            includedTaskIds.set(compositeKey, task);
            matchCount++;
        }
    }
    
    // Second pass: include parent tasks if they have children that match
    for (var i = 0; i < allTasks.length; i++) {
        var task = allTasks[i];
        
        var hasIncludedChildren = false;
        for (var j = 0; j < allTasks.length; j++) {
            var potentialChild = allTasks[j];
            var childKey = potentialChild.odoo_record_id + '_' + potentialChild.account_id;
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
    
    // Third pass: include parent chain for included tasks
    var toProcess = Array.from(includedTaskIds.values());
    for (var i = 0; i < toProcess.length; i++) {
        var task = toProcess[i];
        
        if (task && task.parent_id && task.parent_id > 0) {
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
    
    // Build the filtered tasks list
    for (var i = 0; i < allTasks.length; i++) {
        var task = allTasks[i];
        var taskKey = task.odoo_record_id + '_' + task.account_id;
        if (includedTaskIds.has(taskKey)) {
            filteredTasks.push(task);
        }
    }
    
    return filteredTasks;
}
