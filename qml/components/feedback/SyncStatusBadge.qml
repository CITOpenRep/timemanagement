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

import QtQuick 2.12
import Lomiri.Components 1.3

Rectangle {
    id: badge

    objectName: "pendingSyncIndicator"

    property var syncStateStore: (typeof mainView !== "undefined" && mainView && mainView.syncStateStore) ? mainView.syncStateStore : null
    property int accountId: -1
    property string modelName: ""
    property int localId: -1
    property string rawStatus: ""
    property bool hasDraft: false

    readonly property int _storeRevision: syncStateStore ? syncStateStore.revision : 0
    readonly property string badgeState: {
        if (syncStateStore) {
            return syncStateStore.resolveBadgeState(accountId, modelName, localId, rawStatus, hasDraft, _storeRevision);
        }
        if (!hasDraft && accountId > 0 && (rawStatus === "updated" || rawStatus === "new" || rawStatus === "created")) {
            return "pending";
        }
        return "none";
    }
    readonly property string errorText: syncStateStore ? syncStateStore.getErrorText(accountId, modelName, localId, _storeRevision) : ""
    readonly property bool isDark: typeof theme !== "undefined" && theme && theme.name === "Ubuntu.Components.Themes.SuruDark"
    readonly property bool isUploading: badgeState === "in_flight"
    readonly property bool isError: badgeState === "failed" || badgeState === "conflict"

    visible: badgeState !== "none"
    width: visible ? badgeRow.width + units.gu(1.2) : 0
    height: visible ? units.gu(2) : 0
    radius: height / 2

    color: isError
        ? (isDark ? "#331616" : "#FFEBEE")
        : (isUploading ? (isDark ? "#132933" : "#E1F5FE") : (isDark ? "#2C2210" : "#FFF8E1"))
    border.color: isError ? "#E53935" : (isUploading ? "#0288D1" : "#FFA000")
    border.width: units.gu(0.12)

    Row {
        id: badgeRow
        spacing: units.gu(0.3)
        anchors.centerIn: parent

        Icon {
            id: badgeIcon
            name: badge.isError ? "warning" : "sync"
            width: units.gu(1.2)
            height: units.gu(1.2)
            color: badge.isError
                ? (badge.isDark ? "#FF8A80" : "#C62828")
                : (badge.isUploading ? (badge.isDark ? "#4FC3F7" : "#0277BD") : "#E65100")
            anchors.verticalCenter: parent.verticalCenter

            RotationAnimation on rotation {
                running: badge.visible && badge.isUploading
                loops: Animation.Infinite
                from: 0
                to: 360
                duration: 900
                onRunningChanged: {
                    if (!running) {
                        badgeIcon.rotation = 0;
                    }
                }
            }
        }

        Text {
            id: badgeLabel
            text: {
                if (badge.badgeState === "in_flight") return i18n.dtr("ubtms", "Syncing");
                if (badge.badgeState === "conflict") return i18n.dtr("ubtms", "Conflict");
                if (badge.badgeState === "failed") return i18n.dtr("ubtms", "Failed");
                if (badge.badgeState === "pending") return i18n.dtr("ubtms", "Pending");
                return "";
            }
            font.pixelSize: units.gu(1.0)
            font.bold: true
            color: badge.isError
                ? (badge.isDark ? "#FF8A80" : "#C62828")
                : (badge.isUploading ? (badge.isDark ? "#4FC3F7" : "#0277BD") : "#E65100")
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
