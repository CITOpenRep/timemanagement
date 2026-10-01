import QtQuick 2.7
import QtTest 1.0
import QtQuick.LocalStorage 2.7 as Sql
import "../../../models/constants.js" as Constants
import "../../../models/logger.js" as Logger
import "../../../models/database.js" as DBCommon
import "../../../models/timesheet.js" as Model
import "../../../models/timer_service.js" as TimerService

Item {
    width: 200
    height: 200

    TestCase {
        name: "TimerServiceTests"
        when: windowShown

        function initTestCase() {
            Logger.setLogLevel(Logger.LogLevel.NONE);
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function(tx) {
                tx.executeSql("CREATE TABLE IF NOT EXISTS project_project_app (" +
                              "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                              "odoo_record_id INTEGER, " +
                              "name TEXT, " +
                              "color_pallet TEXT)");

                tx.executeSql("CREATE TABLE IF NOT EXISTS project_task_app (" +
                              "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                              "odoo_record_id INTEGER, " +
                              "name TEXT)");

                tx.executeSql("CREATE TABLE IF NOT EXISTS account_analytic_line_app (" +
                              "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                              "account_id INTEGER, " +
                              "project_id INTEGER, " +
                              "sub_project_id INTEGER, " +
                              "task_id INTEGER, " +
                              "name TEXT, " +
                              "unit_amount REAL, " +
                              "status TEXT, " +
                              "last_modified TEXT)");
            });
        }

        function cleanupTestCase() {
            TimerService.reset();
            Logger.setLogLevel(Logger.LogLevel.WARN);
        }

        function init() {
            TimerService.reset();
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function(tx) {
                tx.executeSql("DELETE FROM project_task_app");
                tx.executeSql("DELETE FROM project_project_app");
                tx.executeSql("DELETE FROM account_analytic_line_app");

                // Seed Project
                tx.executeSql("INSERT INTO project_project_app (id, odoo_record_id, name, color_pallet) VALUES (1, 101, 'Internal Project', '#EB6E67')");

                // Seed Task
                tx.executeSql("INSERT INTO project_task_app (id, odoo_record_id, name) VALUES (1, 201, 'Core Module Task')");

                // Seed Timesheets:
                // 1: Ready timesheet with 1.0 unit_amount
                tx.executeSql("INSERT INTO account_analytic_line_app (id, account_id, project_id, task_id, name, unit_amount, status) VALUES (1, 1, 101, 201, 'Feature Implementation', 1.0, 'draft')");

                // 2: Secondary ready timesheet with 0.5 unit_amount
                tx.executeSql("INSERT INTO account_analytic_line_app (id, account_id, project_id, task_id, name, unit_amount, status) VALUES (2, 1, 101, 201, 'Bug Investigation', 0.5, 'draft')");

                // 3: Invalid timesheet (no project_id or sub_project_id)
                tx.executeSql("INSERT INTO account_analytic_line_app (id, account_id, project_id, sub_project_id, name, unit_amount, status) VALUES (3, 1, 0, 0, 'Unassigned Task', 0.0, 'draft')");

                // 4: Finalized timesheet
                tx.executeSql("INSERT INTO account_analytic_line_app (id, account_id, project_id, task_id, name, unit_amount, status) VALUES (4, 1, 101, 201, 'Approved Timesheet', 2.0, 'updated')");
            });
        }

        function cleanup() {
            TimerService.reset();
        }

        function test_initialState() {
            compare(TimerService.isRunning(), false);
            compare(TimerService.isPaused(), false);
            compare(TimerService.getActiveTimesheetId(), null);
            compare(TimerService.getStartTime(), 0);
            compare(TimerService.getActiveTimesheetName(), "");
            compare(TimerService.getElapsedTime("hhmmss"), "00:00:00");
            compare(TimerService.getElapsedTime("hhmm"), "0.00");
            compare(TimerService.getElapsedDuration(), "0:00");
            compare(TimerService.stop(), "00:00:00");
        }

        function test_updateActiveTimesheetName() {
            TimerService.updateActiveTimesheetName("Developing Unit Tests");
            compare(TimerService.getActiveTimesheetName(), "Developing Unit Tests");

            TimerService.updateActiveTimesheetName("   Padded Title   ");
            compare(TimerService.getActiveTimesheetName(), "Padded Title");

            TimerService.updateActiveTimesheetName(null);
            compare(TimerService.getActiveTimesheetName(), "");

            TimerService.updateActiveTimesheetName(12345);
            compare(TimerService.getActiveTimesheetName(), "");
        }

        function test_startFailsWithoutProject() {
            var result = TimerService.start(3);
            compare(result.success, false);
            compare(result.error, "Unable to start timer, please select a project first");
            compare(TimerService.isRunning(), false);
            compare(TimerService.getActiveTimesheetId(), null);
        }

        function test_startSuccess() {
            var result = TimerService.start(1);
            compare(result.success, true);
            compare(result.error, "");
            compare(TimerService.isRunning(), true);
            compare(TimerService.isPaused(), false);
            compare(TimerService.getActiveTimesheetId(), 1);
            compare(TimerService.getActiveTimesheetName(), "Feature Implementation");
            verify(TimerService.getStartTime() > 0);

            // Verify status marked active in DB
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function(tx) {
                var rs = tx.executeSql("SELECT status FROM account_analytic_line_app WHERE id = 1");
                compare(rs.rows.item(0).status, "active");
            });
        }

        function test_redundantStartSameTimesheetIgnored() {
            TimerService.start(1);
            var initialStartTime = TimerService.getStartTime();

            // Calling start on the same active timesheet does not restart
            TimerService.start(1);
            compare(TimerService.isRunning(), true);
            compare(TimerService.getStartTime(), initialStartTime);
        }

        function test_pauseAndResume() {
            TimerService.start(1);
            compare(TimerService.isRunning(), true);
            compare(TimerService.isPaused(), false);

            TimerService.pause();
            compare(TimerService.isRunning(), true);
            compare(TimerService.isPaused(), true);

            // Calling pause when already paused does nothing
            TimerService.pause();
            compare(TimerService.isPaused(), true);

            // Resume
            TimerService.resume();
            compare(TimerService.isRunning(), true);
            compare(TimerService.isPaused(), false);
        }

        function test_startWhilePausedResumes() {
            TimerService.start(1);
            TimerService.pause();
            compare(TimerService.isPaused(), true);

            // Calling start(1) or start() while paused on the same timesheet should resume
            TimerService.start(1);
            compare(TimerService.isPaused(), false);
            compare(TimerService.isRunning(), true);
        }

        function test_stopRunningTimer() {
            TimerService.start(1);
            var elapsed = TimerService.stop();

            verify(elapsed !== undefined);
            verify(elapsed.length > 0);
            compare(TimerService.isRunning(), false);
            compare(TimerService.isPaused(), false);
            compare(TimerService.getActiveTimesheetId(), null);
            compare(TimerService.getStartTime(), 0);

            // Verify DB status reverted to draft
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function(tx) {
                var rs = tx.executeSql("SELECT status FROM account_analytic_line_app WHERE id = 1");
                compare(rs.rows.item(0).status, "draft");
            });
        }

        function test_stopPausedTimer() {
            TimerService.start(1);
            TimerService.pause();
            var elapsed = TimerService.stop();

            verify(elapsed !== undefined);
            compare(TimerService.isRunning(), false);
            compare(TimerService.isPaused(), false);
            compare(TimerService.getActiveTimesheetId(), null);
        }

        function test_switchTimesheetAutoSavesPrevious() {
            TimerService.start(1);
            compare(TimerService.getActiveTimesheetId(), 1);

            // Switch to timesheet 2
            TimerService.start(2);
            compare(TimerService.getActiveTimesheetId(), 2);
            compare(TimerService.isRunning(), true);

            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function(tx) {
                // Timesheet 1 should be reverted to draft and have duration updated
                var rs1 = tx.executeSql("SELECT status, unit_amount FROM account_analytic_line_app WHERE id = 1");
                compare(rs1.rows.item(0).status, "draft");

                // Timesheet 2 should be active
                var rs2 = tx.executeSql("SELECT status FROM account_analytic_line_app WHERE id = 2");
                compare(rs2.rows.item(0).status, "active");
            });
        }

        function test_stopFinalizedTimesheetPreservesStatus() {
            TimerService.start(1);
            compare(TimerService.getActiveTimesheetId(), 1);

            // Simulate timesheet being finalized/updated while timer was active
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function(tx) {
                tx.executeSql("UPDATE account_analytic_line_app SET status = 'updated' WHERE id = 1");
            });

            // Stop timer
            TimerService.stop();
            compare(TimerService.isRunning(), false);

            // Verify status is still updated, NOT reverted to draft
            db.transaction(function(tx) {
                var rs = tx.executeSql("SELECT status FROM account_analytic_line_app WHERE id = 1");
                compare(rs.rows.item(0).status, "updated");
            });
        }

        function test_resetClearsStateWithoutDbModification() {
            TimerService.start(1);
            compare(TimerService.isRunning(), true);

            TimerService.reset();
            compare(TimerService.isRunning(), false);
            compare(TimerService.isPaused(), false);
            compare(TimerService.getActiveTimesheetId(), null);
            compare(TimerService.getStartTime(), 0);
            compare(TimerService.getActiveTimesheetName(), "");
        }
    }
}
