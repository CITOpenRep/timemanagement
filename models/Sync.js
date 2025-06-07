.import QtQuick.LocalStorage 2.7 as Sql

/* Name: createAccount
* This function will create record in users table and it will return true in case of duplicate record
* -> name -> name for the account
* -> link -> link of the Odoo instance
* -> database -> database name for Odoo instance
* -> username -> User name of Odoo instance
* -> selectedconnectwithId -> Whether connection with API Key or Password
* -> apikey -> API Key
*/

function createAccount(name, link, database, username, selectedconnectwithId, apikey) {
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    var duplicate_account = false;
    db.transaction(function(tx) {
        var check_account = tx.executeSql('SELECT id, COUNT(*) AS count FROM users WHERE link = ? AND database = ? AND username = ?', [link, database, username]);
        if (check_account.rows.item(0).count === 0) {
            var api_key_text = ' ';
            if (selectedconnectwithId == 1) {
                api_key_text = apikey;
            }
            tx.executeSql('INSERT INTO users (name, link, database, username, connectwith_id, api_key) VALUES (?, ?, ?, ?, ?, ?)', [name, link, database, username, selectedconnectwithId, api_key_text]);
        } else {
            duplicate_account = true;
        }
    });
    return duplicate_account;
}

/* Name: get_accounts_list
* This function will return all records of users
*/

function get_accounts_list() {
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);

    var accountsList = [];
    db.transaction(function(tx) {
        var accounts = tx.executeSql('SELECT * FROM users');
        for (var account = 0; account < accounts.rows.length; account++) {
            var connect_with = 0
            if (accounts.rows.item(account).connectwith_id && accounts.rows.item(account).connectwith_id != undefined) {
                connect_with = accounts.rows.item(account).connectwith_id;
            } 
            accountsList.push({'user_id': accounts.rows.item(account).id,
                             'name': accounts.rows.item(account).name,
                             'link': accounts.rows.item(account).link,
                             'database': accounts.rows.item(account).database,
                             'username': accounts.rows.item(account).username,
                             'connect_with': connect_with,
                            'api_key': accounts.rows.item(account).api_key})
        }
    });
    return accountsList;
}

/* Name: deleteAccount
* This function will delete record from users table
* account_id -> record id to be deleted
*/

function deleteAccount(account_id) {
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    db.transaction(function(tx) {
        tx.executeSql('DELETE FROM account_analytic_line_app where account_id =' + parseInt(account_id));
        tx.executeSql('DELETE FROM project_task_app where account_id =' + parseInt(account_id));
        tx.executeSql('DELETE FROM project_project_app where account_id =' + parseInt(account_id));
        tx.executeSql('DELETE FROM mail_activity_type_app where account_id =' + parseInt(account_id));
        tx.executeSql('DELETE FROM mail_activity_app where account_id =' + parseInt(account_id));
        tx.executeSql('DELETE FROM res_users_app where account_id =' + parseInt(account_id));
        tx.executeSql('DELETE FROM users where id =' + parseInt(account_id));
    });
    return
}

/* Name: deleteAccount
* This function will return datetime when last sync was done
* user_id -> record id to fetch last update
*/

function getLastModified(user_id) {
    var last_modified = false;
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    db.transaction(function (tx) {
        var result = tx.executeSql('select last_modified from users where id = ?', [user_id])
        if (result.rows.length) {
            last_modified = result.rows.item(0).last_modified
        }
    })   
    return last_modified;
}

/* Name: create_contacts
* This function will create and update res_users which fetched from Odoo
* contacts -> list of users fetched from Odoo
* instance_id -> account Id to map the res_users with this users table id
*/

function create_contacts(contacts, instance_id) {
    if (contacts === undefined) {
        return
    }
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    db.transaction(function (tx) {
        for (var contact = 0; contact < contacts.length; contact++) {
            var result = tx.executeSql('SELECT id, COUNT(*) AS count FROM res_users_app WHERE odoo_record_id = ? AND account_id = ?', [contacts[contact].id, parseInt(instance_id)]);
            var length = result.rows.length
            if (result.rows.length == 1 && result.rows.item(0).id == null) {
                length = 0
            }
            if (length > 0) {
                tx.executeSql('update res_users_app set name = ?,share = ?,active = ? where id = ?', [contacts[contact].name, contacts[contact].share?1:0, contacts[contact].active?1:0, result.rows.item(0).id])
            } else {
                tx.executeSql('INSERT INTO res_users_app (account_id, name, odoo_record_id, share, active) VALUES (?, ?, ?, ?, ?)', [instance_id, contacts[contact].name, contacts[contact].id, contacts[contact].share?1:0,contacts[contact].active?1:0])
            }
        }
    })
}

/* Name: get_all_projects
* This function to fetch existing projects from database
* instance_id -> to fetch projects related to the instance
* last_modified -> to fetch projects which are updated or created after this datetime
*/

function get_all_projects(instance_id, last_modified) {
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    var list_of_projects = [];
    db.transaction(function (tx) {
      var projects = tx.executeSql('select * from project_project_app where account_id = ? AND (last_modified > ? OR odoo_record_id is NULL)', [instance_id, last_modified])
        for (var project = 0; project < projects.rows.length; project++) {
            var parent_project_id = tx.executeSql('select id, odoo_record_id from project_project_app where id = ?', [projects.rows.item(project).parent_id])
            list_of_projects.push({'local_record_id': projects.rows.item(project).id,
                            'name': projects.rows.item(project).name,
                            'parent_id': projects.rows.item(project).parent_id?parent_project_id.rows.item(0).odoo_record_id: false,
                            'planned_start_date': projects.rows.item(project).planned_start_date,
                            'planned_end_date': projects.rows.item(project).planned_end_date,
                            'allocated_hours': projects.rows.item(project).allocated_hours,
                            'description': projects.rows.item(project).description,
                            'favorites': projects.rows.item(project).favorites,
                            'odoo_record_id': projects.rows.item(project).odoo_record_id,
                            'last_modified': projects.rows.item(project).last_modified,})
        }
    });
    return list_of_projects;
}

/* Name: set_projects
* This function will set id to fetched projects
* created_tasks -> list of projects fetched from Odoo
* instance_id -> to map projects to this instance
*/

function set_projects(created_projects, instance_id) {
    if (created_projects === undefined) {
        return
    }
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    db.transaction(function (tx) {
        for (var created_project = 0; created_project < created_projects.length; created_project++) {
            tx.executeSql('update project_project_app set odoo_record_id = ?, last_modified = ? where id = ?', [created_projects[created_project].odoo_record_id, new Date().toISOString(), created_projects[created_project].local_record_id])
        }
    })
}

/* Name: create_projects
* This function will create, update and delete projects which fetched from Odoo
* In case of project is deleted then it will remove all related data
* projects -> list of projects fetched from Odoo
* instance_id -> account Id to map the project with this users table id
*/

function create_projects(projects, instance_id) {
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);

    if (projects === undefined) {
        return
    }
    db.transaction(function(tx) {
        var fetchedProjects = projects.fetchedProjects
        for (var project = 0; project < fetchedProjects.length; project++) {
            var result = tx.executeSql('SELECT id, COUNT(*) AS count FROM project_project_app WHERE odoo_record_id = ? AND account_id = ?', [fetchedProjects[project].id, parseInt(instance_id)]);
            var parent_id = false;
            if (fetchedProjects[project].parent_id && fetchedProjects[project].parent_id.length) {
                var parent_query = tx.executeSql('SELECT id, COUNT(*) AS count FROM project_project_app WHERE odoo_record_id = ? AND account_id = ?', [fetchedProjects[project].parent_id[0], parseInt(instance_id)]);
                if (parent_query.rows.length !== 0) {
                    parent_id = parent_query.rows.item(0).id
                }
            }
            var planned_start_date = fetchedProjects[project].date_start
            if (planned_start_date == undefined) {
                planned_start_date = false;
            }
            var planned_end_date = fetchedProjects[project].date
            if (planned_end_date == undefined) {
                planned_end_date = false;
            }
            var priority = fetchedProjects[project].is_favorite == true ? 1 : 0
            if (result.rows.item(0).count === 0) {
                tx.executeSql('INSERT INTO project_project_app \
                    (name, account_id, odoo_record_id, parent_id, planned_start_date, \
                    planned_end_date, allocated_hours, favorites, last_modified, last_update_status, description\
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', 
                    [fetchedProjects[project].name, parseInt(instance_id), fetchedProjects[project].id, parent_id,
                    planned_start_date, planned_end_date, fetchedProjects[project].allocated_hours,
                    priority, new Date().toISOString(), fetchedProjects[project].last_update_status, fetchedProjects[project].description]);
            } else {
                tx.executeSql('UPDATE project_project_app SET \
                            account_id = ?, odoo_record_id = ?, name = ?, parent_id = ?, planned_start_date = ?, planned_end_date = ?, \
                            allocated_hours = ?, favorites = ?, description = ?, last_modified = ?\
                            where id = ?', 
                            [parseInt(instance_id), fetchedProjects[project].id, fetchedProjects[project].name, parent_id,
                            planned_start_date, planned_end_date, fetchedProjects[project].allocated_hours,
                            priority, fetchedProjects[project].description, new Date().toISOString(), result.rows.item(0).id])
            }

        }
        var deletedRecords = []
        var ids_array = ''
        if (projects.fetch_all_records) {
            ids_array = projects.existing_projects.join(", ")
            deletedRecords = tx.executeSql('select id from project_project_app where account_id = '+ instance_id +' AND odoo_record_id not in ('+ ids_array +')');
        } else {
            ids_array = projects.deleted_records.join(", ")
            deletedRecords = tx.executeSql('select id from project_project_app where account_id = '+ instance_id +' AND odoo_record_id in ('+ ids_array +')');
        }
        for (var delete_rec = 0; delete_rec < deletedRecords.rows.length; delete_rec++) {
            tx.executeSql('delete from account_analytic_line_app where project_id =  ?', [deletedRecords.rows.item(delete_rec).id])
            tx.executeSql('delete from project_task_app where project_id =  ?', [deletedRecords.rows.item(delete_rec).id])
            tx.executeSql('update project_project_app set parent_id = NULL where parent_id = ?', [deletedRecords.rows.item(delete_rec).id])
            tx.executeSql('delete from project_project_app where id =  ?', [deletedRecords.rows.item(delete_rec).id])
        }
    });
}

/* Name: get_all_tasks
* This function to fetch existing tasks from database
* contacts -> list of users fetched from Odoo
* instance_id -> to fetch tasks related to the instance
* last_modified -> to fetch tasks which are updated or created after this datetime
*/

function get_all_tasks(instance_id, last_modified) {
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    var list_of_tasks = [];
    db.transaction(function (tx) {
      var  tasks = tx.executeSql('select * from project_task_app where account_id = ? AND (last_modified > ? OR odoo_record_id is NULL)', [instance_id, last_modified])
        for (var task = 0; task < tasks.rows.length; task++) {
            var project_id = tx.executeSql('select id, odoo_record_id from project_project_app where id = ?', [tasks.rows.item(task).project_id])
            var sub_project_id = tx.executeSql('select id, odoo_record_id from project_project_app where id = ?', [tasks.rows.item(task).sub_project_id])
            var task_id = tx.executeSql('select id, odoo_record_id from project_task_app where id = ?', [tasks.rows.item(task).parent_id])
            var user_id = tx.executeSql('select id, odoo_record_id from res_users_app where id = ?', [tasks.rows.item(task).user_id])
            var context_project = tx.executeSql('select project_id from project_task_app where id=?', [tasks.rows.item(task).id])
            list_of_tasks.push({'local_record_id': tasks.rows.item(task).id,
                            'name': tasks.rows.item(task).name,
                            'project_id': tasks.rows.item(task).project_id?project_id.rows.item(0).odoo_record_id: false,
                            'parent_id': tasks.rows.item(task).parent_id?task_id.rows.item(0).odoo_record_id: false,
                            'deadline': tasks.rows.item(task).deadline,
                            'sub_project_id': tasks.rows.item(task).sub_project_id?sub_project_id.rows.item(0).odoo_record_id: false,
                            'user_id':tasks.rows.item(task).user_id?user_id.rows.item(0).odoo_record_id:false,
                            'initial_planned_hours': tasks.rows.item(task).initial_planned_hours,
                            'favorites': tasks.rows.item(task).favorites,
                            'last_modified': tasks.rows.item(task).last_modified,
                            'state': tasks.rows.item(task).state,
                            'date_start': tasks.rows.item(task).start_date,
                            'date_end': tasks.rows.item(task).end_date,
                            'description': tasks.rows.item(task).description,
                            'odoo_record_id': tasks.rows.item(task).odoo_record_id})
        }
    });
    return list_of_tasks;
}

/* Name: set_tasks
* This function will set id to fetched tasks
* created_tasks -> list of tasks fetched from Odoo
* instance_id -> to map tasks to this instance
*/

function set_tasks(created_tasks, instance_id) {
    if (created_tasks === undefined) {
        return
    }
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    db.transaction(function (tx) {
        for (var created_task = 0; created_task < created_tasks.length; created_task++) {
            tx.executeSql('update project_task_app set odoo_record_id = ?, last_modified = ? where id = ?', [created_tasks[created_task].odoo_record_id, new Date().toISOString(), created_tasks[created_task].local_record_id])
        }
    })
}

/* Name: create_tasks
* This function will create, update and delete tasks which fetched from Odoo
* In case of task is deleted then it will remove all related data
* tasks -> list of tasks fetched from Odoo
* instance_id -> account Id to map the task with this users table id
*/

function create_tasks(tasks, instance_id) {
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);

    if (tasks === undefined) {
        return
    }
    db.transaction(function(tx) {
        var fetchedTasks = tasks.fetchedTasks
        for (var task = 0; task < fetchedTasks.length; task++) {
            var result = tx.executeSql('SELECT id, start_date, COUNT(*) AS count FROM project_task_app WHERE odoo_record_id = ? AND account_id = ?', [fetchedTasks[task].id, parseInt(instance_id)]);
            var parent_task_id = false;
            if (fetchedTasks[task].parent_id.length) {
                var parent_query = tx.executeSql('SELECT id, COUNT(*) AS count FROM project_task_app WHERE odoo_record_id = ? AND account_id = ?', [fetchedTasks[task].parent_id[0], parseInt(instance_id)]);
                if (parent_query.rows.length !== 0) {
                    parent_task_id = parent_query.rows.item(0).id
                }
            }
            var project_id = false;
            var sub_project_id = false;
            if (fetchedTasks[task].project_id.length) {
                var parent_query = tx.executeSql('SELECT id, parent_id, COUNT(*) AS count FROM project_project_app WHERE odoo_record_id = ? AND account_id = ?', [fetchedTasks[task].project_id[0], parseInt(instance_id)]);
                if (parent_query.rows.length !== 0) {
                    project_id = parent_query.rows.item(0).id
                    if (parent_query.rows.item(0).parent_id) {
                        project_id = parent_query.rows.item(0).parent_id
                        sub_project_id = parent_query.rows.item(0).id
                    }
                }
            }
            var user_id = false;
            if (fetchedTasks[task].user_ids.length) {
                var parent_query = tx.executeSql('SELECT id, COUNT(*) AS count FROM res_users_app WHERE odoo_record_id IN ('+fetchedTasks[task].user_ids.join(", ")+') AND account_id = ?', [parseInt(instance_id)]);
                if (parent_query.rows.length !== 0) {
                    user_id = parent_query.rows.item(0).id
                }
            }
            var start_date = fetchedTasks[task].date_start
            if (start_date == undefined) {
                start_date = false;
            }
            if (result.rows.item(0).count === 0) {
                tx.executeSql('INSERT INTO project_task_app \
                    (name, account_id, project_id, sub_project_id, parent_id, \
                    deadline, initial_planned_hours, favorites, description, \
                    state, last_modified, odoo_record_id, user_id, start_date, end_date) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', 
                    [fetchedTasks[task].name, parseInt(instance_id), project_id, sub_project_id, parent_task_id,
                    fetchedTasks[task].date_deadline, fetchedTasks[task].planned_hours,
                    fetchedTasks[task].priority, fetchedTasks[task].description, fetchedTasks[task].stage_id[1], new Date().toISOString(), fetchedTasks[task].id, user_id, start_date, fetchedTasks[task].date_end]);
            } else {
                if (start_date == false) {
                    start_date = result.rows.item(0).start_date
                }
                tx.executeSql('UPDATE project_task_app set name = ?, account_id = ?, project_id = ?, sub_project_id = ?, parent_id = ?, \
                    deadline = ?, initial_planned_hours = ?, favorites = ?, description = ?, \
                    state = ?, last_modified = ?, odoo_record_id = ?, user_id = ?, start_date = ?, end_date = ? where id = ?', [fetchedTasks[task].name, parseInt(instance_id), project_id, sub_project_id, parent_task_id,
                    fetchedTasks[task].date_deadline, fetchedTasks[task].planned_hours,
                    fetchedTasks[task].priority, fetchedTasks[task].description, fetchedTasks[task].stage_id[1], new Date().toISOString(), fetchedTasks[task].id, user_id, start_date, fetchedTasks[task].date_end, result.rows.item(0).id])
            }

        }
        var deletedRecords = []
        var ids_array = ''
        if (tasks.fetch_all_records) {
            ids_array = tasks.existing_tasks.join(", ")
            deletedRecords = tx.executeSql('select id from project_task_app where account_id = '+ instance_id +' AND odoo_record_id != 0 AND odoo_record_id not in ('+ ids_array +')');
        } else {
            ids_array = tasks.deleted_records.join(", ")
            deletedRecords = tx.executeSql('select id from project_task_app where account_id = '+ instance_id +' AND odoo_record_id != 0 AND odoo_record_id in ('+ ids_array +')');
        }
        for (var delete_rec = 0; delete_rec < deletedRecords.rows.length; delete_rec++) {
            tx.executeSql('delete from account_analytic_line_app where task_id =  ?', [deletedRecords.rows.item(delete_rec).id])
            tx.executeSql('update project_task_app set parent_id = NULL where id = ?', [deletedRecords.rows.item(delete_rec).id])
            tx.executeSql('delete from project_task_app where id =  ?', [deletedRecords.rows.item(delete_rec).id])
        }
    });
}

/* Name: fetchTimesheets
* This function will return timesheets which are updated after sync
* instance_id -> to fetch timesheet entries only related to this account
*/

function fetchTimesheets(instance_id, last_modified) {
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    var timesheetEntries = [];
    db.transaction(function (tx) {
        var fetchedEntries = tx.executeSql('select * from account_analytic_line_app where account_id = ? AND (last_modified > ? OR odoo_record_id IS NULL)', [instance_id, last_modified])
        for (var record = 0; record < fetchedEntries.rows.length; record++) {
            var selected_project_id = fetchedEntries.rows.item(record).project_id
            var selected_task_id = fetchedEntries.rows.item(record).task_id
            if (fetchedEntries.rows.item(record).sub_project_id && fetchedEntries.rows.item(record).sub_project_id != 0) {
                selected_project_id = fetchedEntries.rows.item(record).sub_project_id
            }
            if (fetchedEntries.rows.item(record).sub_task_id && fetchedEntries.rows.item(record).sub_task_id != 0) {
                selected_task_id = fetchedEntries.rows.item(record).sub_task_id
            }
            var projectId = tx.executeSql('select odoo_record_id from project_project_app where account_id = ? AND id >= ?', [instance_id, selected_project_id]);
            var taskId = tx.executeSql('select odoo_record_id from project_task_app where account_id = ? AND id >= ?', [instance_id, selected_task_id]);
            timesheetEntries.push({'local_record_id': fetchedEntries.rows.item(record).id,
                             'record_date': fetchedEntries.rows.item(record).record_date,
                             'name': fetchedEntries.rows.item(record).name,
                             'project_id': projectId.rows.item(0).odoo_record_id, 
                             'task_id': taskId.rows.item(0).odoo_record_id, 
                             'unit_amount': fetchedEntries.rows.item(record).unit_amount, 
                             'odoo_record_id': fetchedEntries.rows.item(record).odoo_record_id,
                             'last_modified': fetchedEntries.rows.item(record).last_modified});
        }
    });
    return timesheetEntries;
}

/* Name: update_timesheet_entries
* This function will update and delete timesheets after sync
* timesheet_entries -> details fetched from Odoo after sync
* instance_id -> to fetch map timesheet entries to this account
*/

function update_timesheet_entries(timesheet_entries, instance_id) {
    if (timesheet_entries === undefined) {
        return
    }
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    var fetchedTimesheets = timesheet_entries.fetchedTimesheets
    db.transaction(function (tx) {
        for (var record = 0; record < fetchedTimesheets.length; record++) {
            tx.executeSql('update account_analytic_line_app set odoo_record_id = ?,last_modified = ? where id = ?', [fetchedTimesheets[record].odoo_record_id, new Date().toISOString(), fetchedTimesheets[record].local_record_id])
        }

        var deletedRecords = []
        var ids_array = ''
        if (timesheet_entries.fetch_all_records) {
            ids_array = timesheet_entries.existing_records.join(", ")
            deletedRecords = tx.executeSql('select id from account_analytic_line_app where account_id = '+ instance_id +' AND odoo_record_id != 0 AND odoo_record_id not in ('+ ids_array +')');
        } else {
            ids_array = timesheet_entries.deleted_records.join(", ")
            deletedRecords = tx.executeSql('select id from account_analytic_line_app where account_id = '+ instance_id +' AND odoo_record_id != 0 AND odoo_record_id in ('+ ids_array +')');
        }
        for (var delete_rec = 0; delete_rec < deletedRecords.rows.length; delete_rec++) {
            tx.executeSql('delete from account_analytic_line_app where id =  ?', [deletedRecords.rows.item(delete_rec).id])
        }
    });
}

/* Name: set_tasks
* This function will set id to fetched timesheets
* created_timesheets -> list of timesheets fetched from Odoo
* instance_id -> to map timesheets to this instance
*/

function set_timesheets(created_timesheets, instance_id) {
    if (created_timesheets === undefined) {
        return
    }
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    db.transaction(function (tx) {
        for (var created_timesheet = 0; created_timesheet < created_timesheets.length; created_timesheet++) {
            tx.executeSql('update account_analytic_line_app set odoo_record_id = ?, last_modified = ? where id = ?', [created_timesheets[created_timesheet].odoo_record_id, new Date().toISOString(), created_timesheets[created_timesheet].local_record_id])
        }
    })
}

/* Name: create_timesheets
* This function will create, update and delete timesheets which fetched from Odoo
* In case of timesheet is deleted then it will remove all related data
* tasks -> list of timesheets fetched from Odoo
* instance_id -> account Id to map the timesheets with this users table id
*/

function create_timesheets(timesheets, instance_id) {
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    if (timesheets === undefined) {
        return
    }
    db.transaction(function(tx) {
        var fetchedTimesheets = timesheets.fetchedTimesheets
        for (var timesheet = 0; timesheet < fetchedTimesheets.length; timesheet++) {
            var result = tx.executeSql('SELECT id, COUNT(*) AS count FROM account_analytic_line_app WHERE odoo_record_id = ? AND account_id = ?', [fetchedTimesheets[timesheet].id, parseInt(instance_id)]);
            var sub_task_id = false;
            var task_id = false;
            if (fetchedTimesheets[timesheet].task_id.length) {
                var parent_query = tx.executeSql('SELECT id, parent_id, COUNT(*) AS count FROM project_task_app WHERE odoo_record_id = ? AND account_id = ?', [fetchedTimesheets[timesheet].task_id[0], parseInt(instance_id)]);
                if (parent_query.rows.length !== 0) {
                    task_id = parent_query.rows.item(0).id
                    if (parent_query.rows.item(0).parent_id) {
                        task_id = parent_query.rows.item(0).parent_id
                        sub_task_id = parent_query.rows.item(0).id
                    }
                }
            }
            var project_id = false;
            var sub_project_id = false;
            if (fetchedTimesheets[timesheet].project_id.length) {
                var parent_query = tx.executeSql('SELECT id, parent_id, COUNT(*) AS count FROM project_project_app WHERE odoo_record_id = ? AND account_id = ?', [fetchedTimesheets[timesheet].project_id[0], parseInt(instance_id)]);
                if (parent_query.rows.length !== 0) {
                    project_id = parent_query.rows.item(0).id
                    if (parent_query.rows.item(0).parent_id) {
                        project_id = parent_query.rows.item(0).parent_id
                        sub_project_id = parent_query.rows.item(0).id
                    }
                }
            }
            let recordDate = false;
            if ("date" in fetchedTimesheets[timesheet]) {
                recordDate = fetchedTimesheets[timesheet].date;
            } else {
                recordDate = fetchedTimesheets[timesheet].date_time;
            }
            if (result.rows.item(0).count === 0) {
                tx.executeSql('INSERT INTO account_analytic_line_app \
                    (account_id, odoo_record_id, record_date, project_id, task_id, name, sub_project_id, sub_task_id, quadrant_id,  \
                    unit_amount, last_modified) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                    [parseInt(instance_id), fetchedTimesheets[timesheet].id, recordDate, project_id, task_id, fetchedTimesheets[timesheet].name, sub_project_id,
                    sub_task_id, fetchedTimesheets[timesheet].quadrant, fetchedTimesheets[timesheet].unit_amount, new Date().toISOString()]);
            } else {
                tx.executeSql('UPDATE account_analytic_line_app \
                    set account_id = ?, odoo_record_id = ?, record_date = ?, project_id = ?, task_id = ?, name = ?, sub_project_id = ?, sub_task_id = ?,  \
                    unit_amount = ?, last_modified = ? WHERE id = ?',
                    [parseInt(instance_id), fetchedTimesheets[timesheet].id, recordDate, project_id, task_id, fetchedTimesheets[timesheet].name, sub_project_id,
                    sub_task_id, fetchedTimesheets[timesheet].unit_amount, new Date().toISOString(), result.rows.item(0).id])
            }

        }
        var deletedRecords = []
        var ids_array = ''
        if (timesheets.fetch_all_records) {
            ids_array = timesheets.existing_timesheets.join(", ")
            deletedRecords = tx.executeSql('select id from account_analytic_line_app where account_id = '+ instance_id +' AND odoo_record_id != 0 AND odoo_record_id not in ('+ ids_array +')');
        } else {
            ids_array = timesheets.deleted_records.join(", ")
            deletedRecords = tx.executeSql('select id from account_analytic_line_app where account_id = '+ instance_id +' AND odoo_record_id != 0 AND odoo_record_id in ('+ ids_array +')');
        }
        for (var delete_rec = 0; delete_rec < deletedRecords.rows.length; delete_rec++) {
            tx.executeSql('delete from account_analytic_line_app where id = ?', [deletedRecords.rows.item(delete_rec).id])
        }
    });
}

/* Name: create_activity_types
* This function will create activity types which are exist in Odoo
* activities -> details fetched from Odoo after sync
* instance_id -> to fetch and map activity types to this account
*/

function create_activity_types(activities, instance_id) {
    if (activities === undefined) {
        return
    }
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    db.transaction(function(tx) {
        for (var activity = 0; activity < activities.length; activity++) {
            var existing_activity = tx.executeSql('select count(*) AS count from mail_activity_type_app where account_id = ? AND odoo_record_id = ?', [instance_id, activities[activity].id])
            if (existing_activity.rows.item(0).count == 0) {
                tx.executeSql('INSERT INTO mail_activity_type_app \
                    (account_id, name, odoo_record_id) VALUES \
                    (?, ?, ?)', [instance_id, activities[activity].name, activities[activity].id])
            }
        }
    })
}

/* Name: fetchAllActivities
* This function will return activities related to the account
* instance_id -> to get the activities related to this account id
*/

function fetchAllActivities(instance_id) {
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    var timesheetEntries = [];
    db.transaction(function (tx) {
        var fetchedEntries = tx.executeSql('select * from mail_activity_app where account_id = ?', [instance_id])
        for (var activity = 0; activity < fetchedEntries.rows.length; activity++) {
            timesheetEntries.push({'id': fetchedEntries.rows.item(activity).id,
                                'odoo_record_id': fetchedEntries.rows.item(activity).odoo_record_id})
        }
    });
    return timesheetEntries;

}

/* Name: create_activities
* This function will create and update activities which fetched from Odoo
* activities -> list of activities fetched from Odoo
* instance_id -> account Id to map the activities with this users table id
*/

function create_activities(activities, instance_id) {
    if (activities === undefined) {
        return
    }
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    db.transaction(function (tx) {
        for (var activity = 0; activity < activities.length; activity++) {
            var existing_activity = tx.executeSql('select id, count(*) AS count from mail_activity_app where account_id = ? AND odoo_record_id = ?', [instance_id, activities[activity].id])
            var activity_type_id = tx.executeSql('select id from mail_activity_type_app where account_id = ? AND odoo_record_id = ?', [instance_id, activities[activity].activity_type_id[0]])
            var user_id = tx.executeSql('select id from res_users_app where account_id = ? AND odoo_record_id = ?', [instance_id, activities[activity].user_id[0]])
            if (existing_activity.rows.item(0).count == 0) {
                if (activities[activity].res_model == 'project.project') {
                    var project_id = tx.executeSql('select id from project_project_app where account_id = ? AND odoo_record_id = ?', [instance_id, activities[activity].res_id])
                    tx.executeSql('INSERT INTO mail_activity_app \
                        (account_id, activity_type_id, summary, due_date, user_id, notes, odoo_record_id, last_modified, project_id, link_id, state)\
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', [instance_id, activity_type_id.rows.item(0).id, 
                            activities[activity].summary, activities[activity].date_deadline, user_id.rows.item(0).id,
                            activities[activity].note, activities[activity].id, new Date().toISOString(), project_id.rows.item(0).id, 1, 'schedule'])
                } else if (activities[activity].res_model == 'project.task') {
                    var task_id = tx.executeSql('select id from project_task_app where account_id = ? AND odoo_record_id = ?', [instance_id, parseInt(activities[activity].res_id)])
                    tx.executeSql('INSERT INTO mail_activity_app \
                        (account_id, activity_type_id, summary, due_date, user_id, notes, odoo_record_id, last_modified, task_id, link_id, state)\
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', [instance_id, activity_type_id.rows.item(0).id, 
                            activities[activity].summary, activities[activity].date_deadline, user_id.rows.item(0).id,
                            activities[activity].note, activities[activity].id, new Date().toISOString(), task_id.rows.item(0).id, 2, 'schedule'])
                } else {
                    tx.executeSql('INSERT INTO mail_activity_app \
                        (account_id, activity_type_id, summary, due_date, user_id, notes, odoo_record_id, last_modified, resModel, resId, link_id, state)\
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', [instance_id, activity_type_id.rows.item(0).id, 
                            activities[activity].summary, activities[activity].date_deadline, user_id.rows.item(0).id,
                            activities[activity].note, activities[activity].id, new Date().toISOString(), activities[activity].res_model, activities[activity].res_id, 3, 'schedule'])
                }
            } else {
                tx.executeSql('update mail_activity_app set activity_type_id = ?, summary = ?, due_date = ?, user_id = ?, notes = ?, last_modified = ?\
                    where id = ?', [activity_type_id.rows.item(0).id, 
                        activities[activity].summary, activities[activity].date_deadline, user_id.rows.item(0).id,
                        activities[activity].note, new Date().toISOString(), existing_activity.rows.item(0).id])
            }
        }
    })
}

/* Name: done_activities
* This function will mark activities as done
* activities -> list of activities fetched from Odoo
* instance_id -> account Id to map the activities with this users table id
*/

function done_activities(activities, instance_id) {
    if (activities === undefined) {
        return
    }
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    db.transaction(function (tx) {
        for (var activity = 0; activity < activities.length; activity++) {
            var existing_activity = tx.executeSql('select id, count(*) AS count from mail_activity_app where account_id = ? AND odoo_record_id = ?', [instance_id, activities[activity]])
            if (existing_activity.rows.length) {
                tx.executeSql('update mail_activity_app set state = ? where id = ?', ['done', existing_activity.rows.item(0).id])
            }
        }
    });

}

/* Name: update_instance_date
* This function will update users table record to help when last sync was done
* instance_id -> account Id
*/

function update_instance_date(instance_id) {
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    var timesheetEntries = [];
    db.transaction(function (tx) {
        tx.executeSql('update users set last_modified = ? where id = ?', [new Date().toISOString(), instance_id]);
    });
}

/* Name: fetchActivities
* This function will return activities which are remaining for sync
* instance_id -> account Id
*/

function fetchActivities(instance_id) {
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    var activities = [];
    db.transaction(function (tx) {
        var result = tx.executeSql('select id, last_modified from users where id = ?', [instance_id]);
        // , last_modified
        var last_modified = false;
        if (result.rows.length) {
            last_modified = result.rows.item(0).last_modified;
        }
        var fetchedEntries = tx.executeSql('select * from mail_activity_app where account_id = ? AND (last_modified > ? OR odoo_record_id IS NULL)', [instance_id, last_modified])
        for (var record = 0; record < fetchedEntries.rows.length; record++) {
            var activityTypeId = tx.executeSql('select odoo_record_id from mail_activity_type_app where account_id = ? AND id >= ?', [instance_id, fetchedEntries.rows.item(record).activity_type_id]);
            var activity_user = tx.executeSql('SELECT id, odoo_record_id FROM res_users_app WHERE id = ?', [fetchedEntries.rows.item(record).user_id]);
            var project_id = false;
            var task_id = false;
            if (fetchedEntries.rows.item(record).project_id) {
                var fetchProject = tx.executeSql('select id, odoo_record_id from project_project_app where id = ?', [fetchedEntries.rows.item(record).project_id])
                if (fetchProject.rows.length !== 0) {
                    project_id = fetchProject.rows.item(0).odoo_record_id
                }
            }
            if (fetchedEntries.rows.item(record).task_id) {
                var fetchTask = tx.executeSql('select id, odoo_record_id from project_task_app where id = ?', [fetchedEntries.rows.item(record).task_id])
                if (fetchTask.rows.length !== 0) {
                    task_id = fetchTask.rows.item(0).odoo_record_id
                }
            }
            activities.push({'local_record_id': fetchedEntries.rows.item(record).id, 
                'user_id': activity_user.rows.item(0).odoo_record_id, 
                'due_date': fetchedEntries.rows.item(record).due_date, 
                'activity_type_id': activityTypeId.rows.item(0).odoo_record_id, 
                'summary': fetchedEntries.rows.item(record).summary, 
                'notes': fetchedEntries.rows.item(record).notes, 
                'odoo_record_id': fetchedEntries.rows.item(record).odoo_record_id,
                'link_id': fetchedEntries.rows.item(record).link_id,
                'project_id': project_id,
                'task_id': task_id,
                'state': fetchedEntries.rows.item(record).state,
                'res_model': fetchedEntries.rows.item(record).resModel,
                'res_id': fetchedEntries.rows.item(record).resId});
        }
    });
    return activities;
}

/* Name: update_activity_entries
* This function will update record id which is fetched from Odoo after sync
* activity_entries -> activities to update record Id
*/

function update_activity_entries(activity_entries) {
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    if (activity_entries === undefined) {
        return
    }
    db.transaction(function (tx) {
        for (var record = 0; record < activity_entries.length; record++) {
            tx.executeSql('update mail_activity_app set odoo_record_id = ? where id = ?', [activity_entries[record].odoo_record_id, activity_entries[record].local_record_id])
        }
    });
}
