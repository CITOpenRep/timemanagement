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

    anchors.top: parent ? parent.top : undefined
    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
    anchors.topMargin: active ? units.gu(1.4) : units.gu(0.4)

    height: units.gu(3.2)
    width: Math.max(units.gu(14), contentRow.implicitWidth + units.gu(2.8))
    radius: height / 2
    z: 99999
    enabled: false

    color: Qt.rgba(0.08, 0.08, 0.1, 0.88)
    border.color: Qt.rgba(1.0, 1.0, 1.0, 0.22)
    border.width: 1

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

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: units.gu(0.8)

        ActivityIndicator {
            id: spinner
            anchors.verticalCenter: parent.verticalCenter
            width: units.gu(1.8)
            height: units.gu(1.8)
            running: root.active && !root.isComplete
            visible: running
        }

        Icon {
            id: completeIcon
            name: "ok"
            width: units.gu(1.6)
            height: units.gu(1.6)
            color: "white"
            visible: root.isComplete
            anchors.verticalCenter: parent.verticalCenter
        }

        Label {
            id: label
            text: root.statusText
            color: "white"
            fontSize: "small"
            font.weight: Font.Medium
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
