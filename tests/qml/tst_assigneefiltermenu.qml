import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components/selectors"

MainView {
    id: testRoot
    width: units.gu(50)
    height: units.gu(70)

    AssigneeFilterMenu {
        id: testAssigneeMenu
    }

    SignalSpy {
        id: filterAppliedSpy
        target: testAssigneeMenu
        signalName: "filterApplied"
    }

    SignalSpy {
        id: filterClearedSpy
        target: testAssigneeMenu
        signalName: "filterCleared"
    }

    TestCase {
        name: "AssigneeFilterMenuTests"
        when: windowShown

        readonly property var sampleAssignees: [
            { id: 101, name: "Alice Adams", email: "alice@test.com", account_id: 1, account_name: "Acme Corp" },
            { id: 102, name: "Bob Brown", email: "bob@test.com", account_id: 1, account_name: "Acme Corp" },
            { id: 103, name: "Charlie Clark", email: "charlie@test.com", account_id: 2, account_name: "Beta Inc" }
        ]

        function init() {
            testAssigneeMenu.expanded = false;
            testAssigneeMenu.showAccountName = false;
            testAssigneeMenu.showAllUsersOption = false;
            testAssigneeMenu.selectedAssigneeIds = [];
            testAssigneeMenu.assigneeModel = [];
            filterAppliedSpy.clear();
            filterClearedSpy.clear();
        }

        function cleanup() {
            filterAppliedSpy.clear();
            filterClearedSpy.clear();
        }

        function test_initialProperties() {
            compare(testAssigneeMenu.expanded, false);
            compare(testAssigneeMenu.showAccountName, false);
            compare(testAssigneeMenu.showAllUsersOption, false);
            compare(testAssigneeMenu.selectedAssigneeIds.length, 0);
            compare(testAssigneeMenu.assigneeModel.length, 0);
            compare(filterAppliedSpy.count, 0);
            compare(filterClearedSpy.count, 0);
        }

        function test_expandedToggle() {
            testAssigneeMenu.expanded = true;
            compare(testAssigneeMenu.expanded, true);

            testAssigneeMenu.expanded = false;
            compare(testAssigneeMenu.expanded, false);
        }

        function test_createSelectionAndIsAssigneeSelected() {
            var sel = testAssigneeMenu.createSelection(101, 1);
            compare(sel.user_id, 101);
            compare(sel.account_id, 1);

            testAssigneeMenu.selectedAssigneeIds = [sel];
            verify(testAssigneeMenu.isAssigneeSelected(101, 1));
            verify(!testAssigneeMenu.isAssigneeSelected(101, 2));
            verify(!testAssigneeMenu.isAssigneeSelected(102, 1));
        }

        function test_addSelectionIfMissingAndRemove() {
            var sel1 = testAssigneeMenu.createSelection(101, 1);
            var sel2 = testAssigneeMenu.createSelection(102, 1);

            testAssigneeMenu.addSelectionIfMissing(sel1);
            compare(testAssigneeMenu.selectedAssigneeIds.length, 1);

            // Adding same should be a no-op
            testAssigneeMenu.addSelectionIfMissing(sel1);
            compare(testAssigneeMenu.selectedAssigneeIds.length, 1);

            testAssigneeMenu.addSelectionIfMissing(sel2);
            compare(testAssigneeMenu.selectedAssigneeIds.length, 2);

            testAssigneeMenu.removeSelectionIfPresent(sel1);
            compare(testAssigneeMenu.selectedAssigneeIds.length, 1);
            compare(testAssigneeMenu.selectedAssigneeIds[0].user_id, 102);
        }

        function test_selectAllUsersOption() {
            testAssigneeMenu.showAllUsersOption = true;
            testAssigneeMenu.selectAllUsers();

            compare(testAssigneeMenu.selectedAssigneeIds.length, 1);
            verify(testAssigneeMenu.isOnlyAllUsersSelected());

            // Adding a specific user should clear the "All Users" (-1) selection
            var sel = testAssigneeMenu.createSelection(101, 1);
            testAssigneeMenu.addSelectionIfMissing(sel);

            verify(!testAssigneeMenu.isOnlyAllUsersSelected());
            compare(testAssigneeMenu.selectedAssigneeIds.length, 1);
            compare(testAssigneeMenu.selectedAssigneeIds[0].user_id, 101);
        }

        function test_displayAssigneeCacheAndCounts() {
            testAssigneeMenu.assigneeModel = sampleAssignees;
            compare(testAssigneeMenu.getDisplayAssigneeCount(), 3);
            compare(testAssigneeMenu.getSelectedDisplayAssigneeCount(), 0);

            testAssigneeMenu.addSelectionIfMissing(testAssigneeMenu.createSelection(101, 1));
            testAssigneeMenu.recomputeDisplayAssigneeCache();
            compare(testAssigneeMenu.getSelectedDisplayAssigneeCount(), 1);

            testAssigneeMenu.addSelectionIfMissing(testAssigneeMenu.createSelection(102, 1));
            testAssigneeMenu.recomputeDisplayAssigneeCache();
            compare(testAssigneeMenu.getSelectedDisplayAssigneeCount(), 2);
        }

        function test_filterAppliedSignalEmission() {
            testAssigneeMenu.assigneeModel = sampleAssignees;
            testAssigneeMenu.addSelectionIfMissing(testAssigneeMenu.createSelection(101, 1));
            testAssigneeMenu.expanded = true;

            compare(filterAppliedSpy.count, 0);
            testAssigneeMenu.filterApplied(testAssigneeMenu.selectedAssigneeIds.slice());

            compare(filterAppliedSpy.count, 1);
            var applied = filterAppliedSpy.signalArguments[0][0];
            compare(applied.length, 1);
            compare(applied[0].user_id, 101);
            compare(applied[0].account_id, 1);
        }

        function test_clearFilterFunction() {
            testAssigneeMenu.showAllUsersOption = false;
            testAssigneeMenu.assigneeModel = sampleAssignees;
            testAssigneeMenu.addSelectionIfMissing(testAssigneeMenu.createSelection(101, 1));
            testAssigneeMenu.expanded = true;

            compare(testAssigneeMenu.selectedAssigneeIds.length, 1);
            compare(filterClearedSpy.count, 0);

            testAssigneeMenu.clearFilter();

            compare(testAssigneeMenu.selectedAssigneeIds.length, 0);
            compare(testAssigneeMenu.expanded, false);
            compare(filterClearedSpy.count, 1);
        }

        function test_clearFilterWithAllUsersOption() {
            testAssigneeMenu.showAllUsersOption = true;
            testAssigneeMenu.assigneeModel = sampleAssignees;
            testAssigneeMenu.addSelectionIfMissing(testAssigneeMenu.createSelection(101, 1));
            testAssigneeMenu.expanded = true;

            testAssigneeMenu.clearFilter();

            verify(testAssigneeMenu.isOnlyAllUsersSelected());
            compare(testAssigneeMenu.expanded, false);
            compare(filterClearedSpy.count, 1);
        }
    }
}
