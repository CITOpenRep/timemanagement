.import QtQuick.LocalStorage 2.7 as Sql

function getLastSyncStatus(accountId) {
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    var result = "";

    db.transaction(function(tx) {
        // 1. Fetch the latest sync status for display
        var rs = tx.executeSql(
                    "SELECT status, timestamp FROM sync_report WHERE account_id = ? ORDER BY timestamp DESC LIMIT 1",
                    [accountId]
                    );
        if (rs.rows.length > 0) {
            var status = rs.rows.item(0).status;
            var timestamp = rs.rows.item(0).timestamp;
            var date = new Date(timestamp);
            var readableTime = date.toLocaleString();
            result = status + " @ " + readableTime;
        }
        /*
        // 2. Delete older entries (keep only latest 5 logs)
        tx.executeSql(
            "DELETE FROM sync_report " +
            "WHERE id NOT IN ( " +
            "    SELECT id FROM sync_report " +
            "    WHERE account_id = ? " +
            "    ORDER BY timestamp DESC " +
            "    LIMIT 5 " +
            ") AND account_id = ?",
            [accountId, accountId]
        );*/
    });

    return result;
}

function getYesterday() {
    var d = new Date();
    d.setDate(d.getDate() - 1);
    return d.toISOString();
}


function insertData(name, link, database, username, selectedconnectwithId, apikey) {
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);

    db.transaction(function(tx) {
        var result = tx.executeSql('SELECT id, COUNT(*) AS count FROM users WHERE link = ? AND database = ? AND username = ?', [link, database, username]);
        if (result.rows.item(0).count === 0) {
            var api_key_text = ' ';
            if (selectedconnectwithId == 1) {
                api_key_text = apikey;
            }
            tx.executeSql('INSERT INTO users (name, link, database, username, connectwith_id, api_key) VALUES (?, ?, ?, ?, ?, ?)', [name, link, database, username, selectedconnectwithId, api_key_text]);
            var newResult = tx.executeSql('SELECT id FROM users WHERE link = ? AND database = ? AND username = ?', [link, database, username]);
            currentUserId = newResult.rows.item(0).id;
        } else {
            currentUserId = result.rows.item(0).id;
        }
    });
}

function queryData() {
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);

    db.transaction(function(tx) {
        var result = tx.executeSql('SELECT * FROM users');
        accountsList = [];
        for (var i = 0; i < result.rows.length; i++) {
            accountsList.push({'user_id': result.rows.item(i).id, 'name': result.rows.item(i).name, 'link': result.rows.item(i).link, 'database': result.rows.item(i).database, 'username': result.rows.item(i).username})
        }
    });
    selectedconnectwithId = 1;
    connectwith.text = 'Connect With Api Key'
}

function accountlistDataGet(){
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    var accountlist = [];

    db.transaction(function(tx) {
        var result = tx.executeSql('SELECT * FROM users');
        for (var i = 0; i < result.rows.length; i++) {
            accountlist.push({'id': result.rows.item(i).id, 'name': result.rows.item(i).name})
        }
    })
    return accountlist

}

function fetch_projects(selectedAccountUserId) {
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    var projectList = []
    db.transaction(function(tx) {
        if(workpersonaSwitchState){
            var result = tx.executeSql('SELECT * FROM project_project_app WHERE account_id = ? AND parent_id IS 0', [selectedAccountUserId]);
        }else{
            var result = tx.executeSql('SELECT * FROM project_project_app WHERE id != ? AND account_id IS NULL AND parent_id IS 0', [selectedAccountUserId]);
        }
        for (var i = 0; i < result.rows.length; i++) {
            var child_projects = tx.executeSql('SELECT count(*) as count FROM project_project_app where parent_id = ?', [result.rows.item(i).id]);
            projectList.push({'id': result.rows.item(i).id, 'name': result.rows.item(i).name, 'projectkHasSubProject': true ? child_projects.rows.item(0).count > 0 : false})
        }
    })
    return projectList;
}

function fetch_sub_project(project_id) {
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    var subProjectsList = []
    db.transaction(function(tx) {
        if(workpersonaSwitchState){
            var child_projects = tx.executeSql('SELECT * FROM project_project_app where parent_id = ?', [project_id]);
        }else{
            var child_projects = tx.executeSql('SELECT * FROM project_project_app where account_id IS NULL AND parent_id = ?', [project_id]);
        }
        for (var i = 0; i < child_projects.rows.length; i++) {
            subProjectsList.push({'id': child_projects.rows.item(i).id, 'name': child_projects.rows.item(i).name})
        }
    })
    return subProjectsList;
}

function fetch_tasks_list(project_id, sub_project_id) {
    var workpersonaSwitchState = true;
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    var tasks_list = []
    db.transaction(function(tx) {
        if(workpersonaSwitchState){
            var result = tx.executeSql('SELECT * FROM project_task_app where project_id = ? AND account_id != 0 AND sub_project_id = ?', [project_id, sub_project_id]);
        }else{
            var result = tx.executeSql('SELECT * FROM project_task_app where account_id = 0 AND project_id = ? AND sub_project_id = ?', [project_id, sub_project_id]);
        }
        for (var i = 0; i < result.rows.length; i++) {
            var child_tasks = tx.executeSql('SELECT count(*) as count FROM project_task_app where parent_id = ?', [result.rows.item(i).id]);
            
            tasks_list.push({'id': result.rows.item(i).id, 'name': result.rows.item(i).name, 'taskHasSubTask': true ? child_tasks.rows.item(0).count > 0 : false,'parent_id':result.rows.item(i).parent_id})
        }
    })
    return tasks_list;
}

function fetch_sub_tasks(task_id) {
    var db = LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    
    var sub_tasks_list = []
    db.transaction(function(tx) {
        if(workpersonaSwitchState){
            var child_tasks = tx.executeSql('SELECT * FROM project_task_app where parent_id = ?', [task_id]);
        }else{
            var child_tasks = tx.executeSql('SELECT * FROM project_task_app where account_id IS NULL AND parent_id = ?', [task_id]);
        }
        for (var i = 0; i < child_tasks.rows.length; i++) {
            sub_tasks_list.push({'id': child_tasks.rows.item(i).id, 'name': child_tasks.rows.item(i).name})
        }
    })
    return sub_tasks_list
}

function timesheetData(data) {
    var db = LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    db.transaction(function(tx) {
        var unitAmount = 0
        if (data.isManualTimeRecord) {
            unitAmount = convTimeFloat(data.manualSpentHours)
        } else {
            unitAmount = convTimeFloat(data.spenthours)
        }
        tx.executeSql('INSERT INTO account_analytic_line_app \
            (account_id, record_date, project_id, task_id, name, sub_project_id, sub_task_id, quadrant_id,  \
            unit_amount, last_modified) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                      [data.instance_id, data.dateTime, data.project, data.task, data.description, data.subprojectId, data.subTask, data.quadrant, unitAmount, new Date().toISOString()]);

        datesmartBtnStart = ""
    });

}

function getAccountIdByName(accountName) {
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    var accountId = -1;  // default if not found

    db.transaction(function(tx) {
        var rs = tx.executeSql("SELECT id FROM users WHERE name = ?", [accountName]);
        if (rs.rows.length > 0) {
            accountId = rs.rows.item(0).id;
        }
    });

    return accountId;
}

function formatOdooDateTime(dateObj) {
    function pad(n) {
        return n < 10 ? '0' + n : n;
    }

    return dateObj.getFullYear() + "-" +
            pad(dateObj.getMonth() + 1) + "-" +
            pad(dateObj.getDate()) + " " +
            pad(dateObj.getHours()) + ":" +
            pad(dateObj.getMinutes()) + ":" +
            pad(dateObj.getSeconds());
}

function getCurrentOdooTimestamp() {
    const now = new Date();

    function pad(n) {
        return n < 10 ? '0' + n : n;
    }

    return now.getFullYear() + "-" +
            pad(now.getMonth() + 1) + "-" +
            pad(now.getDate()) + " " +
            pad(now.getHours()) + ":" +
            pad(now.getMinutes()) + ":" +
            pad(now.getSeconds());
}


function getOdooUsers(){
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    var assigneelist = [];

    db.transaction(function(tx) {
        var result1 = tx.executeSql('SELECT * FROM res_users_app');
        for (var i = 0; i < result1.rows.length; i++) {
            //                console.log("getAssigneeList: " + result1.rows.item(i).name)
            assigneelist.push({'id': result1.rows.item(i).id, 'name': result1.rows.item(i).name,'remoteid': result1.rows.item(i).odoo_record_id})
        }
    })
    return assigneelist

}

function updateOdooUsers(model) {
    const db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    model.clear();

    db.transaction(function(tx) {
        const result = tx.executeSql('SELECT name, odoo_record_id FROM res_users_app');
        for (let i = 0; i < result.rows.length; i++) {
            const row = result.rows.item(i);
            model.append({
                             name: row.name,
                             remoteid: row.odoo_record_id
                         });
        }
    });
}

function updateAccounts(model) {
    const db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    model.clear();

    db.transaction(function(tx) {
        const result = tx.executeSql('SELECT id, name FROM users');
        for (let i = 0; i < result.rows.length; i++) {
            model.append({
                             id: result.rows.item(i).id,
                             name: result.rows.item(i).name
                         });
        }
    });
}

function fetch_projects(instance_id, is_work_state) {
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    var projectList = [];
    db.transaction(function(tx) {
        if (is_work_state) {
            var projects = tx.executeSql('SELECT * FROM project_project_app\
             WHERE account_id = ? AND parent_id IS 0', [instance_id]);
        } else {
            var projects = tx.executeSql('SELECT * FROM project_project_app\
             WHERE account_id IS NULL');
        }
        for (var project = 0; project < projects.rows.length; project++) {
            var child_projects = tx.executeSql('SELECT count(*) as count FROM project_project_app\
             where parent_id = ?', [projects.rows.item(project).id]);
            projectList.push({'id': projects.rows.item(project).odoo_record_id,
                                 'name': projects.rows.item(project).name,
                                 'parent_id': projects.rows.item(project).parent_id,
                                 'projectHasSubProject': true ? child_projects.rows.item(0).count > 0 : false});
        }
    });
    return projectList;
}

function fetch_subprojects(instance_id, parent_project_id) {
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    var subprojectList = [];

    db.transaction(function(tx) {
        var result = tx.executeSql('SELECT * FROM project_project_app \
            WHERE account_id = ? AND parent_id = ?', [instance_id, parent_project_id]);

        for (var i = 0; i < result.rows.length; i++) {
            var row = result.rows.item(i);
            var child_projects = tx.executeSql('SELECT count(*) as count FROM project_project_app \
                WHERE parent_id = ?', [row.id]);

            subprojectList.push({
                                    id: row.odoo_record_id,
                                    name: row.name,
                                    parent_id: row.parent_id,
                                    recordId: row.odoo_record_id,
                                    projectHasSubProject: child_projects.rows.item(0).count > 0
                                });
        }
    });

    return subprojectList;
}

function fetch_subtasks(instance_id, parent_task_id) {
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    var subtaskList = [];

    db.transaction(function(tx) {
        var result = tx.executeSql('SELECT * FROM project_task_app \
            WHERE account_id = ? AND parent_id = ?', [instance_id, parent_task_id]);

        for (var i = 0; i < result.rows.length; i++) {
            var row = result.rows.item(i);
            subtaskList.push({
                                 id: row.odoo_record_id,
                                 name: row.name,
                                 parent_id: row.parent_id,
                                 id_val: row.odoo_record_id
                             });
        }
    });

    return subtaskList;
}


function validateAndCleanOdooURL(url) {
    // Strip trailing slash
    if (url.endsWith("/")) {
        url = url.slice(0, -1);
    }

    const pattern = new RegExp(
                      '^(https?:\\/\\/)?' +
                      '(([a-zA-Z0-9\\-\\.]+)\\.([a-zA-Z]{2,4})|' +
                      '(\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3})|' +
                      '\\[([a-fA-F0-9:\\.]+)\\])' +
                      '(\\:\\d+)?(\\/[-a-zA-Z0-9@:%_\\+.~#?&//=]*)?$',
                      'i'
                      );

    return {
        isValid: pattern.test(url),
        cleanedUrl: url
    };
}

function stripHtmlTags(html) {
    return html ? html.replace(/<[^>]*>/g, "") : "";
}

function getDatabasesFromOdooServer(odooUrl, callback) {
    var xhr = new XMLHttpRequest();
    xhr.open("POST", odooUrl + "/web/database/list");
    xhr.setRequestHeader("Content-Type", "application/json");

    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                try {
                    var response = JSON.parse(xhr.responseText);
                    if (response.result) {
                        callback(response.result);
                    } else {
                        console.error("Failed to get DB list: No result field.");
                        callback([]);
                    }
                } catch (e) {
                    console.error("JSON parse error:", e);
                    callback([]);
                }
            } else {
                console.error("Request failed with status", xhr.status);
                callback([]);
            }
        }
    };

    xhr.send("{}");
}

function populateProjectModelWithTaskCount(model, is_work_state) {
    model.clear();
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);

    db.transaction(function(tx) {
        var query = is_work_state
                ? 'SELECT * FROM project_project_app WHERE account_id IS NOT NULL ORDER BY last_modified DESC'
                : 'SELECT * FROM project_project_app WHERE account_id IS NULL ORDER BY last_modified DESC';

        var result = tx.executeSql(query);

        for (var i = 0; i < result.rows.length; i++) {
            var row = result.rows.item(i);
            var taskCountQuery = tx.executeSql(
                        'SELECT COUNT(*) AS count FROM project_task_app WHERE project_id = ? AND account_id = ?',
                        [row.id, row.account_id]
                        );

            var taskCount = (taskCountQuery.rows.length > 0) ? taskCountQuery.rows.item(0).count : 0;

            model.append({
                             id: row.id,
                             projectName: row.name,
                             allocatedHours: row.allocated_hours || "0",
                             startDate: row.planned_start_date || "",
                             endDate: row.planned_end_date || "",
                             deadline: row.planned_end_date || "",  // same as endDate
                             description: row.description || "",
                             colorPallet: row.color_pallet || "#cccccc",
                             recordId: row.id,
                             isFavorite: row.favorites === 1,
                             task_count: taskCount
                         });
        }
    });
}

function getColorFromOdooIndex(index) {
    //standard from odoo pallet
    const colorMap = [
                       "#FFFFFF", "#EB6E67", "#F39C5A", "#F6C342",
                       "#6CC1E1", "#854D76", "#ED8888", "#2C8397",
                       "#49597C", "#DE3F7C", "#45C486", "#9B6CC3"
                   ];
    return colorMap[index % colorMap.length];
}


function getToday() {
    return new Date().toISOString().slice(0, 10);
}
function getNextWeekRange() {
    const now = new Date();
    const day = now.getDay();
    const diffToNextMonday = day === 0 ? 1 : 8 - day;

    const nextMonday = new Date(now);
    nextMonday.setDate(now.getDate() + diffToNextMonday);

    const nextSunday = new Date(nextMonday);
    nextSunday.setDate(nextMonday.getDate() + 6);

    return {
        start: nextMonday.toISOString().slice(0, 10),
        end: nextSunday.toISOString().slice(0, 10)
    };
}

function getNextMonthRange() {
    const now = new Date();
    const nextMonthStart = new Date(now.getFullYear(), now.getMonth() + 1, 1);
    const nextMonthEnd = new Date(now.getFullYear(), now.getMonth() + 2, 0); // 0 = last day of previous month

    return {
        start: nextMonthStart.toISOString().slice(0, 10),
        end: nextMonthEnd.toISOString().slice(0, 10)
    };
}



