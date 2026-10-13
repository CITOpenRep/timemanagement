import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components/selectors"

MainView {
    id: testRoot
    width: units.gu(40)
    height: units.gu(70)

    SelectionButton {
        id: testSelectionBtn
        width: testRoot.width
        selectorType: "Project"
        labelText: "Select Project"
    }

    SignalSpy {
        id: selectionMadeSpy
        target: testSelectionBtn
        signalName: "selectionMade"
    }

    TestCase {
        name: "SelectionButtonTests"
        when: windowShown

        readonly property var sampleData: [
            { id: 1, name: "Website Redesign" },
            { id: 2, name: "Mobile App" },
            { id: 3, name: "Database Migration" }
        ]

        function init() {
            testSelectionBtn.enabledState = true;
            testSelectionBtn.readOnly = false;
            testSelectionBtn.selectedId = -1;
            testSelectionBtn.setData(sampleData);
            selectionMadeSpy.clear();
        }

        function cleanup() {
            selectionMadeSpy.clear();
        }

        function test_initialProperties() {
            compare(testSelectionBtn.selectorType, "Project");
            compare(testSelectionBtn.labelText, "Select Project");
            compare(testSelectionBtn.enabledState, true);
            compare(testSelectionBtn.readOnly, false);
            compare(testSelectionBtn.selectedId, -1);
            compare(testSelectionBtn.modelData.length, 3);
            compare(selectionMadeSpy.count, 0);
        }

        function test_setDataUpdatesModel() {
            var newData = [
                { id: 10, name: "Internal Operations" },
                { id: 20, name: "Customer Support" }
            ];
            testSelectionBtn.setData(newData);

            compare(testSelectionBtn.modelData.length, 2);
            compare(testSelectionBtn.modelData[0].name, "Internal Operations");
            compare(testSelectionBtn.modelData[1].id, 20);
        }

        function test_updateLabelSetsSelectedIdWithoutSignal() {
            testSelectionBtn.update_label("Mobile App");

            compare(testSelectionBtn.selectedId, 2);
            compare(selectionMadeSpy.count, 0);
        }

        function test_applyDeferredSelectionWithoutSignal() {
            testSelectionBtn.applyDeferredSelection(3, false);

            compare(testSelectionBtn.selectedId, 3);
            compare(selectionMadeSpy.count, 0);
        }

        function test_applyDeferredSelectionWithSignal() {
            testSelectionBtn.applyDeferredSelection(1, true);

            compare(testSelectionBtn.selectedId, 1);
            compare(selectionMadeSpy.count, 1);
            var args = selectionMadeSpy.signalArguments[0];
            compare(args[0], 1);
            compare(args[1], "Website Redesign");
            compare(args[2], "Project");
        }

        function test_setEnabledWhenNotReadOnly() {
            testSelectionBtn.readOnly = false;

            testSelectionBtn.setEnabled(false);
            compare(testSelectionBtn.enabledState, false);

            testSelectionBtn.setEnabled(true);
            compare(testSelectionBtn.enabledState, true);
        }

        function test_setEnabledWhenReadOnlyStaysDisabled() {
            testSelectionBtn.readOnly = true;

            testSelectionBtn.setEnabled(true);
            compare(testSelectionBtn.enabledState, false);
        }

        function test_selectionClickEmitsSignal() {
            var inlineSelector = testSelectionBtn.children[0];
            verify(inlineSelector !== null);

            // Expand selector
            inlineSelector.expand();
            compare(inlineSelector.collapsed, false);

            // Delegate selection simulation via applyDeferredSelection with signal
            testSelectionBtn.applyDeferredSelection(2, true);

            compare(testSelectionBtn.selectedId, 2);
            compare(selectionMadeSpy.count, 1);
            compare(selectionMadeSpy.signalArguments[0][1], "Mobile App");
        }
    }
}
