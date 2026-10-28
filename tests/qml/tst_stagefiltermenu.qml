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

        function findItemWithText(root, text) {
            if (!root) return null;
            if (root.text && root.text === text) return root;
            for (var i = 0; i < (root.children ? root.children.length : 0); i++) {
                var found = findItemWithText(root.children[i], text);
                if (found) return found;
            }
            return null;
        }

        function findItemWithIcon(root, iconName) {
            if (!root) return null;
            if (root.iconName === iconName) return root;
            for (var i = 0; i < (root.children ? root.children.length : 0); i++) {
                var found = findItemWithIcon(root.children[i], iconName);
                if (found) return found;
            }
            return null;
        }

        function test_menuItemSelectedSignal() {
            compare(itemSelectedSpy.count, 0);
            testStageMenu.menuModel = sampleStages;
            testStageMenu.expanded = true;
            wait(200);

            var item = findItemWithText(testStageMenu, "In Progress");
            verify(item !== null, "Delegate with text 'In Progress' should be found");

            mouseClick(item);
            wait(100);

            compare(testStageMenu.selectedIndex, 2);
            compare(testStageMenu.selectedFilterName, "In Progress");
            compare(testStageMenu.expanded, false);
            compare(itemSelectedSpy.count, 1);
            compare(itemSelectedSpy.signalArguments[0][0], 2);
        }

        function test_filterClearedSignal() {
            compare(filterClearedSpy.count, 0);
            testStageMenu.menuModel = sampleStages;
            testStageMenu.selectedIndex = 2;
            testStageMenu.selectedFilterName = "In Progress";
            testStageMenu.expanded = true;
            wait(200);

            var clearBtn = findItemWithIcon(testStageMenu, "edit-clear");
            verify(clearBtn !== null, "Clear filter button should be found");
            verify(clearBtn.visible, "Clear filter button should be visible when selectedIndex > 0");

            mouseClick(clearBtn);
            wait(100);

            compare(testStageMenu.selectedIndex, 0);
            compare(testStageMenu.selectedFilterName, "All Stages");
            compare(testStageMenu.expanded, false);
            compare(filterClearedSpy.count, 1);
            compare(itemSelectedSpy.count, 1);
            compare(itemSelectedSpy.signalArguments[0][0], 0);
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
            var fab = findItemWithIcon(testStageMenu, "filters");
            verify(fab !== null, "FAB button should be found");
            compare(testStageMenu.expanded, false);

            mouseClick(fab);
            wait(100);
            compare(testStageMenu.expanded, true);

            mouseClick(fab);
            wait(100);
            compare(testStageMenu.expanded, false);
        }

        function test_clearingFilterFlow() {
            testStageMenu.menuModel = sampleStages;
            testStageMenu.expanded = true;
            wait(200);

            // 1. Select "Done" stage (index 3) via delegate click
            var doneItem = findItemWithText(testStageMenu, "Done");
            verify(doneItem !== null, "Done item should be found");
            mouseClick(doneItem);
            wait(100);

            compare(testStageMenu.selectedIndex, 3);
            compare(testStageMenu.selectedFilterName, "Done");
            compare(testStageMenu.expanded, false);
            compare(itemSelectedSpy.count, 1);
            compare(itemSelectedSpy.signalArguments[0][0], 3);

            // 2. Open menu again and click clear filter button
            testStageMenu.expanded = true;
            wait(200);

            var clearBtn = findItemWithIcon(testStageMenu, "edit-clear");
            verify(clearBtn !== null, "Clear button should be found");
            verify(clearBtn.visible, "Clear button should be visible");

            mouseClick(clearBtn);
            wait(100);

            compare(testStageMenu.selectedIndex, 0);
            compare(testStageMenu.selectedFilterName, "All Stages");
            compare(testStageMenu.expanded, false);
            compare(filterClearedSpy.count, 1);
            compare(itemSelectedSpy.count, 2);
            compare(itemSelectedSpy.signalArguments[1][0], 0);
        }
    }
}
