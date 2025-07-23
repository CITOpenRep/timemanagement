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

Page {
    id: listpage
    title: "Menu"
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
                        console.log("Error creating timesheet: " + result.message);
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
            }
        ]
    }

    property var page: 0
    LomiriShape {
        anchors.top: header.bottom
        width: parent.width
        height: parent.height

        Column {
            anchors.fill: parent
            ListItem {
                height: units.gu(6)
                Rectangle {
                    color: "transparent"
                    anchors.fill: parent
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(3)

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: units.gu(2)

                        Icon {
                            width: units.gu(2.5)
                            height: units.gu(2.5)
                            name: "home"
                        }

                        Label {
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignLeft
                            text: "Dashboard"
                        }
                    }
                }
                onClicked: {
                    page = 0;
                    apLayout.setCurrentPage(page);
                    var incubator = apLayout.addPageToNextColumn(listpage, Qt.resolvedUrl("Dashboard.qml"));
                }
            }
            ListItem {
                height: units.gu(6)
                Rectangle {
                    color: "transparent"
                    anchors.fill: parent
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(3)

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: units.gu(2)

                        Icon {
                            width: units.gu(2.5)
                            height: units.gu(2.5)
                            name: "alarm-clock"
                        }

                        Label {
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignLeft
                            text: "Timesheet"
                        }
                    }
                }
                onClicked: {
                    apLayout.addPageToNextColumn(listpage, Qt.resolvedUrl("Timesheet_Page.qml"));
                    page = 1;
                    apLayout.setCurrentPage(page);
                }
            }
            ListItem {
                height: units.gu(6)
                Rectangle {
                    color: "transparent"
                    anchors.fill: parent
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(3)
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: units.gu(2)
                        Icon {
                            width: units.gu(2.5)
                            height: units.gu(2.5)
                            name: "calendar"
                        }
                        Label {
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignLeft
                            text: "Activities"
                        }
                    }
                }
                onClicked: {
                    apLayout.addPageToNextColumn(listpage, Qt.resolvedUrl("Activity_Page.qml"));
                    page = 2;
                    apLayout.setCurrentPage(page);
                }
            }
            ListItem {
                height: units.gu(6)
                Rectangle {
                    color: "transparent"
                    anchors.fill: parent
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(3)

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: units.gu(2)

                        Icon {
                            width: units.gu(2.5)
                            height: units.gu(2.5)
                            name: "view-list-symbolic"
                        }

                        Label {
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignLeft
                            text: "Tasks"
                        }
                    }
                }
                onClicked: {
                    apLayout.addPageToNextColumn(listpage, Qt.resolvedUrl("Task_Page.qml"));
                    page = 3;
                    apLayout.setCurrentPage(page);
                }
            }
            ListItem {
                height: units.gu(6)
                Rectangle {
                    color: "transparent"
                    anchors.fill: parent
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(3)

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: units.gu(2)

                        Icon {
                            width: units.gu(2.5)
                            height: units.gu(2.5)
                            name: "folder-symbolic"
                        }

                        Label {
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignLeft
                            text: "Projects"
                        }
                    }
                }
                onClicked: {
                    apLayout.addPageToNextColumn(listpage, Qt.resolvedUrl("Project_Page.qml"));
                    page = 4;
                    apLayout.setCurrentPage(page);
                }
            }
            // ListItem {
            //     height: units.gu(6)
            //     Rectangle {
            //         color: "transparent"
            //         anchors.fill: parent
            //         anchors.left: parent.left
            //         anchors.leftMargin: units.gu(3)
            //         Row {
            //             anchors.verticalCenter: parent.verticalCenter
            //             spacing: units.gu(2)
            //             Icon {
            //                 width: 20
            //                 height: 20
            //                 name: "sync"
            //             }
            //             Label {
            //                 verticalAlignment: Text.AlignVCenter
            //                 horizontalAlignment: Text.AlignLeft
            //                 text: "Sync"
            //             }
            //         }
            //     }
            //     onClicked: {
            //         apLayout.addPageToNextColumn(listpage, Qt.resolvedUrl("Sync_Page.qml"));
            //         page = 5;
            //         apLayout.setCurrentPage(page);
            //     }
            // }
            ListItem {
                height: units.gu(6)
                Rectangle {
                    color: "transparent"
                    anchors.fill: parent
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(3)

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: units.gu(2)

                        Icon {
                            width: units.gu(2.5)
                            height: units.gu(2.5)
                            name: "settings"
                        }

                        Label {
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignLeft
                            text: "Settings"
                        }
                    }
                }
                onClicked: {
                    apLayout.addPageToNextColumn(listpage, Qt.resolvedUrl("Settings_Page.qml"));
                    page = 6;
                    apLayout.setCurrentPage(page);
                }
            }
        }
    }
}
