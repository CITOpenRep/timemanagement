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
import Lomiri.Components.Popups 1.3
import Lomiri.Components 1.3

Item {
    id: dialogWrapper
    width: 0
    height: 0

    // Property to store page reference for navigation
    property var targetPage: null

    // Signals
    signal saveRequested
    signal discardRequested
    signal cancelled

    Component {
        id: dialogComponent

        Dialog {
            id: confirmDialog
            title: i18n.dtr("ubtms", "Unsaved Changes")

            Text {
                id: messageText
                text: i18n.dtr("ubtms", "You have unsaved changes. What would you like to do?\n\nNote: If you cancel, you can navigate back to continue editing.")
                width: parent.width
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                color: theme.palette.normal.backgroundText
            }

            Row {
                spacing: units.gu(1)
                anchors.horizontalCenter: parent.horizontalCenter

                Button {
                    text: i18n.dtr("ubtms", "Save")
                    color: LomiriColors.green
                    onClicked: {
                        console.log("💾 SaveDiscardDialog: User clicked Save");
                        PopupUtils.close(confirmDialog);
                        dialogWrapper.saveRequested();
                    }

                    StyleHints {
                        foregroundColor: "white"
                        backgroundColor: LomiriColors.green
                    }
                }

                Button {
                    text: i18n.dtr("ubtms", "Discard")
                    color: LomiriColors.red
                    onClicked: {
                        console.log("🗑️ SaveDiscardDialog: User clicked Discard");
                        PopupUtils.close(confirmDialog);
                        dialogWrapper.discardRequested();
                    }

                    StyleHints {
                        foregroundColor: "white"
                        backgroundColor: LomiriColors.red
                    }
                }

                Button {
                    text: i18n.dtr("ubtms", "Cancel")
                    onClicked: {
                        console.log("❌ SaveDiscardDialog: User clicked Cancel");
                        PopupUtils.close(confirmDialog);
                        dialogWrapper.cancelled();
                    }

                    StyleHints {
                        foregroundColor: theme.palette.normal.backgroundText
                        backgroundColor: theme.palette.normal.base
                    }
                }
            }
        }
    }

    function open(page) {
        console.log("🔍 SaveDiscardDialog: Opening dialog");
        if (page) {
            targetPage = page;
        }
        PopupUtils.open(dialogComponent);
    }
}
