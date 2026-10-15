import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components/cards"
import "../../models/dbinit.js" as DbInit

MainView {
    id: testRoot
    width: units.gu(50)
    height: units.gu(80)

    Item {
        id: globalTimerWidget
        signal timerStarted()
        signal timerStopped()
        signal timerPaused()
        signal timerResumed()
    }

    ProjectDetailsCard {
        id: testCard
        localId: 101
        recordId: 501
        accountId: 1
    }

    SignalSpy {
        id: editRequestedSpy
        target: testCard
        signalName: "editRequested"
    }

    SignalSpy {
        id: viewRequestedSpy
        target: testCard
        signalName: "viewRequested"
    }

    SignalSpy {
        id: timesheetRequestedSpy
        target: testCard
        signalName: "timesheetRequested"
    }

    SignalSpy {
        id: navigationRequestedSpy
        target: testCard
        signalName: "navigationRequested"
    }

    TestCase {
        name: "ProjectDetailsCardTests"
        when: windowShown

        function initTestCase() {
            DbInit.initializeDatabase();
        }

        function init() {
            testCard.projectName = "";
            testCard.accountName = "";
            testCard.allocatedHours = 0;
            testCard.remainingHours = 0;
            testCard.startDate = "";
            testCard.endDate = "";
            testCard.deadline = "";
            testCard.description = "";
            testCard.colorPallet = 0;
            testCard.recordId = 501;
            testCard.localId = 101;
            testCard.accountId = 1;
            testCard.hasChildren = false;
            testCard.childCount = 0;
            testCard.stage = 0;
            testCard.taskCount = 0;
            testCard.isFavorite = true;
            testCard.timer_on = false;
            testCard.timer_paused = false;
            testCard.hasDraft = false;

            editRequestedSpy.clear();
            viewRequestedSpy.clear();
            timesheetRequestedSpy.clear();
            navigationRequestedSpy.clear();
        }

        function cleanup() {
            editRequestedSpy.clear();
            viewRequestedSpy.clear();
            timesheetRequestedSpy.clear();
            navigationRequestedSpy.clear();
        }

        function test_initialProperties() {
            compare(testCard.isFavorite, true);
            compare(testCard.projectName, "");
            compare(testCard.accountName, "");
            compare(testCard.allocatedHours, 0);
            compare(testCard.remainingHours, 0);
            compare(testCard.hasChildren, false);
            compare(testCard.childCount, 0);
            compare(testCard.hasDraft, false);
            compare(testCard.timer_on, false);
            compare(testCard.timer_paused, false);
            compare(testCard.formattedAccount, "LOCAL");
        }

        function test_formattedAccountUppercase() {
            testCard.accountName = "Production";
            compare(testCard.formattedAccount, "PRODUCTION");

            testCard.accountName = "dev-corp";
            compare(testCard.formattedAccount, "DEV-CORP");

            testCard.accountName = "";
            compare(testCard.formattedAccount, "LOCAL");
        }

        function test_plannedHoursFormatting() {
            testCard.allocatedHours = 14.5;
            compare(testCard.plannedHoursText, "14.5h planned");

            testCard.allocatedHours = 20;
            compare(testCard.plannedHoursText, "20h planned");

            testCard.allocatedHours = 0;
            compare(testCard.plannedHoursText, "");
        }

        function test_dateRangeFormattingSameYear() {
            testCard.startDate = "2026-03-01";
            testCard.endDate = "2026-03-15";
            verify(testCard.dateRangeFormatted.indexOf("Mar 1") !== -1 || testCard.dateRangeFormatted.indexOf("03-01") !== -1);
            verify(testCard.dateRangeFormatted.indexOf("Mar 15") !== -1 || testCard.dateRangeFormatted.indexOf("03-15") !== -1);
        }

        function test_dateRangeFormattingEndDateOnly() {
            testCard.startDate = "";
            testCard.endDate = "2026-12-31";
            verify(testCard.dateRangeFormatted.indexOf("Dec 31") !== -1 || testCard.dateRangeFormatted.indexOf("12-31") !== -1);
        }

        function test_timeStatusAndUrgencyIndicators() {
            // Overdue date in the past
            testCard.deadline = "2020-01-01";
            verify(testCard.hasValidTimeStatus);
            compare(testCard.isOverdue, true);
            compare(testCard.isDueToday, false);

            // Empty dates -> N/A or invalid
            testCard.deadline = "";
            testCard.endDate = "";
            compare(testCard.hasValidTimeStatus, false);
        }

        function test_descriptionSnippetSanitization() {
            testCard.description = "<p>This is a <b>bold</b> project description.</p>";
            verify(testCard.descriptionSnippet.indexOf("<p>") === -1);
            verify(testCard.descriptionSnippet.indexOf("project description") !== -1);

            testCard.description = "   Simple Clean Description   ";
            compare(testCard.descriptionSnippet, "Simple Clean Description");

            testCard.description = "";
            compare(testCard.descriptionSnippet, "");
        }

        function test_remainingSubtitleComposition() {
            testCard.taskCount = 5;
            testCard.allocatedHours = 10;
            testCard.hasChildren = true;
            testCard.childCount = 2;
            testCard.description = "Sample overview";

            var subtitle = testCard.remainingSubtitle;
            verify(subtitle.indexOf("5 tasks") !== -1);
            verify(subtitle.indexOf("10h planned") !== -1);
            verify(subtitle.indexOf("2 subprojects") !== -1);
            verify(subtitle.indexOf("Sample overview") !== -1);
        }

        function test_isStageDoneEvaluation() {
            testCard.stageName = "Completed";
            compare(testCard.isStageDone, true);

            testCard.stageName = "Done";
            compare(testCard.isStageDone, true);

            testCard.stageName = "In Progress";
            compare(testCard.isStageDone, false);

            testCard.stageName = "";
            compare(testCard.isStageDone, false);
        }

        function test_effectiveProjectId() {
            // Server account (accountId > 0) with recordId > 0
            testCard.accountId = 1;
            testCard.recordId = 501;
            testCard.localId = 101;
            compare(testCard.effectiveProjectId, 501);

            // Local account (accountId === 0)
            testCard.accountId = 0;
            testCard.recordId = 501;
            testCard.localId = 101;
            compare(testCard.effectiveProjectId, 101);
        }

        function test_signalsEmissionDirectCall() {
            testCard.viewRequested(101);
            compare(viewRequestedSpy.count, 1);
            compare(viewRequestedSpy.signalArguments[0][0], 101);

            testCard.editRequested(501);
            compare(editRequestedSpy.count, 1);
            compare(editRequestedSpy.signalArguments[0][0], 501);

            testCard.timesheetRequested(101);
            compare(timesheetRequestedSpy.count, 1);
            compare(timesheetRequestedSpy.signalArguments[0][0], 101);

            testCard.navigationRequested(501, 1, "Alpha Project");
            compare(navigationRequestedSpy.count, 1);
            compare(navigationRequestedSpy.signalArguments[0][0], 501);
            compare(navigationRequestedSpy.signalArguments[0][1], 1);
            compare(navigationRequestedSpy.signalArguments[0][2], "Alpha Project");
        }

        function test_globalTimerWidgetReset() {
            testCard.timer_on = true;
            testCard.timer_paused = true;

            globalTimerWidget.timerStopped();

            compare(testCard.timer_on, false);
            compare(testCard.timer_paused, false);
        }
    }
}
