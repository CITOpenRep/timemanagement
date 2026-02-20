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

/*
 * SettingsListItem - A clean, modern settings menu item with icon, label, and
 * optional progression chevron. Designed to match iOS/Material-style settings lists.
 *
 * Usage:
 *   SettingsListItem {
 *       iconName: "account-multiple"
 *       iconColor: "#0078d4"
 *       text: "Connected Accounts"
 *       onClicked: { ... }
 *   }
 */
Item {
    id: root

    width: parent ? parent.width : implicitWidth
    height: units.gu(7)

    // Public API
    property string text: ""
    property string iconName: ""
    property color iconColor: "#666"
    property bool showProgression: true
    property bool showDivider: true

    signal clicked()

    // Internal theming
    readonly property bool isDark: theme.name === "Ubuntu.Components.Themes.SuruDark"
    readonly property color bgColor: isDark ? "#1e1e1e" : "#ffffff"
    readonly property color bgPressedColor: isDark ? "#2a2a2a" : "#f0f0f0"
    readonly property color textColor: isDark ? "#e0e0e0" : "#333333"
    readonly property color dividerColor: isDark ? "#333333" : "#e8e8e8"
    readonly property color chevronColor: isDark ? "#666666" : "#c7c7cc"

    Rectangle {
        id: background
        anchors.fill: parent
        color: mouseArea.pressed ? root.bgPressedColor : root.bgColor

        Behavior on color {
            ColorAnimation { duration: 120 }
        }

        Row {
            anchors.fill: parent
            anchors.leftMargin: units.gu(2)
            anchors.rightMargin: units.gu(2)
            spacing: units.gu(2)

            // Icon container
            Item {
                width: units.gu(4)
                height: parent.height

                Icon {
                    anchors.centerIn: parent
                    name: root.iconName
                    width: units.gu(2.8)
                    height: units.gu(2.8)
                    color: root.iconColor
                }
            }

            // Label
            Item {
                width: parent.width - units.gu(4) - units.gu(3) - units.gu(6)  // icon + chevron + margins
                height: parent.height

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.text
                    font.pixelSize: units.gu(2)
                    color: root.textColor
                    elide: Text.ElideRight
                    width: parent.width
                }
            }

            // Chevron / progression indicator
            Item {
                width: units.gu(3)
                height: parent.height
                visible: root.showProgression

                Text {
                    anchors.centerIn: parent
                    text: "›"
                    font.pixelSize: units.gu(3)
                    color: root.chevronColor
                }
            }
        }

        // Bottom divider
        Rectangle {
            visible: root.showDivider
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: units.gu(8)  // Indent divider past icon area
            height: units.dp(1)
            color: root.dividerColor
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            onClicked: root.clicked()
        }
    }
}
