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
 * SettingsToggleItem - A settings list item with an inline Switch toggle.
 * Shows icon, label, optional description, and a switch on the right side.
 *
 * Usage:
 *   SettingsToggleItem {
 *       iconName: "notification"
 *       iconColor: "#e67e22"
 *       text: "Notifications"
 *       description: "Receive push notifications"
 *       checked: true
 *       enabled: true
 *       onToggled: function(value) { saveSetting(value); }
 *   }
 */
Item {
    id: root

    width: parent ? parent.width : implicitWidth
    height: units.gu(8)

    // Public API
    property string text: ""
    property string description: ""
    property string iconName: ""
    property color iconColor: "#666"
    property bool checked: false
    property bool enabled: true
    property bool showDivider: true

    signal toggled(bool value)

    // Internal theming
    readonly property bool isDark: theme.name === "Ubuntu.Components.Themes.SuruDark"
    readonly property color bgColor: isDark ? "#1e1e1e" : "#ffffff"
    readonly property color textColor: isDark ? "#e0e0e0" : "#333333"
    readonly property color descColor: isDark ? "#999999" : "#888888"
    readonly property color disabledTextColor: isDark ? "#555555" : "#bbbbbb"
    readonly property color dividerColor: isDark ? "#333333" : "#e8e8e8"

    opacity: root.enabled ? 1.0 : 0.5

    Rectangle {
        id: background
        anchors.fill: parent
        color: root.bgColor

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
                    color: root.enabled ? root.iconColor : root.disabledTextColor
                }
            }

            // Label + description column
            Item {
                width: parent.width - units.gu(4) - units.gu(8) - units.gu(6)  // icon + switch area + margins
                height: parent.height

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    spacing: units.gu(0.3)

                    Text {
                        text: root.text
                        font.pixelSize: units.gu(2)
                        color: root.enabled ? root.textColor : root.disabledTextColor
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    Text {
                        visible: root.description !== ""
                        text: root.description
                        font.pixelSize: units.gu(1.3)
                        color: root.enabled ? root.descColor : root.disabledTextColor
                        elide: Text.ElideRight
                        width: parent.width
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                    }
                }
            }

            // Switch
            Item {
                width: units.gu(8)
                height: parent.height

                Switch {
                    id: toggleSwitch
                    anchors.centerIn: parent
                    checked: root.checked
                    enabled: root.enabled
                    onClicked: {
                        root.checked = checked;
                        root.toggled(checked);
                    }
                }
            }
        }

        // Bottom divider
        Rectangle {
            visible: root.showDivider
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: units.gu(8)
            height: units.dp(1)
            color: root.dividerColor
        }
    }
}
