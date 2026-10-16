import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/features/tasks/components"

MainView {
    id: testRoot
    width: units.gu(50)
    height: units.gu(70)

    TaskScheduleFields {
        id: testFields
        availableWidth: testRoot.width
    }

    SignalSpy {
        id: hoursChangedSpy
        target: testFields
        signalName: "hoursChanged"
    }

    SignalSpy {
        id: deadlineChangedSpy
        target: testFields
        signalName: "deadlineChanged"
    }

    SignalSpy {
        id: dateRangeChangedSpy
        target: testFields
        signalName: "dateRangeChanged"
    }

    TestCase {
        name: "TaskScheduleFieldsTests"
        when: windowShown

        function init() {
            testFields.isReadOnly = false;
            testFields.hoursText = "01:00";
            testFields.deadlineText = "Not set";
            hoursChangedSpy.clear();
            deadlineChangedSpy.clear();
            dateRangeChangedSpy.clear();
        }

        function cleanup() {
            hoursChangedSpy.clear();
            deadlineChangedSpy.clear();
            dateRangeChangedSpy.clear();
        }

        function test_initialProperties() {
            compare(testFields.isReadOnly, false);
            compare(testFields.hoursText, "01:00");
            compare(testFields.deadlineText, "Not set");
            verify(testFields.dateRangeWidget !== null);
        }

        function test_hoursChangedSignalEmission() {
            testFields.hoursText = "03:30";
            compare(testFields.hoursText, "03:30");
            compare(hoursChangedSpy.count, 1);
            compare(hoursChangedSpy.signalArguments[0][0], "03:30");
        }

        function test_incdecHrsIncrement() {
            testFields.hoursText = "01:00";
            hoursChangedSpy.clear();

            testFields.incdecHrs(1);
            compare(testFields.hoursText, "2:00");
            verify(hoursChangedSpy.count >= 1);

            testFields.incdecHrs(1);
            compare(testFields.hoursText, "3:00");
        }

        function test_incdecHrsDecrement() {
            testFields.hoursText = "3:00";
            testFields.incdecHrs(-1);
            compare(testFields.hoursText, "2:00");

            testFields.incdecHrs(-1);
            compare(testFields.hoursText, "1:00");

            // Decrement should not go below 0 (clamped)
            testFields.incdecHrs(-1);
            compare(testFields.hoursText, "0:00");
        }

        function test_deadlineTextChange() {
            testFields.deadlineText = "2026-11-15";
            compare(testFields.deadlineText, "2026-11-15");
        }

        function test_readOnlyState() {
            testFields.isReadOnly = true;
            compare(testFields.isReadOnly, true);
            compare(testFields.dateRangeWidget.readOnly, true);
        }

        function test_setDateRangeFunction() {
            testFields.setDateRange("2026-10-01", "2026-10-10");
            verify(testFields.formattedStartDate() !== "");
            verify(testFields.formattedEndDate() !== "");
        }
    }
}
