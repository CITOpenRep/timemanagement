import QtQuick 2.12
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components/pickers"

MainView {
    id: testRoot
    width: units.gu(40)
    height: units.gu(70)

    DateRangeSelector {
        id: testDateRangeSelector
        width: testRoot.width
    }

    SignalSpy {
        id: rangeChangedSpy
        target: testDateRangeSelector
        signalName: "rangeChanged"
    }

    TestCase {
        name: "DateRangeSelectorTests"
        when: windowShown

        function init() {
            testDateRangeSelector.readOnly = false;
            rangeChangedSpy.clear();
        }

        function cleanup() {
            testDateRangeSelector.readOnly = false;
            rangeChangedSpy.clear();
        }

        function test_initialProperties() {
            verify(testDateRangeSelector.startDate instanceof Date);
            verify(testDateRangeSelector.endDate instanceof Date);
            compare(testDateRangeSelector.readOnly, false);
            compare(testDateRangeSelector.isStartDateValid, true);
            compare(testDateRangeSelector.isEndDateValid, true);
        }

        function test_formattedDateStrings() {
            var s = new Date(2026, 8, 15); // 2026-09-15
            var e = new Date(2026, 8, 20); // 2026-09-20
            testDateRangeSelector.setDateRange(s, e);

            compare(testDateRangeSelector.formattedStartDate(), "2026-09-15");
            compare(testDateRangeSelector.formattedEndDate(), "2026-09-20");
        }

        function test_setDateRangeWithDateObjects() {
            var start = new Date(2026, 5, 1);
            var end = new Date(2026, 5, 30);
            rangeChangedSpy.clear();

            testDateRangeSelector.setDateRange(start, end);

            compare(rangeChangedSpy.count, 1);
            compare(testDateRangeSelector.isStartDateValid, true);
            compare(testDateRangeSelector.isEndDateValid, true);
            compare(testDateRangeSelector.startDate.getFullYear(), 2026);
            compare(testDateRangeSelector.startDate.getMonth(), 5);
            compare(testDateRangeSelector.startDate.getDate(), 1);
            compare(testDateRangeSelector.endDate.getDate(), 30);
        }

        function test_setDateRangeWithStringInputs() {
            rangeChangedSpy.clear();
            testDateRangeSelector.setDateRange("2026-11-05", "2026-11-25");

            compare(rangeChangedSpy.count, 1);
            compare(testDateRangeSelector.isStartDateValid, true);
            compare(testDateRangeSelector.isEndDateValid, true);
            compare(testDateRangeSelector.formattedStartDate(), "2026-11-05");
            compare(testDateRangeSelector.formattedEndDate(), "2026-11-25");
        }

        function test_setDateRangeInvalidBoundsHandling() {
            testDateRangeSelector.setDateRange("not-a-date", null);

            compare(testDateRangeSelector.isStartDateValid, false);
            compare(testDateRangeSelector.isEndDateValid, false);
        }

        function test_updateDatesPresetToday() {
            var preset = testDateRangeSelector.children[0].children[0]; // InlineOptionSelector
            verify(preset !== null);

            preset.selectedId = 0; // Today
            rangeChangedSpy.clear();
            testDateRangeSelector.updateDates();

            compare(rangeChangedSpy.count, 1);
            compare(testDateRangeSelector.isStartDateValid, true);
            compare(testDateRangeSelector.isEndDateValid, true);
            var today = new Date();
            compare(testDateRangeSelector.startDate.getDate(), today.getDate());
            compare(testDateRangeSelector.endDate.getDate(), today.getDate());
        }

        function test_updateDatesPresetThisMonth() {
            var preset = testDateRangeSelector.children[0].children[0];
            verify(preset !== null);

            preset.selectedId = 3; // This Month
            rangeChangedSpy.clear();
            testDateRangeSelector.updateDates();

            compare(rangeChangedSpy.count, 1);
            var today = new Date();
            compare(testDateRangeSelector.startDate.getMonth(), today.getMonth());
            compare(testDateRangeSelector.endDate.getMonth(), today.getMonth());
            verify(testDateRangeSelector.endDate.getDate() >= 28);
        }

        function test_readOnlyStateToggling() {
            testDateRangeSelector.readOnly = true;
            compare(testDateRangeSelector.readOnly, true);

            testDateRangeSelector.readOnly = false;
            compare(testDateRangeSelector.readOnly, false);
        }
    }
}
