import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components/pickers"

MainView {
    id: testRoot
    width: units.gu(40)
    height: units.gu(70)

    DaySelector {
        id: testDaySelector
        width: testRoot.width
    }

    SignalSpy {
        id: dateChangedSpy
        target: testDaySelector
        signalName: "dateChanged"
    }

    TestCase {
        name: "DaySelectorTests"
        when: windowShown

        function init() {
            testDaySelector.readOnly = false;
            testDaySelector.showTomorrow = false;
            dateChangedSpy.clear();
        }

        function cleanup() {
            testDaySelector.readOnly = false;
            testDaySelector.showTomorrow = false;
            dateChangedSpy.clear();
        }

        function test_initialProperties() {
            compare(testDaySelector.labelText, "Date");
            verify(testDaySelector.selectedDate instanceof Date);
            compare(testDaySelector.showTomorrow, false);
            compare(testDaySelector.readOnly, false);
            compare(dateChangedSpy.count, 0);
        }

        function test_formattedDate() {
            var target = new Date(2026, 6, 25);
            testDaySelector.setSelectedDate(target);
            compare(testDaySelector.formattedDate(), "2026-07-25");
        }

        function test_relativeLabelYesterdayAndTomorrow() {
            testDaySelector.showTomorrow = false;
            compare(testDaySelector.getRelativeLabel(), "Yesterday");

            testDaySelector.showTomorrow = true;
            compare(testDaySelector.getRelativeLabel(), "Tomorrow");
        }

        function test_relativeDateCalculation() {
            var base = new Date(2026, 5, 10); // June 10

            testDaySelector.showTomorrow = false;
            var yesterday = testDaySelector.getRelativeDate(base);
            compare(yesterday.getDate(), 9);

            testDaySelector.showTomorrow = true;
            var tomorrow = testDaySelector.getRelativeDate(base);
            compare(tomorrow.getDate(), 11);
        }

        function test_isSameDateHelper() {
            var d1 = new Date(2026, 3, 15, 10, 30);
            var d2 = new Date(2026, 3, 15, 18, 45);
            var d3 = new Date(2026, 3, 16, 10, 30);

            verify(testDaySelector.isSameDate(d1, d2));
            verify(!testDaySelector.isSameDate(d1, d3));
            verify(!testDaySelector.isSameDate(null, d1));
            verify(!testDaySelector.isSameDate(d1, "invalid"));
        }

        function test_setSelectedDateWithDateObjectEmitsSignal() {
            var target = new Date(2026, 9, 31);
            dateChangedSpy.clear();

            testDaySelector.setSelectedDate(target);

            compare(dateChangedSpy.count, 1);
            var emittedDate = dateChangedSpy.signalArguments[0][0];
            verify(testDaySelector.isSameDate(emittedDate, target));
        }

        function test_setSelectedDateWithStringInputEmitsSignal() {
            dateChangedSpy.clear();
            testDaySelector.setSelectedDate("2026-12-25");

            compare(dateChangedSpy.count, 1);
            compare(testDaySelector.formattedDate(), "2026-12-25");
        }

        function test_setSelectedDateInvalidInputIgnored() {
            dateChangedSpy.clear();
            testDaySelector.setSelectedDate("not-a-valid-date");

            compare(dateChangedSpy.count, 0);
        }

        function test_updateDateRelativeSelection() {
            verify(testDaySelector.dayCombo !== null, "dayCombo alias should be accessible");

            testDaySelector.showTomorrow = false;
            testDaySelector.dayCombo.selectedId = 1; // Relative (Yesterday)
            dateChangedSpy.clear();

            testDaySelector.updateDate();

            compare(dateChangedSpy.count, 1);
            var expected = new Date();
            expected.setDate(expected.getDate() - 1);
            verify(testDaySelector.isSameDate(testDaySelector.selectedDate, expected));
        }

        function test_readOnlyToggle() {
            testDaySelector.readOnly = true;
            compare(testDaySelector.readOnly, true);

            testDaySelector.readOnly = false;
            compare(testDaySelector.readOnly, false);
        }
    }
}
