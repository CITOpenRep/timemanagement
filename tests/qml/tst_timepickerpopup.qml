import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import "../../qml/components/dialogs"

MainView {
    id: testRoot
    width: units.gu(40)
    height: units.gu(70)

    TimePickerPopup {
        id: testTimePicker
    }

    SignalSpy {
        id: timeSelectedSpy
        target: testTimePicker
        signalName: "timeSelected"
    }

    TestCase {
        name: "TimePickerPopupTests"
        when: windowShown

        function init() {
            testTimePicker.initialHour = 1;
            testTimePicker.initialMinute = 0;
            timeSelectedSpy.clear();
        }

        function cleanup() {
            testTimePicker.initialHour = 1;
            testTimePicker.initialMinute = 0;
            timeSelectedSpy.clear();
        }

        function test_initialProperties() {
            compare(testTimePicker.initialHour, 1);
            compare(testTimePicker.initialMinute, 0);
            compare(timeSelectedSpy.count, 0);
        }

        function test_propertyUpdates() {
            testTimePicker.initialHour = 10;
            testTimePicker.initialMinute = 45;
            compare(testTimePicker.initialHour, 10);
            compare(testTimePicker.initialMinute, 45);
        }

        function test_openFunctionSetsInitialHourAndMinute() {
            testTimePicker.open(14, 30);
            compare(testTimePicker.initialHour, 14);
            compare(testTimePicker.initialMinute, 30);
        }

        function test_openWithoutArgumentsDefaultsToZero() {
            testTimePicker.initialHour = 5;
            testTimePicker.initialMinute = 25;

            testTimePicker.open();
            compare(testTimePicker.initialHour, 0);
            compare(testTimePicker.initialMinute, 0);
        }

        function test_timeSelectedSignalEmission() {
            testTimePicker.timeSelected(8, 40);

            compare(timeSelectedSpy.count, 1);
            var args = timeSelectedSpy.signalArguments[0];
            compare(args[0], 8);
            compare(args[1], 40);
        }

        function test_multipleTimeSelectionConfirmations() {
            testTimePicker.timeSelected(0, 0);
            compare(timeSelectedSpy.count, 1);
            compare(timeSelectedSpy.signalArguments[0][0], 0);
            compare(timeSelectedSpy.signalArguments[0][1], 0);

            testTimePicker.timeSelected(12, 30);
            compare(timeSelectedSpy.count, 2);
            compare(timeSelectedSpy.signalArguments[1][0], 12);
            compare(timeSelectedSpy.signalArguments[1][1], 30);

            testTimePicker.timeSelected(23, 55);
            compare(timeSelectedSpy.count, 3);
            compare(timeSelectedSpy.signalArguments[2][0], 23);
            compare(timeSelectedSpy.signalArguments[2][1], 55);
        }

        function test_boundaryTimeValues() {
            testTimePicker.open(23, 55);
            compare(testTimePicker.initialHour, 23);
            compare(testTimePicker.initialMinute, 55);

            testTimePicker.open(0, 0);
            compare(testTimePicker.initialHour, 0);
            compare(testTimePicker.initialMinute, 0);
        }
    }
}
