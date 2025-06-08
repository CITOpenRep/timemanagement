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
import QtQuick.Controls 2.2
import "../../models/constants.js" as AppConst

Rectangle {
    id: bellWidget
    anchors {
        top: parent.top
        horizontalCenter: parent.horizontalCenter
        topMargin: units.gu(0.5)
    }
    color: AppConst.Colors.Button
    radius: width / 2
    width: units.gu(5)
    height: units.gu(5)
    z: 999  // keep it on top

    property int notificationCount: 0
    signal clicked

    Text {
        id: bellIcon
        text: "🔔"   // or just "🔔"
        font.pixelSize: units.gu(3)
        anchors.centerIn: parent
        color: "white"
    }

    // Notification Badge
    // Notification Badge
    Rectangle {
        visible: notificationCount > 0
        width: units.gu(3)
        height: units.gu(3)
        radius: width / 2
        color: "red"
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: -units.gu(0.5)
        border.color: "white"
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: notificationCount > 9 ? "9+" : notificationCount
            color: "white"
            font.pixelSize: units.gu(2)
            font.bold: true
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: bellWidget.clicked()
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
    }
}
