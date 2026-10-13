import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components/pickers"

MainView {
    id: testRoot
    width: units.gu(40)
    height: units.gu(70)

    Item {
        id: headerContainer
        width: testRoot.width
        height: units.gu(7)

        FilterableHeaderContents {
            id: testFilterableHeader
        }
    }

    SignalSpy {
        id: dateRangeChangedSpy
        target: testFilterableHeader
        signalName: "dateRangeChanged"
    }

    TestCase {
        name: "FilterableHeaderContentsTests"
        when: windowShown

        function init() {
            testFilterableHeader.showDateFilter = false;
            testFilterableHeader.title = "";
            testFilterableHeader.showSubtitle = true;
            testFilterableHeader.userLabel = "";
            dateRangeChangedSpy.clear();
        }

        function cleanup() {
            testFilterableHeader.showDateFilter = false;
            dateRangeChangedSpy.clear();
        }

        function test_initialProperties() {
            compare(testFilterableHeader.showDateFilter, false);
            compare(testFilterableHeader.title, "");
            compare(testFilterableHeader.showSubtitle, true);
            compare(testFilterableHeader.userLabel, "");
            verify(testFilterableHeader.dateFilter !== null);
            compare(dateRangeChangedSpy.count, 0);
        }

        function test_titleAndSubtitleIntegration() {
            testFilterableHeader.title = "Project Tasks";
            testFilterableHeader.userLabel = "Bob Smith";

            compare(testFilterableHeader.title, "Project Tasks");
            compare(testFilterableHeader.userLabel, "Bob Smith");

            var normalRow = testFilterableHeader.children[0];
            verify(normalRow.visible);

            var titleCol = normalRow.children[0];
            var titleLabel = titleCol.children[0];
            var subtitleLabel = titleCol.children[1];

            compare(titleLabel.text, "Project Tasks");
            verify(subtitleLabel.text.indexOf("Bob Smith") !== -1);
            verify(subtitleLabel.text.indexOf(" • ") !== -1);
        }

        function test_subtitleWithoutUserLabel() {
            testFilterableHeader.userLabel = "";

            var normalRow = testFilterableHeader.children[0];
            var titleCol = normalRow.children[0];
            var subtitleLabel = titleCol.children[1];

            compare(subtitleLabel.text, testFilterableHeader.dateFilter.presetLabel);
        }

        function test_showDateFilterToggleSwitchesViews() {
            var normalView = testFilterableHeader.children[0];
            var filterView = testFilterableHeader.children[1];

            // Initially normal is visible, filter view hidden
            compare(normalView.visible, true);
            compare(filterView.visible, false);

            // Toggle showDateFilter = true
            testFilterableHeader.showDateFilter = true;
            compare(normalView.visible, false);
            compare(filterView.visible, true);

            // Toggle back
            testFilterableHeader.showDateFilter = false;
            compare(normalView.visible, true);
            compare(filterView.visible, false);
        }

        function test_closeFilterButtonClickResetsState() {
            testFilterableHeader.showDateFilter = true;
            compare(testFilterableHeader.showDateFilter, true);

            var filterView = testFilterableHeader.children[1];
            var closeBtn = filterView.children[1]; // closeFilterBtn
            var closeMouse = closeBtn.children[1]; // MouseArea

            mouseClick(closeMouse);

            compare(testFilterableHeader.showDateFilter, false);
        }

        function test_dateFilterRangeChangedSignalIntegration() {
            testFilterableHeader.showDateFilter = true;
            dateRangeChangedSpy.clear();

            // Simulate DateRangeHeaderFilter triggering range change
            testFilterableHeader.dateFilter.applyPreset(0, "Today");

            compare(dateRangeChangedSpy.count, 1);
            // Once filter is applied, showDateFilter should automatically reset to false
            compare(testFilterableHeader.showDateFilter, false);
        }
    }
}
