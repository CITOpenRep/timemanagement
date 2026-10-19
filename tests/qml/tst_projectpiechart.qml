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
            verify(testChart.chartTitleText.indexOf("(No Data)") !== -1);
            compare(testChart.series.count, 0);
            verify(testChart.implicitHeight > 0);
        }

        function test_loadSingleProject() {
            var data = [
                { name: "Website Redesign", spentHours: 25.0 }
            ];

            testChart.load(data);

            // Chart should now be loaded with the project
            verify(testChart.chartTitleText.indexOf("(No Data)") === -1);
            compare(testChart.series.count, 1);
            var slice = testChart.series.at(0);
            compare(slice.label, "Website Redesign (100.0%)");
            compare(slice.value, 25.0);
            verify(testChart.implicitHeight > 0);
        }

        function test_loadMultipleProjectsSorting() {
            var data = [
                { name: "Small Task", spentHours: 2.0 },
                { name: "Big Project", spentHours: 40.0 },
                { name: "Medium Task", spentHours: 15.0 }
            ];

            testChart.load(data);

            // Slices should be sorted descending by spentHours: Big Project (40), Medium Task (15), Small Task (2)
            compare(testChart.series.count, 3);
            compare(testChart.series.at(0).value, 40.0);
            verify(testChart.series.at(0).label.indexOf("Big Project") !== -1);
            compare(testChart.series.at(1).value, 15.0);
            verify(testChart.series.at(1).label.indexOf("Medium Task") !== -1);
            compare(testChart.series.at(2).value, 2.0);
            verify(testChart.series.at(2).label.indexOf("Small Task") !== -1);
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

            // Top 10 projects + 1 aggregated "Others" slice = 11 slices total
            compare(testChart.series.count, 11);
            var othersSlice = testChart.series.at(10);
            verify(othersSlice.label.indexOf("Others") !== -1);
            // Items past top 10 (sorted descending: 25..16 are top 10; remaining 15+14+13+12+11 = 65)
            compare(othersSlice.value, 65.0);
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
