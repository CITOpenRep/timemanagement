/*
 * MIT License
 *
 * Copyright (c) 2025 CIT-Services
 */

import QtQuick 2.7
import QtQuick.Controls 2.2
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import "../../models/project.js" as Project
import "../../models/accounts.js" as Accounts

Item {
    id: root
    height: units.gu(12)
    
    property bool readOnly: false
    property int selectedAccountId: -1
    property int selectedProjectId: -1
    
    signal projectChanged()
    
    function getIds() {
        return {
            account_id: selectedAccountId,
            project_id: selectedProjectId
        };
    }
    
    function deferredLoadExistingProject(accountId, projectId) {
        selectedAccountId = accountId;
        selectedProjectId = projectId;
        
        // Load account name
        var accountName = Accounts.getAccountNameById(accountId);
        accountButton.text = accountName || "Select Account";
        
        // Load project name
        var projectName = Project.getProjectName(projectId, accountId);
        projectButton.text = projectName || "Select Project";
    }
    
    Column {
        anchors.fill: parent
        spacing: units.gu(1)
        
        // Account Selector
        Row {
            width: parent.width
            spacing: units.gu(1)
            
            TSLabel {
                text: i18n.dtr("ubtms", "Account:")
                width: units.gu(10)
                anchors.verticalCenter: parent.verticalCenter
            }
            
            Button {
                id: accountButton
                text: i18n.dtr("ubtms", "Select Account")
                width: parent.width - units.gu(11)
                enabled: !readOnly
                onClicked: {
                    accountSelectorPopup.open();
                }
            }
        }
        
        // Project Selector
        Row {
            width: parent.width
            spacing: units.gu(1)
            
            TSLabel {
                text: i18n.dtr("ubtms", "Project:")
                width: units.gu(10)
                anchors.verticalCenter: parent.verticalCenter
            }
            
            Button {
                id: projectButton
                text: i18n.dtr("ubtms", "Select Project")
                width: parent.width - units.gu(11)
                enabled: !readOnly && selectedAccountId > 0
                onClicked: {
                    projectSelectorPopup.open();
                }
            }
        }
    }
    
    // Account Selector Dialog
    Component {
        id: accountSelectorDialog
        Dialog {
            id: dlg
            title: i18n.dtr("ubtms", "Select Account")
            
            ListView {
                height: units.gu(40)
                width: parent.width
                model: ListModel {
                    id: accountListModel
                }
                
                delegate: ListItem {
                    height: units.gu(6)
                    
                    ListItemLayout {
                        title.text: model.name
                    }
                    
                    onClicked: {
                        selectedAccountId = model.id;
                        accountButton.text = model.name;
                        selectedProjectId = -1;
                        projectButton.text = i18n.dtr("ubtms", "Select Project");
                        projectChanged();
                        PopupUtils.close(dlg);
                    }
                }
                
                Component.onCompleted: {
                    var accounts = Accounts.getAccountsList();
                    for (var i = 0; i < accounts.length; i++) {
                        accountListModel.append({
                            id: accounts[i].id,
                            name: accounts[i].name
                        });
                    }
                }
            }
            
            Button {
                text: i18n.dtr("ubtms", "Cancel")
                onClicked: PopupUtils.close(dlg)
            }
        }
    }
    
    // Project Selector Dialog
    Component {
        id: projectSelectorDialog
        Dialog {
            id: dlg
            title: i18n.dtr("ubtms", "Select Project")
            
            ListView {
                height: units.gu(40)
                width: parent.width
                model: ListModel {
                    id: projectListModel
                }
                
                delegate: ListItem {
                    height: units.gu(6)
                    
                    ListItemLayout {
                        title.text: model.name
                    }
                    
                    onClicked: {
                        selectedProjectId = model.id;
                        projectButton.text = model.name;
                        projectChanged();
                        PopupUtils.close(dlg);
                    }
                }
                
                Component.onCompleted: {
                    var projects = Project.getUserProjects(selectedAccountId);
                    for (var i = 0; i < projects.length; i++) {
                        projectListModel.append({
                            id: projects[i].odoo_record_id,
                            name: projects[i].name
                        });
                    }
                }
            }
            
            Button {
                text: i18n.dtr("ubtms", "Cancel")
                onClicked: PopupUtils.close(dlg)
            }
        }
    }
    
    property var accountSelectorPopup: null
    property var projectSelectorPopup: null
    
    Component.onCompleted: {
        accountSelectorPopup = PopupUtils.open(accountSelectorDialog, root);
        accountSelectorPopup.visible = false;
        
        projectSelectorPopup = PopupUtils.open(projectSelectorDialog, root);
        projectSelectorPopup.visible = false;
    }
}
