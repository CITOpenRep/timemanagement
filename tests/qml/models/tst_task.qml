import QtQuick 2.7
import QtTest 1.0
import QtQuick.LocalStorage 2.7 as Sql
import "../../../models/logger.js" as Logger
import "../../../models/database.js" as DBCommon
import "../../../models/dbinit.js" as DbInit
import "../../../models/utils.js" as Utils
import "../../../models/task.js" as TaskModel

Item {
    width: 200
    height: 200

    TestCase {
        name: "TaskModelTests"
        when: windowShown

        function initTestCase() {
            Logger.setLogLevel(Logger.LogLevel.NONE);
            DbInit.initializeDatabase();
        }

        function cleanupTestCase() {
            Logger.setLogLevel(Logger.LogLevel.WARN);
        }

        function init() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function (tx) {
                tx.executeSql("DELETE FROM project_task_app WHERE account_id = 999 OR id >= 90000");
                tx.executeSql("DELETE FROM project_project_app WHERE account_id = 999 OR id >= 90000");
                tx.executeSql("DELETE FROM project_task_type_app WHERE account_id = 999 OR odoo_record_id >= 90000");
            });
        }

        function cleanup() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function (tx) {
                tx.executeSql("DELETE FROM project_task_app WHERE account_id = 999 OR id >= 90000");
                tx.executeSql("DELETE FROM project_project_app WHERE account_id = 999 OR id >= 90000");
                tx.executeSql("DELETE FROM project_task_type_app WHERE account_id = 999 OR odoo_record_id >= 90000");
            });
        }

        // --- 1. Pure Helper Functions ---

        function test_validId() {
            compare(TaskModel.validId(10), 10);
            compare(TaskModel.validId(1), 1);
            compare(TaskModel.validId(0), null);
            compare(TaskModel.validId(-5), null);
            compare(TaskModel.validId(undefined), null);
            compare(TaskModel.validId(null), null);
        }

        function test_parseAssigneeIds() {
            compare(TaskModel.parseAssigneeIds("").length, 0);
            compare(TaskModel.parseAssigneeIds(null).length, 0);
            compare(TaskModel.parseAssigneeIds(undefined).length, 0);

            var parsedSingle = TaskModel.parseAssigneeIds("42");
            compare(parsedSingle.length, 1);
            compare(parsedSingle[0], 42);

            var parsedMulti = TaskModel.parseAssigneeIds("10, 25, 30");
            compare(parsedMulti.length, 3);
            compare(parsedMulti[0], 10);
            compare(parsedMulti[1], 25);
            compare(parsedMulti[2], 30);

            var parsedDirty = TaskModel.parseAssigneeIds("10, invalid, -2, 0, 50");
            compare(parsedDirty.length, 2);
            compare(parsedDirty[0], 10);
            compare(parsedDirty[1], 50);
        }

        function test_formatAssigneeIds() {
            compare(TaskModel.formatAssigneeIds([]), "");
            compare(TaskModel.formatAssigneeIds(null), "");
            compare(TaskModel.formatAssigneeIds(undefined), "");

            var assignees = [{ id: 5 }, { id: 12 }, { id: 99 }];
            compare(TaskModel.formatAssigneeIds(assignees), "5,12,99");

            var single = [{ id: 7 }];
            compare(TaskModel.formatAssigneeIds(single), "7");
        }

        function test_passesSearchFilter() {
            var task = {
                name: "Implement Dashboard Filter",
                description: "Allow filtering tasks by employee and project"
            };

            verify(TaskModel.passesSearchFilter(task, ""));
            verify(TaskModel.passesSearchFilter(task, null));
            verify(TaskModel.passesSearchFilter(task, "Dashboard"));
            verify(TaskModel.passesSearchFilter(task, "dashboard")); // Case-insensitive
            verify(TaskModel.passesSearchFilter(task, "filtering"));
            verify(TaskModel.passesSearchFilter(task, "EMPLOYEE"));
            verify(!TaskModel.passesSearchFilter(task, "NonexistentKeyword"));
        }

        function test_stageClassification() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function (tx) {
                tx.executeSql("INSERT INTO project_task_type_app (odoo_record_id, name, account_id) VALUES (?, ?, ?)", [90001, "Done", 999]);
                tx.executeSql("INSERT INTO project_task_type_app (odoo_record_id, name, account_id) VALUES (?, ?, ?)", [90002, "In Progress", 999]);
                tx.executeSql("INSERT INTO project_task_type_app (odoo_record_id, name, account_id) VALUES (?, ?, ?)", [90003, "Cancelled", 999]);
            });

            var doneTask = { state: 90001, account_id: 999 };
            var activeTask = { state: 90002, account_id: 999 };
            var cancelledTask = { state: 90003, account_id: 999 };

            verify(TaskModel.isTaskInDoneStage(doneTask));
            verify(!TaskModel.isTaskInDoneStage(activeTask));

            verify(TaskModel.isTaskInCancelledStage(cancelledTask));
            verify(!TaskModel.isTaskInCancelledStage(doneTask));
        }

        function test_passesDateFilter_allFilter() {
            var taskWithDates = { start_date: "2026-10-13", end_date: "2026-10-14" };
            var taskNoDates = { start_date: null, end_date: null };

            verify(TaskModel.passesDateFilter(taskWithDates, "all", new Date()));
            verify(TaskModel.passesDateFilter(taskNoDates, "all", new Date()));
            verify(!TaskModel.passesDateFilter(taskNoDates, "today", new Date()));
        }

        function test_dueCalculationsAndOverdue() {
            var refDate = new Date(2026, 9, 13); // 2026-10-13

            var taskToday = { start_date: "2026-10-13", end_date: "2026-10-13" };
            var taskYesterday = { start_date: "2026-10-12", end_date: "2026-10-12" };
            var taskTomorrow = { start_date: "2026-10-14", end_date: "2026-10-14" };

            // Today task is due today
            verify(TaskModel.isTaskDueToday(taskToday, refDate));

            // Tomorrow task is not due today
            verify(!TaskModel.isTaskDueToday(taskTomorrow, refDate));

            // Yesterday task is overdue (and shown in today view)
            verify(TaskModel.isTaskDueToday(taskYesterday, refDate));
            verify(TaskModel.isTaskOverdue(taskYesterday, refDate));
            verify(!TaskModel.isTaskOverdue(taskToday, refDate));
            verify(!TaskModel.isTaskOverdue(taskTomorrow, refDate));

            var statusOverdue = TaskModel.getTaskDateStatus(taskYesterday, refDate);
            verify(statusOverdue.isOverdue);

            var statusToday = TaskModel.getTaskDateStatus(taskToday, refDate);
            verify(statusToday.isInRange);
        }

        // --- 2. Database CRUD and Query Functions ---

        function test_saveOrUpdateTask_and_getTaskDetails() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function (tx) {
                tx.executeSql(
                    "INSERT INTO project_project_app (id, odoo_record_id, name, account_id, parent_id) VALUES (?, ?, ?, ?, ?)",
                    [101, 101, "Test Project", 999, 0]
                );
            });

            var taskData = {
                name: "Unit Test Task Alpha",
                description: "Test task description",
                projectId: 101,
                priority: 1,
                accountId: 999,
                assigneeUserId: "10,20",
                status: "normal"
            };

            var res = TaskModel.saveOrUpdateTask(taskData);
            verify(res.success);
            var taskId = res.taskId;
            verify(taskId > 0);

            var details = TaskModel.getTaskDetails(taskId);
            verify(details !== null);
            compare(details.name, "Unit Test Task Alpha");
            compare(details.project_id, 101);
            compare(details.account_id, 999);
            compare(details.priority, "1");

            // Now test updating the existing task
            taskData.record_id = taskId;
            taskData.name = "Unit Test Task Alpha Updated";
            var updateRes = TaskModel.saveOrUpdateTask(taskData);
            verify(updateRes.success);

            var updatedDetails = TaskModel.getTaskDetails(taskId);
            compare(updatedDetails.name, "Unit Test Task Alpha Updated");
        }

        function test_isUserAssignedToTask() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function (tx) {
                tx.executeSql(
                    "INSERT INTO project_task_app (id, odoo_record_id, name, user_id, account_id) VALUES (?, ?, ?, ?, ?)",
                    [90002, 90002, "Multi Assignee Task", "10, 20, 30", 999]
                );
            });

            verify(TaskModel.isUserAssignedToTask(90002, 10));
            verify(TaskModel.isUserAssignedToTask(90002, 20));
            verify(TaskModel.isUserAssignedToTask(90002, 30));
            verify(!TaskModel.isUserAssignedToTask(90002, 40));
            verify(!TaskModel.isUserAssignedToTask(90002, 99));
        }

        function test_setTaskPriority() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function (tx) {
                tx.executeSql(
                    "INSERT INTO project_task_app (id, odoo_record_id, name, priority, account_id) VALUES (?, ?, ?, ?, ?)",
                    [90003, 90003, "Priority Test Task", 0, 999]
                );
            });

            var res = TaskModel.setTaskPriority(90003, 3, "updated");
            verify(res.success);

            var details = TaskModel.getTaskDetails(90003);
            verify(details !== null);
            compare(details.priority, "3");
            compare(details.status, "updated");
        }

        function test_markTaskAsDeleted() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function (tx) {
                tx.executeSql(
                    "INSERT INTO project_task_app (id, odoo_record_id, name, status, account_id) VALUES (?, ?, ?, ?, ?)",
                    [90004, 90004, "Task to Delete", "normal", 999]
                );
            });

            var deleted = TaskModel.markTaskAsDeleted(90004);
            verify(deleted);

            var details = TaskModel.getTaskDetails(90004);
            verify(details !== null);
            compare(details.status, "deleted");
        }

        function test_getLocalIdFromOdooId() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function (tx) {
                tx.executeSql(
                    "INSERT INTO project_task_app (id, odoo_record_id, name, account_id) VALUES (?, ?, ?, ?)",
                    [90005, 54321, "Odoo Id Mapping Task", 999]
                );
            });

            var localId = TaskModel.getLocalIdFromOdooId(54321, 999);
            compare(localId, 90005);

            var nonExistent = TaskModel.getLocalIdFromOdooId(99999, 999);
            compare(nonExistent, -1);
        }
    }
}
