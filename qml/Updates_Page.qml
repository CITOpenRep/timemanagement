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
import "../models/project.js" as Project
import "../models/accounts.js" as Account
import "../models/global.js" as Global
import "components"
import "../models/timer_service.js" as TimerService

Page {
    id: updates
    title: i18n.dtr("ubtms", "Project Updates")

    // Properties for filtering by project
    property bool filterByProject: false
    property string projectOdooRecordId: ""
    property int projectAccountId: accountPicker.selectedAccountId
    property string projectName: ""

    // Use numeric -1 as default (All accounts). Do NOT initialize from default account (that's for creation only).
    property int selectedAccountId: accountPicker.selectedAccountId

    header: PageHeader {
        id: updatesheader
        title: filterByProject ? "Updates - " + projectName : updates.title
        StyleHints {
            foregroundColor: "white"
            backgroundColor: LomiriColors.orange
            dividerColor: LomiriColors.slate
        }

        trailingActionBar.actions: [
            Action {
                iconName: "add"
                text: i18n.dtr("ubtms", "New")
                onTriggered: {
                    if (filterByProject && projectOdooRecordId && projectAccountId >= 0) {
                        // Direct creation when viewing updates for a specific project
                        var newUpdate = {
                            account_id: projectAccountId,
                            project_id: projectOdooRecordId,
                            name: "",
                            description: "",
                            project_status: "on_track",
                            progress: 0,
                            user_id: Account.getCurrentUserOdooId(projectAccountId)
                        };
                        
                        apLayout.addPageToNextColumn(updates, Qt.resolvedUrl("Updates.qml"), {
                            "recordid": 0,
                            "accountid": projectAccountId,
                            "currentUpdate": newUpdate,
                            "isReadOnly": false
                        });
                    } else {
                        // Navigate to Updates.qml with no pre-selected project
                        // The form will show WorkItemSelector to choose Account and Project
                        // Use selected account from filter, or default account
                        var defaultAcctId = Account.getDefaultAccountId();
                        var accountToUse = selectedAccountId >= 0 ? selectedAccountId : (defaultAcctId >= 0 ? defaultAcctId : 0);
                        
                        var emptyUpdate = {
                            account_id: accountToUse,
                            project_id: -1,
                            name: "",
                            description: "",
                            project_status: "on_track",
                            progress: 0,
                            user_id: -1
                        };
                        
                        apLayout.addPageToNextColumn(updates, Qt.resolvedUrl("Updates.qml"), {
                            "recordid": 0,
                            "accountid": accountToUse,
                            "currentUpdate": emptyUpdate,
                            "isReadOnly": false
                        });
                    }
                }
            }
        ]
    }

    // React to global account changes (numeric normalization)
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
            console.log("Updates_Page: AccountDataRefreshRequested ->", acctNum);
            selectedAccountId = acctNum;
            fetchupdates();
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
            console.log("Updates_Page: GlobalAccountChanged ->", acctNum, accountName);
            selectedAccountId = acctNum;
            fetchupdates();
        }
    }

    // Also listen to accountFilter so the page initializes and updates from the selector's current selection
    Connections {
        target: accountPicker
        onAccepted: function (accountId, accountName) {
            selectedAccountId = accountId;
            fetchupdates();
        }
    }

    NotificationPopup {
        id: notifPopup
        width: units.gu(80)
        height: units.gu(80)
    }

    ListModel {
        id: updatesModel
    }

    function fetchupdates() {
        var updates_list = [];
        try {
            if (filterByProject && projectOdooRecordId && projectAccountId >= 0) {
                updates_list = Project.getProjectUpdatesByProject(projectOdooRecordId, projectAccountId) || [];
            } else {
                // selectedAccountId is numeric -1 for all accounts, otherwise numeric account id
                updates_list = Project.getAllProjectUpdates(selectedAccountId) || [];
            }
        } catch (e) {
            console.error("Error fetching updates:", e);
            updates_list = [];
        }

        updatesModel.clear();
        for (var index = 0; index < updates_list.length; index++) {
            var u = updates_list[index] || {};
            updatesModel.append({
                'name': u.name,
                'id': u.id,
                'date': u.date,
                'account_id': u.account_id,
                'status': u.project_status,
                'progress': u.progress,
                'description': u.description,
                'project_id': u.project_id,
                'user': u.user_id,
                'hasDraft': u.has_draft
            });
        }
    }

    ListView {
        id: timesheetlist
        anchors.top: updatesheader.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: units.gu(1)
        model: updatesModel
        clip: true
        delegate: UpdatesDetailsCard {
            width: parent.width
            name: model.name
            account_id: model.account_id
            project_id: model.project_id
            user: model.user
            status: model.status
            description: model.description
            date: model.date
            progress: model.progress
            recordId: model.id
            hasDraft: model.hasDraft

            onEditRequested: function(accountId, recordId) {
                apLayout.addPageToNextColumn(updates, Qt.resolvedUrl("Updates.qml"), {
                    "recordid": recordId,
                    "accountid": accountId,
                    "isReadOnly": false
                });
            }

            onViewRequested: function(accountId, recordId) {
                apLayout.addPageToNextColumn(updates, Qt.resolvedUrl("Updates.qml"), {
                    "recordid": recordId,
                    "accountid": accountId,
                    "isReadOnly": true
                });
            }

            onShowDescription: {
                Global.description_temporary_holder = description;
                Global.description_context = "update_description";
                apLayout.addPageToNextColumn(updates, Qt.resolvedUrl("ReadMorePage.qml"), {
                    "isReadOnly": true
                });
            }

            onDeleteRequested: {
                var result = Project.markProjectUpdateAsDeleted(model.id);
                if (!result.success) {
                    notifPopup.open("Error", result.message, "error");
                } else {
                    notifPopup.open("Deleted", result.message, "success");
                    fetchupdates();
                }
            }
        }

        Component.onCompleted: fetchupdates()
    }

    onVisibleChanged: {
        if (visible) {
            fetchupdates();
        }
    }

    Component.onCompleted: {
        selectedAccountId = accountPicker.selectedAccountId;

        // Load initial updates list filtered by the account selector
        fetchupdates();
    }
}
