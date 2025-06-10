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
                Layout.preferredWidth: units.gu(20)
                Layout.preferredHeight: units.gu(5.5)

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
