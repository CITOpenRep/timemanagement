import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/features/tasks/components"

MainView {
    id: testRoot
    width: units.gu(50)
    height: units.gu(70)

    Item {
        id: globalTimerWidget
        signal timerStopped()
        signal timerStarted()
        signal timerPaused()
        signal timerResumed()
    }

    TaskDetailsCard {
        id: testCard
        width: testRoot.width
    }

    SignalSpy {
        id: editRequestedSpy
        target: testCard
        signalName: "editRequested"
    }

    SignalSpy {
        id: deleteRequestedSpy
        target: testCard
        signalName: "deleteRequested"
    }

    SignalSpy {
        id: viewRequestedSpy
        target: testCard
        signalName: "viewRequested"
    }

    SignalSpy {
        id: timesheetRequestedSpy
        target: testCard
        signalName: "timesheetRequested"
    }

    SignalSpy {
        id: taskUpdatedSpy
        target: testCard
        signalName: "taskUpdated"
    }

    SignalSpy {
        id: taskStageChangedSpy
        target: testCard
        signalName: "taskStageChanged"
    }

    SignalSpy {
        id: navigationRequestedSpy
        target: testCard
        signalName: "navigationRequested"
    }

    TestCase {
        name: "TaskDetailsCardTests"
        when: windowShown

        function init() {
            testCard.taskName = "";
            testCard.projectName = "";
            testCard.priority = 0;
            testCard.allocatedHours = 0;
            testCard.spentHours = 0;
            testCard.deadline = "";
            testCard.localId = -1;
            testCard.recordId = -1;
            testCard.idVal = -1;
            testCard.accountId = -1;
            testCard.stage = -1;
            testCard.hasChildren = false;
            testCard.flatViewMode = false;
            testCard.hasDraft = false;

            editRequestedSpy.clear();
            deleteRequestedSpy.clear();
            viewRequestedSpy.clear();
            timesheetRequestedSpy.clear();
            taskUpdatedSpy.clear();
            taskStageChangedSpy.clear();
            navigationRequestedSpy.clear();
        }

        function cleanup() {
            editRequestedSpy.clear();
            deleteRequestedSpy.clear();
            viewRequestedSpy.clear();
            timesheetRequestedSpy.clear();
            taskUpdatedSpy.clear();
            taskStageChangedSpy.clear();
            navigationRequestedSpy.clear();
        }

        function test_initialProperties() {
            compare(testCard.priority, 0);
            compare(testCard.taskName, "");
            compare(testCard.projectName, "");
            compare(testCard.allocatedHours, 0);
            compare(testCard.spentHours, 0);
            compare(testCard.deadline, "");
            compare(testCard.localId, -1);
            compare(testCard.recordId, -1);
            compare(testCard.idVal, -1);
            compare(testCard.hasChildren, false);
            compare(testCard.flatViewMode, false);
            compare(testCard.hasDraft, false);
            compare(testCard.timer_on, false);
            compare(testCard.timer_paused, false);
        }

        function test_propertyAssignments() {
            testCard.taskName = "Complete Testing";
            testCard.projectName = "Time Management";
            testCard.priority = 2;
            testCard.allocatedHours = 10.5;
            testCard.spentHours = 4.2;
            testCard.deadline = "2026-12-31";
            testCard.localId = 42;
            testCard.recordId = 1042;
            testCard.accountId = 1;
            testCard.hasDraft = true;

            compare(testCard.taskName, "Complete Testing");
            compare(testCard.projectName, "Time Management");
            compare(testCard.priority, 2);
            compare(testCard.allocatedHours, 10.5);
            compare(testCard.spentHours, 4.2);
            compare(testCard.deadline, "2026-12-31");
            compare(testCard.localId, 42);
            compare(testCard.recordId, 1042);
            compare(testCard.accountId, 1);
            compare(testCard.hasDraft, true);
        }

        function test_effectiveTaskIdCalculation() {
            // Case 1: idVal > 0 takes priority
            testCard.idVal = 99;
            testCard.localId = 10;
            testCard.recordId = 20;
            testCard.accountId = 1;
            compare(testCard.effectiveTaskId, 99);

            // Case 2: idVal <= 0, accountId === 0 uses localId
            testCard.idVal = -1;
            testCard.accountId = 0;
            testCard.localId = 15;
            testCard.recordId = 30;
            compare(testCard.effectiveTaskId, 15);

            // Case 3: idVal <= 0, recordId <= 0 uses localId
            testCard.idVal = -1;
            testCard.accountId = 1;
            testCard.localId = 25;
            testCard.recordId = 0;
            compare(testCard.effectiveTaskId, 25);

            // Case 4: normal remote account uses recordId
            testCard.idVal = -1;
            testCard.accountId = 1;
            testCard.localId = 25;
            testCard.recordId = 300;
            compare(testCard.effectiveTaskId, 300);
        }

        function test_signalsEmission() {
            testCard.localId = 88;

            compare(editRequestedSpy.count, 0);
            testCard.editRequested(88);
            compare(editRequestedSpy.count, 1);
            compare(editRequestedSpy.signalArguments[0][0], 88);

            compare(deleteRequestedSpy.count, 0);
            testCard.deleteRequested(88);
            compare(deleteRequestedSpy.count, 1);
            compare(deleteRequestedSpy.signalArguments[0][0], 88);

            compare(viewRequestedSpy.count, 0);
            testCard.viewRequested(88);
            compare(viewRequestedSpy.count, 1);
            compare(viewRequestedSpy.signalArguments[0][0], 88);

            compare(timesheetRequestedSpy.count, 0);
            testCard.timesheetRequested(88);
            compare(timesheetRequestedSpy.count, 1);
            compare(timesheetRequestedSpy.signalArguments[0][0], 88);

            compare(taskUpdatedSpy.count, 0);
            testCard.taskUpdated(88);
            compare(taskUpdatedSpy.count, 1);
            compare(taskUpdatedSpy.signalArguments[0][0], 88);

            compare(taskStageChangedSpy.count, 0);
            testCard.taskStageChanged(88);
            compare(taskStageChangedSpy.count, 1);
            compare(taskStageChangedSpy.signalArguments[0][0], 88);

            compare(navigationRequestedSpy.count, 0);
            testCard.navigationRequested(88, 1, "Sample Task");
            compare(navigationRequestedSpy.count, 1);
            compare(navigationRequestedSpy.signalArguments[0][0], 88);
            compare(navigationRequestedSpy.signalArguments[0][1], 1);
            compare(navigationRequestedSpy.signalArguments[0][2], "Sample Task");
        }
    }
}
