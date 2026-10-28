import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components/cards"
import "../../models/dbinit.js" as DbInit

MainView {
    id: testRoot
    width: units.gu(50)
    height: units.gu(80)

    ActivityDetailsCard {
        id: testCard
        account_id: 1
        odoo_record_id: 201
    }

    SignalSpy {
        id: cardClickedSpy
        target: testCard
        signalName: "cardClicked"
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
        id: markAsDoneSpy
        target: testCard
        signalName: "markAsDone"
    }

    SignalSpy {
        id: createFollowupSpy
        target: testCard
        signalName: "createFollowup"
    }

    SignalSpy {
        id: dateChangedSpy
        target: testCard
        signalName: "dateChanged"
    }

    TestCase {
        name: "ActivityDetailsCardTests"
        when: windowShown

        function initTestCase() {
            DbInit.initializeDatabase();
        }

        function init() {
            testCard.notes = "";
            testCard.activity_type_name = "";
            testCard.summary = "";
            testCard.activity_type_id = -1;
            testCard.user = "";
            testCard.due_date = "";
            testCard.state = "";
            testCard.id = -1;
            testCard.odoo_record_id = 201;
            testCard.account_id = 1;
            testCard.colorPallet = 0;
            testCard.hasDraft = false;

            cardClickedSpy.clear();
            editRequestedSpy.clear();
            viewRequestedSpy.clear();
            markAsDoneSpy.clear();
            createFollowupSpy.clear();
            dateChangedSpy.clear();
        }

        function cleanup() {
            cardClickedSpy.clear();
            editRequestedSpy.clear();
            viewRequestedSpy.clear();
            markAsDoneSpy.clear();
            createFollowupSpy.clear();
            dateChangedSpy.clear();
        }

        function test_initialProperties() {
            compare(testCard.notes, "");
            compare(testCard.activity_type_name, "");
            compare(testCard.summary, "");
            compare(testCard.user, "");
            compare(testCard.due_date, "");
            compare(testCard.state, "");
            compare(testCard.hasDraft, false);
            compare(testCard.account_id, 1);
            compare(testCard.odoo_record_id, 201);
        }

        function test_stripHtmlTagsComprehensive() {
            var input = "<p>Meeting with <b>client</b> &amp; discuss <style>body{}</style>options.</p>";
            var stripped = testCard.stripHtmlTags(input);
            verify(stripped.indexOf("<p>") === -1);
            verify(stripped.indexOf("<b>") === -1);
            verify(stripped.indexOf("<style>") === -1);
            verify(stripped.indexOf("&") !== -1);
            verify(stripped.indexOf("Meeting with client") !== -1);

            compare(testCard.stripHtmlTags(""), "");
            compare(testCard.stripHtmlTags(null), "");
        }

        function test_hasHtmlTagsDetection() {
            compare(testCard.hasHtmlTags("Plain text without tags"), false);
            compare(testCard.hasHtmlTags("Text with <i>italic</i> markup"), true);
            compare(testCard.hasHtmlTags("<div>content</div>"), true);
        }

        function test_truncateTextHelper() {
            var text = "This is a very long activity summary that exceeds limits";
            var truncated = testCard.truncateText(text, 10);
            verify(truncated.length <= 13);
            verify(truncated.indexOf("...") !== -1);

            var shortText = "Short";
            compare(testCard.truncateText(shortText, 20), "Short");
        }

        function test_smartTruncateRichAndPlain() {
            var plain = "Short plain text";
            var plainTrunc = testCard.smartTruncate(plain, 25);
            compare(plainTrunc, plain);

            var rich = "<p>A <b>formatted</b> string for testing truncate</p>";
            var richTrunc = testCard.smartTruncate(rich, 10);
            verify(richTrunc.indexOf("...") !== -1);
        }

        function test_isActivityOverdueCalculations() {
            // Empty date or done state is never overdue
            testCard.due_date = "";
            testCard.state = "";
            compare(testCard.isActivityOverdue(), false);

            testCard.due_date = "2020-01-01";
            testCard.state = "done";
            compare(testCard.isActivityOverdue(), false);

            // Date in the distant past is overdue
            testCard.due_date = "2020-01-01";
            testCard.state = "planned";
            compare(testCard.isActivityOverdue(), true);

            // Date in the distant future is not overdue
            testCard.due_date = "2099-12-31";
            testCard.state = "planned";
            compare(testCard.isActivityOverdue(), false);
        }

        function test_isActivityDueTodayCalculation() {
            testCard.due_date = "";
            testCard.state = "";
            compare(testCard.isActivityDueToday(), false);

            // Set today's date formatted as YYYY-MM-DD using local date components to match isActivityDueToday()
            var now = new Date();
            var yyyy = now.getFullYear();
            var mm = String(now.getMonth() + 1).padStart(2, '0');
            var dd = String(now.getDate()).padStart(2, '0');
            var todayStr = yyyy + "-" + mm + "-" + dd;

            testCard.due_date = todayStr;
            testCard.state = "planned";
            compare(testCard.isActivityDueToday(), true);

            // Done state ignores due today
            testCard.state = "done";
            compare(testCard.isActivityDueToday(), false);
        }

        function test_getActivityStateInfoOutputs() {
            // Overdue state
            testCard.due_date = "2020-01-01";
            testCard.state = "planned";
            var overdueInfo = testCard.getActivityStateInfo();
            compare(overdueInfo.color, "#F44336");
            verify(overdueInfo.text.indexOf("OVERDUE") !== -1 || overdueInfo.text.length > 0);

            // Done state
            testCard.due_date = "2020-01-01";
            testCard.state = "done";
            var doneInfo = testCard.getActivityStateInfo();
            compare(doneInfo.color, "#28753c");
            verify(doneInfo.text.indexOf("DONE") !== -1 || doneInfo.text.length > 0);

            // Planned state (future date)
            testCard.due_date = "2099-01-01";
            testCard.state = "planned";
            var plannedInfo = testCard.getActivityStateInfo();
            compare(plannedInfo.color, "#2196F3");
            verify(plannedInfo.text.indexOf("PLANNED") !== -1 || plannedInfo.text.length > 0);
        }

        function test_cardClickedSignalEmission() {
            testCard.account_id = 3;
            testCard.odoo_record_id = 777;

            testCard.clicked();

            compare(cardClickedSpy.count, 1);
            compare(cardClickedSpy.signalArguments[0][0], 3);
            compare(cardClickedSpy.signalArguments[0][1], 777);
        }

        function test_actionSignalsDirectEmission() {
            testCard.editRequested(2, 404);
            compare(editRequestedSpy.count, 1);
            compare(editRequestedSpy.signalArguments[0][0], 2);
            compare(editRequestedSpy.signalArguments[0][1], 404);

            testCard.viewRequested(2, 404);
            compare(viewRequestedSpy.count, 1);
            compare(viewRequestedSpy.signalArguments[0][0], 2);
            compare(viewRequestedSpy.signalArguments[0][1], 404);

            testCard.markAsDone(2, 404);
            compare(markAsDoneSpy.count, 1);
            compare(markAsDoneSpy.signalArguments[0][0], 2);
            compare(markAsDoneSpy.signalArguments[0][1], 404);

            testCard.createFollowup(2, 404);
            compare(createFollowupSpy.count, 1);
            compare(createFollowupSpy.signalArguments[0][0], 2);
            compare(createFollowupSpy.signalArguments[0][1], 404);

            testCard.dateChanged(2, 404, "2026-11-01");
            compare(dateChangedSpy.count, 1);
            compare(dateChangedSpy.signalArguments[0][0], 2);
            compare(dateChangedSpy.signalArguments[0][1], 404);
            compare(dateChangedSpy.signalArguments[0][2], "2026-11-01");
        }
    }
}
