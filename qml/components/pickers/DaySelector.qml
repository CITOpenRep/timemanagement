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
    property date customDate: selectedDate
    property bool showTomorrow: false
    property bool readOnly: false
    signal dateChanged(date selectedDate)

    function formattedDate() {
        return Qt.formatDate(selectedDate, "yyyy-MM-dd");
    }

    function getRelativeDate(baseDate) {
        const d = new Date(baseDate);
        d.setDate(d.getDate() + (showTomorrow ? 1 : -1));
        return d;
    }

    function getRelativeLabel() {
        return showTomorrow ? i18n.dtr("ubtms", "Tomorrow") : i18n.dtr("ubtms", "Yesterday");
    }

    function isSameDate(d1, d2) {
        if (!d1 || !d2 || !(d1 instanceof Date) || !(d2 instanceof Date) || isNaN(d1.getTime()) || isNaN(d2.getTime())) {
            return false;
        }
        return d1.getFullYear() === d2.getFullYear() &&
               d1.getMonth() === d2.getMonth() &&
               d1.getDate() === d2.getDate();
    }

    function syncComboSelection(targetDate) {
        const today = new Date();
        const relativeDate = getRelativeDate(today);

        if (isSameDate(targetDate, today)) {
            dayCombo.applyDeferredSelection(0, false);
        } else if (isSameDate(targetDate, relativeDate)) {
            dayCombo.applyDeferredSelection(1, false);
        } else {
            dayCombo.applyDeferredSelection(2, false);
        }
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
            customDate = parsed;

            syncComboSelection(parsed);
            updateModelData();
            dateChanged(selectedDate);
        } else {
            console.warn("Invalid date input for setSelectedDate:", val);
        }
    }

    function updateModelData() {
        const today = new Date();
        const relativeDate = getRelativeDate(today);

        const todayStr = Qt.formatDate(today, "dd-MM-yyyy");
        const relativeStr = Qt.formatDate(relativeDate, "dd-MM-yyyy");
        const currentStr = Qt.formatDate(selectedDate, "dd-MM-yyyy");

        dayCombo.modelData = [
            { id: 0, name: i18n.dtr("ubtms", "Today") + " (" + todayStr + ")" },
            { id: 1, name: getRelativeLabel() + " (" + relativeStr + ")" },
            { id: 2, name: i18n.dtr("ubtms", "Custom") + " (" + currentStr + ")" }
        ];
    }

    function updateDate() {
        const today = new Date();
        let newDate = new Date(today);

        switch (dayCombo.selectedId) {
        case 0: // Today
            break;
        case 1: // Relative (Tomorrow or Yesterday)
            newDate = getRelativeDate(today);
            break;
        case 2: // Custom
            openCustomDatePicker();
            return;
        }

        selectedDate = newDate;
        customDate = newDate;
        updateModelData();
        dateChanged(selectedDate);
    }

    function openCustomDatePicker() {
        customDate = selectedDate;
        let result = PickerPanel.openDatePicker(daySelector, "customDate", "Years|Months|Days");
        if (result) {
            if (result.picker) {
                result.picker.minimum = new Date(2000, 0, 1);
            }
            result.closed.connect(function() {
                if (customDate && !isNaN(customDate.getTime())) {
                    selectedDate = customDate;
                    dayCombo.applyDeferredSelection(2, false);
                    updateModelData();
                    dateChanged(selectedDate);
                }
            });
        }
    }

    onShowTomorrowChanged: {
        if (selectedDate && !isNaN(selectedDate.getTime())) {
            syncComboSelection(selectedDate);
        }
        updateModelData();
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

        if (!selectedDate || isNaN(selectedDate.getTime())) {
            selectedDate = today;
            customDate = today;
            dayCombo.applyDeferredSelection(0, false);
        } else {
            customDate = selectedDate;
            syncComboSelection(selectedDate);
        }
        updateModelData();
    }
}
