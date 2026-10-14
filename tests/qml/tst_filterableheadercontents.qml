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

        function findItemWithText(root, text) {
            if (!root) return null;
            if (root.text && root.text.indexOf(text) !== -1) return root;
            for (var i = 0; i < (root.children ? root.children.length : 0); i++) {
                var found = findItemWithText(root.children[i], text);
                if (found) return found;
            }
            return null;
        }

        function findMouseAreaWithCloseIcon(root) {
            if (!root) return null;
            for (var i = 0; i < (root.children ? root.children.length : 0); i++) {
                var ch = root.children[i];
                if (ch.name === "close") {
                    for (var j = 0; j < root.children.length; j++) {
                        if (root.children[j].cursorShape !== undefined || root.children[j].toString().indexOf("MouseArea") !== -1) {
                            return root.children[j];
                        }
                    }
                }
                var found = findMouseAreaWithCloseIcon(ch);
                if (found) return found;
            }
            return null;
        }

        function test_titleAndSubtitleIntegration() {
            testFilterableHeader.title = "Project Tasks";
            testFilterableHeader.userLabel = "Bob Smith";

            compare(testFilterableHeader.title, "Project Tasks");
            compare(testFilterableHeader.userLabel, "Bob Smith");

            var titleLabel = findItemWithText(testFilterableHeader, "Project Tasks");
            verify(titleLabel !== null, "Title label should be found");
            compare(titleLabel.text, "Project Tasks");

            var subtitleLabel = findItemWithText(testFilterableHeader, "Bob Smith");
            verify(subtitleLabel !== null, "Subtitle label should be found");
            verify(subtitleLabel.text.indexOf(" • ") !== -1);
        }

        function test_subtitleWithoutUserLabel() {
            testFilterableHeader.userLabel = "";

            var subtitleLabel = findItemWithText(testFilterableHeader, testFilterableHeader.dateFilter.presetLabel);
            verify(subtitleLabel !== null, "Subtitle label should match presetLabel");
            compare(subtitleLabel.text, testFilterableHeader.dateFilter.presetLabel);
        }

        function test_showDateFilterToggleSwitchesViews() {
            // Initially normal is visible, date filter is hidden
            compare(testFilterableHeader.showDateFilter, false);

            // Toggle showDateFilter = true
            testFilterableHeader.showDateFilter = true;
            compare(testFilterableHeader.showDateFilter, true);

            // Toggle back
            testFilterableHeader.showDateFilter = false;
            compare(testFilterableHeader.showDateFilter, false);
        }

        function test_closeFilterButtonClickResetsState() {
            testFilterableHeader.showDateFilter = true;
            compare(testFilterableHeader.showDateFilter, true);

            var closeMouse = findMouseAreaWithCloseIcon(testFilterableHeader);
            verify(closeMouse !== null, "Close button MouseArea should be found");

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
