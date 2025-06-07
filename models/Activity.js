.import QtQuick.LocalStorage 2.7 as Sql


function queryActivityData(type, recordid) {
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    var workpersonaSwitchState = true;
    var filterActivityListData = [];
    var activitylist = [];
    var name = "";
    var notes = "";
    db.transaction(function (tx) {
        activityListModel.clear();
        if(workpersonaSwitchState) {
            if (!recordid){
                console.log("Gets all Activity records!");
                var existing_activities = tx.executeSql('select * from mail_activity_app where account_id is not NULL order by last_modified desc')
                if (type == 'pending') {
                    existing_activities = tx.executeSql('select * from mail_activity_app where account_id is not NULL AND state != "done" order by last_modified desc')
                } else if (type == 'done') {
                    existing_activities = tx.executeSql('select * from mail_activity_app where account_id is not NULL AND state = "done" order by last_modified desc')
                }
                else{
                    console.log("Getting all types of Activity");
                    existing_activities = tx.executeSql('select * from mail_activity_app where account_id is not NULL order by last_modified desc')
                }
            }
            else{
                console.log("Gets one Activity record!");
                var existing_activities = []
                if (type == 'pending') {
                    existing_activities = tx.executeSql('select * from mail_activity_app where account_id is not NULL AND state != "done" AND id = ? order by last_modified desc', [recordid])
                } else if (type == 'done') {
                    existing_activities = tx.executeSql('select * from mail_activity_app where account_id is not NULL AND state = "done" AND id = ? order by last_modified desc', [recordid])
                }
                else{
                    console.log("Getting all types of Activity");
                    existing_activities = tx.executeSql('select * from mail_activity_app where account_id is not NULL AND id = ? order by last_modified desc', [recordid])
                    var account_id = tx.executeSql('SELECT name FROM users WHERE id = ?',[existing_activities.rows.item(0).account_id]);
                    var accountName = account_id.rows.length > 0 ? account_id.rows.item(0).name || "" : "";
                }
 
            }
        } 
        else {
            var existing_activities = tx.executeSql('SELECT * FROM mail_activity_app where account_id IS NULL');
        }

        for (var activity = 0; activity < existing_activities.rows.length; activity++) {
            activitylist.push({'summary': existing_activities.rows.item(activity).summary, 
                'due_date': existing_activities.rows.item(activity).due_date, 
                'id': existing_activities.rows.item(activity).id, 'account_id': existing_activities.rows.item(activity).account_id, 
                'accountName': accountName, 'activity_type_id': existing_activities.rows.item(activity).activity_type_id,
                'notes': notes, 'name': name})
            filterActivityListData.push({'summary': existing_activities.rows.item(activity).summary, 'due_date': existing_activities.rows.item(activity).due_date, 'id': existing_activities.rows.item(activity).id})
        }
    })
    return activitylist
}

function filterActivityList(query) {
    activityListModel.clear();

        for (var i = 0; i < filterActivityListData.length; i++) {
            var entry = filterActivityListData[i];
            if (entry.summary.toLowerCase().includes(query.toLowerCase()) ||
                entry.due_date.toLowerCase().includes(query.toLowerCase())
                ) {
                activityListModel.append(entry);

            }
        }
}

function fetch_activity_types(selectedAccountUserId) {
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    var activity_type_list = []
    db.transaction(function (tx) {
        var activity_types = tx.executeSql('select * from mail_activity_type_app where account_id = ?', [selectedAccountUserId])
        for (var type = 0; type < activity_types.rows.length; type++) {
            activity_type_list.push({'id': activity_types.rows.item(type).id, 'name': activity_types.rows.item(type).name});
        }
    })
    return activity_type_list;
}

function editActivityData(data) {
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);

    db.transaction(function(tx) {
        // Update the record in the database
        tx.executeSql('UPDATE mail_activity_app SET \
            account_id = ?, activity_type_id = ?, summary = ?, user_id = ?, due_date = ?, \
            notes = ?, resModel = ?, resId = ?, task_id = ?, project_id = ?, link_id = ?, state = ?, last_modified = ? \
            WHERE id = ?',
            [data.updatedAccount, data.updatedActivity, data.updatedSummary, data.updatedUserId,
            data.updatedDate, data.updatedNote, data.resModel, data.resId, data.task_id, 
            data.project_id, data.link_id, data.editschedule, new Date().toISOString(), data.rowId]
        );
        queryData('pending');
    });
}

function filterStatus(type) {
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    db.transaction(function (tx) {
        filterActivityListData = [];
        if(workpersonaSwitchState) {
            var existing_activities = tx.executeSql('select * from mail_activity_app where account_id is not NULL order by last_modified desc')
            if (type == 'pending') {
                existing_activities = tx.executeSql('select * from mail_activity_app where account_id is not NULL AND state != "done" order by last_modified desc')
            } else if (type == 'done') {
                existing_activities = tx.executeSql('select * from mail_activity_app where account_id is not NULL AND state = "done" order by last_modified desc')
            }
        } else {
            var existing_activities = tx.executeSql('SELECT * FROM mail_activity_app where account_id IS NULL');
        }

        for (var activity = 0; activity < existing_activities.rows.length; activity++) {
            filterActivityListData.push({'summary': existing_activities.rows.item(activity).summary, 'due_date': existing_activities.rows.item(activity).due_date, 'id': existing_activities.rows.item(activity).id})
        }
    })
    return filterActivityListData;
}
