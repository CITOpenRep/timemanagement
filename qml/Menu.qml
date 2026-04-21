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
import "components"
import "components/settings"
import "components/MenuData.js" as MenuData

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
                iconName: "account"
                text: i18n.dtr("ubtms", "Switch Accounts")
                onTriggered: {
                    accountPicker.open(accountPicker.selectedAccountId);
                }
            },
            Action {
                iconSource: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "images/daymode.png" : "images/darkmode.png"
                text: theme.name === "Ubuntu.Components.Themes.SuruDark" ? i18n.dtr("ubtms", "Light Mode") : i18n.dtr("ubtms","Dark Mode")
                onTriggered: {
                    Theme.name = theme.name === "Ubuntu.Components.Themes.SuruDark" ? "Ubuntu.Components.Themes.Ambiance" : "Ubuntu.Components.Themes.SuruDark";
                }
            }
        ]
    }

    readonly property bool isDark: theme.name === "Ubuntu.Components.Themes.SuruDark"

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
                        NavigationMenuList {
                            width: parent.width
                            menuItems: MenuData.items()
                            selectedPageUrl: apLayout && apLayout.currentMenuPageUrl ? apLayout.currentMenuPageUrl : ""
                            onItemSelected: function(item) {
                                apLayout.setPageGlobal(item.pageUrl, item.pageNum)
                            }
                        }
               
                    }
                }

    
               
   
            }
        }
    }
}
