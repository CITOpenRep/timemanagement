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
    width: buttonSize
    height: buttonSize

    // Customization API
    property string iconName: ""          // symbolic icon name
    property string iconText: "+"         // fallback if iconName is not set
    property int buttonSize: units.gu(5)
    
    property int iconSize: units.gu(3)
    property bool iconBold: true

    property color bgColor: AppConst.Colors.Button
    property color fgColor: AppConst.Colors.ButtonText
    property color hoverColor: Qt.darker(bgColor, 1.2)
    property int radius: width / 2

    signal clicked

    Rectangle {
        id: buttonRect
        anchors.fill: parent
        color: mouseArea.containsMouse ? root.hoverColor : root.bgColor
        radius: root.radius

        // Show icon if iconName is provided
        // Image {
        //     visible: root.iconName !== ""
        //     source: "image://theme/" + root.iconName
        //     anchors.centerIn: parent
        //     width: units.gu(3)
           
        //     height: units.gu(3)
        //     fillMode: Image.PreserveAspectFit
        // }

        Icon {
            visible: root.iconName !== ""
            name: root.iconName
            anchors.centerIn: parent
            width: root.iconSize
            height: root.iconSize
            color: root.fgColor
           // font.bold: root.iconBold
        }

        // Fallback to text if no iconName
        Text {
            visible: root.iconName === ""
            text: root.iconText
            anchors.centerIn: parent
            color: root.fgColor
            font.pixelSize: root.iconSize
            font.bold: root.iconBold
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.clicked()
        }
    }
}
