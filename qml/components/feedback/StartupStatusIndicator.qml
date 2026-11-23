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
import Lomiri.Components 1.3

Rectangle {
    id: root

    property var startupManager: null
    readonly property bool active: startupManager ? startupManager.isStartingUp : false
    readonly property string statusText: startupManager ? startupManager.statusMessage : ""
    readonly property bool isComplete: startupManager ? startupManager.isStartupComplete : false
    readonly property bool isFailed: startupManager ? startupManager.syncFailed : false
    readonly property real progress: startupManager ? startupManager.syncProgress : 0.0

    anchors.top: parent ? parent.top : undefined
    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
    anchors.topMargin: active ? units.gu(6.8) : units.gu(4.5)

    height: units.gu(3.8)
    width: Math.max(units.gu(16), contentRow.implicitWidth + units.gu(3.6))
    radius: height / 2
    z: 99999
    enabled: false

    color: (theme && theme.name === "Ubuntu.Components.Themes.SuruDark") ? Qt.rgba(0.12, 0.12, 0.14, 0.96) : Qt.rgba(0.15, 0.15, 0.18, 0.94)
    border.color: root.isFailed ? Qt.rgba(0.95, 0.35, 0.25, 0.7) : (root.isComplete ? Qt.rgba(0.3, 0.85, 0.4, 0.7) : Qt.rgba(1.0, 1.0, 1.0, 0.32))
    border.width: units.dp(1.5)

    opacity: active ? 1.0 : 0.0
    visible: opacity > 0.0

    Behavior on opacity {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }
    }

    Behavior on anchors.topMargin {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }
    }

    // Subtle drop shadow for separation against light/dark background content
    Rectangle {
        anchors.fill: parent
        anchors.topMargin: units.dp(2)
        radius: parent.radius
        color: Qt.rgba(0, 0, 0, 0.35)
        z: -1
    }

    Row {
        id: contentRow
        anchors.centerIn: parent
        anchors.verticalCenterOffset: progressTrack.visible ? -units.dp(1) : 0
        spacing: units.gu(1.0)

        ActivityIndicator {
            id: spinner
            anchors.verticalCenter: parent.verticalCenter
            width: units.gu(2.0)
            height: units.gu(2.0)
            running: root.active && !root.isComplete && !root.isFailed
            visible: running
        }

        Icon {
            id: completeIcon
            name: "ok"
            width: units.gu(1.8)
            height: units.gu(1.8)
            color: "#4cd964"
            visible: root.isComplete && !root.isFailed
            anchors.verticalCenter: parent.verticalCenter
        }

        Icon {
            id: failedIcon
            name: "warning"
            width: units.gu(1.8)
            height: units.gu(1.8)
            color: "#ff9500"
            visible: root.isFailed
            anchors.verticalCenter: parent.verticalCenter
        }

        Label {
            id: label
            text: root.statusText
            color: "white"
            fontSize: "medium"
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // Subtle progress strip along the bottom edge when sync progress is reported
    Rectangle {
        id: progressTrack
        anchors.bottom: parent.bottom
        anchors.bottomMargin: units.dp(3)
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.max(0, parent.width - units.gu(3))
        height: units.dp(2)
        radius: units.dp(1)
        color: Qt.rgba(1.0, 1.0, 1.0, 0.15)
        visible: root.active && !root.isComplete && !root.isFailed && root.progress > 0.0 && root.progress < 1.0

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * root.progress
            radius: parent.radius
            color: LomiriColors.orange
        }
    }
}
