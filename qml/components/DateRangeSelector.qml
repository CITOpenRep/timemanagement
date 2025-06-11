import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3
import QtQuick.Dialogs 1.2
import Lomiri.Components.Pickers 1.3

Item {
    id: dateRangeSelector
    width: parent ? parent.width : 400
    property alias labelText: rangeLabel.text
    property date startDate: new Date()
    property date endDate: new Date()
    signal rangeChanged(date start, date end)
    property bool readOnly: false
    property bool isStartDateValid: true
    property bool isEndDateValid: true

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
        anchors.fill: parent

        TSLabel {
            id: rangeLabel
            text: "Date Range"
        }

        ComboBox {
            id: presetCombo
            model: ["Today", "This Week", "This Month"]
            currentIndex: 0
            visible: !dateRangeSelector.readOnly
            background: Rectangle {
                color: "transparent"
                border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#d3d1d1" : "transparent"
                border.width: 1
                radius: units.gu ? units.gu(0.5) : 4
            }
            contentItem: Text {
                text: presetCombo.displayText
                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: units.gu ? units.gu(2) : 8
            }
            delegate: ItemDelegate {
                width: presetCombo.width
                hoverEnabled: true
                contentItem: Text {
                    text: modelData
                    color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                    leftPadding: units.gu ? units.gu(1) : 4
                    elide: Text.ElideRight
                }
                background: Rectangle {
                    color: hovered
                        ? (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#444" : "#e0e0e0")
                        : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#222" : "white")
                    radius: 4
                }
            }
            onActivated: updateDates()
            onAccepted: updateDates()
        }

        RowLayout {
            spacing: 10

            // Start Date Picker Field
            ColumnLayout {
                spacing: 4
                Label {
                    text: "Start Date"
                    enabled: !dateRangeSelector.readOnly
                    font.pixelSize: 14
                }

                Item {
                    id: startDateItem
                    property date date: new Date()
                    Layout.preferredWidth: 160
                    Layout.preferredHeight: 40

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
                spacing: 4
                Label {
                    text: "End Date"
                    enabled: !dateRangeSelector.readOnly
                    font.pixelSize: 14
                }

                Item {
                    id: endDateItem
                    property date date: new Date()
                    Layout.preferredWidth: 160
                    Layout.preferredHeight: 40

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

        switch (presetCombo.currentIndex) {
        case 0: // Today
            console.log("Today");
            break;
        case 1: // This Week
            console.log("This week");
            const dow = today.getDay();
            const offset = (dow === 0) ? 1 : (dow >= 6 ? 5 : 5 - dow);
            newEnd.setDate(newEnd.getDate() + offset);
            break;
        case 2: // This Month
            console.log("This Month");
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
