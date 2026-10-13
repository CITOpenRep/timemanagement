import QtQuick 2.7
import QtTest 1.0

Item {
    id: root
    width: 200
    height: 200

    property var lastMessage: null

    WorkerScript {
        id: chartWorker
        source: "../../../qml/features/dashboard/js/chartWorker.js"
        onMessage: {
            root.lastMessage = messageObject;
        }
    }

    SignalSpy {
        id: messageSpy
        target: chartWorker
        signalName: "message"
    }

    TestCase {
        name: "ChartWorkerTests"
        when: windowShown

        function init() {
            root.lastMessage = null;
            messageSpy.clear();
        }

        function test_projectsMessageProcessing() {
            var projects = [
                { id: 1, name: "Backend Database", totalHours: 10.0, taskCount: 2 },
                { id: 2, name: "Frontend UI", totalHours: 30.0, taskCount: 8 },
                { id: 3, name: "DevOps Infrastructure", totalHours: 15.0, taskCount: 1 }
            ];

            // 1. Sort by totalHours descending
            chartWorker.sendMessage({
                mode: "projects",
                projects: projects,
                sortMode: "hours",
                searchText: ""
            });

            messageSpy.wait(2000);
            verify(root.lastMessage !== null);
            compare(root.lastMessage.mode, "projects");
            compare(root.lastMessage.items.length, 3);
            compare(root.lastMessage.items[0].projectData.name, "Frontend UI");
            compare(root.lastMessage.items[1].projectData.name, "DevOps Infrastructure");
            compare(root.lastMessage.items[2].projectData.name, "Backend Database");

            // 2. Filter by search query
            messageSpy.clear();
            root.lastMessage = null;
            chartWorker.sendMessage({
                mode: "projects",
                projects: projects,
                sortMode: "hours",
                searchText: "backend"
            });

            messageSpy.wait(2000);
            verify(root.lastMessage !== null);
            compare(root.lastMessage.items.length, 1);
            compare(root.lastMessage.items[0].projectData.name, "Backend Database");
        }

        function test_tasksMessageProcessing() {
            var tasks = [
                { id: 10, name: "Low priority task", totalHours: 3.0 },
                { id: 20, name: "High priority task", totalHours: 18.5 },
                { id: 30, name: "Medium priority task", totalHours: 8.0 }
            ];

            chartWorker.sendMessage({
                mode: "tasks",
                projectId: 99,
                tasks: tasks
            });

            messageSpy.wait(2000);
            verify(root.lastMessage !== null);
            compare(root.lastMessage.mode, "tasks");
            compare(root.lastMessage.projectId, 99);
            compare(root.lastMessage.items.length, 3);
            compare(root.lastMessage.items[0].name, "High priority task");
            compare(root.lastMessage.items[1].name, "Medium priority task");
            compare(root.lastMessage.items[2].name, "Low priority task");
        }
    }
}
