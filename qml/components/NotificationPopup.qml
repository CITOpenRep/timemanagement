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
    id: popupWrapper
    width: 0
    height: 0

    // Public properties
    property string type: "info"     // "success", "error", "warning", "info"
    property string titleText: "Notice"
    property string messageText: "Something happened."
    signal closed

    Component {
        id: dialogComponent

        Dialog {
            id: popupDialog
            title: popupWrapper.titleText

            // Dark mode friendly styling
            StyleHints {
                backgroundColor: theme.palette.normal.background
                foregroundColor: theme.palette.normal.backgroundText
            }

            Text {
                id: messageText
                text: popupWrapper.messageText
                width: parent.width
                wrapMode: Text.WordWrap
                horizontalAlignment: {
                    var wordCount = popupWrapper.messageText.split(/\s+/).length;
                    return wordCount < 100 ? Text.AlignHCenter : Text.AlignJustify;
                }
                textFormat: Text.RichText
                color: theme.palette.normal.backgroundText
            }

            // Color logic based on type (optional, add custom styling if needed)
            Button {
                text: "OK"
                onClicked: PopupUtils.close(popupDialog)

                // Dark mode friendly button styling
                StyleHints {
                    foregroundColor: "white"

                    backgroundColor: LomiriColors.orange
                }
            }
        }
    }

    function open(titleArg, messageArg, typeArg) {
        if (titleArg)
            titleText = titleArg;
        if (messageArg)
            messageText = messageArg;
        if (typeArg)
            type = typeArg;
        PopupUtils.open(dialogComponent);
    }
}
