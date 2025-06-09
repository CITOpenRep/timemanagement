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

    ColumnLayout {
        spacing: 10
        anchors.fill: parent
        anchors.margins: 10

        Label {
            id: rangeLabel
            text: "When is this planned for?"
            font.bold: true
        }

        ComboBox {
            id: presetCombo
            model: ["Today", "This Week", "This Month"]
            currentIndex: 0
            onActivated: {updateDates()}
            onAccepted: {updateDates()}
        }

        RowLayout {
            spacing: 10

            // Start Date Picker Field
            ColumnLayout {
                spacing: 4
                Label {
                    text: "Start Date"
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
                        text: Qt.formatDate(startDateItem.date, "dd-MM-yyyy")
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            let result = PickerPanel.openDatePicker(startDateItem, "date", "Years|Months|Days")
                            if (result) {
                                result.closed.connect(() => {
                                    startDate = startDateItem.date
                                    rangeChanged(startDate, endDate)
                                })
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
                        text: Qt.formatDate(endDateItem.date, "dd-MM-yyyy")
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            let result = PickerPanel.openDatePicker(endDateItem, "date", "Years|Months|Days")
                            if (result) {
                                result.closed.connect(() => {
                                    endDate = endDateItem.date
                                    rangeChanged(startDate, endDate)
                                })
                            }
                        }
                    }
                }
            }
        }
    }

    function updateDates() {
        console.log("Calling updates")
        const today = new Date();
        let newStart = new Date(today);
        let newEnd = new Date(today);

        switch (presetCombo.currentIndex) {
        case 0: // Today
            break;

        case 1: // This Week
            const dow = today.getDay(); // 0 = Sunday, 6 = Saturday
            const offset = (dow === 0) ? 1 : (dow >= 6 ? 5 : 5 - dow);
            newEnd.setDate(newEnd.getDate() + offset);
            break;

        case 2: // This Month
            const year = today.getFullYear();
            const month = today.getMonth();
            let lastDay = new Date(year, month + 1, 0);
            const lastDow = lastDay.getDay();
            if (lastDow === 6) lastDay.setDate(lastDay.getDate() - 1);
            else if (lastDow === 0) lastDay.setDate(lastDay.getDate() - 2);
            newEnd = lastDay;
            break;

        case 3: // Custom
            return; // Let user pick manually
        }

        // Update internal date pickers and emit signal
        startDateItem.date = newStart;
        endDateItem.date = newEnd;
        startDate = newStart;
        endDate = newEnd;

       // console.log("Updating: startDate =", Qt.formatDate(newStart, "dd-MM-yyyy"))
       // console.log("Updating: startDateItem.date =", Qt.formatDate(startDateItem.date, "dd-MM-yyyy"))

        rangeChanged(startDate, endDate);
    }

    Component.onCompleted: updateDates()
}
