.pragma library


var description_temporary_holder=""
var description_context=""

// Global assignee filter state
var assigneeFilterEnabled = false
var assigneeFilterIds = []

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
