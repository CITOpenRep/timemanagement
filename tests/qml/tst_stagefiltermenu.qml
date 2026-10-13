import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components/selectors"

MainView {
    id: testRoot
    width: units.gu(50)
    height: units.gu(70)

    StageFilterMenu {
        id: testStageMenu
    }

    SignalSpy {
        id: itemSelectedSpy
        target: testStageMenu
        signalName: "menuItemSelected"
    }

    SignalSpy {
        id: filterClearedSpy
        target: testStageMenu
        signalName: "filterCleared"
    }

    TestCase {
        name: "StageFilterMenuTests"
        when: windowShown

        readonly property var sampleStages: [
            { label: "All Stages", value: -1 },
            { label: "New", value: 10 },
            { label: "In Progress", value: 20 },
            { label: "Done", value: 30 }
        ]

        function init() {
            testStageMenu.expanded = false;
            testStageMenu.selectedIndex = -1;
            testStageMenu.selectedFilterName = "All Stages";
            testStageMenu.menuModel = [];
            itemSelectedSpy.clear();
            filterClearedSpy.clear();
        }

        function cleanup() {
            itemSelectedSpy.clear();
            filterClearedSpy.clear();
        }

        function test_initialProperties() {
            compare(testStageMenu.expanded, false);
            compare(testStageMenu.selectedIndex, -1);
            compare(testStageMenu.selectedFilterName, "All Stages");
            compare(testStageMenu.menuModel.length, 0);
            compare(itemSelectedSpy.count, 0);
            compare(filterClearedSpy.count, 0);
        }

        function test_expandedToggle() {
            testStageMenu.expanded = true;
            compare(testStageMenu.expanded, true);

            testStageMenu.expanded = false;
            compare(testStageMenu.expanded, false);
        }

        function test_menuModelAssignment() {
            testStageMenu.menuModel = sampleStages;
            compare(testStageMenu.menuModel.length, 4);
            compare(testStageMenu.menuModel[0].label, "All Stages");
            compare(testStageMenu.menuModel[1].value, 10);
            compare(testStageMenu.menuModel[2].label, "In Progress");
            compare(testStageMenu.menuModel[3].value, 30);
        }

        function test_menuItemSelectedSignal() {
            compare(itemSelectedSpy.count, 0);
            testStageMenu.menuItemSelected(2);

            compare(itemSelectedSpy.count, 1);
            compare(itemSelectedSpy.signalArguments[0][0], 2);
        }

        function test_filterClearedSignal() {
            compare(filterClearedSpy.count, 0);
            testStageMenu.filterCleared();

            compare(filterClearedSpy.count, 1);
        }

        function test_selectionStateUpdates() {
            testStageMenu.menuModel = sampleStages;
            testStageMenu.selectedIndex = 2;
            testStageMenu.selectedFilterName = "In Progress";

            compare(testStageMenu.selectedIndex, 2);
            compare(testStageMenu.selectedFilterName, "In Progress");

            testStageMenu.selectedIndex = 3;
            testStageMenu.selectedFilterName = "Done";

            compare(testStageMenu.selectedIndex, 3);
            compare(testStageMenu.selectedFilterName, "Done");
        }

        function test_fabTogglesExpanded() {
            // Find the FAB child item
            var fab = null;
            for (var i = 0; i < testStageMenu.children.length; i++) {
                var child = testStageMenu.children[i];
                if (child.objectName === "fab" || child.iconName !== undefined) {
                    fab = child;
                    break;
                }
            }

            verify(fab !== null);
            compare(testStageMenu.expanded, false);

            fab.clicked();
            compare(testStageMenu.expanded, true);

            fab.clicked();
            compare(testStageMenu.expanded, false);
        }

        function test_clearingFilterFlow() {
            testStageMenu.menuModel = sampleStages;
            testStageMenu.selectedIndex = 2;
            testStageMenu.selectedFilterName = "In Progress";
            testStageMenu.expanded = true;

            // Trigger clearing: resets selectedIndex to 0 and closes menu
            testStageMenu.selectedIndex = 0;
            testStageMenu.selectedFilterName = testStageMenu.menuModel[0].label;
            testStageMenu.expanded = false;
            testStageMenu.filterCleared();
            testStageMenu.menuItemSelected(0);

            compare(testStageMenu.selectedIndex, 0);
            compare(testStageMenu.selectedFilterName, "All Stages");
            compare(testStageMenu.expanded, false);
            compare(filterClearedSpy.count, 1);
            compare(itemSelectedSpy.count, 1);
            compare(itemSelectedSpy.signalArguments[0][0], 0);
        }
    }
}
