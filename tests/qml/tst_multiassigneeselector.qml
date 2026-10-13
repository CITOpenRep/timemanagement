import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components/selectors"

MainView {
    id: testRoot
    width: units.gu(40)
    height: units.gu(70)

    MultiAssigneeSelector {
        id: testMultiAssignee
        width: testRoot.width
    }

    SignalSpy {
        id: assigneesChangedSpy
        target: testMultiAssignee
        signalName: "assigneesChanged"
    }

    TestCase {
        name: "MultiAssigneeSelectorTests"
        when: windowShown

        function init() {
            testMultiAssignee.readOnly = false;
            testMultiAssignee.enabledState = true;
            testMultiAssignee.setSelectedAssignees([]);
            assigneesChangedSpy.clear();
        }

        function cleanup() {
            testMultiAssignee.readOnly = false;
            testMultiAssignee.setSelectedAssignees([]);
            assigneesChangedSpy.clear();
        }

        function test_initialProperties() {
            compare(testMultiAssignee.readOnly, false);
            compare(testMultiAssignee.enabledState, true);
            compare(testMultiAssignee.selectedAssignees.length, 0);
            var ids = testMultiAssignee.getSelectedAssigneeIds();
            compare(ids.length, 0);
            compare(assigneesChangedSpy.count, 0);
        }

        function test_setSelectedAssigneesAndIdsArrayOutput() {
            var initialList = [
                { id: 101, name: "Alice Developer" },
                { id: 102, name: "Bob Reviewer" }
            ];

            testMultiAssignee.setSelectedAssignees(initialList);

            compare(assigneesChangedSpy.count, 1);
            var assignees = testMultiAssignee.getSelectedAssignees();
            compare(assignees.length, 2);

            var ids = testMultiAssignee.getSelectedAssigneeIds();
            compare(ids.length, 2);
            compare(ids[0], 101);
            compare(ids[1], 102);
        }

        function test_addAssigneeAppendsToIdsArrayOutput() {
            testMultiAssignee.setSelectedAssignees([
                { id: 201, name: "Dave Lead" }
            ]);
            assigneesChangedSpy.clear();

            testMultiAssignee.addAssignee({ id: 202, name: "Eve Engineer" });

            compare(assigneesChangedSpy.count, 1);
            var ids = testMultiAssignee.getSelectedAssigneeIds();
            compare(ids.length, 2);
            compare(ids[0], 201);
            compare(ids[1], 202);
        }

        function test_addDuplicateAssigneeDoesNotDuplicateId() {
            testMultiAssignee.setSelectedAssignees([
                { id: 301, name: "Frank QA" }
            ]);
            assigneesChangedSpy.clear();

            testMultiAssignee.addAssignee({ id: 301, name: "Frank QA Duplicate" });

            compare(assigneesChangedSpy.count, 0);
            var ids = testMultiAssignee.getSelectedAssigneeIds();
            compare(ids.length, 1);
            compare(ids[0], 301);
        }

        function test_removeAssigneeUpdatesIdsArrayOutput() {
            testMultiAssignee.setSelectedAssignees([
                { id: 401, name: "Grace Support" },
                { id: 402, name: "Heidi Admin" }
            ]);
            assigneesChangedSpy.clear();

            testMultiAssignee.removeAssignee(0);

            compare(assigneesChangedSpy.count, 1);
            var ids = testMultiAssignee.getSelectedAssigneeIds();
            compare(ids.length, 1);
            compare(ids[0], 402);
        }

        function test_readOnlyBlocksAddAndRemove() {
            testMultiAssignee.setSelectedAssignees([
                { id: 501, name: "Ivan DevOps" }
            ]);
            assigneesChangedSpy.clear();

            testMultiAssignee.readOnly = true;

            testMultiAssignee.addAssignee({ id: 502, name: "Judy Manager" });
            compare(assigneesChangedSpy.count, 0);
            compare(testMultiAssignee.getSelectedAssigneeIds().length, 1);

            testMultiAssignee.removeAssignee(0);
            compare(assigneesChangedSpy.count, 0);
            compare(testMultiAssignee.getSelectedAssigneeIds().length, 1);
        }

        function test_setEnabledToggle() {
            testMultiAssignee.readOnly = false;
            testMultiAssignee.setEnabled(false);
            compare(testMultiAssignee.enabledState, false);

            testMultiAssignee.setEnabled(true);
            compare(testMultiAssignee.enabledState, true);

            testMultiAssignee.readOnly = true;
            testMultiAssignee.setEnabled(true);
            compare(testMultiAssignee.enabledState, false);
        }
    }
}
