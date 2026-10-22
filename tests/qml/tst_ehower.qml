import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
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

    EHower {
        id: testMatrix
        anchors.fill: parent
    }

    SignalSpy {
        id: quadrantClickedSpy
        target: testMatrix
        signalName: "quadrantClicked"
    }

    TestCase {
        name: "EHowerTests"
        when: windowShown

        function initTestCase() {
            DbInit.initializeDatabase();
        }

        function init() {
            testMatrix.selectedAccountId = 1;
            testMatrix.selectedUserId = -1;
            testMatrix.quadrant1Hours = "0";
            testMatrix.quadrant2Hours = "0";
            testMatrix.quadrant3Hours = "0";
            testMatrix.quadrant4Hours = "0";
            quadrantClickedSpy.clear();
        }

        function cleanup() {
            quadrantClickedSpy.clear();
        }

        function test_initialProperties() {
            verify(testMatrix.quadrant1Hours !== undefined);
            verify(testMatrix.quadrant2Hours !== undefined);
            verify(testMatrix.quadrant3Hours !== undefined);
            verify(testMatrix.quadrant4Hours !== undefined);
            compare(testMatrix.autoRefreshOnAccountChange, true);
        }

        function test_quadrantHoursPropertiesUpdate() {
            testMatrix.quadrant1Hours = "10H";
            testMatrix.quadrant2Hours = "15H";
            testMatrix.quadrant3Hours = "5H";
            testMatrix.quadrant4Hours = "2H";

            compare(testMatrix.quadrant1Hours, "10H");
            compare(testMatrix.quadrant2Hours, "15H");
            compare(testMatrix.quadrant3Hours, "5H");
            compare(testMatrix.quadrant4Hours, "2H");
        }

        function test_quadrantClickedSignalQ1() {
            testMatrix.quadrantClicked(1);

            compare(quadrantClickedSpy.count, 1);
            compare(quadrantClickedSpy.signalArguments[0][0], 1);
        }

        function test_quadrantClickedSignalQ2() {
            testMatrix.quadrantClicked(2);

            compare(quadrantClickedSpy.count, 1);
            compare(quadrantClickedSpy.signalArguments[0][0], 2);
        }

        function test_quadrantClickedSignalQ3() {
            testMatrix.quadrantClicked(3);

            compare(quadrantClickedSpy.count, 1);
            compare(quadrantClickedSpy.signalArguments[0][0], 3);
        }

        function test_quadrantClickedSignalQ4() {
            testMatrix.quadrantClicked(4);

            compare(quadrantClickedSpy.count, 1);
            compare(quadrantClickedSpy.signalArguments[0][0], 4);
        }

        function test_refreshQuadrantsParameters() {
            testMatrix.refreshQuadrants("2026-01-01", "2026-12-31", 10, 2);

            compare(testMatrix.selectedAccountId, 2);
            compare(testMatrix.selectedUserId, 10);
            verify(testMatrix.quadrant1Hours.indexOf("H") !== -1);
            verify(testMatrix.quadrant2Hours.indexOf("H") !== -1);
            verify(testMatrix.quadrant3Hours.indexOf("H") !== -1);
            verify(testMatrix.quadrant4Hours.indexOf("H") !== -1);
        }

        function test_accountPickerAcceptedUpdatesAccount() {
            accountPicker.selectedAccountId = 5;
            accountPicker.accepted(5, "New Account");

            compare(testMatrix.selectedAccountId, 5);
        }
    }
}
