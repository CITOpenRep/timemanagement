import QtQuick 2.7
import QtTest 1.0
import QtQuick.LocalStorage 2.7 as Sql
import "../../../models/logger.js" as Logger
import "../../../models/database.js" as DBCommon
import "../../../models/dbinit.js" as DbInit
import "../../../models/draft_manager.js" as DraftManager

Item {
    width: 200
    height: 200

    TestCase {
        name: "DraftManagerTests"
        when: windowShown

        function initTestCase() {
            Logger.setLogLevel(Logger.LogLevel.NONE);
            DbInit.initializeDatabase();
        }

        function cleanupTestCase() {
            Logger.setLogLevel(Logger.LogLevel.WARN);
        }

        function init() {
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function(tx) {
                tx.executeSql("DELETE FROM form_drafts");
            });
        }

        function test_saveDraftValidation() {
            var res = DraftManager.saveDraft({});
            verify(!res.success);
            compare(res.error, "draftType is required");
        }

        function test_valuesAreEqualPrimitives() {
            verify(DraftManager.valuesAreEqual(10, 10));
            verify(!DraftManager.valuesAreEqual(10, 20));

            verify(DraftManager.valuesAreEqual("hello", "hello"));
            verify(!DraftManager.valuesAreEqual("hello", "world"));

            verify(DraftManager.valuesAreEqual(true, true));
            verify(!DraftManager.valuesAreEqual(true, false));

            verify(DraftManager.valuesAreEqual(null, null));
            verify(DraftManager.valuesAreEqual(undefined, undefined));
            verify(DraftManager.valuesAreEqual(null, undefined));
            verify(DraftManager.valuesAreEqual(null, ""));
            verify(DraftManager.valuesAreEqual(undefined, ""));
        }

        function test_valuesAreEqualArrays() {
            verify(DraftManager.valuesAreEqual([1, 2, 3], [1, 2, 3]));
            verify(!DraftManager.valuesAreEqual([1, 2, 3], [1, 2]));
            verify(!DraftManager.valuesAreEqual([1, 2, 3], [1, 2, 4]));
            verify(DraftManager.valuesAreEqual([], []));
        }

        function test_valuesAreEqualObjects() {
            verify(DraftManager.valuesAreEqual({a: 1, b: "test"}, {a: 1, b: "test"}));
            verify(!DraftManager.valuesAreEqual({a: 1, b: "test"}, {a: 1, b: "other"}));
            verify(!DraftManager.valuesAreEqual({a: 1}, {a: 1, b: 2}));
        }

        function test_getChangedFields() {
            var original = { title: "Original Title", priority: 1, description: "Desc" };
            var modified = { title: "New Title", priority: 1, description: "Updated Desc" };

            var changed = DraftManager.getChangedFields(modified, original);
            verify(changed !== null);
            compare(changed.length, 2);
            verify(changed.indexOf("title") !== -1);
            verify(changed.indexOf("description") !== -1);
            verify(changed.indexOf("priority") === -1);
        }

        function test_hasUnsavedChanges() {
            var original = { name: "Task A", hours: 2.5 };
            var same = { name: "Task A", hours: 2.5 };
            var changed = { name: "Task B", hours: 2.5 };

            verify(!DraftManager.hasUnsavedChanges(same, original));
            verify(DraftManager.hasUnsavedChanges(changed, original));
        }

        function test_saveAndLoadDraft() {
            var saveParams = {
                draftType: "task",
                recordId: 501,
                accountId: 0,
                pageIdentifier: "task_edit_page",
                formData: { name: "My Draft Task", priority: 3 },
                originalData: { name: "Original Task", priority: 1 }
            };

            var saveRes = DraftManager.saveDraft(saveParams);
            verify(saveRes.success);
            verify(saveRes.hasChanges);
            verify(saveRes.draftId > 0);

            var loadParams = {
                draftType: "task",
                recordId: 501,
                accountId: 0,
                pageIdentifier: "task_edit_page"
            };

            var loaded = DraftManager.loadDraft(loadParams);
            verify(loaded !== null);
            compare(loaded.draft_type, "task");
            compare(loaded.record_id, 501);

            var parsedData = typeof loaded.draft_data === "string" ? JSON.parse(loaded.draft_data) : loaded.draft_data;
            compare(parsedData.name, "My Draft Task");
            compare(parsedData.priority, 3);
        }

        function test_deleteDraftById() {
            var saveParams = {
                draftType: "timesheet",
                recordId: 601,
                accountId: 0,
                formData: { unit_amount: 4.0 },
                originalData: { unit_amount: 1.0 }
            };

            var saveRes = DraftManager.saveDraft(saveParams);
            verify(saveRes.success);
            var draftId = saveRes.draftId;

            var deleteRes = DraftManager.deleteDraft(draftId);
            verify(deleteRes);

            var loaded = DraftManager.loadDraft({
                draftType: "timesheet",
                recordId: 601,
                accountId: 0
            });
            compare(loaded, null);
        }

        function test_deleteDraftsByParams() {
            DraftManager.saveDraft({
                draftType: "project",
                recordId: 701,
                accountId: 0,
                formData: { name: "Project Draft 1" },
                originalData: { name: "Old" }
            });

            DraftManager.saveDraft({
                draftType: "project",
                recordId: 702,
                accountId: 0,
                formData: { name: "Project Draft 2" },
                originalData: { name: "Old" }
            });

            var countBefore = DraftManager.getAllDrafts(0).length;
            compare(countBefore, 2);

            var delRes = DraftManager.deleteDrafts({
                draftType: "project",
                recordId: 701,
                accountId: 0
            });
            verify(delRes);

            var countAfter = DraftManager.getAllDrafts(0).length;
            compare(countAfter, 1);
        }

        function test_getDraftsSummary() {
            DraftManager.saveDraft({
                draftType: "task",
                recordId: 801,
                accountId: 0,
                formData: { name: "Task 1" },
                originalData: {}
            });

            DraftManager.saveDraft({
                draftType: "timesheet",
                recordId: 802,
                accountId: 0,
                formData: { hours: 5 },
                originalData: {}
            });

            var summary = DraftManager.getDraftsSummary(0);
            verify(summary !== null);
            compare(summary.total, 2);
            compare(summary.byType.task, 1);
            compare(summary.byType.timesheet, 1);
        }
    }
}
