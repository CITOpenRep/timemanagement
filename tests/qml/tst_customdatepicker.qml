import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import "../../qml/components/pickers"

MainView {
    id: testRoot
    width: units.gu(40)
    height: units.gu(70)

    CustomDatePicker {
        id: testDatePicker
    }

    SignalSpy {
        id: dateSelectedSpy
        target: testDatePicker
        signalName: "dateSelected"
    }

    TestCase {
        name: "CustomDatePickerTests"
        when: windowShown

        function init() {
            testDatePicker.titleText = "Select Date";
            testDatePicker.selected_date = "";
            testDatePicker.mode = "next";
            testDatePicker.showCustomPicker = false;
            testDatePicker.tempCustomDate = "";
            testDatePicker.currentDate = "";
            dateSelectedSpy.clear();
        }

        function test_initialProperties() {
            compare(testDatePicker.titleText, "Select Date");
            compare(testDatePicker.selected_date, "");
            compare(testDatePicker.mode, "next");
            compare(testDatePicker.showCustomPicker, false);
            compare(testDatePicker.tempCustomDate, "");
            compare(testDatePicker.currentDate, "");
        }

        function test_customTitleText() {
            testDatePicker.titleText = "Schedule Follow-up";
            compare(testDatePicker.titleText, "Schedule Follow-up");
        }

        function test_modeSwitching() {
            testDatePicker.mode = "previous";
            compare(testDatePicker.mode, "previous");

            testDatePicker.mode = "next";
            compare(testDatePicker.mode, "next");
        }

        function test_selectedDatePropertyUpdate() {
            testDatePicker.selected_date = "2026-09-25";
            compare(testDatePicker.selected_date, "2026-09-25");
        }

        function test_currentDatePropertyUpdate() {
            testDatePicker.currentDate = "2026-09-20";
            compare(testDatePicker.currentDate, "2026-09-20");
        }

        function test_showCustomPickerToggle() {
            testDatePicker.showCustomPicker = true;
            compare(testDatePicker.showCustomPicker, true);

            testDatePicker.showCustomPicker = false;
            compare(testDatePicker.showCustomPicker, false);
        }

        function test_dateSelectedSignalEmission() {
            var targetDate = "2026-10-15";
            testDatePicker.dateSelected(targetDate);

            compare(dateSelectedSpy.count, 1);
            compare(dateSelectedSpy.signalArguments[0][0], targetDate);
        }

        function test_openResetsCustomPickerState() {
            testDatePicker.showCustomPicker = true;
            compare(testDatePicker.showCustomPicker, true);

            testDatePicker.open();
            compare(testDatePicker.showCustomPicker, false);
        }
    }
}
