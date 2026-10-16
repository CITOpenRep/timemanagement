import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/features/dashboard/components"

MainView {
    id: testRoot
    width: units.gu(50)
    height: units.gu(70)

    TaskChartCanvas {
        id: testCanvas
        width: testRoot.width
    }

    SignalSpy {
        id: taskSelectedSpy
        target: testCanvas
        signalName: "taskSelected"
    }

    TestCase {
        name: "TaskChartCanvasTests"
        when: windowShown

        function init() {
            testCanvas.tasksData = [];
            testCanvas.accentColour = "#E95420";
            testCanvas.highlightedIndex = -1;
            taskSelectedSpy.clear();
        }

        function cleanup() {
            taskSelectedSpy.clear();
        }

        function test_initialProperties() {
            compare(testCanvas.tasksData.length, 0);
            compare(testCanvas.maxHours, 1);
            compare(testCanvas.highlightedIndex, -1);
            verify(testCanvas.barColors.length > 0);
            compare(taskSelectedSpy.count, 0);
        }

        function test_tasksDataAndMaxHoursCalculation() {
            testCanvas.tasksData = [
                { id: "task_1", name: "UI Redesign", totalHours: 6.0 },
                { id: "task_2", name: "API Client", totalHours: 14.5 },
                { id: "task_3", name: "Testing", totalHours: 3.5 }
            ];

            compare(testCanvas.tasksData.length, 3);
            compare(testCanvas.maxHours, 14.5);
            verify(testCanvas.implicitHeight > units.gu(10));
        }

        function test_barColorsPalette() {
            var colors = testCanvas.barColors;
            verify(colors.indexOf("#E95420") !== -1);
            verify(colors.indexOf("#3498DB") !== -1);
            verify(colors.indexOf("#2ECC71") !== -1);
        }

        function test_taskSelectedSignalEmission() {
            compare(taskSelectedSpy.count, 0);
            testCanvas.taskSelected("task_42");
            compare(taskSelectedSpy.count, 1);
            compare(taskSelectedSpy.signalArguments[0][0], "task_42");
        }
    }
}
