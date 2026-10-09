import QtQuick 2.7
import QtTest 1.0
import QtQuick.LocalStorage 2.7 as Sql
import "../../../models/logger.js" as Logger
import "../../../models/database.js" as DBCommon
import "../../../models/dbinit.js" as DBInit
import "../../../models/global.js" as Global
import "../../../models/accounts.js" as Account
import "../../../models/project.js" as Project
import "../../../models/task.js" as Task
import "../../../models/timesheet.js" as Timesheet
import "../../../models/Main.js" as Main
import "../../../qml/components/visualization"

Item {
    width: 200
    height: 200

    EHower {
        id: testEHower
        visible: false
        autoRefreshOnAccountChange: false
    }

    TestCase {
        name: "DashboardUserFilterTests"
        when: windowShown

        function initTestCase() {
            Logger.setLogLevel(Logger.LogLevel.NONE);
            DBInit.initializeDatabase();
        }

        function cleanupTestCase() {
            Logger.setLogLevel(Logger.LogLevel.WARN);
        }

        function init() {
            Global.setDashboardUserFilter(-1, "All Users");
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function(tx) {
                tx.executeSql("DELETE FROM users");
                tx.executeSql("DELETE FROM res_users_app");
                tx.executeSql("DELETE FROM project_project_app");
                tx.executeSql("DELETE FROM project_task_app");
                tx.executeSql("DELETE FROM account_analytic_line_app");
            });
        }

        // --- 1. Global User Filter State ---
        function test_globalDashboardUserFilterState() {
            Global.setDashboardUserFilter(-1, "All Users");
            var current = Global.getDashboardUserFilter();
            compare(current.userId, -1);
            compare(current.userName, "All Users");

            Global.setDashboardUserFilter(101, "Alice Smith");
            current = Global.getDashboardUserFilter();
            compare(current.userId, 101);
            compare(current.userName, "Alice Smith");

            // Reset with null/undefined values
            Global.setDashboardUserFilter(null, "");
            current = Global.getDashboardUserFilter();
            compare(current.userId, -1);
            compare(current.userName, "All Users");
        }

        // --- 2. Account.getDashboardFilterUsers ---
        function test_getDashboardFilterUsers_empty() {
            var users = Account.getDashboardFilterUsers(1);
            compare(users.length, 0);
        }

        function test_getDashboardFilterUsers_populated() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function(tx) {
                // Account 1 active users
                tx.executeSql("INSERT INTO res_users_app (account_id, odoo_record_id, name, active) VALUES (1, 10, 'Charlie', 1)");
                tx.executeSql("INSERT INTO res_users_app (account_id, odoo_record_id, name, active) VALUES (1, 20, 'Alice', 1)");
                tx.executeSql("INSERT INTO res_users_app (account_id, odoo_record_id, name, active) VALUES (1, 30, 'Bob', 1)");
                // Account 1 inactive user (should be ignored)
                tx.executeSql("INSERT INTO res_users_app (account_id, odoo_record_id, name, active) VALUES (1, 40, 'Inactive User', 0)");
                // Account 2 user (should be ignored)
                tx.executeSql("INSERT INTO res_users_app (account_id, odoo_record_id, name, active) VALUES (2, 50, 'Account2 User', 1)");
            });

            var users = Account.getDashboardFilterUsers(1);
            compare(users.length, 3);
            // Should be sorted alphabetically: Alice, Bob, Charlie
            compare(users[0].name, "Alice");
            compare(users[0].id, 20);
            compare(users[1].name, "Bob");
            compare(users[1].id, 30);
            compare(users[2].name, "Charlie");
            compare(users[2].id, 10);
        }

        // --- 3. Account.getDashboardSingleUserDefault ---
        function test_getDashboardSingleUserDefault_singleUser() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function(tx) {
                tx.executeSql("INSERT INTO res_users_app (account_id, odoo_record_id, name, active) VALUES (1, 15, 'Single User', 1)");
            });

            var available = Account.getDashboardFilterUsers(1);
            compare(available.length, 1);
            var defaultUser = Account.getDashboardSingleUserDefault(1, available);
            verify(defaultUser !== null);
            compare(defaultUser.id, 15);
            compare(defaultUser.name, "Single User");
        }

        function test_getDashboardSingleUserDefault_standardEmployeeSingleTimesheets() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function(tx) {
                // Multiple users exist in directory
                tx.executeSql("INSERT INTO res_users_app (account_id, odoo_record_id, name, active) VALUES (1, 10, 'Employee Alice', 1)");
                tx.executeSql("INSERT INTO res_users_app (account_id, odoo_record_id, name, active) VALUES (1, 20, 'Manager Bob', 1)");

                // But only Alice's timesheets are synced locally (standard employee permission)
                tx.executeSql("INSERT INTO account_analytic_line_app (account_id, user_id, unit_amount, record_date, status) VALUES (1, 10, 8.0, '2026-10-01', 'synced')");
                tx.executeSql("INSERT INTO account_analytic_line_app (account_id, user_id, unit_amount, record_date, status) VALUES (1, 10, 7.5, '2026-10-02', 'synced')");
            });

            var available = Account.getDashboardFilterUsers(1);
            compare(available.length, 1);
            var defaultUser = Account.getDashboardSingleUserDefault(1, available);
            verify(defaultUser !== null);
            compare(defaultUser.id, 10);
            compare(defaultUser.name, "Employee Alice");
        }

        function test_getDashboardSingleUserDefault_managerMultipleTimesheets() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function(tx) {
                // Account 1 with Bob logged in as manager
                tx.executeSql("INSERT INTO users (id, name, link, database, username) VALUES (1, 'Acme Corp', 'https://odoo.acme.com', 'acme_db', 'bob')");

                // Multiple users exist
                tx.executeSql("INSERT INTO res_users_app (account_id, odoo_record_id, name, login, active) VALUES (1, 10, 'Alice', 'alice', 1)");
                tx.executeSql("INSERT INTO res_users_app (account_id, odoo_record_id, name, login, active) VALUES (1, 20, 'Bob', 'bob', 1)");

                // Both users have timesheets
                tx.executeSql("INSERT INTO account_analytic_line_app (account_id, user_id, unit_amount, record_date, status) VALUES (1, 10, 8.0, '2026-10-01', 'synced')");
                tx.executeSql("INSERT INTO account_analytic_line_app (account_id, user_id, unit_amount, record_date, status) VALUES (1, 20, 6.0, '2026-10-01', 'synced')");
            });

            var available = Account.getDashboardFilterUsers(1);
            compare(available.length, 2);
            var defaultUser = Account.getDashboardSingleUserDefault(1, available);
            // Manager viewing team: should default to logged-in user's personal metrics (Bob, 20), not All Users
            verify(defaultUser !== null);
            compare(defaultUser.id, 20);
            compare(defaultUser.name, "Bob");
        }

        function test_getDashboardSingleUserDefault_unresolvedLoggedInUserMultipleUsers() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function(tx) {
                // No entry in users table for account 1
                tx.executeSql("INSERT INTO res_users_app (account_id, odoo_record_id, name, login, active) VALUES (1, 10, 'Alice', 'alice', 1)");
                tx.executeSql("INSERT INTO res_users_app (account_id, odoo_record_id, name, login, active) VALUES (1, 20, 'Bob', 'bob', 1)");
            });

            var available = Account.getDashboardFilterUsers(1);
            compare(available.length, 2);
            var defaultUser = Account.getDashboardSingleUserDefault(1, available);
            // If logged-in user cannot be resolved and multiple users exist, returns null (fallback to All Users)
            compare(defaultUser, null);
        }

        function test_getDashboardSingleUserDefault_localAccount() {
            var defaultUser = Account.getDashboardSingleUserDefault(0);
            verify(defaultUser !== null);
            compare(defaultUser.id, 1);
            compare(defaultUser.name, "Local User");

            var users = Account.getDashboardFilterUsers(0);
            compare(users.length, 1);
            compare(users[0].name, "Local User");
        }

        // --- 4. Filtering in Model Queries ---
        function test_projectSpentHoursList_userIdFilter() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function(tx) {
                tx.executeSql("INSERT INTO project_project_app (id, account_id, odoo_record_id, name) VALUES (1, 1, 100, 'Project Alpha')");
                tx.executeSql("INSERT INTO project_project_app (id, account_id, odoo_record_id, name) VALUES (2, 1, 200, 'Project Beta')");

                // Project Alpha: Alice 5 hrs, Bob 3 hrs
                tx.executeSql("INSERT INTO account_analytic_line_app (account_id, project_id, user_id, unit_amount, record_date, status) VALUES (1, 100, 10, 5.0, '2026-10-01', 'synced')");
                tx.executeSql("INSERT INTO account_analytic_line_app (account_id, project_id, user_id, unit_amount, record_date, status) VALUES (1, 100, 20, 3.0, '2026-10-01', 'synced')");

                // Project Beta: Alice 2 hrs, Bob 7 hrs
                tx.executeSql("INSERT INTO account_analytic_line_app (account_id, project_id, user_id, unit_amount, record_date, status) VALUES (1, 200, 10, 2.0, '2026-10-01', 'synced')");
                tx.executeSql("INSERT INTO account_analytic_line_app (account_id, project_id, user_id, unit_amount, record_date, status) VALUES (1, 200, 20, 7.0, '2026-10-01', 'synced')");
            });

            // All Users (userId = -1)
            var allData = Project.getProjectSpentHoursList(true, 1, "", "", -1);
            compare(allData.length, 2);
            var alphaAll = allData.filter(function(p) { return p.name === "Project Alpha"; })[0];
            var betaAll = allData.filter(function(p) { return p.name === "Project Beta"; })[0];
            compare(alphaAll.spentHours, 8.0);
            compare(betaAll.spentHours, 9.0);

            // Filter by Alice (userId = 10)
            var aliceData = Project.getProjectSpentHoursList(true, 1, "", "", 10);
            compare(aliceData.length, 2);
            var alphaAlice = aliceData.filter(function(p) { return p.name === "Project Alpha"; })[0];
            var betaAlice = aliceData.filter(function(p) { return p.name === "Project Beta"; })[0];
            compare(alphaAlice.spentHours, 5.0);
            compare(betaAlice.spentHours, 2.0);

            // Filter by Bob (userId = 20)
            var bobData = Project.getProjectSpentHoursList(true, 1, "", "", 20);
            compare(bobData.length, 2);
            var alphaBob = bobData.filter(function(p) { return p.name === "Project Alpha"; })[0];
            var betaBob = bobData.filter(function(p) { return p.name === "Project Beta"; })[0];
            compare(alphaBob.spentHours, 3.0);
            compare(betaBob.spentHours, 7.0);
        }

        function test_mainSpentHours_userIdFilter() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function(tx) {
                tx.executeSql("INSERT INTO project_project_app (id, account_id, odoo_record_id, name) VALUES (1, 1, 100, 'Project Alpha')");
                tx.executeSql("INSERT INTO project_task_app (id, account_id, odoo_record_id, name, project_id) VALUES (1, 1, 501, 'Task 1', 100)");

                tx.executeSql("INSERT INTO account_analytic_line_app (account_id, project_id, task_id, user_id, unit_amount, record_date, status) VALUES (1, 100, 501, 10, 4.0, '2026-10-01', 'synced')");
                tx.executeSql("INSERT INTO account_analytic_line_app (account_id, project_id, task_id, user_id, unit_amount, record_date, status) VALUES (1, 100, 501, 20, 6.0, '2026-10-01', 'synced')");
            });

            // Projects spent hours via Main.get_projects_spent_hours
            var allProjects = Main.get_projects_spent_hours(1, "", "", -1);
            compare(allProjects.length, 1);
            compare(allProjects[0].total, 10.0);

            var aliceProjects = Main.get_projects_spent_hours(1, "", "", 10);
            compare(aliceProjects.length, 1);
            compare(aliceProjects[0].total, 4.0);

            // Pie chart spent hours via Project.getProjectSpentHoursList
            var allPieProjects = Project.getProjectSpentHoursList(true, 1, "", "", -1);
            compare(allPieProjects.length, 1);
            compare(allPieProjects[0].spentHours, 10.0);

            var alicePieProjects = Project.getProjectSpentHoursList(true, 1, "", "", 10);
            compare(alicePieProjects.length, 1);
            compare(alicePieProjects[0].spentHours, 4.0);

            var bobPieProjects = Project.getProjectSpentHoursList(true, 1, "", "", 20);
            compare(bobPieProjects.length, 1);
            compare(bobPieProjects[0].spentHours, 6.0);

            // Tasks spent hours via Main.get_tasks_spent_hours
            var allTasks = Main.get_tasks_spent_hours(1, "", "", -1);
            compare(allTasks["Task 1"], 10.0);

            var aliceTasks = Main.get_tasks_spent_hours(1, "", "", 10);
            compare(aliceTasks["Task 1"], 4.0);

            var bobTasks = Main.get_tasks_spent_hours(1, "", "", 20);
            compare(bobTasks["Task 1"], 6.0);
        }

        function test_timesheetsForTask_userIdFilter() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function(tx) {
                tx.executeSql("INSERT INTO project_project_app (id, account_id, odoo_record_id, name) VALUES (1, 1, 100, 'Project Alpha')");
                tx.executeSql("INSERT INTO project_task_app (id, account_id, odoo_record_id, name, project_id) VALUES (1, 1, 501, 'Task 1', 100)");

                tx.executeSql("INSERT INTO account_analytic_line_app (account_id, project_id, task_id, user_id, unit_amount, name, record_date, status) VALUES (1, 100, 501, 10, 2.5, 'Alice Work', '2026-10-01', 'synced')");
                tx.executeSql("INSERT INTO account_analytic_line_app (account_id, project_id, task_id, user_id, unit_amount, name, record_date, status) VALUES (1, 100, 501, 20, 3.5, 'Bob Work', '2026-10-01', 'synced')");
            });

            // All timesheets
            var allTs = Timesheet.getTimesheetsForTask(501, 1, "all", "", "", -1);
            compare(allTs.length, 2);

            // Alice only
            var aliceTs = Timesheet.getTimesheetsForTask(501, 1, "all", "", "", 10);
            compare(aliceTs.length, 1);
            compare(aliceTs[0].name, "Alice Work");

            // Bob only
            var bobTs = Timesheet.getTimesheetsForTask(501, 1, "all", "", "", 20);
            compare(bobTs.length, 1);
            compare(bobTs[0].name, "Bob Work");
        }

        // --- 5. Eisenhower Priority Matrix User Filter ---
        function test_eisenhowerQuadrants_userIdFilter() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function(tx) {
                // Alice (10): Q1 = 3 hrs, Q3 = 1 hr
                tx.executeSql("INSERT INTO account_analytic_line_app (account_id, quadrant_id, user_id, unit_amount, record_date, status) VALUES (1, 1, 10, 3.0, '2026-10-01', 'synced')");
                tx.executeSql("INSERT INTO account_analytic_line_app (account_id, quadrant_id, user_id, unit_amount, record_date, status) VALUES (1, 3, 10, 1.0, '2026-10-01', 'synced')");
                // Bob (20): Q1 = 5 hrs, Q2 = 4 hrs
                tx.executeSql("INSERT INTO account_analytic_line_app (account_id, quadrant_id, user_id, unit_amount, record_date, status) VALUES (1, 1, 20, 5.0, '2026-10-01', 'synced')");
                tx.executeSql("INSERT INTO account_analytic_line_app (account_id, quadrant_id, user_id, unit_amount, record_date, status) VALUES (1, 2, 20, 4.0, '2026-10-01', 'synced')");
                // Charlie (30): Q2 = 2 hrs, Q4 = 7 hrs
                tx.executeSql("INSERT INTO account_analytic_line_app (account_id, quadrant_id, user_id, unit_amount, record_date, status) VALUES (1, 2, 30, 2.0, '2026-10-01', 'synced')");
                tx.executeSql("INSERT INTO account_analytic_line_app (account_id, quadrant_id, user_id, unit_amount, record_date, status) VALUES (1, 4, 30, 7.0, '2026-10-01', 'synced')");
            });

            // 1. All users (-1)
            var allTotals = testEHower.getQuadrantHoursFromAllInstances(1, "", "", -1);
            compare(allTotals[1], "8"); // 3 + 5
            compare(allTotals[2], "6"); // 4 + 2
            compare(allTotals[3], "1"); // 1
            compare(allTotals[4], "7"); // 7

            // 2. Single user: Alice (10)
            var aliceTotals = testEHower.getQuadrantHoursFromAllInstances(1, "", "", 10);
            compare(aliceTotals[1], "3");
            compare(aliceTotals[2], "0");
            compare(aliceTotals[3], "1");
            compare(aliceTotals[4], "0");

            // 3. Single user: Bob (20)
            var bobTotals = testEHower.getQuadrantHoursFromAllInstances(1, "", "", 20);
            compare(bobTotals[1], "5");
            compare(bobTotals[2], "4");
            compare(bobTotals[3], "0");
            compare(bobTotals[4], "0");

            // 4. Multi-user selection array: Alice (10) and Bob (20)
            var aliceBobTotals = testEHower.getQuadrantHoursFromAllInstances(1, "", "", [10, 20]);
            compare(aliceBobTotals[1], "8"); // 3 + 5
            compare(aliceBobTotals[2], "4"); // 4
            compare(aliceBobTotals[3], "1"); // 1
            compare(aliceBobTotals[4], "0"); // 0

            // 5. Multi-user selection array: Bob (20) and Charlie (30)
            var bobCharlieTotals = testEHower.getQuadrantHoursFromAllInstances(1, "", "", [20, 30]);
            compare(bobCharlieTotals[1], "5"); // 5
            compare(bobCharlieTotals[2], "6"); // 4 + 2
            compare(bobCharlieTotals[3], "0"); // 0
            compare(bobCharlieTotals[4], "7"); // 7

            // 6. Selection objects array: [{ user_id: 10, account_id: 1 }, { user_id: 30, account_id: 1 }]
            var objTotals = testEHower.getQuadrantHoursFromAllInstances(1, "", "", [
                { user_id: 10, account_id: 1 },
                { user_id: 30, account_id: 1 }
            ]);
            compare(objTotals[1], "3"); // 3
            compare(objTotals[2], "2"); // 2
            compare(objTotals[3], "1"); // 1
            compare(objTotals[4], "7"); // 7

            // 7. Verify refreshQuadrants updates component properties
            testEHower.refreshQuadrants("", "", [10, 20], 1);
            compare(testEHower.quadrant1Hours, "8H");
            compare(testEHower.quadrant2Hours, "4H");
            compare(testEHower.quadrant3Hours, "1H");
            compare(testEHower.quadrant4Hours, "0H");
        }

        // --- 6. Tasks Tab Summary & Project Tasks User Filter ---
        function test_dashboardProjectTaskSummary_userIdFilter() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function(tx) {
                tx.executeSql("INSERT INTO project_project_app (id, account_id, odoo_record_id, name) VALUES (1, 1, 100, 'Project Alpha')");
                tx.executeSql("INSERT INTO project_task_app (id, account_id, odoo_record_id, name, project_id) VALUES (1, 1, 501, 'Task 1', 100)");

                tx.executeSql("INSERT INTO account_analytic_line_app (account_id, project_id, task_id, user_id, unit_amount, record_date, status) VALUES (1, 100, 501, 10, 2.0, '2026-10-01', 'synced')");
                tx.executeSql("INSERT INTO account_analytic_line_app (account_id, project_id, task_id, user_id, unit_amount, record_date, status) VALUES (1, 100, 501, 20, 6.0, '2026-10-01', 'synced')");
            });

            // Summary: all users (-1)
            var allSummary = Project.getDashboardProjectTaskSummary(1, "", "", -1);
            compare(allSummary.length, 1);
            compare(allSummary[0].totalHours, 8.0);

            // Summary: Alice (10)
            var aliceSummary = Project.getDashboardProjectTaskSummary(1, "", "", 10);
            compare(aliceSummary.length, 1);
            compare(aliceSummary[0].totalHours, 2.0);

            // Summary: Bob (20)
            var bobSummary = Project.getDashboardProjectTaskSummary(1, "", "", 20);
            compare(bobSummary.length, 1);
            compare(bobSummary[0].totalHours, 6.0);

            // Tasks for project: Alice (10)
            var aliceTasks = Task.getTasksForProject(100, 1, "", "", 10);
            compare(aliceTasks.length, 1);

            // Tasks for project: non-existent user (99)
            var nonExistentTasks = Task.getTasksForProject(100, 1, "", "", 99);
            compare(nonExistentTasks.length, 0);
        }

        // --- 7. Combining users by email across accounts ---
        function test_combineUsersByEmail_acrossAccounts() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function(tx) {
                tx.executeSql("INSERT INTO users (id, name, link, database, username, is_default) VALUES (1, 'Account 1', 'https://a1.com', 'db1', 'u1', 1)");
                tx.executeSql("INSERT INTO users (id, name, link, database, username, is_default) VALUES (2, 'Account 2', 'https://a2.com', 'db2', 'u2', 0)");

                // Account 1: User 10 named 'Parvathy', email 'p.nair@cit-services.eu'
                tx.executeSql("INSERT INTO res_users_app (account_id, odoo_record_id, name, email, login, active) VALUES (1, 10, 'Parvathy', 'p.nair@cit-services.eu', 'pnair', 1)");
                // Account 2: User 25 named 'Parvathy Nair', email 'p.nair@cit-services.eu'
                tx.executeSql("INSERT INTO res_users_app (account_id, odoo_record_id, name, email, login, active) VALUES (2, 25, 'Parvathy Nair', 'p.nair@cit-services.eu', 'pnair2', 1)");
                // Account 2: User 30 named 'Other User', email 'other@cit-services.eu'
                tx.executeSql("INSERT INTO res_users_app (account_id, odoo_record_id, name, email, login, active) VALUES (2, 30, 'Other User', 'other@cit-services.eu', 'other', 1)");

                // Timesheets so they appear as active dashboard users
                tx.executeSql("INSERT INTO account_analytic_line_app (account_id, user_id, unit_amount, record_date, status) VALUES (1, 10, 2.5, '2026-10-01', 'synced')");
                tx.executeSql("INSERT INTO account_analytic_line_app (account_id, user_id, unit_amount, record_date, status) VALUES (2, 25, 4.0, '2026-10-02', 'synced')");
                tx.executeSql("INSERT INTO account_analytic_line_app (account_id, user_id, unit_amount, record_date, status) VALUES (2, 30, 1.5, '2026-10-03', 'synced')");
            });

            // Single account 1: only Parvathy
            var acc1Users = Account.getDashboardFilterUsers(1);
            compare(acc1Users.length, 1);
            compare(acc1Users[0].id, 10);
            compare(acc1Users[0].name, "Parvathy");

            // Single account 2: Parvathy Nair and Other User
            var acc2Users = Account.getDashboardFilterUsers(2);
            compare(acc2Users.length, 2);

            // All accounts (-1): Should combine users by email
            var allUsers = Account.getDashboardFilterUsers(-1);
            compare(allUsers.length, 2);

            // Find combined Parvathy Nair entry
            var pEntry = null;
            for (var i = 0; i < allUsers.length; i++) {
                if (allUsers[i].email === "p.nair@cit-services.eu") {
                    pEntry = allUsers[i];
                    break;
                }
            }
            verify(pEntry !== null);
            // Should choose the longer, more complete name 'Parvathy Nair'
            compare(pEntry.name, "Parvathy Nair");
            // allUserIds should contain both IDs (10 and 25)
            verify(pEntry.allUserIds.indexOf(10) !== -1);
            verify(pEntry.allUserIds.indexOf(25) !== -1);
        }

        // --- 8. Cross-Account buildUserFilterSQL & Data Aggregation across widgets ---
        function test_crossAccountCombinedUserDataAggregation() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function(tx) {
                tx.executeSql("INSERT INTO users (id, name, link, database, username, is_default) VALUES (1, 'Instance 1', 'https://a1.com', 'db1', 'u1', 1)");
                tx.executeSql("INSERT INTO users (id, name, link, database, username, is_default) VALUES (2, 'Instance 2', 'https://a2.com', 'db2', 'u2', 0)");

                tx.executeSql("INSERT INTO res_users_app (account_id, odoo_record_id, name, email, active) VALUES (1, 10, 'Parvathy', 'p.nair@cit-services.eu', 1)");
                tx.executeSql("INSERT INTO res_users_app (account_id, odoo_record_id, name, email, active) VALUES (2, 25, 'Parvathy Nair', 'p.nair@cit-services.eu', 1)");
                tx.executeSql("INSERT INTO res_users_app (account_id, odoo_record_id, name, email, active) VALUES (2, 30, 'Bob Ross', 'bob@example.com', 1)");

                tx.executeSql("INSERT INTO project_project_app (id, account_id, odoo_record_id, name) VALUES (1, 1, 101, 'Project In Instance 1')");
                tx.executeSql("INSERT INTO project_project_app (id, account_id, odoo_record_id, name) VALUES (2, 2, 202, 'Project In Instance 2')");

                tx.executeSql("INSERT INTO project_task_app (id, account_id, odoo_record_id, name, project_id) VALUES (1, 1, 501, 'Task A1', 101)");
                tx.executeSql("INSERT INTO project_task_app (id, account_id, odoo_record_id, name, project_id) VALUES (2, 2, 601, 'Task A2', 202)");

                // Timesheets:
                // Instance 1, user 10 (Parvathy): 3.0 hrs in Project 101
                tx.executeSql("INSERT INTO account_analytic_line_app (account_id, project_id, task_id, user_id, unit_amount, record_date, status, quadrant_id) VALUES (1, 101, 501, 10, 3.0, '2026-10-01', 'synced', 1)");
                // Instance 2, user 25 (Parvathy Nair): 5.0 hrs in Project 202
                tx.executeSql("INSERT INTO account_analytic_line_app (account_id, project_id, task_id, user_id, unit_amount, record_date, status, quadrant_id) VALUES (2, 202, 601, 25, 5.0, '2026-10-02', 'synced', 2)");
                // Instance 2, user 30 (Bob): 4.0 hrs in Project 202
                tx.executeSql("INSERT INTO account_analytic_line_app (account_id, project_id, task_id, user_id, unit_amount, record_date, status, quadrant_id) VALUES (2, 202, 601, 30, 4.0, '2026-10-02', 'synced', 1)");
            });

            // 1. Overview Pie Chart: getProjectSpentHoursList for All Accounts (-1) with user 10
            var pieProjects = Project.getProjectSpentHoursList(true, -1, "", "", 10);
            compare(pieProjects.length, 2);
            var totalSpent = 0;
            for (var p = 0; p < pieProjects.length; p++) {
                totalSpent += pieProjects[p].spentHours;
            }
            compare(totalSpent, 8.0); // 3.0 + 5.0

            // 2. Projects Bar Chart: Main.get_projects_spent_hours for All Accounts (-1) with user 10
            var barProjects = Main.get_projects_spent_hours(-1, "", "", 10);
            compare(barProjects.length, 2);
            var barTotal = 0;
            for (var b = 0; b < barProjects.length; b++) {
                barTotal += barProjects[b].total;
            }
            compare(barTotal, 8.0); // 3.0 + 5.0

            // 3. Tasks Tab Project Summary: Project.getDashboardProjectTaskSummary for All Accounts (-1) with user 10
            var summary = Project.getDashboardProjectTaskSummary(-1, "", "", 10);
            var summaryHours = 0;
            for (var s = 0; s < summary.length; s++) {
                summaryHours += summary[s].totalHours;
            }
            compare(summaryHours, 8.0); // 3.0 + 5.0

            // 4. Tasks Tab Drilldown: Task.getTasksForProject for Project 202 (Account 2) passing user 10
            // Even though user ID 10 is from Account 1, it should map to user 25 in Account 2
            var tasksForP2 = Task.getTasksForProject(202, 2, "", "", 10);
            compare(tasksForP2.length, 1);
            compare(tasksForP2[0].spent_hours, 5.0);

            // 5. Timesheet logs for task 601 (Account 2) passing user 10
            var logs = Timesheet.getTimesheetsForTask(601, 2, "all", "", "", 10);
            compare(logs.length, 1);
            compare(logs[0].spentHours, "5:00");
        }

        // --- 11. Multi-assignee Filter Tests ---
        function test_multiUserFilterSQL_emptyOrAllUsers() {
            var fEmpty = Account.buildUserFilterSQL([], 1, "a");
            compare(fEmpty.clause, "");
            compare(fEmpty.params.length, 0);

            var fAllArr = Account.buildUserFilterSQL([-1], 1, "a");
            compare(fAllArr.clause, "");
            compare(fAllArr.params.length, 0);

            var fAllObj = Account.buildUserFilterSQL([{ user_id: -1, account_id: -1 }], 1, "a");
            compare(fAllObj.clause, "");
            compare(fAllObj.params.length, 0);
        }

        function test_multiUserFilterSQL_singleAccountMultiSelect() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function(tx) {
                tx.executeSql("INSERT INTO users (id, name, link, database, username) VALUES (1, 'Acct 1', 'https://a1.com', 'db1', 'admin1')");
                tx.executeSql("INSERT INTO res_users_app (account_id, odoo_record_id, name, email, active) VALUES (1, 10, 'Alice', 'alice@test.com', 1)");
                tx.executeSql("INSERT INTO res_users_app (account_id, odoo_record_id, name, email, active) VALUES (1, 20, 'Bob', 'bob@test.com', 1)");
                tx.executeSql("INSERT INTO res_users_app (account_id, odoo_record_id, name, email, active) VALUES (1, 30, 'Charlie', 'charlie@test.com', 1)");

                tx.executeSql("INSERT INTO project_project_app (id, account_id, odoo_record_id, name) VALUES (1, 1, 101, 'Project 1')");
                tx.executeSql("INSERT INTO project_task_app (id, account_id, odoo_record_id, name, project_id) VALUES (1, 1, 501, 'Task 1', 101)");

                tx.executeSql("INSERT INTO account_analytic_line_app (account_id, project_id, task_id, user_id, unit_amount, record_date, status) VALUES (1, 101, 501, 10, 2.0, '2026-10-01', 'synced')");
                tx.executeSql("INSERT INTO account_analytic_line_app (account_id, project_id, task_id, user_id, unit_amount, record_date, status) VALUES (1, 101, 501, 20, 3.5, '2026-10-01', 'synced')");
                tx.executeSql("INSERT INTO account_analytic_line_app (account_id, project_id, task_id, user_id, unit_amount, record_date, status) VALUES (1, 101, 501, 30, 5.0, '2026-10-01', 'synced')");
            });

            // Filtering by Alice and Bob [10, 20]
            var filterSQL = Account.buildUserFilterSQL([10, 20], 1, "a");
            compare(filterSQL.clause, "a.user_id IN (?, ?)");
            compare(filterSQL.params.length, 2);

            // Verify Project.getProjectSpentHoursList filters for both Alice and Bob (2.0 + 3.5 = 5.5 hrs)
            var pieProjects = Project.getProjectSpentHoursList(true, 1, "", "", [10, 20]);
            compare(pieProjects.length, 1);
            compare(pieProjects[0].spentHours, 5.5);

            // Verify Main.get_projects_spent_hours
            var barProjects = Main.get_projects_spent_hours(1, "", "", [10, 20]);
            compare(barProjects.length, 1);
            compare(barProjects[0].total, 5.5);

            // Selection objects [{ user_id: 10, account_id: 1 }, { user_id: 20, account_id: 1 }]
            var pieObj = Project.getProjectSpentHoursList(true, 1, "", "", [{ user_id: 10, account_id: 1 }, { user_id: 20, account_id: 1 }]);
            compare(pieObj.length, 1);
            compare(pieObj[0].spentHours, 5.5);
        }

        function test_multiUserFilterSQL_allAccountsMultiSelect() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function(tx) {
                tx.executeSql("INSERT INTO users (id, name, link, database, username, is_default) VALUES (1, 'Instance 1', 'https://a1.com', 'db1', 'admin1', 1)");
                tx.executeSql("INSERT INTO users (id, name, link, database, username, is_default) VALUES (2, 'Instance 2', 'https://a2.com', 'db2', 'admin2', 0)");

                // Parvathy in both accounts (uid 10 in acc 1, uid 25 in acc 2)
                tx.executeSql("INSERT INTO res_users_app (account_id, odoo_record_id, name, email, active) VALUES (1, 10, 'Parvathy', 'p.nair@cit-services.eu', 1)");
                tx.executeSql("INSERT INTO res_users_app (account_id, odoo_record_id, name, email, active) VALUES (2, 25, 'Parvathy Nair', 'p.nair@cit-services.eu', 1)");
                // Bob only in account 2 (uid 30)
                tx.executeSql("INSERT INTO res_users_app (account_id, odoo_record_id, name, email, active) VALUES (2, 30, 'Bob Ross', 'bob@example.com', 1)");

                tx.executeSql("INSERT INTO project_project_app (id, account_id, odoo_record_id, name) VALUES (1, 1, 101, 'Project 1')");
                tx.executeSql("INSERT INTO project_project_app (id, account_id, odoo_record_id, name) VALUES (2, 2, 202, 'Project 2')");

                tx.executeSql("INSERT INTO project_task_app (id, account_id, odoo_record_id, name, project_id) VALUES (1, 1, 501, 'Task 1', 101)");
                tx.executeSql("INSERT INTO project_task_app (id, account_id, odoo_record_id, name, project_id) VALUES (2, 2, 601, 'Task 2', 202)");

                // Timesheets:
                // Parvathy: 3.0 in Project 1 (acc 1), 5.0 in Project 2 (acc 2)
                tx.executeSql("INSERT INTO account_analytic_line_app (account_id, project_id, task_id, user_id, unit_amount, record_date, status) VALUES (1, 101, 501, 10, 3.0, '2026-10-01', 'synced')");
                tx.executeSql("INSERT INTO account_analytic_line_app (account_id, project_id, task_id, user_id, unit_amount, record_date, status) VALUES (2, 202, 601, 25, 5.0, '2026-10-02', 'synced')");
                // Bob: 4.0 in Project 2 (acc 2)
                tx.executeSql("INSERT INTO account_analytic_line_app (account_id, project_id, task_id, user_id, unit_amount, record_date, status) VALUES (2, 202, 601, 30, 4.0, '2026-10-02', 'synced')");
            });

            // Multi-selecting Parvathy (10) and Bob (30) in All Accounts (-1)
            var multiFilter = Account.buildUserFilterSQL([10, 30], -1, "aal");
            verify(multiFilter.clause.length > 0);

            // Total spent across all accounts for Parvathy + Bob: 3.0 + 5.0 + 4.0 = 12.0 hrs
            var pieProjects = Project.getProjectSpentHoursList(true, -1, "", "", [10, 30]);
            var totalSpent = 0;
            for (var p = 0; p < pieProjects.length; p++) {
                totalSpent += pieProjects[p].spentHours;
            }
            compare(totalSpent, 12.0);

            // Bar chart: Main.get_projects_spent_hours
            var barProjects = Main.get_projects_spent_hours(-1, "", "", [10, 30]);
            var barTotal = 0;
            for (var b = 0; b < barProjects.length; b++) {
                barTotal += barProjects[b].total;
            }
            compare(barTotal, 12.0);

            // Project task summary: Project.getDashboardProjectTaskSummary
            var summary = Project.getDashboardProjectTaskSummary(-1, "", "", [10, 30]);
            var summaryHours = 0;
            for (var s = 0; s < summary.length; s++) {
                summaryHours += summary[s].totalHours;
            }
            compare(summaryHours, 12.0);
        }

        // --- 10. Dynamic Visibility: hasManagerOrAdminAccess ---
        function test_hasManagerOrAdminAccess_localAccount() {
            // Local Account (0) is single-user offline only - standard access
            compare(Account.hasManagerOrAdminAccess(0), false);
        }

        function test_hasManagerOrAdminAccess_standardEmployee() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function(tx) {
                // Account 1: Standard Employee
                tx.executeSql("INSERT INTO users (id, name, link, database, username) VALUES (1, 'Acct 1', 'https://a1.com', 'db1', 'employee@test.com')");
                tx.executeSql("INSERT INTO res_users_app (account_id, odoo_record_id, name, email, login, active) VALUES (1, 100, 'John Doe', 'employee@test.com', 'employee@test.com', 1)");
                // Project managed by someone else (user_id = 999)
                tx.executeSql("INSERT INTO project_project_app (id, account_id, odoo_record_id, name, user_id) VALUES (1, 1, 101, 'Project 1', 999)");
                // Timesheets only for self (user_id = 100)
                tx.executeSql("INSERT INTO account_analytic_line_app (account_id, project_id, task_id, user_id, unit_amount, record_date, status) VALUES (1, 101, 1, 100, 4.0, '2026-10-01', 'synced')");
            });

            // Standard access account: hide icon
            compare(Account.hasManagerOrAdminAccess(1), false);
        }

        function test_hasManagerOrAdminAccess_adminUsername() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function(tx) {
                tx.executeSql("INSERT INTO users (id, name, link, database, username) VALUES (2, 'Admin Acct', 'https://a2.com', 'db2', 'admin')");
                tx.executeSql("INSERT INTO res_users_app (account_id, odoo_record_id, name, email, login, active) VALUES (2, 2, 'Administrator', 'admin@test.com', 'admin', 1)");
            });

            // Admin account: show icon
            compare(Account.hasManagerOrAdminAccess(2), true);
        }

        function test_hasManagerOrAdminAccess_adminLogin() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function(tx) {
                // Username in users table is user's email, but res_users_app login is 'admin'
                tx.executeSql("INSERT INTO users (id, name, link, database, username) VALUES (3, 'Admin Acct 2', 'https://a3.com', 'db3', 'admin@corp.com')");
                tx.executeSql("INSERT INTO res_users_app (account_id, odoo_record_id, name, email, login, active) VALUES (3, 200, 'Corp Admin', 'admin@corp.com', 'admin', 1)");
            });

            compare(Account.hasManagerOrAdminAccess(3), true);
        }

        function test_hasManagerOrAdminAccess_adminUid2() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function(tx) {
                // Odoo default Administrator UID is 2
                tx.executeSql("INSERT INTO users (id, name, link, database, username) VALUES (4, 'Acct 4', 'https://a4.com', 'db4', 'odoo_super')");
                tx.executeSql("INSERT INTO res_users_app (account_id, odoo_record_id, name, email, login, active) VALUES (4, 2, 'Super User', 'super@test.com', 'odoo_super', 1)");
            });

            compare(Account.hasManagerOrAdminAccess(4), true);
        }

        function test_hasManagerOrAdminAccess_projectManager() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function(tx) {
                // Account 5: User is Project Manager of Project 1 (user_id = 50 matches odoo_record_id = 50)
                tx.executeSql("INSERT INTO users (id, name, link, database, username) VALUES (5, 'PM Acct', 'https://a5.com', 'db5', 'pm@test.com')");
                tx.executeSql("INSERT INTO res_users_app (account_id, odoo_record_id, name, email, login, active) VALUES (5, 50, 'PM User', 'pm@test.com', 'pm@test.com', 1)");
                tx.executeSql("INSERT INTO project_project_app (id, account_id, odoo_record_id, name, user_id) VALUES (1, 5, 201, 'Managed Project', 50)");
                // Only own timesheet
                tx.executeSql("INSERT INTO account_analytic_line_app (account_id, project_id, task_id, user_id, unit_amount, record_date, status) VALUES (5, 201, 1, 50, 2.0, '2026-10-01', 'synced')");
            });

            // Project Manager account: show icon
            compare(Account.hasManagerOrAdminAccess(5), true);
        }

        function test_hasManagerOrAdminAccess_teamTimesheetManager() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function(tx) {
                // Account 6: Lead with team timesheets
                tx.executeSql("INSERT INTO users (id, name, link, database, username) VALUES (6, 'Team Acct', 'https://a6.com', 'db6', 'lead@test.com')");
                tx.executeSql("INSERT INTO res_users_app (account_id, odoo_record_id, name, email, login, active) VALUES (6, 60, 'Team Lead', 'lead@test.com', 'lead@test.com', 1)");
                tx.executeSql("INSERT INTO res_users_app (account_id, odoo_record_id, name, email, login, active) VALUES (6, 70, 'Subordinate', 'sub@test.com', 'sub@test.com', 1)");
                // Project not managed by lead
                tx.executeSql("INSERT INTO project_project_app (id, account_id, odoo_record_id, name, user_id) VALUES (1, 6, 301, 'Team Project', 999)");
                // Timesheets for multiple employees (lead 60 + subordinate 70)
                tx.executeSql("INSERT INTO account_analytic_line_app (account_id, project_id, task_id, user_id, unit_amount, record_date, status) VALUES (6, 301, 1, 60, 3.0, '2026-10-01', 'synced')");
                tx.executeSql("INSERT INTO account_analytic_line_app (account_id, project_id, task_id, user_id, unit_amount, record_date, status) VALUES (6, 301, 1, 70, 5.0, '2026-10-01', 'synced')");
            });

            // Team manager with multiple employees' timesheets: show icon
            compare(Account.hasManagerOrAdminAccess(6), true);
        }

        function test_hasManagerOrAdminAccess_allAccounts() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function(tx) {
                // Standard Account 1
                tx.executeSql("INSERT INTO users (id, name, link, database, username) VALUES (1, 'Standard 1', 'https://a1.com', 'db1', 'u1@test.com')");
                tx.executeSql("INSERT INTO res_users_app (account_id, odoo_record_id, name, login, active) VALUES (1, 10, 'User 1', 'u1@test.com', 1)");
                tx.executeSql("INSERT INTO project_project_app (id, account_id, odoo_record_id, name, user_id) VALUES (1, 1, 101, 'Proj 1', 999)");
                tx.executeSql("INSERT INTO account_analytic_line_app (account_id, project_id, task_id, user_id, unit_amount, record_date, status) VALUES (1, 101, 1, 10, 2.0, '2026-10-01', 'synced')");

                // Standard Account 2
                tx.executeSql("INSERT INTO users (id, name, link, database, username) VALUES (2, 'Standard 2', 'https://a2.com', 'db2', 'u2@test.com')");
                tx.executeSql("INSERT INTO res_users_app (account_id, odoo_record_id, name, login, active) VALUES (2, 20, 'User 2', 'u2@test.com', 1)");
                tx.executeSql("INSERT INTO project_project_app (id, account_id, odoo_record_id, name, user_id) VALUES (2, 2, 201, 'Proj 2', 999)");
                tx.executeSql("INSERT INTO account_analytic_line_app (account_id, project_id, task_id, user_id, unit_amount, record_date, status) VALUES (2, 201, 1, 20, 3.0, '2026-10-01', 'synced')");
            });

            // When all accounts only grant standard access: hide icon
            compare(Account.hasManagerOrAdminAccess(-1), false);

            // Now add an Admin account (Account 3)
            db.transaction(function(tx) {
                tx.executeSql("INSERT INTO users (id, name, link, database, username) VALUES (3, 'Admin Acct', 'https://a3.com', 'db3', 'admin')");
            });

            // When at least one instance account grants manager/admin access: show icon
            compare(Account.hasManagerOrAdminAccess(-1), true);
        }

        function test_accountSwitching_togglesManagerAccess() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function(tx) {
                // Account A (ID 10): Standard Employee
                tx.executeSql("INSERT INTO users (id, name, link, database, username) VALUES (10, 'Instance A', 'https://a.com', 'dbA', 'user@company.com')");
                tx.executeSql("INSERT INTO res_users_app (account_id, odoo_record_id, name, login, active) VALUES (10, 101, 'User A', 'user@company.com', 1)");
                tx.executeSql("INSERT INTO project_project_app (id, account_id, odoo_record_id, name, user_id) VALUES (1, 10, 501, 'Proj A', 999)");
                tx.executeSql("INSERT INTO account_analytic_line_app (account_id, project_id, task_id, user_id, unit_amount, record_date, status) VALUES (10, 501, 1, 101, 3.0, '2026-10-01', 'synced')");

                // Account B (ID 20): Project Manager
                tx.executeSql("INSERT INTO users (id, name, link, database, username) VALUES (20, 'Instance B', 'https://b.com', 'dbB', 'user@company.com')");
                tx.executeSql("INSERT INTO res_users_app (account_id, odoo_record_id, name, login, active) VALUES (20, 202, 'User B', 'user@company.com', 1)");
                tx.executeSql("INSERT INTO project_project_app (id, account_id, odoo_record_id, name, user_id) VALUES (2, 20, 601, 'Proj B', 202)");
                tx.executeSql("INSERT INTO account_analytic_line_app (account_id, project_id, task_id, user_id, unit_amount, record_date, status) VALUES (20, 601, 1, 202, 5.0, '2026-10-01', 'synced')");
            });

            // 1. Initial Account A (Standard Access): Icon hidden
            var activeAccountId = 10;
            var isVisible = Account.hasManagerOrAdminAccess(activeAccountId);
            compare(isVisible, false);

            // 2. User toggles to Account B (Project Manager Access): Icon visible
            activeAccountId = 20;
            isVisible = Account.hasManagerOrAdminAccess(activeAccountId);
            compare(isVisible, true);

            // 3. User toggles back to Account A (Standard Access): Icon hidden
            activeAccountId = 10;
            isVisible = Account.hasManagerOrAdminAccess(activeAccountId);
            compare(isVisible, false);

            // 4. User toggles to Local Account (0): Icon hidden
            activeAccountId = 0;
            isVisible = Account.hasManagerOrAdminAccess(activeAccountId);
            compare(isVisible, false);

            // 5. User toggles to All Accounts (-1): Icon visible because Account B is PM
            activeAccountId = -1;
            isVisible = Account.hasManagerOrAdminAccess(activeAccountId);
            compare(isVisible, true);
        }
    }
}
