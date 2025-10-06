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
import Lomiri.Components 1.3
import QtQuick.Window 2.2
import Ubuntu.Components 1.3 as Ubuntu
import QtQuick.LocalStorage 2.7
import Lomiri.Components.ListItems 1.3 as ListItem

import "../models/project.js" as Project
import "../models/utils.js" as Utils
import "../models/accounts.js" as Account

import "components"

Page {
    id: project
    title: "Projects"
    header: PageHeader {
        id: projectheader
        StyleHints {
            foregroundColor: "white"
            backgroundColor: LomiriColors.orange
            dividerColor: LomiriColors.slate
        }
        title: project.title

        trailingActionBar.actions: [
            Action {
                iconName: "add"
                text: "New"
                onTriggered: {
                    // console.log("Create Project clicked");
                    apLayout.addPageToNextColumn(project, Qt.resolvedUrl("Projects.qml"), {
                        "isReadOnly": false
                    });
                }
            },
            Action {
                iconName: "search"
                text: "Search"
                onTriggered: {
                    projectlist.toggleSearchVisibility();
                }
            }
            // Action {
            //     iconName: "account"
            //     onTriggered: {
            //         accountFilterVisible = !accountFilterVisible;
            //     }
            // }
        ]
    }

    LomiriShape {
        anchors.top: projectheader.bottom
        height: parent.height - projectheader.height
        width: parent.width

        ProjectList {
            id: projectlist
            anchors.fill: parent

            // keep filterByAccount true, but DON'T initialize selectedAccountId from default account
            filterByAccount: true
            // initialize to numeric -1 (All accounts); we will set it on Component.onCompleted
            selectedAccountId: -1

            onProjectSelected: {
                //  console.log("Viewing Project");
                apLayout.addPageToNextColumn(project, Qt.resolvedUrl("Projects.qml"), {
                    "recordid": recordId,
                    "isReadOnly": true
                });
            }
            onProjectTimesheetRequested: localId => {
                let result = Timesheet.createTimesheetFromProject(localId);
                if (result.success) {
                    apLayout.addPageToNextColumn(project, Qt.resolvedUrl("Timesheet.qml"), {
                        "recordid": result.id,
                        "isReadOnly": false
                    });
                } else {
                    console.error(result.error);
                    // You might want to add error notification here
                }
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            projectlist.refresh();
        }
    }

    // When the global account changes, normalize to numeric and refresh
    Connections {
        target: mainView

        onAccountDataRefreshRequested: function (accountId) {
            var acctNum = -1;
            try {
                if (typeof accountId !== "undefined" && accountId !== null) {
                    var maybe = Number(accountId);
                    acctNum = isNaN(maybe) ? -1 : maybe;
                } else {
                    acctNum = -1;
                }
            } catch (e) {
                acctNum = -1;
            }

            projectlist.selectedAccountId = acctNum;
            projectlist.refresh();
        }

        onGlobalAccountChanged: function (accountId, accountName) {
            var acctNum = -1;
            try {
                if (typeof accountId !== "undefined" && accountId !== null) {
                    var maybe = Number(accountId);
                    acctNum = isNaN(maybe) ? -1 : maybe;
                } else {
                    acctNum = -1;
                }
            } catch (e) {
                acctNum = -1;
            }

            projectlist.selectedAccountId = acctNum;
            projectlist.refresh();
        }
    }

    // Listen to accountFilter directly so page initializes and updates from the selector's current selection
    Connections {
        target: accountFilter
        onAccountChanged: function (accountId, accountName) {
            console.log("Project_Page: Account filter changed to:", accountName, "ID:", accountId);
            var acctNum = -1;
            try {
                if (typeof accountId !== "undefined" && accountId !== null) {
                    var maybe = Number(accountId);
                    acctNum = isNaN(maybe) ? -1 : maybe;
                } else {
                    acctNum = -1;
                }
            } catch (e) {
                acctNum = -1;
            }

            projectlist.selectedAccountId = acctNum;
            projectlist.refresh();
        }
    }

    Component.onCompleted: {
        // Determine initial account selection from accountFilter (try common property names),
        // fall back to numeric -1 (All accounts) if none found. This ensures initial list is filtered.
        try {
            var initialAccountNum = -1;
            if (typeof accountFilter !== "undefined" && accountFilter !== null) {
                if (typeof accountFilter.selectedAccountId !== "undefined" && accountFilter.selectedAccountId !== null) {
                    var maybe = Number(accountFilter.selectedAccountId);
                    initialAccountNum = isNaN(maybe) ? -1 : maybe;
                } else if (typeof accountFilter.currentAccountId !== "undefined" && accountFilter.currentAccountId !== null) {
                    var maybe2 = Number(accountFilter.currentAccountId);
                    initialAccountNum = isNaN(maybe2) ? -1 : maybe2;
                } else if (typeof accountFilter.currentIndex !== "undefined" && accountFilter.currentIndex >= 0) {
                    // If accountFilter only exposes index, mapping index -> id is required.
                    // Default to -1 to avoid accidental assignment of an invalid id.
                    initialAccountNum = -1;
                } else {
                    initialAccountNum = -1;
                }
            } else if (typeof Account.getSelectedAccountId === "function") {
                var acct = Account.getSelectedAccountId();
                var acctNum = Number(acct);
                initialAccountNum = (acct !== null && typeof acct !== "undefined" && !isNaN(acctNum)) ? acctNum : -1;
            } else {
                initialAccountNum = -1;
            }

            console.log("Project_Page initial account selection (numeric):", initialAccountNum);
            projectlist.selectedAccountId = initialAccountNum;
        } catch (e) {
            console.error("Project_Page: error determining initial account:", e);
            projectlist.selectedAccountId = -1;
        }

        // initial refresh
        projectlist.refresh();
    }
}
