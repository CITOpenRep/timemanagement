import QtQuick 2.7
import QtTest 1.0
import "../../../qml/app/navigation/NavigationRoutes.js" as NavigationRoutes

Item {
    width: 200
    height: 200

    TestCase {
        name: "NavigationRoutesTests"
        when: windowShown

        function test_menuItemsIntegrity() {
            var items = NavigationRoutes.menuItems();
            verify(Array.isArray(items));
            compare(items.length, 9);

            var expectedKeys = [
                "Dashboard", "Timesheet", "Activities", "My Tasks",
                "All Tasks", "Projects", "Project Updates", "About Us", "Settings"
            ];

            for (var i = 0; i < items.length; i++) {
                var item = items[i];
                compare(item.textKey, expectedKeys[i]);
                verify(typeof item.iconName === "string" && item.iconName.length > 0);
                verify(typeof item.iconColor === "string" && item.iconColor.startsWith("#"));
                verify(typeof item.pageUrl === "string" && item.pageUrl.endsWith(".qml"));
                verify(typeof item.pageNum === "number" && item.pageNum >= 0);
            }
        }

        function test_menuItemsImmutability() {
            var items1 = NavigationRoutes.menuItems();
            items1.pop(); // Modify returned array
            var items2 = NavigationRoutes.menuItems();
            compare(items2.length, 9); // Original must not be modified
        }

        function test_resolvePageKey() {
            compare(NavigationRoutes.resolvePageKey(0, ""), "dashboard");
            compare(NavigationRoutes.resolvePageKey(1, ""), "timesheet_list");
            compare(NavigationRoutes.resolvePageKey(2, ""), "activity");

            // Page 3: distinguishes My Tasks vs All Tasks
            compare(NavigationRoutes.resolvePageKey(3, "features/tasks/pages/MyTasksPage.qml"), "my_tasks");
            compare(NavigationRoutes.resolvePageKey(3, "features/tasks/pages/Task_Page.qml"), "task");
            compare(NavigationRoutes.resolvePageKey(3, ""), "task");

            compare(NavigationRoutes.resolvePageKey(4, ""), "project");
            compare(NavigationRoutes.resolvePageKey(5, ""), "updates");
            compare(NavigationRoutes.resolvePageKey(6, ""), "settings");
            compare(NavigationRoutes.resolvePageKey(7, ""), "about");

            // Unknown page numbers fall back to "dynamic"
            compare(NavigationRoutes.resolvePageKey(8, ""), "dynamic");
            compare(NavigationRoutes.resolvePageKey(-1, ""), "dynamic");
            compare(NavigationRoutes.resolvePageKey(99, ""), "dynamic");
        }

        function test_pageUrlForNavType() {
            compare(NavigationRoutes.pageUrlForNavType("Task"), "features/tasks/pages/Tasks.qml");
            compare(NavigationRoutes.pageUrlForNavType("Activity"), "features/activities/pages/Activities.qml");
            compare(NavigationRoutes.pageUrlForNavType("ProjectUpdate"), "features/updates/pages/Updates.qml");
            compare(NavigationRoutes.pageUrlForNavType("Project"), "features/projects/pages/Projects.qml");
            compare(NavigationRoutes.pageUrlForNavType("Timesheet"), "features/timesheets/pages/Timesheet.qml");

            // Unknown nav types return empty string
            compare(NavigationRoutes.pageUrlForNavType("Unknown"), "");
            compare(NavigationRoutes.pageUrlForNavType(""), "");
            compare(NavigationRoutes.pageUrlForNavType(null), "");
            compare(NavigationRoutes.pageUrlForNavType(undefined), "");
        }
    }
}
