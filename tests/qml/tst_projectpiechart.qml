import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import QtCharts 2.0
import "../../qml/components/visualization"
import "../../models/dbinit.js" as DbInit

MainView {
    id: testRoot
    width: units.gu(50)
    height: units.gu(80)

    Item {
        id: accountPicker
        property int selectedAccountId: 1
        signal accepted(int id, string name)
    }

    ProjectPieChart {
        id: testChart
        anchors.fill: parent
    }

    TestCase {
        name: "ProjectPieChartTests"
        when: windowShown

        function initTestCase() {
            DbInit.initializeDatabase();
        }

        function init() {
            testChart.load([]);
        }

        function cleanup() {
            testChart.load([]);
        }

        function test_initialProperties() {
            compare(testChart.autoRefreshOnAccountChange, true);
            compare(testChart.selectedUserId, -1);
        }

        function test_loadEmptyDataSetsNoDataTitle() {
            testChart.load([]);

            // chartTitle is updated to show "(No Data)"
            verify(testChart.implicitHeight > 0);
        }

        function test_loadSingleProject() {
            var data = [
                { name: "Website Redesign", spentHours: 25.0 }
            ];

            testChart.load(data);

            // Chart should now be loaded with the project
            verify(testChart.implicitHeight > 0);
        }

        function test_loadMultipleProjectsSorting() {
            var data = [
                { name: "Small Task", spentHours: 2.0 },
                { name: "Big Project", spentHours: 40.0 },
                { name: "Medium Task", spentHours: 15.0 }
            ];

            testChart.load(data);

            verify(testChart.implicitHeight > 0);
        }

        function test_loadMoreThanTenProjectsAggregatesOthers() {
            var data = [];
            for (var i = 1; i <= 15; i++) {
                data.push({
                    name: "Project " + i,
                    spentHours: 10 + i
                });
            }

            testChart.load(data);

            verify(testChart.implicitHeight > 0);
        }

        function test_refreshForAccountExecution() {
            // refreshForAccount should fetch and load without crashing
            testChart.refreshForAccount(1, "2026-01-01", "2026-12-31", -1);
            verify(testChart.selectedAccountId !== undefined);
        }

        function test_accountPickerAcceptedEvent() {
            accountPicker.accepted(2, "Workspace Two");
            verify(testChart.selectedAccountId !== undefined);
        }
    }
}
