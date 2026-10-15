import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components/cards"
import "../../models/dbinit.js" as DbInit

MainView {
    id: testRoot
    width: units.gu(50)
    height: units.gu(80)

    UpdatesDetailsCard {
        id: testCard
        account_id: 1
        recordId: 301
    }

    SignalSpy {
        id: showDescriptionSpy
        target: testCard
        signalName: "showDescription"
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
        id: deleteRequestedSpy
        target: testCard
        signalName: "deleteRequested"
    }

    TestCase {
        name: "UpdatesDetailsCardTests"
        when: windowShown

        function initTestCase() {
            DbInit.initializeDatabase();
        }

        function init() {
            testCard.name = "";
            testCard.project_id = "";
            testCard.status = "";
            testCard.progress = 0;
            testCard.description = "";
            testCard.user = "";
            testCard.date = "";
            testCard.recordId = 301;
            testCard.account_id = 1;
            testCard.colorPallet = 0;
            testCard.hasDraft = false;

            showDescriptionSpy.clear();
            editRequestedSpy.clear();
            viewRequestedSpy.clear();
            deleteRequestedSpy.clear();
        }

        function cleanup() {
            showDescriptionSpy.clear();
            editRequestedSpy.clear();
            viewRequestedSpy.clear();
            deleteRequestedSpy.clear();
        }

        function test_initialProperties() {
            compare(testCard.name, "");
            compare(testCard.project_id, "");
            compare(testCard.status, "");
            compare(testCard.progress, 0);
            compare(testCard.description, "");
            compare(testCard.user, "");
            compare(testCard.date, "");
            compare(testCard.hasDraft, false);
            compare(testCard.recordId, 301);
            compare(testCard.account_id, 1);
        }

        function test_updateSummaryAndProgressProperties() {
            testCard.name = "Weekly Sprint Update";
            testCard.description = "Completed milestone 3 and backend integration";
            testCard.progress = 65;
            testCard.date = "2026-10-15";
            testCard.user = "42";

            compare(testCard.name, "Weekly Sprint Update");
            compare(testCard.description, "Completed milestone 3 and backend integration");
            compare(testCard.progress, 65);
            compare(testCard.date, "2026-10-15");
            compare(testCard.user, "42");
        }

        function test_statusBadgeValues() {
            testCard.status = "on_track";
            compare(testCard.status, "on_track");

            testCard.status = "at_risk";
            compare(testCard.status, "at_risk");

            testCard.status = "off_track";
            compare(testCard.status, "off_track");

            testCard.status = "on_hold";
            compare(testCard.status, "on_hold");
        }

        function test_draftIndicatorProperty() {
            testCard.hasDraft = true;
            compare(testCard.hasDraft, true);

            testCard.hasDraft = false;
            compare(testCard.hasDraft, false);
        }

        function test_cardClickEmitsViewRequested() {
            testCard.account_id = 2;
            testCard.recordId = 999;

            testCard.clicked();

            compare(viewRequestedSpy.count, 1);
            compare(viewRequestedSpy.signalArguments[0][0], 2);
            compare(viewRequestedSpy.signalArguments[0][1], 999);
        }

        function test_showDescriptionSignalEmission() {
            testCard.name = "Release 1.0";
            testCard.description = "Everything tested and deployed.";

            testCard.showDescription("<h1>" + testCard.name + "</h1>" + testCard.description);

            compare(showDescriptionSpy.count, 1);
            var emittedText = showDescriptionSpy.signalArguments[0][0];
            verify(emittedText.indexOf("<h1>Release 1.0</h1>") !== -1);
            verify(emittedText.indexOf("Everything tested and deployed.") !== -1);
        }

        function test_actionSignalsDirectCalls() {
            testCard.editRequested(5, 777);
            compare(editRequestedSpy.count, 1);
            compare(editRequestedSpy.signalArguments[0][0], 5);
            compare(editRequestedSpy.signalArguments[0][1], 777);

            testCard.deleteRequested(888);
            compare(deleteRequestedSpy.count, 1);
            compare(deleteRequestedSpy.signalArguments[0][0], 888);
        }
    }
}
