import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/features/timesheets/components"

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

    TimeSheetDetailsCard {
        id: testCard
        width: testRoot.width
    }

    SignalSpy {
        id: editRequestedSpy
        target: testCard
        signalName: "editRequested"
    }

    SignalSpy {
        id: viewRequestedSpy
        target: testCard
        signalName: "viewRequested"
    }

    SignalSpy {
        id: deleteRequestedSpy
        target: testCard
        signalName: "deleteRequested"
    }

    SignalSpy {
        id: refreshSpy
        target: testCard
        signalName: "refresh"
    }

    TestCase {
        name: "TimeSheetDetailsCardTests"
        when: windowShown

        function init() {
            testCard.name = "";
            testCard.project = "";
            testCard.task = "";
            testCard.user = "";
            testCard.date = "";
            testCard.instance = "";
            testCard.spentHours = "0";
            testCard.quadrant = "Do";
            testCard.recordId = -1;
            testCard.accountId = -1;
            testCard.status = "";
            testCard.timer_on = false;
            testCard.timer_paused = false;
            testCard.hasDraft = false;

            editRequestedSpy.clear();
            viewRequestedSpy.clear();
            deleteRequestedSpy.clear();
            refreshSpy.clear();
        }

        function cleanup() {
            editRequestedSpy.clear();
            viewRequestedSpy.clear();
            deleteRequestedSpy.clear();
            refreshSpy.clear();
        }

        function test_initialProperties() {
            compare(testCard.name, "");
            compare(testCard.project, "");
            compare(testCard.task, "");
            compare(testCard.user, "");
            compare(testCard.spentHours, "0");
            compare(testCard.quadrant, "Do");
            compare(testCard.recordId, -1);
            compare(testCard.accountId, -1);
            compare(testCard.timer_on, false);
            compare(testCard.timer_paused, false);
            compare(testCard.hasDraft, false);
            compare(testCard.height, units.gu(12));
        }

        function test_propertyAssignments() {
            testCard.name = "Refactor components";
            testCard.project = "TMM App";
            testCard.task = "Sprint Planning";
            testCard.user = "Developer";
            testCard.date = "2026-10-16";
            testCard.instance = "Production";
            testCard.spentHours = "3:30";
            testCard.quadrant = "Schedule";
            testCard.recordId = 456;
            testCard.accountId = 2;
            testCard.status = "draft";
            testCard.hasDraft = true;

            compare(testCard.name, "Refactor components");
            compare(testCard.project, "TMM App");
            compare(testCard.task, "Sprint Planning");
            compare(testCard.user, "Developer");
            compare(testCard.date, "2026-10-16");
            compare(testCard.instance, "Production");
            compare(testCard.spentHours, "3:30");
            compare(testCard.quadrant, "Schedule");
            compare(testCard.recordId, 456);
            compare(testCard.accountId, 2);
            compare(testCard.status, "draft");
            compare(testCard.hasDraft, true);
        }

        function test_signalsEmission() {
            testCard.recordId = 789;

            compare(editRequestedSpy.count, 0);
            testCard.editRequested(789);
            compare(editRequestedSpy.count, 1);
            compare(editRequestedSpy.signalArguments[0][0], 789);

            compare(viewRequestedSpy.count, 0);
            testCard.viewRequested(789);
            compare(viewRequestedSpy.count, 1);
            compare(viewRequestedSpy.signalArguments[0][0], 789);

            compare(deleteRequestedSpy.count, 0);
            testCard.deleteRequested(789);
            compare(deleteRequestedSpy.count, 1);
            compare(deleteRequestedSpy.signalArguments[0][0], 789);

            compare(refreshSpy.count, 0);
            testCard.refresh();
            compare(refreshSpy.count, 1);
        }
    }
}
