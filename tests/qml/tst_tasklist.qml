import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import QtQuick.LocalStorage 2.0 as Sql
import "../../qml/features/tasks/components"
import "../../models/dbinit.js" as DbInit
import "../../models/database.js" as DBCommon

MainView {
    id: testRoot
    width: units.gu(50)
    height: units.gu(70)

    Item {
        id: globalTimerWidget
        signal timerStopped()
        signal timerStarted()
        signal timerPaused()
        signal timerResumed()
    }

    Item {
        id: accountPicker
        property int selectedAccountId: 0
        signal accepted(int id, string name)
    }

    TaskList {
        id: testTaskList
        anchors.fill: parent
    }

    SignalSpy {
        id: taskSelectedSpy
        target: testTaskList
        signalName: "taskSelected"
    }

    SignalSpy {
        id: taskEditRequestedSpy
        target: testTaskList
        signalName: "taskEditRequested"
    }

    SignalSpy {
        id: taskDeleteRequestedSpy
        target: testTaskList
        signalName: "taskDeleteRequested"
    }

    SignalSpy {
        id: taskTimesheetRequestedSpy
        target: testTaskList
        signalName: "taskTimesheetRequested"
    }

    TestCase {
        name: "TaskListTests"
        when: windowShown

        function initTestCase() {
            DbInit.initializeDatabase();
        }

        function init() {
            testTaskList.currentFilter = "today";
            testTaskList.currentSearchQuery = "";
            testTaskList.filterByProject = false;
            testTaskList.projectOdooRecordId = -1;
            testTaskList.projectAccountId = -1;
            testTaskList.filterByAccount = false;
            testTaskList.filterByAssignees = false;
            testTaskList.flatViewMode = false;

            taskSelectedSpy.clear();
            taskEditRequestedSpy.clear();
            taskDeleteRequestedSpy.clear();
            taskTimesheetRequestedSpy.clear();
        }

        function cleanup() {
            taskSelectedSpy.clear();
            taskEditRequestedSpy.clear();
            taskDeleteRequestedSpy.clear();
            taskTimesheetRequestedSpy.clear();
        }

        function test_initialProperties() {
            compare(testTaskList.currentFilter, "today");
            compare(testTaskList.currentSearchQuery, "");
            compare(testTaskList.pageSize, 30);
            compare(testTaskList.currentParentId, -1);
            compare(testTaskList.filterByProject, false);
            compare(testTaskList.flatViewMode, false);
            compare(testTaskList.isMyTasksContext, false);
        }

        function test_applyFilterMethod() {
            testTaskList.applyFilter("all");
            compare(testTaskList.currentFilter, "all");
            compare(testTaskList.currentParentId, -1);

            testTaskList.applyFilter("starred");
            compare(testTaskList.currentFilter, "starred");
        }

        function test_applySearchMethod() {
            testTaskList.applySearch("QML Unit Test");
            compare(testTaskList.currentSearchQuery, "QML Unit Test");
            compare(testTaskList.currentParentId, -1);

            testTaskList.applySearch("");
            compare(testTaskList.currentSearchQuery, "");
        }

        function test_applyProjectFilterMethod() {
            testTaskList.applyProjectFilter(105, 1);
            compare(testTaskList.filterByProject, true);
            compare(testTaskList.projectOdooRecordId, 105);
            compare(testTaskList.currentFilter, "all");
            compare(testTaskList.currentSearchQuery, "");
        }

        function test_applyProjectAndTimeFilterMethod() {
            testTaskList.applyProjectAndTimeFilter(205, 2, "overdue");
            compare(testTaskList.filterByProject, true);
            compare(testTaskList.projectOdooRecordId, 205);
            compare(testTaskList.projectAccountId, 2);
            compare(testTaskList.currentFilter, "overdue");
        }

        function test_applyProjectAndSearchFilterMethod() {
            testTaskList.applyProjectAndSearchFilter(305, 3, "Database Refactor");
            compare(testTaskList.filterByProject, true);
            compare(testTaskList.projectOdooRecordId, 305);
            compare(testTaskList.projectAccountId, 3);
            compare(testTaskList.currentSearchQuery, "Database Refactor");
        }

        function test_signalsEmission() {
            compare(taskSelectedSpy.count, 0);
            testTaskList.taskSelected(55);
            compare(taskSelectedSpy.count, 1);
            compare(taskSelectedSpy.signalArguments[0][0], 55);

            compare(taskEditRequestedSpy.count, 0);
            testTaskList.taskEditRequested(66);
            compare(taskEditRequestedSpy.count, 1);
            compare(taskEditRequestedSpy.signalArguments[0][0], 66);

            compare(taskDeleteRequestedSpy.count, 0);
            testTaskList.taskDeleteRequested(77);
            compare(taskDeleteRequestedSpy.count, 1);
            compare(taskDeleteRequestedSpy.signalArguments[0][0], 77);

            compare(taskTimesheetRequestedSpy.count, 0);
            testTaskList.taskTimesheetRequested(88);
            compare(taskTimesheetRequestedSpy.count, 1);
            compare(taskTimesheetRequestedSpy.signalArguments[0][0], 88);
        }
    }
}
