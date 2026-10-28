import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/features/tasks/components"

MainView {
    id: testRoot
    width: units.gu(40)
    height: units.gu(30)

    TaskPrioritySelector {
        id: testSelector
        width: testRoot.width
    }

    TestCase {
        name: "TaskPrioritySelectorTests"
        when: windowShown

        function getStarMouseAreas() {
            var mas = [];
            function findMAs(item) {
                if (!item) return;
                if (item instanceof MouseArea) mas.push(item);
                for (var i = 0; i < (item.children ? item.children.length : 0); i++) {
                    findMAs(item.children[i]);
                }
            }
            findMAs(testSelector);
            return mas;
        }

        function findLevelLabel(rootItem) {
            if (!rootItem) return null;
            if (rootItem.text !== undefined && rootItem.text.indexOf("Level:") !== -1) return rootItem;
            for (var i = 0; i < (rootItem.children ? rootItem.children.length : 0); i++) {
                var found = findLevelLabel(rootItem.children[i]);
                if (found) return found;
            }
            return null;
        }

        function init() {
            testSelector.priority = 0;
            testSelector.isReadOnly = false;
        }

        function cleanup() {
            testSelector.priority = 0;
            testSelector.isReadOnly = false;
        }

        function test_initialProperties() {
            compare(testSelector.priority, 0);
            compare(testSelector.isReadOnly, false);
            compare(testSelector.height, units.gu(6));

            var lbl = findLevelLabel(testSelector);
            if (lbl) {
                compare(lbl.visible, false);
            }
        }

        function test_setPriorityDirectly() {
            testSelector.priority = 1;
            compare(testSelector.priority, 1);

            var lbl = findLevelLabel(testSelector);
            verify(lbl !== null);
            compare(lbl.visible, true);
            compare(lbl.text, "(Level: 1)");

            testSelector.priority = 3;
            compare(testSelector.priority, 3);
            compare(lbl.text, "(Level: 3)");

            testSelector.priority = 0;
            compare(testSelector.priority, 0);
            compare(lbl.visible, false);
        }

        function test_mouseClickTogglesPriority() {
            var mas = getStarMouseAreas();
            verify(mas.length >= 3, "Should have 3 star mouse areas");

            // Click star 1 (index 0) -> priority 1
            mouseClick(mas[0]);
            compare(testSelector.priority, 1);

            // Click star 1 again -> toggles to 0
            mouseClick(mas[0]);
            compare(testSelector.priority, 0);

            // Click star 2 (index 1) -> priority 2
            mouseClick(mas[1]);
            compare(testSelector.priority, 2);

            // Click star 3 (index 2) -> priority 3
            mouseClick(mas[2]);
            compare(testSelector.priority, 3);
        }

        function test_readOnlyDisablesMouseClicks() {
            testSelector.isReadOnly = true;
            testSelector.priority = 1;

            var mas = getStarMouseAreas();
            verify(mas.length >= 3);
            compare(mas[0].enabled, false);
            compare(mas[1].enabled, false);
            compare(mas[2].enabled, false);

            mouseClick(mas[2]);
            // Priority should remain unchanged
            compare(testSelector.priority, 1);
        }
    }
}
