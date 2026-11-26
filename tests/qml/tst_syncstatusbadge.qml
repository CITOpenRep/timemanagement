import QtQuick 2.12
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/app"
import "../../qml/components"

Item {
    id: root
    width: units.gu(40)
    height: units.gu(20)

    SyncStateStore {
        id: store
    }

    SyncStatusBadge {
        id: liveBadge
        syncStateStore: store
        accountId: 10
        modelName: "project.task"
        localId: 42
        rawStatus: "updated"
        hasDraft: false
    }

    SyncStatusBadge {
        id: fallbackBadge
        syncStateStore: null
        accountId: 10
        modelName: "project.task"
        localId: 42
        rawStatus: "updated"
        hasDraft: false
    }

    TestCase {
        name: "SyncStatusBadgeTests"
        when: windowShown

        function init() {
            store._states = ({});
            store.revision += 1;
            liveBadge.accountId = 10;
            liveBadge.modelName = "project.task";
            liveBadge.localId = 42;
            liveBadge.rawStatus = "updated";
            liveBadge.hasDraft = false;
        }

        function test_storeTransitionsUpdateBadgeWithoutRebuild() {
            compare(liveBadge.badgeState, "pending");
            compare(liveBadge.visible, true);

            store.handleEvent({
                "event": "queue_item_state",
                "payload": {
                    "account_id": 10,
                    "model_name": "project.task",
                    "local_id": 42,
                    "state": "in_flight"
                }
            });
            compare(liveBadge.badgeState, "in_flight");
            compare(liveBadge.isUploading, true);
            compare(liveBadge.visible, true);

            store.handleEvent({
                "event": "queue_item_state",
                "payload": {
                    "account_id": 10,
                    "model_name": "project.task",
                    "local_id": 42,
                    "state": "synced"
                }
            });
            // Cleared even though stale ListModel row still holds rawStatus = "updated"
            compare(liveBadge.badgeState, "none");
            compare(liveBadge.visible, false);
        }

        function test_errorConflictAndMidflightRequeueStates() {
            store.handleEvent({
                "event": "queue_item_state",
                "payload": {
                    "account_id": 10,
                    "model_name": "project.task",
                    "local_id": 42,
                    "state": "failed",
                    "error": "Missing required field"
                }
            });
            compare(liveBadge.badgeState, "failed");
            compare(liveBadge.isError, true);
            compare(liveBadge.errorText, "Missing required field");

            store.handleEvent({
                "event": "queue_item_state",
                "payload": {
                    "account_id": 10,
                    "model_name": "project.task",
                    "local_id": 42,
                    "state": "conflict",
                    "error": "Deleted remotely"
                }
            });
            compare(liveBadge.badgeState, "conflict");
            compare(liveBadge.isError, true);
            compare(liveBadge.errorText, "Deleted remotely");

            store.markPending(10, "project.task", 42);
            compare(liveBadge.badgeState, "pending");
            compare(liveBadge.isError, false);
            compare(liveBadge.errorText, "");
        }

        function test_hydrateReconcilesRemovedQueueEntries() {
            store.applyHydratedItems([
                {
                    "account_id": 10,
                    "model_name": "project.task",
                    "local_id": 42,
                    "state": "in_flight",
                    "error": "",
                    "next_retry_at": ""
                }
            ], 10);
            compare(liveBadge.badgeState, "in_flight");

            store.applyHydratedItems([], 10);
            compare(liveBadge.badgeState, "none");
            compare(liveBadge.visible, false);
        }

        function test_localAccountAndDraftSuppressBadge() {
            store.markPending(10, "project.task", 42);
            compare(liveBadge.badgeState, "pending");

            liveBadge.hasDraft = true;
            compare(liveBadge.badgeState, "none");

            liveBadge.hasDraft = false;
            liveBadge.accountId = 0;
            compare(liveBadge.badgeState, "none");
        }

        function test_standaloneFallbackWithoutStore() {
            compare(fallbackBadge.badgeState, "pending");
            compare(fallbackBadge.visible, true);

            fallbackBadge.rawStatus = "";
            compare(fallbackBadge.badgeState, "none");
            compare(fallbackBadge.visible, false);
        }
    }
}
