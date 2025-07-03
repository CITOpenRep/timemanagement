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
        console.log("applyDeferredSelection called with:", JSON.stringify({
            accountId: accountId,
            projectId: projectId,
            subProjectId: subProjectId,
            taskId: taskId,
            subTaskId: subTaskId,
            assigneeId: assigneeId
        }));

        // Check if we need to defer
        var modelCount = accountSelector.model ? accountSelector.model.count : 0;
        console.log("Account selector model count:", modelCount);

        if (modelCount === 0) {
            console.log("Using deferred approach. Model count:", modelCount);
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

        console.log("Loading Deferred Selection immediately:", JSON.stringify({
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

        // Set the account selector to show the correct account using Qt.callLater for proper timing
        if (accountId !== -1) {
            console.log("Setting account selector to:", accountId);
            Qt.callLater(() => {
                console.log("Calling accountSelector.selectAccountById with:", accountId);
                accountSelector.selectAccountById(accountId);
            });
        }

        // Set account ID for all selectors first
        projectSelectorWrapper.accountId = accountId;
        taskSelectorWrapper.accountId = accountId;
        assigneeSelectorWrapper.accountId = accountId;

        // Use Qt.callLater for better timing
        Qt.callLater(() => {
            console.log("Loading selectors with values - project:", selectedProjectId, "task:", selectedTaskId, "assignee:", selectedAssigneeId);

            // Load projects first
            projectSelectorWrapper.loadParentSelector(selectedProjectId);

            // If we have a selected project, set the task filter and load tasks
            if (selectedProjectId !== -1) {
                taskSelectorWrapper.setProjectFilter(selectedProjectId);
            } else {
                taskSelectorWrapper.setProjectFilter(-1); // Show all tasks for account
            }
            taskSelectorWrapper.loadParentSelector(selectedTaskId);

            // Load assignees
            assigneeSelectorWrapper.loadSelector(selectedAssigneeId);

            // Debug the final state after a delay
            Qt.callLater(() => {
                debugSelectorStates();  // Can be remooved
            });
        });
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

    //Can be Deleted Later after debugging

    // Debugging function to check current selector states
    function debugSelectorStates() {
        console.log("=== Selector States Debug ===");
        console.log("Account Selector:");
        console.log("  - selectedInstanceId:", accountSelector.selectedInstanceId);
        console.log("  - currentText:", accountSelector.currentText);
        console.log("  - model count:", accountSelector.model ? accountSelector.model.count : 0);

        console.log("Project Selector:");
        console.log("  - selectedId:", projectSelectorWrapper.effectiveId);
        console.log("  - parentSelector.currentText:", projectSelectorWrapper.parentSelector ? projectSelectorWrapper.parentSelector.currentText : "N/A");

        console.log("Task Selector:");
        console.log("  - selectedId:", taskSelectorWrapper.effectiveId);
        console.log("  - parentSelector.currentText:", taskSelectorWrapper.parentSelector ? taskSelectorWrapper.parentSelector.currentText : "N/A");

        console.log("Assignee Selector:");
        console.log("  - selectedId:", assigneeSelectorWrapper.effectiveId);
        console.log("  - currentText:", assigneeSelectorWrapper.currentText);
        console.log("=== End Debug ===");
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
                        taskSelectorWrapper.setProjectFilter(-1); // Reset project filter
                        taskSelectorWrapper.loadParentSelector(-1); // Reload tasks for new account
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
                        name: "Select Assignee", // Changed from "Unassigned" to "Select Assignee"
                        parent_id: null
                    }
                ];

                let selectedText = "Select Assignee";
                let selectedFound = false;

                // Check if selectedId matches "Unassigned"
                if (selectedId === -1) {
                    selectedText = "Select Assignee";
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

                // Use Qt.callLater to ensure the selector state is properly initialized before setting values
                Qt.callLater(() => {
                    console.log("Setting assignee selector - selectedId:", selectedId, "selectedText:", selectedText);
                    assigneeSelectorWrapper.selectedId = selectedId !== undefined ? selectedId : -1;
                    assigneeSelectorWrapper.currentText = selectedText;
                    console.log("After setting assignee - selectedId:", assigneeSelectorWrapper.selectedId, "currentText:", assigneeSelectorWrapper.currentText);
                });
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
            enabled: !readOnly
            width: parent.width
            height: units.gu(10)

            property int effectiveId: -1

            onParentItemSelected: {
                // Handle immediate project selection - enable and populate task selector
                console.log("Project immediately selected:", id);
                if (id !== -1) {
                    taskSelectorWrapper.accountId = selectedAccountId;
                    taskSelectorWrapper.setProjectFilter(id);
                    taskSelectorWrapper.loadParentSelector(-1);
                }
            }

            onFinalItemSelected: {
                effectiveId = id;
                console.log("Effective Project ID:", effectiveId);
                taskSelectorWrapper.accountId = selectedAccountId;
                taskSelectorWrapper.setProjectFilter(effectiveId); // Set project filter in ParentChildSelector
                taskSelectorWrapper.loadParentSelector(-1); // Reload tasks with project filter
            }
        }

        // Task & Subtask Selector
        ParentChildSelector {
            id: taskSelectorWrapper
            accountId: selectedAccountId
            parentLabel: taskLabelText
            childLabel: subTaskLabelText
            visible: showTaskSelector
            enabled: !readOnly
            width: parent.width
            height: units.gu(10)
            getRecords: Task.getTasksForAccount
            useProjectFilter: true // Enable project filtering for tasks

            property int effectiveId: -1

            onFinalItemSelected: {
                effectiveId = id;
                console.log("Effective Task ID:", effectiveId);
            }
        }

        Timer {
            id: deferredApplyTimer
            interval: 200  // Increased interval for better timing
            repeat: true
            running: false
            property var deferredPayload: null
            property int retryCount: 0
            property int maxRetries: 10

            onTriggered: {
                if (!deferredPayload) {
                    deferredApplyTimer.stop();
                    return;
                }

                retryCount++;
                console.log("Deferred timer retry:", retryCount, "Model count:", accountSelector.model ? accountSelector.model.count : 0);

                if ((accountSelector.model && accountSelector.model.count > 0) || retryCount >= maxRetries) {
                    console.log("Applying deferred selection, retry:", retryCount);
                    deferredApplyTimer.stop();
                    let p = deferredPayload;
                    deferredPayload = null;
                    retryCount = 0;

                    // Add another delay to ensure everything is ready
                    Qt.callLater(() => {
                        applyDeferredSelection(p.accountId, p.projectId, p.subProjectId, p.taskId, p.subTaskId, p.assigneeId);
                    });
                } else if (retryCount >= maxRetries) {
                    console.warn("Max retries reached, stopping deferred timer");
                    deferredApplyTimer.stop();
                    retryCount = 0;
                    deferredPayload = null;
                }
            }
        }
    }
}
