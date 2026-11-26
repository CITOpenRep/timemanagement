/*
 * MIT License
 *
 * Copyright (c) 2026 CIT-Services
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import QtQuick 2.7

QtObject {
    id: root

    property int revision: 0
    property var _states: ({})
    property var _bridge: null
    property bool _bridgeConnected: false
    property int _syncedTtlMs: 300000

    function _makeKey(accountId, modelName, localId) {
        return String(Number(accountId)) + ":" + String(modelName || "") + ":" + String(Number(localId));
    }

    function _pruneExpiredSynced(stateMap, nowMs) {
        var next = {};
        var cutoff = nowMs - root._syncedTtlMs;
        for (var key in stateMap) {
            if (!stateMap.hasOwnProperty(key)) {
                continue;
            }
            var entry = stateMap[key];
            if (!entry) {
                continue;
            }
            if (entry.state === "synced" && entry.updatedAt && entry.updatedAt < cutoff) {
                continue;
            }
            next[key] = entry;
        }
        return next;
    }

    function connectToBridge(bridge) {
        if (!bridge) {
            return;
        }
        _bridge = bridge;
        if (!_bridgeConnected) {
            _bridgeConnected = true;
            bridge.messageReceived.connect(function (evt) {
                root.handleEvent(evt);
            });
            bridge.readyChanged.connect(function () {
                if (bridge.ready) {
                    root.hydrate(-1);
                }
            });
        }
        if (bridge.ready) {
            hydrate(-1);
        }
    }

    function hydrate(accountId) {
        if (!_bridge || !_bridge.ready) {
            return;
        }
        var targetAcc = (accountId !== undefined && accountId !== null) ? Number(accountId) : -1;
        _bridge.call("backend.resolve_qml_db_path", ["ubtms"], function (dbPath) {
            var resolved = dbPath || "app_settings.db";
            _bridge.call("backend.get_sync_queue_items", [resolved, targetAcc], function (items) {
                applyHydratedItems(items || [], targetAcc);
            });
        });
    }

    function applyHydratedItems(items, accountId) {
        var now = Date.now();
        var scopeAcc = (accountId !== undefined && accountId !== null) ? Number(accountId) : -1;
        var activeKeys = {};
        var i;

        for (i = 0; i < items.length; i++) {
            var row = items[i];
            if (!row || !row.model_name || row.local_id === undefined) {
                continue;
            }
            var k = _makeKey(row.account_id, row.model_name, row.local_id);
            activeKeys[k] = {
                accountId: Number(row.account_id),
                modelName: String(row.model_name),
                localId: Number(row.local_id),
                state: String(row.state || "pending"),
                error: String(row.error || ""),
                nextRetryAt: String(row.next_retry_at || ""),
                updatedAt: now
            };
        }

        var merged = {};
        var cutoff = now - root._syncedTtlMs;
        for (var oldKey in _states) {
            if (!_states.hasOwnProperty(oldKey)) {
                continue;
            }
            var oldEntry = _states[oldKey];
            if (!oldEntry || activeKeys.hasOwnProperty(oldKey)) {
                continue;
            }
            var inScope = (scopeAcc < 0 || oldEntry.accountId === scopeAcc);
            if (oldEntry.state === "synced") {
                if (!oldEntry.updatedAt || oldEntry.updatedAt >= cutoff) {
                    merged[oldKey] = oldEntry;
                }
            } else if (!inScope) {
                merged[oldKey] = oldEntry;
            } else {
                // Active queue item no longer exists in sync_queue -> override stale ListModels as synced
                merged[oldKey] = {
                    accountId: oldEntry.accountId,
                    modelName: oldEntry.modelName,
                    localId: oldEntry.localId,
                    state: "synced",
                    error: "",
                    nextRetryAt: "",
                    updatedAt: now
                };
            }
        }

        for (var activeKey in activeKeys) {
            if (activeKeys.hasOwnProperty(activeKey)) {
                merged[activeKey] = activeKeys[activeKey];
            }
        }

        _states = merged;
        revision += 1;
    }

    function setItemState(accountId, modelName, localId, state, errorText, nextRetryAt) {
        if (accountId === undefined || accountId === null || Number(accountId) <= 0) {
            return;
        }
        if (!modelName || localId === undefined || localId === null || Number(localId) <= 0) {
            return;
        }
        var now = Date.now();
        var next = _pruneExpiredSynced(_states, now);
        var key = _makeKey(accountId, modelName, localId);
        next[key] = {
            accountId: Number(accountId),
            modelName: String(modelName),
            localId: Number(localId),
            state: String(state || "pending"),
            error: String(errorText || ""),
            nextRetryAt: String(nextRetryAt || ""),
            updatedAt: now
        };
        _states = next;
        revision += 1;
    }

    function markPending(accountId, modelName, localId) {
        setItemState(accountId, modelName, localId, "pending", "", "");
    }

    function markSynced(accountId, modelName, localId) {
        setItemState(accountId, modelName, localId, "synced", "", "");
    }

    function handleEvent(evt) {
        if (!evt || !evt.event) {
            return;
        }
        if (evt.event === "queue_item_state" && evt.payload) {
            var p = evt.payload;
            setItemState(
                p.account_id,
                p.model_name,
                p.local_id,
                p.state,
                p.error,
                p.next_retry_at
            );
        } else if (evt.event === "sync_completed" && evt.payload === true) {
            hydrate(-1);
        } else if (evt.event === "queue_synced") {
            _states = _pruneExpiredSynced(_states, Date.now());
        }
    }

    function resolveBadgeState(accountId, modelName, localId, rawStatus, hasDraft, rev) {
        var _dep = revision;
        if (hasDraft || accountId === undefined || accountId === null || Number(accountId) <= 0) {
            return "none";
        }
        if (modelName && localId !== undefined && localId !== null && Number(localId) > 0) {
            var entry = _states[_makeKey(accountId, modelName, localId)];
            if (entry) {
                if (entry.state === "synced") {
                    return "none";
                }
                if (
                    entry.state === "pending" ||
                    entry.state === "in_flight" ||
                    entry.state === "failed" ||
                    entry.state === "conflict"
                ) {
                    return entry.state;
                }
            }
        }
        if (rawStatus === "updated" || rawStatus === "new" || rawStatus === "created") {
            return "pending";
        }
        return "none";
    }

    function getErrorText(accountId, modelName, localId, rev) {
        var _dep = revision;
        if (!modelName || accountId === undefined || accountId === null || localId === undefined || localId === null) {
            return "";
        }
        var entry = _states[_makeKey(accountId, modelName, localId)];
        if (entry && (entry.state === "failed" || entry.state === "conflict")) {
            return entry.error || "";
        }
        return "";
    }
}
