import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3
import QtQuick.Dialogs 1.2
import Lomiri.Components.Pickers 1.3
import ".."

Item {
    id: daySelector
    width: parent ? parent.width : 400
    height: dayCombo.height
    
    property string labelText: "Date"
    property date selectedDate: new Date()
    property bool readOnly: false
    signal dateChanged(date selectedDate)

    function formattedDate() {
        return Qt.formatDate(selectedDate, "yyyy-MM-dd");
    }

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
            selectedDate = parsed;
            
            // Update dayCombo selection
            const today = new Date();
            const yesterday = new Date(today);
            yesterday.setDate(yesterday.getDate() - 1);
            
            if (isSameDate(parsed, today)) {
                dayCombo.applyDeferredSelection(0, false);
            } else if (isSameDate(parsed, yesterday)) {
                dayCombo.applyDeferredSelection(1, false);
            } else {
                dayCombo.applyDeferredSelection(2, false);
            }
            
            updateModelData();
            dateChanged(selectedDate);
        } else {
            console.warn("❌ Invalid date input for setSelectedDate:", val);
        }
    }

    function isSameDate(d1, d2) {
        return d1.getFullYear() === d2.getFullYear() &&
               d1.getMonth() === d2.getMonth() &&
               d1.getDate() === d2.getDate();
    }

    function updateModelData() {
        const today = new Date();
        const yesterday = new Date(today);
        yesterday.setDate(yesterday.getDate() - 1);
        
        const todayStr = Qt.formatDate(today, "dd-MM-yyyy");
        const yesterdayStr = Qt.formatDate(yesterday, "dd-MM-yyyy");
        const currentStr = Qt.formatDate(selectedDate, "dd-MM-yyyy");
        
        dayCombo.modelData = [
            { id: 0, name: "Today (" + todayStr + ")" },
            { id: 1, name: "Yesterday (" + yesterdayStr + ")" },
            { id: 2, name: "Custom (" + currentStr + ")" }
        ];
    }

    function updateDate() {
        const today = new Date();
        let newDate = new Date(today);

        switch (dayCombo.selectedId) {
        case 0: // Today
            break;
        case 1: // Yesterday
            newDate.setDate(newDate.getDate() - 1);
            break;
        case 2: // Custom
            openCustomDatePicker();
            return;
        }

        selectedDate = newDate;
        updateModelData();
        dateChanged(selectedDate);
    }

    function openCustomDatePicker() {
        let result = PickerPanel.openDatePicker(daySelector, "selectedDate", "Years|Months|Days");
        if (result) {
            result.closed.connect(() => {
                dayCombo.applyDeferredSelection(2, false);
                updateModelData();
                dateChanged(selectedDate);
            });
        }
    }

    InlineOptionSelector {
        id: dayCombo
        width: parent.width
        labelText: daySelector.labelText
        selectorType: "date_type"
        readOnly: daySelector.readOnly
        enabledState: !daySelector.readOnly
        
        onSelectionMade: function(id, name, selectorType) {
            updateDate();
        }
    }

    Component.onCompleted: {
        const today = new Date();
        const yesterday = new Date(today);
        yesterday.setDate(yesterday.getDate() - 1);

        if (!selectedDate || isNaN(selectedDate.getTime())) {
            selectedDate = today;
            dayCombo.applyDeferredSelection(0, false);
        } else {
            if (isSameDate(selectedDate, today)) {
                dayCombo.applyDeferredSelection(0, false);
            } else if (isSameDate(selectedDate, yesterday)) {
                dayCombo.applyDeferredSelection(1, false);
            } else {
                dayCombo.applyDeferredSelection(2, false);
            }
        }
        updateModelData();
    }
}
