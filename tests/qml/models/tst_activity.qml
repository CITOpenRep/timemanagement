import QtQuick 2.7
import QtTest 1.0
import QtQuick.LocalStorage 2.7 as Sql
import "../../../models/logger.js" as Logger
import "../../../models/database.js" as DBCommon
import "../../../models/dbinit.js" as DbInit
import "../../../models/utils.js" as Utils
import "../../../models/activity.js" as ActivityModel

Item {
    width: 200
    height: 200

    TestCase {
        name: "ActivityModelTests"
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
                tx.executeSql("DELETE FROM mail_activity_app WHERE account_id = 999 OR id >= 90000");
                tx.executeSql("DELETE FROM mail_activity_type_app WHERE account_id = 999 OR id >= 90000");
            });
        }

        function init() {
            clearTestData();
        }

        function cleanup() {
            clearTestData();
        }

        // --- 1. Pure Helper Functions ---

        function test_sanitizeId() {
            compare(ActivityModel.sanitizeId(null), -1);
            compare(ActivityModel.sanitizeId(undefined), -1);
            compare(ActivityModel.sanitizeId(""), -1);
            compare(ActivityModel.sanitizeId(0), 0);
            compare(ActivityModel.sanitizeId(42), 42);
            compare(ActivityModel.sanitizeId("42"), 42);
            compare(ActivityModel.sanitizeId(-5), -5);
            compare(ActivityModel.sanitizeId("invalid"), -1);
        }

        function test_getActivityIconForType() {
            compare(ActivityModel.getActivityIconForType("Send Mail"), "activity_mail.png");
            compare(ActivityModel.getActivityIconForType("Client Call"), "activity_call.png");
            compare(ActivityModel.getActivityIconForType("Project Meeting"), "activity_meeting.png");
            compare(ActivityModel.getActivityIconForType("Todo List"), "activity_others.png");
            compare(ActivityModel.getActivityIconForType(""), "activity_others.png");
            compare(ActivityModel.getActivityIconForType(null), "activity_others.png");
        }

        function test_passesActivityDateFilter() {
            var refDate = new Date(2026, 9, 13); // 2026-10-13

            var actToday = { due_date: "2026-10-13" };
            var actYesterday = { due_date: "2026-10-12" };
            var actNoDate = { due_date: null };

            // "all" filter
            verify(ActivityModel.passesActivityDateFilter(actToday, "all", refDate));
            verify(ActivityModel.passesActivityDateFilter(actNoDate, "all", refDate));

            // Without date, non-"all" filters return false
            verify(!ActivityModel.passesActivityDateFilter(actNoDate, "today", refDate));

            // "today" includes today and overdue items
            verify(ActivityModel.passesActivityDateFilter(actToday, "today", refDate));
            verify(ActivityModel.passesActivityDateFilter(actYesterday, "today", refDate));

            // "overdue"
            verify(ActivityModel.passesActivityDateFilter(actYesterday, "overdue", refDate));
            verify(!ActivityModel.passesActivityDateFilter(actToday, "overdue", refDate));
        }

        function test_passesActivitySearchFilter() {
            var activity = {
                summary: "Quarterly Planning",
                notes: "Discuss Q4 objectives and budget",
                activity_type_id: 1,
                account_id: 999
            };

            verify(ActivityModel.passesActivitySearchFilter(activity, ""));
            verify(ActivityModel.passesActivitySearchFilter(activity, null));
            verify(ActivityModel.passesActivitySearchFilter(activity, "Quarterly"));
            verify(ActivityModel.passesActivitySearchFilter(activity, "planning"));
            verify(ActivityModel.passesActivitySearchFilter(activity, "budget"));
            verify(!ActivityModel.passesActivitySearchFilter(activity, "UnrelatedTerm"));
        }

        // --- 2. Database CRUD and Mutations ---

        function test_saveActivityData_and_getActivityById() {
            var newActivity = {
                updatedAccount: 999,
                updatedActivity: 1,
                updatedSummary: "Review Architecture Doc",
                updatedUserId: 10,
                updatedDate: "2026-10-14",
                updatedNote: "Detailed review comments",
                resModel: "project.project",
                resId: 101,
                task_id: 0,
                project_id: 101,
                link_id: 101,
                state: "planned",
                status: "normal"
            };

            var saveRes = ActivityModel.saveActivityData(newActivity, 0);
            verify(saveRes.success);
            var actId = saveRes.recordId;
            verify(actId > 0);

            var details = ActivityModel.getActivityById(actId, 999);
            verify(details !== null);
            compare(details.id, actId);
            compare(details.summary, "Review Architecture Doc");
            compare(details.account_id, 999);
            compare(details.state, "planned");

            // Update the activity
            newActivity.updatedSummary = "Review Architecture Doc Updated";
            var updateRes = ActivityModel.saveActivityData(newActivity, actId);
            verify(updateRes.success);

            var updatedDetails = ActivityModel.getActivityById(actId, 999);
            compare(updatedDetails.summary, "Review Architecture Doc Updated");
        }

        function test_markAsDone_and_updateActivityDate() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function (tx) {
                tx.executeSql(
                    "INSERT INTO mail_activity_app (id, account_id, summary, due_date, state, status) VALUES (?, ?, ?, ?, ?, ?)",
                    [90010, 999, "Call Vendor", "2026-10-13", "planned", "normal"]
                );
            });

            ActivityModel.updateActivityDate(999, 90010, "2026-10-15");
            var d1 = ActivityModel.getActivityById(90010, 999);
            compare(d1.due_date, "2026-10-15");
            compare(d1.status, "updated");

            ActivityModel.markAsDone(999, 90010);
            var d2 = ActivityModel.getActivityById(90010, 999);
            compare(d2.state, "done");
            compare(d2.status, "updated");
        }

        function test_deleteActivity() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function (tx) {
                tx.executeSql(
                    "INSERT INTO mail_activity_app (id, account_id, summary, status) VALUES (?, ?, ?, ?)",
                    [90020, 999, "Temporary Activity", "normal"]
                );
            });

            var delRes = ActivityModel.deleteActivity(999, 90020);
            verify(delRes.success);

            var details = ActivityModel.getActivityById(90020, 999);
            // Non-existent activity returns empty object or null
            verify(!details || !details.id);
        }

        function test_getActivityTypesForAccount() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function (tx) {
                tx.executeSql(
                    "INSERT INTO mail_activity_type_app (id, odoo_record_id, name, account_id, status) VALUES (?, ?, ?, ?, ?)",
                    [90031, 90031, "Email", 999, "normal"]
                );
                tx.executeSql(
                    "INSERT INTO mail_activity_type_app (id, odoo_record_id, name, account_id, status) VALUES (?, ?, ?, ?, ?)",
                    [90032, 90032, "Meeting", 999, "normal"]
                );
            });

            var types = ActivityModel.getActivityTypesForAccount(999);
            compare(types.length, 2);
        }
    }
}
