import QtQuick 2.7
import QtTest 1.0
import QtQuick.LocalStorage 2.7 as Sql
import "../../../models/logger.js" as Logger
import "../../../models/database.js" as DBCommon
import "../../../models/dbinit.js" as DbInit
import "../../../models/global.js" as Global

Item {
    width: 200
    height: 200

    TestCase {
        name: "GlobalStateTests"
        when: windowShown

        function initTestCase() {
            Logger.setLogLevel(Logger.LogLevel.NONE);
            DbInit.initializeDatabase();
        }

        function cleanupTestCase() {
            Logger.setLogLevel(Logger.LogLevel.WARN);
            Global.clearAssigneeFilter();
            Global.clearDateRangeFilter();
        }

        function test_assigneeFilterLifecycle() {
            Global.clearAssigneeFilter();
            var initial = Global.getAssigneeFilter();
            compare(initial.enabled, false);
            compare(initial.assigneeIds.length, 0);

            // Set filter
            Global.setAssigneeFilter(true, [10, 20, 30]);
            var active = Global.getAssigneeFilter();
            compare(active.enabled, true);
            compare(active.assigneeIds.length, 3);
            compare(active.assigneeIds[0], 10);
            compare(active.assigneeIds[1], 20);
            compare(active.assigneeIds[2], 30);

            // Mutating returned array should not mutate internal state (array copy isolation)
            active.assigneeIds.push(999);
            var rechecked = Global.getAssigneeFilter();
            compare(rechecked.assigneeIds.length, 3);

            // Clear filter
            Global.clearAssigneeFilter();
            var cleared = Global.getAssigneeFilter();
            compare(cleared.enabled, false);
            compare(cleared.assigneeIds.length, 0);
        }

        function test_lastVisitedPageTracking() {
            Global.setLastVisitedPage("Tasks");
            compare(Global.getLastVisitedPage(), "Tasks");

            Global.setLastVisitedPage("Dashboard");
            compare(Global.getLastVisitedPage(), "Dashboard");
        }

        function test_shouldPreserveAssigneeFilter() {
            // Task page group transitions
            verify(Global.shouldPreserveAssigneeFilter("Task_Page", "Tasks"));
            verify(Global.shouldPreserveAssigneeFilter("Tasks", "Task_Page"));

            // Activity page group transitions
            verify(Global.shouldPreserveAssigneeFilter("Activity_Page", "Activities"));
            verify(Global.shouldPreserveAssigneeFilter("Activities", "Activity_Page"));

            // External transitions
            verify(!Global.shouldPreserveAssigneeFilter("Tasks", "Dashboard"));
            verify(!Global.shouldPreserveAssigneeFilter("Activity_Page", "Timesheet"));
            verify(!Global.shouldPreserveAssigneeFilter("Dashboard", "Projects"));
        }

        function test_dateRangeFilterLifecycle() {
            Global.setDateRangeFilter(1, "2026-10-01", "2026-10-07", "This Week");

            var filter = Global.getDateRangeFilter();
            verify(filter !== null);
            compare(filter.presetId, 1);
            compare(filter.startDate, "2026-10-01");
            compare(filter.endDate, "2026-10-07");
            compare(filter.presetLabel, "This Week");

            // Verify persistence in app_settings table
            var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
            db.transaction(function(tx) {
                var res = tx.executeSql("SELECT value FROM app_settings WHERE key = 'dashboard_date_range_filter'");
                verify(res.rows.length > 0);
                var data = JSON.parse(res.rows.item(0).value);
                compare(data.presetId, 1);
                compare(data.startDate, "2026-10-01");
            });

            // Clear filter
            Global.clearDateRangeFilter();
            var cleared = Global.getDateRangeFilter();
            compare(cleared.presetId, -1);
            compare(cleared.startDate, "");
            compare(cleared.endDate, "");
            compare(cleared.presetLabel, "No Filter");
        }
    }
}
