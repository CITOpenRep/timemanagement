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

Item {
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

    /** Whether the toolbar is currently expanded (user toggle) */
    property bool toolbarExpanded: true

    /** Direct access to the editor component */
    property alias editor: htmlEditor
    
    /** Current font size display */
    property string currentFontSize: htmlEditor ? htmlEditor.currentFontSize : "13px"
    
    /** Current text color */
    property color currentTextColor: htmlEditor ? htmlEditor.currentTextColor : "#000000"
    
    /** Current highlight color */
    property color currentHighlightColor: htmlEditor ? htmlEditor.currentHighlightColor : "transparent"

    /** Active list state */
    property bool isUnorderedList: htmlEditor ? htmlEditor.isUnorderedList : false
    property bool isOrderedList: htmlEditor ? htmlEditor.isOrderedList : false

    /** Text alignment */
    property string alignment: htmlEditor ? htmlEditor.alignment : "left"

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


    // ============ PUBLIC FUNCTIONS (matching RichTextEditor API) ============

    /** Get text content asynchronously */
    function getText(callback) {
        htmlEditor.getText(callback)
    }

    /**
     * Get formatted text synchronously (API compatible with RichTextPreview)
     * Returns the cached 'text' property which is kept up-to-date via contentChanged events.
     * @return Current text property value
     */
    function getFormattedText() {
        return htmlEditorContainer.text || "";
    }

    /** Set text content */
    function setText(htmlText) {
        htmlEditor.setText(htmlText)
    }

    /** 
     * Sync content immediately
     * Also returns the current cached text for immediate sync needs
     */
    function syncContent() {
        var result = htmlEditor.syncContent()
        // Return our cached text which is kept in sync via contentChanged
        return htmlEditorContainer.text || "";
    }

    // ============ LAYOUT ============

    HtmlEditorToolbar {
        id: htmlToolbar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        visible: showToolbar && !readOnly && toolbarExpanded
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
        anchors.top: (htmlToolbar.visible) ? htmlToolbar.bottom : parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        
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
            }
        }
    }

    Component {
        id: colorPickerDialogComponent
        ColorPickerDialog {
            onColorSelected: {
                if (isHighlight) {
                    htmlEditor.setHighlightColor(color)
                } else {
                    htmlEditor.setTextColor(color)
                }
            }
        }
    }
}
