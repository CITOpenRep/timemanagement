import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import QtQuick.LocalStorage 2.0 as Sql
import "../../qml/components/selectors"
import "../../models/dbinit.js" as DbInit
import "../../models/database.js" as DBCommon

MainView {
    id: testRoot
    width: units.gu(40)
    height: units.gu(70)

    ProjectStageSelector {
        id: testStageSelector
    }

    SignalSpy {
        id: stageSelectedSpy
        target: testStageSelector
        signalName: "stageSelected"
    }

    TestCase {
        name: "ProjectStageSelectorTests"
        when: windowShown

        function initTestCase() {
            DbInit.initializeDatabase();
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function (tx) {
                tx.executeSql("DELETE FROM project_project_stage_app WHERE account_id = 9999");
                tx.executeSql("INSERT INTO project_project_stage_app (account_id, odoo_record_id, name, sequence, active, fold) VALUES (?, ?, ?, ?, ?, ?)", [9999, 101, "Planning", 1, 1, 0]);
                tx.executeSql("INSERT INTO project_project_stage_app (account_id, odoo_record_id, name, sequence, active, fold) VALUES (?, ?, ?, ?, ?, ?)", [9999, 102, "In Progress", 2, 1, 0]);
                tx.executeSql("INSERT INTO project_project_stage_app (account_id, odoo_record_id, name, sequence, active, fold) VALUES (?, ?, ?, ?, ?, ?)", [9999, 103, "Completed", 3, 1, 1]);
            });
        }

        function cleanupTestCase() {
            try {
                var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
                db.transaction(function (tx) {
                    tx.executeSql("DELETE FROM project_project_stage_app WHERE account_id = 9999");
                });
            } catch (e) {
                console.log("Cleanup error: " + e);
            }
        }

        function init() {
            testStageSelector.projectId = -1;
            testStageSelector.accountId = -1;
            testStageSelector.currentStageOdooRecordId = -1;
            testStageSelector.availableStages = [];
            stageSelectedSpy.clear();
        }

        function cleanup() {
            stageSelectedSpy.clear();
        }

        function test_initialProperties() {
            compare(testStageSelector.title, "Change Project Stage");
            compare(testStageSelector.projectId, -1);
            compare(testStageSelector.accountId, -1);
            compare(testStageSelector.currentStageOdooRecordId, -1);
            compare(stageSelectedSpy.count, 0);
        }

        function test_propertyAssignments() {
            testStageSelector.projectId = 42;
            testStageSelector.accountId = 9999;
            testStageSelector.currentStageOdooRecordId = 101;

            compare(testStageSelector.projectId, 42);
            compare(testStageSelector.accountId, 9999);
            compare(testStageSelector.currentStageOdooRecordId, 101);
        }

        function test_loadStagesForAccount() {
            testStageSelector.accountId = 9999;
            testStageSelector.currentStageOdooRecordId = 102;
            testStageSelector.loadStages();

            compare(testStageSelector.availableStages.length, 3);
            compare(testStageSelector.availableStages[0].odoo_record_id, 101);
            compare(testStageSelector.availableStages[0].name, "Planning");
            compare(testStageSelector.availableStages[0].fold, 0);

            compare(testStageSelector.availableStages[1].odoo_record_id, 102);
            compare(testStageSelector.availableStages[1].name, "In Progress");

            compare(testStageSelector.availableStages[2].odoo_record_id, 103);
            compare(testStageSelector.availableStages[2].name, "Completed");
            compare(testStageSelector.availableStages[2].fold, 1);
        }

        function test_loadStagesForEmptyAccount() {
            testStageSelector.accountId = 88888;
            testStageSelector.loadStages();
            compare(testStageSelector.availableStages.length, 0);
        }

        function test_stageSelectedSignalEmission() {
            compare(stageSelectedSpy.count, 0);
            testStageSelector.stageSelected(103, "Completed");
            compare(stageSelectedSpy.count, 1);
            compare(stageSelectedSpy.signalArguments[0][0], 103);
            compare(stageSelectedSpy.signalArguments[0][1], "Completed");
        }

        function test_stageSelectedMultipleEmissions() {
            testStageSelector.stageSelected(101, "Planning");
            testStageSelector.stageSelected(102, "In Progress");

            compare(stageSelectedSpy.count, 2);
            compare(stageSelectedSpy.signalArguments[0][0], 101);
            compare(stageSelectedSpy.signalArguments[0][1], "Planning");
            compare(stageSelectedSpy.signalArguments[1][0], 102);
            compare(stageSelectedSpy.signalArguments[1][1], "In Progress");
        }
    }
}
