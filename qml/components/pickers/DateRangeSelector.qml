import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3
import QtQuick.Dialogs 1.2
import Lomiri.Components.Pickers 1.3
import ".."

Item {
    id: dateRangeSelector
    width: parent ? parent.width : units.gu(50)
    implicitHeight: layout.implicitHeight
    height: layout.implicitHeight
    property alias labelText: presetSelector.labelText
    property date startDate: new Date()
    property date endDate: new Date()
    signal rangeChanged(date start, date end)
    property bool readOnly: false
    property bool isStartDateValid: true
    property bool isEndDateValid: true

    /**
     * Returns the selected start date as a formatted string (yyyy-MM-dd).
     * @returns {string}
     */
    function formattedStartDate() {
        return Qt.formatDate(startDate, "yyyy-MM-dd");
    }

    /**
     * Returns the selected end date as a formatted string (yyyy-MM-dd).
     * @returns {string}
     */
    function formattedEndDate() {
        return Qt.formatDate(endDate, "yyyy-MM-dd");
    }

    function setDateRange(start, end) {
        function toDate(val) {
            if (val instanceof Date)
                return val;
            if (typeof val === "string") {
                const d = new Date(val);
                return !isNaN(d.getTime()) ? d : null;
            }
            return null;
        }

        const sDate = toDate(start);
        const eDate = toDate(end);

        if (sDate) {
            startDateItem.date = sDate;
            startDate = sDate;
            isStartDateValid = true;
        } else {
            console.warn("Invalid start date:", start);
            isStartDateValid = false;
        }

        if (eDate) {
            endDateItem.date = eDate;
            endDate = eDate;
            isEndDateValid = true;
        } else {
            console.warn("Invalid end date:", end);
            isEndDateValid = false;
        }

        rangeChanged(startDate, endDate);
    }

    ColumnLayout {
        id: layout
        width: parent.width

        InlineOptionSelector {
            id: presetSelector
            Layout.fillWidth: true
            Layout.preferredHeight: height
            labelText: "Date Range"
            enabledState: !dateRangeSelector.readOnly
            readOnly: dateRangeSelector.readOnly
            visible: !dateRangeSelector.readOnly

            modelData: [
                {id: 0, name: i18n.dtr("ubtms", "Today")},
                {id: 1, name: i18n.dtr("ubtms", "This Week")},
                {id: 2, name: i18n.dtr("ubtms", "Next Week")},
                {id: 3, name: i18n.dtr("ubtms", "This Month")},
                {id: 4, name: i18n.dtr("ubtms", "Next Month")}
            ]

            selectedId: 1 // default is "This Week" (id: 1)

            onSelectionMade: {
                dateRangeSelector.updateDates();
            }
        }

        RowLayout {
            spacing: units.gu(1.2)

            // Start Date Picker Field
            ColumnLayout {
                spacing: units.gu(0.5)
                TSLabel {
                    text: "Start Date"
                    enabled: !dateRangeSelector.readOnly
                    // font.pixelSize: units.gu(1.8)
                }

                Item {
                    id: startDateItem
                    property date date: new Date()
                    Layout.preferredWidth: units.gu(20)
                    Layout.preferredHeight: units.gu(5)

                    TextField {
                        anchors.fill: parent
                        readOnly: true
                        enabled: !dateRangeSelector.readOnly
                        text: isStartDateValid ? Qt.formatDate(startDateItem.date, "dd-MM-yyyy") : ""
                        placeholderText: isStartDateValid ? "" : "No date set"
                        color: isStartDateValid ? "black" : "gray"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!dateRangeSelector.readOnly) {
                                let result = PickerPanel.openDatePicker(startDateItem, "date", "Years|Months|Days");
                                if (result) {
                                    result.closed.connect(() => {
                                        startDate = startDateItem.date;
                                        isStartDateValid = true;
                                        rangeChanged(startDate, endDate);
                                    });
                                }
                            }
                        }
                    }
                }
            }

            // End Date Picker Field
            ColumnLayout {
                spacing: units.gu(0.5)
                TSLabel {
                    text: "End Date"
                    enabled: !dateRangeSelector.readOnly
                    //  font.pixelSize: units.gu(1.8)
                }

                Item {
                    id: endDateItem
                    property date date: new Date()
                    Layout.preferredWidth: units.gu(20)
                    Layout.preferredHeight: units.gu(5)

                    TextField {
                        anchors.fill: parent
                        readOnly: true
                        enabled: !dateRangeSelector.readOnly
                        text: isEndDateValid ? Qt.formatDate(endDateItem.date, "dd-MM-yyyy") : ""
                        placeholderText: isEndDateValid ? "" : "No date set"
                        color: isEndDateValid ? "black" : "gray"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!dateRangeSelector.readOnly) {
                                let result = PickerPanel.openDatePicker(endDateItem, "date", "Years|Months|Days");
                                if (result) {
                                    result.closed.connect(() => {
                                        endDate = endDateItem.date;
                                        isEndDateValid = true;
                                        rangeChanged(startDate, endDate);
                                    });
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function updateDates() {
        const today = new Date();
        let newStart = new Date(today);
        let newEnd = new Date(today);

        switch (presetSelector.selectedId) {
        case 0 // Today
        :
            break;
        case 1 // This Week
        :
            const dow = today.getDay();
            // For weekend handling:
            // - Sunday (0): keep start and end as today
            // - Saturday (6): start = Saturday (today), end = Sunday (tomorrow)
            if (dow === 0) {
                // Sunday: start and end are the same (today)
                break;
            } else if (dow === 6) {
                // Saturday: set end to Sunday
                newStart = new Date(today);
                newEnd = new Date(today);
                newEnd.setDate(today.getDate() + 1);
                break;
            } else {
                // Weekday: calculate Monday of current week as start date
                const daysFromMonday = dow - 1; // Monday = 1, so dow - 1 gives days from Monday
                newStart.setDate(today.getDate() - daysFromMonday);
                // End date should be Friday of current week
                const daysUntilFriday = 5 - dow;
                newEnd.setDate(today.getDate() + daysUntilFriday);
            }
            break;
        case 2 // Next Week
        :
            const currentDow = today.getDay();
            // Start of next week (Monday)
            const daysUntilNextMonday = currentDow === 0 ? 1 : (8 - currentDow);
            newStart.setDate(today.getDate() + daysUntilNextMonday);
            // End of next week (Friday)
            newEnd.setDate(today.getDate() + daysUntilNextMonday + 4);
            break;
        case 3 // This Month
        :
            const year = today.getFullYear();
            const month = today.getMonth();
            let lastDay = new Date(year, month + 1, 0);
            const lastDow = lastDay.getDay();
            if (lastDow === 6)
                lastDay.setDate(lastDay.getDate() - 1);
            else if (lastDow === 0)
                lastDay.setDate(lastDay.getDate() - 2);
            newEnd = lastDay;
            break;
        case 4 // Next Month
        :
            const nextMonthYear = today.getMonth() === 11 ? today.getFullYear() + 1 : today.getFullYear();
            const nextMonth = today.getMonth() === 11 ? 0 : today.getMonth() + 1;
            // First day of next month
            newStart = new Date(nextMonthYear, nextMonth, 1);
            // Last working day of next month
            let nextMonthLastDay = new Date(nextMonthYear, nextMonth + 1, 0);
            const nextMonthLastDow = nextMonthLastDay.getDay();
            if (nextMonthLastDow === 6)
                nextMonthLastDay.setDate(nextMonthLastDay.getDate() - 1);
            else if (nextMonthLastDow === 0)
                nextMonthLastDay.setDate(nextMonthLastDay.getDate() - 2);
            newEnd = nextMonthLastDay;
            break;
        }

        startDateItem.date = newStart;
        endDateItem.date = newEnd;
        startDate = newStart;
        endDate = newEnd;
        isStartDateValid = true;
        isEndDateValid = true;
        rangeChanged(startDate, endDate);
    }

    Component.onCompleted: updateDates()
}
