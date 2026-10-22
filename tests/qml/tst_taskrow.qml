import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/features/dashboard/components"

MainView {
    id: testRoot
    width: units.gu(50)
    height: units.gu(30)

    TaskRow {
        id: testRow
        width: testRoot.width
    }

    SignalSpy {
        id: clickedSpy
        target: testRow
        signalName: "clicked"
    }

    TestCase {
        name: "TaskRowTests"
        when: windowShown

        function init() {
            testRow.taskData = {};
            testRow.projectTotalHours = 0;
            testRow.accentColour = "#E95420";
            clickedSpy.clear();
        }

        function cleanup() {
            clickedSpy.clear();
        }

        function test_initialProperties() {
            compare(testRow.projectTotalHours, 0);
            compare(testRow.accentColour, "#e95420");
            compare(testRow.implicitHeight, units.gu(8));
            compare(clickedSpy.count, 0);
        }

        function test_taskDataBinding() {
            testRow.taskData = {
                name: "Database Migration",
                totalHours: 12.5
            };
            testRow.projectTotalHours = 50.0;

            compare(testRow.taskData.name, "Database Migration");
            compare(testRow.taskData.totalHours, 12.5);
            compare(testRow.projectTotalHours, 50.0);
        }

        function test_accentColourCustomization() {
            testRow.accentColour = "#3498db";
            compare(testRow.accentColour, "#3498db");

            testRow.accentColour = "#2ecc71";
            compare(testRow.accentColour, "#2ecc71");
        }

        function test_clickedSignalEmission() {
            compare(clickedSpy.count, 0);
            mouseClick(testRow);
            compare(clickedSpy.count, 1);
        }
    }
}
