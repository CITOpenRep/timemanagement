import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components/system"

Item {
    id: testRoot
    width: units.gu(50)
    height: units.gu(40)

    ModelDownloadTimerWidget {
        id: testWidget
    }

    TestCase {
        name: "ModelDownloadTimerWidgetTests"
        when: windowShown

        function init() {
            testWidget.stopSync();
        }

        function cleanup() {
            testWidget.stopSync();
        }

        function test_initialProperties() {
            compare(testWidget.enableTimesheetTimer, false);
            compare(testWidget.rotateIcon, false);
            compare(testWidget.defaultSyncTitle, "Voice Model Download");
            compare(testWidget.defaultSyncingSubtitle, "Downloading...");
            compare(testWidget.syncSuccessSubtitle, "Installation complete!");
            compare(testWidget.defaultSyncFailedText, "Download failed");
            compare(testWidget.isSyncing, false);
            compare(testWidget.syncProgress, 0.0);
        }

        function test_startDownloadViaSync() {
            testWidget.startSync(1, "Whisper Tiny Model");

            compare(testWidget.isSyncing, true);
            compare(testWidget.syncAccountId, 1);
            compare(testWidget.syncAccountName, "Whisper Tiny Model");
            compare(testWidget.syncProgress, 0.0);
            compare(testWidget.visible, true);
        }

        function test_handleDownloadProgressStages() {
            testWidget.startSync(1, "Whisper Tiny Model");

            testWidget.handleDownloadEvent({ event: "download_progress", payload: 10 });
            compare(testWidget.syncProgress, 0.10);

            testWidget.handleDownloadEvent({ event: "download_progress", payload: 50 });
            compare(testWidget.syncProgress, 0.50);

            testWidget.handleDownloadEvent({ event: "download_progress", payload: 90 });
            compare(testWidget.syncProgress, 0.90);

            testWidget.handleDownloadEvent({ event: "download_progress", payload: 99 });
            compare(testWidget.syncProgress, 0.99);
        }

        function test_updateSyncMessageProgression() {
            testWidget.startSync(1, "Model");

            testWidget.syncProgress = 0.10;
            testWidget.updateSyncMessage();
            compare(testWidget.syncStatusMessage, "Initializing download...");

            testWidget.syncProgress = 0.40;
            testWidget.updateSyncMessage();
            compare(testWidget.syncStatusMessage, "Downloading model files...");

            testWidget.syncProgress = 0.85;
            testWidget.updateSyncMessage();
            compare(testWidget.syncStatusMessage, "Extracting and installing...");

            testWidget.syncProgress = 0.98;
            testWidget.updateSyncMessage();
            compare(testWidget.syncStatusMessage, "Installation complete!");
        }

        function test_handleDownloadMessageCustomText() {
            testWidget.startSync(1, "Model");

            testWidget.handleDownloadEvent({
                event: "download_message",
                payload: "Extracting ggml-tiny.bin..."
            });

            compare(testWidget.syncStatusMessage, "Extracting ggml-tiny.bin...");
        }

        function test_handleDownloadCompletedSuccess() {
            testWidget.startSync(1, "Model");

            testWidget.handleDownloadEvent({ event: "download_completed" });

            compare(testWidget.syncSuccessful, true);
            compare(testWidget.syncFailed, false);
            compare(testWidget.syncProgress, 1.0);
            compare(testWidget.syncStatusMessage, "Installation complete!");
        }

        function test_handleDownloadErrorFailure() {
            testWidget.startSync(1, "Model");

            testWidget.handleDownloadEvent({
                event: "download_error",
                payload: "Checksum verification failed"
            });

            compare(testWidget.syncFailed, true);
            compare(testWidget.syncSuccessful, false);
            verify(testWidget.syncStatusMessage.indexOf("Checksum verification failed") !== -1);
        }

        function test_stopSyncCancelsDownload() {
            testWidget.startSync(1, "Model");
            testWidget.handleDownloadEvent({ event: "download_progress", payload: 50 });
            compare(testWidget.isSyncing, true);

            // Cancel action
            testWidget.stopSync();

            compare(testWidget.isSyncing, false);
            compare(testWidget.syncProgress, 0.0);
            compare(testWidget.syncSuccessful, false);
            compare(testWidget.syncFailed, false);
            compare(testWidget.visible, false);
        }
    }
}
