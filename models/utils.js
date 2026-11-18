.import "logger.js" as Logger
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
                'SELECT name FROM res_users_app WHERE account_id = ? AND (odoo_record_id = ? OR (account_id = 0 AND id = ?))',
                [accountId, createUid, createUid]
            );
            if (userRs.rows.length > 0) {
                assignerName = userRs.rows.item(0).name;
            }
        }
    });

    return assignerName;
}

function validateAndCleanOdooURL(url) {
    if (!url || typeof url !== "string") {
        return {
            isValid: false,
            cleanedUrl: ""
        };
    }

    url = url.trim();
    if (url.length === 0 || url === "http://" || url === "https://") {
        return {
            isValid: false,
            cleanedUrl: ""
        };
    }

    // Add https:// if protocol is missing
    if (!url.startsWith("http://") && !url.startsWith("https://")) {
        if (!url.includes("://")) {
            url = "https://" + url;
        }
    }

    // Strip trailing slashes beyond the protocol
    while (url.endsWith("/") && url !== "http://" && url !== "https://") {
        url = url.slice(0, -1);
    }

    const pattern = new RegExp(
                      '^(https?:\\/\\/)?' +
                      '(([a-zA-Z0-9\\-\\.]+)\\.([a-zA-Z]{2,63})|' +
                      'localhost|' +
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
                        Logger.error("Utils", "Failed to get DB list: No result field.")
                        callback([]);
                    }
                } catch (e) {
                    Logger.error("Utils", "JSON parse error:", e)
                    callback([]);
                }
            } else {
                Logger.error("Utils", "Request failed with status", xhr.status)
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

function getNextWeekSameDay(baseDate) {
    const now = baseDate ? new Date(baseDate + 'T12:00:00Z') : new Date(); // Use UTC to avoid timezone issues
    const nextWeek = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + 7)); // Add exactly 7 days
    Logger.debug("Utils", "getNextWeekSameDay: From", now.toISOString().slice(0, 10), "to", nextWeek.toISOString().slice(0, 10))
    return nextWeek.toISOString().slice(0, 10);
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
    
    Logger.debug("Utils", "getNextMonthSameDay: From", now.toISOString().slice(0, 10), "to", nextMonth.toISOString().slice(0, 10))
    return nextMonth.toISOString().slice(0, 10);
}

function truncateText(text, maxLength) {
    if (!text || typeof text !== 'string') return "";
    var cleaned = cleanText(stripHtmlTags(text));
    if (cleaned.length > maxLength) {
        return cleaned.slice(0, maxLength).trim() + "...";
    }
    return cleaned;
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
    Logger.debug("Utils", "Input string is " + hhmmString)
    if (typeof hhmmString === "number") {
        return parseFloat(hhmmString.toFixed(4));
    }
    if (typeof hhmmString !== "string") {
        Logger.error("Utils", "Input is not a string or number:", hhmmString)
        return 0;
    }

    hhmmString = hhmmString.trim();
    if (hhmmString === "") {
        return 0;
    }

    // Handle numeric string directly if no colons
    if (!hhmmString.includes(":") && !isNaN(Number(hhmmString))) {
        return parseFloat(Number(hhmmString).toFixed(4));
    }

    var parts = hhmmString.split(":");
    if (parts.length === 2) {
        var hours = parseInt(parts[0], 10);
        var minutes = parseInt(parts[1], 10);

        if (isNaN(hours) || isNaN(minutes)) {
            Logger.error("Utils", "Invalid numeric values in HH:MM string:", hhmmString)
            return 0;
        }

        return parseFloat((hours + (minutes / 60)).toFixed(4));
    } else if (parts.length === 3) {
        var hours = parseInt(parts[0], 10);
        var minutes = parseInt(parts[1], 10);
        var seconds = parseInt(parts[2], 10);

        if (isNaN(hours) || isNaN(minutes) || isNaN(seconds)) {
            Logger.error("Utils", "Invalid numeric values in HH:MM:SS string:", hhmmString)
            return 0;
        }

        return parseFloat((hours + (minutes / 60) + (seconds / 3600)).toFixed(4));
    } else {
        Logger.error("Utils", "Invalid HH:MM string:", hhmmString)
        return 0;
    }
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
* This function will return float value from HH:MM or HH:MM:SS format
* -> value -> HH:MM / HH:MM:SS format to convert float value
*/

function convertDurationToFloat(value) {
    if (typeof value === "number") {
        return value;
    }
    if (typeof value !== "string" || value.trim() === "") {
        return 0;
    }
    let vals = value.trim().split(":");
    let hours = parseFloat(vals[0]) || 0;
    let minutes = (vals.length > 1) ? (parseFloat(vals[1]) || 0) : 0;
    let seconds = (vals.length > 2) ? (parseFloat(vals[2]) || 0) : 0;
    // Remove the day calculation and modulo operation for project hours
    // Project allocation can be any number of hours, not limited to 24-hour days
    let convertedMinutes = minutes / 60.0;
    let convertedSeconds = seconds / 3600.0;
    return hours + convertedMinutes + convertedSeconds;
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
                     
        Logger.debug("Utils", "convertToISODate: converted", dateString, "to", isoDate)
        return isoDate;
    } catch (e) {
        Logger.error("Utils", "Error converting date to ISO format:", e)
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
    if (days === 1)
        return "1 day remaining";
    return days + " days remaining";
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
        .replace(/&nbsp;/gi, ' ')
        // Remove common invisible/control characters (ASCII + Unicode + non-breaking space)
        .replace(/[\u0000-\u001F\u007F-\u009F\u200B-\u200F\u2028\u2029\u2060\uFEFF\u00A0]/g, '')
        // Normalize to avoid weird composed characters
        .normalize('NFC')
        // Collapse multiple spaces into single space
        .replace(/[ \t]+/g, ' ')
        // Trim extra whitespace from both ends
        .trim();
}


