/*
 * MIT License
 * Copyright (c) 2025 CIT-Services
 */
import QtQuick 2.7
import Lomiri.Components 1.3
import "../../../../models/utils.js" as Utils
import "../../../components"
import "../js/taskFormUtils.js" as TaskFormUtils

Column {
    id: root

    property bool isReadOnly: false
    property real availableWidth: parent.width

    // Planned Hours
    property alias hoursText: hours_input.text

    // Date Range
    property alias dateRangeWidget: date_range_widget

    // Deadline
    property alias deadlineText: deadline_text.text

    signal hoursChanged(string text)
    signal deadlineChanged(string text)
    signal dateRangeChanged()

    width: root.availableWidth
    height: childrenRect.height
    spacing: units.gu(1)

    // ── Planned Hours Row ──
    Row {
        id: plannedh_row
        width: root.availableWidth
        anchors.leftMargin: units.gu(1)
        anchors.rightMargin: units.gu(1)
        spacing: units.gu(2)

        TSLabel {
            text: i18n.dtr("ubtms", "Planned Hours")
            width: parent.width * 0.25
            anchors.verticalCenter: parent.verticalCenter
        }

        TextField {
            id: hours_input
            readOnly: root.isReadOnly
            width: parent.width * 0.3
            height: units.gu(5)
            anchors.verticalCenter: parent.verticalCenter
            text: "01:00"
            placeholderText: i18n.dtr("ubtms", "e.g., 2:30 or 1.5")

            onTextChanged: root.hoursChanged(text)

            validator: RegExpValidator {
                regExp: /^(\d{1,3}(:\d{2})?|\d+(\.\d+)?)$/
            }

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                radius: units.gu(0.5)
                border.width: parent.activeFocus ? units.gu(0.2) : units.gu(0.1)
                border.color: parent.activeFocus ? LomiriColors.orange : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#d3d1d1" : "#999")
            }

            onFocusChanged: {
                if (!focus && text !== "" && TaskFormUtils.validateHoursInput(text)) {
                    text = TaskFormUtils.formatHoursDisplay(text);
                }
            }

            Keys.onReturnPressed: {
                if (text !== "" && TaskFormUtils.validateHoursInput(text)) {
                    text = TaskFormUtils.formatHoursDisplay(text);
                }
                focus = false;
            }
        }

        Row {
            spacing: units.gu(1)
            width: parent.width * 0.3
            anchors.verticalCenter: parent.verticalCenter
            visible: !root.isReadOnly

            TSButton {
                text: "-"
                enabled: !root.isReadOnly
                fontSize: units.gu(2.5)
                width: units.gu(4.5)
                height: units.gu(4.5)
                onClicked: incdecHrs(-1)
            }

            TSButton {
                text: "+"
                enabled: !root.isReadOnly
                fontSize: units.gu(2.5)
                width: units.gu(4.5)
                height: units.gu(4.5)
                onClicked: incdecHrs(1)
            }
        }
    }

    // ── Date Range Row ──
    Row {
        width: root.availableWidth
        height: date_range_widget.height

        Column {
            leftPadding: units.gu(1)
            DateRangeSelector {
                id: date_range_widget
                readOnly: root.isReadOnly
                width: root.availableWidth < units.gu(361) ? root.availableWidth - units.gu(35) : root.availableWidth - units.gu(30)

                onRangeChanged: root.dateRangeChanged()
            }
        }
    }

    // ── Deadline Row ──
    Row {
        width: root.availableWidth
        anchors.leftMargin: units.gu(1)
        anchors.rightMargin: units.gu(1)
        spacing: units.gu(2)

        TSLabel {
            text: i18n.dtr("ubtms", "Deadline")
            width: parent.width * 0.3
            anchors.verticalCenter: parent.verticalCenter
        }

        TSLabel {
            id: deadline_text
            text: i18n.dtr("ubtms", "Not set")
            enabled: !root.isReadOnly
            width: parent.width * 0.4
            fontBold: true
            anchors.verticalCenter: parent.verticalCenter
        }

        TSButton {
            text: i18n.dtr("ubtms", "Select")
            objectName: "button_deadline"
            enabled: !root.isReadOnly
            width: parent.width * 0.2
            height: units.gu(5)
            anchors.verticalCenter: parent.verticalCenter

            onClicked: deadlinePicker.open()
        }
    }

    // ── Deadline Picker ──
    CustomDatePicker {
        id: deadlinePicker
        titleText: i18n.dtr("ubtms", "Select Deadline")

        onDateSelected: {
            deadline_text.text = Qt.formatDate(new Date(date), "yyyy-MM-dd");
            root.deadlineChanged(deadline_text.text);
        }
    }

    // ── Helper functions ──
    function incdecHrs(value) {
        var currentText = hours_input.text || "0:00";
        var currentFloat = Utils.convertDurationToFloat(currentText);

        if (value === 1) {
            currentFloat += 1.0;
        } else {
            if (currentFloat >= 1.0) {
                currentFloat -= 1.0;
            }
        }

        hours_input.text = Utils.convertDecimalHoursToHHMM(currentFloat);
    }

    function formattedStartDate() {
        return date_range_widget.formattedStartDate ? date_range_widget.formattedStartDate() : "";
    }

    function formattedEndDate() {
        return date_range_widget.formattedEndDate ? date_range_widget.formattedEndDate() : "";
    }

    function setDateRange(start, end) {
        date_range_widget.setDateRange(start, end);
    }
}
