.pragma library


var description_temporary_holder=""
var description_context=""

// Global assignee filter state
var assigneeFilterEnabled = false
var assigneeFilterIds = []

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

// Track page navigation for filter persistence
function setLastVisitedPage(pageName) {
    lastVisitedPage = pageName;
}

function getLastVisitedPage() {
    return lastVisitedPage;
}

// Check if we should preserve filter (navigating between Task_Page and Tasks.qml)
function shouldPreserveAssigneeFilter(currentPage, previousPage) {
    var taskPages = ["Task_Page", "Tasks"];
    var isCurrentTaskPage = taskPages.indexOf(currentPage) !== -1;
    var isPreviousTaskPage = taskPages.indexOf(previousPage) !== -1;
    return isCurrentTaskPage && isPreviousTaskPage;
}
