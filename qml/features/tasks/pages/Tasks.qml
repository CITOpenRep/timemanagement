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
import QtQuick.Window 2.2
import Qt.labs.settings 1.0
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.Components.Pickers 1.3
import QtCharts 2.0
import "../../../../models/task.js" as Task
import "../../../../models/timesheet.js" as Timesheet
import "../../../../models/utils.js" as Utils
import "../../../../models/global.js" as Global
import "../../../../models/activity.js" as Activity
import "../../../../models/timer_service.js" as TimerService
import "../js/taskFormUtils.js" as TaskFormUtils

import "../../../components"
import "../../../components/richtext"
import "../components"

Page {
    id: taskCreate
    title: i18n.dtr("ubtms", "Task")
    header: PageHeader {
        title: taskCreate.title + (draftHandler.hasUnsavedChanges ? " •" : "")
        StyleHints {
            foregroundColor: "white"
            backgroundColor: LomiriColors.orange
            dividerColor: LomiriColors.slate
        }

        // Custom back button with unsaved changes check
        leadingActionBar.actions: [
            Action {
                iconName: "back"
                text: i18n.dtr("ubtms", "Back")
                onTriggered: {
                    handleBackNavigation();
                }
            }
        ]

        trailingActionBar.actions: [
            Action {
                iconSource: "../../../images/save.svg"
                visible: !isReadOnly
                text: i18n.dtr("ubtms", "Save")
                onTriggered: {
                    save_task_data();
                }
            },
            Action {
                iconName: "edit"
                visible: isReadOnly && recordid !== 0 && editVisible
                text: i18n.dtr("ubtms", "Edit")
                onTriggered: {
                    switchToEditMode();
                }
            },
            Action{
                iconName: "close"
                text: i18n.dtr("ubtms", "Close")
                visible: draftHandler.hasUnsavedChanges 
                onTriggered: {
                    restoreFormToOriginal();  // Restore form to original values
            draftHandler.clearDraft(); // Clear the draft from database
             Qt.callLater(navigateBack);
                }
            }
        ]
    }
    property var recordid: 0 //0 means creation mode
    property bool isOdooRecordId: false // If true, recordid is an odoo_record_id, not local id

    property string currentEditingField: ""
    property bool workpersonaSwitchState: true
    property bool isReadOnly: recordid != 0 // Set read-only immediately based on recordid
    property int selectedProjectId: 0
    property int selectedparentId: 0
    property int selectedTaskId: 0
    property int priority: 0
    property bool editVisible: true   
    onPriorityChanged: {
        if (draftHandler.enabled && draftHandler._initialized) {
            draftHandler.markFieldChanged("priority", priority);
        }
    }
    
    property int subProjectId: 0
    property var prevtask: ""
    property var textkey: ""
    property bool descriptionExpanded: false
    property real expandedHeight: units.gu(60)
    property int selectedStageOdooRecordId: -1 // For storing selected stage during task creation
    property var selectedPersonalStageOdooRecordId: null // For storing selected personal stage (null = no stage, >0 = stage ID)
    
    // Track stage changes for draft management
    onSelectedStageOdooRecordIdChanged: {
        if (isRestoringFromDraft) {
            return;
        }
        if (draftHandler.enabled && draftHandler._initialized) {
            draftHandler.markFieldChanged("selectedStageOdooRecordId", selectedStageOdooRecordId);
        } else {
        }
    }
    
    onSelectedPersonalStageOdooRecordIdChanged: {
        if (isRestoringFromDraft) {
            return;
        }
        if (draftHandler.enabled && draftHandler._initialized) {
            draftHandler.markFieldChanged("selectedPersonalStageOdooRecordId", selectedPersonalStageOdooRecordId);
        } else {
        }
    }

    // Properties for prefilled data when creating task from project
    property var prefilledAccountId: -1
    property var prefilledProjectId: -1
    property var prefilledSubProjectId: -1
    property var prefilledParentProjectId: -1
    property string prefilledProjectName: ""

    property var currentTask: {}

    // Track if we're navigating to ReadMorePage to avoid showing save dialog
    property bool navigatingToReadMore: false
    
    // Track if form is fully initialized (to defer draft restoration)
    property bool formFullyInitialized: false
    
    // Flag to suppress change tracking during draft restoration
    property bool isRestoringFromDraft: false

    // Handle hardware back button presses
    Keys.onReleased: {
        if (event.key === Qt.Key_Back || event.key === Qt.Key_Escape) {
            event.accepted = true;
            handleBackNavigation();
        }
    }

    // ==================== DRAFT HANDLER ====================
    FormDraftHandler {
        id: draftHandler
        draftType: "task"
        recordId: taskCreate.recordid
        accountId: (currentTask && currentTask.account_id) ? currentTask.account_id : 0
        enabled: !isReadOnly
        autoSaveInterval: 30000 // 30 seconds
        
        onDraftLoaded: {
            // Only restore if form is fully initialized
            if (formFullyInitialized) {
                restoreFormFromDraft(draftData);
                notifPopup.open("📂 Draft Found", 
                    "Unsaved changes restored. ", 
                    "info");
            } else {
                // Defer restoration until form is ready
                Qt.callLater(function() {
                    if (formFullyInitialized) {
                        restoreFormFromDraft(draftData);
                        notifPopup.open("📂 Draft Restored", 
                            "Unsaved changes restored: " + getChangesSummary(), 
                            "info");
                    }
                });
            }
        }
        
        onUnsavedChangesWarning: {
            // This signal is now handled by the back button logic
        }
        
        onDraftSaved: {
        }
    }

    SaveDiscardDialog {
        id: saveDiscardDialog
        onSaveRequested: {
            var success = save_task_data(true); // true = skip automatic navigation
            // Only navigate back if save was successful
            if (success) {
                Qt.callLater(navigateBack);
            }
        }
        onDiscardRequested: {
            restoreFormToOriginal();  // Restore form to original values
            draftHandler.clearDraft(); // Clear the draft from database
            Qt.callLater(navigateBack);
        }
        onCancelled: {
        }
    }

    function handleBackNavigation() {
        // Check if we're navigating to ReadMore page
        if (navigatingToReadMore) {
            navigateBack();
            return;
        }
        
        // Check if we have unsaved changes
        if (!isReadOnly && draftHandler.hasUnsavedChanges) {
            saveDiscardDialog.open();
            return;
        }
        
        // No unsaved changes, navigate back normally
        navigateBack();
    }

    function navigateBack() {
        
        // Method 1: AdaptivePageLayout (primary method for this app)
        try {
            if (typeof apLayout !== "undefined" && apLayout && apLayout.removePages) {
                apLayout.removePages(taskCreate);
                return;
            }
        } catch (e) {
        }
        
        // Method 2: Standard pageStack
        try {
            if (typeof pageStack !== "undefined" && pageStack && pageStack.pop) {
                pageStack.pop();
                return;
            }
        } catch (e) {
            console.error("❌ Navigation error with pageStack:", e);
        }

        // Method 3: Parent pop
        try {
            if (parent && parent.pop) {
                parent.pop();
                return;
            }
        } catch (e) {
            console.error("❌ Parent navigation error:", e);
        }
        
        console.warn("⚠️ No navigation method found!");
    }

    function restoreStageSelections(stageId, personalStageId) {
        if (stageId !== undefined && stageId !== null) {
            selectedStageOdooRecordId = stageId;
        }
        if (personalStageId !== undefined) {
            selectedPersonalStageOdooRecordId = personalStageId;
        }
    }

    function finishDraftRestoration() {
        Qt.callLater(function() {
            isRestoringFromDraft = false;
            draftHandler.trackingSuspended = false;
        });
    }

    function restoreFormFromDraft(draftData) {
        isRestoringFromDraft = true;
        draftHandler.trackingSuspended = true;
        
        if (draftData.name) taskNameField.text = draftData.name;
        if (draftData.description) description_text.setContent(draftData.description);
        if (draftData.plannedHours) taskScheduleFields.hoursText = draftData.plannedHours;
        if (draftData.priority !== undefined) priority = draftData.priority;
        
        if (draftData.startDate || draftData.endDate) {
            taskScheduleFields.setDateRange(draftData.startDate || "", draftData.endDate || "");
        }
        
        if (draftData.deadline) {
            taskScheduleFields.deadlineText = draftData.deadline;
        }
        
        if (draftData.accountId !== undefined || draftData.projectId !== undefined) {
            var accountId = TaskFormUtils.normalizeIdForRestore(draftData.accountId);
            var projectId = TaskFormUtils.normalizeIdForRestore(draftData.projectId);
            
            if (TaskFormUtils.restoreWorkItemSelection(workItem, draftData)) {
                if (projectId > 0 && accountId > 0) {
                    var savedStageId = draftData.selectedStageOdooRecordId;
                    var savedPersonalStageId = draftData.selectedPersonalStageOdooRecordId;
                    
                    Qt.callLater(function() {
                        loadStagesForProject(projectId, accountId);
                        Qt.callLater(function() {
                            restoreStageSelections(savedStageId, savedPersonalStageId);
                            // Update combobox to match restored stage
                            if (savedStageId !== undefined && savedStageId !== null) {
                                for (var i = 0; i < initialStageSelector.model.count; i++) {
                                    if (initialStageSelector.model.get(i).odoo_record_id === savedStageId) {
                                        initialStageSelector.currentIndex = i;
                                        break;
                                    }
                                }
                            }
                            finishDraftRestoration();
                        });
                    });
                    return; // Early return — async completion
                }
            }
        }
        
        // Synchronous path: restore stages and finish
        restoreStageSelections(draftData.selectedStageOdooRecordId, draftData.selectedPersonalStageOdooRecordId);
        finishDraftRestoration();
    }
    
    function restoreFormToOriginal() {
        
        var originalData = draftHandler.originalData;
        if (originalData.name !== undefined) taskNameField.text = originalData.name;
        if (originalData.description !== undefined) description_text.setContent(originalData.description);
        if (originalData.plannedHours !== undefined) taskScheduleFields.hoursText = originalData.plannedHours;
        if (originalData.priority !== undefined) priority = originalData.priority;
        
        if (originalData.startDate !== undefined || originalData.endDate !== undefined) {
            taskScheduleFields.setDateRange(
                originalData.startDate || "", 
                originalData.endDate || ""
            );
        }
        
        if (originalData.deadline !== undefined) {
            taskScheduleFields.deadlineText = originalData.deadline;
        }
        
        if (originalData.accountId !== undefined || originalData.projectId !== undefined) {
            TaskFormUtils.restoreWorkItemSelection(workItem, originalData);
        }
        
        // Restore stage selections
        if (originalData.selectedStageOdooRecordId !== undefined) {
            selectedStageOdooRecordId = originalData.selectedStageOdooRecordId;
        }
        if (originalData.selectedPersonalStageOdooRecordId !== undefined) {
            selectedPersonalStageOdooRecordId = originalData.selectedPersonalStageOdooRecordId;
        }
    }
    
    function getCurrentFormData() {
        return TaskFormUtils.getCurrentFormData({
            workItem: workItem,
            name: taskNameField.text,
            description: description_text.getFormattedText ? description_text.getFormattedText() : description_text.text,
            plannedHours: taskScheduleFields.hoursText,
            priority: priority,
            startDate: taskScheduleFields.formattedStartDate(),
            endDate: taskScheduleFields.formattedEndDate(),
            deadline: taskScheduleFields.deadlineText,
            selectedStageOdooRecordId: selectedStageOdooRecordId,
            selectedPersonalStageOdooRecordId: selectedPersonalStageOdooRecordId
        });
    }

    function switchToEditMode() {
        // Simply change the current page to edit mode
        if (recordid !== 0) {
            isReadOnly = false;
            
            // Initialize draft handler when switching from read-only to edit mode
            // This ensures drafts are loaded if they exist
            draftHandler.trackingSuspended = true;
            Qt.callLater(function() {
                var originalTaskData = getCurrentFormData();
                draftHandler.initialize(originalTaskData);
                if (!draftHandler.currentDraftId) {
                    draftHandler.trackingSuspended = false;
                }
            });
        }
    }

    function finalizeInitialFormSetup() {
        Qt.callLater(function() {
            Qt.callLater(function() {
                formFullyInitialized = true;

                if (!isReadOnly) {
                    var originalTaskData = getCurrentFormData();
                    draftHandler.initialize(originalTaskData);
                    if (!draftHandler.currentDraftId) {
                        draftHandler.trackingSuspended = false;
                    }
                } else {
                    draftHandler.trackingSuspended = false;
                }
            });
        });
    }

    function validateHoursInput(text) {
        return TaskFormUtils.validateHoursInput(text);
    }
    function formatHoursDisplay(text) {
        return TaskFormUtils.formatHoursDisplay(text);
    }

    function save_task_data(skipNavigation) {
        const ids = workItem.getIds();

        // Check for assignees - either single or multiple
        var hasAssignees = false;
        if (workItem.enableMultipleAssignees) {
            hasAssignees = ids.multiple_assignees && ids.multiple_assignees.length > 0;
        } else {
            hasAssignees = ids.assignee_id !== null;
        }

        if (!hasAssignees) {
            notifPopup.open("Error", "Please select at least one assignee", "error");
            return false;
        }
        if (!ids.project_id) {
            notifPopup.open("Error", "Please select the project", "error");
            return false;
        }

        // Validate hours input before saving
        if (taskScheduleFields.hoursText !== "" && !validateHoursInput(taskScheduleFields.hoursText)) {
            notifPopup.open("Error", "Please enter valid hours (e.g., 1.5, 2:30, or 8:00)", "error");
            return false;
        }

        if (taskNameField.text != "") {
            const saveData = TaskFormUtils.buildSaveData({
                ids: ids,
                name: taskNameField.text,
                recordId: recordid,
                startDate: taskScheduleFields.formattedStartDate(),
                endDate: taskScheduleFields.formattedEndDate(),
                deadline: taskScheduleFields.deadlineText,
                priority: priority,
                plannedHours: taskScheduleFields.hoursText,
                description: description_text.getFormattedText ? description_text.getFormattedText() : description_text.text,
                selectedStageOdooRecordId: selectedStageOdooRecordId,
                selectedPersonalStageOdooRecordId: selectedPersonalStageOdooRecordId,
                stageListCount: initialStageSelector.model.count,
                firstStage: initialStageSelector.model.count > 0 ? initialStageSelector.model.get(0) : null,
                enableMultipleAssignees: workItem.enableMultipleAssignees
            });

            const result = Task.saveOrUpdateTask(saveData);
            if (!result.success) {
                notifPopup.open("Error", "Unable to Save the Task", "error");
                return false;
            } else {
                notifPopup.open("Saved", "Task has been saved successfully", "success");

                // Prevent programmatic UI normalization from creating a fresh draft.
                draftHandler.trackingSuspended = true;

                // Format the hours display after successful save.
                if (taskScheduleFields.hoursText !== "") {
                    taskScheduleFields.hoursText = formatHoursDisplay(taskScheduleFields.hoursText);
                }

                // Clear any persisted draft and reset the clean baseline to the saved state.
                draftHandler.clearDraft();
                draftHandler.updateOriginalData(getCurrentFormData());
                draftHandler.trackingSuspended = false;
                
                // Navigate back to list view after successful save (unless skipNavigation is true)
                if (!skipNavigation) {
                    navigateBack();
                }
                
                return true;
            }
        } else {
            notifPopup.open("Error", "Please add a Name to the task", "error");
            return false;
        }
    }

    function incdecHrs(value) {
        var currentText = taskScheduleFields.hoursText || "0:00";
        var currentFloat = Utils.convertDurationToFloat(currentText);

        if (value === 1) {
            currentFloat += 1.0;
        } else {
            if (currentFloat >= 1.0) {
                currentFloat -= 1.0;
            }
        }

        taskScheduleFields.hoursText = Utils.convertDecimalHoursToHHMM(currentFloat);
    }

    NotificationPopup {
        id: notifPopup
        width: units.gu(80)
        height: units.gu(80)
    }

    Component {
        id: taskStageSelector
        TaskStageSelector {
            onStageSelected: {
                handleStageChange(stageOdooRecordId, stageName);
            }
        }
    }

    Component {
        id: personalStageSelector
        PersonalStageSelector {
            onPersonalStageSelected: {
                handlePersonalStageChange(personalStageOdooRecordId, personalStageName);
            }
        }
    }

    function handleStageChange(stageOdooRecordId, stageName) {
        if (!currentTask || !currentTask.id) {
            notifPopup.open("Error", "Task data not available", "error");
            return;
        }

        var result = Task.updateTaskStage(currentTask.id, stageOdooRecordId, currentTask.account_id);

        if (result.success) {
            // Update the current task's stage
            currentTask.state = stageOdooRecordId;

            // Reload the task to reflect changes
            loadTask();

            notifPopup.open("Success", "Task stage changed to: " + stageName, "success");
        } else {
            notifPopup.open("Error", "Failed to change stage: " + (result.error || "Unknown error"), "error");
        }
    }

    function handlePersonalStageChange(personalStageOdooRecordId, personalStageName) {
        if (!currentTask || !currentTask.id) {
            notifPopup.open("Error", "Task data not available", "error");
            return;
        }

        var result = Task.updateTaskPersonalStage(currentTask.id, personalStageOdooRecordId, currentTask.account_id);

        if (result.success) {
            // Update the current task's personal stage
            currentTask.personal_stage = personalStageOdooRecordId;

            // Update the property to preserve it during next save
            selectedPersonalStageOdooRecordId = personalStageOdooRecordId;

            // Reload the task to reflect changes
            loadTask();

            var message = personalStageOdooRecordId === null ? "Personal stage cleared" : "Personal stage changed to: " + personalStageName;
            notifPopup.open("Success", message, "success");
        } else {
            notifPopup.open("Error", "Failed to change personal stage: " + (result.error || "Unknown error"), "error");
        }
    }

    function loadStagesForProject(projectOdooRecordId, accountId) {

        if (projectOdooRecordId <= 0 || accountId <= 0) {
            initialStageSelector.model.clear();
            initialStageSelector.currentIndex = -1;
            selectedStageOdooRecordId = -1;
            return;
        }

        var stages = Task.getTaskStagesForProject(projectOdooRecordId, accountId);
        initialStageSelector.model.clear();

        for (var i = 0; i < stages.length; i++) {
            initialStageSelector.model.append({
                odoo_record_id: stages[i].odoo_record_id,
                name: stages[i].name,
                sequence: stages[i].sequence,
                fold: stages[i].fold
            });
        }

        // Automatically select first stage as default (user can change it)
        if (initialStageSelector.model.count > 0) {
            initialStageSelector.currentIndex = 0;
            var firstStage = initialStageSelector.model.get(0);
            selectedStageOdooRecordId = firstStage.odoo_record_id;
        } else {
            initialStageSelector.currentIndex = -1;
            selectedStageOdooRecordId = -1;
            console.warn("No stages available for project", projectOdooRecordId);
        }

    }

    Flickable {
        id: tasksDetailsPageFlickable
        anchors.topMargin: units.gu(6)
        anchors.fill: parent
        contentHeight: contentColumn.childrenRect.height + units.gu(10)
        flickableDirection: Flickable.VerticalFlick

        width: parent.width

        Column {
            id: contentColumn
            width: parent.width
            spacing: units.gu(1)

        Row {
            id: myRow1a
            width: parent.width
            height: workItemColumn.implicitHeight
            Column {
                id: workItemColumn
                leftPadding: units.gu(1)

                WorkItemSelector {
                    id: workItem
                    readOnly: isReadOnly
                    taskLabelText: i18n.dtr("ubtms", "Parent Task")
                    showAccountSelector: true
                    showAssigneeSelector: true
                    enableMultipleAssignees: true  // Enable multiple assignee selection
                    showProjectSelector: true
                    showSubProjectSelector: true
                    showTaskSelector: true
                    showSubTaskSelector: false
                    width: tasksDetailsPageFlickable.width - units.gu(2)

                    onMultiAssigneesChanged: {
                        if (draftHandler.enabled && draftHandler._initialized) {
                            var idsForDraft = workItem.getIds();
                            draftHandler.markFieldChanged("multipleAssignees", idsForDraft.multiple_assignees);
                            draftHandler.markFieldChanged("assigneeIds", idsForDraft.assignee_ids);
                        }
                    }

                    onStateChanged: {
                        // Draft tracking
                        if (draftHandler.enabled && draftHandler._initialized) {
                            var idsForDraft = workItem.getIds();
                            var changedId = data.id || null;

                            var draftFieldMap = {
                                "AccountSelected": "accountId",
                                "ProjectSelected": "projectId",
                                "SubprojectSelected": "subprojectId",
                                "TaskSelected": "taskId",
                                "SubtaskSelected": "subtaskId"
                            };

                            if (draftFieldMap[newState]) {
                                draftHandler.markFieldChanged(draftFieldMap[newState], changedId);
                            } else if (newState === "AssigneeSelected") {
                                if (workItem.enableMultipleAssignees) {
                                    draftHandler.markFieldChanged("multipleAssignees", idsForDraft.multiple_assignees);
                                    draftHandler.markFieldChanged("assigneeIds", idsForDraft.assignee_ids);
                                } else {
                                    draftHandler.markFieldChanged("assigneeId", changedId);
                                }
                            }
                        }

                        // Stage loading (creation mode only)
                        if (recordid === 0) {
                            if (newState === "ProjectSelected") {
                                var ids = workItem.getIds();
                                var projectId = data.id;
                                var accountId = ids.account_id;
                                if (projectId > 0 && accountId > 0) {
                                    loadStagesForProject(projectId, accountId);
                                }
                            } else if (newState === "SubprojectSelected") {
                                var ids2 = workItem.getIds();
                                if (ids2.project_id > 0 && ids2.account_id > 0) {
                                    loadStagesForProject(ids2.project_id, ids2.account_id);
                                }
                            } else if (newState === "AccountSelected") {
                                initialStageSelector.model.clear();
                                initialStageSelector.currentIndex = -1;
                                selectedStageOdooRecordId = -1;
                            }
                        }
                    }
                }
            }
        }
        TaskNameField {
            id: taskNameField
            availableWidth: parent.width
            isReadOnly: taskCreate.isReadOnly
            onNameEdited: {
                if (draftHandler.enabled) {
                    draftHandler.markFieldChanged("name", newText);
                }
            }
        }
        Item {
            id: add_timesheet
            width: parent.width
            height: units.gu(1)
            visible: false
        }
        TaskPrioritySelector {
            id: taskPrioritySelector
            width: parent.width
            priority: taskCreate.priority
            isReadOnly: taskCreate.isReadOnly
            onPriorityChanged: taskCreate.priority = priority
        }

        TaskInitialStageSelector {
            id: initialStageSelector
            width: parent.width - units.gu(2)
            x: units.gu(1)
            visible: taskCreate.recordid === 0
            isReadOnly: taskCreate.isReadOnly

            onStageSelected: taskCreate.selectedStageOdooRecordId = odooRecordId
        }

        Row {
            id: myRow9
            width: parent.width
            topPadding: units.gu(3)

            Column {
                id: myCol9

                Item {
                    id: textAreaContainer
                    width: tasksDetailsPageFlickable.width
                    height: description_text.height

                    RichTextPreview {
                        id: description_text
                        width: parent.width
                        height: units.gu(20) // Start with collapsed height
                        anchors.centerIn: parent.centerIn
                        text: ""
                        is_read_only: isReadOnly
                        onClicked: {
                            //set the data to a global Slore and pass the key to the page
                            navigatingToReadMore = true;
                            var contentToPass = getFormattedText();
                            Global.description_temporary_holder = contentToPass;
                            description_text.liveSyncActive = true;
                            apLayout.addPageToNextColumn(taskCreate, Qt.resolvedUrl("../../../components/richtext/ReadMorePage.qml"), {
                                isReadOnly: isReadOnly,
                                parentDraftHandler: draftHandler // Pass draft handler reference
                            });
                        }
                        
                        // Track inline text changes for draft management
                        onTextChanged: {
                            if (draftHandler.enabled && draftHandler._initialized) {
                                draftHandler.markFieldChanged("description", getFormattedText());
                            }
                        }
                    }
                }
            }
        }

        // Current Stage Display Row
        // Current Stage Display Grid
        TaskRecordActionsGrid {
            id: currentStageRow
            width: parent.width - units.gu(2)
            x: units.gu(1)
            currentTask: taskCreate.currentTask
            recordid: taskCreate.recordid
            onChangeStageRequested: {
                if (!currentTask || !currentTask.id) {
                    notifPopup.open("Error", "Task data not available", "error");
                    return;
                }

                PopupUtils.open(taskStageSelector, taskCreate, {
                    taskId: currentTask.id,
                    projectOdooRecordId: currentTask.project_id,
                    accountId: currentTask.account_id,
                    currentStageOdooRecordId: currentTask.state || -1
                });
            }
            onCreateActivityRequested: {
                let result = Activity.createActivityFromProjectOrTask(false, currentTask.account_id, currentTask.odoo_record_id);
                if (result.success) {
                    apLayout.addPageToNextColumn(taskCreate, Qt.resolvedUrl("../../activities/pages/Activities.qml"), {
                        "recordid": result.record_id,
                        "accountid": currentTask.account_id,
                        "isReadOnly": false
                    });
                } else {
                    notifPopup.open("Failed", "Unable to create activity", "error");
                }
            }
            onViewActivitiesRequested: {
                console.log("Viewing activities for task:", currentTask.id, "odoo_record_id:", currentTask.odoo_record_id);
                apLayout.addPageToNextColumn(taskCreate, Qt.resolvedUrl("../../activities/pages/Activity_Page.qml"), {
                    "filterByTasks": true,
                    "taskOdooRecordId": currentTask.odoo_record_id,
                    "projectAccountId": currentTask.account_id,
                    "projectName": currentTask.name || "Task"
                });
            }
            onCreateTimesheetRequested: {
                const result = Timesheet.createTimesheetFromTask(currentTask.odoo_record_id);
                if (result.success) {
                    apLayout.addPageToNextColumn(taskCreate, Qt.resolvedUrl("../../timesheets/pages/Timesheet.qml"), {
                        "recordid": result.id,
                        "isReadOnly": false
                    });
                } else {
                    console.error("Error creating timesheet:", result.error);
                    notifPopup.open("Error", "Unable to create timesheet: " + result.error, "error");
                }
            }
            onViewTimesheetsRequested: {
                console.log("Viewing timesheets for task:", currentTask.id, "odoo_record_id:", currentTask.odoo_record_id);
                apLayout.addPageToNextColumn(taskCreate, Qt.resolvedUrl("../../timesheets/pages/Timesheet_Page.qml"), {
                    "filterByTask": true,
                    "taskOdooRecordId": currentTask.odoo_record_id,
                    "taskAccountId": currentTask.account_id,
                    "taskName": currentTask.name || "Task"
                });
            }
        }
        TaskScheduleFields {
            id: taskScheduleFields
            availableWidth: parent.width - units.gu(2)
            x: units.gu(1)
            isReadOnly: taskCreate.isReadOnly
            onHoursChanged: {
                if (draftHandler.enabled) {
                    draftHandler.markFieldChanged("plannedHours", text);
                }
            }
            onDateRangeChanged: {
                if (draftHandler.enabled && draftHandler._initialized) {
                    draftHandler.markFieldChanged("startDate", formattedStartDate());
                    draftHandler.markFieldChanged("endDate", formattedEndDate());
                }
            }
            onDeadlineChanged: {
                if (draftHandler.enabled) {
                    draftHandler.markFieldChanged("deadline", text);
                }
            }
        }
        //changed the attachment color
        Rectangle {
                id: attachmentRow
                anchors.top: deadlineRow.bottom
                height: units.gu(50)
                width: parent.width
                anchors.margins: units.gu(0.1)
                color: "transparent"
                AttachmentManager {
                id: attachments_widget
                anchors.fill: parent
                resource_type: "project.task"   // keep as-is if that's your default
                resource_id: (currentTask && currentTask.odoo_record_id) ? currentTask.odoo_record_id : 0
                account_id: (currentTask && currentTask.account_id) ? currentTask.account_id : 0
                notifier: infobar

                onUploadCompleted: {
                    //kinda refresh
                    attachments_widget.setAttachments(Task.getAttachmentsForTask(currentTask.odoo_record_id, currentTask.account_id));
                }

                onItemClicked: function (rec) {
                    // Open viewer / download / preview
                    console.log("Clicked attachment:", rec ? rec.name : rec);
                }
            }
        }
        } // end Column (contentColumn)
    } // end Flickable
    

    function loadTask() {
        draftHandler.trackingSuspended = true;

        if (recordid != 0) // We are loading a task, depends on readonly value it could be for view/edit
        {
            // Use appropriate lookup based on whether recordid is a local id or odoo_record_id
            if (isOdooRecordId) {
                // recordid is an odoo_record_id (stable, from notification deep link)
                currentTask = Task.getTaskDetailsByOdooId(recordid);
                // Update recordid to local id for subsequent operations
                if (currentTask && currentTask.id) {
                    recordid = currentTask.id;
                    isOdooRecordId = false; // Now we have the local id
                }
            } else {
                // recordid is a local id (from normal navigation)
                currentTask = Task.getTaskDetails(recordid);
            }

            let instanceId = (currentTask.account_id !== undefined && currentTask.account_id !== null) ? currentTask.account_id : -1;
            let project_id = (currentTask.project_id !== undefined && currentTask.project_id !== null && currentTask.project_id > 0) ? currentTask.project_id : -1;
            let sub_project_id = (currentTask.sub_project_id !== undefined && currentTask.sub_project_id !== null) ? currentTask.sub_project_id : -1;
            let parent_task_id = (currentTask.parent_id !== undefined && currentTask.parent_id !== null) ? currentTask.parent_id : -1;

            // Handle assignee_id - extract first ID if comma-separated (for single assignee mode)
            let assignee_id = TaskFormUtils.resolveSingleAssigneeId(currentTask.user_id);

            workItem.deferredLoadExistingRecordSet(instanceId, project_id, sub_project_id, parent_task_id, -1, assignee_id); //passing -1 as no subtask feature is needed

            taskNameField.text = currentTask.name || "";
            console.log("[Tasks] loadTask - setting description, currentTask.description:", currentTask.description);
            description_text.setContent(currentTask.description || "");

            // Handle planned hours more carefully
            if (currentTask.initial_planned_hours !== undefined && currentTask.initial_planned_hours !== null && currentTask.initial_planned_hours > 0) {
                taskScheduleFields.hoursText = Utils.convertDecimalHoursToHHMM(parseFloat(currentTask.initial_planned_hours));
            } else {
                taskScheduleFields.hoursText = "01:00";  // Default value
            }

            // Set date range more carefully to preserve original dates
            if (currentTask.start_date && currentTask.end_date) {
                taskScheduleFields.setDateRange(currentTask.start_date, currentTask.end_date);
            } else if (currentTask.start_date) {
                taskScheduleFields.setDateRange(currentTask.start_date, null);
            } else if (currentTask.end_date) {
                taskScheduleFields.setDateRange(null, currentTask.end_date);
            }
            // If no dates are set, don't call setDateRange to avoid defaulting to today

            // Set deadline
            if (currentTask.deadline) {
                taskScheduleFields.deadlineText = currentTask.deadline;
            } else {
                taskScheduleFields.deadlineText = "Not set";
            }

            // Set task priority (0-3) - convert from string to numeric for UI
            priority = Math.max(0, Math.min(3, parseInt(currentTask.priority || "0")));

            // Set the current task's stage (IMPORTANT: preserves stage during edit)
            if (currentTask.state !== undefined && currentTask.state !== null) {
                selectedStageOdooRecordId = currentTask.state;
                console.log("Loaded task stage:", selectedStageOdooRecordId);
            } else {
                selectedStageOdooRecordId = -1;
                console.log("Task has no stage set");
            }

            // Set the current task's personal stage (IMPORTANT: preserves personal stage during edit)
            if (currentTask.personal_stage !== undefined && currentTask.personal_stage !== null) {
                selectedPersonalStageOdooRecordId = currentTask.personal_stage;
                console.log("Loaded task personal stage:", selectedPersonalStageOdooRecordId);
            } else {
                selectedPersonalStageOdooRecordId = null;
                console.log("Task has no personal stage set");
            }

            Qt.callLater(function() {
                // Defer secondary data so the main form renders first.
                if (workItem.enableMultipleAssignees) {
                    var existingAssignees = Task.getTaskAssignees(recordid, instanceId);
                    workItem.setMultipleAssignees(existingAssignees);
                }

                attachments_widget.setAttachments(Task.getAttachmentsForTask(currentTask.odoo_record_id, currentTask.account_id));
            });
        } else {
            // We are creating a new task
            workItem.loadAccounts();
            taskScheduleFields.deadlineText = "Not set";

            // Handle prefilled data when creating task from project
            if (prefilledAccountId !== -1) {
                var mainProjectId = prefilledProjectId !== -1 ? prefilledProjectId : prefilledParentProjectId;
                var subProjectId = prefilledSubProjectId !== -1 ? prefilledSubProjectId : -1;

                // Set prefilled account, project, and subproject data
                if (workItem.deferredLoadExistingRecordSet) {
                    workItem.deferredLoadExistingRecordSet(prefilledAccountId, mainProjectId, subProjectId, -1, -1, -1);
                } else if (workItem.applyDeferredSelection) {
                    workItem.applyDeferredSelection(prefilledAccountId, mainProjectId, subProjectId);
                }

                // Load stages for the prefilled project
                if (mainProjectId > 0 && prefilledAccountId > 0) {
                    console.log("🎯 Loading stages for prefilled project:", mainProjectId, "account:", prefilledAccountId);
                    loadStagesForProject(mainProjectId, prefilledAccountId);
                }
            }
        }
    
        finalizeInitialFormSetup();
    }

    Component.onCompleted: {
        loadTask();
    }

    onVisibleChanged: {
        if (visible) {
            // Update navigation tracking when Tasks detail page becomes visible
            Global.setLastVisitedPage("Tasks");

            // Stop live sync — content is already up-to-date via the timer
            description_text.liveSyncActive = false;

            if (Global.description_temporary_holder !== "") {
                //Check if you are coming back from the ReadMore page
                description_text.setContent(Global.description_temporary_holder);
                Global.description_temporary_holder = "";
                navigatingToReadMore = false; // Reset the flag after coming back
                
                // Track description change for draft
                if (draftHandler.enabled) {
                    draftHandler.markFieldChanged("description", description_text.getFormattedText());
                }
            }
        } else {
            if (!isReadOnly && draftHandler.hasUnsavedChanges) {
                draftHandler.saveDraft();
            }

            // Only clear the holder if we're not navigating to ReadMore
            if (!navigatingToReadMore) {
                Global.description_temporary_holder = "";
            }
        }
    }
}
