.pragma library

    .import "database.js" as DBCommon
        .import "accounts.js" as Account
            .import QtQuick.LocalStorage 2.7 as Sql

var description_temporary_holder = ""
var description_context = ""

var current_account_id = Account.getDefaultAccountId()

// Global callback storage for CreateUpdatePage
var createUpdateCallback = null

// Global callback storage for ReadMorePage rich-text saves
var richTextSaveCallback = null

// Global assignee filter state
var assigneeFilterEnabled = false
var assigneeFilterIds = []

// Navigation tracking for filter persistence
var lastVisitedPage = ""

// Global Date Range Filter state
var dateRangePresetId = 2 // 2: This Month
var dateRangeStartDate = "" // yyyy-MM-dd
var dateRangeEndDate = ""   // yyyy-MM-dd
var dateRangePresetLabel = "This Month"
var dateRangeInitialized = false

// Functions to manage assignee filter state
function setAssigneeFilter(enabled, assigneeIds) {
    assigneeFilterEnabled = enabled;
    assigneeFilterIds = assigneeIds ? assigneeIds.slice() : []; // Create a copy of the array
}

function getAssigneeFilter() {
    return {
        enabled: assigneeFilterEnabled,
        assigneeIds: assigneeFilterIds.slice() // Return a copy of the array
    };
}

function clearAssigneeFilter() {
    assigneeFilterEnabled = false;
    assigneeFilterIds = [];
}

// Track page navigation for filter persistence
function setLastVisitedPage(pageName) {
    lastVisitedPage = pageName;
}

function getLastVisitedPage() {
    return lastVisitedPage;
}

// Check if we should preserve filter (navigating between related pages)
function shouldPreserveAssigneeFilter(currentPage, previousPage) {
    // Define page groups that should preserve filters when navigating between each other
    var taskPages = ["Task_Page", "Tasks"];
    var activityPages = ["Activity_Page", "Activities"];

    // Check if both current and previous are in task pages group
    var bothInTaskPages = taskPages.indexOf(currentPage) !== -1 && taskPages.indexOf(previousPage) !== -1;

    // Check if both current and previous are in activity pages group
    var bothInActivityPages = activityPages.indexOf(currentPage) !== -1 && activityPages.indexOf(previousPage) !== -1;

    return bothInTaskPages || bothInActivityPages;
}

// Global Date Range Filter state management and DB persistence
function setDateRangeFilter(presetId, startDate, endDate, presetLabel) {
    dateRangePresetId = (presetId !== undefined && presetId !== null) ? presetId : -1;
    dateRangeStartDate = startDate || "";
    dateRangeEndDate = endDate || "";
    dateRangePresetLabel = presetLabel || "No Filter";
    dateRangeInitialized = true;

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
        db.transaction(function (tx) {
            var data = JSON.stringify({
                presetId: dateRangePresetId,
                startDate: dateRangeStartDate,
                endDate: dateRangeEndDate,
                presetLabel: dateRangePresetLabel
            });
            tx.executeSql("INSERT OR REPLACE INTO app_settings (key, value) VALUES (?, ?)", ["dashboard_date_range_filter", data]);
        });
    } catch (e) {
        console.error("Error saving date range filter to settings:", e);
    }
}

function getDateRangeFilter() {
    if (!dateRangeInitialized) {
        try {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function (tx) {
                var rs = tx.executeSql("SELECT value FROM app_settings WHERE key = ?", ["dashboard_date_range_filter"]);
                if (rs.rows.length > 0) {
                    var data = JSON.parse(rs.rows.item(0).value);
                    if (data) {
                        dateRangePresetId = data.presetId !== undefined ? data.presetId : -1;
                        dateRangeStartDate = data.startDate || "";
                        dateRangeEndDate = data.endDate || "";
                        dateRangePresetLabel = data.presetLabel || "No Filter";
                    }
                }
            });
        } catch (e) {
            console.error("Error loading date range filter from settings:", e);
        }
        dateRangeInitialized = true;
    }

    return {
        presetId: dateRangePresetId,
        startDate: dateRangeStartDate,
        endDate: dateRangeEndDate,
        presetLabel: dateRangePresetLabel,
        isFiltered: dateRangePresetId !== -1
    };
}

function clearDateRangeFilter() {
    setDateRangeFilter(-1, "", "", "No Filter");
}

