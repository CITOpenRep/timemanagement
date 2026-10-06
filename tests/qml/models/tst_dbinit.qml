import QtQuick 2.7
import QtTest 1.0
import QtQuick.LocalStorage 2.7 as Sql
import "../../../models/logger.js" as Logger
import "../../../models/database.js" as DBCommon
import "../../../models/dbinit.js" as DbInit

Item {
    width: 200
    height: 200

    TestCase {
        name: "DbInitTests"
        when: windowShown

        function initTestCase() {
            Logger.setLogLevel(Logger.LogLevel.NONE);
        }

        function cleanupTestCase() {
            Logger.setLogLevel(Logger.LogLevel.WARN);
        }

        function test_initializeDatabaseCreatesTables() {
            DbInit.initializeDatabase();

            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

            var expectedTables = [
                "sync_report",
                "users",
                "notification",
                "app_settings",
                "project_project_app",
                "res_users_app",
                "project_task_app",
                "account_analytic_line_app",
                "mail_activity_app",
                "form_drafts"
            ];

            db.transaction(function(tx) {
                var res = tx.executeSql("SELECT name FROM sqlite_master WHERE type='table'");
                var existingTables = [];
                for (var i = 0; i < res.rows.length; i++) {
                    existingTables.push(res.rows.item(i).name);
                }

                for (var j = 0; j < expectedTables.length; j++) {
                    var tbl = expectedTables[j];
                    verify(existingTables.indexOf(tbl) !== -1, "Expected table: " + tbl + " to exist");
                }
            });
        }

        function test_initializeAutoSyncSettings() {
            DbInit.initializeDatabase();
            DbInit.initializeAutoSyncSettings();

            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function(tx) {
                var resInterval = tx.executeSql("SELECT value FROM app_settings WHERE key = 'auto_sync_interval'");
                verify(resInterval.rows.length > 0);
                compare(resInterval.rows.item(0).value, "15");

                var resEnabled = tx.executeSql("SELECT value FROM app_settings WHERE key = 'auto_sync_enabled'");
                verify(resEnabled.rows.length > 0);
                compare(resEnabled.rows.item(0).value, "false");
            });
        }

        function test_performPostStartupMaintenance() {
            DbInit.initializeDatabase();
            // Verify maintenance executes cleanly without error
            DbInit.performPostStartupMaintenance();
            verify(true);
        }

        function test_purgeCache() {
            DbInit.initializeDatabase();
            // Verify cache purge executes safely
            DbInit.purgeCache();
            verify(true);
        }

        function test_syncDraftFlags() {
            DbInit.initializeDatabase();

            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function(tx) {
                // Clear any existing draft records
                tx.executeSql("DELETE FROM form_drafts");
                tx.executeSql("DELETE FROM project_task_app WHERE id = 9999");

                // Seed task with has_draft = 0
                tx.executeSql("INSERT OR REPLACE INTO project_task_app (id, name, account_id, has_draft) VALUES (9999, 'Draft Sync Task', 0, 0)");

                // Insert a matching draft for task 9999
                tx.executeSql("INSERT INTO form_drafts (draft_type, record_id, account_id, page_identifier, draft_data, created_at, updated_at) " +
                              "VALUES ('task', 9999, 0, 'test_page', '{\"name\":\"Draft Sync Task\"}', datetime('now'), datetime('now'))");
            });

            DbInit.syncDraftFlags();

            db.transaction(function(tx) {
                var res = tx.executeSql("SELECT has_draft FROM project_task_app WHERE id = 9999");
                verify(res.rows.length > 0);
                compare(res.rows.item(0).has_draft, 1);

                // Clean up test rows
                tx.executeSql("DELETE FROM form_drafts WHERE record_id = 9999");
                tx.executeSql("DELETE FROM project_task_app WHERE id = 9999");
            });
        }
    }
}
