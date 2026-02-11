/*
* MIT License
*
* Copyright (c) 2025 CIT-Services
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.LocalStorage 2.7 as Sql
import Lomiri.Components 1.3
import "../components"
import "../components/settings"

Page {
    id: notificationSettingsPage
    title: i18n.dtr("ubtms", "Notifications")

    header: SettingsHeader {
        id: pageHeader
        title: notificationSettingsPage.title
    }

    // Settings Helper Functions
    function getAutoSyncSetting(key) {
        var defaultValues = {
            "autosync_enabled": "true",
            "sync_interval_minutes": "15",
            "sync_direction": "both",
            "notifications_enabled": "true",
            "notification_schedule_enabled": "false",
            "notification_timezone": "",
            "notification_active_start": "09:00",
            "notification_active_end": "18:00",
            "notification_working_days": "1,2,3,4,5"
        };

        try {
            var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
            var result = defaultValues[key] || "";

            db.transaction(function (tx) {
                // Create settings table if it doesn't exist
                tx.executeSql('CREATE TABLE IF NOT EXISTS app_settings (key TEXT PRIMARY KEY, value TEXT)');

                var rs = tx.executeSql('SELECT value FROM app_settings WHERE key = ?', [key]);
                if (rs.rows.length > 0) {
                    result = rs.rows.item(0).value;
                }
            });

            return result;
        } catch (e) {
            console.warn("Error reading setting:", e);
            return defaultValues[key] || "";
        }
    }

    function saveAutoSyncSetting(key, value) {
        try {
            var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);

            db.transaction(function (tx) {
                // Create settings table if it doesn't exist
                tx.executeSql('CREATE TABLE IF NOT EXISTS app_settings (key TEXT PRIMARY KEY, value TEXT)');

                // Save setting (INSERT OR REPLACE)
                tx.executeSql('INSERT OR REPLACE INTO app_settings (key, value) VALUES (?, ?)', [key, value]);
            });

            //console.log("Setting saved:", key, "=", value);
        } catch (e) {
            console.warn("Error saving setting:", e);
        }
    }

    // --- State properties (mutable, refreshed on page load) ---

    // Is sync direction "upload_only"?  (regular property — re-assigned in reloadSettings)
    property bool isSyncUploadOnly: false

    // Master notification toggle (persisted)
    property bool notificationsEnabled: true

    // Helper: whether notification sub-controls should be interactive
    readonly property bool notificationsEffectivelyEnabled:
        notificationsEnabled && !isSyncUploadOnly

    // Load / reload all settings from DB
    function reloadSettings() {
        isSyncUploadOnly = (getAutoSyncSetting("sync_direction") === "upload_only");
        notificationsEnabled = (getAutoSyncSetting("notifications_enabled") === "true");
    }

    Component.onCompleted: reloadSettings()

    // ── Working-day helpers  (day indices: 0=Sun, 1=Mon … 6=Sat) ──
    function getWorkingDays() {
        var str = getAutoSyncSetting("notification_working_days");
        if (!str || str.length === 0) return [1,2,3,4,5]; // default Mon-Fri
        var arr = [];
        var parts = str.split(",");
        for (var i = 0; i < parts.length; i++) {
            var v = parseInt(parts[i].trim());
            if (!isNaN(v) && v >= 0 && v <= 6) arr.push(v);
        }
        return arr;
    }

    function saveWorkingDays(daysArray) {
        saveAutoSyncSetting("notification_working_days", daysArray.join(","));
    }

    function isDaySelected(dayIndex) {
        var days = getWorkingDays();
        return days.indexOf(dayIndex) !== -1;
    }

    function toggleDay(dayIndex) {
        var days = getWorkingDays();
        var idx = days.indexOf(dayIndex);
        if (idx !== -1) {
            days.splice(idx, 1);
        } else {
            days.push(dayIndex);
        }
        days.sort();
        saveWorkingDays(days);
    }

    // ── Scrollable content ──
    Flickable {
        anchors.top: pageHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        contentHeight: mainColumn.height + units.gu(4)
        clip: true

        Rectangle {
            anchors.fill: parent
            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#111" : "transparent"
        }

        Column {
            id: mainColumn
            width: parent.width - units.gu(4)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: units.gu(2)
            spacing: units.gu(2)

            // ──────────────────────────────────────────────────
            // 1. Master Notification Toggle Section
            // ──────────────────────────────────────────────────
            Rectangle {
                width: parent.width
                height: masterNotificationSection.height + units.gu(2)
                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#1a1a1a" : "#f8f8f8"
                border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#444" : "#ddd"
                border.width: 1
                radius: units.gu(1)

                Column {
                    id: masterNotificationSection
                    width: parent.width - units.gu(2)
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: units.gu(1)
                    spacing: units.gu(1.5)

                    // Header
                    Text {
                        text: i18n.dtr("ubtms", "Push Notifications")
                        font.pixelSize: units.gu(2.5)
                        font.bold: true
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#e0e0e0" : "#333"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: i18n.dtr("ubtms", "Receive push notifications for task updates and reminders")
                        font.pixelSize: units.gu(1.5)
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#b0b0b0" : "#666"
                        anchors.horizontalCenter: parent.horizontalCenter
                        wrapMode: Text.WordWrap
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                    }

                    // Enable Notifications Toggle
                    Row {
                        width: parent.width
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: units.gu(2)
                        opacity: notificationSettingsPage.isSyncUploadOnly ? 0.5 : 1.0

                        Text {
                            text: i18n.dtr("ubtms", "Enable Notifications")
                            font.pixelSize: units.gu(2)
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#e0e0e0" : "#333"
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - notificationMasterSwitch.width - units.gu(4)
                        }

                        Switch {
                            id: notificationMasterSwitch
                            checked: notificationSettingsPage.notificationsEnabled && !notificationSettingsPage.isSyncUploadOnly
                            enabled: !notificationSettingsPage.isSyncUploadOnly
                            anchors.verticalCenter: parent.verticalCenter
                            onClicked: {
                                notificationSettingsPage.notificationsEnabled = checked;
                                saveAutoSyncSetting("notifications_enabled", checked ? "true" : "false");
                            }
                        }
                    }

                    // Info text when disabled due to sync direction
                    Text {
                        visible: notificationSettingsPage.isSyncUploadOnly
                        text: i18n.dtr("ubtms", "⚠ Notifications are disabled when Background Sync is set to Upload Only")
                        font.pixelSize: units.gu(1.3)
                        font.italic: true
                        color: "#e67e22"
                        anchors.horizontalCenter: parent.horizontalCenter
                        wrapMode: Text.WordWrap
                        width: parent.width - units.gu(2)
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            // ──────────────────────────────────────────────────
            // 2. Notification Schedule Settings Section
            // ──────────────────────────────────────────────────
            Rectangle {
                width: parent.width
                height: notificationScheduleSection.height + units.gu(2)
                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#1a1a1a" : "#f8f8f8"
                border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#444" : "#ddd"
                border.width: 1
                radius: units.gu(1)
                opacity: notificationSettingsPage.notificationsEffectivelyEnabled ? 1.0 : 0.5

                Column {
                    id: notificationScheduleSection
                    width: parent.width - units.gu(2)
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: units.gu(1)
                    spacing: units.gu(1.5)

                    // Header
                    Text {
                        text: i18n.dtr("ubtms", "Notification Schedule")
                        font.pixelSize: units.gu(2.5)
                        font.bold: true
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#e0e0e0" : "#333"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: i18n.dtr("ubtms", "Set your timezone, working days and active hours to receive notifications only during work time")
                        font.pixelSize: units.gu(1.5)
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#b0b0b0" : "#666"
                        anchors.horizontalCenter: parent.horizontalCenter
                        wrapMode: Text.WordWrap
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                    }

                    // Enable Notification Schedule Toggle
                    Row {
                        width: parent.width
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: units.gu(2)

                        Text {
                            text: i18n.dtr("ubtms", "Enable Schedule")
                            font.pixelSize: units.gu(2)
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#e0e0e0" : "#333"
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - notificationScheduleSwitch.width - units.gu(4)
                        }

                        Switch {
                            id: notificationScheduleSwitch
                            checked: getAutoSyncSetting("notification_schedule_enabled") === "true"
                            enabled: notificationSettingsPage.notificationsEffectivelyEnabled
                            anchors.verticalCenter: parent.verticalCenter
                            onClicked: {
                                saveAutoSyncSetting("notification_schedule_enabled", checked ? "true" : "false");
                            }
                        }
                    }

                    // Helper: are schedule sub-controls active?
                    property bool scheduleActive: notificationScheduleSwitch.checked && notificationScheduleSwitch.enabled

                    // Timezone Selector
                    Row {
                        width: parent.width
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: units.gu(2)
                        opacity: notificationScheduleSection.scheduleActive ? 1.0 : 0.5

                        Text {
                            text: i18n.dtr("ubtms", "Timezone")
                            font.pixelSize: units.gu(2)
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#e0e0e0" : "#333"
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - timezoneCombo.width - units.gu(4)
                        }

                        ComboBox {
                            id: timezoneCombo
                            width: units.gu(22)
                            enabled: notificationScheduleSection.scheduleActive
                            model: [
                                { text: "System Default", value: "" },
                                { text: "UTC", value: "UTC" },
                                { text: "America/New_York", value: "America/New_York" },
                                { text: "America/Chicago", value: "America/Chicago" },
                                { text: "America/Denver", value: "America/Denver" },
                                { text: "America/Los_Angeles", value: "America/Los_Angeles" },
                                { text: "America/Toronto", value: "America/Toronto" },
                                { text: "America/Mexico_City", value: "America/Mexico_City" },
                                { text: "America/Sao_Paulo", value: "America/Sao_Paulo" },
                                { text: "Europe/London", value: "Europe/London" },
                                { text: "Europe/Paris", value: "Europe/Paris" },
                                { text: "Europe/Berlin", value: "Europe/Berlin" },
                                { text: "Europe/Madrid", value: "Europe/Madrid" },
                                { text: "Europe/Rome", value: "Europe/Rome" },
                                { text: "Europe/Amsterdam", value: "Europe/Amsterdam" },
                                { text: "Europe/Moscow", value: "Europe/Moscow" },
                                { text: "Asia/Dubai", value: "Asia/Dubai" },
                                { text: "Asia/Kolkata", value: "Asia/Kolkata" },
                                { text: "Asia/Mumbai", value: "Asia/Mumbai" },
                                { text: "Asia/Bangkok", value: "Asia/Bangkok" },
                                { text: "Asia/Singapore", value: "Asia/Singapore" },
                                { text: "Asia/Hong_Kong", value: "Asia/Hong_Kong" },
                                { text: "Asia/Shanghai", value: "Asia/Shanghai" },
                                { text: "Asia/Tokyo", value: "Asia/Tokyo" },
                                { text: "Asia/Seoul", value: "Asia/Seoul" },
                                { text: "Australia/Sydney", value: "Australia/Sydney" },
                                { text: "Australia/Melbourne", value: "Australia/Melbourne" },
                                { text: "Pacific/Auckland", value: "Pacific/Auckland" },
                                { text: "Africa/Cairo", value: "Africa/Cairo" },
                                { text: "Africa/Johannesburg", value: "Africa/Johannesburg" }
                            ]
                            textRole: "text"
                            currentIndex: {
                                var saved = getAutoSyncSetting("notification_timezone");
                                for (var i = 0; i < model.length; i++) {
                                    if (model[i].value === saved) return i;
                                }
                                return 0; // Default to System Default
                            }
                            onCurrentIndexChanged: {
                                if (currentIndex >= 0 && currentIndex < model.length) {
                                    saveAutoSyncSetting("notification_timezone", model[currentIndex].value);
                                }
                            }
                        }
                    }

                    // ──────────────────────────────────
                    // Working Days Selector
                    // ──────────────────────────────────
                    Text {
                        text: i18n.dtr("ubtms", "Working Days")
                        font.pixelSize: units.gu(1.8)
                        font.bold: true
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#e0e0e0" : "#333"
                        anchors.horizontalCenter: parent.horizontalCenter
                        opacity: notificationScheduleSection.scheduleActive ? 1.0 : 0.5
                    }

                    Text {
                        text: i18n.dtr("ubtms", "Notifications will only be sent on selected days")
                        font.pixelSize: units.gu(1.3)
                        font.italic: true
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#888" : "#888"
                        anchors.horizontalCenter: parent.horizontalCenter
                        wrapMode: Text.WordWrap
                        width: parent.width - units.gu(2)
                        horizontalAlignment: Text.AlignHCenter
                        opacity: notificationScheduleSection.scheduleActive ? 1.0 : 0.5
                    }

                    // Day buttons row
                    Row {
                        id: dayButtonsRow
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: units.gu(0.5)
                        opacity: notificationScheduleSection.scheduleActive ? 1.0 : 0.5

                        // Refresh counter to force button re-evaluation after toggle
                        property int refreshCounter: 0

                        Repeater {
                            // Model: ordered Mon–Sun; dayIndex uses 0=Sun,1=Mon…6=Sat
                            model: [
                                { dayIndex: 1, label: "Mon" },
                                { dayIndex: 2, label: "Tue" },
                                { dayIndex: 3, label: "Wed" },
                                { dayIndex: 4, label: "Thu" },
                                { dayIndex: 5, label: "Fri" },
                                { dayIndex: 6, label: "Sat" },
                                { dayIndex: 0, label: "Sun" }
                            ]

                            delegate: Rectangle {
                                id: dayButton
                                width: units.gu(5)
                                height: units.gu(4.5)
                                radius: units.gu(0.5)
                                border.width: 1

                                property bool isSelected: {
                                    // Reference refreshCounter so binding re-evaluates on toggle
                                    var _unused = dayButtonsRow.refreshCounter;
                                    return isDaySelected(modelData.dayIndex);
                                }

                                color: {
                                    if (!notificationScheduleSection.scheduleActive)
                                        return theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#222" : "#e0e0e0";
                                    if (isSelected)
                                        return theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#2d7d46" : "#4CAF50";
                                    return theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#333" : "#fff";
                                }

                                border.color: {
                                    if (isSelected && notificationScheduleSection.scheduleActive)
                                        return theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#4CAF50" : "#388E3C";
                                    return theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#555" : "#ccc";
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: i18n.dtr("ubtms", modelData.label)
                                    font.pixelSize: units.gu(1.5)
                                    font.bold: dayButton.isSelected
                                    color: {
                                        if (dayButton.isSelected && notificationScheduleSection.scheduleActive)
                                            return "#fff";
                                        return theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#b0b0b0" : "#555";
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: notificationScheduleSection.scheduleActive
                                    onClicked: {
                                        toggleDay(modelData.dayIndex);
                                        dayButtonsRow.refreshCounter++;
                                    }
                                }
                            }
                        }
                    }

                    // ──────────────────────────────────
                    // Working Hours
                    // ──────────────────────────────────
                    Text {
                        text: i18n.dtr("ubtms", "Working Hours (notifications allowed)")
                        font.pixelSize: units.gu(1.8)
                        font.bold: true
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#e0e0e0" : "#333"
                        anchors.horizontalCenter: parent.horizontalCenter
                        opacity: notificationScheduleSection.scheduleActive ? 1.0 : 0.5
                    }

                    // Start / End Time Row
                    Row {
                        width: parent.width
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: units.gu(2)
                        opacity: notificationScheduleSection.scheduleActive ? 1.0 : 0.5

                        Text {
                            text: i18n.dtr("ubtms", "From")
                            font.pixelSize: units.gu(2)
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#e0e0e0" : "#333"
                            anchors.verticalCenter: parent.verticalCenter
                            width: units.gu(8)
                        }

                        Rectangle {
                            id: startTimeButton
                            width: units.gu(12)
                            height: units.gu(4)
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#333" : "#fff"
                            border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#555" : "#ccc"
                            border.width: 1
                            radius: units.gu(0.5)

                            property string timeValue: getAutoSyncSetting("notification_active_start") || "09:00"

                            Text {
                                anchors.centerIn: parent
                                text: parent.timeValue
                                font.pixelSize: units.gu(2)
                                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#e0e0e0" : "#333"
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: notificationScheduleSection.scheduleActive
                                onClicked: {
                                    var parts = startTimeButton.timeValue.split(":");
                                    var hour = parseInt(parts[0]) || 9;
                                    var minute = parseInt(parts[1]) || 0;
                                    startTimePicker.open(hour, minute);
                                }
                            }
                        }

                        Text {
                            text: i18n.dtr("ubtms", "To")
                            font.pixelSize: units.gu(2)
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#e0e0e0" : "#333"
                            anchors.verticalCenter: parent.verticalCenter
                            width: units.gu(4)
                        }

                        Rectangle {
                            id: endTimeButton
                            width: units.gu(12)
                            height: units.gu(4)
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#333" : "#fff"
                            border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#555" : "#ccc"
                            border.width: 1
                            radius: units.gu(0.5)

                            property string timeValue: getAutoSyncSetting("notification_active_end") || "18:00"

                            Text {
                                anchors.centerIn: parent
                                text: parent.timeValue
                                font.pixelSize: units.gu(2)
                                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#e0e0e0" : "#333"
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: notificationScheduleSection.scheduleActive
                                onClicked: {
                                    var parts = endTimeButton.timeValue.split(":");
                                    var hour = parseInt(parts[0]) || 18;
                                    var minute = parseInt(parts[1]) || 0;
                                    endTimePicker.open(hour, minute);
                                }
                            }
                        }
                    }

                    // Info text
                    Text {
                        text: i18n.dtr("ubtms", "Push notifications will only be sent during working hours on working days. Overnight schedules (e.g., 22:00 to 06:00) are supported.")
                        font.pixelSize: units.gu(1.3)
                        font.italic: true
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#888" : "#888"
                        anchors.horizontalCenter: parent.horizontalCenter
                        wrapMode: Text.WordWrap
                        width: parent.width - units.gu(2)
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                // Time Picker for Start Time
                TimePickerPopup {
                    id: startTimePicker
                    onTimeSelected: function(hour, minute) {
                        var timeStr = (hour < 10 ? "0" + hour : hour) + ":" + (minute < 10 ? "0" + minute : minute);
                        startTimeButton.timeValue = timeStr;
                        saveAutoSyncSetting("notification_active_start", timeStr);
                    }
                }

                // Time Picker for End Time
                TimePickerPopup {
                    id: endTimePicker
                    onTimeSelected: function(hour, minute) {
                        var timeStr = (hour < 10 ? "0" + hour : hour) + ":" + (minute < 10 ? "0" + minute : minute);
                        endTimeButton.timeValue = timeStr;
                        saveAutoSyncSetting("notification_active_end", timeStr);
                    }
                }
            }
        }
    }

    // Re-read settings when page becomes visible (e.g. navigating back from Sync settings)
    onVisibleChanged: {
        if (visible) {
            reloadSettings();
        }
    }
}
