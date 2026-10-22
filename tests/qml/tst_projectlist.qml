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

    ProjectList {
        id: testList
        anchors.fill: parent
    }

    SignalSpy {
        id: projectSelectedSpy
        target: testList
        signalName: "projectSelected"
    }

    SignalSpy {
        id: projectEditRequestedSpy
        target: testList
        signalName: "projectEditRequested"
    }

    SignalSpy {
        id: projectDeleteRequestedSpy
        target: testList
        signalName: "projectDeleteRequested"
    }

    SignalSpy {
        id: projectTimesheetRequestedSpy
        target: testList
        signalName: "projectTimesheetRequested"
    }

    SignalSpy {
        id: customSearchSpy
        target: testList
        signalName: "customSearch"
    }

    TestCase {
        name: "ProjectListTests"
        when: windowShown

        function initTestCase() {
            DbInit.initializeDatabase();
        }

        function init() {
            testList.navigationStackModel.clear();
            testList.currentParentId = -1;
            testList.currentParentName = "";
            testList.flatViewMode = false;
            testList.searchQuery = "";
            testList.showSearchBox = false;

            projectSelectedSpy.clear();
            projectEditRequestedSpy.clear();
            projectDeleteRequestedSpy.clear();
            projectTimesheetRequestedSpy.clear();
            customSearchSpy.clear();
        }

        function cleanup() {
            projectSelectedSpy.clear();
            projectEditRequestedSpy.clear();
            projectDeleteRequestedSpy.clear();
            projectTimesheetRequestedSpy.clear();
            customSearchSpy.clear();
        }

        function test_initialProperties() {
            compare(testList.currentParentId, -1);
            compare(testList.currentParentName, "");
            compare(testList.flatViewMode, false);
            compare(testList.searchQuery, "");
            compare(testList.showSearchBox, false);
            compare(testList.navigationStackModel.count, 0);
            compare(testList.pageSize, 30);
        }

        function test_navigateToProjectPushesStack() {
            testList.navigateToProject(100, 1, "Parent Project A");

            compare(testList.navigationStackModel.count, 1);
            compare(testList.currentParentId, 100);
            compare(testList.currentParentName, "Parent Project A");
            compare(testList.currentAccountId, 1);
        }

        function test_navigateBackInHierarchyPopsStack() {
            testList.navigateToProject(100, 1, "Parent Project A");
            compare(testList.navigationStackModel.count, 1);

            testList.navigateBackInHierarchy();

            compare(testList.navigationStackModel.count, 0);
            compare(testList.currentParentId, -1);
            compare(testList.currentParentName, "");
        }

        function test_multiLevelHierarchyNavigationAndBacktrack() {
            testList.navigateToProject(100, 1, "Level 1");
            testList.navigateToProject(200, 1, "Level 2");

            compare(testList.navigationStackModel.count, 2);
            compare(testList.currentParentId, 200);
            compare(testList.currentParentName, "Level 2");

            // Backtrack to Level 1
            testList.navigateBackInHierarchy();
            compare(testList.navigationStackModel.count, 1);
            compare(testList.currentParentId, 100);
            compare(testList.currentParentName, "Level 1");

            // Backtrack to Root
            testList.navigateBackInHierarchy();
            compare(testList.navigationStackModel.count, 0);
            compare(testList.currentParentId, -1);
        }

        function test_projectActionSignalsEmission() {
            testList.selectProject(55);
            compare(projectSelectedSpy.count, 1);
            compare(projectSelectedSpy.signalArguments[0][0], 55);

            testList.editProject(55);
            compare(projectEditRequestedSpy.count, 1);
            compare(projectEditRequestedSpy.signalArguments[0][0], 55);

            testList.requestTimesheet(55);
            compare(projectTimesheetRequestedSpy.count, 1);
            compare(projectTimesheetRequestedSpy.signalArguments[0][0], 55);

            testList.projectDeleteRequested(55);
            compare(projectDeleteRequestedSpy.count, 1);
            compare(projectDeleteRequestedSpy.signalArguments[0][0], 55);
        }

        function test_toggleFlatViewMode() {
            compare(testList.flatViewMode, false);

            testList.toggleFlatView();
            compare(testList.flatViewMode, true);

            testList.toggleFlatView();
            compare(testList.flatViewMode, false);
        }

        function test_searchOperationsAndSignals() {
            testList.performSearch("Redesign");

            compare(testList.searchQuery, "Redesign");
            compare(customSearchSpy.count, 1);
            compare(customSearchSpy.signalArguments[0][0], "Redesign");

            testList.clearSearch();

            compare(testList.searchQuery, "");
            compare(customSearchSpy.count, 2);
            compare(customSearchSpy.signalArguments[1][0], "");
        }

        function test_toggleSearchVisibility() {
            compare(testList.showSearchBox, false);

            testList.toggleSearchVisibility();
            compare(testList.showSearchBox, true);

            testList.toggleSearchVisibility();
            compare(testList.showSearchBox, false);
        }

        function test_handleAccountChangedResetsNavigation() {
            testList.navigateToProject(100, 1, "Level 1");
            compare(testList.navigationStackModel.count, 1);

            testList.handleAccountChanged(2);

            compare(testList.currentAccountId, 2);
            compare(testList.currentParentId, -1);
            compare(testList.currentParentName, "");
            compare(testList.navigationStackModel.count, 0);
            compare(testList.searchQuery, "");
        }
    }
}
