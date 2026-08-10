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
import QtQuick.Layouts 1.3
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.Components.Pickers 1.3
import "../../../models/global.js" as Global
import "../selectors"
import ".."

Item {
    id: rootFilter
    width: parent ? parent.width : units.gu(35)
    height: parent ? parent.height : contentColumn.implicitHeight
    implicitHeight: contentColumn.implicitHeight
    z: 9999

    property int presetId: -1
    property string startDate: ""
    property string endDate: ""
    property string presetLabel: i18n.dtr("ubtms", "No Filter (All Time)")
    property bool isFiltered: presetId !== -1
    property bool suppressSignal: false

    signal dateRangeChanged(int presetId, string startDate, string endDate, string presetLabel)

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        anchors.leftMargin: units.gu(0.5)
        anchors.rightMargin: units.gu(0.5)
        anchors.topMargin: 0
        anchors.bottomMargin: 0
        spacing: 0

        RowLayout {
            id: filterRow
            Layout.fillWidth: true
            spacing: units.gu(1)

            InlineOptionSelector {
                id: inlinePresetSelector
                Layout.fillWidth: true
                labelText: i18n.dtr("ubtms", "Date Range")
                selectorType: "date_range"
                selectedId: rootFilter.presetId

                bgColor: "transparent"
                borderColor: "white"
                textColor: "white"
                mutedTextColor: "white"

                modelData: [
                    { id: -1, name: i18n.dtr("ubtms", "No Filter (All Time)") },
                    { id: 0,  name: i18n.dtr("ubtms", "Today") },
                    { id: 1,  name: i18n.dtr("ubtms", "This Week") },
                    { id: 2,  name: i18n.dtr("ubtms", "Last 7 Days") },
                    { id: 3,  name: i18n.dtr("ubtms", "This Month") },
                    { id: 4,  name: i18n.dtr("ubtms", "Last 30 Days") },
                    { id: 5,  name: i18n.dtr("ubtms", "This Quarter") },
                    { id: 6,  name: i18n.dtr("ubtms", "This Year") },
                    { id: 7,  name: i18n.dtr("ubtms", "Custom Range...") }
                ]

                onSelectionMade: function(id, name, type) {
                    if (rootFilter.suppressSignal) return;
                    rootFilter.applyPreset(id, name);
                }
            }

            // Clear (X) button
            Item {
                id: clearBtn
                visible: rootFilter.isFiltered
                Layout.preferredWidth: units.gu(4)
                Layout.preferredHeight: units.gu(4)
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    anchors.fill: parent
                    radius: units.gu(0.5)
                    color: clearMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.2) : "transparent"
                    border.color: "white"
                    border.width: 1

                    Icon {
                        name: "close"
                        anchors.centerIn: parent
                        width: units.gu(2)
                        height: units.gu(2)
                        color: clearMouse.containsMouse ? LomiriColors.red : "white"
                    }
                }

                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        rootFilter.clearFilter();
                    }
                }
            }
        }

        // Active range date badge for custom range
        Rectangle {
            id: customBadge
            Layout.alignment: Qt.AlignHCenter
            width: badgeText.implicitWidth + units.gu(2)
            height: units.gu(3)
            visible: rootFilter.isFiltered && rootFilter.presetId === 7 && rootFilter.startDate !== ""
            radius: units.gu(0.5)
            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#333" : "#fff"
            border.color: LomiriColors.orange
            border.width: 1

            Text {
                id: badgeText
                anchors.centerIn: parent
                text: rootFilter.startDate + " ~ " + rootFilter.endDate
                font.pixelSize: units.dp(12)
                color: LomiriColors.orange
            }
        }
    }

    function calculateDates(id) {
        var today = new Date();
        today.setHours(0, 0, 0, 0);

        var start = null;
        var end = null;

        function fmt(d) {
            return Qt.formatDate(d, "yyyy-MM-dd");
        }

        switch (id) {
        case 0: // Today
            start = new Date(today);
            end = new Date(today);
            break;
        case 1: // This Week (Mon - Sun)
            var dow = today.getDay();
            var daysFromMon = dow === 0 ? 6 : dow - 1;
            start = new Date(today);
            start.setDate(today.getDate() - daysFromMon);
            end = new Date(start);
            end.setDate(start.getDate() + 6);
            break;
        case 2: // Last 7 Days
            start = new Date(today);
            start.setDate(today.getDate() - 6);
            end = new Date(today);
            break;
        case 3: // This Month
            start = new Date(today.getFullYear(), today.getMonth(), 1);
            end = new Date(today.getFullYear(), today.getMonth() + 1, 0);
            break;
        case 4: // Last 30 Days
            start = new Date(today);
            start.setDate(today.getDate() - 29);
            end = new Date(today);
            break;
        case 5: // This Quarter
            var q = Math.floor(today.getMonth() / 3);
            start = new Date(today.getFullYear(), q * 3, 1);
            end = new Date(today.getFullYear(), (q + 1) * 3, 0);
            break;
        case 6: // This Year
            start = new Date(today.getFullYear(), 0, 1);
            end = new Date(today.getFullYear(), 11, 31);
            break;
        default:
            break;
        }

        return {
            start: start ? fmt(start) : "",
            end: end ? fmt(end) : ""
        };
    }

    function applyPreset(id, label) {
        if (id === 7) {
            // Custom Range...
            openCustomDateDialog();
            return;
        }

        var dates = calculateDates(id);
        setFilterState(id, dates.start, dates.end, label);
    }

    function setFilterState(id, start, end, label) {
        var pid = (id !== undefined && id !== null && !isNaN(Number(id))) ? Number(id) : -1;
        presetId = pid;
        startDate = start || "";
        endDate = end || "";
        presetLabel = label || i18n.dtr("ubtms", "No Filter (All Time)");
        isFiltered = (pid !== -1);

        // Update InlineOptionSelector selected state
        suppressSignal = true;
        inlinePresetSelector.selectedId = pid;
        inlinePresetSelector.selectedName = presetLabel;
        suppressSignal = false;

        // Save state globally & emit signal
        Global.setDateRangeFilter(presetId, startDate, endDate, presetLabel);
        dateRangeChanged(presetId, startDate, endDate, presetLabel);
        if (typeof mainView !== "undefined" && mainView && mainView.globalDateRangeChanged) {
            mainView.globalDateRangeChanged(presetId, startDate, endDate, presetLabel);
        }
    }

    function clearFilter() {
        setFilterState(-1, "", "", i18n.dtr("ubtms", "No Filter (All Time)"));
    }

    function openCustomDateDialog() {
        PopupUtils.open(customDateDialogComponent, rootFilter);
    }

    Component {
        id: customDateDialogComponent

        Dialog {
            id: customDialog
            title: i18n.dtr("ubtms", "Custom Date Range")

            property date tempStart: rootFilter.startDate !== "" ? new Date(rootFilter.startDate) : new Date()
            property date tempEnd: rootFilter.endDate !== "" ? new Date(rootFilter.endDate) : new Date()

            ColumnLayout {
                width: parent.width
                spacing: units.gu(1.5)

                RowLayout {
                    Layout.fillWidth: true
                    spacing: units.gu(1)

                    Label {
                        text: i18n.dtr("ubtms", "From:")
                        Layout.preferredWidth: units.gu(6)
                    }

                    TextField {
                        id: startField
                        Layout.fillWidth: true
                        readOnly: true
                        text: Qt.formatDate(customDialog.tempStart, "yyyy-MM-dd")

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                let picker = PickerPanel.openDatePicker(customDialog, "tempStart", "Years|Months|Days");
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: units.gu(1)

                    Label {
                        text: i18n.dtr("ubtms", "To:")
                        Layout.preferredWidth: units.gu(6)
                    }

                    TextField {
                        id: endField
                        Layout.fillWidth: true
                        readOnly: true
                        text: Qt.formatDate(customDialog.tempEnd, "yyyy-MM-dd")

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                let picker = PickerPanel.openDatePicker(customDialog, "tempEnd", "Years|Months|Days");
                            }
                        }
                    }
                }
            }

            Button {
                text: i18n.dtr("ubtms", "Apply Range")
                color: LomiriColors.orange
                onClicked: {
                    var sStr = Qt.formatDate(customDialog.tempStart, "yyyy-MM-dd");
                    var eStr = Qt.formatDate(customDialog.tempEnd, "yyyy-MM-dd");
                    var label = sStr + " ~ " + eStr;
                    rootFilter.setFilterState(7, sStr, eStr, label);
                    PopupUtils.close(customDialog);
                }
            }

            Button {
                text: i18n.dtr("ubtms", "Cancel")
                onClicked: {
                    // Revert InlineOptionSelector selection to current active presetId if cancelled
                    rootFilter.suppressSignal = true;
                    inlinePresetSelector.selectedId = rootFilter.presetId;
                    inlinePresetSelector.selectedName = rootFilter.presetLabel;
                    rootFilter.suppressSignal = false;
                    PopupUtils.close(customDialog);
                }
            }
        }
    }

    Component.onCompleted: {
        var saved = Global.getDateRangeFilter();
        if (saved && saved.isFiltered) {
            setFilterState(saved.presetId, saved.startDate, saved.endDate, saved.presetLabel);
        } else {
            clearFilter();
        }
    }
}
