import QtQuick 2.7
import QtTest 1.0
import QtQuick.LocalStorage 2.7 as Sql
import "../../../models/logger.js" as Logger
import "../../../models/database.js" as DBCommon
import "../../../models/dbinit.js" as DbInit
import "../../../models/utils.js" as Utils
import "../../../models/accounts.js" as AccountsModel

Item {
    width: 200
    height: 200

    TestCase {
        name: "AccountsModelTests"
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
                tx.executeSql("DELETE FROM users WHERE id >= 90000 OR name LIKE 'TestAccount%' OR name LIKE 'CreatedAccount%'");
                tx.executeSql("DELETE FROM attachment_download_app WHERE account_id = 999 OR record_id >= 90000");
                tx.executeSql("UPDATE users SET is_default = 0");
                // Ensure local account is default
                tx.executeSql("UPDATE users SET is_default = 1 WHERE id = 0");
            });
        }

        function init() {
            clearTestData();
        }

        function cleanup() {
            clearTestData();
        }

        // --- 1. Default Account Management ---

        function test_defaultAccountHandling() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function (tx) {
                tx.executeSql(
                    "INSERT INTO users (id, name, link, database, username, is_default) VALUES (?, ?, ?, ?, ?, ?)",
                    [90001, "TestAccount Alpha", "https://alpha.example.com", "db_alpha", "user_alpha", 0]
                );
                tx.executeSql(
                    "INSERT INTO users (id, name, link, database, username, is_default) VALUES (?, ?, ?, ?, ?, ?)",
                    [90002, "TestAccount Beta", "https://beta.example.com", "db_beta", "user_beta", 0]
                );
            });

            AccountsModel.setDefaultAccount(90001);
            compare(AccountsModel.getDefaultAccountId(), 90001);

            AccountsModel.setDefaultAccount(90002);
            compare(AccountsModel.getDefaultAccountId(), 90002);

            AccountsModel.clearDefaultAccount();
            // When none marked default, getDefaultAccountId falls back to first account (usually id 0)
            compare(AccountsModel.getDefaultAccountId(), 0);
        }

        // --- 2. Account Creation and Duplicate Detection ---

        function test_createAccount_success_and_duplicates() {
            var res1 = AccountsModel.createAccount("CreatedAccount One", "https://odoo1.com", "db1", "admin1", 1, "apikey1");
            verify(!res1.duplicateFound);

            // Duplicate name (case-insensitive)
            var resDupName = AccountsModel.createAccount("createdaccount one", "https://other.com", "otherdb", "otheruser", 1, "key");
            verify(resDupName.duplicateFound);
            compare(resDupName.duplicateType, "name");

            // Duplicate server connection
            var resDupConn = AccountsModel.createAccount("CreatedAccount Two", "https://odoo1.com", "db1", "admin1", 1, "apikey2");
            verify(resDupConn.duplicateFound);
            compare(resDupConn.duplicateType, "connection");
        }

        // --- 3. Account Name and Update ---

        function test_getAccountName_and_updateAccount() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function (tx) {
                tx.executeSql(
                    "INSERT INTO users (id, name, link, database, username) VALUES (?, ?, ?, ?, ?)",
                    [90010, "TestAccount Gamma", "https://gamma.com", "db_gamma", "user_gamma"]
                );
            });

            // Local account ID 0 name check
            compare(AccountsModel.getAccountName(0), "Local");

            // User account name check
            compare(AccountsModel.getAccountName(90010), "TestAccount Gamma");

            // Update account
            var updateRes = AccountsModel.updateAccount(90010, "TestAccount Gamma Renamed", "https://gamma2.com", "db_gamma2", "user_gamma2", 1, "newkey");
            verify(updateRes.success);

            compare(AccountsModel.getAccountName(90010), "TestAccount Gamma Renamed");
        }

        // --- 4. Delete Account and Related Data ---

        function test_deleteAccountAndRelatedData() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function (tx) {
                tx.executeSql(
                    "INSERT INTO users (id, name, link, database, username) VALUES (?, ?, ?, ?, ?)",
                    [90020, "TestAccount Delta", "https://delta.com", "db_delta", "user_delta"]
                );
                tx.executeSql(
                    "INSERT INTO project_project_app (id, odoo_record_id, name, account_id) VALUES (?, ?, ?, ?)",
                    [90021, 90021, "Delta Project", 90020]
                );
            });

            AccountsModel.deleteAccountAndRelatedData(90020);

            // User record should be deleted
            var afterUser = AccountsModel.getAccountName(90020);
            compare(afterUser, "");

            // Related project should also be deleted
            db.transaction(function (tx) {
                var rs = tx.executeSql("SELECT COUNT(*) AS count FROM project_project_app WHERE account_id = ?", [90020]);
                compare(rs.rows.item(0).count, 0);
            });

            // Verify local account 0 cannot be deleted
            AccountsModel.deleteAccountAndRelatedData(0);
            compare(AccountsModel.getAccountName(0), "Local");
        }

        // --- 5. Sync Settings ---

        function test_accountSyncSettings() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function (tx) {
                tx.executeSql(
                    "INSERT INTO users (id, name, link, database, username) VALUES (?, ?, ?, ?, ?)",
                    [90030, "TestAccount Sync", "https://sync.com", "db_sync", "user_sync"]
                );
            });

            AccountsModel.updateAccountSyncSettings(90030, 30, "download_only", 1);
            var settings = AccountsModel.getAccountSyncSettings(90030);
            compare(settings.sync_interval_minutes, 30);
            compare(settings.sync_direction, "download_only");
            compare(settings.autosync_enabled, 1);
        }

        // --- 6. Attachment Download Tracking ---

        function test_attachmentDownloadTracking() {
            compare(AccountsModel.isAttachmentDownloaded(999, 90040), false);

            AccountsModel.markAttachmentDownloaded(999, 90040, "specs.pdf");
            compare(AccountsModel.isAttachmentDownloaded(999, 90040), true);
        }
    }
}
