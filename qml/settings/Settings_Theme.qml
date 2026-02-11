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
import "../components/settings"

Page {
    id: themeSettingsPage
    title: i18n.dtr("ubtms", "Theme Settings")

    header: SettingsHeader {
        id: pageHeader
        title: themeSettingsPage.title
    }

    // Theme management functions
    function getCurrentTheme() {
        return theme.name;
    }

    function setThemePreference(themeName) {
        try {
            // Apply theme immediately
            Theme.name = themeName;

            // Save to database directly
            saveThemeToDatabase(themeName);
        } catch (e) {
            console.error("Error setting theme preference:", e);
        }
    }

    function saveThemeToDatabase(themeName) {
        try {
            var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);

            db.transaction(function (tx) {
                // Create settings table if it doesn't exist
                tx.executeSql('CREATE TABLE IF NOT EXISTS app_settings (key TEXT PRIMARY KEY, value TEXT)');

                // Save theme preference (INSERT OR REPLACE)
                tx.executeSql('INSERT OR REPLACE INTO app_settings (key, value) VALUES (?, ?)', ['theme_preference', themeName]);
            });
        } catch (e) {
            console.warn("Error saving theme to database:", e);
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

            // Theme Preference Section
            Rectangle {
                width: parent.width
                height: themeSection.height + units.gu(2)
                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#1a1a1a" : "#f8f8f8"
                border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#444" : "#ddd"
                border.width: 1
                radius: units.gu(1)

                Column {
                    id: themeSection
                    width: parent.width - units.gu(2)
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: units.gu(1)
                    spacing: units.gu(1)

                    // Header
                    Text {
                        text: i18n.dtr("ubtms", "App Theme Preference")
                        font.pixelSize: units.gu(2.5)
                        font.bold: true
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#e0e0e0" : "#333"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: i18n.dtr("ubtms", "Choose your preferred theme for the application")
                        font.pixelSize: units.gu(1.5)
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#b0b0b0" : "#666"
                        anchors.horizontalCenter: parent.horizontalCenter
                        wrapMode: Text.WordWrap
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                    }

                    // Theme Options
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: units.gu(4)

                        // Light Theme Option
                        Column {
                            spacing: units.gu(1)

                            Rectangle {
                                width: units.gu(8)
                                height: units.gu(6)
                                color: "#ffffff"
                                border.color: getCurrentTheme() === "Ubuntu.Components.Themes.Ambiance" ? LomiriColors.orange : "#ccc"
                                border.width: getCurrentTheme() === "Ubuntu.Components.Themes.Ambiance" ? 3 : 1
                                radius: units.gu(0.5)

                                // Light theme preview
                                Column {
                                    anchors.fill: parent
                                    anchors.margins: units.gu(0.5)
                                    spacing: units.gu(0.2)

                                    Rectangle {
                                        width: parent.width
                                        height: units.gu(1)
                                        color: "#f0f0f0"
                                        radius: units.gu(0.2)
                                    }
                                    Rectangle {
                                        width: parent.width * 0.7
                                        height: units.gu(0.5)
                                        color: "#666"
                                        radius: units.gu(0.1)
                                    }
                                    Rectangle {
                                        width: parent.width * 0.9
                                        height: units.gu(0.5)
                                        color: "#999"
                                        radius: units.gu(0.1)
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        setThemePreference("Ubuntu.Components.Themes.Ambiance");
                                    }
                                }
                            }

                            Text {
                                text: i18n.dtr("ubtms", "Light Theme")
                                font.pixelSize: units.gu(1.5)
                                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#e0e0e0" : "#333"
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            CheckBox {
                                id: lightThemeCheckbox
                                checked: getCurrentTheme() === "Ubuntu.Components.Themes.Ambiance"
                                anchors.horizontalCenter: parent.horizontalCenter
                                onClicked: {
                                    if (checked) {
                                        setThemePreference("Ubuntu.Components.Themes.Ambiance");
                                    }
                                }
                            }
                        }

                        // Dark Theme Option
                        Column {
                            spacing: units.gu(1)

                            Rectangle {
                                width: units.gu(8)
                                height: units.gu(6)
                                color: "#2c2c2c"
                                border.color: getCurrentTheme() === "Ubuntu.Components.Themes.SuruDark" ? LomiriColors.orange : "#666"
                                border.width: getCurrentTheme() === "Ubuntu.Components.Themes.SuruDark" ? 3 : 1
                                radius: units.gu(0.5)

                                // Dark theme preview
                                Column {
                                    anchors.fill: parent
                                    anchors.margins: units.gu(0.5)
                                    spacing: units.gu(0.2)

                                    Rectangle {
                                        width: parent.width
                                        height: units.gu(1)
                                        color: "#444"
                                        radius: units.gu(0.2)
                                    }
                                    Rectangle {
                                        width: parent.width * 0.7
                                        height: units.gu(0.5)
                                        color: "#e0e0e0"
                                        radius: units.gu(0.1)
                                    }
                                    Rectangle {
                                        width: parent.width * 0.9
                                        height: units.gu(0.5)
                                        color: "#b0b0b0"
                                        radius: units.gu(0.1)
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        setThemePreference("Ubuntu.Components.Themes.SuruDark");
                                    }
                                }
                            }

                            Text {
                                text: i18n.dtr("ubtms", "Dark Theme")
                                font.pixelSize: units.gu(1.5)
                                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#e0e0e0" : "#333"
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            CheckBox {
                                id: darkThemeCheckbox
                                checked: getCurrentTheme() === "Ubuntu.Components.Themes.SuruDark"
                                anchors.horizontalCenter: parent.horizontalCenter
                                onClicked: {
                                    if (checked) {
                                        setThemePreference("Ubuntu.Components.Themes.SuruDark");
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
