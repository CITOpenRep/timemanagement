import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components/selectors"

MainView {
    id: testRoot
    width: units.gu(40)
    height: units.gu(70)

    InlineOptionSelector {
        id: testInlineSelector
        width: testRoot.width
        labelText: "Priority"
        selectorType: "priority_level"
    }

    SignalSpy {
        id: selectionMadeSpy
        target: testInlineSelector
        signalName: "selectionMade"
    }

    TestCase {
        name: "InlineOptionSelectorTests"
        when: windowShown

        readonly property var sampleOptions: [
            { id: 1, name: "Low" },
            { id: 2, name: "Medium" },
            { id: 3, name: "High" },
            { id: 4, name: "Urgent" }
        ]

        function init() {
            testInlineSelector.enabledState = true;
            testInlineSelector.readOnly = false;
            testInlineSelector.setData(sampleOptions);
            testInlineSelector.clear();
            testInlineSelector.collapse();
            selectionMadeSpy.clear();
        }

        function cleanup() {
            selectionMadeSpy.clear();
        }

        function test_initialProperties() {
            compare(testInlineSelector.labelText, "Priority");
            compare(testInlineSelector.selectorType, "priority_level");
            compare(testInlineSelector.selectedId, -1);
            compare(testInlineSelector.selectedName, "");
            compare(testInlineSelector.collapsed, true);
            compare(testInlineSelector.enabledState, true);
            compare(testInlineSelector.readOnly, false);
            compare(selectionMadeSpy.count, 0);
        }

        function test_expandAndCollapseFunctions() {
            testInlineSelector.expand();
            compare(testInlineSelector.collapsed, false);

            testInlineSelector.collapse();
            compare(testInlineSelector.collapsed, true);
        }

        function test_radioStyleOptionSelection() {
            // Selecting Medium (exclusive radio-style selection)
            var resMedium = testInlineSelector.applyDeferredSelection(2, true);
            verify(resMedium);
            compare(testInlineSelector.selectedId, 2);
            compare(testInlineSelector.selectedName, "Medium");
            compare(selectionMadeSpy.count, 1);
            compare(selectionMadeSpy.signalArguments[0][0], 2);
            compare(selectionMadeSpy.signalArguments[0][1], "Medium");

            // Switching selection to High (overwrites previous selection)
            var resHigh = testInlineSelector.applyDeferredSelection(3, true);
            verify(resHigh);
            compare(testInlineSelector.selectedId, 3);
            compare(testInlineSelector.selectedName, "High");
            compare(selectionMadeSpy.count, 2);
            compare(selectionMadeSpy.signalArguments[1][0], 3);
            compare(selectionMadeSpy.signalArguments[1][1], "High");
        }

        function test_applyDeferredSelectionWithoutSignal() {
            var res = testInlineSelector.applyDeferredSelection(1, false);
            verify(res);
            compare(testInlineSelector.selectedId, 1);
            compare(testInlineSelector.selectedName, "Low");
            compare(selectionMadeSpy.count, 0);
        }

        function test_applyDeferredSelectionNonExistentId() {
            var res = testInlineSelector.applyDeferredSelection(999, false);
            verify(!res);
            compare(testInlineSelector.selectedId, -1);
        }

        function test_clearResetsSelection() {
            testInlineSelector.applyDeferredSelection(4, false);
            compare(testInlineSelector.selectedId, 4);
            compare(testInlineSelector.selectedName, "Urgent");

            testInlineSelector.clear();
            compare(testInlineSelector.selectedId, -1);
            compare(testInlineSelector.selectedName, "");
        }

        function test_setDataUpdatesOptionsAndNameResolution() {
            var newOptions = [
                { id: 10, name: "Tier 1" },
                { id: 20, name: "Tier 2" }
            ];
            testInlineSelector.setData(newOptions);

            testInlineSelector.applyDeferredSelection(20, true);
            compare(testInlineSelector.selectedId, 20);
            compare(testInlineSelector.selectedName, "Tier 2");
            compare(selectionMadeSpy.count, 1);
        }

        function test_setEnabledAndReadOnly() {
            testInlineSelector.readOnly = false;
            testInlineSelector.setEnabled(false);
            compare(testInlineSelector.enabledState, false);

            testInlineSelector.setEnabled(true);
            compare(testInlineSelector.enabledState, true);

            testInlineSelector.readOnly = true;
            testInlineSelector.setEnabled(true);
            compare(testInlineSelector.enabledState, false);
        }
    }
}
