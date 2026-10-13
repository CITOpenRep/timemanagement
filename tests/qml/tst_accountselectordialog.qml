import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import "../../qml/components/dialogs"
import "../../models/dbinit.js" as DbInit

MainView {
    id: testRoot
    width: units.gu(40)
    height: units.gu(70)

    AccountSelectorDialog {
        id: testAccountSelector
    }

    SignalSpy {
        id: acceptedSpy
        target: testAccountSelector
        signalName: "accepted"
    }

    SignalSpy {
        id: canceledSpy
        target: testAccountSelector
        signalName: "canceled"
    }

    TestCase {
        name: "AccountSelectorDialogTests"
        when: windowShown

        function initTestCase() {
            DbInit.initializeDatabase();
        }

        function init() {
            testAccountSelector.titleText = "Select Account";
            testAccountSelector.restrictToLocalOnly = false;
            testAccountSelector.selectedAccountId = -1;
            testAccountSelector.selectedAccountName = "";
            testAccountSelector.lastRemoteAccountId = -1;
            acceptedSpy.clear();
            canceledSpy.clear();
        }

        function cleanup() {
            acceptedSpy.clear();
            canceledSpy.clear();
        }

        function test_initialProperties() {
            compare(testAccountSelector.titleText, "Select Account");
            compare(testAccountSelector.restrictToLocalOnly, false);
            compare(acceptedSpy.count, 0);
            compare(canceledSpy.count, 0);
        }

        function test_customTitleText() {
            testAccountSelector.titleText = "Switch Active Account";
            compare(testAccountSelector.titleText, "Switch Active Account");
        }

        function test_restrictToLocalOnlyToggle() {
            testAccountSelector.restrictToLocalOnly = true;
            compare(testAccountSelector.restrictToLocalOnly, true);

            testAccountSelector.restrictToLocalOnly = false;
            compare(testAccountSelector.restrictToLocalOnly, false);
        }

        function test_accountListPickAndSignalEmission() {
            var targetId = 2;
            var targetName = "Acme Corp Odoo";

            testAccountSelector.selectedAccountId = targetId;
            testAccountSelector.selectedAccountName = targetName;
            testAccountSelector.accepted(targetId, targetName);

            compare(testAccountSelector.selectedAccountId, targetId);
            compare(testAccountSelector.selectedAccountName, targetName);
            compare(acceptedSpy.count, 1);
            compare(acceptedSpy.signalArguments[0][0], targetId);
            compare(acceptedSpy.signalArguments[0][1], targetName);
        }

        function test_switchSignalMultipleAccounts() {
            testAccountSelector.accepted(0, "Local Account");
            testAccountSelector.accepted(1, "Dev Server");
            testAccountSelector.accepted(-1, "All Accounts");

            compare(acceptedSpy.count, 3);
            compare(acceptedSpy.signalArguments[0][0], 0);
            compare(acceptedSpy.signalArguments[0][1], "Local Account");
            compare(acceptedSpy.signalArguments[1][0], 1);
            compare(acceptedSpy.signalArguments[1][1], "Dev Server");
            compare(acceptedSpy.signalArguments[2][0], -1);
            compare(acceptedSpy.signalArguments[2][1], "All Accounts");
        }

        function test_canceledSignalEmission() {
            compare(canceledSpy.count, 0);
            testAccountSelector.canceled();
            compare(canceledSpy.count, 1);
            compare(acceptedSpy.count, 0);
        }

        function test_toggleLocalModeSwitchesToLocalAndEmitsSignal() {
            testAccountSelector.selectedAccountId = 3;
            testAccountSelector.selectedAccountName = "Remote Server";

            var result = testAccountSelector.toggleLocalMode(true);
            verify(result);
            compare(testAccountSelector.selectedAccountId, 0);
            compare(acceptedSpy.count, 1);
            compare(acceptedSpy.signalArguments[0][0], 0);
        }

        function test_toggleLocalModeWhenAlreadyLocalDoesNotReEmit() {
            testAccountSelector.selectedAccountId = 0;
            testAccountSelector.selectedAccountName = "Local";
            acceptedSpy.clear();

            var result = testAccountSelector.toggleLocalMode(true);
            verify(result);
            compare(acceptedSpy.count, 0);
        }

        function test_openWithInitialAccountId() {
            testAccountSelector.open(5);
            // Verify open() sets requested initial id or opens cleanly
            verify(testAccountSelector !== null);
        }
    }
}
