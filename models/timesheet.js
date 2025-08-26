.import QtQuick.LocalStorage 2.7 as Sql
.import "database.js" as DBCommon
.import "utils.js" as Utils


/**
 * Retrieves all non-deleted timesheet entries from the local SQLite database.
 *
 * Joins related data from `project_project_app`, `users`, `res_users_app`, and `project_task_app`
 * to enrich the timesheet list with human-readable project, task, instance, and user names.
 *
 * @returns {Array<Object>} - A list of enriched timesheet entries.
 */
function fetchTimesheetsByStatus(status) {
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var timesheetList = [];

    try {
        db.transaction(function (tx) {
            // Build map of odoo_record_id -> color_pallet
            var projectColorMap = {};
            var projectResult = tx.executeSql("SELECT odoo_record_id, color_pallet FROM project_project_app");
            for (var j = 0; j < projectResult.rows.length; j++) {
                var projectRow = projectResult.rows.item(j);
                projectColorMap[projectRow.odoo_record_id] = projectRow.color_pallet;
            }

            var query = "";
            var params = [];

            if (!status || status.toLowerCase() === "all") {
                query = "SELECT * FROM account_analytic_line_app WHERE (status IS NULL OR status != 'deleted') ORDER BY last_modified DESC";
            } else {
                query = "SELECT * FROM account_analytic_line_app WHERE status = ? ORDER BY last_modified DESC";
                params = [status];
            }

            var result = tx.executeSql(query, params);

            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);

                var quadrantMap = {
                    0: "Unknown",
                    1: "Do",
                    2: "Plan",
                    3: "Delegate",
                    4: "Delete"
                };

                // Resolve project name and parent name
                var projectName = "Unknown Project";
                var inheritedColor = 0;

                if (row.project_id) {
                    var rs_project = tx.executeSql(
                        "SELECT name, parent_id FROM project_project_app WHERE odoo_record_id = ? LIMIT 1",
                        [row.project_id]
                    );

                    if (rs_project.rows.length > 0) {
                        var project_row = rs_project.rows.item(0);
                        if (project_row.parent_id && project_row.parent_id > 0) {
                            // Subproject case
                            var rs_parent = tx.executeSql(
                                "SELECT name FROM project_project_app WHERE odoo_record_id = ? LIMIT 1",
                                [project_row.parent_id]
                            );
                            if (rs_parent.rows.length > 0) {
                                projectName = rs_parent.rows.item(0).name + " / " + project_row.name;
                            } else {
                                projectName = project_row.name;
                            }

                            // Inherit color from subproject
                            inheritedColor = projectColorMap[row.project_id] || projectColorMap[project_row.parent_id] || 0;
                        } else {
                            projectName = project_row.name;
                            inheritedColor = projectColorMap[row.project_id] || 0;
                        }
                    }
                }

                // Resolve task name
                var taskName = "Unknown Task";
                if (row.task_id) {
                    var rs_task = tx.executeSql(
                        "SELECT name FROM project_task_app WHERE odoo_record_id = ? LIMIT 1",
                        [row.task_id]
                    );
                    if (rs_task.rows.length > 0) {
                        taskName = rs_task.rows.item(0).name;
                    }
                }

                // Resolve instance and user names
                var instanceName = "", userName = "";
                if (row.account_id) {
                    var rs_instance = tx.executeSql("SELECT name FROM users WHERE id = ? LIMIT 1", [row.account_id]);
                    if (rs_instance.rows.length > 0) instanceName = rs_instance.rows.item(0).name;
                }

                if (row.user_id) {
                    var rs_user = tx.executeSql("SELECT name FROM res_users_app WHERE odoo_record_id = ? LIMIT 1", [row.user_id]);
                    if (rs_user.rows.length > 0) userName = rs_user.rows.item(0).name;
                }

                timesheetList.push({
                    id: row.id,
                    instance: instanceName,
                    name: row.name || '',
                    spentHours: Utils.convertDecimalHoursToHHMM(row.unit_amount),
                    project: projectName,
                    quadrant: quadrantMap[row.quadrant_id] || "Unknown",
                    date: row.record_date,
                    status: row.status,
                    task: taskName,
                    user: userName,
                    timer_type: row.timer_type || 'manual',
                    color_pallet: parseInt(inheritedColor) || 0
                });
            }
        });
    } catch (e) {
        DBCommon.logException("fetchTimesheetsByStatus", e);
    }

    return timesheetList;
}


function getAttachmentsForTimesheet(odooRecordId) {
    var attachmentList = [];

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var query = `
                SELECT name, mimetype, datas
                FROM ir_attachment_app
                WHERE res_model = 'hr_timesheet.sheet' AND res_id = ?
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


function getTimesheetNameById(timesheetId) {
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var name = "";
    try {
        db.transaction(function (tx) {
            var rs = tx.executeSql("SELECT name FROM account_analytic_line_app WHERE id = ?", [timesheetId]);
            if (rs.rows.length > 0) {
                name = rs.rows.item(0).name;
            }
        });
    } catch (e) {
        DBCommon.logException("getTimesheetNameById", e);
    }
    return name;
}

/**
 * Checks if a timesheet is ready to be synced to Odoo.
 * Both project (or sub-project) and task (or sub-task) must be assigned to prevent sync errors.
 *
 * @param {number} timesheetId - The ID of the timesheet to check
 * @returns {boolean} - True if the timesheet has both project and task assigned, false otherwise
 */
function isTimesheetReadyToRecord(timesheetId) {
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var ready = false;

    try {
        db.transaction(function(tx) {
            var rs = tx.executeSql(
                "SELECT project_id, sub_project_id, task_id, sub_task_id FROM account_analytic_line_app WHERE id = ? LIMIT 1",
                [timesheetId]
            );

            if (rs.rows.length > 0) {
                var row = rs.rows.item(0);
              //  console.log("Project id " +row.project_id)
              //  console.log("SubProject id " + row.sub_project_id)
              //  console.log("Task id " +row.task_id  )
              //  console.log("SubTask id " +row.sub_task_id)

                var hasProjectOrSubproject = (row.project_id && row.project_id > 0) ||
                                             (row.sub_project_id && row.sub_project_id > 0);

                var hasTaskOrSubtask = (row.task_id && row.task_id > 0) ||
                                       (row.sub_task_id && row.sub_task_id > 0);

                // Both project and task are mandatory for sync to prevent sync errors
                ready = hasProjectOrSubproject && hasTaskOrSubtask;
            } else {
                console.log("Timesheet ID " + timesheetId + " not found in DB.");
            }
        });
    } catch (e) {
        console.log("isTimesheetReadyToRecord failed:", e);
    }

    return ready;
}

/**
 * Checks if a timesheet is ready to start timer tracking.
 * Only requires a project (or sub-project) to be assigned, allowing draft timesheets to be tracked.
 *
 * @param {number} timesheetId - The ID of the timesheet to check
 * @returns {boolean} - True if the timesheet has a project assigned, false otherwise
 */
function isTimesheetReadyToStartTimer(timesheetId) {
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var ready = false;

    try {
        db.transaction(function(tx) {
            var rs = tx.executeSql(
                "SELECT project_id, sub_project_id FROM account_analytic_line_app WHERE id = ? LIMIT 1",
                [timesheetId]
            );

            if (rs.rows.length > 0) {
                var row = rs.rows.item(0);
                
                var hasProjectOrSubproject = (row.project_id && row.project_id > 0) ||
                                             (row.sub_project_id && row.sub_project_id > 0);

                // Only project is required for timer start - task can be selected later
                ready = hasProjectOrSubproject;
            } else {
                console.log("Timesheet ID " + timesheetId + " not found in DB.");
            }
        });
    } catch (e) {
        console.log("isTimesheetReadyToStartTimer failed:", e);
    }

    return ready;
}


/**
 * Marks a timesheet entry as deleted in the local SQLite database by setting its `status` to `'deleted'`.
 *
 * This is a soft delete and does not remove the record from the database.
 *
 * @param {number} taskId - The ID of the timesheet entry to be marked as deleted.
 * @returns {Object} - An object with `success` (boolean) and `message` (string) indicating the result.
 */
function markTimesheetAsDeleted(taskId) {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            tx.executeSql(
                        "UPDATE account_analytic_line_app SET status = 'deleted' WHERE id = ?",
                        [taskId]
                        );
        });

        DBCommon.log("Timesheet marked as deleted (id: " + taskId + ")");
        return { success: true, message: "Timesheet marked as deleted." };

    } catch (e) {
        DBCommon.logException("markTimesheetAsDeleted", e);
        return { success: false, message: "Failed to mark as deleted: " + e.message };
    }
}

/**
 * Retrieves details of a specific timesheet entry by its local database ID.
 *
 * The returned object includes project/task associations, recorded hours,
 * quadrant classification, and a formatted record date.
 *
 * @param {number} record_id - The local database ID of the timesheet entry.
 * @returns {Object} - A timesheet detail object, or an empty object if not found.
 */
function getTimeSheetDetails(record_id) {
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var timesheet_detail = {};
    db.transaction(function (tx) {
        var timesheet = tx.executeSql('SELECT * FROM account_analytic_line_app\
                                    WHERE id = ?', [record_id]);
        if (timesheet.rows.length) {
            timesheet_detail = {
                'instance_id': timesheet.rows.item(0).account_id,
                'project_id': timesheet.rows.item(0).project_id,
                'sub_project_id': timesheet.rows.item(0).sub_project_id,
                'task_id': timesheet.rows.item(0).task_id,
                'sub_task_id': timesheet.rows.item(0).sub_task_id,
                'name': timesheet.rows.item(0).name,
                'spentHours': Utils.convertDecimalHoursToHHMM(timesheet.rows.item(0).unit_amount),
                'quadrant_id': timesheet.rows.item(0).quadrant_id,
                'record_date': Utils.formatDate(new Date(timesheet.rows.item(0).record_date)),
                'timer_type': timesheet.rows.item(0).timer_type || 'manual'
            };
        }
    });
    return timesheet_detail;
}

/**
 * Creates a new timesheet entry or updates an existing one in the local SQLite database.
 *
 * The function decides whether to insert or update based on the presence of a valid `id` in `data`.
 * Duration is parsed based on whether the entry is manually recorded or tracked automatically.
 *
 * @param {Object} data - An object representing the timesheet fields:
 *                        - `id`, `instance_id`, `record_date`, `project`, `task`, `description`,
 *                        - `subprojectId`, `subTask`, `quadrant`, `spenthours`, `manualSpentHours`,
 *                        - `isManualTimeRecord`, `status`, `user_id`
 * @returns {Object} - An object containing `success` (boolean) and `error` (string, if any).
 */
function saveTimesheet(data) {
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var timestamp = Utils.getFormattedTimestampUTC();
    var result = { success: false, error: "", id: null };

    // Validation: Ensure ID is provided
    if (!data.id || data.id <= 0) {
        result.error = "Invalid timesheet ID for update.";
        return result;
    }

    try {
        db.transaction(function (tx) {
            tx.executeSql(`UPDATE account_analytic_line_app SET
                          account_id = ?,
                          record_date = ?,
                          project_id = ?,
                          task_id = ?,
                          name = ?,
                          sub_project_id = ?,
                          sub_task_id = ?,
                          quadrant_id = ?,
                          unit_amount = ?,
                          last_modified = ?,
                          status = ?,
                          timer_type = ?,
                          user_id = ?
                          WHERE id = ?`,
                          [
                              data.instance_id || null,
                              data.record_date || Utils.getToday(),
                              data.project || null,
                              data.task || null,
                              data.description || "",
                              data.subprojectId || null,
                              data.subTask || null,
                              data.quadrant || null,
                              data.unit_amount || 0,
                              timestamp,
                              data.status || "draft",
                              data.timer_type || "manual",
                              data.user_id || null,
                              data.id
                          ]);

            result.success = true;
            result.id = data.id;
        });
    } catch (err) {
        result.error = err.message;
    }

    return result;
}

function createTimesheet(instance_id,userid) {
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var timestamp = Utils.getFormattedTimestampUTC();
    var result = { success: false, error: "", id: null };

    try {
        db.transaction(function (tx) {
            tx.executeSql(`INSERT INTO account_analytic_line_app
                          (account_id, record_date, project_id, task_id, name, sub_project_id,
                          sub_task_id, quadrant_id, unit_amount, last_modified, status, timer_type, user_id)
                          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
                          [
                              instance_id,               // account_id
                              Utils.getToday(),      // record_date, fallback to today
                              null,                      // project_id
                              null,                      // task_id
                              "",                        // name/description
                              null,                      // sub_project_id
                              null,                      // sub_task_id
                              0,                      // quadrant_id
                              0,                         // unit_amount
                              timestamp,                 // last_modified
                              "draft",                   // status
                              "manual",                  // timer_type - default to manual
                              userid                       // user_id
                          ]);

            // Retrieve the last inserted ID
            var rs = tx.executeSql("SELECT last_insert_rowid() as id");
            if (rs.rows.length > 0) {
                result.id = rs.rows.item(0).id;
                result.success = true;
            } else {
                result.error = "Unable to retrieve the inserted record ID.";
            }
        });
    } catch (err) {
        console.log(err.message)
        result.error = err.message;
    }

    return result;
}


/**
 * Creates a new timesheet entry from a given task by directly querying the local SQLite task table,
 * then inserting using createOrSaveTimesheet.
 *
 * @param {number} taskRecordId - The ID of the task to link to the new timesheet.
 * @returns {Object} - { success: boolean, id: number | null, error: string }
 */function createTimesheetFromTask(taskRecordId) {
     console.log("Creating time sheet for " + taskRecordId);
     var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
     var result = { success: false, id: null, error: "" };

     try {
         if (!taskRecordId || taskRecordId <= 0) {
             result.error = "Invalid taskRecordId provided.";
             return result;
         }

         var task = null;
         db.readTransaction(function(tx) {
             var rs = tx.executeSql("SELECT * FROM project_task_app WHERE odoo_record_id = ?", [taskRecordId]);
             if (rs.rows.length > 0) {
                 task = rs.rows.item(0);
             }
         });

         if (!task) {
             result.error = "Task not found in local DB." +taskRecordId;
             return result;
         }

         if (!task.project_id || !task.account_id) {
             result.error = "Task missing required project/account linkage.";
             return result;
         }

         // Use createTimesheet(instance_id, user_id) to create the empty record
         var tsResult = createTimesheet(task.account_id, task.user_id);

         if (!tsResult.success) {
             result.error = tsResult.error || "Failed to create base timesheet record.";
             return result;
         }

         var timesheetId = tsResult.id;

         // Now update the created empty timesheet with project, task, description, etc.
         var today = Utils.getToday(); // ensure "yyyy-MM-dd"

         var timesheet_data = {
             id: timesheetId,
             instance_id: task.account_id,
             record_date: today,
             project: task.project_id,
             task: task.odoo_record_id || null,
             subprojectId: task.sub_project_id || null,
             subTask: null,
             description: "Timesheet (" + today + ") " + (task.name || ""),
             unit_amount: 0,
             timer_type: "manual", // Default to manual when created from task
             status: "draft",
             user_id: task.user_id
         };

         console.log("Updating created timesheet ID " + timesheetId + " with task data.");

         var updateResult = saveTimesheet(timesheet_data);

         if (updateResult.success) {
             result.success = true;
             result.id = timesheetId;
         } else {
             result.error = updateResult.error || "Failed to update timesheet with task data.";
         }

     } catch (e) {
         result.error = e.toString();
     }

     return result;
 }


function createTimesheetFromProject(projectRecordId) {
    console.log("Creating timesheet for project " + projectRecordId);
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var result = { success: false, id: null, error: "" };
    
    try {
        var project = null;
        db.readTransaction(function(tx) {
            var rs = tx.executeSql("SELECT * FROM project_project_app WHERE odoo_record_id = ?", [projectRecordId]);
            if (rs.rows.length > 0) {
                project = rs.rows.item(0);
                console.log("Project data:", JSON.stringify(project));
                console.log("Account ID:", project.account_id);
                console.log("User ID:", project.user_id);
            }
        });

        if (!project) {
            result.error = "Project not found in local DB: " + projectRecordId;
            return result;
        }

        if (!project.account_id || project.account_id <= 0) {
            result.error = "Project missing required account_id. Current value: " + project.account_id;
            return result;
        }

        // **Handle missing user_id by using a default or current user**
        var userId = project.user_id;
        if (!userId || userId === undefined || userId === null) {
            // Option 1: Use a default user ID or get current logged-in user
            // You'll need to implement getCurrentUserId() or use a default
            userId = 1; // Fallback to user ID 1
            console.log("Project missing user_id, using fallback:", userId);
        }

        // Create empty timesheet
        var tsResult = createTimesheet(project.account_id, userId);
        if (!tsResult.success) {
            result.error = tsResult.error || "Failed to create base timesheet record.";
            return result;
        }

        var timesheetId = tsResult.id;
        var today = Utils.getToday();
        
        // Update timesheet with project data
        var timesheet_data = {
            id: timesheetId,
            instance_id: project.account_id,
            record_date: today,
            project: project.odoo_record_id,
            task: null, // No specific task for project-level timesheet
            subprojectId: null,
            subTask: null,
            description: "Project Timesheet (" + today + ") " + (project.name || ""),
            unit_amount: 0,
            timer_type: "manual", // Default to manual when created from project
            status: "draft",
            user_id: userId // Use the resolved user ID
        };

        var updateResult = saveTimesheet(timesheet_data);
        if (updateResult.success) {
            result.success = true;
            result.id = timesheetId;
        } else {
            result.error = updateResult.error || "Failed to update timesheet with project data.";
        }

    } catch (e) {
        result.error = e.toString();
    }

    return result;
}


function doesProjectIdMatchSheetInActive(projectId, sheetId) {
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var matches = false;
    
    try {
        db.transaction(function(tx) {
            var rs = tx.executeSql(
                "SELECT id FROM account_analytic_line_app WHERE id = ? AND status = ? AND project_id = ? LIMIT 1",
                [sheetId, "active", projectId]
            );
            if (rs.rows.length > 0) {
                matches = true;
            }
        });
    } catch (e) {
        console.log("doesProjectIdMatchSheetInActive failed:", e);
    }
    
    return matches;
}

function doesTaskIdMatchSheetInActive(taskId, sheetId) {
    //console.log("Checking if sheet ID " + sheetId + " has task ID " + taskId + " in DRAFT status...");

    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var matches = false;

    try {
        db.transaction(function(tx) {
            var rs = tx.executeSql(
                "SELECT id FROM account_analytic_line_app WHERE id = ? AND status = ? AND (task_id = ? OR sub_task_id = ?) LIMIT 1",
                [sheetId, "active", taskId, taskId]
            );

            if (rs.rows.length > 0) {
                console.log("Sheet ID " + sheetId + " with task ID " + taskId + " found in DRAFT timesheets.");
                matches = true;
            }
        });
    } catch (e) {
        console.log("doesTaskIdMatchSheetInDraft failed:", e);
    }

    return matches;
}


function updateTimesheetWithDuration(timesheetId, durationHours) {
    console.log("Updating timesheet " + timesheetId + " with hours " + durationHours);

    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var timestamp = Utils.getFormattedTimestampUTC();
    var time_taken=Utils.convertHHMMtoDecimalHours(durationHours)
    console.log("Updating duration : "+time_taken)

    try {
        db.transaction(function(tx) {
            tx.executeSql(
                        "UPDATE account_analytic_line_app SET unit_amount = ?, last_modified = ?, status = ? WHERE id = ?",
                        [time_taken, timestamp, "active", timesheetId]
                        );
        });
    } catch (e) {
        console.log("updateTimesheetWithDuration failed:", e);
    }
}

function markTimesheetAsActiveById(timesheetId) {
    console.log("Marking timesheet " + timesheetId + " as active");

    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var timestamp = Utils.getFormattedTimestampUTC();

    try {
        db.transaction(function(tx) {
            tx.executeSql(
                        "UPDATE account_analytic_line_app SET last_modified = ?, status = ? WHERE id = ?",
                        [timestamp, "active", timesheetId]
                        );
        });
        console.log("Timesheet " + timesheetId + " marked as draft successfully.");
    } catch (e) {
        console.log("markTimesheetAsDraftById failed:", e);
    }
}

/**
 * Marks a timesheet as ready to be synced to Odoo by setting its status to "updated".
 * The timesheet must have required project/task information to be marked as ready.
 *
 * @param {number} timesheetId - The ID of the timesheet to be marked as ready for sync
 * @returns {Object} - An object with `success` (boolean) and `error` (string) indicating the result
 */
function markTimesheetAsReadyById(timesheetId) {
    var result = { success: false, error: "", id: null };
    
    if(!isTimesheetReadyToRecord(timesheetId)) {
        result.success = false;
        result.error = "Timesheet not ready - both project and task must be selected";
        return result;
    }
 
    console.log("Marking timesheet " + timesheetId + " as updated for sync");
 
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var timestamp = Utils.getFormattedTimestampUTC();
 
    try {
        db.transaction(function(tx) {
            
            tx.executeSql(
                "UPDATE account_analytic_line_app SET last_modified = ?, status = ? WHERE id = ?",
                [timestamp, "updated", timesheetId]  
            );
        });
        console.log("Timesheet " + timesheetId + " marked as updated successfully.");
        result.success = true;
    } catch (e) {
        console.log("markTimesheetAsReadyById failed:", e);
        result.success = false;
        result.error = e.message;
    }
    return result;
}
 
/**
 * Marks a timesheet as draft by setting its status to "draft".
 * This is typically used when stopping a timer to reset the timesheet status.
 *
 * @param {number} timesheetId - The ID of the timesheet to be marked as draft
 * @returns {Object} - An object with `success` (boolean) and `error` (string) indicating the result
 */
function markTimesheetAsDraftById(timesheetId) {
    var result = { success: false, error: "", id: null };
    
    console.log("Marking timesheet " + timesheetId + " as draft");
 
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var timestamp = Utils.getFormattedTimestampUTC();
 
    try {
        db.transaction(function(tx) {
            tx.executeSql(
                "UPDATE account_analytic_line_app SET last_modified = ?, status = ? WHERE id = ?",
                [timestamp, "draft", timesheetId]  
            );
        });
        console.log("Timesheet " + timesheetId + " marked as draft successfully.");
        result.success = true;
    } catch (e) {
        console.log("markTimesheetAsDraftById failed:", e);
        result.success = false;
        result.error = e.message;
    }
    return result;
}

function getTimesheetUnitAmount(timesheetId) {
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var unitAmount = 0;
    try {
        db.transaction(function(tx) {
            var rs = tx.executeSql("SELECT unit_amount FROM account_analytic_line_app WHERE id = ?", [timesheetId]);
            if (rs.rows.length > 0 && rs.rows.item(0).unit_amount !== null) {
                unitAmount = parseFloat(rs.rows.item(0).unit_amount);
            }
        });
    } catch (e) {
        DBCommon.logException("getTimesheetUnitAmount", e);
    }
    return unitAmount;
}
