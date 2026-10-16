import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import QtQuick.LocalStorage 2.0 as Sql
import "../../qml/features/tasks/components"
import "../../models/dbinit.js" as DbInit
import "../../models/database.js" as DBCommon

MainView {
    id: testRoot
    width: units.gu(40)
    height: units.gu(70)

    PersonalStageSelector {
        id: testSelector
    }

    SignalSpy {
        id: personalStageSelectedSpy
        target: testSelector
        signalName: "personalStageSelected"
    }

    TestCase {
        name: "PersonalStageSelectorTests"
        when: windowShown

        function initTestCase() {
            DbInit.initializeDatabase();
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function (tx) {
                tx.executeSql("DELETE FROM project_task_type_app WHERE account_id = 9991");
                tx.executeSql("INSERT INTO project_task_type_app (account_id, odoo_record_id, name, sequence, active, fold, user_id, is_global) VALUES (?, ?, ?, ?, ?, ?, ?, ?)", [9991, 501, "Inbox", 1, 1, 0, 77, "[]"]);
                tx.executeSql("INSERT INTO project_task_type_app (account_id, odoo_record_id, name, sequence, active, fold, user_id, is_global) VALUES (?, ?, ?, ?, ?, ?, ?, ?)", [9991, 502, "Today", 2, 1, 0, 77, "[]"]);
                tx.executeSql("INSERT INTO project_task_type_app (account_id, odoo_record_id, name, sequence, active, fold, user_id, is_global) VALUES (?, ?, ?, ?, ?, ?, ?, ?)", [9991, 503, "Done Personal", 3, 1, 1, 77, "[]"]);
            });
        }

        function cleanupTestCase() {
            try {
                var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
                db.transaction(function (tx) {
                    tx.executeSql("DELETE FROM project_task_type_app WHERE account_id = 9991");
                });
            } catch (e) {
                console.log("Cleanup error: " + e);
            }
        }

        function init() {
            testSelector.taskId = -1;
            testSelector.accountId = -1;
            testSelector.userId = -1;
            testSelector.currentPersonalStageOdooRecordId = -1;
            testSelector.availablePersonalStages = [];
            personalStageSelectedSpy.clear();
        }

        function cleanup() {
            personalStageSelectedSpy.clear();
        }

        function test_initialProperties() {
            compare(testSelector.title, "Change Personal Stage");
            compare(testSelector.taskId, -1);
            compare(testSelector.accountId, -1);
            compare(testSelector.userId, -1);
            compare(testSelector.currentPersonalStageOdooRecordId, -1);
            compare(personalStageSelectedSpy.count, 0);
        }

        function test_propertyAssignments() {
            testSelector.taskId = 12;
            testSelector.accountId = 9991;
            testSelector.userId = 77;
            testSelector.currentPersonalStageOdooRecordId = 502;

            compare(testSelector.taskId, 12);
            compare(testSelector.accountId, 9991);
            compare(testSelector.userId, 77);
            compare(testSelector.currentPersonalStageOdooRecordId, 502);
        }

        function test_loadPersonalStagesForUser() {
            testSelector.accountId = 9991;
            testSelector.userId = 77;
            testSelector.currentPersonalStageOdooRecordId = 501;
            testSelector.loadPersonalStages();

            compare(testSelector.availablePersonalStages.length, 3);
            compare(testSelector.availablePersonalStages[0].odoo_record_id, 501);
            compare(testSelector.availablePersonalStages[0].name, "Inbox");
            compare(testSelector.availablePersonalStages[0].fold, 0);

            compare(testSelector.availablePersonalStages[1].odoo_record_id, 502);
            compare(testSelector.availablePersonalStages[1].name, "Today");

            compare(testSelector.availablePersonalStages[2].odoo_record_id, 503);
            compare(testSelector.availablePersonalStages[2].name, "Done Personal");
            compare(testSelector.availablePersonalStages[2].fold, 1);
        }

        function test_loadPersonalStagesForNonExistentUser() {
            testSelector.accountId = 9991;
            testSelector.userId = 99999;
            testSelector.loadPersonalStages();
            compare(testSelector.availablePersonalStages.length, 0);
        }

        function test_personalStageSelectedSignalEmission() {
            compare(personalStageSelectedSpy.count, 0);
            testSelector.personalStageSelected(502, "Today");
            compare(personalStageSelectedSpy.count, 1);
            compare(personalStageSelectedSpy.signalArguments[0][0], 502);
            compare(personalStageSelectedSpy.signalArguments[0][1], "Today");
        }

        function test_clearPersonalStageSignalEmission() {
            testSelector.personalStageSelected(null, "(Clear Personal Stage)");
            compare(personalStageSelectedSpy.count, 1);
            compare(personalStageSelectedSpy.signalArguments[0][0], 0);
            compare(personalStageSelectedSpy.signalArguments[0][1], "(Clear Personal Stage)");
        }
    }
}
