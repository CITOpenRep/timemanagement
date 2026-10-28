import QtQuick 2.7
import QtTest 1.0
import QtQuick.LocalStorage 2.7 as Sql
import "../../../models/logger.js" as Logger
import "../../../models/database.js" as DBCommon
import "../../../models/dbinit.js" as DbInit
import "../../../models/utils.js" as Utils
import "../../../models/Main.js" as MainModel

Item {
    width: 200
    height: 200

    TestCase {
        name: "MainModelTests"
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

        // --- 1. Pure Helper Date Functions ---

        function test_dateHelpers() {
            var monday = MainModel.getMondayOfCurrentWeek();
            verify(monday !== "");
            // Matches YYYY-MM-DD
            verify(/^\d{4}-\d{2}-\d{2}$/.test(monday));

            var firstDay = MainModel.getFirstDayOfCurrentMonth();
            verify(firstDay !== "");
            verify(/^\d{4}-\d{2}-01$/.test(firstDay));
        }

        // --- 2. Entity Name Resolvers ---

        function test_getProjectAndTaskName() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function (tx) {
                tx.executeSql("INSERT INTO project_project_app (id, odoo_record_id, name, account_id) VALUES (?, ?, ?, ?)", [90001, 90001, "Main Project Test", 999]);
                tx.executeSql("INSERT INTO project_task_app (id, odoo_record_id, name, account_id) VALUES (?, ?, ?, ?)", [90002, 90002, "Main Task Test", 999]);
            });

            compare(MainModel.get_project_name(90001), "Main Project Test");
            compare(MainModel.get_project_name(99999), "");

            compare(MainModel.get_task_name(90002), "Main Task Test");
            compare(MainModel.get_task_name(99999), "");
        }

        // --- 3. Quadrant and Spent Hours Aggregations ---

        function test_get_quadrant_difference() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function (tx) {
                tx.executeSql(
                    "INSERT INTO account_analytic_line_app (id, account_id, quadrant_id, unit_amount, status) VALUES (?, ?, ?, ?, ?)",
                    [90011, 999, 0, 3.5, "saved"]
                );
                tx.executeSql(
                    "INSERT INTO account_analytic_line_app (id, account_id, quadrant_id, unit_amount, status) VALUES (?, ?, ?, ?, ?)",
                    [90012, 999, 1, 4.0, "saved"]
                );
                tx.executeSql(
                    "INSERT INTO account_analytic_line_app (id, account_id, quadrant_id, unit_amount, status) VALUES (?, ?, ?, ?, ?)",
                    [90013, 999, 2, 2.0, "saved"]
                );
            });

            var quadDiff = MainModel.get_quadrant_difference();
            verify(quadDiff !== null);
            compare(quadDiff[0], 3.5);
            compare(quadDiff[1], 4.0);
            compare(quadDiff[2], 2.0);
        }

        function test_get_spent_hours_query() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function (tx) {
                tx.executeSql(
                    "INSERT INTO account_analytic_line_app (id, account_id, project_id, unit_amount, record_date, status) VALUES (?, ?, ?, ?, ?, ?)",
                    [90021, 999, 101, 1.5, "2026-10-10", "saved"]
                );
                tx.executeSql(
                    "INSERT INTO account_analytic_line_app (id, account_id, project_id, unit_amount, record_date, status) VALUES (?, ?, ?, ?, ?, ?)",
                    [90022, 999, 101, 2.5, "2026-10-12", "saved"]
                );
            });

            // Group by project_id
            var spentGrouped = MainModel.get_spent_hours({ group_by: "project_id" }, 999);
            verify(spentGrouped.length >= 1);
            compare(spentGrouped[0].total, 4.0);

            // Filter with dateFilter
            var spentFiltered = MainModel.get_spent_hours({ dateFilter: "2026-10-11" }, 999);
            compare(spentFiltered.length, 1);
            compare(spentFiltered[0].id, 90022);
        }

        function test_get_projects_and_tasks_spent_hours() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function (tx) {
                tx.executeSql("INSERT INTO project_project_app (id, odoo_record_id, name, account_id) VALUES (?, ?, ?, ?)", [90100, 90100, "Project Gamma", 999]);
                tx.executeSql("INSERT INTO project_task_app (id, odoo_record_id, name, account_id, project_id) VALUES (?, ?, ?, ?, ?)", [90200, 90200, "Task Delta", 999, 90100]);
                tx.executeSql(
                    "INSERT INTO account_analytic_line_app (id, account_id, project_id, task_id, unit_amount, record_date, status, user_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                    [90031, 999, 90100, 90200, 5.0, "2026-10-13", "saved", 10]
                );
            });

            var projectsSummary = MainModel.get_projects_spent_hours(999, "2026-10-01", "2026-10-31", 10);
            verify(projectsSummary.length >= 1);
            compare(projectsSummary[0].name, "Project Gamma");
            compare(projectsSummary[0].total, 5.0);

            var tasksSummary = MainModel.get_tasks_spent_hours(999, "2026-10-01", "2026-10-31", 10);
            compare(tasksSummary["Task Delta"], 5.0);
        }
    }
}
