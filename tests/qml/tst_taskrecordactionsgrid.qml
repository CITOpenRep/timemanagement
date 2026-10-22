import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/features/tasks/components"

MainView {
    id: testRoot
    width: units.gu(50)
    height: units.gu(70)

    TaskRecordActionsGrid {
        id: testGrid
        width: testRoot.width
    }

    SignalSpy {
        id: changeStageSpy
        target: testGrid
        signalName: "changeStageRequested"
    }

    SignalSpy {
        id: createActivitySpy
        target: testGrid
        signalName: "createActivityRequested"
    }

    SignalSpy {
        id: viewActivitiesSpy
        target: testGrid
        signalName: "viewActivitiesRequested"
    }

    SignalSpy {
        id: createTimesheetSpy
        target: testGrid
        signalName: "createTimesheetRequested"
    }

    SignalSpy {
        id: viewTimesheetsSpy
        target: testGrid
        signalName: "viewTimesheetsRequested"
    }

    TestCase {
        name: "TaskRecordActionsGridTests"
        when: windowShown

        function init() {
            testGrid.recordid = 0;
            testGrid.currentTask = null;
            changeStageSpy.clear();
            createActivitySpy.clear();
            viewActivitiesSpy.clear();
            createTimesheetSpy.clear();
            viewTimesheetsSpy.clear();
        }

        function cleanup() {
            testGrid.recordid = 0;
            testGrid.currentTask = null;
            changeStageSpy.clear();
            createActivitySpy.clear();
            viewActivitiesSpy.clear();
            createTimesheetSpy.clear();
            viewTimesheetsSpy.clear();
        }

        function test_initialProperties() {
            compare(testGrid.recordid, 0);
            compare(testGrid.currentTask, null);
            compare(testGrid.visible, false);
            compare(testGrid.columns, 3);
            compare(testGrid.rows, 3);
        }

        function test_visibilityOnRecordId() {
            testGrid.recordid = 101;
            compare(testGrid.visible, true);
            verify(testGrid.height > 0);

            testGrid.recordid = 0;
            compare(testGrid.visible, false);
            compare(testGrid.height, 0);
        }

        function test_signalEmissions() {
            testGrid.recordid = 101;

            compare(changeStageSpy.count, 0);
            testGrid.changeStageRequested();
            compare(changeStageSpy.count, 1);

            compare(createActivitySpy.count, 0);
            testGrid.createActivityRequested();
            compare(createActivitySpy.count, 1);

            compare(viewActivitiesSpy.count, 0);
            testGrid.viewActivitiesRequested();
            compare(viewActivitiesSpy.count, 1);

            compare(createTimesheetSpy.count, 0);
            testGrid.createTimesheetRequested();
            compare(createTimesheetSpy.count, 1);

            compare(viewTimesheetsSpy.count, 0);
            testGrid.viewTimesheetsRequested();
            compare(viewTimesheetsSpy.count, 1);
        }

        function test_currentTaskAssignment() {
            testGrid.recordid = 42;
            testGrid.currentTask = {
                id: 42,
                name: "Test Task",
                state: 1,
                account_id: 0
            };
            compare(testGrid.currentTask.name, "Test Task");
            compare(testGrid.currentTask.id, 42);
        }
    }
}
