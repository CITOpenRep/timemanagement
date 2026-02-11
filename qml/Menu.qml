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
import Lomiri.Components 1.3
import QtCharts 2.0
import QtQuick.Layouts 1.11
import Qt.labs.settings 1.0
import "../models/Main.js" as Model
import "../models/timesheet.js" as TimesheetModel
import "../models/accounts.js" as Account
import "components/settings"

Page {
    id: listpage
    title: i18n.dtr("ubtms", "Menu")
    property bool isMultiColumn: apLayout.columns > 1
    anchors.fill: parent
    header: PageHeader {
        id: header
        title: listpage.title
        StyleHints {
            foregroundColor: "white"

            backgroundColor: LomiriColors.orange
            dividerColor: LomiriColors.slate
        }
        trailingActionBar.actions: [
            Action {
                iconName: "reminder-new"
                text: "New Timesheet"
                onTriggered: {
                    const result = TimesheetModel.createTimesheet(Account.getDefaultAccountId(), Account.getCurrentUserOdooId(Account.getDefaultAccountId()));
                    if (result.success) {
                        apLayout.addPageToNextColumn(listpage, Qt.resolvedUrl("Timesheet.qml"), {
                            "recordid": result.id,
                            "isReadOnly": false
                        });
                    } else {
                        console.error("Error creating timesheet: " + result.message);
                    }
                    page = 1;
                    apLayout.setCurrentPage(page);
                }
            },
            Action {
                iconName: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "weather-clear-night-symbolic" : "weather-clear-symbolic"
                text: theme.name === "Ubuntu.Components.Themes.SuruDark" ? i18n.tr("Light Mode") : i18n.tr("Dark Mode")
                onTriggered: {
                    var newTheme = theme.name === "Ubuntu.Components.Themes.SuruDark" ? "Ubuntu.Components.Themes.Ambiance" : "Ubuntu.Components.Themes.SuruDark";
                    Theme.name = newTheme;

                    // // Save theme preference to persist across app restarts // We are not saving the theme preference from here.
                    // if (typeof mainView !== 'undefined' && mainView.saveThemePreference) {
                    //     mainView.saveThemePreference(newTheme);
                    // }
                }
            },
            Action {
                iconName: "account"
                text: i18n.dtr("ubtms", "Switch Accounts")
                onTriggered: {
                    accountPicker.open(0);
                }
            }
        ]
    }

    readonly property bool isDark: theme.name === "Ubuntu.Components.Themes.SuruDark"

    property var page: 0

    Rectangle {
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        color: isDark ? "#111" : "#f2f2f7"

        Flickable {
            anchors.fill: parent
            contentHeight: menuColumn.height + units.gu(4)
            clip: true

            Column {
                id: menuColumn
                width: parent.width
                anchors.top: parent.top
               // anchors.topMargin: units.gu(2)

            
          
                Rectangle {
                    width: parent.width
                    height: mainSection.height
                    color: isDark ? "#1e1e1e" : "#ffffff"

                    Column {
                        id: mainSection
                        width: parent.width

                        SettingsListItem {
                            iconName: "home"
                            iconColor: "#3498db"
                            text: i18n.dtr("ubtms", "Dashboard")
                            onClicked: {
                                page = 0;
                                apLayout.setCurrentPage(page);
                                apLayout.addPageToNextColumn(listpage, Qt.resolvedUrl("Dashboard.qml"));
                            }
                        }

                        SettingsListItem {
                            iconName: "alarm-clock"
                            iconColor: "#e67e22"
                            text: i18n.dtr("ubtms", "Timesheet")
                            onClicked: {
                                apLayout.addPageToNextColumn(listpage, Qt.resolvedUrl("Timesheet_Page.qml"));
                                page = 1;
                                apLayout.setCurrentPage(page);
                            }
                        }

                        SettingsListItem {
                            iconName: "calendar"
                            iconColor: "#e74c3c"
                            text: i18n.dtr("ubtms", "Activities")
                          
                            onClicked: {
                                apLayout.addPageToNextColumn(listpage, Qt.resolvedUrl("Activity_Page.qml"));
                                page = 2;
                                apLayout.setCurrentPage(page);
                            }
                        }

                                             SettingsListItem {
                            iconName: "scope-manager"
                            iconColor: "#2ecc71"
                            text: i18n.dtr("ubtms", "My Tasks")
                            onClicked: {
                                apLayout.addPageToNextColumn(listpage, Qt.resolvedUrl("MyTasks.qml"));
                                page = 3;
                                apLayout.setCurrentPage(page);
                            }
                        }

                        SettingsListItem {
                            iconName: "view-list-symbolic"
                            iconColor: "#1abc9c"
                            text: i18n.dtr("ubtms", "All Tasks")
                            onClicked: {
                                apLayout.addPageToNextColumn(listpage, Qt.resolvedUrl("Task_Page.qml"));
                                page = 3;
                                apLayout.setCurrentPage(page);
                            }
                        }

                        SettingsListItem {
                            iconName: "folder-symbolic"
                            iconColor: "#9b59b6"
                            text: i18n.dtr("ubtms", "Projects")
                            onClicked: {
                                apLayout.addPageToNextColumn(listpage, Qt.resolvedUrl("Project_Page.qml"));
                                page = 4;
                                apLayout.setCurrentPage(page);
                            }
                        }

                        SettingsListItem {
                            iconName: "history"
                            iconColor: "#f39c12"
                            text: i18n.dtr("ubtms", "Project Updates")
                            onClicked: {
                                apLayout.addPageToNextColumn(listpage, Qt.resolvedUrl("Updates_Page.qml"));
                                page = 4;
                                apLayout.setCurrentPage(page);
                            }
                        }
            
            

           

                        SettingsListItem {
                            iconName: "info"
                            iconColor: "#2980b9"
                            text: i18n.dtr("ubtms", "About Us")
                            onClicked: {
                                apLayout.addPageToNextColumn(listpage, Qt.resolvedUrl("Aboutus.qml"));
                                page = 5;
                                apLayout.setCurrentPage(page);
                            }
                        }

                        SettingsListItem {
                            iconName: "settings"
                            iconColor: "#7f8c8d"
                            text: i18n.dtr("ubtms", "Settings")
                            showDivider: false
                            onClicked: {
                                apLayout.addPageToNextColumn(listpage, Qt.resolvedUrl("settings/Settings_Page.qml"));
                                page = 6;
                                apLayout.setCurrentPage(page);
                            }
                        }
               
                    }
                }

    
               
   
            }
        }
    }
}
