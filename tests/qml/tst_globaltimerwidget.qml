import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components/system"

Item {
    width: units.gu(50)
    height: units.gu(70)

    GlobalTimerWidget {
        id: testTimer
    }

    SignalSpy {
        id: syncTimedOutSpy
        target: testTimer
        signalName: "syncTimedOut"
    }

    SignalSpy {
        id: timerStartedSpy
        target: testTimer
        signalName: "timerStarted"
    }

    SignalSpy {
        id: timerStoppedSpy
        target: testTimer
        signalName: "timerStopped"
    }

    SignalSpy {
        id: timerPausedSpy
        target: testTimer
        signalName: "timerPaused"
    }

    SignalSpy {
        id: timerResumedSpy
        target: testTimer
        signalName: "timerResumed"
    }

    TestCase {
        name: "GlobalTimerWidgetTests"
        when: windowShown

        function init() {
            testTimer.stopSync();
            syncTimedOutSpy.clear();
            timerStartedSpy.clear();
            timerStoppedSpy.clear();
            timerPausedSpy.clear();
            timerResumedSpy.clear();
        }

        function test_initialProperties() {
            compare(testTimer.enableTimesheetTimer, true);
            compare(testTimer.isTimerRunning, false);
            compare(testTimer.isTimerPaused, false);
            compare(testTimer.isSyncing, false);
            compare(testTimer.syncProgress, 0.0);
            compare(testTimer.syncAccountId, -1);
            compare(testTimer.syncAccountName, "");
            compare(testTimer.syncSuccessful, false);
            compare(testTimer.syncFailed, false);
            compare(testTimer.syncStatusMessage, "");
            compare(testTimer.activeTitle, "/");
            compare(testTimer.activeTime, "00:00:00");
        }

        function test_startSyncExplicitAccountName() {
            testTimer.startSync(101, "Production Account");

            compare(testTimer.isSyncing, true);
            compare(testTimer.syncAccountId, 101);
            compare(testTimer.syncAccountName, "Production Account");
            compare(testTimer.syncProgress, 0.0);
            compare(testTimer.syncSuccessful, false);
            compare(testTimer.syncFailed, false);
            compare(testTimer.syncStatusMessage, "Starting sync...");
            compare(testTimer.visible, true);
        }

        function test_startSyncDefaultAccountNameFallback() {
            testTimer.startSync(202, "");

            compare(testTimer.isSyncing, true);
            compare(testTimer.syncAccountId, 202);
            compare(testTimer.syncAccountName, "Account 202");
        }

        function test_handleSyncProgressStages() {
            testTimer.startSync(101, "Production Account");

            testTimer.handleSyncEvent({ event: "sync_progress", payload: 20 });
            compare(testTimer.syncProgress, 0.20);

            testTimer.handleSyncEvent({ event: "sync_progress", payload: 45 });
            compare(testTimer.syncProgress, 0.45);

            testTimer.handleSyncEvent({ event: "sync_progress", payload: 85 });
            compare(testTimer.syncProgress, 0.85);

            testTimer.handleSyncEvent({ event: "sync_progress", payload: 95 });
            compare(testTimer.syncProgress, 0.95);
        }

        function test_handleSyncMessageUpdatesStatus() {
            testTimer.startSync(101, "Production Account");

            testTimer.handleSyncEvent({ event: "sync_message", payload: "Pulling latest work items..." });
            compare(testTimer.syncStatusMessage, "Pulling latest work items...");
        }

        function test_handleSyncCompletedSuccess() {
            testTimer.startSync(101, "Production Account");

            testTimer.handleSyncEvent({ event: "sync_completed", payload: true });
            compare(testTimer.syncSuccessful, true);
            compare(testTimer.syncFailed, false);
            compare(testTimer.syncProgress, 1.0);
            compare(testTimer.syncStatusMessage, testTimer.syncSuccessSubtitle);
        }

        function test_handleSyncCompletedFailure() {
            testTimer.startSync(101, "Production Account");

            testTimer.handleSyncEvent({ event: "sync_completed", payload: false });
            compare(testTimer.syncSuccessful, false);
            compare(testTimer.syncFailed, true);
            compare(testTimer.syncStatusMessage, testTimer.defaultSyncFailedText);
        }

        function test_handleSyncErrorCustomMessage() {
            testTimer.startSync(101, "Production Account");

            testTimer.handleSyncEvent({ event: "sync_error", payload: "Connection reset by peer" });
            compare(testTimer.syncFailed, true);
            compare(testTimer.syncSuccessful, false);
            verify(testTimer.syncStatusMessage.indexOf("Connection reset by peer") !== -1);
        }

        function test_stopSyncResetsAllSyncState() {
            testTimer.startSync(101, "Production Account");
            testTimer.handleSyncEvent({ event: "sync_progress", payload: 50 });

            testTimer.stopSync();

            compare(testTimer.isSyncing, false);
            compare(testTimer.syncSuccessful, false);
            compare(testTimer.syncFailed, false);
            compare(testTimer.syncProgress, 0.0);
            compare(testTimer.syncAccountId, -1);
            compare(testTimer.syncAccountName, "");
            compare(testTimer.syncStatusMessage, "");
            compare(testTimer.visible, false);
        }

        function test_syncTimedOutSignalEmission() {
            testTimer.syncTimedOut(303);

            compare(syncTimedOutSpy.count, 1);
            compare(syncTimedOutSpy.signalArguments[0][0], 303);
        }

        function test_timerLifecycleSignalSpies() {
            testTimer.timerStarted();
            testTimer.timerPaused();
            testTimer.timerResumed();
            testTimer.timerStopped();

            compare(timerStartedSpy.count, 1);
            compare(timerPausedSpy.count, 1);
            compare(timerResumedSpy.count, 1);
            compare(timerStoppedSpy.count, 1);
        }
    }
}
