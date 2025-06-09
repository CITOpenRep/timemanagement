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
    signal dateChanged(date selectedDate)

    ColumnLayout {
        spacing: 10
        anchors.fill: parent
        anchors.margins: 10

        Label {
            id: rangeLabel
            text: "Which day are you logging for?"
            font.bold: true
        }

        ComboBox {
            id: dayCombo
            model: ["Today", "Yesterday", "Custom"]
            currentIndex: 0
            onActivated: { updateDate() }
            onAccepted: { updateDate() }
        }

        ColumnLayout {
            spacing: 4
            Label {
                text: "Date"
                font.pixelSize: 14
            }

            Item {
                id: dateItem
                property date date: new Date()
                Layout.preferredWidth: 160
                Layout.preferredHeight: 40

                TextField {
                    anchors.fill: parent
                    readOnly: true
                    text: Qt.formatDate(dateItem.date, "dd-MM-yyyy")
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        let result = PickerPanel.openDatePicker(dateItem, "date", "Years|Months|Days")
                        if (result) {
                            result.closed.connect(() => {
                                selectedDate = dateItem.date
                                dateChanged(selectedDate)
                            })
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

    Component.onCompleted: updateDate()
}
