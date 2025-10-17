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
import Lomiri.Components.Popups 1.3
import Lomiri.Components.Pickers 1.3
import "../../models/utils.js" as Utils

Item {
    id: dialogWrapper
    width: 0
    height: 0

    property string titleText: "Reschedule Task"
    property string currentStartDate: ""
    property string currentEndDate: ""

    signal dateRangeSelected(string startDate, string endDate)

    function open() {
        PopupUtils.open(dialogComponent, parent);
    }

    Component {
        id: dialogComponent

        Dialog {
            id: rangeDialog
            title: dialogWrapper.titleText
            modal: true
            // width: units.gu(40)
            //   height: units.gu(40)

            property date selectedStartDate: new Date(currentStartDate || Utils.getToday())
            property date selectedEndDate: new Date(currentEndDate || Utils.getTomorrow())

            function formatDateToString(date) {
                return Qt.formatDate(date, "yyyy-MM-dd");
            }

            function selectDateRange() {
                var startStr = formatDateToString(selectedStartDate);
                var endStr = formatDateToString(selectedEndDate);

                // Validate that end date is not before start date
                if (selectedEndDate < selectedStartDate) {
                    // Auto-correct: set end date to start date + 1 day
                    selectedEndDate = new Date(selectedStartDate.getTime() + 24 * 60 * 60 * 1000);
                    endStr = formatDateToString(selectedEndDate);
                }

                dateRangeSelected(startStr, endStr);
                PopupUtils.close(rangeDialog);
            }

            Column {
                width: parent.width
                spacing: units.gu(2)

                // Quick preset options
                Column {
                    width: parent.width
                    spacing: units.gu(1)

                    Text {
                        text: "Quick reschedule options:"
                        font.bold: true
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                    }

                    TSButton {
                        text: "Tomorrow"
                        width: parent.width
                        bgColor: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#404258" : "#22BABB"
                        onClicked: {
                            var tomorrow = new Date();
                            tomorrow.setDate(tomorrow.getDate() + 1);
                            selectedStartDate = new Date(tomorrow);
                            selectedEndDate = new Date(tomorrow);
                            selectDateRange();
                        }
                    }

                    TSButton {
                        text: "Next Week"
                        width: parent.width
                        bgColor: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#404258" : "#22BABB"
                        onClicked: {
                            var today = new Date();
                            var daysUntilNextMonday = today.getDay() === 0 ? 1 : (8 - today.getDay());
                            selectedStartDate = new Date(today.getTime() + daysUntilNextMonday * 24 * 60 * 60 * 1000);
                            selectedEndDate = new Date(selectedStartDate.getTime() + 4 * 24 * 60 * 60 * 1000); // Friday
                            selectDateRange();
                        }
                    }

                    TSButton {
                        text: "Next Month"
                        width: parent.width
                        bgColor: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#404258" : "#22BABB"
                        onClicked: {
                            var today = new Date();
                            var nextMonth = new Date(today.getFullYear(), today.getMonth() + 1, 1); // First day of next month
                            var lastDayOfNextMonth = new Date(today.getFullYear(), today.getMonth() + 2, 0); // Last day of next month
                            selectedStartDate = new Date(nextMonth);
                            selectedEndDate = new Date(lastDayOfNextMonth);
                            selectDateRange();
                        }
                    }
                }

                // Separator
                Rectangle {
                    width: parent.width
                    height: 1
                    color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#444" : "#ddd"
                }

                // Custom date range selection
                Column {
                    width: parent.width
                    spacing: units.gu(1)

                    Text {
                        text: "Custom date range:"
                        font.bold: true
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                    }

                    // Start Date Selection
                    Row {
                        width: parent.width
                        spacing: units.gu(1)

                        Text {
                            text: "Start Date:"
                            width: units.gu(12)
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        TSButton {
                            text: Qt.formatDate(selectedStartDate, "dd-MM-yyyy")
                            bgColor: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#404258" : "#22BABB"
                            width: parent.width - units.gu(13)
                            onClicked: {
                                PickerPanel.openDatePicker(rangeDialog, "selectedStartDate", "Years|Months|Days");
                            }
                        }
                    }

                    // End Date Selection
                    Row {
                        width: parent.width
                        spacing: units.gu(1)

                        Text {
                            text: "End Date:"
                            width: units.gu(12)
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        TSButton {
                            text: Qt.formatDate(selectedEndDate, "dd-MM-yyyy")
                            bgColor: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#404258" : "#22BABB"
                            width: parent.width - units.gu(13)
                            onClicked: {
                                PickerPanel.openDatePicker(rangeDialog, "selectedEndDate", "Years|Months|Days");
                            }
                        }
                    }

                    // Duration info
                    Text {
                        text: {
                            var timeDiff = selectedEndDate.getTime() - selectedStartDate.getTime();
                            var daysDiff = Math.floor(timeDiff / (1000 * 60 * 60 * 24));
                            return "Duration: " + (daysDiff + 1) + " day(s)";
                        }
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#bbb" : "#666"
                    }
                }

                // Action buttons
                Row {
                    width: parent.width
                    spacing: units.gu(1)

                    TSButton {
                        text: "Cancel"
                        width: (parent.width - units.gu(1)) / 2
                        bgColor: "#F25041"
                        onClicked: PopupUtils.close(rangeDialog)
                    }

                    TSButton {
                        text: "Apply"
                        width: (parent.width - units.gu(1)) / 2
                        bgColor: "#1F7D53"
                        onClicked: selectDateRange()
                    }
                }
            }
        }
    }
}
