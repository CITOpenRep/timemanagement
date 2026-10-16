import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/features/dashboard/charts"

MainView {
    id: testRoot
    width: units.gu(50)
    height: units.gu(70)

    TaskTimeChart {
        id: testChart
        width: testRoot.width
    }

    SignalSpy {
        id: projectOpenedSpy
        target: testChart
        signalName: "projectOpened"
    }

    SignalSpy {
        id: taskOpenedSpy
        target: testChart
        signalName: "taskOpened"
    }

    SignalSpy {
        id: backNavigatedSpy
        target: testChart
        signalName: "backNavigated"
    }

    TestCase {
        name: "TaskTimeChartTests"
        when: windowShown

        function init() {
            testChart.projectsModel = [];
            testChart.currentView = "projects";
            testChart.selectedProject = null;
            testChart.selectedTask = null;
            testChart.selectedProjectTasks = [];
            testChart.selectedTaskLogs = [];
            testChart.portfolioSearchText = "";
            testChart.portfolioSortMode = "time";
            testChart.showAllTasks = false;

            projectOpenedSpy.clear();
            taskOpenedSpy.clear();
            backNavigatedSpy.clear();
        }

        function cleanup() {
            projectOpenedSpy.clear();
            taskOpenedSpy.clear();
            backNavigatedSpy.clear();
        }

        function test_initialProperties() {
            compare(testChart.currentView, "projects");
            compare(testChart.projectsModel.length, 0);
            compare(testChart.selectedProject, null);
            compare(testChart.selectedTask, null);
            compare(testChart.portfolioSortMode, "time");
            compare(testChart.portfolioSearchText, "");
            compare(testChart.portfolioTotalHours, 0);
            compare(testChart.portfolioMaxHours, 0);
            compare(projectOpenedSpy.count, 0);
        }

        function test_projectsModelCalculations() {
            testChart.projectsModel = [
                { id: "proj_1", name: "Web App", totalHours: 20.0, taskCount: 4, colour: "#3498DB" },
                { id: "proj_2", name: "Mobile Client", totalHours: 45.0, taskCount: 8, colour: "#E95420" }
            ];

            compare(testChart.portfolioTotalHours, 65.0);
            compare(testChart.portfolioMaxHours, 45.0);
            compare(testChart.visibleProjects.length, 2);
        }

        function test_openProjectNavigation() {
            var sampleProject = {
                id: "proj_1",
                name: "Web App",
                totalHours: 20.0,
                colour: "#3498DB"
            };

            testChart.openProject(sampleProject);
            compare(testChart.currentView, "project");
            compare(testChart.selectedProject.id, "proj_1");
            compare(projectOpenedSpy.count, 1);
            compare(projectOpenedSpy.signalArguments[0][0], "proj_1");
        }

        function test_openTaskNavigation() {
            var sampleProject = {
                id: "proj_1",
                name: "Web App",
                totalHours: 20.0,
                colour: "#3498DB"
            };
            var sampleTask = {
                id: "task_1",
                name: "Implement API",
                totalHours: 8.0
            };

            testChart.openProject(sampleProject);
            testChart.openTask(sampleTask);

            compare(testChart.currentView, "task");
            compare(testChart.selectedTask.id, "task_1");
            compare(taskOpenedSpy.count, 1);
            compare(taskOpenedSpy.signalArguments[0][0], "proj_1");
            compare(taskOpenedSpy.signalArguments[0][1], "task_1");
        }

        function test_goBackNavigationHierarchy() {
            var sampleProject = { id: "proj_1", name: "Web App", totalHours: 20.0 };
            var sampleTask = { id: "task_1", name: "API", totalHours: 8.0 };

            testChart.openProject(sampleProject);
            testChart.openTask(sampleTask);
            compare(testChart.currentView, "task");

            // First goBack returns from task to project view
            testChart.goBack();
            compare(testChart.currentView, "project");
            compare(backNavigatedSpy.count, 1);

            // Second goBack returns from project to projects view
            testChart.goBack();
            compare(testChart.currentView, "projects");
            compare(testChart.selectedProject, null);
            compare(backNavigatedSpy.count, 2);
        }

        function test_activeAccentColor() {
            compare(testChart.activeAccent, "#e95420");

            testChart.openProject({ id: "p1", name: "Custom", totalHours: 5, colour: "#2ecc71" });
            compare(testChart.activeAccent, "#2ecc71");
        }
    }
}
