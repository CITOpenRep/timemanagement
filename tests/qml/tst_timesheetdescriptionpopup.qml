import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/features/timesheets/components"

MainView {
    id: testRoot
    width: units.gu(50)
    height: units.gu(70)

    TimeSheetDescriptionPopup {
        id: testPopup
    }

    SignalSpy {
        id: savedSpy
        target: testPopup
        signalName: "saved"
    }

    SignalSpy {
        id: finalizedSpy
        target: testPopup
        signalName: "finalized"
    }

    SignalSpy {
        id: cancelledSpy
        target: testPopup
        signalName: "cancelled"
    }

    TestCase {
        name: "TimeSheetDescriptionPopupTests"
        when: windowShown

        function init() {
            testPopup.timesheetId = 0;
            testPopup.timesheetName = "";
            testPopup.elapsedTime = "";
            testPopup.hasTask = false;
            testPopup.isLocalAccount = false;

            savedSpy.clear();
            finalizedSpy.clear();
            cancelledSpy.clear();
        }

        function cleanup() {
            savedSpy.clear();
            finalizedSpy.clear();
            cancelledSpy.clear();
        }

        function test_initialProperties() {
            compare(testPopup.timesheetId, 0);
            compare(testPopup.timesheetName, "");
            compare(testPopup.elapsedTime, "");
            compare(testPopup.hasTask, false);
            compare(testPopup.isLocalAccount, false);
        }

        function test_updateTimesheetDescriptionInvalidId() {
            testPopup.timesheetId = 0;
            var res = testPopup.updateTimesheetDescription("Work done", "draft");
            compare(res.success, false);
            compare(res.error, "Invalid timesheet ID");

            testPopup.timesheetId = -1;
            var resNegative = testPopup.updateTimesheetDescription("Work done", "draft");
            compare(resNegative.success, false);
            compare(resNegative.error, "Invalid timesheet ID");
        }

        function test_propertyAssignments() {
            testPopup.timesheetId = 123;
            testPopup.timesheetName = "Initial meeting";
            testPopup.elapsedTime = "02:15";
            testPopup.hasTask = true;
            testPopup.isLocalAccount = true;

            compare(testPopup.timesheetId, 123);
            compare(testPopup.timesheetName, "Initial meeting");
            compare(testPopup.elapsedTime, "02:15");
            compare(testPopup.hasTask, true);
            compare(testPopup.isLocalAccount, true);
        }

        function test_signalsEmission() {
            compare(savedSpy.count, 0);
            testPopup.saved("Draft notes", "draft");
            compare(savedSpy.count, 1);
            compare(savedSpy.signalArguments[0][0], "Draft notes");
            compare(savedSpy.signalArguments[0][1], "draft");

            compare(finalizedSpy.count, 0);
            testPopup.finalized(true, "Finalized successfully");
            compare(finalizedSpy.count, 1);
            compare(finalizedSpy.signalArguments[0][0], true);
            compare(finalizedSpy.signalArguments[0][1], "Finalized successfully");

            compare(cancelledSpy.count, 0);
            testPopup.cancelled();
            compare(cancelledSpy.count, 1);
        }
    }
}
