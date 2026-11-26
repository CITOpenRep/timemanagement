import QtQuick 2.7
import QtTest 1.0
import QtQuick.LocalStorage 2.7 as Sql
import "../../../models/database.js" as DBCommon
import "../../../models/dbinit.js" as DbInit
import "../../../models/task.js" as TaskModel
import "../../../models/timesheet.js" as TimesheetModel
import "../../../models/activity.js" as ActivityModel
import "../../../models/project.js" as ProjectModel

Item {
    width: 200
    height: 200

    TestCase {
        name: "SyncQueueModelTests"
        when: windowShown

        function initTestCase() {
            DbInit.initializeDatabase();
        }

        function cleanup() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function(tx) {
                tx.executeSql("DELETE FROM sync_queue");
                tx.executeSql("DELETE FROM project_task_app WHERE account_id = 777");
                tx.executeSql("DELETE FROM account_analytic_line_app WHERE account_id = 777");
                tx.executeSql("DELETE FROM mail_activity_app WHERE account_id = 777");
                tx.executeSql("DELETE FROM project_project_app WHERE account_id = 777");
                tx.executeSql("DELETE FROM project_update_app WHERE account_id = 777");
                tx.executeSql("DELETE FROM users WHERE id = 777");
            });
        }

        function seedRemoteAccount() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function(tx) {
                tx.executeSql(
                    "INSERT OR REPLACE INTO users (id, name, link, database, username, api_key) VALUES (777, 'RemoteTest', 'https://odoo.test', 'db', 'u', 'k')"
                );
            });
        }

        function test_computeDirtyFields_normalizesEmptyAndChanged() {
            var oldRow = {
                name: "Task A",
                description: null,
                priority: "1",
                state: 5,
                deadline: "2026-11-30"
            };
            var newVals = {
                name: "Task A",
                description: "",
                priority: 1,
                state: 6,
                deadline: ""
            };
            var dirty = DBCommon.computeDirtyFields(oldRow, newVals);
            verify(dirty.indexOf("name") === -1);
            verify(dirty.indexOf("description") === -1);
            verify(dirty.indexOf("priority") === -1);
            verify(dirty.indexOf("state") !== -1);
            verify(dirty.indexOf("deadline") !== -1);
        }

        function test_saveOrUpdateTask_tracksDirtyFieldsAndCoalescesQueue() {
            seedRemoteAccount();
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            var taskId = 0;

            db.transaction(function(tx) {
                tx.executeSql(
                    "INSERT INTO project_task_app (account_id, name, project_id, priority, description, state, odoo_record_id, base_write_date, status, mutation_seq) " +
                    "VALUES (777, 'Synced Task', 10, '0', 'Initial desc', 1, 9001, '2026-11-26 10:00:00', '', 0)"
                );
                taskId = tx.executeSql("SELECT last_insert_rowid() as id").rows.item(0).id;
            });

            // Edit ONLY description via saveOrUpdateTask
            var res = TaskModel.saveOrUpdateTask({
                record_id: taskId,
                accountId: 777,
                name: "Synced Task",
                projectId: 10,
                parentId: 0,
                plannedHours: 0,
                priority: "0",
                description: "Edited desc",
                assigneeUserId: null,
                subProjectId: null,
                startDate: null,
                endDate: null,
                deadline: null,
                stageOdooRecordId: 1,
                personalStageOdooRecordId: null,
                status: "updated"
            });
            verify(res.success);

            // Follow up with priority change
            TaskModel.setTaskPriority(taskId, "3", "updated");

            db.transaction(function(tx) {
                var qRs = tx.executeSql(
                    "SELECT operation, dirty_fields, base_write_date, queued_seq, status FROM sync_queue WHERE account_id = 777 AND model_name = 'project.task' AND local_id = ?",
                    [taskId]
                );
                compare(qRs.rows.length, 1);
                compare(qRs.rows.item(0).operation, "upsert");
                compare(qRs.rows.item(0).base_write_date, "2026-11-26 10:00:00");
                compare(qRs.rows.item(0).queued_seq, 2);
                compare(qRs.rows.item(0).status, "pending");

                var dirtyParsed = JSON.parse(qRs.rows.item(0).dirty_fields);
                var dirty = Array.isArray(dirtyParsed) ? dirtyParsed : dirtyParsed.fields;
                verify(dirty.indexOf("description") !== -1);
                verify(dirty.indexOf("priority") !== -1);
                verify(dirty.indexOf("name") === -1);
                verify(dirtyParsed.base !== undefined);
                compare(dirtyParsed.base.description, "Initial desc");
            });
        }

        function test_localAccountAndDraftTimersNeverEnqueue() {
            seedRemoteAccount();
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

            // Local account task must NOT enqueue
            var localRes = TaskModel.saveOrUpdateTask({
                accountId: 0,
                name: "Personal Local Task",
                projectId: 1,
                parentId: 0,
                plannedHours: 0,
                priority: "0",
                description: "",
                assigneeUserId: null,
                subProjectId: null,
                startDate: null,
                endDate: null,
                deadline: null,
                stageOdooRecordId: -1,
                status: "saved"
            });
            verify(localRes.success);

            // Draft timer on remote account must NOT enqueue
            var tsCreate = TimesheetModel.createTimesheet(777, 1);
            verify(tsCreate.success);
            TimesheetModel.saveTimesheet({
                id: tsCreate.id,
                instance_id: 777,
                project: 10,
                task: 20,
                description: "Draft work",
                unit_amount: 0.5,
                status: "draft"
            });

            db.transaction(function(tx) {
                var cnt = tx.executeSql("SELECT COUNT(*) as c FROM sync_queue").rows.item(0).c;
                compare(cnt, 0);
            });
        }

        function test_deleteUnsyncedDropsQueueAndDeleteSyncedEnqueuesUnlink() {
            seedRemoteAccount();
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

            // Unsynced task: create then delete -> queue entry removed cleanly
            var unsynced = TaskModel.saveOrUpdateTask({
                accountId: 777,
                name: "Temp Task",
                projectId: 10,
                parentId: 0,
                plannedHours: 0,
                priority: "0",
                description: "",
                assigneeUserId: null,
                subProjectId: null,
                startDate: null,
                endDate: null,
                deadline: null,
                stageOdooRecordId: null,
                status: "updated"
            });
            verify(unsynced.success);
            TaskModel.markTaskAsDeleted(unsynced.taskId, true);

            // Synced update -> mark deleted -> enqueues delete operation
            var updId = 0;
            db.transaction(function(tx) {
                tx.executeSql(
                    "INSERT INTO project_update_app (account_id, project_id, name, odoo_record_id, status) VALUES (777, 10, 'Synced Update', 404, '')"
                );
                updId = tx.executeSql("SELECT last_insert_rowid() as id").rows.item(0).id;
            });
            ProjectModel.markProjectUpdateAsDeleted(updId);

            db.transaction(function(tx) {
                var taskQueue = tx.executeSql("SELECT COUNT(*) as c FROM sync_queue WHERE model_name = 'project.task' AND local_id = ?", [unsynced.taskId]).rows.item(0).c;
                compare(taskQueue, 0);

                var updQueue = tx.executeSql("SELECT operation, odoo_record_id FROM sync_queue WHERE model_name = 'project.update' AND local_id = ?", [updId]);
                compare(updQueue.rows.length, 1);
                compare(updQueue.rows.item(0).operation, "delete");
                compare(updQueue.rows.item(0).odoo_record_id, 404);
            });
        }

        function test_activityDoneAndProjectFavoriteEnqueueSpecialOperations() {
            seedRemoteAccount();
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            var actId = 0;
            var projId = 0;

            db.transaction(function(tx) {
                tx.executeSql(
                    "INSERT INTO mail_activity_app (account_id, summary, state, odoo_record_id, status) VALUES (777, 'Call', 'planned', 601, '')"
                );
                actId = tx.executeSql("SELECT last_insert_rowid() as id").rows.item(0).id;

                tx.executeSql(
                    "INSERT INTO project_project_app (account_id, name, favorites, odoo_record_id, status) VALUES (777, 'Proj', 0, 701, '')"
                );
                projId = tx.executeSql("SELECT last_insert_rowid() as id").rows.item(0).id;
            });

            ActivityModel.markAsDone(777, actId);
            ProjectModel.toggleProjectFavorite(projId, true, "updated");

            db.transaction(function(tx) {
                var actQ = tx.executeSql("SELECT operation, dirty_fields FROM sync_queue WHERE model_name = 'mail.activity' AND local_id = ?", [actId]);
                compare(actQ.rows.item(0).operation, "action_done");

                var projQ = tx.executeSql("SELECT operation, dirty_fields FROM sync_queue WHERE model_name = 'project.project' AND local_id = ?", [projId]);
                compare(projQ.rows.item(0).operation, "favorite");
                compare(JSON.parse(projQ.rows.item(0).dirty_fields)[0], "favorites");
            });
        }
    }
}
