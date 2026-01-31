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

Column {
    id: htmlEditorContainer

    // ============ PUBLIC PROPERTIES ============
    
    /** The HTML content of the editor */
    property string text: ""
    
    /** Whether the editor is in read-only mode */
    property bool readOnly: false
    
    /** Placeholder text when editor is empty */
    property string placeholder: "Write something amazing..."
    
    /** Dark mode state - auto-detected from theme */
    property bool darkMode: theme.name === "Ubuntu.Components.Themes.SuruDark"
    
    /** Whether to show the formatting toolbar */
    property bool showToolbar: true

    /** Direct access to the editor component */
    property alias editor: htmlEditor
    
    /** Current font size display */
    property string currentFontSize: "11pt"
    
    /** Current text color */
    property color currentTextColor: "#000000"
    
    /** Current highlight color */
    property color currentHighlightColor: "transparent"

    // ============ SIGNALS ============
    
    /** Emitted when content changes */
    signal contentChanged(string newText)
    
    /** Emitted when editor has finished loading */
    signal contentLoaded()

    // ============ HELPER FUNCTIONS ============

    function rgbToHex(rgbStr) {
        if (!rgbStr) return "#000000"
        
        // Handle format: rgb(255, 102, 0) or rgb(255,102,0)
        var match = rgbStr.match(/rgb\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)/)
        if (match) {
            var r = parseInt(match[1])
            var g = parseInt(match[2])
            var b = parseInt(match[3])
            var hex = "#" + ((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1)
            return hex
        }
        return rgbStr
    }

    function parsePathForFormatting(path) {
        var parts = path.split('>')
        var size = "11pt"
        var color = "#000000"
        var highlight = "transparent"

        for (var i = 0; i < parts.length; i++) {
            var part = parts[i]
            
            // Extract font size
            var fontSizeMatch = part.match(/fontSize=([^\]]+)/)
            if (fontSizeMatch) {
                size = fontSizeMatch[1]
            }

            // Extract text color
            var colorMatch = part.match(/\[color=([^\]]+)\]/)
            if (colorMatch) {
                color = rgbToHex(colorMatch[1])
            }

            // Extract highlight color
            var highlightMatch = part.match(/backgroundColor=([^\]]+)/)
            if (highlightMatch) {
                highlight = rgbToHex(highlightMatch[1])
            }
        }
        
        currentFontSize = size
        currentTextColor = color
        currentHighlightColor = highlight
    }

    // ============ PUBLIC FUNCTIONS (matching RichTextEditor API) ============

    /** Get text content asynchronously */
    function getText(callback) {
        htmlEditor.getText(callback)
    }

    /** Set text content */
    function setText(htmlText) {
        htmlEditor.setText(htmlText)
    }

    /** Sync content immediately */
    function syncContent() {
        htmlEditor.syncContent()
    }

    // ============ LAYOUT ============

    spacing: 0

    HtmlEditorToolbar {
        id: htmlToolbar
        width: parent.width
        visible: showToolbar && !readOnly
        editor: htmlEditor
        darkMode: htmlEditorContainer.darkMode
        currentFontSize: htmlEditorContainer.currentFontSize
        currentTextColor: htmlEditorContainer.currentTextColor
        currentHighlightColor: htmlEditorContainer.currentHighlightColor

        onFontSizeClicked: {
            PopupUtils.open(fontSizeDialogComponent)
        }

        onTextColorClicked: {
            var dialog = PopupUtils.open(colorPickerDialogComponent)
            dialog.isHighlight = false
        }

        onHighlightColorClicked: {
            var dialog = PopupUtils.open(colorPickerDialogComponent)
            dialog.isHighlight = true
        }

        onLinkClicked: {
            PopupUtils.open(linkDialogComponent)
        }
    }

    RichTextEditor {
        id: htmlEditor
        width: parent.width
        height: parent.height - (htmlToolbar.visible ? htmlToolbar.height : 0)
        
        text: htmlEditorContainer.text
        readOnly: htmlEditorContainer.readOnly
        placeholder: htmlEditorContainer.placeholder
        darkMode: htmlEditorContainer.darkMode

        onContentLoaded: {
            htmlEditorContainer.contentLoaded()
        }

        onContentChanged: {
            htmlEditorContainer.text = newText
            htmlEditorContainer.contentChanged(newText)
        }

        onPathChanged: {
            htmlEditorContainer.parsePathForFormatting(path)
        }
    }

    // ============ DIALOG COMPONENTS ============

    Component {
        id: linkDialogComponent
        LinkDialog {
            onLinkInserted: {
                if (text && text.length > 0) {
                    htmlEditor.insertLinkWithText(url, text)
                } else {
                    htmlEditor.insertLink(url)
                }
            }
        }
    }

    Component {
        id: fontSizeDialogComponent
        FontSizeDialog {
            onSizeSelected: {
                htmlEditor.setFontSize(size)
                htmlEditorContainer.currentFontSize = size
            }
        }
    }

    Component {
        id: colorPickerDialogComponent
        ColorPickerDialog {
            onColorSelected: {
                if (isHighlight) {
                    htmlEditor.setHighlightColor(color)
                    htmlEditorContainer.currentHighlightColor = color
                } else {
                    htmlEditor.setTextColor(color)
                    htmlEditorContainer.currentTextColor = color
                }
            }
        }
    }
}
