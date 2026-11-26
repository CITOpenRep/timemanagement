import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components"
import "../../qml/components/selectors" as Selectors

MainView {
    id: testRoot
    width: units.gu(50)
    height: units.gu(80)

    OptionPickerDialog {
        id: singlePicker
        titleText: "Select Project"
        multiSelect: false
        searchThreshold: 4
    }

    OptionPickerDialog {
        id: multiPicker
        titleText: "Select Assignees"
        multiSelect: true
        searchThreshold: 3
    }

    OptionPickerDialog {
        id: sharedPicker
    }

    InlineOptionSelector {
        id: largeInline
        width: testRoot.width
        labelText: "Task"
        selectorType: "Task"
        pickerThreshold: 4
        optionPickerOverride: sharedPicker
    }

    Selectors.MultiAssigneeSelector {
        id: multiAssigneeSelector
        width: testRoot.width
        optionPickerOverride: sharedPicker
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

    SignalSpy {
        id: assigneesSpy
        target: multiAssigneeSelector
        signalName: "assigneesChanged"
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

            sharedPicker.close();

            largeInline.setData(sampleProjects);
            largeInline.clear();
            largeInline.collapse();

            multiAssigneeSelector.availableAssignees = sampleUsers;
            multiAssigneeSelector.setSelectedAssignees([]);

            singleSelectedSpy.clear();
            multiToggledSpy.clear();
            multiClearedSpy.clear();
            inlineSelectionSpy.clear();
            assigneesSpy.clear();
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

        function test_largeDatasetDebouncedAndCappedFiltering() {
            var manyItems = [];
            for (var i = 1; i <= 320; i++) {
                manyItems.push({ id: i, name: "Matchable Task " + i });
            }
            sharedPicker.open({
                titleText: "Many Tasks",
                modelData: manyItems,
                multiSelect: false,
                searchThreshold: 6
            });
            compare(sharedPicker.isOpen, true);
            compare(sharedPicker.filteredCount, 320);

            sharedPicker.searchText = "matchable task";
            tryCompare(sharedPicker, "filteredCount", 200, 400);
            compare(sharedPicker._hasMoreMatches, true);
            compare(sharedPicker._totalMatchCount, 320);

            sharedPicker.searchText = "319";
            tryCompare(sharedPicker, "filteredCount", 1, 400);
            compare(sharedPicker._hasMoreMatches, false);
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

        function test_inlineSelectorLazyCountAndSharedModalFlow() {
            compare(largeInline.optionCount, 6);
            compare(largeInline.collapsed, true);

            largeInline.openPicker();
            compare(largeInline.collapsed, true);
            compare(sharedPicker.isOpen, true);
            compare(sharedPicker.titleText, "Task");
            compare(sharedPicker.filteredCount, 6);

            sharedPicker._onSelectedCallback(14, "Mobile Auth");
            sharedPicker.close();

            compare(largeInline.selectedId, 14);
            compare(largeInline.selectedName, "Mobile Auth");
            compare(inlineSelectionSpy.count, 1);

            largeInline.openPicker();
            compare(sharedPicker.isOpen, true);
            largeInline.collapse();
            compare(sharedPicker.isOpen, false);
        }

        function test_multiAssigneeSharedPickerCallbacks() {
            sharedPicker.open({
                titleText: "Select Assignees",
                modelData: multiAssigneeSelector.availableAssignees,
                multiSelect: true,
                selectedIds: [],
                searchThreshold: 5,
                onMultiToggled: function (id, name, shouldSelect) {
                    if (shouldSelect) {
                        multiAssigneeSelector.addAssignee({ id: id, name: name });
                    } else {
                        for (var i = 0; i < multiAssigneeSelector.selectedAssignees.length; i++) {
                            if (multiAssigneeSelector.selectedAssignees[i].id === id) {
                                multiAssigneeSelector.removeAssignee(i);
                                break;
                            }
                        }
                    }
                },
                onMultiCleared: function () {
                    multiAssigneeSelector.setSelectedAssignees([]);
                }
            });

            compare(sharedPicker.isOpen, true);
            sharedPicker._onMultiToggleCallback(2, "Bob Smith", true);
            compare(multiAssigneeSelector.getSelectedAssigneeIds().length, 1);
            compare(multiAssigneeSelector.getSelectedAssigneeIds()[0], 2);

            sharedPicker._onMultiClearCallback();
            compare(multiAssigneeSelector.getSelectedAssigneeIds().length, 0);
        }

        function _findButtonByText(item, label) {
            if (!item) return null;
            if (item.hasOwnProperty("text") && item.text === label && item.hasOwnProperty("enabled") && item.hasOwnProperty("bgColor")) {
                return item;
            }
            var kids = item.children || [];
            for (var i = 0; i < kids.length; i++) {
                var found = _findButtonByText(kids[i], label);
                if (found) return found;
            }
            return null;
        }

        function test_singleSelectPositiveIdClearButtonDoesNotHang() {
            singlePicker.open({
                titleText: "Select Project",
                modelData: sampleProjects,
                multiSelect: false,
                selectedId: 12,
                searchThreshold: 4
            });
            compare(singlePicker.isOpen, true);
            waitForRendering(singlePicker);

            var clearBtn = _findButtonByText(singlePicker, "Clear");
            verify(clearBtn !== null);
            compare(clearBtn.visible, true);
            verify(clearBtn.width > 0 && clearBtn.width < singlePicker.width);

            mouseClick(clearBtn, clearBtn.width / 2, clearBtn.height / 2);
            compare(singleSelectedSpy.count, 1);
            compare(singleSelectedSpy.signalArguments[0][0], -1);
            compare(singlePicker.isOpen, false);
        }

        function test_multiSelectFooterButtonsDoNotOverlap() {
            multiPicker.open({
                titleText: "Select Assignees",
                modelData: sampleUsers,
                multiSelect: true,
                selectedIds: [1, 3],
                searchThreshold: 3
            });
            compare(multiPicker.isOpen, true);
            waitForRendering(multiPicker);

            var clearAllBtn = _findButtonByText(multiPicker, "Clear All");
            var doneBtn = _findButtonByText(multiPicker, "Done");
            verify(clearAllBtn !== null && doneBtn !== null);
            verify(clearAllBtn.width > 0 && doneBtn.width > 0);
            verify(clearAllBtn.x + clearAllBtn.width <= doneBtn.x);

            mouseClick(doneBtn, doneBtn.width / 2, doneBtn.height / 2);
            compare(multiPicker.isOpen, false);
        }
    }
}
