import QtQuick 2.7
import QtTest 1.0
import "../../../qml/features/tasks/js/taskFormUtils.js" as TaskFormUtils

Item {
    width: 200
    height: 200

    TestCase {
        name: "TaskFormUtilsTests"
        when: windowShown

        function test_normalizeIdForRestore() {
            compare(TaskFormUtils.normalizeIdForRestore(null), -1);
            compare(TaskFormUtils.normalizeIdForRestore(undefined), -1);
            compare(TaskFormUtils.normalizeIdForRestore(""), -1);
            compare(TaskFormUtils.normalizeIdForRestore("invalid"), -1);
            compare(TaskFormUtils.normalizeIdForRestore(42), 42);
            compare(TaskFormUtils.normalizeIdForRestore("42"), 42);
            compare(TaskFormUtils.normalizeIdForRestore(0), 0);
        }

        function test_validateHoursInput() {
            // HH:MM format
            verify(TaskFormUtils.validateHoursInput("01:30"));
            verify(TaskFormUtils.validateHoursInput("0:00"));
            verify(TaskFormUtils.validateHoursInput("999:59"));
            verify(!TaskFormUtils.validateHoursInput("1:60")); // minutes >= 60 invalid
            verify(!TaskFormUtils.validateHoursInput("1000:00")); // hours > 999 invalid
            verify(!TaskFormUtils.validateHoursInput("-1:00"));

            // Decimal format
            verify(TaskFormUtils.validateHoursInput("2.5"));
            verify(TaskFormUtils.validateHoursInput("0"));
            verify(TaskFormUtils.validateHoursInput("999"));
            verify(!TaskFormUtils.validateHoursInput("1000")); // > 999 invalid
            verify(!TaskFormUtils.validateHoursInput("-5"));

            // Invalid non-numeric strings
            verify(!TaskFormUtils.validateHoursInput(""));
            verify(!TaskFormUtils.validateHoursInput("abc"));
            verify(!TaskFormUtils.validateHoursInput("12:abc"));
        }

        function test_formatHoursDisplay() {
            compare(TaskFormUtils.formatHoursDisplay("1:05"), "01:05");
            compare(TaskFormUtils.formatHoursDisplay("10:30"), "10:30");
            compare(TaskFormUtils.formatHoursDisplay("2.5"), "2:30");
            compare(TaskFormUtils.formatHoursDisplay("invalid"), "invalid");
        }

        function test_resolveSingleAssigneeId() {
            compare(TaskFormUtils.resolveSingleAssigneeId(undefined), -1);
            compare(TaskFormUtils.resolveSingleAssigneeId(null), -1);
            compare(TaskFormUtils.resolveSingleAssigneeId(""), -1);
            compare(TaskFormUtils.resolveSingleAssigneeId(42), 42);
            compare(TaskFormUtils.resolveSingleAssigneeId("42"), 42);
            compare(TaskFormUtils.resolveSingleAssigneeId("10, 20, 30"), 10);
            compare(TaskFormUtils.resolveSingleAssigneeId("invalid"), -1);
        }

        function test_buildSaveData_remoteAccount() {
            var params = {
                ids: {
                    account_id: 999,
                    project_id: 101,
                    subproject_id: 0,
                    task_id: 201,
                    assignee_id: "15"
                },
                name: "Unit Test Task",
                recordId: 50,
                startDate: "2026-10-13",
                endDate: "2026-10-15",
                deadline: "2026-10-20",
                priority: 2,
                plannedHours: "03:30",
                description: "Test description",
                selectedStageOdooRecordId: 5,
                selectedPersonalStageOdooRecordId: null,
                stageListCount: 3
            };

            var data = TaskFormUtils.buildSaveData(params);
            compare(data.accountId, 999);
            compare(data.name, "Unit Test Task");
            compare(data.record_id, 50);
            compare(data.projectId, 101);
            compare(data.parentId, 201);
            compare(data.deadline, "2026-10-20");
            compare(data.priority, "2");
            compare(data.plannedHours, 3.5);
            compare(data.status, "updated"); // Remote account gets "updated"
            compare(data.stageOdooRecordId, 5);
        }

        function test_buildSaveData_localAccount() {
            var params = {
                ids: {
                    account_id: 0,
                    project_id: 10,
                    subproject_id: 0,
                    task_id: 0,
                    assignee_id: ""
                },
                name: "Local Task",
                recordId: 0,
                startDate: "2026-10-13",
                endDate: "2026-10-13",
                deadline: "Not set",
                priority: 0,
                plannedHours: "1.0",
                description: "",
                selectedStageOdooRecordId: -1,
                selectedPersonalStageOdooRecordId: null,
                stageListCount: 1
            };

            var data = TaskFormUtils.buildSaveData(params);
            compare(data.accountId, 0);
            compare(data.status, "saved"); // Local account gets "saved"
            compare(data.deadline, ""); // "Not set" deadline becomes empty string
            compare(data.plannedHours, 1.0);
            compare(data.stageOdooRecordId, -1);
        }

        function test_buildSaveData_multipleAssigneesAndStageFallback() {
            var params = {
                ids: {
                    account_id: 10,
                    project_id: 5,
                    subproject_id: 0,
                    task_id: 0,
                    assignee_id: "101",
                    multiple_assignees: [
                        { id: 101, name: "Alice" },
                        { id: 102, name: "Bob" }
                    ]
                },
                name: "New Task with Fallback Stage",
                recordId: 0,
                startDate: "2026-10-14",
                endDate: "2026-10-14",
                deadline: "",
                priority: 1,
                plannedHours: "2.0",
                description: "",
                selectedStageOdooRecordId: null,
                selectedPersonalStageOdooRecordId: 44,
                stageListCount: 2,
                firstStage: { odoo_record_id: 7, name: "Backlog" },
                enableMultipleAssignees: true
            };

            var data = TaskFormUtils.buildSaveData(params);
            compare(data.stageOdooRecordId, 7); // Falls back to firstStage
            compare(data.personalStageOdooRecordId, 44);
            verify(Array.isArray(data.multipleAssignees));
            compare(data.multipleAssignees.length, 2);
            compare(data.multipleAssignees[0].id, 101);
            compare(data.multipleAssignees[1].id, 102);
        }
    }
}
