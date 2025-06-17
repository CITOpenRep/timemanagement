.import QtQuick.LocalStorage 2.7 as Sql
.import "database.js" as DBCommon


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


/**
 * Retrieves all activity records from the `mail_activity_app` table.
 *
 * This function opens a read-only SQLite transaction using the DBCommon configuration,
 * executes a query to fetch all rows from the `mail_activity_app` table without any filtering
 * (e.g., includes all statuses, states, and accounts), and returns the results as a list of objects.
 *
 * Each row is converted into a plain JavaScript object using `DBCommon.rowToObject`.
 *
 * @function
 * @returns {Array<Object>} A list of all activities stored in the local database, sorted by `due_date` ascending.
 *
 * @example
 * const allActivities = getAllActivities();
 * console.log(allActivities[0].summary); // Example usage
 */
function getAllActivities() {
    var activityList = [];

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var query = `
            SELECT *
            FROM mail_activity_app
            ORDER BY due_date ASC
            `;

            var rs = tx.executeSql(query);

            for (var i = 0; i < rs.rows.length; i++) {
                activityList.push(DBCommon.rowToObject(rs.rows.item(i)));
            }
        });

    } catch (e) {
        DBCommon.logException("getAllActivities", e);
    }

    return activityList;
}

function getActivityByOdooId(odoo_record_id) {
    var activity = null;

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var query = `
            SELECT *
            FROM mail_activity_app
            WHERE odoo_record_id = ?
            LIMIT 1
            `;

            var rs = tx.executeSql(query, [odoo_record_id]);

            if (rs.rows.length > 0) {
                activity = DBCommon.rowToObject(rs.rows.item(0));
            }
        });

    } catch (e) {
        DBCommon.logException("getActivityByOdooId", e);
    }

    return activity;
}

function getActivityTypeName(odooRecordId) {
    var typeName = "";

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var query = `
            SELECT name FROM mail_activity_type_app
            WHERE odoo_record_id = ?
            LIMIT 1
            `;
            var rs = tx.executeSql(query, [odooRecordId]);

            if (rs.rows.length > 0) {
                typeName = rs.rows.item(0).name;
            }
        });

    } catch (e) {
        DBCommon.logException("getActivityTypeName", e);
    }

    return typeName;
}

function getActivityIconForType(typeName) {
    if (!typeName) return "activity_others.png";

    const normalized = typeName.trim().toLowerCase();

    if (normalized.includes("mail")) {
        return "activity_mail.png";
    } else if (normalized.includes("call")) {
        return "activity_call.png";
    }else if (normalized.includes("meeting")) {
        return "activity_meeting.png";
    }
    else {
        return "activity_others.png";
    }
}
