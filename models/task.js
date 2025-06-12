.import QtQuick.LocalStorage 2.7 as Sql
.import "database.js" as DBCommon
.import "utils.js" as Utils


function saveOrUpdateTask(data) {
    try {
        var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
        var timestamp = Utils.getFormattedTimestamp();
        db.transaction(function(tx) {
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


// Helper to handle -1/null
function validId(value) {
    return (value !== undefined && value > 0) ? value : null;
}

/**
 * Fetches tasks for a given account and optionally filtered by project.
 *
 * If `projectId` is 0, it fetches all tasks for the account. Otherwise, it fetches
 * tasks belonging to both the account and the specified project.
 *
 * @param {number} accountId - The ID of the account.
 * @param {number} projectId - The ID of the project to filter by (0 to ignore).
 * @returns {Array<Object>} An array of task objects from the local DB.
 */
function getTasksForAccountAndProject(accountId, projectId) {
    log('getTasksForAccountAndProject', '[${tag}] Fetching tasks for accountId: ${accountId}, projectId: ${projectId}');

    var tasks = [];

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var result;

            if (projectId === 0) {
                result = tx.executeSql(
                    "SELECT * FROM project_task_app WHERE account_id = ? ORDER BY last_modified DESC",
                    [accountId]
                );
            } else {
                result = tx.executeSql(
                    "SELECT * FROM project_task_app WHERE account_id = ? AND project_id = ? ORDER BY last_modified DESC",
                    [accountId, projectId]
                );
            }

            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);
                tasks.push({
                    id: row.id,
                    remote_id: row.odoo_record_id,
                    name: row.name,
                    allocated_hours: row.initial_planned_hours,
                    state: row.state,
                    project_id: row.project_id,
                    parent_id: row.parent_id,
                    favorites: row.favorites
                });
            }
        });

    } catch (e) {
        logException(e);
    }

    return tasks;
}

function markTaskAsDeleted(taskId) {
    try {
        var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
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

function togglePriority(taskId, currentState) {
    try {
        var newState = currentState > 0 ? 0 : 1;
        var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
        db.transaction(function(tx) {
            tx.executeSql("UPDATE project_task_app SET favorites = ?, last_modified = ? WHERE id = ?", [newState, new Date().toISOString(), taskId]);
        });
        console.log("togglePriority: Updated favorites for taskId " + taskId + " to " + newState);
    } catch (e) {
        console.error("togglePriority: Failed to update favorites for taskId " + taskId + " - " + e);
    }
}

function deletetaskData(taskId) {
    try {
        var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
        db.transaction(function(tx) {
            tx.executeSql("DELETE FROM project_task_app WHERE id = ?", [taskId]);
        });
        console.log("deletetaskData: Deleted task with id " + taskId);
    } catch (e) {
        console.error("deletetaskData: Failed to delete task with id " + taskId + " - " + e);
    }
}


function edittaskData(data){
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);

    db.transaction(function(tx) {
        tx.executeSql('UPDATE project_task_app SET \
            account_id = ?, name = ?, project_id = ?, parent_id = ?, initial_planned_hours = ?, favorites = ?, description = ?, user_id = ?, sub_project_id = ?, \
            start_date = ?, end_date = ?, deadline = ?, last_modified = ? WHERE id = ?',
                      [data.selectedAccountUserId, data.nameInput, data.selectedProjectId,data.selectedparentId, data.initialInput,data.img_star,data.editdescription, data.selectedassigneesUserId, data.editselectedSubProjectId,
                       data.startdateInput, data.enddateInput,data.deadlineInput, new Date().toISOString(), data.rowId]
                      );
        fetch_tasks_lists()
    });
}

function fetch_tasks_lists(recordid) {
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    var workpersonaSwitchState = true;
    var filtertasklistData = []
    var tasklist = []
    db.transaction(function(tx) {
        if (!recordid){
            console.log("Gets all records!");
            if(workpersonaSwitchState){
                var result = tx.executeSql('SELECT * FROM project_task_app where account_id != 0 order by last_modified desc');
            }else{
                var result = tx.executeSql('SELECT * FROM project_task_app where account_id = 0');
            }
        }
        else{
            console.log("Gets one record!");
            var result = tx.executeSql('SELECT * FROM project_task_app where id = ? order by last_modified desc', [recordid]);
        }
        for (var i = 0; i < result.rows.length; i++) {
            var parent_task = tx.executeSql('SELECT name FROM project_task_app WHERE id = ?',[result.rows.item(i).parent_id]);
            var parentTask = parent_task.rows.length > 0 ? parent_task.rows.item(0).name || "" : "";

            var accunt_id = tx.executeSql('SELECT name FROM users WHERE id = ?',[result.rows.item(i).account_id]);
            var accountName = accunt_id.rows.length > 0 ? accunt_id.rows.item(0).name || "" : "";

            var project_name = tx.executeSql('SELECT name FROM project_project_app WHERE id = ?', [result.rows.item(i).project_id]);
            var project = project_name.rows.length > 0 ? project_name.rows.item(0).name || "" : "";
            

            var id = result.rows.item(i).id
            var spentHoursQuery = tx.executeSql('SELECT unit_amount FROM account_analytic_line_app WHERE task_id = ?', [id]);

            var color_pallet = ''
            if (result.rows.item(i).sub_project_id != 0) {
                var project_color = tx.executeSql('select color_pallet from project_project_app where id = ?', [result.rows.item(i).sub_project_id])
                if (project_color.rows.length) {
                    color_pallet = project_color.rows.item(0).color_pallet;
                }
            } else {
                var project_color = tx.executeSql('select color_pallet from project_project_app where id = ?', [result.rows.item(i).project_id])
                if (project_color.rows.length) {
                    color_pallet = project_color.rows.item(0).color_pallet;
                }
            }

            var totalMinutes = 0;
            for (var j = 0; j < spentHoursQuery.rows.length; j++) {
                /*                var timeString = spentHoursQuery.rows.item(j).unit_amount || "00:00";
                var parts = timeString.split(":");
                var hours = parseInt(parts[0], 10) || 0;
                var minutes = parseInt(parts[1], 10) || 0;
*/
                totalMinutes += spentHoursQuery.rows.item(j).unit_amount;
            }
            var timesheetCount = spentHoursQuery.rows.length;

            var totalHours = Math.floor(totalMinutes / 60);
            var remainingMinutes =  Math.floor(totalMinutes) % 60;
            var spentHours =  totalHours + ":" + (remainingMinutes < 10 ? "0" : "") + remainingMinutes;

            tasklist.push({'id': result.rows.item(i).id, 'color_pallet': color_pallet,
                              'name': result.rows.item(i).name, 'allocated_hours': result.rows.item(i).initial_planned_hours,
                              'state': result.rows.item(i).state, 'parentTask': parentTask, 'accountName':accountName,
                              'favorites':result.rows.item(i).favorites,'spentHours':spentHours, 'timerRunning': false,
                              'account_id': result.rows.item(i).account_id, 'parent_id': result.rows.item(i).parent_id,
                              'description': result.rows.item(i).description, 'start_date':result.rows.item(i).start_date,
                              'end_date':result.rows.item(i).end_date, 'deadline':result.rows.item(i).deadline,'number_of_timesheets': timesheetCount,
                              'user_id': result.rows.item(i).user_id, 'project_id': result.rows.item(i).project_id, 'project': project});


            filtertasklistData.push({'id': result.rows.item(i).id, 'name': result.rows.item(i).name,
                                        'allocated_hours': result.rows.item(i).initial_planned_hours, 'state': result.rows.item(i).state,
                                        'parentTask': parentTask, 'accountName':accountName,'favorites':result.rows.item(i).favorites,
                                        'spentHours':spentHours, 'timerRunning': false});
        }
    });
    return tasklist
}

function fetch_task_details(taskrec){
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    var workpersonaSwitchState = true;
    var taskdata = []
    console.log("In fetch_task_details: " + taskrec[0].id + " " + taskrec[0].project_id + " " + taskrec[0].parent_id);
    db.transaction(function(tx) {
        var project = tx.executeSql('SELECT name FROM project_project_app WHERE id = ?', taskrec[0].project_id);
        var parentname = tx.executeSql('SELECT name FROM project_task_app WHERE id = ?', taskrec[0].parent_id);
        if(parentname.rows.item(0) === undefined)
            console.log("Parentname is undefined")
        if(workpersonaSwitchState){
            var account = tx.executeSql('SELECT name FROM users WHERE id = ?', taskrec[0].account_id);
            var user = tx.executeSql('SELECT name FROM res_users_app WHERE id = ?', taskrec[0].user_id);
        }
        //        console.log("get_task_details: project: " + project.rows.item(0).name)
        //        console.log("get_task_details: parentname: " + user.rows.item(0).name)
        //        console.log("get_task_details: user: " + user.rows.item(0).name)
        //        taskdata.push({'project': project.rows.item(0).name, 'parentname': parentname.rows.item(0).name, 'user': user.rows.item(0).name})
        

        if (parentname.rows.item(0) != undefined)
        {
            console.log("Parentname is not null")
            var parent_name = parentname.rows.item(0).name
        }
        else{
            var parent_name = ""

        }
        if (user.rows.item(0) != undefined)
        {
            var user_name = user.rows.item(0).name
        }
        else{
            var user_name = ""
        }
        taskdata.push({'project': project.rows.item(0).name, 'user': user_name, 'parentname': parent_name})
        console.log("get_task_details: user: " + taskdata[0].user + " Project: " + taskdata[0].project)
    })
    return taskdata
}


function filterTaskList(query) {
    tasksListModel.clear();

    for (var i = 0; i < filtertasklistData.length; i++) {
        var entry = filtertasklistData[i];
        
        if (entry.name.toLowerCase().includes(query.toLowerCase()) ||
                entry.parentTask.toLowerCase().includes(query.toLowerCase()) ||
                entry.state.toLowerCase().includes(query.toLowerCase()) ||
                entry.accountName.toLowerCase().includes(query.toLowerCase()) ||
                (entry.spentHours.toString().includes(query)) ||
                (entry.allocated_hours.toString().includes(query))
                ) {
            tasksListModel.append(entry);
        }
    }
}

function fetch_current_users_task(selectedAccountUserId) {
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    var activity_type_list = []
    db.transaction(function (tx) {
        var instance_users = tx.executeSql('select * from res_users_app where account_id = ? AND share = ? AND active = ?', [selectedAccountUserId, 0, 1])
        var all_users = tx.executeSql('select * from res_users_app')
        for (var user = 0; user < all_users.rows.length; user++) {
        } //GM: What is this for?
        for (var instance_user = 0; instance_user < instance_users.rows.length; instance_user++) {
            activity_type_list.push({'id': instance_users.rows.item(instance_user).id, 'name': instance_users.rows.item(instance_user).name});
        }
    })
    return activity_type_list;
}

function getAssigneeList(){
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    var assigneelist = [];

    db.transaction(function(tx) {
        var result1 = tx.executeSql('SELECT * FROM res_users_app');
        for (var i = 0; i < result1.rows.length; i++) {
            //                console.log("getAssigneeList: " + result1.rows.item(i).name)
            assigneelist.push({'id': result1.rows.item(i).id, 'name': result1.rows.item(i).name})
        }
    })
    return assigneelist

}

function get_filtered_tasklist(filtertext){
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    var workpersonaSwitchState = true;
    var filteredtasks = [];
    var searchstr = "%" + filtertext + "%"
    db.transaction(function(tx) {
        if(workpersonaSwitchState){
            var result = tx.executeSql('SELECT * FROM project_task_app where account_id != 0 AND name like "' + searchstr + '" order by last_modified desc');
        }else{
            var result = tx.executeSql('SELECT * FROM project_task_app where account_id = 0 AND name like "' + searchstr + '"');
        }
        for (var i = 0; i < result.rows.length; i++) {
            var parent_task = tx.executeSql('SELECT name FROM project_task_app WHERE id = ?',[result.rows.item(i).parent_id]);
            var parentTask = parent_task.rows.length > 0 ? parent_task.rows.item(0).name || "" : "";

            var accunt_id = tx.executeSql('SELECT name FROM users WHERE id = ?',[result.rows.item(i).account_id]);
            var accountName = accunt_id.rows.length > 0 ? accunt_id.rows.item(0).name || "" : "";

            var project_name = tx.executeSql('SELECT name FROM project_project_app WHERE id = ?', [result.rows.item(i).project_id]);
            var project = project_name.rows.length > 0 ? project_name.rows.item(0).name || "" : "";


            var id = result.rows.item(i).id
            var spentHoursQuery = tx.executeSql('SELECT unit_amount FROM account_analytic_line_app WHERE task_id = ?', [id]);

            var color_pallet = ''
            if (result.rows.item(i).sub_project_id != 0) {
                var project_color = tx.executeSql('select color_pallet from project_project_app where id = ?', [result.rows.item(i).sub_project_id])
                if (project_color.rows.length) {
                    color_pallet = project_color.rows.item(0).color_pallet;
                }
            } else {
                var project_color = tx.executeSql('select color_pallet from project_project_app where id = ?', [result.rows.item(i).project_id])
                if (project_color.rows.length) {
                    color_pallet = project_color.rows.item(0).color_pallet;
                }
            }

            var totalMinutes = 0;
            for (var j = 0; j < spentHoursQuery.rows.length; j++) {
                /*                var timeString = spentHoursQuery.rows.item(j).unit_amount || "00:00";
            var parts = timeString.split(":");
            var hours = parseInt(parts[0], 10) || 0;
            var minutes = parseInt(parts[1], 10) || 0;
*/
                totalMinutes += spentHoursQuery.rows.item(j).unit_amount;
            }

            var totalHours = Math.floor(totalMinutes / 60);
            var remainingMinutes = totalMinutes % 60;
            var spentHours =  totalHours + ":" + (remainingMinutes < 10 ? "0" : "") + remainingMinutes;


            filteredtasks.push({'id': result.rows.item(i).id, 'color_pallet': color_pallet,
                                   'name': result.rows.item(i).name, 'allocated_hours': result.rows.item(i).initial_planned_hours,
                                   'state': result.rows.item(i).state, 'parentTask': parentTask, 'accountName':accountName,
                                   'favorites':result.rows.item(i).favorites,'spentHours':spentHours, 'timerRunning': false,
                                   'account_id': result.rows.item(i).account_id, 'parent_id': result.rows.item(i).parent_id,
                                   'description': result.rows.item(i).description, 'start_date':result.rows.item(i).start_date,
                                   'end_date':result.rows.item(i).end_date, 'deadline':result.rows.item(i).deadline,
                                   'user_id': result.rows.item(i).user_id, 'project_id': result.rows.item(i).project_id, 'project': project});
        }
    });
    return filteredtasks

}




//Refactored

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
                    start_date: row.start_date ? formatDate(new Date(row.start_date)) : "",
                    end_date: row.end_date ? formatDate(new Date(row.end_date)) : "",
                    deadline: row.deadline ? formatDate(new Date(row.deadline)) : "",
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

    function formatDate(date) {
        var month = date.getMonth() + 1;
        var day = date.getDate();
        var year = date.getFullYear();
        return month + '/' + day + '/' + year;
    }

    return task_detail;
}
