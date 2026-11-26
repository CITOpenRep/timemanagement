import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components"

MainView {
    id: testRoot
    width: units.gu(50)
    height: units.gu(80)

    OptionPickerDialog {
        id: singlePicker
        anchorItem: testRoot
        titleText: "Select Project"
        multiSelect: false
        searchThreshold: 4
    }

    OptionPickerDialog {
        id: multiPicker
        anchorItem: testRoot
        titleText: "Select Assignees"
        multiSelect: true
        searchThreshold: 3
    }

    InlineOptionSelector {
        id: largeInline
        width: testRoot.width
        labelText: "Task"
        selectorType: "Task"
        pickerThreshold: 4
    }

    WorkItemSelector {
        id: workSelector
        width: testRoot.width
    }

    SignalSpy {
        id: singleSelectedSpy
        target: singlePicker
        signalName: "optionSelected"
    }

    SignalSpy {
        id: multiToggledSpy
        target: multiPicker
        signalName: "multiItemToggled"
    }

    SignalSpy {
        id: multiClearedSpy
        target: multiPicker
        signalName: "multiCleared"
    }

    SignalSpy {
        id: inlineSelectionSpy
        target: largeInline
        signalName: "selectionMade"
    }

    TestCase {
        name: "OptionPickerDialogTests"
        when: windowShown

        readonly property var sampleProjects: [
            { id: -1, name: "Select" },
            { id: 10, name: "Alpha Migration" },
            { id: 11, name: "Beta Portal" },
            { id: 12, name: "Client Dashboard" },
            { id: 13, name: "DevOps Pipeline" },
            { id: 14, name: "Mobile Auth" }
        ]

        readonly property var sampleUsers: [
            { id: 1, name: "Alice Johnson" },
            { id: 2, name: "Bob Smith" },
            { id: 3, name: "Charlie Brown" },
            { id: 4, name: "Diana Prince" }
        ]

        function init() {
            singlePicker.close();
            singlePicker.selectedId = -1;
            singlePicker.modelData = sampleProjects;

            multiPicker.close();
            multiPicker.selectedIds = [];
            multiPicker.modelData = sampleUsers;

            largeInline.setData(sampleProjects);
            largeInline.clear();
            largeInline.collapse();

            singleSelectedSpy.clear();
            multiToggledSpy.clear();
            multiClearedSpy.clear();
            inlineSelectionSpy.clear();
        }

        function test_singleSelectFilteringAndSelection() {
            compare(singlePicker.showSearchBar, true);
            singlePicker.open();
            compare(singlePicker.isOpen, true);
            compare(singlePicker.filteredCount, 6);

            singlePicker.searchText = "alpha";
            compare(singlePicker.filteredCount, 1);

            singlePicker.searchText = "";
            compare(singlePicker.filteredCount, 6);
        }

        function test_smallListHidesSearchBar() {
            singlePicker.modelData = [
                { id: 1, name: "One" },
                { id: 2, name: "Two" }
            ];
            compare(singlePicker.showSearchBar, false);
        }

        function test_multiSelectFilterAndClear() {
            multiPicker.selectedIds = [1, 3];
            compare(multiPicker.showSearchBar, true);
            compare(multiPicker._isSelected(1), true);
            compare(multiPicker._isSelected(2), false);

            multiPicker.open();
            compare(multiPicker.filteredCount, 4);

            multiPicker.searchText = "diana";
            compare(multiPicker.filteredCount, 1);
            compare(multiPicker._isSelected(1), true);

            multiPicker.multiCleared();
            compare(multiClearedSpy.count, 1);
            multiPicker.close();
            compare(multiPicker.isOpen, false);
        }

        function test_workItemSelectorAccordionCollapse() {
            function collectSelectors(item, found) {
                if (!item) return;
                if (item.hasOwnProperty("collapsed") && typeof item.collapse === "function" && typeof item.expand === "function") {
                    found.push(item);
                }
                for (var i = 0; i < (item.children ? item.children.length : 0); i++) {
                    collectSelectors(item.children[i], found);
                }
            }

            var selectors = [];
            collectSelectors(workSelector, selectors);
            verify(selectors.length >= 2, "WorkItemSelector should contain InlineOptionSelectors");

            selectors[0].setData([{ id: 1, name: "Acc 1" }, { id: 2, name: "Acc 2" }]);
            selectors[1].setData([{ id: 10, name: "Proj 1" }, { id: 11, name: "Proj 2" }]);

            selectors[0].expand();
            compare(selectors[0].collapsed, false);

            selectors[1].expand();
            compare(selectors[1].collapsed, false);
            compare(selectors[0].collapsed, true);
        }

        function test_inlineSelectorModalTriggerAboveThreshold() {
            largeInline.openPicker();
            compare(largeInline.collapsed, true);
            largeInline.applyDeferredSelection(14, true);
            compare(largeInline.selectedId, 14);
            compare(largeInline.selectedName, "Mobile Auth");
            compare(inlineSelectionSpy.count, 1);
        }
    }
}
