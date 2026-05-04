// Utility helpers for formatting, percentages, and client-side chart sorting.
function formatHours(hours) {
    return Number(hours || 0).toFixed(1) + " h";
}

function calcPercent(value, total) {
    if (!total || total <= 0) {
        return 0;
    }
    return (Number(value || 0) / Number(total)) * 100;
}

function percentLabel(value, total) {
    return calcPercent(value, total).toFixed(1) + "%";
}

function averageLabel(totalHours, count) {
    if (!count || count <= 0) {
        return formatHours(0);
    }
    return formatHours(Number(totalHours || 0) / count);
}

function topTaskName(tasks) {
    if (!tasks || tasks.length === 0) {
        return "None";
    }
    var sorted = prepareTasks(tasks);
    return sorted.length > 0 ? sorted[0].name : "None";
}

function sumProjectHours(projects) {
    var total = 0;
    for (var i = 0; i < projects.length; i++) {
        total += Number(projects[i].totalHours || 0);
    }
    return total;
}

function maxProjectHours(projects) {
    var maxHours = 0;
    for (var i = 0; i < projects.length; i++) {
        maxHours = Math.max(maxHours, Number(projects[i].totalHours || 0));
    }
    return maxHours;
}

function projectSubtitle(project, taskCount) {
    if (!project) {
        return "";
    }
    return String(taskCount || 0) + " tasks | " + formatHours(project.totalHours || 0);
}

function topTasks(tasks, count) {
    var sorted = prepareTasks(tasks);
    return sorted.slice(0, count || 10);
}

function maxTaskHours(tasks) {
    var maxHours = 0;
    for (var i = 0; i < tasks.length; i++) {
        maxHours = Math.max(maxHours, Number(tasks[i].totalHours || 0));
    }
    return maxHours;
}

function prepareProjects(projects, sortMode, searchText) {
    var filtered = [];
    var query = (searchText || "").toLowerCase();

    for (var i = 0; i < projects.length; i++) {
        var project = projects[i];
        if (query && String(project.name || "").toLowerCase().indexOf(query) === -1) {
            continue;
        }
        filtered.push({
            projectId: project.id,
            projectData: project
        });
    }

    filtered.sort(function(a, b) {
        var left = a.projectData;
        var right = b.projectData;
        if (sortMode === "tasks") {
            return Number(right.taskCount || 0) - Number(left.taskCount || 0) ||
                   Number(right.totalHours || 0) - Number(left.totalHours || 0);
        }
        if (sortMode === "name") {
            return String(left.name || "").localeCompare(String(right.name || ""));
        }
        return Number(right.totalHours || 0) - Number(left.totalHours || 0) ||
               Number(right.taskCount || 0) - Number(left.taskCount || 0);
    });

    return filtered;
}

function prepareTasks(tasks) {
    var sorted = [];
    for (var i = 0; i < tasks.length; i++) {
        var task = tasks[i];
        sorted.push(task);
    }

    sorted.sort(function(a, b) {
        return Number(b.totalHours || 0) - Number(a.totalHours || 0) ||
               String(a.name || "").localeCompare(String(b.name || ""));
    });

    return sorted;
}

function elide(text, maxLength) {
    var value = String(text || "");
    if (value.length <= maxLength) {
        return value;
    }
    return value.slice(0, Math.max(0, maxLength - 3)) + "...";
}

function chartSignature(tasks, accentColour, highlightedIndex) {
    var parts = [String(accentColour), String(highlightedIndex)];
    for (var i = 0; i < tasks.length; i++) {
        parts.push(String(tasks[i].id) + ":" + String(tasks[i].totalHours));
    }
    return parts.join("|");
}

function findTaskById(tasks, taskId) {
    for (var i = 0; i < tasks.length; i++) {
        if (tasks[i].id === taskId) {
            return tasks[i];
        }
    }
    return null;
}
