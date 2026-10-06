import QtQuick 2.7
import QtTest 1.0
import QtQuick.LocalStorage 2.7 as Sql
import "../../../models/logger.js" as Logger
import "../../../models/database.js" as DBCommon

Item {
    width: 200
    height: 200

    TestCase {
        name: "DatabaseTests"
        when: windowShown

        function initTestCase() {
            Logger.setLogLevel(Logger.LogLevel.NONE);
        }

        function cleanupTestCase() {
            Logger.setLogLevel(Logger.LogLevel.WARN);
        }

        function test_constants() {
            verify(DBCommon.NAME !== undefined);
            compare(typeof DBCommon.NAME, "string");
            compare(DBCommon.NAME, "myDatabase");

            verify(DBCommon.VERSION !== undefined);
            compare(typeof DBCommon.VERSION, "string");
            compare(DBCommon.VERSION, "1.0");

            verify(DBCommon.DISPLAY_NAME !== undefined);
            compare(typeof DBCommon.DISPLAY_NAME, "string");
            compare(DBCommon.DISPLAY_NAME, "My Database");

            verify(DBCommon.SIZE !== undefined);
            compare(typeof DBCommon.SIZE, "number");
            compare(DBCommon.SIZE, 1000000);
        }

        function test_getTimestamp() {
            var ts = DBCommon.getTimestamp();
            verify(ts !== undefined);
            compare(typeof ts, "string");
            verify(ts.length > 0);

            var parsed = new Date(ts);
            verify(!isNaN(parsed.getTime()));
        }

        function test_rowToObjectValid() {
            var mockRow = {
                id: 42,
                name: "Test Task",
                active: 1,
                notes: null
            };

            var obj = DBCommon.rowToObject(mockRow);
            verify(obj !== null);
            compare(obj.id, 42);
            compare(obj.name, "Test Task");
            compare(obj.active, 1);
            compare(obj.notes, null);
        }

        function test_rowToObjectInvalidInputs() {
            var objNull = DBCommon.rowToObject(null);
            verify(typeof objNull === "object");
            compare(Object.keys(objNull).length, 0);

            var objUndefined = DBCommon.rowToObject(undefined);
            verify(typeof objUndefined === "object");
            compare(Object.keys(objUndefined).length, 0);

            var objPrimitive = DBCommon.rowToObject("not a row");
            verify(typeof objPrimitive === "object");
        }

        function test_createOrUpdateTable() {
            var tableName = "tst_db_sample_table";
            var createSQL = "CREATE TABLE IF NOT EXISTS " + tableName + " (id INTEGER PRIMARY KEY, title TEXT)";
            var initialCols = ["title TEXT"];

            DBCommon.createOrUpdateTable(tableName, createSQL, initialCols);

            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function(tx) {
                var res = tx.executeSql("PRAGMA table_info(" + tableName + ")");
                var colNames = [];
                for (var i = 0; i < res.rows.length; i++) {
                    colNames.push(res.rows.item(i).name);
                }
                verify(colNames.indexOf("id") !== -1);
                verify(colNames.indexOf("title") !== -1);
            });

            // Update table with a new column
            var updatedCols = ["title TEXT", "priority INTEGER"];
            DBCommon.createOrUpdateTable(tableName, createSQL, updatedCols);

            db.transaction(function(tx) {
                var res = tx.executeSql("PRAGMA table_info(" + tableName + ")");
                var colNames = [];
                for (var i = 0; i < res.rows.length; i++) {
                    colNames.push(res.rows.item(i).name);
                }
                verify(colNames.indexOf("priority") !== -1);
                tx.executeSql("DROP TABLE IF EXISTS " + tableName);
            });
        }

        function test_ensureDefaultLocalAccountExists() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

            db.transaction(function(tx) {
                tx.executeSql("CREATE TABLE IF NOT EXISTS users (" +
                              "id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, link TEXT NOT NULL, " +
                              "last_modified datetime, database TEXT NOT NULL, connectwith_id INTEGER, " +
                              "api_key TEXT, username TEXT NOT NULL, is_default INTEGER DEFAULT 0)");

                tx.executeSql("CREATE TABLE IF NOT EXISTS res_users_app (" +
                              "id INTEGER PRIMARY KEY AUTOINCREMENT, account_id INTEGER, name TEXT, login TEXT, " +
                              "email TEXT, work_email TEXT, mobile_phone TEXT, job_title TEXT, company_id INTEGER, " +
                              "share INTEGER, active INTEGER, status TEXT, odoo_record_id INTEGER)");

                tx.executeSql("CREATE TABLE IF NOT EXISTS project_project_stage_app (" +
                              "id INTEGER PRIMARY KEY AUTOINCREMENT, account_id INTEGER, odoo_record_id INTEGER, " +
                              "name TEXT, sequence INTEGER, fold INTEGER, active INTEGER, create_date TEXT, " +
                              "write_date TEXT, status TEXT)");

                tx.executeSql("CREATE TABLE IF NOT EXISTS project_project_app (" +
                              "id INTEGER PRIMARY KEY AUTOINCREMENT, account_id INTEGER, stage INTEGER)");

                tx.executeSql("CREATE TABLE IF NOT EXISTS project_task_type_app (" +
                              "id INTEGER PRIMARY KEY AUTOINCREMENT, account_id INTEGER, odoo_record_id INTEGER, " +
                              "name TEXT, sequence INTEGER, fold INTEGER, is_global INTEGER, active INTEGER, " +
                              "create_date TEXT, write_date TEXT, status TEXT)");

                tx.executeSql("CREATE TABLE IF NOT EXISTS project_task_app (" +
                              "id INTEGER PRIMARY KEY AUTOINCREMENT, account_id INTEGER, state TEXT)");
            });

            DBCommon.ensureDefaultLocalAccountExists();

            db.transaction(function(tx) {
                var userRes = tx.executeSql("SELECT * FROM users WHERE id = 0");
                verify(userRes.rows.length > 0);
                var userRow = userRes.rows.item(0);
                compare(userRow.name, "Local");
                compare(userRow.username, "local_user");
                compare(userRow.is_default, 1);

                var resUserRes = tx.executeSql("SELECT * FROM res_users_app WHERE account_id = 0 AND odoo_record_id = -1");
                verify(resUserRes.rows.length > 0);
                var resUserRow = resUserRes.rows.item(0);
                compare(resUserRow.name, "Local User");
                compare(resUserRow.login, "local_user");
            });
        }

        function test_ensureDefaultLocalActivityTypes() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

            db.transaction(function(tx) {
                tx.executeSql("CREATE TABLE IF NOT EXISTS mail_activity_type_app (" +
                              "id INTEGER PRIMARY KEY AUTOINCREMENT, account_id INTEGER, name TEXT, " +
                              "status TEXT, odoo_record_id INTEGER)");
            });

            DBCommon.ensureDefaultLocalActivityTypes();

            db.transaction(function(tx) {
                var res = tx.executeSql("SELECT name FROM mail_activity_type_app WHERE account_id = 0");
                verify(res.rows.length >= 4);

                var names = [];
                for (var i = 0; i < res.rows.length; i++) {
                    names.push(res.rows.item(i).name);
                }

                verify(names.indexOf("To Do") !== -1);
                verify(names.indexOf("Call") !== -1);
                verify(names.indexOf("Email") !== -1);
                verify(names.indexOf("Meeting") !== -1);
            });
        }

        function test_ensureDefaultLocalProjectStages() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

            db.transaction(function(tx) {
                tx.executeSql("CREATE TABLE IF NOT EXISTS project_project_stage_app (" +
                              "id INTEGER PRIMARY KEY AUTOINCREMENT, account_id INTEGER, odoo_record_id INTEGER, " +
                              "name TEXT, sequence INTEGER, fold INTEGER, active INTEGER, create_date TEXT, " +
                              "write_date TEXT, status TEXT)");
                tx.executeSql("CREATE TABLE IF NOT EXISTS project_project_app (" +
                              "id INTEGER PRIMARY KEY AUTOINCREMENT, account_id INTEGER, stage INTEGER)");
            });

            DBCommon.ensureDefaultLocalProjectStages();

            db.transaction(function(tx) {
                var res = tx.executeSql("SELECT name, odoo_record_id FROM project_project_stage_app WHERE account_id = 0 ORDER BY sequence ASC");
                verify(res.rows.length >= 4);

                var stageNames = [];
                for (var i = 0; i < res.rows.length; i++) {
                    stageNames.push(res.rows.item(i).name);
                }

                verify(stageNames.indexOf("Planning") !== -1);
                verify(stageNames.indexOf("In Progress") !== -1);
                verify(stageNames.indexOf("Completed") !== -1);
                verify(stageNames.indexOf("Cancelled") !== -1);
            });
        }

        function test_ensureDefaultLocalTaskStages() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

            db.transaction(function(tx) {
                tx.executeSql("CREATE TABLE IF NOT EXISTS project_task_type_app (" +
                              "id INTEGER PRIMARY KEY AUTOINCREMENT, account_id INTEGER, odoo_record_id INTEGER, " +
                              "name TEXT, sequence INTEGER, fold INTEGER, is_global INTEGER, active INTEGER, " +
                              "create_date TEXT, write_date TEXT, status TEXT)");
                tx.executeSql("CREATE TABLE IF NOT EXISTS project_task_app (" +
                              "id INTEGER PRIMARY KEY AUTOINCREMENT, account_id INTEGER, state TEXT)");
            });

            DBCommon.ensureDefaultLocalTaskStages();

            db.transaction(function(tx) {
                var res = tx.executeSql("SELECT name FROM project_task_type_app WHERE account_id = 0 ORDER BY sequence ASC");
                verify(res.rows.length >= 4);

                var stageNames = [];
                for (var i = 0; i < res.rows.length; i++) {
                    stageNames.push(res.rows.item(i).name);
                }

                verify(stageNames.indexOf("New") !== -1);
                verify(stageNames.indexOf("In Progress") !== -1);
                verify(stageNames.indexOf("Done") !== -1);
                verify(stageNames.indexOf("Cancelled") !== -1);
            });
        }
    }
}
