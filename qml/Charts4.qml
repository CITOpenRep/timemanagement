// Chart 4 compatibility wrapper that adapts dashboard data into the new drilldown flow.
import QtQuick 2.12
import Lomiri.Components 1.3
import "../models/project.js" as ProjectModel
import "../models/task.js" as TaskModel
import "../models/timesheet.js" as TimesheetModel
import "../models/utils.js" as Utils

Item {
    id: root

    width: parent ? parent.width : units.gu(48)
    height: parent ? parent.height : units.gu(40)

    property int selectedAccountId: typeof accountPicker !== "undefined" ? accountPicker.selectedAccountId : -1
    property var projectsModel: []

    function reloadData() {
        projectsModel = buildProjectsModel();
    }

    function buildProjectsModel() {
        var accountId = selectedAccountId;
        var projectRows = accountId === -1 ? ProjectModel.getAllProjects() : ProjectModel.getProjectsForAccount(accountId);
        var taskRows = accountId === -1 ? TaskModel.getAllTasks() : TaskModel.getTasksForAccount(accountId);
        var aggregateByProject = {};
        var topLevelProjects = [];
        var seenProjectKeys = {};

        for (var i = 0; i < taskRows.length; i++) {
            var task = taskRows[i];
            if (!task || task.parent_id > 0) {
                continue;
            }

            var projectKey = String(task.account_id) + ":" + String(task.project_id);
            if (!aggregateByProject[projectKey]) {
                aggregateByProject[projectKey] = {
                    taskCount: 0,
                    totalHours: 0
                };
            }

            aggregateByProject[projectKey].taskCount += 1;
            aggregateByProject[projectKey].totalHours += Number(task.spent_hours || 0);
        }

        for (var j = 0; j < projectRows.length; j++) {
            var project = projectRows[j];
            if (!project || project.parent_id > 0) {
                continue;
            }

            var uniqueKey = String(project.account_id) + ":" + String(project.odoo_record_id);
            if (seenProjectKeys[uniqueKey]) {
                continue;
            }
            seenProjectKeys[uniqueKey] = true;

            var aggregate = aggregateByProject[uniqueKey] || { taskCount: 0, totalHours: 0 };
            topLevelProjects.push({
                id: uniqueKey,
                accountId: project.account_id,
                odooRecordId: project.odoo_record_id,
                localId: project.id,
                name: project.name || i18n.dtr("ubtms", "Unnamed project"),
                colour: normalizeProjectColour(project.color_pallet),
                taskCount: aggregate.taskCount,
                totalHours: Number(aggregate.totalHours || 0),
                tasks: [],
                _tasksLoaded: false
            });
        }

        return topLevelProjects;
    }

    function loadTasksForProject(projectId) {
        var project = findProject(projectId);
        if (!project) {
            return [];
        }

        var taskRows = TaskModel.getTasksForProject(project.odooRecordId, project.accountId);
        var mappedTasks = [];

        for (var i = 0; i < taskRows.length; i++) {
            var task = taskRows[i];
            if (!task || task.parent_id > 0) {
                continue;
            }

            var assignee = Utils.getTaskAssignerName(project.accountId, task.id);
            mappedTasks.push({
                id: String(project.id) + ":" + String(task.odoo_record_id),
                localId: task.id,
                odooRecordId: task.odoo_record_id,
                projectId: project.id,
                name: task.name || i18n.dtr("ubtms", "Unnamed task"),
                totalHours: Number(task.spent_hours || 0),
                description: task.description || "",
                assignee: assignee || i18n.dtr("ubtms", "Unassigned"),
                status: task.state || task.status || i18n.dtr("ubtms", "Unknown"),
                projectName: project.name,
                logs: [],
                _logsLoaded: false
            });
        }

        project.tasks = mappedTasks;
        project._tasksLoaded = true;
        project.taskCount = mappedTasks.length;

        return mappedTasks;
    }

    function loadLogsForTask(projectId, taskId) {
        var project = findProject(projectId);
        var task = findTask(project, taskId);
        if (!project || !task) {
            return [];
        }

        var timesheets = TimesheetModel.getTimesheetsForTask(task.odooRecordId, project.accountId, "all");
        var logs = [];

        for (var i = 0; i < timesheets.length; i++) {
            var entry = timesheets[i];
            logs.push({
                id: entry.id,
                date: toIsoDate(entry.date),
                hours: parseHours(entry.spentHours),
                note: entry.name || ""
            });
        }

        task.logs = logs;
        task._logsLoaded = true;
        return logs;
    }

    function findProject(projectId) {
        for (var i = 0; i < projectsModel.length; i++) {
            if (projectsModel[i].id === projectId) {
                return projectsModel[i];
            }
        }
        return null;
    }

    function findTask(project, taskId) {
        if (!project || !project.tasks) {
            return null;
        }

        for (var i = 0; i < project.tasks.length; i++) {
            if (project.tasks[i].id === taskId) {
                return project.tasks[i];
            }
        }
        return null;
    }

    function normalizeProjectColour(colourValue) {
        if (typeof colourValue === "string" && colourValue.indexOf("#") === 0) {
            return colourValue;
        }
        return Theme.palette.selected.background;
    }

    function toIsoDate(dateValue) {
        if (!dateValue) {
            return "";
        }

        var stringValue = String(dateValue);
        return stringValue.length >= 10 ? stringValue.slice(0, 10) : stringValue;
    }

    function parseHours(hoursValue) {
        if (typeof hoursValue === "number") {
            return hoursValue;
        }

        if (!hoursValue) {
            return 0;
        }

        var text = String(hoursValue);
        if (text.indexOf(":") !== -1) {
            var parts = text.split(":");
            var hours = Number(parts[0] || 0);
            var minutes = Number(parts[1] || 0);
            return hours + (minutes / 60);
        }

        return Number(text) || 0;
    }

    TaskTimeChart {
        id: chartFlow
        anchors.fill: parent
        projectsModel: root.projectsModel
        projectTasksProvider: root.loadTasksForProject
        taskLogsProvider: root.loadLogsForTask
    }

    Component.onCompleted: reloadData()
}
