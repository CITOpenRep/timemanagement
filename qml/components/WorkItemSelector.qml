import QtQuick 2.7
import QtQuick.Controls 2.2
import Lomiri.Components 1.3

import "../../models/constants.js" as AppConst
import "../../models/project.js" as Project
import "../../models/accounts.js" as Accounts
import "../../models/task.js" as Task

Rectangle {
    id: workItemSelector
    width: parent ? parent.width : Screen.width
    height: contentColumn.implicitHeight
    color: "transparent"

    // External interface unchanged:
    property bool showAccountSelector: true
    property bool showProjectSelector: true
    property bool showTaskSelector: true
    property bool showAssigneeSelector: false

    property bool readOnly: false
    property string accountLabelText: "Account"
    property string projectLabelText: "Project"
    property string subProjectLabelText: "Subproject"
    property string taskLabelText: "Task"
    property string subTaskLabelText: "Subtask"
    property string assigneeLabelText: "Assignee"

    signal accountChanged(int accountId)

    property int selectedAccountId: -1
    property int selectedProjectId: -1
    property int selectedTaskId: -1
    property int selectedAssigneeId: -1

    function applyDeferredSelection(accountId, projectId, subProjectId, taskId, subTaskId, assigneeId) {
        if (accountSelector.model.count === 0) {
            deferredApplyTimer.deferredPayload = {
                accountId,
                projectId,
                subProjectId,
                taskId,
                subTaskId,
                assigneeId
            };
            deferredApplyTimer.start();
            return;
        }

        console.log("Loading Deferred Selection:", JSON.stringify({
            accountId,
            projectId,
            subProjectId,
            taskId,
            subTaskId,
            assigneeId
        }));

        selectedAccountId = accountId;
        selectedProjectId = subProjectId !== -1 ? subProjectId : projectId;
        selectedTaskId = subTaskId !== -1 ? subTaskId : taskId;
        selectedAssigneeId = assigneeId;

        projectSelectorWrapper.accountId = accountId;
        projectSelectorWrapper.loadParentSelector(selectedProjectId);


        taskSelectorWrapper.accountId = accountId;
        taskSelectorWrapper.loadParentSelector(selectedTaskId);

        assigneeSelectorWrapper.accountId = accountId;
        assigneeSelectorWrapper.loadSelector(selectedAssigneeId);
    }

    function getAllSelectedDbRecordIds() {
        return {
            accountDbId: selectedAccountId,
            projectDbId: projectSelectorWrapper.effectiveId,
            subProjectDbId: -1,
            taskDbId: taskSelectorWrapper.effectiveId,
            subTaskDbId: -1,
            assigneeDbId: assigneeSelectorWrapper.effectiveId
        };
    }

    Column {
        id: contentColumn
        width: parent.width
        spacing: units.gu(1)

        // Account Selector
        Row {
            id: myRow1a
            width: parent.width
            visible: showAccountSelector
            height: units.gu(5)

            TSLabel {
                width: parent.width * 0.25
                anchors.verticalCenter: parent.verticalCenter
                text: accountLabelText
                verticalAlignment: Text.AlignVCenter
            }

            Item {
                width: parent.width * 0.75
                height: units.gu(5)
                anchors.verticalCenter: parent.verticalCenter

                AccountSelector {
                    id: accountSelector
                    anchors.centerIn: parent
                    enabled: !readOnly
                    editable: false

                    onAccountSelected: {
                        console.log("Account selected:", accountSelector.selectedInstanceId);
                        selectedAccountId = accountSelector.selectedInstanceId;
                        projectSelectorWrapper.accountId = selectedAccountId;
                        projectSelectorWrapper.loadParentSelector(-1);
                        taskSelectorWrapper.accountId = selectedAccountId;
                        assigneeSelectorWrapper.accountId = selectedAccountId;
                        assigneeSelectorWrapper.loadSelector(-1); // Reload assignees for new account
                        accountChanged(selectedAccountId);
                    }
                }
            }
        }

        // Assignee Selector
        TreeSelector {
            id: assigneeSelectorWrapper
            labelText: assigneeLabelText
            width: parent.width
            visible: showAssigneeSelector
            enabled: !readOnly

            height: units.gu(5)

            property int accountId: selectedAccountId
            property int effectiveId: -1

            function loadSelector(selectedId) {
                if (accountId === -1)
                    return;
                let records = Accounts.getUsers(accountId);
                let flatModel = [
                    {
                        id: -1,
                        name: "Unassigned",
                        parent_id: null
                    }
                ];
                
                let selectedText = "Select Assignee";
                let selectedFound = false;
                
                // Check if selectedId matches "Unassigned"
                if (selectedId === -1) {
                    selectedText = "Unassigned";
                    selectedFound = true;
                }
                
                for (let i = 0; i < records.length; i++) {
                    let id = records[i].odoo_record_id !== undefined ? records[i].odoo_record_id : records[i].id;
                    let name = records[i].name;
                    flatModel.push({
                        id: id,
                        name: name,
                        parent_id: null
                    });
                    
                    // Check if this is the selected assignee
                    if (selectedId !== undefined && selectedId === id) {
                        selectedText = name;
                        selectedFound = true;
                    }
                }
                assigneeSelectorWrapper.dataList = flatModel;
                assigneeSelectorWrapper.reload();
                assigneeSelectorWrapper.selectedId = selectedId !== undefined ? selectedId : -1;
                assigneeSelectorWrapper.currentText = selectedText;
            }

            onItemSelected: {
                effectiveId = assigneeSelectorWrapper.selectedId;
                console.log("Assignee ID:", effectiveId);
            }
        }

        // Project & Subproject Selector
        ParentChildSelector {
            id: projectSelectorWrapper
            accountId: selectedAccountId
            parentLabel: projectLabelText
            childLabel: subProjectLabelText
            getRecords: Project.getProjectsForAccount
            visible: showProjectSelector
            width: parent.width
            height: units.gu(10)

            // anchors.top: showAssigneeSelector ? assigneeSelectorWrapper.bottom : myRow1a.bottom
            // anchors.left: parent.left
            // anchors.right: parent.right

            property int effectiveId: -1

            onFinalItemSelected: {
                effectiveId = id;
                console.log("Effective Project ID:", effectiveId);
                taskSelectorWrapper.accountId = selectedAccountId;
                taskSelectorWrapper.setProjectFilter(effectiveId); // Filter tasks by project/subproject
                taskSelectorWrapper.loadParentSelector(-1);
            }
        }

        // Task & Subtask Selector
        ParentChildSelector {
            id: taskSelectorWrapper
            accountId: selectedAccountId
            parentLabel: taskLabelText
            childLabel: subTaskLabelText
            visible: showTaskSelector
            width: parent.width
            height: units.gu(10)

            property int effectiveId: -1
            property int projectFilterId: -1

            function setProjectFilter(projId) {
                projectFilterId = projId;
            }

            getRecords: function (accountId) {
                let allTasks = Task.getTasksForAccount(accountId);
                if (projectFilterId === -1) {
                    return allTasks;
                }
                return allTasks.filter(function (task) {
                    return task.project_id === projectFilterId;
                });
            }

            onFinalItemSelected: {
                effectiveId = id;
                console.log("Effective Task ID:", effectiveId);
            }
        }

        Timer {
            id: deferredApplyTimer
            interval: 100
            repeat: true
            running: false
            property var deferredPayload: null

            onTriggered: {
                if (!deferredPayload || accountSelector.model.count === 0)
                    return;
                deferredApplyTimer.stop();
                let p = deferredApplyTimer.deferredPayload;
                deferredApplyTimer.deferredPayload = null;
                applyDeferredSelection(p.accountId, p.projectId, p.subProjectId, p.taskId, p.subTaskId, p.assigneeId);
            }
        }
    }
}
