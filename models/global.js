.pragma library

.import "accounts.js" as Account

var description_temporary_holder=""
var description_context=""

var current_account_id=Account.getDefaultAccountId()

// Global callback storage for CreateUpdatePage
var createUpdateCallback = null

// Global assignee filter state
var assigneeFilterEnabled = false
var assigneeFilterIds = []

// Global "My Items" filter state (shows items assigned to or created by the current user)
var myItemsFilterEnabled = true  // ON by default

// Navigation tracking for filter persistence
var lastVisitedPage = ""

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

// Functions to manage "My Items" filter state
function setMyItemsFilter(enabled) {
    myItemsFilterEnabled = enabled;
}

function getMyItemsFilter() {
    return myItemsFilterEnabled;
}

function clearMyItemsFilter() {
    myItemsFilterEnabled = true; // Reset to default (ON)
}

// Track page navigation for filter persistence
function setLastVisitedPage(pageName) {
    lastVisitedPage = pageName;
}

function getLastVisitedPage() {
    return lastVisitedPage;
}

// Check if we should preserve filters (navigating between related pages)
function shouldPreserveFilters(currentPage, previousPage) {
    // Define page groups that should preserve filters when navigating between each other
    var taskPages = ["Task_Page", "Tasks"];
    var activityPages = ["Activity_Page", "Activities"];
    
    // Check if both current and previous are in task pages group
    var bothInTaskPages = taskPages.indexOf(currentPage) !== -1 && taskPages.indexOf(previousPage) !== -1;
    
    // Check if both current and previous are in activity pages group
    var bothInActivityPages = activityPages.indexOf(currentPage) !== -1 && activityPages.indexOf(previousPage) !== -1;
    
    return bothInTaskPages || bothInActivityPages;
}

// Backward compatibility alias
function shouldPreserveAssigneeFilter(currentPage, previousPage) {
    return shouldPreserveFilters(currentPage, previousPage);
}
