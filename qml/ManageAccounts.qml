/*
 * MIT License
 *
 * Copyright (c) 2025 CIT-Services
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import QtQuick 2.7
import QtQuick.Window 2.2
import QtQuick.Controls 2.2
import QtQuick.LocalStorage 2.7
import io.thp.pyotherside 1.4
import Ubuntu.Components 1.3 as Ubuntu
import "components"

Item {
    width: parent.width
    height: parent.height
    property var optionList: []
    property bool isTextInputVisible: false
    property bool isTextMenuVisible: false
    property bool isValidUrl: true
    property bool isValidLogin: true
    property bool isValidAccount: true
    property bool isPasswordVisible: false
    property var accountsList: []
    property bool loading: false
    property bool issearchHeader: false
    property string loadingMessage: ""

    function initializeDatabase() {
        var db = LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);

        db.transaction(function (tx) {
            tx.executeSql('CREATE TABLE IF NOT EXISTS users (\
                id INTEGER PRIMARY KEY AUTOINCREMENT,\
                name TEXT NOT NULL,\
                link TEXT NOT NULL,\
                last_modified datetime,\
                database TEXT NOT NULL,\
                connectwith_id INTEGER,\
                api_key TEXT,\
                username TEXT NOT NULL\
            )');
        });

        db.transaction(function (tx) {
            tx.executeSql('CREATE TABLE IF NOT EXISTS project_project_app (\
                id INTEGER PRIMARY KEY AUTOINCREMENT,\
                name TEXT NOT NULL,\
                account_id INTEGER,\
                parent_id INTEGER,\
                planned_start_date date,\
                planned_end_date date,\
                allocated_hours FLOAT,\
                favorites INTEGER,\
                last_update_status TEXT,\
                description TEXT,\
                last_modified datetime,\
                color_pallet TEXT,\
                odoo_record_id INTEGER,\
                FOREIGN KEY (account_id) REFERENCES users(id) ON DELETE CASCADE,\
                FOREIGN KEY (parent_id) REFERENCES project_project_app(id) ON DELETE CASCADE\
            )');
        });

        db.transaction(function (tx) {
            tx.executeSql('CREATE TABLE IF NOT EXISTS res_users_app (\
                id INTEGER PRIMARY KEY AUTOINCREMENT,\
                account_id INTEGER,\
                name Text,\
                share INTEGER,\
                active INTEGER,\
                odoo_record_id INTEGER,\
                FOREIGN KEY (account_id) REFERENCES users(id) ON DELETE CASCADE\
            )');
        });

        db.transaction(function (tx) {
            tx.executeSql('CREATE TABLE IF NOT EXISTS project_task_app (\
                id INTEGER PRIMARY KEY AUTOINCREMENT,\
                name TEXT NOT NULL,\
                account_id INTEGER,\
                project_id INTEGER,\
                sub_project_id INTEGER,\
                parent_id INTEGER,\
                start_date date,\
                end_date date,\
                deadline date,\
                initial_planned_hours FLOAT,\
                favorites INTEGER,\
                state TEXT,\
                description TEXT,\
                last_modified datetime,\
                user_id INTEGER,\
                odoo_record_id INTEGER,\
                FOREIGN KEY (account_id) REFERENCES users(id) ON DELETE CASCADE,\
                FOREIGN KEY (project_id) REFERENCES project_project_app(id) ON DELETE CASCADE,\
                FOREIGN KEY (sub_project_id) REFERENCES project_project_app(id) ON DELETE CASCADE,\
                FOREIGN KEY (user_id) REFERENCES res_users_app(id) ON DELETE CASCADE,\
                FOREIGN KEY (parent_id) REFERENCES project_task_app(id) ON DELETE CASCADE\
            )');
        });

        db.transaction(function (tx) {
            tx.executeSql('CREATE TABLE IF NOT EXISTS account_analytic_line_app (\
                id INTEGER PRIMARY KEY AUTOINCREMENT,\
                account_id INTEGER,\
                project_id INTEGER,\
                sub_project_id INTEGER,\
                task_id INTEGER,\
                sub_task_id INTEGER,\
                name TEXT,\
                unit_amount FLOAT,\
                last_modified datetime,\
                quadrant_id INTEGER,\
                record_date date,\
                odoo_record_id INTEGER,\
                FOREIGN KEY (account_id) REFERENCES users(id) ON DELETE CASCADE,\
                FOREIGN KEY (project_id) REFERENCES project_project_app(id) ON DELETE CASCADE,\
                FOREIGN KEY (task_id) REFERENCES project_task_app(id) ON DELETE CASCADE\
            )');
        });

        db.transaction(function (tx) {
            tx.executeSql('CREATE TABLE IF NOT EXISTS mail_activity_type_app (\
                id INTEGER PRIMARY KEY AUTOINCREMENT,\
                account_id INTEGER,\
                name TEXT,\
                odoo_record_id INTEGER,\
                FOREIGN KEY (account_id) REFERENCES users(id) ON DELETE CASCADE\
            )');
        });

        db.transaction(function (tx) {
            tx.executeSql('CREATE TABLE IF NOT EXISTS mail_activity_app (\
                id INTEGER PRIMARY KEY AUTOINCREMENT,\
                account_id INTEGER,\
                activity_type_id INTEGER,\
                summary TEXT,\
                due_date DATE,\
                user_id INTEGER,\
                notes TEXT,\
                odoo_record_id INTEGER,\
                last_modified datetime,\
                link_id INTEGER,\
                project_id INTEGER,\
                task_id INTEGER,\
                resId INTEGER,\
                resModel TEXT,\
                state TEXT,\
                FOREIGN KEY (account_id) REFERENCES users(id) ON DELETE CASCADE,\
                FOREIGN KEY (user_id) REFERENCES res_users_app(id) ON DELETE CASCADE,\
                FOREIGN KEY (activity_type_id) REFERENCES mail_activity_type_app(id) ON DELETE CASCADE\
                FOREIGN KEY (project_id) REFERENCES project_project_app(id) ON DELETE CASCADE,\
                FOREIGN KEY (task_id) REFERENCES project_task_app(id) ON DELETE CASCADE\
            )');
        });
    }

    function queryData() {
        var db = LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);

        db.transaction(function (tx) {
            var result = tx.executeSql('SELECT * FROM users');
            console.log("Database Query Results:");
            accountsList = [];
            for (var i = 0; i < result.rows.length; i++) {
                accountsList.push({
                    'user_id': result.rows.item(i).id,
                    'connect_with': result.rows.item(i).connectwith_id,
                    'name': result.rows.item(i).name,
                    'link': result.rows.item(i).link,
                    'database': result.rows.item(i).database,
                    'username': result.rows.item(i).username,
                    'last_modified': result.rows.item(i).last_modified,
                    'api_key': result.rows.item(i).api_key
                });
            }
            recordModel.clear();
            for (var i = 0; i < accountsList.length; i++) {
                recordModel.append(accountsList[i]);
            }
        });
    }

    function getLastModified(user_id) {
        var last_modified = false;
        var db = LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
        db.transaction(function (tx) {
            var result = tx.executeSql('select last_modified from users where id = ?', [user_id]);
            if (result.rows.length) {
                last_modified = result.rows.item(0).last_modified;
            }
        });
        return last_modified;
    }

    function filtersynList(query) {
        recordModel.clear(); // Clear existing data in the model

        for (var i = 0; i < accountsList.length; i++) {
            var entry = accountsList[i];
            if (entry.name.toLowerCase().includes(query.toLowerCase())) {
                recordModel.append(entry);
            }
        }
    }

    function fetchTimesheets(instance_id) {
        var db = LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
        var timesheetEntries = [];
        db.transaction(function (tx) {
            var result = tx.executeSql('select id, last_modified from users where id = ?', [instance_id]);
            var last_modified = false;
            if (result.rows.length) {
                last_modified = result.rows.item(0).last_modified;
            }
            var fetchedEntries = tx.executeSql('select * from account_analytic_line_app where account_id = ? AND (last_modified > ? OR odoo_record_id IS NULL)', [instance_id, last_modified]);
            for (var record = 0; record < fetchedEntries.rows.length; record++) {
                var selected_project_id = fetchedEntries.rows.item(record).project_id;
                var selected_task_id = fetchedEntries.rows.item(record).task_id;
                if (fetchedEntries.rows.item(record).sub_project_id && fetchedEntries.rows.item(record).sub_project_id != 0) {
                    selected_project_id = fetchedEntries.rows.item(record).sub_project_id;
                }
                if (fetchedEntries.rows.item(record).sub_task_id && fetchedEntries.rows.item(record).sub_task_id != 0) {
                    selected_task_id = fetchedEntries.rows.item(record).sub_task_id;
                }
                var projectId = tx.executeSql('select odoo_record_id from project_project_app where account_id = ? AND id >= ?', [instance_id, selected_project_id]);
                var taskId = tx.executeSql('select odoo_record_id from project_task_app where account_id = ? AND id >= ?', [instance_id, selected_task_id]);
                timesheetEntries.push({
                    'local_record_id': fetchedEntries.rows.item(record).id,
                    'record_date': fetchedEntries.rows.item(record).record_date,
                    'name': fetchedEntries.rows.item(record).name,
                    'project_id': projectId.rows.item(0).odoo_record_id,
                    'task_id': taskId.rows.item(0).odoo_record_id,
                    'unit_amount': fetchedEntries.rows.item(record).unit_amount,
                    'odoo_record_id': fetchedEntries.rows.item(record).odoo_record_id
                });
            }
        });
        return timesheetEntries;
    }

    function fetchActivities(instance_id) {
        var db = LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
        var timesheetEntries = [];
        db.transaction(function (tx) {
            var result = tx.executeSql('select id, last_modified from users where id = ?', [instance_id]);
            // , last_modified
            var last_modified = false;
            if (result.rows.length) {
                last_modified = result.rows.item(0).last_modified;
            }
            var fetchedEntries = tx.executeSql('select * from mail_activity_app where account_id = ? AND (last_modified > ? OR odoo_record_id IS NULL)', [instance_id, last_modified]);
            for (var record = 0; record < fetchedEntries.rows.length; record++) {
                var activityTypeId = tx.executeSql('select odoo_record_id from mail_activity_type_app where account_id = ? AND id >= ?', [instance_id, fetchedEntries.rows.item(record).activity_type_id]);
                var activity_user = tx.executeSql('SELECT id, odoo_record_id FROM res_users_app WHERE id = ?', [fetchedEntries.rows.item(record).user_id]);
                var project_id = false;
                var task_id = false;
                if (fetchedEntries.rows.item(record).project_id) {
                    var fetchProject = tx.executeSql('select id, odoo_record_id from project_project_app where id = ?', [fetchedEntries.rows.item(record).project_id]);
                    if (fetchProject.rows.length !== 0) {
                        project_id = fetchProject.rows.item(0).odoo_record_id;
                    }
                }
                if (fetchedEntries.rows.item(record).task_id) {
                    var fetchTask = tx.executeSql('select id, odoo_record_id from project_task_app where id = ?', [fetchedEntries.rows.item(record).task_id]);
                    if (fetchTask.rows.length !== 0) {
                        task_id = fetchTask.rows.item(0).odoo_record_id;
                    }
                }
                timesheetEntries.push({
                    'local_record_id': fetchedEntries.rows.item(record).id,
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
                    'res_id': fetchedEntries.rows.item(record).resId
                });
            }
        });
        return timesheetEntries;
    }

    function fetchAllActivities(instance_id) {
        var db = LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
        var timesheetEntries = [];
        db.transaction(function (tx) {
            var fetchedEntries = tx.executeSql('select * from mail_activity_app where account_id = ?', [instance_id]);
            for (var activity = 0; activity < fetchedEntries.rows.length; activity++) {
                timesheetEntries.push({
                    'id': fetchedEntries.rows.item(activity).id,
                    'odoo_record_id': fetchedEntries.rows.item(activity).odoo_record_id
                });
            }
        });
        return timesheetEntries;
    }

    function update_instance_date(instance_id) {
        var db = LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
        var timesheetEntries = [];
        db.transaction(function (tx) {
            tx.executeSql('update users set last_modified = ? where id = ?', [new Date().toISOString(), instance_id]);
        });
    }

    function update_timesheet_entries(timesheet_entries, instance_id) {
        if (timesheet_entries === undefined) {
            return;
        }
        var db = LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
        var fetchedTimesheets = timesheet_entries.fetchedTimesheets;
        db.transaction(function (tx) {
            for (var record = 0; record < fetchedTimesheets.length; record++) {
                tx.executeSql('update account_analytic_line_app set odoo_record_id = ?,last_modified = ? where id = ?', [fetchedTimesheets[record].odoo_record_id, new Date().toISOString(), fetchedTimesheets[record].local_record_id]);
            }

            var deletedRecords = [];
            var ids_array = '';
            if (timesheet_entries.fetch_all_records) {
                ids_array = timesheet_entries.existing_records.join(", ");
                deletedRecords = tx.executeSql('select id from account_analytic_line_app where account_id = ' + instance_id + ' AND odoo_record_id != 0 AND odoo_record_id not in (' + ids_array + ')');
            } else {
                ids_array = timesheet_entries.deleted_records.join(", ");
                deletedRecords = tx.executeSql('select id from account_analytic_line_app where account_id = ' + instance_id + ' AND odoo_record_id != 0 AND odoo_record_id in (' + ids_array + ')');
            }
            for (var delete_rec = 0; delete_rec < deletedRecords.rows.length; delete_rec++) {
                tx.executeSql('delete from account_analytic_line_app where id =  ?', [deletedRecords.rows.item(delete_rec).id]);
            }
        });
    }

    function update_activity_entries(activity_entries) {
        var db = LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
        if (activity_entries === undefined) {
            return;
        }
        db.transaction(function (tx) {
            for (var record = 0; record < activity_entries.length; record++) {
                tx.executeSql('update mail_activity_app set odoo_record_id = ? where id = ?', [activity_entries[record].odoo_record_id, activity_entries[record].local_record_id]);
            }
        });
    }

    function create_contacts(contacts, instance_id) {
        if (contacts === undefined) {
            return;
        }
        var db = LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
        db.transaction(function (tx) {
            for (var contact = 0; contact < contacts.length; contact++) {
                var result = tx.executeSql('SELECT id, COUNT(*) AS count FROM res_users_app WHERE odoo_record_id = ? AND account_id = ?', [contacts[contact].id, parseInt(instance_id)]);
                var length = result.rows.length;
                if (result.rows.length == 1 && result.rows.item(0).id == null) {
                    length = 0;
                }
                if (length > 0) {
                    tx.executeSql('update res_users_app set name = ?,share = ?,active = ? where id = ?', [contacts[contact].name, contacts[contact].share ? 1 : 0, contacts[contact].active ? 1 : 0, result.rows.item(0).id]);
                } else {
                    tx.executeSql('INSERT INTO res_users_app (account_id, name, odoo_record_id, share, active) VALUES (?, ?, ?, ?, ?)', [instance_id, contacts[contact].name, contacts[contact].id, contacts[contact].share ? 1 : 0, contacts[contact].active ? 1 : 0]);
                }
            }
        });
    }

    function create_projects(projects, instance_id) {
        var db = LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
        if (projects === undefined) {
            return;
        }
        db.transaction(function (tx) {
            var fetchedProjects = projects.projects;
            for (var project = 0; project < fetchedProjects.length; project++) {
                var result = tx.executeSql('SELECT id, COUNT(*) AS count FROM project_project_app WHERE odoo_record_id = ? AND account_id = ?', [fetchedProjects[project].id, parseInt(instance_id)]);
                var parent_project_id = false;
                if (fetchedProjects[project].parent_id.length) {
                    var parent_query = tx.executeSql('SELECT id, COUNT(*) AS count FROM project_project_app WHERE odoo_record_id = ? AND account_id = ?', [fetchedProjects[project].parent_id[0], parseInt(instance_id)]);
                    if (parent_query.rows.length !== 0) {
                        parent_project_id = parent_query.rows.item(0).id;
                    }
                }
                if (result.rows.item(0).count === 0) {
                    tx.executeSql('INSERT INTO project_project_app \
                        (name, account_id, parent_id, planned_start_date, \
                        planned_end_date, allocated_hours, favorites, last_modified, last_update_status, description,  \
                        odoo_record_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', [fetchedProjects[project].name, parseInt(instance_id), parent_project_id, fetchedProjects[project].date_start, fetchedProjects[project].date, fetchedProjects[project].allocated_hours, fetchedProjects[project].is_favorite, new Date().toISOString(), fetchedProjects[project].last_update_status, fetchedProjects[project].description, fetchedProjects[project].id]);
                } else {
                    tx.executeSql('update project_project_app set name = ?,account_id = ?, parent_id = ?, planned_start_date = ?, \
                        planned_end_date = ?, allocated_hours = ?, favorites = ?, last_update_status = ?, description = ?, last_modified = ?, \
                        odoo_record_id = ? where id = ?', [fetchedProjects[project].name, parseInt(instance_id), parent_project_id, fetchedProjects[project].date_start, fetchedProjects[project].date, fetchedProjects[project].allocated_hours, fetchedProjects[project].is_favorite, fetchedProjects[project].last_update_status, fetchedProjects[project].description, new Date().toISOString(), fetchedProjects[project].id, result.rows.item(0).id]);
                }
            }
            var deletedRecords = [];
            var ids_array = '';
            if (projects.fetch_all_records) {
                ids_array = projects.existing_projects.join(", ");
                deletedRecords = tx.executeSql('select id from project_project_app where account_id = ' + instance_id + ' AND odoo_record_id not in (' + ids_array + ')');
            } else {
                ids_array = projects.deleted_records.join(", ");
                deletedRecords = tx.executeSql('select id from project_project_app where account_id = ' + instance_id + ' AND odoo_record_id in (' + ids_array + ')');
            }
            for (var delete_rec = 0; delete_rec < deletedRecords.rows.length; delete_rec++) {
                tx.executeSql('delete from account_analytic_line_app where project_id =  ?', [deletedRecords.rows.item(delete_rec).id]);
                tx.executeSql('delete from project_task_app where project_id =  ?', [deletedRecords.rows.item(delete_rec).id]);
                tx.executeSql('update project_project_app set parent_id = NULL where parent_id = ?', [deletedRecords.rows.item(delete_rec).id]);
                tx.executeSql('delete from project_project_app where id =  ?', [deletedRecords.rows.item(delete_rec).id]);
            }
        });
    }

    function create_tasks(tasks, instance_id) {
        var db = LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);

        if (tasks === undefined) {
            return;
        }
        db.transaction(function (tx) {
            var fetchedTasks = tasks.fetchedTasks;
            for (var task = 0; task < fetchedTasks.length; task++) {
                var result = tx.executeSql('SELECT id, start_date, COUNT(*) AS count FROM project_task_app WHERE odoo_record_id = ? AND account_id = ?', [fetchedTasks[task].id, parseInt(instance_id)]);
                var parent_task_id = false;
                if (fetchedTasks[task].parent_id.length) {
                    var parent_query = tx.executeSql('SELECT id, COUNT(*) AS count FROM project_task_app WHERE odoo_record_id = ? AND account_id = ?', [fetchedTasks[task].parent_id[0], parseInt(instance_id)]);
                    if (parent_query.rows.length !== 0) {
                        parent_task_id = parent_query.rows.item(0).id;
                    }
                }
                var project_id = false;
                var sub_project_id = false;
                if (fetchedTasks[task].project_id.length) {
                    var parent_query = tx.executeSql('SELECT id, parent_id, COUNT(*) AS count FROM project_project_app WHERE odoo_record_id = ? AND account_id = ?', [fetchedTasks[task].project_id[0], parseInt(instance_id)]);
                    if (parent_query.rows.length !== 0) {
                        project_id = parent_query.rows.item(0).id;
                        if (parent_query.rows.item(0).parent_id) {
                            project_id = parent_query.rows.item(0).parent_id;
                            sub_project_id = parent_query.rows.item(0).id;
                        }
                    }
                }
                var user_id = false;
                if (fetchedTasks[task].user_ids.length) {
                    console.log('\n\n fetchedTasks[task].user_ids', fetchedTasks[task].user_ids);
                    var parent_query = tx.executeSql('SELECT id, COUNT(*) AS count FROM res_users_app WHERE odoo_record_id IN (' + fetchedTasks[task].user_ids.join(", ") + ') AND account_id = ?', [parseInt(instance_id)]);
                    if (parent_query.rows.length !== 0) {
                        user_id = parent_query.rows.item(0).id;
                    }
                }
                console.log('\n\n fetchedTasks[task]', fetchedTasks[task].date_start);
                var start_date = fetchedTasks[task].date_start;
                if (start_date == undefined) {
                    start_date = false;
                }
                if (result.rows.item(0).count === 0) {
                    tx.executeSql('INSERT INTO project_task_app \
                        (name, account_id, project_id, sub_project_id, parent_id, \
                        deadline, initial_planned_hours, favorites, description, \
                        state, last_modified, odoo_record_id, user_id, start_date, end_date) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', [fetchedTasks[task].name, parseInt(instance_id), project_id, sub_project_id, parent_task_id, fetchedTasks[task].date_deadline, fetchedTasks[task].planned_hours, fetchedTasks[task].priority, fetchedTasks[task].description, fetchedTasks[task].stage_id[1], new Date().toISOString(), fetchedTasks[task].id, user_id, start_date, fetchedTasks[task].date_end]);
                } else {
                    if (start_date == false) {
                        start_date = result.rows.item(0).start_date;
                    }
                    tx.executeSql('UPDATE project_task_app set name = ?, account_id = ?, project_id = ?, sub_project_id = ?, parent_id = ?, \
                        deadline = ?, initial_planned_hours = ?, favorites = ?, description = ?, \
                        state = ?, last_modified = ?, odoo_record_id = ?, user_id = ?, start_date = ?, end_date = ? where id = ?', [fetchedTasks[task].name, parseInt(instance_id), project_id, sub_project_id, parent_task_id, fetchedTasks[task].date_deadline, fetchedTasks[task].planned_hours, fetchedTasks[task].priority, fetchedTasks[task].description, fetchedTasks[task].stage_id[1], new Date().toISOString(), fetchedTasks[task].id, user_id, start_date, fetchedTasks[task].date_end, result.rows.item(0).id]);
                }
            }
            var deletedRecords = [];
            var ids_array = '';
            if (tasks.fetch_all_records) {
                ids_array = tasks.existing_tasks.join(", ");
                deletedRecords = tx.executeSql('select id from project_task_app where account_id = ' + instance_id + ' AND odoo_record_id != 0 AND odoo_record_id not in (' + ids_array + ')');
            } else {
                ids_array = tasks.deleted_records.join(", ");
                deletedRecords = tx.executeSql('select id from project_task_app where account_id = ' + instance_id + ' AND odoo_record_id != 0 AND odoo_record_id in (' + ids_array + ')');
            }
            for (var delete_rec = 0; delete_rec < deletedRecords.rows.length; delete_rec++) {
                tx.executeSql('delete from account_analytic_line_app where task_id =  ?', [deletedRecords.rows.item(delete_rec).id]);
                tx.executeSql('update project_task_app set parent_id = NULL where id = ?', [deletedRecords.rows.item(delete_rec).id]);
                tx.executeSql('delete from project_task_app where id =  ?', [deletedRecords.rows.item(delete_rec).id]);
            }
        });
    }

    function get_all_tasks(instance_id, last_modified) {
        var db = LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
        var list_of_tasks = [];
        db.transaction(function (tx) {
            var tasks = tx.executeSql('select * from project_task_app where account_id = ? AND (last_modified > ? OR odoo_record_id is NULL)', [instance_id, last_modified]);
            for (var task = 0; task < tasks.rows.length; task++) {
                var project_id = tx.executeSql('select id, odoo_record_id from project_project_app where id = ?', [tasks.rows.item(task).project_id]);
                var sub_project_id = tx.executeSql('select id, odoo_record_id from project_project_app where id = ?', [tasks.rows.item(task).sub_project_id]);
                var task_id = tx.executeSql('select id, odoo_record_id from project_task_app where id = ?', [tasks.rows.item(task).parent_id]);
                var user_id = tx.executeSql('select id, odoo_record_id from res_users_app where id = ?', [tasks.rows.item(task).user_id]);
                var context_project = tx.executeSql('select project_id from project_task_app where id=?', [tasks.rows.item(task).id]);
                list_of_tasks.push({
                    'local_record_id': tasks.rows.item(task).id,
                    'name': tasks.rows.item(task).name,
                    'project_id': tasks.rows.item(task).project_id ? project_id.rows.item(0).odoo_record_id : false,
                    'parent_id': tasks.rows.item(task).parent_id ? task_id.rows.item(0).odoo_record_id : false,
                    'deadline': tasks.rows.item(task).deadline,
                    'sub_project_id': tasks.rows.item(task).sub_project_id ? sub_project_id.rows.item(0).odoo_record_id : false,
                    'user_id': tasks.rows.item(task).user_id ? user_id.rows.item(0).odoo_record_id : false,
                    'initial_planned_hours': tasks.rows.item(task).initial_planned_hours,
                    'favorites': tasks.rows.item(task).favorites,
                    'last_modified': tasks.rows.item(task).last_modified,
                    'state': tasks.rows.item(task).state,
                    'date_start': tasks.rows.item(task).start_date,
                    'date_end': tasks.rows.item(task).end_date,
                    'description': tasks.rows.item(task).description,
                    'odoo_record_id': tasks.rows.item(task).odoo_record_id
                });
            }
        });
        return list_of_tasks;
    }

    function set_tasks(created_tasks, instance_id) {
        if (created_tasks === undefined) {
            return;
        }
        var db = LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
        db.transaction(function (tx) {
            for (var created_task = 0; created_task < created_tasks.length; created_task++) {
                tx.executeSql('update project_task_app set odoo_record_id = ?, last_modified = ? where id = ?', [created_tasks[created_task].odoo_record_id, new Date().toISOString(), created_tasks[created_task].local_record_id]);
            }
        });
    }

    function create_activity_types(activities, instance_id) {
        if (activities === undefined) {
            return;
        }
        var db = LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
        db.transaction(function (tx) {
            for (var activity = 0; activity < activities.length; activity++) {
                var existing_activity = tx.executeSql('select count(*) AS count from mail_activity_type_app where account_id = ? AND odoo_record_id = ?', [instance_id, activities[activity].id]);
                if (existing_activity.rows.item(0).count == 0) {
                    tx.executeSql('INSERT INTO mail_activity_type_app \
                        (account_id, name, odoo_record_id) VALUES \
                        (?, ?, ?)', [instance_id, activities[activity].name, activities[activity].id]);
                }
            }
        });
    }

    function create_activities(activities, instance_id) {
        if (activities === undefined) {
            return;
        }
        var db = LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
        db.transaction(function (tx) {
            for (var activity = 0; activity < activities.length; activity++) {
                var existing_activity = tx.executeSql('select id, count(*) AS count from mail_activity_app where account_id = ? AND odoo_record_id = ?', [instance_id, activities[activity].id]);
                var activity_type_id = tx.executeSql('select id from mail_activity_type_app where account_id = ? AND odoo_record_id = ?', [instance_id, activities[activity].activity_type_id[0]]);
                var user_id = tx.executeSql('select id from res_users_app where account_id = ? AND odoo_record_id = ?', [instance_id, activities[activity].user_id[0]]);
                if (existing_activity.rows.item(0).count == 0) {
                    if (activities[activity].res_model == 'project.project') {
                        var project_id = tx.executeSql('select id from project_project_app where account_id = ? AND odoo_record_id = ?', [instance_id, activities[activity].res_id]);
                        tx.executeSql('INSERT INTO mail_activity_app \
                            (account_id, activity_type_id, summary, due_date, user_id, notes, odoo_record_id, last_modified, project_id, link_id, state)\
                            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', [instance_id, activity_type_id.rows.item(0).id, activities[activity].summary, activities[activity].date_deadline, user_id.rows.item(0).id, activities[activity].note, activities[activity].id, new Date().toISOString(), project_id.rows.item(0).id, 1, 'schedule']);
                    } else if (activities[activity].res_model == 'project.task') {
                        var task_id = tx.executeSql('select id from project_task_app where account_id = ? AND odoo_record_id = ?', [instance_id, parseInt(activities[activity].res_id)]);
                        tx.executeSql('INSERT INTO mail_activity_app \
                            (account_id, activity_type_id, summary, due_date, user_id, notes, odoo_record_id, last_modified, task_id, link_id, state)\
                            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', [instance_id, activity_type_id.rows.item(0).id, activities[activity].summary, activities[activity].date_deadline, user_id.rows.item(0).id, activities[activity].note, activities[activity].id, new Date().toISOString(), task_id.rows.item(0).id, 2, 'schedule']);
                    } else {
                        tx.executeSql('INSERT INTO mail_activity_app \
                            (account_id, activity_type_id, summary, due_date, user_id, notes, odoo_record_id, last_modified, resModel, resId, link_id, state)\
                            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', [instance_id, activity_type_id.rows.item(0).id, activities[activity].summary, activities[activity].date_deadline, user_id.rows.item(0).id, activities[activity].note, activities[activity].id, new Date().toISOString(), activities[activity].res_model, activities[activity].res_id, 3, 'schedule']);
                    }
                } else {
                    tx.executeSql('update mail_activity_app set activity_type_id = ?, summary = ?, due_date = ?, user_id = ?, notes = ?, last_modified = ?\
                        where id = ?', [activity_type_id.rows.item(0).id, activities[activity].summary, activities[activity].date_deadline, user_id.rows.item(0).id, activities[activity].note, new Date().toISOString(), existing_activity.rows.item(0).id]);
                }
            }
        });
    }

    function done_activities(activities, instance_id) {
        if (activities === undefined) {
            return;
        }
        var db = LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
        db.transaction(function (tx) {
            for (var activity = 0; activity < activities.length; activity++) {
                var existing_activity = tx.executeSql('select id, count(*) AS count from mail_activity_app where account_id = ? AND odoo_record_id = ?', [instance_id, activities[activity]]);
                if (existing_activity.rows.length) {
                    tx.executeSql('update mail_activity_app set state = ? where id = ?', ['done', existing_activity.rows.item(0).id]);
                }
            }
        });
    }

    function deleteData(recordId) {
        var db = LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);

        db.transaction(function (tx) {
            var result = tx.executeSql('DELETE FROM users where id =' + parseInt(recordId));
        });
    }

    ListModel {
        id: recordModel
    }
    Rectangle {
        id: sycchronizationHeader
        width: parent.width
        height: isDesktop() ? 60 : 120
        anchors.top: parent.top
        anchors.topMargin: isDesktop() ? 60 : 120
        color: "#FFFFFF"
        z: 1

        Rectangle {
            width: parent.width
            height: 2
            color: "#DDDDDD"
            anchors.bottom: parent.bottom
        }

        Row {
            id: row_id
            width: parent.width
            anchors.verticalCenter: parent.verticalCenter
            anchors.fill: parent
            spacing: isDesktop() ? 20 : 40
            anchors.left: parent.left
            anchors.leftMargin: isDesktop() ? issearchHeader ? 55 : 70 : issearchHeader ? -10 : 15
            anchors.right: parent.right
            anchors.rightMargin: isDesktop() ? 15 : 20

            Rectangle {
                id: header_tital
                visible: !issearchHeader
                color: "transparent"
                width: parent.width / 5
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height

                Row {
                    anchors.verticalCenter: parent.verticalCenter

                    Label {
                        text: "Synchronization"
                        font.pixelSize: isDesktop() ? 20 : 40
                        anchors.verticalCenter: parent.verticalCenter
                        font.bold: true
                        color: "#121944"
                    }
                }
            }

            Rectangle {
                id: header_btnADD
                visible: !issearchHeader
                color: "transparent"
                width: parent.width / 5
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                anchors.right: parent.right

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: isDesktop() ? 10 : 20
                    anchors.right: parent.right

                    ToolButton {
                        id: search_id
                        width: isDesktop() ? 40 : 80
                        height: isDesktop() ? 35 : 80
                        background: Rectangle {
                            color: "transparent"
                        }
                        contentItem: Ubuntu.Icon {
                            name: "search"
                        }
                        onClicked: {
                            issearchHeader = true;
                        }
                    }
                }
            }
            Rectangle {
                id: search_header
                visible: issearchHeader
                width: parent.width
                anchors.verticalCenter: parent.verticalCenter
                ToolButton {
                    id: back_idn
                    width: isDesktop() ? 35 : 80
                    height: isDesktop() ? 35 : 80
                    anchors.verticalCenter: parent.verticalCenter
                    background: Rectangle {
                        color: "transparent"
                    }
                    contentItem: Ubuntu.Icon {
                        name: "back"
                    }
                    onClicked: {
                        issearchHeader = false;
                        searchField.text = "";
                    }
                }

                // Full-width TextField
                TextField {
                    id: searchField
                    placeholderText: "Search..."
                    anchors.left: back_idn.right
                    anchors.leftMargin: isDesktop() ? 0 : 5
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    onTextChanged: {
                        filtersynList(searchField.text);
                    }
                }
            }
        }
    }
    Rectangle {
        width: parent.width
        height: parent.height
        anchors.top: parent.top
        anchors.topMargin: isDesktop() ? 65 : 120
        anchors.left: parent.left
        anchors.leftMargin: isDesktop() ? 70 : 20
        anchors.right: parent.right
        anchors.rightMargin: isDesktop() ? 10 : 20
        anchors.bottom: parent.bottom
        anchors.bottomMargin: isDesktop() ? 0 : 100
        color: "#ffffff"

        Rectangle {
            // spacing: 0
            anchors.fill: parent
            anchors.top: searchId.bottom
            anchors.topMargin: isDesktop() ? 68 : 170
            border.color: "#CCCCCC"
            border.width: isDesktop() ? 1 : 2

            Flickable {
                id: listView
                anchors.fill: parent
                width: parent.width
                contentHeight: column.height
                clip: true

                Column {
                    id: column
                    width: parent.width
                    spacing: 0

                    Repeater {
                        model: recordModel
                        delegate: Rectangle {
                            width: parent.width
                            height: isDesktop() ? 80 : 130
                            color: "#FFFFFF"
                            border.color: "#CCCCCC"
                            border.width: isDesktop() ? 1 : 2
                            // radius: 10

                            Column {
                                spacing: 0
                                anchors.fill: parent

                                Row {
                                    width: parent.width
                                    height: isDesktop() ? 80 : 130
                                    spacing: 20

                                    Rectangle {
                                        id: imgmodulename
                                        width: isDesktop() ? 50 : 90
                                        height: isDesktop() ? 50 : 90
                                        color: "#0078d4"
                                        radius: 80
                                        border.color: "#0056a0"
                                        border.width: 2
                                        anchors.rightMargin: 10

                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.leftMargin: 10

                                        Text {
                                            text: model.name.charAt(0).toUpperCase()
                                            color: "#fff"
                                            anchors.centerIn: parent
                                            font.pixelSize: isDesktop() ? 20 : 40
                                        }
                                    }

                                    Column {
                                        spacing: 5
                                        width: parent.width - 280
                                        anchors.centerIn: parent

                                        Text {
                                            text: model.name
                                            font.pixelSize: isDesktop() ? 20 : 40
                                            color: "#000"
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            text: (model.link.length > 40) ? model.link.substring(0, 40) + "..." : model.link
                                            font.pixelSize: isDesktop() ? 18 : 30
                                            color: "#0078d4"
                                            elide: Text.ElideNone
                                        }
                                    }

                                    TSButton {

                                        width: isDesktop() ? 40 : 90
                                        height: isDesktop() ? 40 : 90

                                        background: Rectangle {
                                            color: "transparent"
                                            radius: 10
                                            border.color: "transparent"
                                        }
                                        Image {
                                            source: "images/reload.png"
                                            anchors.fill: parent
                                            smooth: true
                                        }
                                        anchors.right: parent.right
                                        anchors.rightMargin: 20
                                        anchors.verticalCenter: parent.verticalCenter
                                        onClicked: {
                                            if (model.connect_with == 1) {
                                                loading = true;
                                                var failed_sync = false;
                                                loadingMessage = 'Synchronization for ' + model.name + '!';
                                                var filled_password = model.api_key;
                                                var last_user_update = getLastModified(model.user_id);
                                                python.call("backend.fetch_projects", [model.link, model.username, filled_password,
                                                    {
                                                        'isTextInputVisible': true,
                                                        'input_text': model.database
                                                    },
                                                    last_user_update], function (projects) {
                                                    if (projects === undefined) {
                                                        loading = false;
                                                        failed_sync = true;
                                                        return;
                                                    }
                                                    create_projects(projects, model.user_id);
                                                    python.call("backend.fetch_contacts", [model.link, model.username, filled_password,
                                                        {
                                                            'isTextInputVisible': true,
                                                            'input_text': model.database
                                                        },
                                                        last_user_update], function (contacts) {
                                                        create_contacts(contacts, model.user_id);
                                                        var fetchedAllTasks = get_all_tasks(model.user_id, last_user_update);
                                                        python.call('backend.create_update_tasks', [model.link, model.username, filled_password,
                                                            {
                                                                'isTextInputVisible': true,
                                                                'input_text': model.database
                                                            },
                                                            fetchedAllTasks, last_user_update], function (obj_data) {
                                                            set_tasks(obj_data.settled_tasks, model.user_id);
                                                            create_tasks(obj_data.updated_tasks, model.user_id);
                                                            var timesheets = fetchTimesheets(model.user_id);
                                                            python.call("backend.create_timesheets", [model.link, model.username, filled_password,
                                                                {
                                                                    'isTextInputVisible': true,
                                                                    'input_text': model.database
                                                                },
                                                                timesheets], function (res) {
                                                                update_timesheet_entries(res, model.user_id);
                                                            });
                                                            python.call('backend.fetch_activity_type', [model.link, model.username, filled_password,
                                                                {
                                                                    'isTextInputVisible': true,
                                                                    'input_text': model.database
                                                                },
                                                                last_user_update], function (activity_types) {
                                                                create_activity_types(activity_types, model.user_id);
                                                                var fetchedallActivities = fetchAllActivities(model.user_id);
                                                                python.call('backend.fetch_activities', [model.link, model.username, filled_password,
                                                                    {
                                                                        'isTextInputVisible': true,
                                                                        'input_text': model.database
                                                                    },
                                                                    last_user_update, fetchedallActivities], function (activities_dict) {
                                                                    if (activities_dict === undefined) {
                                                                        loading = false;
                                                                        return;
                                                                    }
                                                                    create_activities(activities_dict.activities_list, model.user_id);
                                                                    done_activities(activities_dict.done_activities, model.user_id);
                                                                    loading = false;
                                                                    update_instance_date(model.user_id);
                                                                });
                                                            });
                                                            var activities = fetchActivities(model.user_id);
                                                            python.call("backend.create_activities", [model.link, model.username, filled_password,
                                                                {
                                                                    'isTextInputVisible': true,
                                                                    'input_text': model.database
                                                                },
                                                                activities], function (res) {
                                                                update_activity_entries(res);
                                                            });
                                                        });

                                                        passwordInput.text = "";
                                                        passwordDialog.close();
                                                    });
                                                });
                                            } else {
                                                passwordDialog.open();
                                            }
                                        }
                                    }
                                    Dialog {
                                        id: passwordDialog
                                        title: "Enter Password"
                                        x: (parent.width - width) / 2
                                        y: -150
                                        standardButtons: Dialog.Ok | Dialog.Cancel

                                        contentItem: Column {
                                            spacing: 10
                                            padding: 20

                                            Row {
                                                spacing: 5

                                                TextField {
                                                    id: passwordInput
                                                    placeholderText: "Password"
                                                    echoMode: isPasswordVisible ? TextInput.Normal : TextInput.Password
                                                }

                                                Button {
                                                    height: passwordInput.height
                                                    width: passwordInput.height
                                                    Image {
                                                        source: isPasswordVisible ? "images/show.png" : "images/hide.png"
                                                        anchors.fill: parent
                                                        smooth: true
                                                    }
                                                    onClicked: {
                                                        isPasswordVisible = !isPasswordVisible;
                                                    }
                                                }
                                            }
                                        }

                                        onAccepted: {
                                            loading = true;
                                            var failed_sync = false;
                                            loadingMessage = 'Synchronization for ' + model.name + '!';
                                            var filled_password = passwordInput.text;
                                            var last_user_update = getLastModified(model.user_id);
                                            python.call("backend.fetch_projects", [model.link, model.username, filled_password,
                                                {
                                                    'isTextInputVisible': true,
                                                    'input_text': model.database
                                                },
                                                last_user_update], function (projects) {
                                                if (projects === undefined) {
                                                    loading = false;
                                                    failed_sync = true;
                                                    return;
                                                }
                                                create_projects(projects, model.user_id);
                                                python.call("backend.fetch_contacts", [model.link, model.username, filled_password,
                                                    {
                                                        'isTextInputVisible': true,
                                                        'input_text': model.database
                                                    },
                                                    last_user_update], function (contacts) {
                                                    create_contacts(contacts, model.user_id);
                                                    var fetchedAllTasks = get_all_tasks(model.user_id, last_user_update);
                                                    python.call('backend.create_update_tasks', [model.link, model.username, filled_password,
                                                        {
                                                            'isTextInputVisible': true,
                                                            'input_text': model.database
                                                        },
                                                        fetchedAllTasks, last_user_update], function (obj_data) {
                                                        set_tasks(obj_data.settled_tasks, model.user_id);
                                                        create_tasks(obj_data.updated_tasks, model.user_id);
                                                        var timesheets = fetchTimesheets(model.user_id);
                                                        python.call("backend.create_timesheets", [model.link, model.username, filled_password,
                                                            {
                                                                'isTextInputVisible': true,
                                                                'input_text': model.database
                                                            },
                                                            timesheets], function (res) {
                                                            update_timesheet_entries(res, model.user_id);
                                                        });
                                                        python.call('backend.fetch_activity_type', [model.link, model.username, filled_password,
                                                            {
                                                                'isTextInputVisible': true,
                                                                'input_text': model.database
                                                            },
                                                            last_user_update], function (activity_types) {
                                                            create_activity_types(activity_types, model.user_id);
                                                            var fetchedallActivities = fetchAllActivities(model.user_id);
                                                            python.call('backend.fetch_activities', [model.link, model.username, filled_password,
                                                                {
                                                                    'isTextInputVisible': true,
                                                                    'input_text': model.database
                                                                },
                                                                last_user_update, fetchedallActivities], function (activities_dict) {
                                                                if (activities_dict === undefined) {
                                                                    loading = false;
                                                                    return;
                                                                }
                                                                create_activities(activities_dict.activities_list, model.user_id);
                                                                done_activities(activities_dict.done_activities, model.user_id);
                                                                loading = false;
                                                                update_instance_date(model.user_id);
                                                            });
                                                        });
                                                        var activities = fetchActivities(model.user_id);
                                                        python.call("backend.create_activities", [model.link, model.username, filled_password,
                                                            {
                                                                'isTextInputVisible': true,
                                                                'input_text': model.database
                                                            },
                                                            activities], function (res) {
                                                            update_activity_entries(res);
                                                        });
                                                    });

                                                    passwordInput.text = "";
                                                    passwordDialog.close();
                                                });
                                            });
                                        }

                                        onRejected: {
                                            console.log("Dialog cancelled");
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            Item {
                id: loader
                visible: loading
                width: parent.width
                height: parent.height

                Rectangle {
                    width: parent.width
                    height: parent.height
                    color: "lightgray"
                    opacity: 0.8
                    BusyIndicator {
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        anchors.centerIn: parent
                        text: loadingMessage
                        font.pixelSize: 50
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        initializeDatabase();
        queryData();
        issearchHeader = false;
    }

    signal logInPage(string Accountuser_id)
    signal goToLogin
    signal backPage
}
