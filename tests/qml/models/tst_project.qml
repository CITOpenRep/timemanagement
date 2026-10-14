import QtQuick 2.7
import QtTest 1.0
import QtQuick.LocalStorage 2.7 as Sql
import "../../../models/logger.js" as Logger
import "../../../models/database.js" as DBCommon
import "../../../models/dbinit.js" as DbInit
import "../../../models/utils.js" as Utils
import "../../../models/project.js" as ProjectModel

Item {
    width: 200
    height: 200

    TestCase {
        name: "ProjectModelTests"
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
                tx.executeSql("DELETE FROM project_project_app WHERE account_id = 999 OR id >= 90000");
                tx.executeSql("DELETE FROM project_update_app WHERE account_id = 999 OR id >= 90000");
                tx.executeSql("DELETE FROM dl_cache_app WHERE record_id >= 90000");
            });
        }

        function init() {
            clearTestData();
        }

        function cleanup() {
            clearTestData();
        }

        // --- 1. Cache Functions ---

        function test_cacheOperations() {
            compare(ProjectModel.isPresentInCache(90001), false);
            compare(ProjectModel.getFromCache(90001), null);

            ProjectModel.putInCache(90001, "SGVsbG8gV29ybGQ="); // base64
            compare(ProjectModel.isPresentInCache(90001), true);
            compare(ProjectModel.getFromCache(90001), "SGVsbG8gV29ybGQ=");

            ProjectModel.putInCache(90002, "VXBkYXRlZA==");
            compare(ProjectModel.isPresentInCache(90002), true);
            compare(ProjectModel.getFromCache(90002), "VXBkYXRlZA==");
        }

        // --- 2. ID Mapping and Details ---

        function test_getLocalIdFromOdooId() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function (tx) {
                tx.executeSql(
                    "INSERT INTO project_project_app (id, odoo_record_id, name, account_id) VALUES (?, ?, ?, ?)",
                    [90010, 44444, "Mapped Project", 999]
                );
            });

            compare(ProjectModel.getLocalIdFromOdooId(44444, 999), 90010);
            compare(ProjectModel.getLocalIdFromOdooId(99999, 999), -1);
        }

        function test_getProjectName_and_getProjectDetails() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function (tx) {
                tx.executeSql(
                    "INSERT INTO project_project_app (id, odoo_record_id, name, account_id, description, favorites, color_pallet) " +
                    "VALUES (?, ?, ?, ?, ?, ?, ?)",
                    [90020, 55555, "Alpha Project", 999, "A detailed project", 0, "#FF0000"]
                );
            });

            var name = ProjectModel.getProjectName(90020, 999);
            compare(name, "Alpha Project");

            var details = ProjectModel.getProjectDetails(90020);
            verify(details !== null);
            compare(details.id, 90020);
            compare(details.name, "Alpha Project");
            compare(details.account_id, 999);
            compare(details.description, "A detailed project");
            compare(details.color_pallet, "#FF0000");
        }

        // --- 3. Project Creation, Updating, and Favorites ---

        function test_createUpdateProject() {
            var newProject = {
                account_id: 999,
                name: "Created Project",
                parent_id: 0,
                planned_start_date: "2026-10-13",
                planned_end_date: "2026-10-20",
                allocated_hours: "10:00",
                favorites: 0,
                description: "Test description",
                color: "#00FF00",
                stage: 1,
                status: "normal"
            };

            var createRes = ProjectModel.createUpdateProject(newProject, 0);
            verify(createRes.is_success);
            var projectId = createRes.record_id;
            verify(projectId > 0);

            var details = ProjectModel.getProjectDetails(projectId);
            compare(details.name, "Created Project");
            compare(details.account_id, 999);
            compare(details.color_pallet, "#00FF00");

            // Update project
            newProject.name = "Updated Project Name";
            newProject.favorites = 1;
            var updateRes = ProjectModel.createUpdateProject(newProject, projectId);
            verify(updateRes.is_success);

            var updatedDetails = ProjectModel.getProjectDetails(projectId);
            compare(updatedDetails.name, "Updated Project Name");
            compare(updatedDetails.favorites, 1);
        }

        function test_toggleProjectFavorite() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function (tx) {
                tx.executeSql(
                    "INSERT INTO project_project_app (id, odoo_record_id, name, account_id, favorites, status) VALUES (?, ?, ?, ?, ?, ?)",
                    [90030, 90030, "Favorite Test Project", 999, 0, "normal"]
                );
            });

            var resFav = ProjectModel.toggleProjectFavorite(90030, true, "updated");
            verify(resFav.success);
            var d1 = ProjectModel.getProjectDetails(90030);
            compare(d1.favorites, 1);
            compare(d1.status, "updated");

            var resUnfav = ProjectModel.toggleProjectFavorite(90030, false, "updated");
            verify(resUnfav.success);
            var d2 = ProjectModel.getProjectDetails(90030);
            compare(d2.favorites, 0);
        }

        // --- 4. Project Updates / Snapshots ---

        function test_projectUpdatesCRUD() {
            var updateData = {
                project_id: 90020,
                name: "Weekly Status Update",
                project_status: "on_track",
                progress: 50,
                description: "Halfway completed milestones",
                account_id: 999,
                user_id: 10
            };

            var res = ProjectModel.createUpdateSnapShot(updateData, 0);
            verify(res.is_success);
            var updateId = res.record_id;
            verify(updateId > 0);

            var updates = ProjectModel.getAllProjectUpdates(999);
            verify(updates.length > 0);

            var delRes = ProjectModel.markProjectUpdateAsDeleted(updateId);
            verify(delRes.success);
        }

        // --- 5. Project Listing ---

        function test_getProjectsForAccount() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function (tx) {
                tx.executeSql(
                    "INSERT INTO project_project_app (id, odoo_record_id, name, account_id, status) VALUES (?, ?, ?, ?, ?)",
                    [90041, 90041, "Account Project 1", 999, "normal"]
                );
                tx.executeSql(
                    "INSERT INTO project_project_app (id, odoo_record_id, name, account_id, status) VALUES (?, ?, ?, ?, ?)",
                    [90042, 90042, "Account Project 2", 999, "normal"]
                );
            });

            var projects = ProjectModel.getProjectsForAccount(999);
            compare(projects.length, 2);
        }
    }
}
