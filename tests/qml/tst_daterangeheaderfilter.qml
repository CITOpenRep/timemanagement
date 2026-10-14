import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components/pickers"

MainView {
    id: testRoot
    width: units.gu(40)
    height: units.gu(70)

    DateRangeHeaderFilter {
        id: testHeaderFilter
        width: testRoot.width
    }

    SignalSpy {
        id: dateRangeChangedSpy
        target: testHeaderFilter
        signalName: "dateRangeChanged"
    }

    TestCase {
        name: "DateRangeHeaderFilterTests"
        when: windowShown

        function init() {
            testHeaderFilter.clearFilter();
            testHeaderFilter.showClearButton = true;
            dateRangeChangedSpy.clear();
        }

        function cleanup() {
            testHeaderFilter.clearFilter();
            dateRangeChangedSpy.clear();
        }

        function test_initialProperties() {
            compare(testHeaderFilter.presetId, -1);
            compare(testHeaderFilter.startDate, "");
            compare(testHeaderFilter.endDate, "");
            compare(testHeaderFilter.isFiltered, false);
            compare(testHeaderFilter.presetLabel, "No Filter (All Time)");
            compare(testHeaderFilter.showClearButton, true);
            compare(dateRangeChangedSpy.count, 0);
        }

        function test_calculateDatesToday() {
            var dates = testHeaderFilter.calculateDates(0); // Today
            var todayStr = Qt.formatDate(new Date(), "yyyy-MM-dd");
            compare(dates.start, todayStr);
            compare(dates.end, todayStr);
        }

        function test_calculateDatesThisMonth() {
            var dates = testHeaderFilter.calculateDates(2); // This Month
            var now = new Date();
            var expectedMonthPrefix = Qt.formatDate(now, "yyyy-MM");
            verify(dates.start.indexOf(expectedMonthPrefix + "-01") === 0);
            verify(dates.end.indexOf(expectedMonthPrefix) === 0);
        }

        function test_calculateDatesThisYear() {
            var dates = testHeaderFilter.calculateDates(4); // This Year
            var y = new Date().getFullYear();
            compare(dates.start, y + "-01-01");
            compare(dates.end, y + "-12-31");
        }

        function test_setFilterStateUpdatesPropertiesAndEmitsSignal() {
            testHeaderFilter.setFilterState(1, "2026-10-12", "2026-10-18", "This Week");

            compare(testHeaderFilter.presetId, 1);
            compare(testHeaderFilter.startDate, "2026-10-12");
            compare(testHeaderFilter.endDate, "2026-10-18");
            compare(testHeaderFilter.presetLabel, "This Week");
            compare(testHeaderFilter.isFiltered, true);

            compare(dateRangeChangedSpy.count, 1);
            var args = dateRangeChangedSpy.signalArguments[0];
            compare(args[0], 1);
            compare(args[1], "2026-10-12");
            compare(args[2], "2026-10-18");
            compare(args[3], "This Week");
        }

        function test_applyPresetTodayTogglesFilterAndRangeText() {
            testHeaderFilter.applyPreset(0, "Today");

            compare(testHeaderFilter.isFiltered, true);
            compare(testHeaderFilter.presetId, 0);
            compare(testHeaderFilter.presetLabel, "Today");
            verify(testHeaderFilter.startDate !== "");
            verify(testHeaderFilter.endDate !== "");
            compare(dateRangeChangedSpy.count, 1);
        }

        function test_clearFilterResetsActiveFilterAndRangeText() {
            testHeaderFilter.applyPreset(0, "Today");
            compare(testHeaderFilter.isFiltered, true);
            dateRangeChangedSpy.clear();

            testHeaderFilter.clearFilter();

            compare(testHeaderFilter.isFiltered, false);
            compare(testHeaderFilter.presetId, -1);
            compare(testHeaderFilter.startDate, "");
            compare(testHeaderFilter.endDate, "");
            compare(testHeaderFilter.presetLabel, "No Filter (All Time)");
            compare(dateRangeChangedSpy.count, 1);
            compare(dateRangeChangedSpy.signalArguments[0][0], -1);
        }

        function test_showClearButtonToggling() {
            testHeaderFilter.showClearButton = false;
            compare(testHeaderFilter.showClearButton, false);

            testHeaderFilter.showClearButton = true;
            compare(testHeaderFilter.showClearButton, true);
        }
    }
}
