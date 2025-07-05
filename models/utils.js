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

function truncateText(text, maxLength) {
    if (text.length > maxLength) {
        return text.slice(0, maxLength) + "...";
    }
    return text;
}

function getFormattedTimestampUTC() {
    console.log("Local Time:", new Date().toLocaleString());
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
    let days = Math.floor(hours / 24);
    hours = hours % 24;
    let convertedMinutes = minutes / 60.0;
    return hours + convertedMinutes;
}

function formatDate(date) {
    var month = date.getMonth() + 1;
    var day = date.getDate();
    var year = date.getFullYear();
    return month + '/' + day + '/' + year;
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
