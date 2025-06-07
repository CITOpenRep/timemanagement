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
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.0
import Lomiri.Components 1.3
import "../constants.js" as AppConst

Item {
    id: dialerMenu
    width: parent.width
    height: parent.height

    signal menuItemSelected(int index)

    property alias menuModel: repeater.model
    //property alias text: fab.text
    property bool expanded: false
    property int fabSize: units.gu(7)
    property int itemSize: units.gu(6)

    // Floating Action Button (FAB)
    TSIconButton {
        id: fab
        width: fabSize
        height: fabSize
        radius: width / 2
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 24
        iconName: "open-menu-symbolic"

        z: 10
        //text: "+"
        //fontSize: units.gu(3)

        onClicked: {
            console.log("FAB Click Detected");
            expanded = !expanded;
        }
    }

    // Professional vertical list menu
    Column {
        id: menuList
        visible: expanded
        spacing: 8
        anchors.right: fab.left
        anchors.bottom: fab.top
        anchors.margins: 12
        z: 9

        Repeater {
            id: repeater
            model: menuModel

            delegate: Rectangle {
                width: units.gu(17.5)
                height: units.gu(5)
                radius: units.gu(1)
                color: LomiriColors.orange
                //border.color: "#cccccc"
                //border.width: 1
                opacity: expanded ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }
                }

                Text {
                    text: modelData.label
                    anchors.centerIn: parent
                    font.pixelSize: units.gu(2)
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        expanded = false;
                        dialerMenu.menuItemSelected(model.index);
                    }
                }
            }
        }
    }
}
