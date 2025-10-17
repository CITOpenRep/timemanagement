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

Item {
    id: popupWrapper
    width: 0
    height: 0

    signal timeSelected(int hour, int minute)

    property int initialHour: 1
    property int initialMinute: 0

    Component {
        id: timeDialogComponent

        Dialog {
            id: timeDialog
            title: i18n.dtr("ubtms", "Select Hours")

            property int selectedHour: popupWrapper.initialHour
            property int selectedMinute: popupWrapper.initialMinute

            Column {
                spacing: units.gu(2)
                anchors.horizontalCenter: parent.horizontalCenter

                Row {
                    spacing: units.gu(1)

                    ComboBox {
                        id: hourCombo
                        width: units.gu(10)
                        model: ListModel {}
                        Component.onCompleted: {
                            for (var i = 0; i < 24; i++) {
                                hourCombo.model.append({
                                    text: i < 10 ? "0" + i : "" + i
                                });
                            }
                            currentIndex = popupWrapper.initialHour;
                            selectedHour = popupWrapper.initialHour;
                        }
                        onCurrentIndexChanged: {
                            if (model.count > currentIndex)
                                selectedHour = parseInt(model.get(currentIndex).text);
                        }
                    }

                    Text {
                        text: ":"
                        verticalAlignment: Text.AlignVCenter
                    }

                    ComboBox {
                        id: minuteCombo
                        width: units.gu(10)
                        model: ListModel {}
                        Component.onCompleted: {
                            for (var j = 0; j < 60; j += 5) {
                                minuteCombo.model.append({
                                    text: j < 10 ? "0" + j : "" + j
                                });
                            }
                            currentIndex = Math.floor(popupWrapper.initialMinute / 5);
                            selectedMinute = popupWrapper.initialMinute;
                        }
                        onCurrentIndexChanged: {
                            if (model.count > currentIndex)
                                selectedMinute = parseInt(model.get(currentIndex).text);
                        }
                    }
                }

                Row {
                    spacing: units.gu(2)
                    TSButton {
                        text: "Cancel"
                        width: units.gu(10)
                        height: units.gu(5)
                        onClicked: PopupUtils.close(timeDialog)
                    }
                    TSButton {
                        text: "OK"
                        height: units.gu(5)
                        width: units.gu(10)
                        onClicked: {
                            popupWrapper.timeSelected(selectedHour, selectedMinute);
                            PopupUtils.close(timeDialog);
                        }
                    }
                }
            }
        }
    }

    function open(hour, minute) {
        initialHour = hour || 0;
        initialMinute = minute || 0;
        PopupUtils.open(timeDialogComponent);
    }
}
