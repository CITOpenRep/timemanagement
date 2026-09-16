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
import "../../../models/constants.js" as AppConst
import ".."

Item {
    id: root

    property alias text: searchField.text
    property string placeholderText: i18n.dtr("ubtms", "Search...")
    property alias activeFocusOnPress: searchField.activeFocusOnPress
    readonly property bool isInputActive: searchField.activeFocus

    readonly property bool isDark: typeof theme !== 'undefined' && theme.name === "Ubuntu.Components.Themes.SuruDark"

    property real capsuleRadius: units.gu(1.2)
    property real topPadding: units.gu(1.2)
    property real bottomPadding: units.gu(1.2)
    property real horizontalPadding: units.gu(1.5)

    implicitHeight: topPadding + units.gu(4.6) + bottomPadding
    implicitWidth: units.gu(30)
    clip: true

    signal accepted(string query)
    signal cleared()

    function clear() {
        if (searchField.text !== "") {
            searchField.text = "";
        }
    }

    function forceActiveFocus() {
        Qt.callLater(function() {
            searchField.forceActiveFocus();
        });
    }

    Rectangle {
        id: searchBarBox
        anchors.fill: parent
        anchors.leftMargin: root.horizontalPadding
        anchors.rightMargin: root.horizontalPadding
        anchors.topMargin: root.topPadding
        anchors.bottomMargin: root.bottomPadding
        radius: root.capsuleRadius
        color: root.isDark ? "#1e1e1e" : "#f1f5f9"
        border.color: searchField.activeFocus
            ? AppConst.Colors.Orange
            : (root.isDark ? "#2d2d2d" : "#e2e8f0")
        border.width: searchField.activeFocus ? units.gu(0.18) : units.gu(0.1)

        Behavior on border.color {
            ColorAnimation { duration: 150 }
        }

        MouseArea {
            anchors.fill: parent
            z: 0
            cursorShape: Qt.IBeamCursor
            onClicked: {
                searchField.forceActiveFocus();
            }
        }

        Icon {
            id: searchIcon
            anchors.left: parent.left
            anchors.leftMargin: units.gu(1.4)
            anchors.verticalCenter: parent.verticalCenter
            width: units.gu(2)
            height: units.gu(2)
            name: "search"
            color: searchField.activeFocus
                ? AppConst.Colors.Orange
                : (root.isDark ? "#71717a" : "#94a3b8")

            Behavior on color {
                ColorAnimation { duration: 150 }
            }
        }

        TextInput {
            id: searchField
            anchors.left: searchIcon.right
            anchors.leftMargin: units.gu(1.2)
            anchors.right: clearSearchButton.visible ? clearSearchButton.left : parent.right
            anchors.rightMargin: clearSearchButton.visible ? units.gu(0.5) : units.gu(1.4)
            anchors.verticalCenter: parent.verticalCenter
            verticalAlignment: TextInput.AlignVCenter
            color: root.isDark ? "#f3f4f6" : "#0f172a"
            font.pixelSize: units.gu(1.8)
            selectByMouse: true
            clip: true
            inputMethodHints: Qt.ImhNoPredictiveText

            onAccepted: {
                root.accepted(text);
            }

            onTextChanged: {
                if (text === "") {
                    root.cleared();
                }
            }
        }

        Text {
            anchors.fill: searchField
            verticalAlignment: Text.AlignVCenter
            text: root.placeholderText
            color: root.isDark ? "#71717a" : "#94a3b8"
            font.pixelSize: searchField.font.pixelSize
            visible: !searchField.text && !searchField.activeFocus
            elide: Text.ElideRight
        }

        Item {
            id: clearSearchButton
            visible: searchField.text.length > 0
            anchors.right: parent.right
            anchors.rightMargin: units.gu(0.8)
            anchors.verticalCenter: parent.verticalCenter
            width: units.gu(3.2)
            height: units.gu(3.2)
            z: 1

            Rectangle {
                anchors.centerIn: parent
                width: units.gu(2.4)
                height: units.gu(2.4)
                radius: width / 2
                color: clearMouseArea.pressed
                    ? (root.isDark ? "#444444" : "#cbd5e1")
                    : (root.isDark ? "#2a2a2a" : "#e2e8f0")

                Icon {
                    name: "close"
                    width: units.gu(1.3)
                    height: units.gu(1.3)
                    anchors.centerIn: parent
                    color: root.isDark ? "#a1a1aa" : "#64748b"
                }
            }

            MouseArea {
                id: clearMouseArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.clear();
                }
            }
        }
    }
}
