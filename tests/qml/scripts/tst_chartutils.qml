import QtQuick 2.7
import QtTest 1.0
import "../../../qml/features/dashboard/js/chartUtils.js" as ChartUtils

Item {
    width: 200
    height: 200

    TestCase {
        name: "ChartUtilsTests"
        when: windowShown

        function test_formatHours() {
            compare(ChartUtils.formatHours(2.5), "2.5 h");
            compare(ChartUtils.formatHours(0), "0.0 h");
            compare(ChartUtils.formatHours(null), "0.0 h");
            compare(ChartUtils.formatHours(undefined), "0.0 h");
            compare(ChartUtils.formatHours(10.123), "10.1 h");
        }

        function test_calcPercent_and_percentLabel() {
            compare(ChartUtils.calcPercent(25, 100), 25);
            compare(ChartUtils.calcPercent(0, 100), 0);
            compare(ChartUtils.calcPercent(5, 0), 0);
            compare(ChartUtils.calcPercent(5, -10), 0);
            compare(ChartUtils.calcPercent(null, 100), 0);

            compare(ChartUtils.percentLabel(25, 100), "25.0%");
            compare(ChartUtils.percentLabel(1, 3), "33.3%");
            compare(ChartUtils.percentLabel(0, 0), "0.0%");
        }

        function test_averageLabel() {
            compare(ChartUtils.averageLabel(10, 2), "5.0 h");
            compare(ChartUtils.averageLabel(10, 0), "0.0 h");
            compare(ChartUtils.averageLabel(10, -5), "0.0 h");
            compare(ChartUtils.averageLabel(null, 2), "0.0 h");
        }

        function test_projectSummaries() {
            var projects = [
                { id: 1, name: "Project Alpha", totalHours: 12.5, taskCount: 3 },
                { id: 2, name: "Project Beta", totalHours: 8.0, taskCount: 2 },
                { id: 3, name: "Project Gamma", totalHours: 20.0, taskCount: 5 }
            ];

            compare(ChartUtils.sumProjectHours(projects), 40.5);
            compare(ChartUtils.maxProjectHours(projects), 20.0);
            compare(ChartUtils.projectSubtitle(projects[0], 3), "3 tasks | 12.5 h");
            compare(ChartUtils.projectSubtitle(null, 0), "");
        }

        function test_taskSummaries() {
            var tasks = [
                { id: 10, name: "Refactor API", totalHours: 4.5 },
                { id: 20, name: "Fix UI Glitch", totalHours: 9.0 },
                { id: 30, name: "Write Docs", totalHours: 2.0 }
            ];

            compare(ChartUtils.maxTaskHours(tasks), 9.0);
            compare(ChartUtils.topTaskName(tasks), "Fix UI Glitch");
            compare(ChartUtils.topTaskName([]), "None");
            compare(ChartUtils.topTaskName(null), "None");

            var top2 = ChartUtils.topTasks(tasks, 2);
            compare(top2.length, 2);
            compare(top2[0].name, "Fix UI Glitch");
            compare(top2[1].name, "Refactor API");
        }

        function test_prepareProjects_sorting_and_filtering() {
            var projects = [
                { id: 1, name: "Backend Work", totalHours: 10.0, taskCount: 2 },
                { id: 2, name: "Frontend UI", totalHours: 25.0, taskCount: 8 },
                { id: 3, name: "DevOps Pipeline", totalHours: 15.0, taskCount: 1 }
            ];

            // Default sort: totalHours desc
            var sortedByHours = ChartUtils.prepareProjects(projects, "hours", "");
            compare(sortedByHours.length, 3);
            compare(sortedByHours[0].projectData.name, "Frontend UI");
            compare(sortedByHours[1].projectData.name, "DevOps Pipeline");
            compare(sortedByHours[2].projectData.name, "Backend Work");

            // Sort by tasks desc
            var sortedByTasks = ChartUtils.prepareProjects(projects, "tasks", "");
            compare(sortedByTasks[0].projectData.name, "Frontend UI"); // 8 tasks
            compare(sortedByTasks[1].projectData.name, "Backend Work"); // 2 tasks
            compare(sortedByTasks[2].projectData.name, "DevOps Pipeline"); // 1 task

            // Sort by name asc
            var sortedByName = ChartUtils.prepareProjects(projects, "name", "");
            compare(sortedByName[0].projectData.name, "Backend Work");
            compare(sortedByName[1].projectData.name, "DevOps Pipeline");
            compare(sortedByName[2].projectData.name, "Frontend UI");

            // Filter with search text
            var filtered = ChartUtils.prepareProjects(projects, "hours", "backend");
            compare(filtered.length, 1);
            compare(filtered[0].projectData.name, "Backend Work");
        }

        function test_prepareTasks_sorting() {
            var tasks = [
                { id: 1, name: "Task B", totalHours: 5.0 },
                { id: 2, name: "Task A", totalHours: 10.0 },
                { id: 3, name: "Task C", totalHours: 5.0 }
            ];

            var sorted = ChartUtils.prepareTasks(tasks);
            compare(sorted[0].name, "Task A"); // 10.0 hours
            compare(sorted[1].name, "Task B"); // 5.0 hours, alphabetical A before C
            compare(sorted[2].name, "Task C"); // 5.0 hours
        }

        function test_findTaskById() {
            var tasks = [
                { id: 101, name: "Design mockups" },
                { id: 102, name: "Implement code" }
            ];

            var found = ChartUtils.findTaskById(tasks, 102);
            verify(found !== null);
            compare(found.name, "Implement code");

            compare(ChartUtils.findTaskById(tasks, 999), null);
        }

        function test_elide() {
            compare(ChartUtils.elide("Short", 10), "Short");
            compare(ChartUtils.elide("Long text that should be truncated", 12), "Long text...");
            compare(ChartUtils.elide("", 5), "");
            compare(ChartUtils.elide(null, 5), "");
        }

        function test_chartSignature() {
            var tasks = [
                { id: 1, totalHours: 3.5 },
                { id: 2, totalHours: 7.0 }
            ];

            var sig = ChartUtils.chartSignature(tasks, "#ff0000", 0);
            compare(sig, "#ff0000|0|1:3.5|2:7");
        }
    }
}
