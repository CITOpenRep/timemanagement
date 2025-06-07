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

Dialog {
    id: colorDialog
    modal: true
    focus: true
    property int selectedColorIndex: -1
    signal colorPicked(int colorIndex)

    title: "Select Color"
    standardButtons: Dialog.Ok | Dialog.Cancel

    // ✨ This makes the dialog appear centered
    anchors.centerIn: parent
    width: 300
    height: implicitHeight
    padding: 12

    onAccepted: {
        colorPicked(selectedColor);
    }

    contentItem: ColumnLayout {
        spacing: 10
        width: parent.width

        GridLayout {
            id: colorGrid
            columns: 6
            Layout.alignment: Qt.AlignHCenter

            property var odooColors: ["#FFFFFF", "#EB6E67", "#F39C5A", "#F6C342", "#6CC1E1", "#854D76", "#ED8888", "#2C8397", "#49597C", "#DE3F7C", "#45C486", "#9B6CC3"]

            Repeater {
                model: colorGrid.odooColors.length
                Rectangle {
                    width: 32
                    height: 32
                    color: colorGrid.odooColors[index]
                    border.color: Qt.darker(color, 1.3)
                    radius: 4
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            colorDialog.selectedColorIndex = index;
                            colorPicked(index);  // Emit the integer index
                            colorDialog.close();
                        }
                    }
                }
            }
        }
    }
}
