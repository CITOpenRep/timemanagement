import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import "../../qml/components/feedback"

MainView {
    id: testRoot
    width: units.gu(40)
    height: units.gu(70)

    NotificationPopup {
        id: testNotificationPopup
    }

    SignalSpy {
        id: closedSpy
        target: testNotificationPopup
        signalName: "closed"
    }

    Timer {
        id: autoDismissTimer
        interval: 100
        repeat: false
        onTriggered: {
            if (testNotificationPopup.activeDialog) {
                PopupUtils.close(testNotificationPopup.activeDialog);
            }
            testNotificationPopup.activeDialog = null;
            testNotificationPopup.closed();
        }
    }

    TestCase {
        name: "NotificationPopupTests"
        when: windowShown

        function init() {
            if (testNotificationPopup.activeDialog) {
                PopupUtils.close(testNotificationPopup.activeDialog);
                testNotificationPopup.activeDialog = null;
            }
            wait(100);
            testNotificationPopup.type = "info";
            testNotificationPopup.titleText = "Notice";
            testNotificationPopup.messageText = "Something happened.";
            closedSpy.clear();
        }

        function cleanup() {
            if (testNotificationPopup.activeDialog) {
                PopupUtils.close(testNotificationPopup.activeDialog);
                testNotificationPopup.activeDialog = null;
            }
            wait(100);
            closedSpy.clear();
        }

        function test_initialProperties() {
            compare(testNotificationPopup.type, "info");
            compare(testNotificationPopup.titleText, "Notice");
            compare(testNotificationPopup.messageText, "Something happened.");
            compare(testNotificationPopup.activeDialog, null);
            compare(testNotificationPopup.isOpen, false);
            compare(closedSpy.count, 0);
        }

        function test_propertyUpdates() {
            testNotificationPopup.titleText = "Error Alert";
            testNotificationPopup.messageText = "Could not sync data with server.";
            testNotificationPopup.type = "error";

            compare(testNotificationPopup.titleText, "Error Alert");
            compare(testNotificationPopup.messageText, "Could not sync data with server.");
            compare(testNotificationPopup.type, "error");
        }

        function test_openUpdatesParametersAndSetsIsOpen() {
            var dlg = testNotificationPopup.open("Success", "Task completed!", "success");
            verify(dlg !== null);
            compare(testNotificationPopup.titleText, "Success");
            compare(testNotificationPopup.messageText, "Task completed!");
            compare(testNotificationPopup.type, "success");
            compare(testNotificationPopup.isOpen, true);

            PopupUtils.close(dlg);
            testNotificationPopup.activeDialog = null;
        }

        function test_dismissEmitsClosedSignalAndResetsIsOpen() {
            var dlg = testNotificationPopup.open("Confirmation", "Action succeeded", "info");
            verify(dlg !== null);
            compare(testNotificationPopup.isOpen, true);

            PopupUtils.close(dlg);
            testNotificationPopup.activeDialog = null;
            testNotificationPopup.closed();

            compare(closedSpy.count, 1);
            compare(testNotificationPopup.isOpen, false);
            compare(testNotificationPopup.activeDialog, null);
        }

        function test_timeoutAutoDismiss() {
            var dlg = testNotificationPopup.open("Auto-Dismiss", "This notification expires shortly", "warning");
            verify(dlg !== null);
            compare(testNotificationPopup.isOpen, true);

            autoDismissTimer.start();

            tryCompare(closedSpy, "count", 1, 1000);
            compare(testNotificationPopup.isOpen, false);
        }

        function test_openReturnsExistingDialogWhenAlreadyOpen() {
            var firstDlg = testNotificationPopup.open("First", "Message 1", "info");
            var secondDlg = testNotificationPopup.open("Second", "Message 2", "warning");

            compare(firstDlg, secondDlg);
            PopupUtils.close(firstDlg);
            testNotificationPopup.activeDialog = null;
        }

        function test_supportedNotificationTypes() {
            var types = ["info", "success", "warning", "error"];
            for (var i = 0; i < types.length; i++) {
                testNotificationPopup.type = types[i];
                compare(testNotificationPopup.type, types[i]);
            }
        }
    }
}
