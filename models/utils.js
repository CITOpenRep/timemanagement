.import QtQuick.LocalStorage 2.7 as Sql
.import "database.js" as DBCommon

function getLastSyncStatus(accountId) {
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    var result = "";

    db.transaction(function (tx) {
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

function show_dict_data(data) {
  //  console.log(JSON.stringify(data, null, 2));
}


function insertData(name, link, database, username, selectedconnectwithId, apikey) {
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);

    db.transaction(function (tx) {
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

    db.transaction(function (tx) {
        var result = tx.executeSql('SELECT * FROM users');
        accountsList = [];
        for (var i = 0; i < result.rows.length; i++) {
            accountsList.push({ 'user_id': result.rows.item(i).id, 'name': result.rows.item(i).name, 'link': result.rows.item(i).link, 'database': result.rows.item(i).database, 'username': result.rows.item(i).username })
        }
    });
    selectedconnectwithId = 1;
    connectwith.text = 'Connect With Api Key'
}

function accountlistDataGet() {
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    var accountlist = [];

    db.transaction(function (tx) {
        var result = tx.executeSql('SELECT * FROM users');
        for (var i = 0; i < result.rows.length; i++) {
            accountlist.push({ 'id': result.rows.item(i).id, 'name': result.rows.item(i).name })
        }
    })
    return accountlist

}

function timesheetData(data) {
    var db = LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    db.transaction(function (tx) {
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

    db.transaction(function (tx) {
        var rs = tx.executeSql("SELECT id FROM users WHERE name = ?", [accountName]);
        if (rs.rows.length > 0) {
            accountId = rs.rows.item(0).id;
        }
    });

    return accountId;
}

function updateOdooUsers(model) {
    const db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    model.clear();

    db.transaction(function (tx) {
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

/**
 * Get user information by their Odoo record ID.
 * Useful for looking up who assigned a task/activity.
 *
 * @param {int} accountId - The account ID
 * @param {int} odooUserId - The Odoo user ID (odoo_record_id in res_users_app)
 * @returns {object|null} User info with name, avatar_128, login, job_title or null if not found
 */
function getUserInfoByOdooId(accountId, odooUserId) {
    if (!odooUserId) {
        return null;
    }
    
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    var userInfo = null;

    db.transaction(function (tx) {
        var rs = tx.executeSql(
            'SELECT name, avatar_128, odoo_record_id, login, job_title FROM res_users_app WHERE account_id = ? AND odoo_record_id = ?',
            [accountId, odooUserId]
        );
        if (rs.rows.length > 0) {
            var row = rs.rows.item(0);
            userInfo = {
                name: row.name,
                avatar_128: row.avatar_128,
                odoo_record_id: row.odoo_record_id,
                login: row.login,
                job_title: row.job_title
            };
        }
    });

    return userInfo;
}

/**
 * Get the assigner name for a task by looking up the create_uid.
 *
 * @param {int} accountId - The account ID
 * @param {int} taskId - The local task ID
 * @returns {string|null} The name of the user who created/assigned the task, or null
 */
function getTaskAssignerName(accountId, taskId) {
    if (!taskId) {
        return null;
    }
    
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    var assignerName = null;

    db.transaction(function (tx) {
        // First get the create_uid from the task
        var taskRs = tx.executeSql(
            'SELECT create_uid FROM project_task_app WHERE id = ? AND account_id = ?',
            [taskId, accountId]
        );
        if (taskRs.rows.length > 0 && taskRs.rows.item(0).create_uid) {
            var createUid = taskRs.rows.item(0).create_uid;
            // Now look up the user name
            var userRs = tx.executeSql(
                'SELECT name FROM res_users_app WHERE account_id = ? AND odoo_record_id = ?',
                [accountId, createUid]
            );
            if (userRs.rows.length > 0) {
                assignerName = userRs.rows.item(0).name;
            }
        }
    });

    return assignerName;
}

/**
 * Get the assigner info for an activity by looking up the create_uid.
 *
 * @param {int} accountId - The account ID
 * @param {int} activityId - The local activity ID
 * @returns {object|null} Object with name and avatar_128, or null
 */
function getActivityAssignerInfo(accountId, activityId) {
    if (!activityId) {
        return null;
    }
    
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    var assignerInfo = null;

    db.transaction(function (tx) {
        // First get the create_uid from the activity
        var activityRs = tx.executeSql(
            'SELECT create_uid FROM mail_activity_app WHERE id = ? AND account_id = ?',
            [activityId, accountId]
        );
        if (activityRs.rows.length > 0 && activityRs.rows.item(0).create_uid) {
            var createUid = activityRs.rows.item(0).create_uid;
            // Now look up the user info
            var userRs = tx.executeSql(
                'SELECT name, avatar_128 FROM res_users_app WHERE account_id = ? AND odoo_record_id = ?',
                [accountId, createUid]
            );
            if (userRs.rows.length > 0) {
                var row = userRs.rows.item(0);
                assignerInfo = {
                    name: row.name,
                    avatar_128: row.avatar_128
                };
            }
        }
    });

    return assignerInfo;
}

function fetch_subtasks(instance_id, parent_task_id) {
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
    var subtaskList = [];

    db.transaction(function (tx) {
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

    xhr.onreadystatechange = function () {
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

function getColorFromOdooIndex(index) {
    //standard from odoo pallet
    const colorMap = [
                       "transparent", "#EB6E67", "#F39C5A", "#F6C342",
                       "#6CC1E1", "#854D76", "#ED8888", "#2C8397",
                       "#49597C", "#DE3F7C", "#45C486", "#9B6CC3"
                   ];
    return colorMap[index % colorMap.length];
}

function getToday() {
    return new Date().toISOString().slice(0, 10);
}

function getTomorrow() {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    return tomorrow.toISOString().slice(0, 10);
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

function getNextWeekSameDay(baseDate) {
    const now = baseDate ? new Date(baseDate + 'T12:00:00Z') : new Date(); // Use UTC to avoid timezone issues
    const nextWeek = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + 7)); // Add exactly 7 days
    console.log("📅 getNextWeekSameDay: From", now.toISOString().slice(0, 10), "to", nextWeek.toISOString().slice(0, 10));
    return nextWeek.toISOString().slice(0, 10);
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

function getNextMonthSameDay(baseDate) {
    const now = baseDate ? new Date(baseDate + 'T12:00:00Z') : new Date(); // Use UTC to avoid timezone issues
    const currentDay = now.getUTCDate();
    const targetMonth = now.getUTCMonth() + 1;
    const targetYear = now.getUTCFullYear();
    
    // Adjust year if we're in December
    const finalYear = targetMonth > 11 ? targetYear + 1 : targetYear;
    const finalMonth = targetMonth > 11 ? 0 : targetMonth;
    
    // Get the last day of the target month to check if our desired day exists
    const lastDayOfTargetMonth = new Date(Date.UTC(finalYear, finalMonth + 1, 0)).getUTCDate();
    
    // Use the same day if it exists in the target month, otherwise use the last day
    const dayToUse = currentDay <= lastDayOfTargetMonth ? currentDay : lastDayOfTargetMonth;
    
    const nextMonth = new Date(Date.UTC(finalYear, finalMonth, dayToUse));
    
    console.log("📅 getNextMonthSameDay: From", now.toISOString().slice(0, 10), "to", nextMonth.toISOString().slice(0, 10));
    return nextMonth.toISOString().slice(0, 10);
}

function truncateText(text, maxLength) {
    if (text.length > maxLength) {
        return text.slice(0, maxLength) + "...";
    }
    return text;
}

function getFormattedTimestampUTC() {
    const now = new Date();
    const year = now.getUTCFullYear();
    const month = String(now.getUTCMonth() + 1).padStart(2, '0');
    const day = String(now.getUTCDate()).padStart(2, '0');
    const hours = String(now.getUTCHours()).padStart(2, '0');
    const minutes = String(now.getUTCMinutes()).padStart(2, '0');
    const seconds = String(now.getUTCSeconds()).padStart(2, '0');
    return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
}

function convertHHMMtoDecimalHours(hhmmString) {
    console.log("Input string is " + hhmmString)
    if (typeof hhmmString !== "string") {
            console.error("Input is not a string:", hhmmString);
            return 0;
        }

        var parts = hhmmString.split(":");
        if (parts.length !== 2) {
            console.error("Invalid HH:MM string:", hhmmString);
            return 0;
        }

        var hours = parseInt(parts[0], 10);
        var minutes = parseInt(parts[1], 10);

        if (isNaN(hours) || isNaN(minutes)) {
            console.error("Invalid numeric values in HH:MM string:", hhmmString);
            return 0;
        }

        return parseFloat((hours + (minutes / 60)).toFixed(4));
}

/**
 * Converts decimal hours to HH.MM format for display.
 * E.g., 11.8333 => "11.50" (for 11 hours 50 minutes)
 * @param {number} decimalHours
 * @returns {string} - HH.MM string
 */
function convertDecimalHoursToHHMM(decimalHours) {
    var hours = Math.floor(decimalHours);
    var minutes = Math.round((decimalHours - hours) * 60);
    return hours + ":" + String(minutes).padStart(2, "0");
}


/* Name: convertDurationToFloat
* This function will return float value from HH:MM format
* -> value -> HH:MM format to convert float value
*/

function convertDurationToFloat(value) {
    let vals = value.split(":");
    let hours = parseFloat(vals[0]);
    let minutes = parseFloat(vals[1]);
    // Remove the day calculation and modulo operation for project hours
    // Project allocation can be any number of hours, not limited to 24-hour days
    let convertedMinutes = minutes / 60.0;
    return hours + convertedMinutes;
}

function formatDate(date) {
    var month = date.getMonth() + 1;
    var day = date.getDate();
    var year = date.getFullYear();
    return month + '/' + day + '/' + year;
}

/**
 * Converts date from M/d/yyyy format to yyyy-MM-dd ISO format for database/API use
 * @param {string} dateString - Date in M/d/yyyy format (e.g., "9/24/2025")
 * @returns {string} - Date in yyyy-MM-dd format (e.g., "2025-09-24")
 */
function convertToISODate(dateString) {
    if (!dateString) return "";
    
    try {
        // Parse the M/d/yyyy format
        var parts = dateString.split('/');
        if (parts.length !== 3) return dateString; // Return original if not in expected format
        
        var month = parseInt(parts[0]);
        var day = parseInt(parts[1]);
        var year = parseInt(parts[2]);
        
        // Format as yyyy-MM-dd with zero padding
        var isoDate = year + '-' + 
                     (month < 10 ? '0' : '') + month + '-' + 
                     (day < 10 ? '0' : '') + day;
                     
        console.log("convertToISODate: converted", dateString, "to", isoDate);
        return isoDate;
    } catch (e) {
        console.error("Error converting date to ISO format:", e);
        return dateString; // Return original on error
    }
}

function getTimeStatusInText(endDateString) {
    if (!endDateString)
        return "N/A";
    var end = new Date(endDateString);
    if (isNaN(end.getTime()))
        return "Invalid";
    
    // Normalize both dates to remove time component for accurate day calculation
    var now = new Date();
    var endDay = new Date(end.getFullYear(), end.getMonth(), end.getDate());
    var nowDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    
    var diff = endDay - nowDay;
    var days = Math.floor(diff / (1000 * 60 * 60 * 24));
    if (days < 0)
        return Math.abs(days) + " days overdue";
    if (days === 0)
        return "Due today";
    return days + " days";
}

function extractDate(datetimeStr) {
  // datetimeStr example: "2025-06-23T13:53:42.834"
   const d = new Date(datetimeStr);
  const year = d.getFullYear();
  const month = String(d.getMonth() + 1).padStart(2, '0');  // Months are 0-based
  const day = String(d.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}


/**
 * Cleans a string by removing:
 * - Non-printable ASCII control characters
 * - Common invisible Unicode characters (e.g. LRM, RLM, separators)
 * - Excess whitespace from both ends
 */
function cleanText(str) {
    if (typeof str !== 'string') return '';

    return str
        // Remove common invisible/control characters (ASCII + Unicode)
        .replace(/[\u0000-\u001F\u007F-\u009F\u200B-\u200F\u2028\u2029\u2060\uFEFF]/g, '')
        // Normalize to avoid weird composed characters
        .normalize('NFC')
        // Trim extra whitespace
        .trim();
}

/**
 * Verifies and reports on personal stage data in the local database.
 * Checks if personal_stage column exists and provides statistics.
 * Also shows sample data to help diagnose sync issues.
 * 
 * @returns {Object} - Status object with:
 *   - success: boolean indicating if check completed
 *   - message: detailed status message
 *   - tasksUpdated: number (0 for diagnostic)
 *   - stagesProcessed: number (0 for diagnostic)
 */
function migratePersonalStageData() {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        var results = {
            success: false,
            message: "",
            tasksUpdated: 0,
            stagesProcessed: 0
        };

        // Step 1: Check if personal_stage column exists
        var columnExists = false;
        db.readTransaction(function(tx) {
            var rs = tx.executeSql("SELECT COUNT(*) as count FROM pragma_table_info('project_task_app') WHERE name='personal_stage'");
            if (rs.rows.length > 0 && rs.rows.item(0).count > 0) {
                columnExists = true;
            }
        });

        if (!columnExists) {
            results.message = "❌ Error: personal_stage column does not exist in database. Please sync from Odoo first.";
            return results;
        }

        // Step 2: Get statistics about tasks and personal stages
        var stats = {
            total_tasks: 0,
            tasks_with_stage: 0,
            tasks_without_stage: 0,
            personal_stages_count: 0,
            sample_tasks: [],
            sample_stages: []
        };

        db.readTransaction(function(tx) {
            // Count total tasks, tasks with stages, tasks without stages
            var rs = tx.executeSql(
                "SELECT COUNT(*) as total, " +
                "COUNT(CASE WHEN personal_stage IS NOT NULL AND personal_stage != '' THEN 1 END) as with_stage, " +
                "COUNT(CASE WHEN personal_stage IS NULL OR personal_stage = '' THEN 1 END) as without_stage " +
                "FROM project_task_app"
            );
            if (rs.rows.length > 0) {
                var row = rs.rows.item(0);
                stats.total_tasks = row.total;
                stats.tasks_with_stage = row.with_stage;
                stats.tasks_without_stage = row.without_stage;
            }

            // Get sample tasks (first 3)
            var rs_sample = tx.executeSql(
                "SELECT id, name, personal_stage, user_id, state FROM project_task_app LIMIT 3"
            );
            for (var i = 0; i < rs_sample.rows.length; i++) {
                stats.sample_tasks.push(rs_sample.rows.item(i));
            }

            // Count personal stages (stages with user_id)
            var rs2 = tx.executeSql(
                "SELECT COUNT(*) as count FROM project_task_type_app WHERE user_id IS NOT NULL AND user_id != ''"
            );
            if (rs2.rows.length > 0) {
                stats.personal_stages_count = rs2.rows.item(0).count;
            }

            // Get sample personal stages (first 3)
            var rs_stages = tx.executeSql(
                "SELECT id, name, user_id, odoo_record_id FROM project_task_type_app WHERE user_id IS NOT NULL LIMIT 3"
            );
            for (var i = 0; i < rs_stages.rows.length; i++) {
                stats.sample_stages.push(rs_stages.rows.item(i));
            }
        });

        // Step 3: Build informative message
        var message = "📊 Personal Stage Status:\n\n";
        message += "Total tasks: " + stats.total_tasks + "\n";
        message += "Tasks with personal stage: " + stats.tasks_with_stage + "\n";
        message += "Tasks without personal stage: " + stats.tasks_without_stage + "\n";
        message += "Personal stages available: " + stats.personal_stages_count + "\n\n";

        // Show sample task data
        if (stats.sample_tasks.length > 0) {
            message += "📋 Sample Task Data:\n";
            for (var i = 0; i < stats.sample_tasks.length; i++) {
                var task = stats.sample_tasks[i];
                message += "Task: " + (task.name || "Unnamed") + "\n";
                message += "  personal_stage: " + (task.personal_stage || "NULL") + "\n";
                message += "  state: " + (task.state || "NULL") + "\n";
                message += "  user_id: " + (task.user_id || "NULL") + "\n\n";
            }
        }

        // Show sample stage data
        if (stats.sample_stages.length > 0) {
            message += "🏷️ Sample Personal Stage Data:\n";
            for (var i = 0; i < stats.sample_stages.length; i++) {
                var stage = stats.sample_stages[i];
                message += "Stage: " + (stage.name || "Unnamed") + "\n";
                message += "  odoo_record_id: " + (stage.odoo_record_id || "NULL") + "\n";
                message += "  user_id: " + (stage.user_id || "NULL") + "\n\n";
            }
        }

        if (stats.personal_stages_count === 0) {
            message += "⚠️ No personal stages found. Personal stages need to have a user assigned in Odoo.\n\n";
            message += "To use personal stages:\n";
            message += "1. In Odoo, go to Project > Configuration > Stages\n";
            message += "2. Create or edit stages and assign them to specific users\n";
            message += "3. Sync again from this app";
        } else if (stats.tasks_with_stage === 0) {
            message += "⚠️ No tasks have personal stages assigned yet.\n\n";
            message += "This means the 'personal_stage' field is not being synced.\n";
            message += "Check that:\n";
            message += "1. Tasks in Odoo have 'personal_stage_type_id' field set\n";
            message += "2. The field mapping in field_config.json includes:\n";
            message += "   \"personal_stage_type_id\": \"personal_stage\"\n";
            message += "3. Re-sync from Odoo after verifying";
        } else if (stats.tasks_with_stage === stats.total_tasks) {
            message += "✅ All tasks have personal stages assigned!";
        } else {
            message += "✅ Personal stages are working correctly!\n";
            message += Math.round((stats.tasks_with_stage / stats.total_tasks) * 100) + "% of tasks have personal stages.";
        }

        results.success = true;
        results.message = message;
        return results;

    } catch (error) {
        console.error("Error in personal stage diagnostics:", error);
        return {
            success: false,
            message: "❌ Error checking personal stage data: " + error.message,
            tasksUpdated: 0,
            stagesProcessed: 0
        };
    }
}

/**
 * Forces re-sync of tasks by resetting their last_modified timestamp.
 * This will cause the sync logic to fetch fresh data from Odoo server.
 * 
 * @param {boolean} onlyWithoutStages - If true, only reset tasks without personal_stage
 * @returns {Object} - Status object with:
 *   - success: boolean indicating if reset completed
 *   - message: detailed status message
 *   - tasksUpdated: number of tasks that had their timestamp reset
 */
function forceTaskResync(onlyWithoutStages) {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        var tasksUpdated = 0;
        
        db.transaction(function(tx) {
            var condition = onlyWithoutStages 
                ? "WHERE personal_stage IS NULL OR personal_stage = ''"
                : "";
            
            // First, count how many tasks will be affected
            var countSql = "SELECT COUNT(*) as count FROM project_task_app " + condition;
            var rs = tx.executeSql(countSql);
            if (rs.rows.length > 0) {
                tasksUpdated = rs.rows.item(0).count;
            }
            
            // Reset the last_modified timestamp to force re-sync
            // Set it to a very old date (epoch start) so sync will definitely update it
            var updateSql = "UPDATE project_task_app SET last_modified = '1970-01-01 00:00:00' " + condition;
            tx.executeSql(updateSql);
        });
        
        var message = "";
        if (tasksUpdated === 0) {
            if (onlyWithoutStages) {
                message = "✓ No tasks need updating - all tasks already have personal stages!";
            } else {
                message = "⚠️ No tasks found in database.";
            }
        } else {
            message = "✓ Successfully reset " + tasksUpdated + " task(s).\n\n";
            message += "Next steps:\n";
            message += "1. Go to your connected account settings\n";
            message += "2. Click 'Sync Now' to fetch fresh data from Odoo\n";
            message += "3. The personal_stage field will be updated if set in Odoo\n\n";
            message += "Note: This will update ALL task fields, not just personal stages.";
        }
        
        return {
            success: true,
            message: message,
            tasksUpdated: tasksUpdated,
            stagesProcessed: 0
        };
        
    } catch (error) {
        console.error("Error forcing task resync:", error);
        return {
            success: false,
            message: "❌ Error resetting task timestamps: " + error.message,
            tasksUpdated: 0,
            stagesProcessed: 0
        };
    }
}
