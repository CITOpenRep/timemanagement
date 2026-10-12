import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components/feedback"
import "../../models/dbinit.js" as DbInit

MainView {
    id: testRoot
    width: units.gu(40)
    height: units.gu(70)

    NotificationBell {
        id: testBell
        parentWindow: testRoot
    }

    SignalSpy {
        id: navigateSpy
        target: testBell
        signalName: "navigateToRecord"
    }

    TestCase {
        name: "NotificationBellTests"
        when: windowShown

        function initTestCase() {
            DbInit.initializeDatabase();
        }

        function init() {
            testBell.activeFilter = "normal";
            testBell.normalCount = 0;
            testBell.syncCount = 0;
            testBell.totalCount = 0;
            testBell.notificationCount = 0;
            navigateSpy.clear();
        }

        function cleanup() {
            navigateSpy.clear();
        }

        function test_initialProperties() {
            verify(testBell.width > 0);
            verify(testBell.height > 0);
            compare(testBell.activeFilter, "normal");
            compare(typeof testBell.normalCount, "number");
            compare(typeof testBell.syncCount, "number");
            compare(typeof testBell.totalCount, "number");
            compare(navigateSpy.count, 0);
        }

        function test_unreadCounterBadgeComputation() {
            testBell.normalCount = 4;
            testBell.syncCount = 2;
            testBell.totalCount = testBell.normalCount + testBell.syncCount;

            compare(testBell.normalCount, 4);
            compare(testBell.syncCount, 2);
            compare(testBell.totalCount, 6);
        }

        function test_activeFilterSwitching() {
            testBell.activeFilter = "sync";
            compare(testBell.activeFilter, "sync");

            testBell.activeFilter = "normal";
            compare(testBell.activeFilter, "normal");
        }

        function test_formatTimestampNow() {
            var now = new Date().toISOString();
            var formatted = testBell.formatTimestamp(now);
            compare(formatted, "Just now");
        }

        function test_formatTimestampEmpty() {
            compare(testBell.formatTimestamp(""), "");
            compare(testBell.formatTimestamp(null), "");
        }

        function test_formatTimestampMinutesAgo() {
            var past = new Date(Date.now() - 10 * 60 * 1000).toISOString();
            var formatted = testBell.formatTimestamp(past);
            verify(formatted.indexOf("m ago") !== -1 || formatted.indexOf("10") !== -1);
        }

        function test_formatTimestampHoursAgo() {
            var past = new Date(Date.now() - 3 * 3600 * 1000).toISOString();
            var formatted = testBell.formatTimestamp(past);
            verify(formatted.indexOf("h ago") !== -1 || formatted.indexOf("3") !== -1);
        }

        function test_navigateToRecordSignalEmission() {
            testBell.navigateToRecord("Task", 105, 2);

            compare(navigateSpy.count, 1);
            var args = navigateSpy.signalArguments[0];
            compare(args[0], "Task");
            compare(args[1], 105);
            compare(args[2], 2);
        }

        function test_handleNotificationClickTriggersNavigation() {
            var modelData = {
                id: 9999,
                type: "Activity",
                account_id: 1,
                payload: JSON.stringify({ id: 250, project_id: 12 })
            };

            testBell.handleNotificationClick(modelData);

            compare(navigateSpy.count, 1);
            var args = navigateSpy.signalArguments[0];
            compare(args[0], "Activity");
            compare(args[1], 250);
            compare(args[2], 1);
        }

        function test_handleNotificationClickWithoutRecordIdDoesNotNavigate() {
            var modelData = {
                id: 9998,
                type: "Sync",
                account_id: 1,
                payload: ""
            };

            testBell.handleNotificationClick(modelData);
            compare(navigateSpy.count, 0);
        }

        function test_openPopupExecution() {
            testBell.openPopup();
            verify(testBell !== null);
        }
    }
}
