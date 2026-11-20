import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components/feedback"

MainView {
    id: testRoot
    width: units.gu(40)
    height: units.gu(70)

    QtObject {
        id: mockStartupManager
        property bool isStartingUp: false
        property bool isStartupComplete: false
        property string statusMessage: ""
        property real syncProgress: 0.0
        property bool syncFailed: false
    }

    StartupStatusIndicator {
        id: testIndicator
        startupManager: mockStartupManager
    }

    TestCase {
        name: "StartupStatusIndicatorTests"
        when: windowShown

        function findActivityIndicator(rootItem) {
            for (var i = 0; i < rootItem.children.length; i++) {
                var child = rootItem.children[i];
                if (child.running !== undefined) {
                    return child;
                }
                var sub = findActivityIndicator(child);
                if (sub) return sub;
            }
            return null;
        }

        function findStatusLabel(rootItem) {
            for (var i = 0; i < rootItem.children.length; i++) {
                var child = rootItem.children[i];
                if (child.text !== undefined && child.fontSize !== undefined) {
                    return child;
                }
                var sub = findStatusLabel(child);
                if (sub) return sub;
            }
            return null;
        }

        function findCompleteIcon(rootItem) {
            for (var i = 0; i < rootItem.children.length; i++) {
                var child = rootItem.children[i];
                if (child.name !== undefined && child.name === "ok") {
                    return child;
                }
                var sub = findCompleteIcon(child);
                if (sub) return sub;
            }
            return null;
        }

        function init() {
            mockStartupManager.isStartingUp = false;
            mockStartupManager.isStartupComplete = false;
            mockStartupManager.statusMessage = "";
            mockStartupManager.syncProgress = 0.0;
            mockStartupManager.syncFailed = false;
        }

        function test_initialProperties() {
            compare(testIndicator.active, false);
            compare(testIndicator.isComplete, false);
            compare(testIndicator.statusText, "");
            compare(testIndicator.enabled, false);
            compare(testIndicator.z, 99999);
        }

        function test_activeStateActivation() {
            mockStartupManager.isStartingUp = true;
            mockStartupManager.statusMessage = "Connecting...";

            compare(testIndicator.active, true);
            compare(testIndicator.statusText, "Connecting...");
            compare(testIndicator.opacity, 1.0);
            compare(testIndicator.visible, true);

            var spinner = findActivityIndicator(testIndicator);
            verify(spinner !== null, "ActivityIndicator spinner should exist");
            compare(spinner.running, true);
        }

        function test_statusMessageUpdate() {
            mockStartupManager.isStartingUp = true;
            mockStartupManager.statusMessage = "Connecting...";

            var label = findStatusLabel(testIndicator);
            verify(label !== null, "Status Label should exist");
            compare(label.text, "Connecting...");

            mockStartupManager.statusMessage = "Syncing...";
            compare(label.text, "Syncing...");
        }

        function test_completionStateTransition() {
            mockStartupManager.isStartingUp = true;
            mockStartupManager.isStartupComplete = true;
            mockStartupManager.statusMessage = "Updated";

            compare(testIndicator.isComplete, true);
            var spinner = findActivityIndicator(testIndicator);
            verify(spinner !== null);
            compare(spinner.running, false);

            var icon = findCompleteIcon(testIndicator);
            verify(icon !== null, "Checkmark icon should exist");
            compare(icon.visible, true);
        }

        function test_dismissalHidesIndicator() {
            mockStartupManager.isStartingUp = true;
            mockStartupManager.statusMessage = "Connecting...";
            compare(testIndicator.active, true);

            mockStartupManager.isStartingUp = false;
            compare(testIndicator.active, false);
            compare(testIndicator.opacity, 0.0);
        }

        function test_nonBlockingBehavior() {
            compare(testIndicator.enabled, false);
        }
    }
}
