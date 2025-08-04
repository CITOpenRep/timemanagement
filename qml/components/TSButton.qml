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
import Lomiri.Components 1.3
import "../../models/constants.js" as AppConst

Item {
    id: root
    width: parent ? parent.width : implicitWidth
    height: units.gu(5)

    property alias text: label.text
    property alias fontSize: label.font.pixelSize
    property alias fontBold: label.font.bold
    property bool enabled: true
    signal clicked

    // Customizable colors
    property color bgColor: (enabled) ? AppConst.Colors.Button : AppConst.Colors.ButtonDisabled
    property color fgColor: AppConst.Colors.ButtonText
    property color hoverColor: AppConst.Colors.ButtonHover  // fallback hover
    property int radius: units.gu(0.8)

    Rectangle {
        id: buttonRect
        anchors.fill: parent
        anchors.margins: units.gu(0.25)
        radius: root.radius
        color: mouseArea.containsMouse ? root.hoverColor : root.bgColor

        Text {
            id: label
            anchors.centerIn: parent
            color: root.fgColor
            font.bold: false
            font.pixelSize: units.gu(1.5)
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.clicked()
        }
    }
}
