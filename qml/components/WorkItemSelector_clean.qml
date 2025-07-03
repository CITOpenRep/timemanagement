import QtQuick 2.7
import QtQuick.Controls 2.2
import Lomiri.Components 1.3

import "../../models/constants.js" as A
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
            console.log("Deferring selection - models not ready");
            deferredApplyTimer.deferredPayload = {
                accountId,
                projectId,
                subProjectId,
                taskId,
                subTaskId,
                assigneeId
            };
            deferredApplyTimer.retryCount = 0; // Reset retry count
            deferredApplyTimer.start();
            return;
        }

        console.log("Applying selection immediately - models ready");
        _applySelectionNow(accountId, projectId, subProjectId, taskId, subTaskId, assigneeId);
    }

    function _applySelectionNow(accountId, projectId, subProjectId, taskId, subTaskId, assigneeId) {
        console.log("_applySelectionNow called with:", JSON.stringify({
            accountId, projectId, subProjectId, taskId, subTaskId, assigneeId
        }));

        // Update internal state
        selectedAccountId = accountId;
        selectedProjectId = subProjectId !== -1 ? subProjectId : projectId;
        selectedTaskId = subTaskId !== -1 ? subTaskId : taskId;
        selectedAssigneeId = assigneeId;

        // Set account selector first
        if (accountId !== -1 && accountSelector.selectAccountById) {
            console.log("Setting account selector to:", accountId);
            accountSelector.selectAccountById(accountId);
        }

        // Set account ID for all selectors
        projectSelectorWrapper.accountId = accountId;
        taskSelectorWrapper.accountId = accountId;
        assigneeSelectorWrapper.accountId = accountId;

        // Load selectors in sequence with proper timing
        Qt.callLater(() => {
            console.log("Loading project selector with ID:", selectedProjectId);
            projectSelectorWrapper.loadParentSelector(selectedProjectId);
            
            // Force update the effective ID immediately after loading
            Qt.callLater(() => {
                projectSelectorWrapper.effectiveId = selectedProjectId;
                projectSelectorWrapper.syncEffectiveId(); // Sync from actual selector state
                console.log("Forced project effectiveId to:", projectSelectorWrapper.effectiveId);

                Qt.callLater(() => {
                    console.log("Setting up task selector");
                    // Configure task selector with project filter
                    if (selectedProjectId !== -1) {
                        taskSelectorWrapper.setProjectFilter(selectedProjectId);
                        console.log("Task filter set to project:", selectedProjectId);
                    } else {
                        taskSelectorWrapper.setProjectFilter(-1);
                        console.log("Task filter cleared (show all tasks)");
                    }
                    
                    taskSelectorWrapper.loadParentSelector(selectedTaskId);
                    console.log("Loading task selector with ID:", selectedTaskId);
                    
                    // Force update the task effective ID immediately after loading
                    Qt.callLater(() => {
                        taskSelectorWrapper.effectiveId = selectedTaskId;
                        taskSelectorWrapper.syncEffectiveId(); // Sync from actual selector state
                        console.log("Forced task effectiveId to:", taskSelectorWrapper.effectiveId);

                        Qt.callLater(() => {
                            console.log("Loading assignee selector with ID:", selectedAssigneeId);
                            assigneeSelectorWrapper.loadSelector(selectedAssigneeId);
                            
                            // Final state verification
                            Qt.callLater(() => {
                                console.log("Final state verification:");
                                debugSelectorStates();
                            });
                        });
                    });
                });
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
        console.log("  - effectiveId:", projectSelectorWrapper.effectiveId);
        console.log("  - parentSelector exists:", projectSelectorWrapper.parentSelector ? "Yes" : "No");
        if (projectSelectorWrapper.parentSelector) {
            console.log("  - parentSelector.selectedId:", projectSelectorWrapper.parentSelector.selectedId);
            console.log("  - parentSelector.currentText:", projectSelectorWrapper.parentSelector.currentText);
        }
        console.log("  - childSelector exists:", projectSelectorWrapper.childSelector ? "Yes" : "No");
        if (projectSelectorWrapper.childSelector) {
            console.log("  - childSelector.selectedId:", projectSelectorWrapper.childSelector.selectedId);
            console.log("  - childSelector.currentText:", projectSelectorWrapper.childSelector.currentText);
        }
        
        console.log("Task Selector:");
        console.log("  - effectiveId:", taskSelectorWrapper.effectiveId);
        console.log("  - parentSelector exists:", taskSelectorWrapper.parentSelector ? "Yes" : "No");
        if (taskSelectorWrapper.parentSelector) {
            console.log("  - parentSelector.selectedId:", taskSelectorWrapper.parentSelector.selectedId);
            console.log("  - parentSelector.currentText:", taskSelectorWrapper.parentSelector.currentText);
        }
        console.log("  - childSelector exists:", taskSelectorWrapper.childSelector ? "Yes" : "No");
        if (taskSelectorWrapper.childSelector) {
            console.log("  - childSelector.selectedId:", taskSelectorWrapper.childSelector.selectedId);
            console.log("  - childSelector.currentText:", taskSelectorWrapper.childSelector.currentText);
        }
        
        console.log("Assignee Selector:");
        console.log("  - effectiveId:", assigneeSelectorWrapper.effectiveId);
        console.log("  - selectedId:", assigneeSelectorWrapper.selectedId);
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
                console.log("Loading assignee selector with selectedId:", selectedId, "accountId:", accountId);
                
                if (accountId === -1) {
                    console.log("Cannot load assignees - no account selected");
                    return;
                }
                
                let records = Accounts.getUsers(accountId);
                console.log("Found", records.length, "users for account", accountId);
                
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
                    console.log("Selected 'Unassigned' option");
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
                        console.log("Found selected assignee:", name, "with ID:", id);
                    }
                }
                
                console.log("Built model with", flatModel.length, "items, selectedFound:", selectedFound);
                assigneeSelectorWrapper.dataList = flatModel;
                assigneeSelectorWrapper.reload();
                
                // Set the effective ID immediately
                effectiveId = selectedId !== undefined ? selectedId : -1;
                
                // Use Qt.callLater to ensure proper timing for UI updates
                Qt.callLater(() => {
                    console.log("Setting assignee UI - selectedId:", selectedId, "selectedText:", selectedText);
                    assigneeSelectorWrapper.selectedId = selectedId !== undefined ? selectedId : -1;
                    assigneeSelectorWrapper.currentText = selectedText;
                    
                    // Verify the final state
                    Qt.callLater(() => {
                        console.log("Assignee final state - selectedId:", assigneeSelectorWrapper.selectedId, 
                                  "currentText:", assigneeSelectorWrapper.currentText, 
                                  "effectiveId:", effectiveId);
                    });
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

            // Function to sync effectiveId from actual selector state
            function syncEffectiveId() {
                var actualId = -1;
                if (childSelector && childSelector.selectedId !== -1) {
                    actualId = childSelector.selectedId;
                    console.log("Project: Syncing from childSelector:", actualId);
                } else if (parentSelector && parentSelector.selectedId !== -1) {
                    actualId = parentSelector.selectedId;
                    console.log("Project: Syncing from parentSelector:", actualId);
                }
                if (actualId !== effectiveId) {
                    console.log("Project: effectiveId changed from", effectiveId, "to", actualId);
                    effectiveId = actualId;
                }
                return actualId;
            }

            onParentItemSelected: {
                // Handle immediate project selection - enable and populate task selector
                console.log("Project immediately selected:", id);
                effectiveId = id; // Update effective ID immediately
                if (id !== -1) {
                    taskSelectorWrapper.accountId = selectedAccountId;
                    taskSelectorWrapper.setProjectFilter(id);
                    taskSelectorWrapper.loadParentSelector(-1);
                }
            }

            onFinalItemSelected: {
                effectiveId = id;
                console.log("Final Project ID:", effectiveId);
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

            // Function to sync effectiveId from actual selector state
            function syncEffectiveId() {
                var actualId = -1;
                if (childSelector && childSelector.selectedId !== -1) {
                    actualId = childSelector.selectedId;
                    console.log("Task: Syncing from childSelector:", actualId);
                } else if (parentSelector && parentSelector.selectedId !== -1) {
                    actualId = parentSelector.selectedId;
                    console.log("Task: Syncing from parentSelector:", actualId);
                }
                if (actualId !== effectiveId) {
                    console.log("Task: effectiveId changed from", effectiveId, "to", actualId);
                    effectiveId = actualId;
                }
                return actualId;
            }

            onParentItemSelected: {
                // Handle immediate task selection
                console.log("Task immediately selected:", id);
                effectiveId = id; // Update effective ID immediately
            }

            onFinalItemSelected: {
                effectiveId = id;
                console.log("Final Task ID:", effectiveId);
            }
        }

        Timer {
            id: deferredApplyTimer
            interval: 250  // Increased interval for better timing
            repeat: true
            running: false
            property var deferredPayload: null
            property int retryCount: 0
            property int maxRetries: 15

            onTriggered: {
                if (!deferredPayload) {
                    stop();
                    return;
                }
                
                retryCount++;
                var modelCount = accountSelector.model ? accountSelector.model.count : 0;
                console.log("Deferred timer retry:", retryCount, "Model count:", modelCount);
                
                if (modelCount > 0) {
                    console.log("Models ready, applying deferred selection");
                    stop();
                    let payload = deferredPayload;
                    deferredPayload = null;
                    retryCount = 0;
                    
                    // Call the actual implementation function to avoid recursion
                    Qt.callLater(() => {
                        _applySelectionNow(payload.accountId, payload.projectId, payload.subProjectId, 
                                         payload.taskId, payload.subTaskId, payload.assigneeId);
                    });
                } else if (retryCount >= maxRetries) {
                    console.warn("Max retries reached, stopping deferred timer");
                    stop();
                    retryCount = 0;
                    deferredPayload = null;
                }
            }
        }
    }
}
