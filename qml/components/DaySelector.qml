import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3
import QtQuick.Dialogs 1.2
import Lomiri.Components.Pickers 1.3

Item {
    id: daySelector
    width: parent ? parent.width : 400
    property alias labelText: rangeLabel.text
    property date selectedDate: new Date()
    property bool readOnly: false
    signal dateChanged(date selectedDate)
    // color: "transparent"

    /**
     * Returns the selected date in "yyyy-MM-dd" format (for database/API use).
     * @returns {string}
     */
    function formattedDate() {
        return Qt.formatDate(selectedDate, "yyyy-MM-dd");
    }

    /**
     * Sets the selected date from a string or Date object.
     * Accepts either a JS Date or a valid string like "2025-06-12".
     * @param {string|Date} val
     */
    function setSelectedDate(val) {
        function toDate(input) {
            if (input instanceof Date)
                return input;
            if (typeof input === "string") {
                const d = new Date(input);
                return !isNaN(d.getTime()) ? d : null;
            }
            return null;
        }

        const parsed = toDate(val);

        if (parsed) {
            dateItem.date = parsed;
            selectedDate = parsed;
            dateChanged(selectedDate);
        } else {
            console.warn("❌ Invalid date input for setSelectedDate:", val);
        }
    }

    ColumnLayout {
        anchors.fill: parent
        //anchors.margins: units.gu(1)

        // Row for label and combo
        RowLayout {

            TSLabel {
                id: rangeLabel
                enabled: true
                text: "Date"
            }

            Item {
                // Add left margin using Layout.leftMargin for TSCombobox
                Layout.preferredWidth: units.gu(20)
                Layout.preferredHeight: units.gu(5)
                Layout.leftMargin: units.gu(4)

                TSCombobox {
                    id: dayCombo
                    anchors.fill: parent
                    model: ["Today", "Yesterday", "Custom"]
                    visible: !daySelector.readOnly
                    currentIndex: 0
                    onActivated: updateDate()
                    onAccepted: updateDate()
                }
            }

            Item {
                id: dateItem
                property date date: new Date()
                Layout.preferredWidth: parent.width * 0.5
                Layout.preferredHeight: parent.height
                Layout.leftMargin: units.gu(1)

                //   color: "white"

                TSLabel {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    enabled: !daySelector.readOnly
                    //readOnly: true
                    text: Qt.formatDate(dateItem.date, "dd-MM-yyyy")
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (daySelector.readOnly) {
                            return;
                        }

                        let result = PickerPanel.openDatePicker(dateItem, "date", "Years|Months|Days");
                        if (result) {
                            result.closed.connect(() => {
                                selectedDate = dateItem.date;
                                dateChanged(selectedDate);
                            });
                        }
                    }
                }
            }
        }
    }

    function updateDate() {
        const today = new Date();
        let newDate = new Date(today);

        switch (dayCombo.currentIndex) {
        case 0: // Today
            break;
        case 1: // Yesterday
            newDate.setDate(newDate.getDate() - 1);
            break;
        case 2: // Custom
            return; // let user pick manually
        }

        dateItem.date = newDate;
        selectedDate = newDate;
        dateChanged(selectedDate);
    }

    Component.onCompleted: {
        if (!selectedDate || isNaN(selectedDate.getTime())) {
            updateDate(); // fallback to Today/Yesterday/Custom logic
        } else {
            // If selectedDate already set externally, respect it
            dateItem.date = selectedDate;
        }
    }
}
