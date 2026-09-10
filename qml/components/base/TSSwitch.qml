/*
 * MIT License
 *
 * Copyright (c) 2025 CIT-Services
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

Item {
    id: root

    implicitWidth: units.gu(4.2)
    implicitHeight: units.gu(2.1)

    property bool checked: false
    property bool enabled: true
    property bool interactive: true
    property color checkedColor: Qt.darker(LomiriColors.orange, 1.35)
    property color uncheckedColor: "#35ffffff"
    property color thumbColor: "white"
    property color checkedBorderColor: "transparent"
    property color uncheckedBorderColor: "#40ffffff"
    property color borderColor: root.checked ? checkedBorderColor : uncheckedBorderColor
    property int borderWidth: root.checked ? 0 : units.dp(1)

    signal clicked()
    signal toggled(bool checked)

    opacity: root.enabled ? 1.0 : 0.6

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? root.checkedColor : root.uncheckedColor
        border.color: root.borderColor
        border.width: root.borderWidth

        Behavior on color {
            ColorAnimation { duration: 150 }
        }

        Rectangle {
            id: thumb
            width: parent.height - units.dp(4)
            height: width
            radius: width / 2
            color: root.thumbColor
            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? (parent.width - width - units.dp(2)) : units.dp(2)

            Behavior on x {
                NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled && root.interactive
        visible: root.interactive
        cursorShape: (root.enabled && root.interactive) ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            root.clicked();
            root.toggled(!root.checked);
        }
    }
}
