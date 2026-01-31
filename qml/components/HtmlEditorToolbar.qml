/* Copyright (C) 2016 - 2017 Dan Chapman <dpniel@ubuntu.com>
   Copyright (C) 2025 Dekko Project
   Adapted for timemanagement project

   This file is part of Dekko email client for Ubuntu devices

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation; either version 2 of
   the License or (at your option) version 3

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
import QtQuick 2.7
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3

Rectangle {
    id: toolbar

    property var editor: null
    property string currentFontSize: "12pt"
    property color currentTextColor: "#000000"
    property color currentHighlightColor: "transparent"
    property bool darkMode: theme.name === "Ubuntu.Components.Themes.SuruDark"

    signal fontSizeClicked()
    signal textColorClicked()
    signal highlightColorClicked()
    signal linkClicked()

    height: units.gu(6)
    color: darkMode ? "#3d3d3d" : "#f5f5f5"

    Flickable {
        anchors.fill: parent
        contentWidth: toolbarRow.width + units.gu(2)
        contentHeight: height
        flickableDirection: Flickable.HorizontalFlick
        clip: true

        Row {
            id: toolbarRow
            x: units.gu(1)
            anchors.verticalCenter: parent.verticalCenter
            spacing: units.gu(0.5)

            // Bold
            Button {
                width: units.gu(5)
                height: units.gu(4)
                text: "B"
                font.bold: true
                color: editor && editor.font.bold ? LomiriColors.orange : (darkMode ? "#555555" : "#F0F0F0")
                onClicked: {
                    if (editor) {
                        editor.toggleBold()
                    }
                }
            }

            // Italic
            Button {
                width: units.gu(5)
                height: units.gu(4)
                text: "I"
                font.italic: true
                color: editor && editor.font.italic ? LomiriColors.orange : (darkMode ? "#555555" : "#F0F0F0")
                onClicked: {
                    if (editor) {
                        editor.toggleItalic()
                    }
                }
            }

            // Underline
            Button {
                width: units.gu(5)
                height: units.gu(4)
                text: "U"
                font.underline: true
                color: editor && editor.font.underline ? LomiriColors.orange : (darkMode ? "#555555" : "#F0F0F0")
                onClicked: {
                    if (editor) {
                        editor.toggleUnderline()
                    }
                }
            }

            // Strikethrough
            Button {
                width: units.gu(5)
                height: units.gu(4)
                text: "S"
                font.strikeout: true
                color: editor && editor.font.strikethrough ? LomiriColors.orange : (darkMode ? "#555555" : "#F0F0F0")
                onClicked: {
                    if (editor) {
                        editor.toggleStrikethrough()
                    }
                }
            }

            ToolbarSeparator {}

            // Font Size
            Button {
                width: units.gu(7)
                height: units.gu(4)
                text: currentFontSize
                color: darkMode ? "#555555" : "#F0F0F0"
                onClicked: toolbar.fontSizeClicked()
            }

            // Text Color
            Button {
                width: units.gu(5)
                height: units.gu(4)
                text: "A"
                font.bold: true
                color: darkMode ? "#555555" : "#F0F0F0"
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottomMargin: units.gu(0.5)
                    width: parent.width - units.gu(1)
                    height: units.gu(0.4)
                    color: currentTextColor
                }
                onClicked: toolbar.textColorClicked()
            }

            // Highlight Color
            Button {
                width: units.gu(5)
                height: units.gu(4)
                color: darkMode ? "#555555" : "#F0F0F0"
                Rectangle {
                    anchors.centerIn: parent
                    width: units.gu(2)
                    height: units.gu(2)
                    color: currentHighlightColor === "transparent" ? "#FFFF00" : currentHighlightColor
                    border.width: 1
                    border.color: "#999999"
                }
                onClicked: toolbar.highlightColorClicked()
            }

            ToolbarSeparator {}

            // Alignment Left
            Button {
                width: units.gu(5)
                height: units.gu(4)
                color: darkMode ? "#555555" : "#F0F0F0"
                Column {
                    anchors.centerIn: parent
                    spacing: 2
                    Repeater {
                        model: 3
                        Rectangle {
                            width: units.gu(2)
                            height: 2
                            color: darkMode ? "#CCCCCC" : "#333333"
                        }
                    }
                }
                onClicked: if (editor) editor.setTextAlignment(Qt.AlignLeft)
            }

            // Alignment Center
            Button {
                width: units.gu(5)
                height: units.gu(4)
                color: darkMode ? "#555555" : "#F0F0F0"
                Column {
                    anchors.centerIn: parent
                    spacing: 2
                    Rectangle { width: units.gu(2); height: 2; color: darkMode ? "#CCCCCC" : "#333333"; anchors.horizontalCenter: parent.horizontalCenter }
                    Rectangle { width: units.gu(1.5); height: 2; color: darkMode ? "#CCCCCC" : "#333333"; anchors.horizontalCenter: parent.horizontalCenter }
                    Rectangle { width: units.gu(2); height: 2; color: darkMode ? "#CCCCCC" : "#333333"; anchors.horizontalCenter: parent.horizontalCenter }
                }
                onClicked: if (editor) editor.setTextAlignment(Qt.AlignHCenter)
            }

            // Alignment Right
            Button {
                width: units.gu(5)
                height: units.gu(4)
                color: darkMode ? "#555555" : "#F0F0F0"
                Column {
                    anchors.centerIn: parent
                    spacing: 2
                    Repeater {
                        model: 3
                        Rectangle {
                            width: units.gu(2)
                            height: 2
                            color: darkMode ? "#CCCCCC" : "#333333"
                            anchors.right: parent.right
                        }
                    }
                }
                onClicked: if (editor) editor.setTextAlignment(Qt.AlignRight)
            }

            // Alignment Justify
            Button {
                width: units.gu(5)
                height: units.gu(4)
                color: darkMode ? "#555555" : "#F0F0F0"
                Column {
                    anchors.centerIn: parent
                    spacing: 2
                    Repeater {
                        model: 3
                        Rectangle {
                            width: units.gu(2)
                            height: 2
                            color: darkMode ? "#CCCCCC" : "#333333"
                        }
                    }
                }
                onClicked: if (editor) editor.setTextAlignment(Qt.AlignJustify)
            }

            ToolbarSeparator {}

            // Unordered List
            Button {
                width: units.gu(5)
                height: units.gu(4)
                text: "•"
                font.pixelSize: units.gu(2)
                color: darkMode ? "#555555" : "#F0F0F0"
                onClicked: {
                    console.log("[Toolbar] Unordered list clicked, editor:", editor ? "exists" : "null");
                    if (editor) editor.makeUnorderedList()
                }
            }

            // Ordered List
            Button {
                width: units.gu(5)
                height: units.gu(4)
                text: "1."
                font.pixelSize: units.gu(1.5)
                color: darkMode ? "#555555" : "#F0F0F0"
                onClicked: {
                    console.log("[Toolbar] Ordered list clicked, editor:", editor ? "exists" : "null");
                    if (editor) editor.makeOrderedList()
                }
            }

            ToolbarSeparator {}

            // Link
            Button {
                width: units.gu(5)
                height: units.gu(4)
                text: "🔗"
                font.pixelSize: units.gu(1.5)
                color: darkMode ? "#555555" : "#F0F0F0"
                onClicked: toolbar.linkClicked()
            }

            ToolbarSeparator {}

            // Undo
            Button {
                width: units.gu(5)
                height: units.gu(4)
                text: "↶"
                font.pixelSize: units.gu(2)
                color: darkMode ? "#555555" : "#F0F0F0"
                onClicked: {
                    console.log("[Toolbar] Undo clicked");
                    if (editor) editor.undo()
                }
            }

            // Redo
            Button {
                width: units.gu(5)
                height: units.gu(4)
                text: "↷"
                font.pixelSize: units.gu(2)
                color: darkMode ? "#555555" : "#F0F0F0"
                onClicked: {
                    console.log("[Toolbar] Redo clicked");
                    if (editor) editor.redo()
                }
            }

            ToolbarSeparator {}

            // Clear Formatting
            Button {
                width: units.gu(5)
                height: units.gu(4)
                text: "Tx"
                font.pixelSize: units.gu(1.5)
                color: darkMode ? "#555555" : "#F0F0F0"
                onClicked: if (editor) editor.removeAllFormatting()
            }
        }
    }
}
