import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components/selectors"
import "../../models/dbinit.js" as DbInit

MainView {
    id: testRoot
    width: units.gu(50)
    height: units.gu(80)

    WorkItemSelector {
        id: testSelector
    }

    SignalSpy {
        id: stateChangedSpy
        target: testSelector
        signalName: "stateChanged"
    }

    SignalSpy {
        id: multiAssigneesSpy
        target: testSelector
        signalName: "multiAssigneesChanged"
    }

    TestCase {
        name: "WorkItemSelectorTests"
        when: windowShown

        function initTestCase() {
            DbInit.initializeDatabase();
        }

        function init() {
            testSelector.showAccountSelector = true;
            testSelector.showProjectSelector = true;
            testSelector.showSubProjectSelector = true;
            testSelector.showTaskSelector = true;
            testSelector.showSubTaskSelector = true;
            testSelector.showAssigneeSelector = true;
            testSelector.enableMultipleAssignees = false;
            testSelector.readOnly = false;
            testSelector.restrictAccountToLocalOnly = false;
            testSelector.currentState = "Init";
            testSelector.selectedProjectId = -1;
            testSelector.selectedSubProjectId = -1;
            testSelector.selectedTaskId = -1;
            testSelector.selectedSubTaskId = -1;
            testSelector.selectedAssigneeId = -1;
            stateChangedSpy.clear();
            multiAssigneesSpy.clear();
        }

        function cleanup() {
            stateChangedSpy.clear();
            multiAssigneesSpy.clear();
        }

        function test_initialProperties() {
            compare(testSelector.showAccountSelector, true);
            compare(testSelector.showProjectSelector, true);
            compare(testSelector.showSubProjectSelector, true);
            compare(testSelector.showTaskSelector, true);
            compare(testSelector.showSubTaskSelector, true);
            compare(testSelector.showAssigneeSelector, true);
            compare(testSelector.enableMultipleAssignees, false);
            compare(testSelector.readOnly, false);
            compare(testSelector.restrictAccountToLocalOnly, false);
            compare(testSelector.currentState, "Init");
            compare(testSelector.selectedProjectId, -1);
            compare(testSelector.selectedSubProjectId, -1);
            compare(testSelector.selectedTaskId, -1);
            compare(testSelector.selectedSubTaskId, -1);
            compare(testSelector.selectedAssigneeId, -1);
            compare(stateChangedSpy.count, 0);
        }

        function test_visibilityToggles() {
            testSelector.showProjectSelector = false;
            compare(testSelector.showProjectSelector, false);

            testSelector.showSubProjectSelector = false;
            compare(testSelector.showSubProjectSelector, false);

            testSelector.showTaskSelector = false;
            compare(testSelector.showTaskSelector, false);

            testSelector.showSubTaskSelector = false;
            compare(testSelector.showSubTaskSelector, false);

            testSelector.showAssigneeSelector = false;
            compare(testSelector.showAssigneeSelector, false);

            testSelector.enableMultipleAssignees = true;
            compare(testSelector.enableMultipleAssignees, true);
        }

        function test_transitionToFunction() {
            testSelector.transitionTo("CustomState", { key: "value" });
            compare(testSelector.currentState, "CustomState");
            compare(stateChangedSpy.count, 1);
            compare(stateChangedSpy.signalArguments[0][0], "CustomState");
            compare(stateChangedSpy.signalArguments[0][1].key, "value");
        }

        function test_handleSelectionAccount() {
            testSelector.handleSelection(1, "My Local Account", "Account");
            compare(testSelector.selectedAccountId, 1);
            compare(testSelector.currentState, "AccountSelected");
            compare(stateChangedSpy.count, 1);
            compare(stateChangedSpy.signalArguments[0][0], "AccountSelected");
            compare(stateChangedSpy.signalArguments[0][1].id, 1);
            compare(stateChangedSpy.signalArguments[0][1].name, "My Local Account");
        }

        function test_handleSelectionProjectClearsChildSelections() {
            testSelector.selectedSubProjectId = 5;
            testSelector.selectedTaskId = 12;
            testSelector.selectedSubTaskId = 34;

            testSelector.handleSelection(100, "Core Platform", "Project");

            compare(testSelector.selectedProjectId, 100);
            compare(testSelector.currentState, "ProjectSelected");
            compare(stateChangedSpy.count, 1);
            compare(stateChangedSpy.signalArguments[0][0], "ProjectSelected");
            compare(stateChangedSpy.signalArguments[0][1].id, 100);
            compare(stateChangedSpy.signalArguments[0][1].name, "Core Platform");
        }

        function test_handleSelectionSubproject() {
            testSelector.selectedProjectId = 50;

            // Valid subproject
            testSelector.handleSelection(55, "Frontend Sub", "Subproject");
            compare(testSelector.selectedSubProjectId, 55);
            compare(testSelector.currentState, "SubprojectSelected");
            compare(stateChangedSpy.count, 1);

            stateChangedSpy.clear();
            // Reset to -1 falls back to project_component.selectedId (-1 by default)
            testSelector.handleSelection(-1, "Select", "Subproject");
            compare(testSelector.selectedSubProjectId, -1);
            compare(testSelector.currentState, "ProjectSelected");
            compare(stateChangedSpy.count, 1);
        }

        function test_handleSelectionTaskClearsSubtask() {
            testSelector.selectedSubTaskId = 88;

            testSelector.handleSelection(200, "Implement Auth", "Task");
            compare(testSelector.selectedTaskId, 200);
            compare(testSelector.selectedSubTaskId, -1);
            compare(testSelector.currentState, "TaskSelected");
            compare(stateChangedSpy.count, 1);
            compare(stateChangedSpy.signalArguments[0][1].id, 200);
        }

        function test_handleSelectionSubtask() {
            testSelector.handleSelection(300, "Write Unit Tests", "Subtask");
            compare(testSelector.selectedSubTaskId, 300);
            compare(testSelector.currentState, "SubtaskSelected");
            compare(stateChangedSpy.count, 1);

            stateChangedSpy.clear();
            testSelector.handleSelection(-1, "Select", "Subtask");
            compare(testSelector.selectedSubTaskId, -1);
            compare(testSelector.currentState, "TaskSelected");
            compare(stateChangedSpy.count, 1);
        }

        function test_handleSelectionAssignee() {
            testSelector.handleSelection(42, "Jane Smith", "Assignee");
            compare(testSelector.selectedAssigneeId, 42);
            compare(testSelector.currentState, "AssigneeSelected");
            compare(stateChangedSpy.count, 1);
            compare(stateChangedSpy.signalArguments[0][1].id, 42);
            compare(stateChangedSpy.signalArguments[0][1].name, "Jane Smith");
        }

        function test_getIdsNormalization() {
            testSelector.selectedAccountId = -1;

            var ids = testSelector.getIds();
            compare(ids.account_id, null);
            compare(ids.project_id, null);
            compare(ids.subproject_id, null);
            compare(ids.task_id, null);
            compare(ids.subtask_id, null);
            compare(ids.assignee_id, null);

            testSelector.selectedAccountId = 42;
            var activeIds = testSelector.getIds();
            compare(activeIds.account_id, 42);
            compare(activeIds.project_id, null);
        }

        function test_multiAssigneesWithModeEnabled() {
            testSelector.enableMultipleAssignees = true;
            var sample = [
                { id: 101, name: "Alice", email: "alice@test.com" },
                { id: 102, name: "Bob", email: "bob@test.com" }
            ];

            testSelector.setMultipleAssignees(sample);
            var retrieved = testSelector.getMultipleAssignees();
            compare(retrieved.length, 2);
            compare(retrieved[0].id, 101);
            compare(retrieved[1].id, 102);

            var ids = testSelector.getIds();
            verify(ids.multiple_assignees !== undefined);
            compare(ids.multiple_assignees.length, 2);
            verify(ids.assignee_ids !== undefined);
            compare(ids.assignee_ids.length, 2);
            compare(ids.assignee_ids[0], 101);
            compare(ids.assignee_ids[1], 102);
        }

        function test_readOnlyStateUpdate() {
            testSelector.readOnly = true;
            compare(testSelector.readOnly, true);
            testSelector.updateAllSelectorStates();

            testSelector.readOnly = false;
            compare(testSelector.readOnly, false);
            testSelector.updateAllSelectorStates();
        }
    }
}
