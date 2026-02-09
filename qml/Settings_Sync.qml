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
import "components/settings"

Page {
    id: syncSettingsPage
    title: i18n.dtr("ubtms", "Background Sync")

    header: SettingsHeader {
        id: pageHeader
        title: syncSettingsPage.title
    }

    // AutoSync Settings Helper Functions
    function getAutoSyncSetting(key) {
        var defaultValues = {
            "autosync_enabled": "true",
            "sync_interval_minutes": "15",
            "sync_direction": "both"
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
            console.warn("Error reading AutoSync setting:", e);
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

            console.log("AutoSync setting saved:", key, "=", value);
        } catch (e) {
            console.warn("Error saving AutoSync setting:", e);
        }
    }

    Rectangle {
        anchors.top: pageHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#111" : "transparent"

        Column {
            width: parent.width - units.gu(4)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: units.gu(2)
            spacing: units.gu(2)

            // AutoSync Settings Section
            Rectangle {
                width: parent.width
                height: autoSyncSection.height + units.gu(2)
                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#1a1a1a" : "#f8f8f8"
                border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#444" : "#ddd"
                border.width: 1
                radius: units.gu(1)

                Column {
                    id: autoSyncSection
                    width: parent.width - units.gu(2)
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: units.gu(1)
                    spacing: units.gu(1.5)

                    // Header
                    Text {
                        text: i18n.dtr("ubtms", "Background Sync Settings")
                        font.pixelSize: units.gu(2.5)
                        font.bold: true
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#e0e0e0" : "#333"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: i18n.dtr("ubtms", "Configure automatic synchronization with Odoo")
                        font.pixelSize: units.gu(1.5)
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#b0b0b0" : "#666"
                        anchors.horizontalCenter: parent.horizontalCenter
                        wrapMode: Text.WordWrap
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                    }

                    // AutoSync Enable Toggle
                    Row {
                        width: parent.width
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: units.gu(2)

                        Text {
                            text: i18n.dtr("ubtms", "Enable AutoSync")
                            font.pixelSize: units.gu(2)
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#e0e0e0" : "#333"
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - autoSyncSwitch.width - units.gu(4)
                        }

                        Switch {
                            id: autoSyncSwitch
                            checked: getAutoSyncSetting("autosync_enabled") === "true"
                            anchors.verticalCenter: parent.verticalCenter
                            onCheckedChanged: {
                                saveAutoSyncSetting("autosync_enabled", checked ? "true" : "false");
                            }
                        }
                    }

                    // Sync Interval Selector
                    OptionSelector {
                        id: syncIntervalCombo
                        text: i18n.dtr("ubtms", "Sync Interval")
                        enabled: autoSyncSwitch.checked
                        containerHeight: units.gu(30)
                        model: [
                            { text: "1 minute", value: "1" },
                            { text: "5 minutes", value: "5" },
                            { text: "15 minutes", value: "15" },
                            { text: "30 minutes", value: "30" },
                            { text: "60 minutes", value: "60" }
                        ]
                        delegate: OptionSelectorDelegate { 
                            text: modelData.text 
                        }
                        
                        Component.onCompleted: {
                            var saved = getAutoSyncSetting("sync_interval_minutes");
                            var foundIndex = 2; // Default to 15 minutes
                            for (var i = 0; i < model.length; i++) {
                                if (model[i].value === saved) {
                                    foundIndex = i;
                                    break;
                                }
                            }
                            selectedIndex = foundIndex;
                        }
                        
                        onSelectedIndexChanged: {
                            if (selectedIndex >= 0 && selectedIndex < model.length) {
                                saveAutoSyncSetting("sync_interval_minutes", model[selectedIndex].value);
                            }
                        }
                    }

                    // Sync Direction Selector
                    OptionSelector {
                        id: syncDirectionCombo
                        text: i18n.dtr("ubtms", "Sync Direction")
                        enabled: autoSyncSwitch.checked
                        containerHeight: units.gu(20)
                        model: [
                            { text: "Both (Up & Down)", value: "both" },
                            { text: "Download Only", value: "download_only" },
                            { text: "Upload Only", value: "upload_only" }
                        ]
                        delegate: OptionSelectorDelegate { 
                            text: modelData.text 
                        }
                        
                        Component.onCompleted: {
                            var saved = getAutoSyncSetting("sync_direction");
                            var foundIndex = 0; // Default to both
                            for (var i = 0; i < model.length; i++) {
                                if (model[i].value === saved) {
                                    foundIndex = i;
                                    break;
                                }
                            }
                            selectedIndex = foundIndex;
                        }
                        
                        onSelectedIndexChanged: {
                            if (selectedIndex >= 0 && selectedIndex < model.length) {
                                saveAutoSyncSetting("sync_direction", model[selectedIndex].value);
                            }
                        }
                    }

                    // Info text
                    Text {
                        text: i18n.dtr("ubtms", "Note: Changes take effect on the next sync cycle. The background daemon checks for setting updates automatically.")
                        font.pixelSize: units.gu(1.3)
                        font.italic: true
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#888" : "#888"
                        anchors.horizontalCenter: parent.horizontalCenter
                        wrapMode: Text.WordWrap
                        width: parent.width - units.gu(2)
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }
}
