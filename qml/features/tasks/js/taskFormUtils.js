.pragma library

.import "../../../../models/utils.js" as Utils

function normalizeIdForRestore(value) {
    if (value === null || value === undefined)
        return -1;

    var num = parseInt(value);
    return isNaN(num) ? -1 : num;
}

function restoreWorkItemSelection(workItem, snapshot) {
    if (!workItem || (!snapshot.accountId && !snapshot.projectId && snapshot.accountId !== 0))
        return false;

    var accountId = normalizeIdForRestore(snapshot.accountId);
    var projectId = normalizeIdForRestore(snapshot.projectId);
    var subprojectId = normalizeIdForRestore(snapshot.subprojectId);
    var taskId = normalizeIdForRestore(snapshot.taskId);
    var subtaskId = normalizeIdForRestore(snapshot.subtaskId);
    var assigneeId = normalizeIdForRestore(snapshot.assigneeId);

    if (accountId > 0 || projectId > 0) {
        workItem.deferredLoadExistingRecordSet(accountId, projectId, subprojectId, taskId, subtaskId, assigneeId);

        if (workItem.enableMultipleAssignees && snapshot.multipleAssignees) {
            Qt.callLater(function() {
                workItem.setMultipleAssignees(snapshot.multipleAssignees);
            });
        }
        return true;
    }

    return false;
}

function getCurrentFormData(params) {
    var ids = params.workItem.getIds();
    var formData = {
        name: params.name,
        description: params.description,
        plannedHours: params.plannedHours,
        priority: params.priority,
        startDate: params.startDate,
        endDate: params.endDate,
        deadline: params.deadline,
        accountId: ids.account_id,
        projectId: ids.project_id,
        subprojectId: ids.subproject_id,
        taskId: ids.task_id,
        subtaskId: ids.subtask_id,
        selectedStageOdooRecordId: params.selectedStageOdooRecordId,
        selectedPersonalStageOdooRecordId: params.selectedPersonalStageOdooRecordId
    };

    if (params.workItem.enableMultipleAssignees) {
        formData.multipleAssignees = ids.multiple_assignees || [];
        formData.assigneeIds = ids.assignee_ids || [];
    } else {
        formData.assigneeId = ids.assignee_id;
    }

    return formData;
}

function validateHoursInput(text) {
    var timeRegex = /^(\d{1,3}):([0-5]\d)$/;
    var decimalRegex = /^\d+(\.\d+)?$/;

    if (timeRegex.test(text)) {
        var match = text.match(timeRegex);
        var hours = parseInt(match[1]);
        var minutes = parseInt(match[2]);
        return hours >= 0 && hours <= 999 && minutes >= 0 && minutes <= 59;
    }

    if (decimalRegex.test(text)) {
        var value = parseFloat(text);
        return value >= 0 && value <= 999;
    }

    return false;
}

function formatHoursDisplay(text) {
    var timeRegex = /^(\d{1,3}):([0-5]\d)$/;
    var decimalRegex = /^\d+(\.\d+)?$/;

    if (timeRegex.test(text)) {
        var match = text.match(timeRegex);
        var hours = parseInt(match[1]);
        var minutes = parseInt(match[2]);
        return (hours < 10 ? "0" + hours : hours) + ":" + (minutes < 10 ? "0" + minutes : minutes);
    }

    if (decimalRegex.test(text))
        return Utils.convertDecimalHoursToHHMM(parseFloat(text));

    return text;
}

function resolveSingleAssigneeId(userIdValue) {
    if (userIdValue === undefined || userIdValue === null || userIdValue === "")
        return -1;

    var userIdStr = userIdValue.toString();
    if (userIdStr.indexOf(", ") >= 0) {
        var firstId = parseInt(userIdStr.split(", ")[0].trim());
        return isNaN(firstId) ? -1 : firstId;
    }

    var singleId = parseInt(userIdStr);
    return isNaN(singleId) ? -1 : singleId;
}

function buildSaveData(params) {
    var saveData = {
        accountId: params.ids.account_id < 0 ? 0 : params.ids.account_id,
        name: params.name,
        record_id: params.recordId,
        projectId: params.ids.project_id,
        subProjectId: params.ids.subproject_id,
        parentId: params.ids.task_id,
        startDate: params.startDate,
        endDate: params.endDate,
        deadline: params.deadline !== "Not set" ? params.deadline : "",
        priority: (params.priority != null ? params.priority.toString() : "0"),
        plannedHours: Utils.convertDurationToFloat(params.plannedHours),
        description: params.description,
        assigneeUserId: params.ids.assignee_id,
        status: "updated"
    };

    var stageToAssign = params.selectedStageOdooRecordId;
    if (params.recordId === 0 && stageToAssign <= 0 && params.stageListCount > 0) {
        var firstStage = params.firstStage;
        stageToAssign = firstStage ? firstStage.odoo_record_id : stageToAssign;
    }

    if (stageToAssign > 0)
        saveData.stageOdooRecordId = stageToAssign;

    if (params.selectedPersonalStageOdooRecordId !== undefined && params.selectedPersonalStageOdooRecordId !== null) {
        saveData.personalStageOdooRecordId = params.selectedPersonalStageOdooRecordId > 0
                                           ? params.selectedPersonalStageOdooRecordId
                                           : null;
    }

    if (params.enableMultipleAssignees && params.ids.multiple_assignees)
        saveData.multipleAssignees = params.ids.multiple_assignees;

    return saveData;
}
