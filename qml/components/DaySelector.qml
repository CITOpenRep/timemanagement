import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3
import QtQuick.Dialogs 1.2
import Lomiri.Components.Pickers 1.3

Rectangle {
    id: daySelector
    width: parent ? parent.width : 400
    property alias labelText: rangeLabel.text
    property date selectedDate: new Date()
    signal dateChanged(date selectedDate)
    color: "transparent"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: units.gu(1)

        // Row for label and combo
        RowLayout {
            Label {
                id: rangeLabel
                text: "Date"
            }

            TSCombobox {
                id: dayCombo
                model: ["Today", "Yesterday", "Custom"]
                currentIndex: 0
                enabled: daySelector.enabled
                onActivated: {
                    updateDate();
                }
                onAccepted: {
                    updateDate();
                }
                //Layout.preferredWidth: 200
            }
            Item {
                id: dateItem
                property date date: new Date()
                Layout.preferredWidth: parent.width * 0.5
                Layout.preferredHeight: parent.height

                TextField {
                    anchors.fill: parent
                    readOnly: true
                    text: Qt.formatDate(dateItem.date, "dd-MM-yyyy")
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
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
