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

    TimeRecorderWidget {
        id: testWidget
        width: testRoot.width
    }

    SignalSpy {
        id: invalidtimesheetSpy
        target: testWidget
        signalName: "invalidtimesheet"
    }

    SignalSpy {
        id: requestAutoSaveSpy
        target: testWidget
        signalName: "requestAutoSave"
    }

    SignalSpy {
        id: beforeStopSpy
        target: testWidget
        signalName: "beforeStop"
    }

    SignalSpy {
        id: stoppedSpy
        target: testWidget
        signalName: "stopped"
    }

    TestCase {
        name: "TimeRecorderWidgetTests"
        when: windowShown

        function init() {
            testWidget.isRecording = false;
            testWidget.autoMode = false;
            testWidget.elapsedTime = "01:00";
            testWidget.timesheetId = 0;

            invalidtimesheetSpy.clear();
            requestAutoSaveSpy.clear();
            beforeStopSpy.clear();
            stoppedSpy.clear();
        }

        function cleanup() {
            invalidtimesheetSpy.clear();
            requestAutoSaveSpy.clear();
            beforeStopSpy.clear();
            stoppedSpy.clear();
        }

        function test_initialProperties() {
            compare(testWidget.isRecording, false);
            compare(testWidget.autoMode, false);
            compare(testWidget.elapsedTime, "01:00");
            compare(testWidget.timesheetId, 0);
            compare(invalidtimesheetSpy.count, 0);
        }

        function test_tryStartTimerInvalidTimesheet() {
            testWidget.timesheetId = 0;
            testWidget.tryStartTimer();
            compare(invalidtimesheetSpy.count, 1);

            testWidget.timesheetId = -5;
            testWidget.tryStartTimer();
            compare(invalidtimesheetSpy.count, 2);
        }

        function test_modeToggle() {
            testWidget.autoMode = true;
            compare(testWidget.autoMode, true);

            testWidget.autoMode = false;
            compare(testWidget.autoMode, false);
        }

        function test_elapsedTimeAssignment() {
            testWidget.elapsedTime = "03:45";
            compare(testWidget.elapsedTime, "03:45");
        }

        function test_signalsEmission() {
            compare(beforeStopSpy.count, 0);
            testWidget.beforeStop();
            compare(beforeStopSpy.count, 1);

            compare(stoppedSpy.count, 0);
            testWidget.stopped();
            compare(stoppedSpy.count, 1);

            compare(requestAutoSaveSpy.count, 0);
            testWidget.requestAutoSave();
            compare(requestAutoSaveSpy.count, 1);
        }
    }
}
