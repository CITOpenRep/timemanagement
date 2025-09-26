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

    // Icon properties
    property string iconName: ""  // Built-in symbolic icon name (e.g., "add", "edit", "delete")
    property string iconSource: ""  // Path to custom icon image file
    property color iconColor: root.fgColor  // Icon color (for colorized icons)
    property real iconSize: units.gu(1.5)  // Icon size
    property bool iconBold: false  // Make icon appear bolder (increases size and adjusts appearance)
    property int spacing: units.gu(1)  // Spacing between icon and text

    // Customizable colors
    property color bgColor: (enabled) ? AppConst.Colors.Button : AppConst.Colors.ButtonDisabled
    property color fgColor: AppConst.Colors.ButtonText
    property color hoverColor: AppConst.Colors.ButtonHover  // fallback hover
    property color borderColor: "transparent" // Default border color
    property int radius: units.gu(0.8)

    Rectangle {
        id: buttonRect
        anchors.fill: parent
        anchors.margins: units.gu(0.25)
        radius: root.radius
        color: mouseArea.containsMouse ? root.hoverColor : root.bgColor
        border.color: root.borderColor

        Row {
            id: contentRow
            anchors.centerIn: parent
            spacing: root.spacing

            // Built-in icon using Lomiri Icon component
            Icon {
                id: builtinIcon
                visible: root.iconName !== ""
                name: root.iconName
                width: visible ? (root.iconBold ? root.iconSize * 1.2 : root.iconSize) : 0
                height: visible ? (root.iconBold ? root.iconSize * 1.2 : root.iconSize) : 0
                anchors.verticalCenter: parent.verticalCenter
                color: root.iconBold ? Qt.darker(root.iconColor, 0.8) : root.iconColor
            }

            // Custom icon using Image component
            Image {
                id: customIcon
                visible: root.iconSource !== "" && root.iconName === ""
                source: root.iconSource
                width: visible ? (root.iconBold ? root.iconSize * 1.2 : root.iconSize) : 0
                height: visible ? (root.iconBold ? root.iconSize * 1.2 : root.iconSize) : 0
                anchors.verticalCenter: parent.verticalCenter
                opacity: root.iconBold ? 1.0 : 0.9  // Slightly more opaque when bold
                // Optional: Add color overlay for monochrome icons
                // ColorOverlay {
                //     anchors.fill: parent
                //     source: parent
                //     color: root.iconBold ? Qt.darker(root.iconColor, 0.8) : root.iconColor
                //     visible: root.iconSource !== "" && root.iconColor !== "transparent"
                // }
            }

            Text {
                id: label
                anchors.verticalCenter: parent.verticalCenter
                color: root.fgColor
                font.bold: false
                font.pixelSize: units.gu(1.5)
                visible: text !== ""
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.clicked()
        }
    }
}
