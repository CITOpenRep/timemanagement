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

    TaskStageSelector {
        id: testStageSelector
    }

    SignalSpy {
        id: stageSelectedSpy
        target: testStageSelector
        signalName: "stageSelected"
    }

    TestCase {
        name: "TaskStageSelectorTests"
        when: windowShown

        function initTestCase() {
            DbInit.initializeDatabase();
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function (tx) {
                tx.executeSql("DELETE FROM project_task_type_app WHERE account_id = 9992");
                tx.executeSql("INSERT INTO project_task_type_app (account_id, odoo_record_id, name, sequence, active, fold, is_global, description) VALUES (?, ?, ?, ?, ?, ?, ?, ?)", [9992, 601, "New", 1, 1, 0, "1", "New tasks"]);
                tx.executeSql("INSERT INTO project_task_type_app (account_id, odoo_record_id, name, sequence, active, fold, is_global, description) VALUES (?, ?, ?, ?, ?, ?, ?, ?)", [9992, 602, "In Progress", 2, 1, 0, "1", "Under active development"]);
                tx.executeSql("INSERT INTO project_task_type_app (account_id, odoo_record_id, name, sequence, active, fold, is_global, description) VALUES (?, ?, ?, ?, ?, ?, ?, ?)", [9992, 603, "Done", 3, 1, 1, "1", "Completed tasks"]);
            });
        }

        function cleanupTestCase() {
            try {
                var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
                db.transaction(function (tx) {
                    tx.executeSql("DELETE FROM project_task_type_app WHERE account_id = 9992");
                });
            } catch (e) {
                console.log("Cleanup error: " + e);
            }
        }

        function init() {
            testStageSelector.taskId = -1;
            testStageSelector.projectOdooRecordId = -1;
            testStageSelector.accountId = -1;
            testStageSelector.currentStageOdooRecordId = -1;
            testStageSelector.availableStages = [];
            stageSelectedSpy.clear();
        }

        function cleanup() {
            stageSelectedSpy.clear();
        }

        function test_initialProperties() {
            compare(testStageSelector.title, "Change Task Stage");
            compare(testStageSelector.taskId, -1);
            compare(testStageSelector.projectOdooRecordId, -1);
            compare(testStageSelector.accountId, -1);
            compare(testStageSelector.currentStageOdooRecordId, -1);
            compare(stageSelectedSpy.count, 0);
        }

        function test_propertyAssignments() {
            testStageSelector.taskId = 100;
            testStageSelector.projectOdooRecordId = 200;
            testStageSelector.accountId = 9992;
            testStageSelector.currentStageOdooRecordId = 601;

            compare(testStageSelector.taskId, 100);
            compare(testStageSelector.projectOdooRecordId, 200);
            compare(testStageSelector.accountId, 9992);
            compare(testStageSelector.currentStageOdooRecordId, 601);
        }

        function test_loadStagesForProject() {
            testStageSelector.projectOdooRecordId = 200;
            testStageSelector.accountId = 9992;
            testStageSelector.currentStageOdooRecordId = 601;
            testStageSelector.loadStages();

            compare(testStageSelector.availableStages.length, 3);
            compare(testStageSelector.availableStages[0].odoo_record_id, 601);
            compare(testStageSelector.availableStages[0].name, "New");
            compare(testStageSelector.availableStages[0].fold, 0);

            compare(testStageSelector.availableStages[1].odoo_record_id, 602);
            compare(testStageSelector.availableStages[1].name, "In Progress");

            compare(testStageSelector.availableStages[2].odoo_record_id, 603);
            compare(testStageSelector.availableStages[2].name, "Done");
            compare(testStageSelector.availableStages[2].fold, 1);
        }

        function test_loadStagesEmptyAccount() {
            testStageSelector.projectOdooRecordId = 200;
            testStageSelector.accountId = 77777;
            testStageSelector.loadStages();
            compare(testStageSelector.availableStages.length, 0);
        }

        function test_stageSelectedSignalEmission() {
            compare(stageSelectedSpy.count, 0);
            testStageSelector.stageSelected(603, "Done");
            compare(stageSelectedSpy.count, 1);
            compare(stageSelectedSpy.signalArguments[0][0], 603);
            compare(stageSelectedSpy.signalArguments[0][1], "Done");
        }

        function test_stageSelectedMultipleTransitions() {
            testStageSelector.stageSelected(601, "New");
            testStageSelector.stageSelected(602, "In Progress");
            testStageSelector.stageSelected(603, "Done");

            compare(stageSelectedSpy.count, 3);
            compare(stageSelectedSpy.signalArguments[0][0], 601);
            compare(stageSelectedSpy.signalArguments[0][1], "New");
            compare(stageSelectedSpy.signalArguments[1][0], 602);
            compare(stageSelectedSpy.signalArguments[1][1], "In Progress");
            compare(stageSelectedSpy.signalArguments[2][0], 603);
            compare(stageSelectedSpy.signalArguments[2][1], "Done");
        }
    }
}
