import QtQuick 2.7
import QtTest 1.0
import QtQuick.LocalStorage 2.7 as Sql
import "../../../models/logger.js" as Logger
import "../../../models/database.js" as DBCommon
import "../../../models/dbinit.js" as DbInit
import "../../../models/utils.js" as Utils
import "../../../models/timesheet.js" as TimesheetModel

Item {
    width: 200
    height: 200

    TestCase {
        name: "TimesheetModelTests"
        when: windowShown

        function initTestCase() {
            Logger.setLogLevel(Logger.LogLevel.NONE);
            DbInit.initializeDatabase();
        }

        function cleanupTestCase() {
            Logger.setLogLevel(Logger.LogLevel.WARN);
        }

        function clearTestData() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function (tx) {
                tx.executeSql("DELETE FROM account_analytic_line_app WHERE account_id = 999 OR id >= 90000");
                tx.executeSql("DELETE FROM project_task_app WHERE account_id = 999 OR id >= 90000");
                tx.executeSql("DELETE FROM project_project_app WHERE account_id = 999 OR id >= 90000");
            });
        }

        function init() {
            clearTestData();
        }

        function cleanup() {
            clearTestData();
        }

        // --- 1. Creation and Details ---

        function test_createTimesheet_and_getTimeSheetDetails() {
            var createRes = TimesheetModel.createTimesheet(999, 10);
            verify(createRes.success);
            var sheetId = createRes.id;
            verify(sheetId > 0);

            var details = TimesheetModel.getTimeSheetDetails(sheetId, 999);
            verify(details !== null);
            compare(details.id, sheetId);
            compare(details.instance_id, 999);
            compare(details.user_id, 10);
            compare(details.status, "draft");
        }

        function test_createTimesheet_invalidAccount() {
            var res = TimesheetModel.createTimesheet(-1, 10);
            verify(!res.success);
        }

        // --- 2. Readiness and Finalization ---

        function test_readinessChecks() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function (tx) {
                // Neither project nor task
                tx.executeSql(
                    "INSERT INTO account_analytic_line_app (id, account_id, project_id, task_id, status) VALUES (?, ?, ?, ?, ?)",
                    [90010, 999, null, null, "draft"]
                );
                // Project only
                tx.executeSql(
                    "INSERT INTO account_analytic_line_app (id, account_id, project_id, task_id, status) VALUES (?, ?, ?, ?, ?)",
                    [90011, 999, 101, null, "draft"]
                );
                // Project and task
                tx.executeSql(
                    "INSERT INTO account_analytic_line_app (id, account_id, project_id, task_id, status) VALUES (?, ?, ?, ?, ?)",
                    [90012, 999, 101, 201, "draft"]
                );
            });

            // Timer ready requires project only
            verify(!TimesheetModel.isTimesheetReadyToStartTimer(90010));
            verify(TimesheetModel.isTimesheetReadyToStartTimer(90011));
            verify(TimesheetModel.isTimesheetReadyToStartTimer(90012));

            // Record/sync ready requires both project and task
            verify(!TimesheetModel.isTimesheetReadyToRecord(90010));
            verify(!TimesheetModel.isTimesheetReadyToRecord(90011));
            verify(TimesheetModel.isTimesheetReadyToRecord(90012));
        }

        function test_isTimesheetFinalized() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function (tx) {
                tx.executeSql("INSERT INTO account_analytic_line_app (id, account_id, status) VALUES (?, ?, ?)", [90020, 999, "draft"]);
                tx.executeSql("INSERT INTO account_analytic_line_app (id, account_id, status) VALUES (?, ?, ?)", [90021, 999, "active"]);
                tx.executeSql("INSERT INTO account_analytic_line_app (id, account_id, status) VALUES (?, ?, ?)", [90022, 999, "updated"]);
                tx.executeSql("INSERT INTO account_analytic_line_app (id, account_id, status) VALUES (?, ?, ?)", [90023, 999, "saved"]);
            });

            verify(!TimesheetModel.isTimesheetFinalized(90020));
            verify(!TimesheetModel.isTimesheetFinalized(90021));
            verify(TimesheetModel.isTimesheetFinalized(90022));
            verify(TimesheetModel.isTimesheetFinalized(90023));
        }

        // --- 3. Save, Duration, and Deletion ---

        function test_saveTimesheet() {
            var createRes = TimesheetModel.createTimesheet(999, 10);
            verify(createRes.success);
            var sheetId = createRes.id;

            var updateData = {
                id: sheetId,
                instance_id: 999,
                description: "Work on QML Unit Tests",
                project: 101,
                task: 201,
                unit_amount: 2.5,
                status: "draft"
            };

            var saveRes = TimesheetModel.saveTimesheet(updateData);
            verify(saveRes.success);

            var details = TimesheetModel.getTimeSheetDetails(sheetId, 999);
            compare(details.name, "Work on QML Unit Tests");
            compare(details.project_id, 101);
            compare(details.task_id, 201);
            compare(details.spentHours, "2:30");
        }

        function test_updateDuration_and_getUnitAmount() {
            var createRes = TimesheetModel.createTimesheet(999, 10);
            var sheetId = createRes.id;

            TimesheetModel.updateTimesheetWithDuration(sheetId, "01:45");
            var amount = TimesheetModel.getTimesheetUnitAmount(sheetId);
            compare(amount, 1.75);
        }

        function test_markTimesheetAsDeleted() {
            var createRes = TimesheetModel.createTimesheet(999, 10);
            var sheetId = createRes.id;

            var res = TimesheetModel.markTimesheetAsDeleted(sheetId);
            verify(res.success);

            var details = TimesheetModel.getTimeSheetDetails(sheetId, 999);
            compare(details.status, "deleted");
        }

        // --- 4. Status Transitions ---

        function test_statusTransitions() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function (tx) {
                tx.executeSql(
                    "INSERT INTO account_analytic_line_app (id, account_id, project_id, task_id, status) VALUES (?, ?, ?, ?, ?)",
                    [90030, 999, 101, 201, "draft"]
                );
                tx.executeSql(
                    "INSERT INTO account_analytic_line_app (id, account_id, project_id, task_id, status) VALUES (?, ?, ?, ?, ?)",
                    [90031, 999, 101, 201, "draft"]
                );
            });

            // Mark 90030 as active
            TimesheetModel.markTimesheetAsActiveById(90030);
            var d1 = TimesheetModel.getTimeSheetDetails(90030, 999);
            compare(d1.status, "active");

            // Mark 90031 as active -> 90030 should revert to draft
            TimesheetModel.markTimesheetAsActiveById(90031);
            var d1Reverted = TimesheetModel.getTimeSheetDetails(90030, 999);
            var d2Active = TimesheetModel.getTimeSheetDetails(90031, 999);
            compare(d1Reverted.status, "draft");
            compare(d2Active.status, "active");

            // Mark 90030 as saved
            TimesheetModel.markTimesheetAsSavedById(90030);
            var d1Saved = TimesheetModel.getTimeSheetDetails(90030, 999);
            compare(d1Saved.status, "saved");

            // Mark 90030 as draft
            TimesheetModel.markTimesheetAsDraftById(90030);
            var d1Draft = TimesheetModel.getTimeSheetDetails(90030, 999);
            compare(d1Draft.status, "draft");

            // Mark 90030 as ready (with project and task present)
            var readyRes = TimesheetModel.markTimesheetAsReadyById(90030);
            verify(readyRes.success);
            var d1Ready = TimesheetModel.getTimeSheetDetails(90030, 999);
            compare(d1Ready.status, "updated");
        }

        // --- 5. Display Names and Matching ---

        function test_getTimesheetDisplayName_and_Matching() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function (tx) {
                tx.executeSql("INSERT INTO project_project_app (id, odoo_record_id, name, account_id) VALUES (?, ?, ?, ?)", [90101, 90101, "Test Project", 999]);
                tx.executeSql("INSERT INTO project_task_app (id, odoo_record_id, name, account_id) VALUES (?, ?, ?, ?)", [90201, 90201, "Test Task", 999]);
                tx.executeSql(
                    "INSERT INTO account_analytic_line_app (id, account_id, project_id, task_id, name, status) VALUES (?, ?, ?, ?, ?, ?)",
                    [90040, 999, 90101, 90201, "Custom Work Description", "active"]
                );
                tx.executeSql(
                    "INSERT INTO account_analytic_line_app (id, account_id, project_id, task_id, name, status) VALUES (?, ?, ?, ?, ?, ?)",
                    [90041, 999, 90101, 90201, "", "draft"]
                );
            });

            // When name is present, display name is the description
            var name1 = TimesheetModel.getTimesheetDisplayName(90040);
            compare(name1, "Custom Work Description");

            // When name is empty, display name falls back to "Project - Task"
            var name2 = TimesheetModel.getTimesheetDisplayName(90041);
            compare(name2, "Test Project - Test Task");

            // Matching active sheet
            verify(TimesheetModel.doesProjectIdMatchSheetInActive(90101, 90040));
            verify(!TimesheetModel.doesProjectIdMatchSheetInActive(99999, 90040));

            verify(TimesheetModel.doesTaskIdMatchSheetInActive(90201, 90040));
            verify(!TimesheetModel.doesTaskIdMatchSheetInActive(99999, 90040));

            // getTimesheetAccountId
            compare(TimesheetModel.getTimesheetAccountId(90040), 999);
        }

        // --- 6. Fetching by Status ---

        function test_fetchTimesheetsByStatus() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function (tx) {
                tx.executeSql(
                    "INSERT INTO account_analytic_line_app (id, account_id, status, record_date) VALUES (?, ?, ?, ?)",
                    [90051, 999, "draft", "2026-10-13"]
                );
                tx.executeSql(
                    "INSERT INTO account_analytic_line_app (id, account_id, status, record_date) VALUES (?, ?, ?, ?)",
                    [90052, 999, "saved", "2026-10-13"]
                );
                tx.executeSql(
                    "INSERT INTO account_analytic_line_app (id, account_id, status, record_date) VALUES (?, ?, ?, ?)",
                    [90053, 999, "deleted", "2026-10-13"]
                );
            });

            var drafts = TimesheetModel.fetchTimesheetsByStatus("draft", 999);
            // In fetchTimesheetsByStatus, status === "draft" matches both "draft" and "saved"
            compare(drafts.length, 2);

            var all = TimesheetModel.fetchTimesheetsByStatus("all", 999);
            // "all" returns non-deleted records
            compare(all.length, 2);
        }
    }
}
