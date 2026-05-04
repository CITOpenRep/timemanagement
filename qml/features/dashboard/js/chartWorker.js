// WorkerScript helper for sorting and filtering larger chart datasets off the UI thread.
WorkerScript.onMessage = function(message) {
    if (message.mode === "projects") {
        var items = [];
        var query = String(message.searchText || "").toLowerCase();
        var projects = message.projects || [];

        for (var i = 0; i < projects.length; i++) {
            var project = projects[i];
            if (query && String(project.name || "").toLowerCase().indexOf(query) === -1) {
                continue;
            }
            items.push({
                projectId: project.id,
                projectData: project
            });
        }

        items.sort(function(a, b) {
            var left = a.projectData;
            var right = b.projectData;
            if (message.sortMode === "tasks") {
                return Number(right.taskCount || 0) - Number(left.taskCount || 0) ||
                       Number(right.totalHours || 0) - Number(left.totalHours || 0);
            }
            if (message.sortMode === "name") {
                return String(left.name || "").localeCompare(String(right.name || ""));
            }
            return Number(right.totalHours || 0) - Number(left.totalHours || 0) ||
                   Number(right.taskCount || 0) - Number(left.taskCount || 0);
        });

        WorkerScript.sendMessage({
            mode: "projects",
            items: items
        });
        return;
    }

    if (message.mode === "tasks") {
        var tasks = (message.tasks || []).slice(0);
        tasks.sort(function(a, b) {
            return Number(b.totalHours || 0) - Number(a.totalHours || 0) ||
                   String(a.name || "").localeCompare(String(b.name || ""));
        });
        WorkerScript.sendMessage({
            mode: "tasks",
            projectId: message.projectId,
            items: tasks
        });
    }
};
