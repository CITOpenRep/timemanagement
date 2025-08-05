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

// components/QuickDateSelectorDialog.qml
import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1
import Lomiri.Components.Popups 1.3
import Lomiri.Components.Pickers 1.3
import "../../models/utils.js" as Utils

Item {
    id: popupWrapper
    width: 0
    height: 0

    property string titleText: "Select Date"
    property string selected_date: ""
    property string mode: "next" // or "previous"
    property bool showCustomPicker: false
    property string tempCustomDate: ""

    signal dateSelected(string date)

    Component {
        id: dialogComponent

        Dialog {
            id: quickDialog
            title: popupWrapper.titleText
            modal: true

            function selectSingleDate(dateStr) {
                popupWrapper.selected_date = dateStr; // Keep original YYYY-MM-DD format
                dateSelected(popupWrapper.selected_date);
                PopupUtils.close(quickDialog);
            }

            function formatDateToDMY(dateStr) {
                var date = new Date(dateStr);
                var dd = String(date.getDate()).padStart(2, '0');
                var mm = String(date.getMonth() + 1).padStart(2, '0'); // Months are 0-indexed
                var yyyy = date.getFullYear();
                return dd + '-' + mm + '-' + yyyy;
            }

            ColumnLayout {
                width: parent.width
                spacing: units.gu(2)

                // PREVIOUS MODE
                ColumnLayout {
                    visible: mode === "previous"
                    spacing: units.gu(1)

                    TSButton {
                        text: "Today"
                        Layout.fillWidth: true
                        onClicked: selectSingleDate(Utils.getToday())
                    }

                    TSButton {
                        text: "Yesterday"
                        Layout.fillWidth: true
                        onClicked: selectSingleDate(Utils.getYesterday()) // Add this in Utils.js
                    }

                    TSButton {
                        text: "Custom"
                        Layout.fillWidth: true
                        onClicked: showCustomPicker = !showCustomPicker
                    }
                }

                // NEXT MODE
                ColumnLayout {
                    visible: mode === "next"
                    spacing: units.gu(1)

                    TSButton {
                        text: "Tomorrow"
                        bgColor: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#404258" :  "#121212"
                        Layout.fillWidth: true
                        onClicked: selectSingleDate(Utils.getTomorrow())
                    }

                    TSButton {
                        text: "Next Week"
                        bgColor: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#404258" :  "#121212"
                        Layout.fillWidth: true
                        onClicked: selectSingleDate(Utils.getNextWeekRange().start)
                    }

                    TSButton {
                        text: "Next Month"
                        bgColor: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#404258" :  "#121212"
                        Layout.fillWidth: true
                        onClicked: selectSingleDate(Utils.getNextMonthRange().start)
                    }

                    TSButton {
                        text: "Custom"
                        bgColor: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#404258" :  "#121212"
                        Layout.fillWidth: true
                        onClicked: showCustomPicker = !showCustomPicker
                    }

                    TSButton {
                        text: "Cancel"
                        Layout.fillWidth: true
                       bgColor: "#8A0000"
                        visible: !showCustomPicker
                        onClicked: PopupUtils.close(quickDialog)

                      
                    }
                }

                // SHARED: Custom Picker UI
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: units.gu(10)
                    visible: showCustomPicker

                    TSButton {
                        id: customDateButton
                         bgColor: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#404258" :  "#121212"
                        property date date: new Date()
                        text: date ? Qt.formatDateTime(date, "dd-MM-yy") : "Custom"
                        Layout.fillWidth: true
                        onClicked: PickerPanel.openDatePicker(customDateButton, "date", "Years|Months|Days")
                    }

                    RowLayout {
                        // Layout.alignment: Qt.AlignHCenter
                        spacing: units.gu(2)

                        TSButton {
                            text: "Cancel"
                            Layout.fillWidth: true
                            bgColor: "#8A0000"
                            onClicked: PopupUtils.close(quickDialog)
                        }

                        TSButton {
                            text: "OK"
                            Layout.fillWidth: true
                            bgColor: "#1F7D53"
                            onClicked: {
                                selected_date = customDateButton.date;
                                // Convert to YYYY-MM-DD format for database storage
                                var dateStr = customDateButton.date.toISOString().slice(0, 10);
                                dateSelected(dateStr);
                                PopupUtils.close(quickDialog);
                            }
                        }
                    }
                }
            }
        }
    }

    function open() {
        showCustomPicker = false;
        PopupUtils.open(dialogComponent);
    }
}
