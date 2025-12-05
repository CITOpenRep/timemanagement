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
import "../models/task.js" as Task
import "../models/timesheet.js" as Timesheet
import "../models/utils.js" as Utils
import "../models/global.js" as Global
import "../models/activity.js" as Activity
import "../models/accounts.js" as Accounts
import "../models/timer_service.js" as TimerService

import "components"

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
                iconSource: "images/save.svg"
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
        console.log("🎯 Stage changed to:", selectedStageOdooRecordId);
        if (isRestoringFromDraft) {
            console.log("⏭️ Stage tracking skipped - restoring from draft");
            return;
        }
        if (draftHandler.enabled && draftHandler._initialized) {
            draftHandler.markFieldChanged("selectedStageOdooRecordId", selectedStageOdooRecordId);
            console.log("📝 Tracked stage change - hasUnsavedChanges:", draftHandler.hasUnsavedChanges);
        } else {
            console.log("⏸️ Stage tracking skipped - enabled:", draftHandler.enabled, "initialized:", draftHandler._initialized);
        }
    }
    
    onSelectedPersonalStageOdooRecordIdChanged: {
        console.log("🎯 Personal stage changed to:", selectedPersonalStageOdooRecordId);
        if (isRestoringFromDraft) {
            console.log("⏭️ Personal stage tracking skipped - restoring from draft");
            return;
        }
        if (draftHandler.enabled && draftHandler._initialized) {
            draftHandler.markFieldChanged("selectedPersonalStageOdooRecordId", selectedPersonalStageOdooRecordId);
            console.log("📝 Tracked personal stage change - hasUnsavedChanges:", draftHandler.hasUnsavedChanges);
        } else {
            console.log("⏸️ Personal stage tracking skipped - enabled:", draftHandler.enabled, "initialized:", draftHandler._initialized);
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
        autoSaveInterval: 300000 // 5 minutes
        
        onDraftLoaded: {
            // Only restore if form is fully initialized
            if (formFullyInitialized) {
                restoreFormFromDraft(draftData);
                notifPopup.open("📂 Draft Found", 
                    "Unsaved changes restored. ", 
                    "info");
            } else {
                // Defer restoration until form is ready
                console.log("⏳ Deferring draft restoration until form is fully initialized...");
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
            console.log("⚠️ Unsaved changes detected");
        }
        
        onDraftSaved: {
            console.log("💾 Draft saved successfully (ID: " + draftId + ")");
        }
    }

    SaveDiscardDialog {
        id: saveDiscardDialog
        onSaveRequested: {
            console.log("💾 SaveDiscardDialog: Saving task...");
            var success = save_task_data(true); // true = skip automatic navigation
            // Only navigate back if save was successful
            if (success) {
                Qt.callLater(navigateBack);
            }
        }
        onDiscardRequested: {
            console.log("🗑️ SaveDiscardDialog: Discarding changes...");
            restoreFormToOriginal();  // Restore form to original values
            draftHandler.clearDraft(); // Clear the draft from database
            Qt.callLater(navigateBack);
        }
        onCancelled: {
            console.log("❌ User cancelled navigation - staying on page");
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
            console.log("⚠️ Unsaved changes detected on back navigation");
            saveDiscardDialog.open();
            return;
        }
        
        // No unsaved changes, navigate back normally
        navigateBack();
    }

    function navigateBack() {
        console.log("🔙 Attempting to navigate back...");
        
        // Method 1: AdaptivePageLayout (primary method for this app)
        try {
            if (typeof apLayout !== "undefined" && apLayout && apLayout.removePages) {
                console.log("✅ Navigating via apLayout.removePages()");
                apLayout.removePages(taskCreate);
                return;
            }
        } catch (e) {
            console.error("❌ apLayout navigation error:", e);
        }
        
        // Method 2: Standard pageStack
        try {
            if (typeof pageStack !== "undefined" && pageStack && pageStack.pop) {
                console.log("✅ Navigating via pageStack.pop()");
                pageStack.pop();
                return;
            }
        } catch (e) {
            console.error("❌ Navigation error with pageStack:", e);
        }

        // Method 3: Parent pop
        try {
            if (parent && parent.pop) {
                console.log("✅ Navigating via parent.pop()");
                parent.pop();
                return;
            }
        } catch (e) {
            console.error("❌ Parent navigation error:", e);
        }
        
        console.warn("⚠️ No navigation method found!");
    }

    function restoreFormFromDraft(draftData) {
        console.log("🔄 Restoring form from draft data...");
        
        // Set flag to suppress tracking during restoration
        isRestoringFromDraft = true;
        
        if (draftData.name) name_text.text = draftData.name;
        if (draftData.description) description_text.setContent(draftData.description);
        if (draftData.plannedHours) hours_input.text = draftData.plannedHours;
        if (draftData.priority !== undefined) priority = draftData.priority;
        
        if (draftData.startDate || draftData.endDate) {
            date_range_widget.setDateRange(
                draftData.startDate || "", 
                draftData.endDate || ""
            );
        }
        
        if (draftData.deadline) {
            deadline_text.text = draftData.deadline;
        }
        
        // Restore WorkItemSelector selections
        // Helper function to convert null/undefined to -1 for WorkItemSelector
        // WorkItemSelector expects -1 for "not selected", but stores null in drafts
        function normalizeIdForRestore(value) {
            if (value === null || value === undefined) return -1;
            var num = parseInt(value);
            return isNaN(num) ? -1 : num;
        }
        
        if (draftData.accountId !== undefined || draftData.projectId !== undefined) {
            console.log("📋 Restoring WorkItemSelector from draft...");
            
            var accountId = normalizeIdForRestore(draftData.accountId);
            var projectId = normalizeIdForRestore(draftData.projectId);
            var subprojectId = normalizeIdForRestore(draftData.subprojectId);
            var taskId = normalizeIdForRestore(draftData.taskId);
            var subtaskId = normalizeIdForRestore(draftData.subtaskId);
            var assigneeId = normalizeIdForRestore(draftData.assigneeId);
            
            console.log("📋 Draft IDs - account:", accountId, "project:", projectId, "subproject:", subprojectId, "task:", taskId, "assignee:", assigneeId);
            
            // Only restore if we have valid IDs (at least account or project)
            if (accountId > 0 || projectId > 0) {
                // Use deferred loading to restore all selections
                workItem.deferredLoadExistingRecordSet(accountId, projectId, subprojectId, taskId, subtaskId, assigneeId);
                
                // If using multiple assignees, restore them after deferred loading completes
                if (workItem.enableMultipleAssignees && draftData.multipleAssignees) {
                    Qt.callLater(function() {
                        workItem.setMultipleAssignees(draftData.multipleAssignees);
                    });
                }
                
                // Reload stages if project was selected, then restore the stage from draft
                if (projectId > 0 && accountId > 0) {
                    // Save the stage values from draft before loading
                    var savedStageId = draftData.selectedStageOdooRecordId;
                    var savedPersonalStageId = draftData.selectedPersonalStageOdooRecordId;
                    
                    Qt.callLater(function() {
                        loadStagesForProject(projectId, accountId);
                        
                        // Restore the stage from draft AFTER stages are loaded
                        // Use another Qt.callLater to ensure stages are fully loaded
                        Qt.callLater(function() {
                            if (savedStageId !== undefined && savedStageId !== null) {
                                console.log("🔄 Restoring draft stage:", savedStageId, "after stage loading");
                                selectedStageOdooRecordId = savedStageId;
                                
                                // Also update the combobox selection
                                for (var i = 0; i < stageListModel.count; i++) {
                                    if (stageListModel.get(i).odoo_record_id === savedStageId) {
                                        stageComboBox.currentIndex = i;
                                        break;
                                    }
                                }
                            }
                            if (savedPersonalStageId !== undefined) {
                                console.log("🔄 Restoring draft personal stage:", savedPersonalStageId, "after stage loading");
                                selectedPersonalStageOdooRecordId = savedPersonalStageId;
                            }
                            
                            // Clear the restoration flag after stage restoration is complete
                            Qt.callLater(function() {
                                isRestoringFromDraft = false;
                                console.log("✅ Draft restoration complete - tracking re-enabled");
                            });
                        });
                    });
                } else {
                    // No project selected, restore stages directly
                    if (draftData.selectedStageOdooRecordId !== undefined) {
                        selectedStageOdooRecordId = draftData.selectedStageOdooRecordId;
                    }
                    if (draftData.selectedPersonalStageOdooRecordId !== undefined) {
                        selectedPersonalStageOdooRecordId = draftData.selectedPersonalStageOdooRecordId;
                    }
                    
                    // Clear the restoration flag
                    Qt.callLater(function() {
                        isRestoringFromDraft = false;
                        console.log("✅ Draft restoration complete (no project) - tracking re-enabled");
                    });
                }
            } else {
                console.log("⚠️ Draft has no valid account/project IDs - skipping WorkItemSelector restoration");
                
                // Still restore stage selections even if no project
                if (draftData.selectedStageOdooRecordId !== undefined) {
                    selectedStageOdooRecordId = draftData.selectedStageOdooRecordId;
                }
                if (draftData.selectedPersonalStageOdooRecordId !== undefined) {
                    selectedPersonalStageOdooRecordId = draftData.selectedPersonalStageOdooRecordId;
                }
                
                // Clear the restoration flag
                Qt.callLater(function() {
                    isRestoringFromDraft = false;
                    console.log("✅ Draft restoration complete (no valid IDs) - tracking re-enabled");
                });
            }
        } else {
            // No WorkItemSelector data, but restore stages if present
            if (draftData.selectedStageOdooRecordId !== undefined) {
                selectedStageOdooRecordId = draftData.selectedStageOdooRecordId;
            }
            if (draftData.selectedPersonalStageOdooRecordId !== undefined) {
                selectedPersonalStageOdooRecordId = draftData.selectedPersonalStageOdooRecordId;
            }
            
            // Clear the restoration flag
            Qt.callLater(function() {
                isRestoringFromDraft = false;
                console.log("✅ Draft restoration complete (no WorkItemSelector) - tracking re-enabled");
            });
        }
    }
    
    function restoreFormToOriginal() {
        console.log("🔄 Restoring form to original values...");
        
        var originalData = draftHandler.originalData;
        if (originalData.name !== undefined) name_text.text = originalData.name;
        if (originalData.description !== undefined) description_text.setContent(originalData.description);
        if (originalData.plannedHours !== undefined) hours_input.text = originalData.plannedHours;
        if (originalData.priority !== undefined) priority = originalData.priority;
        
        if (originalData.startDate !== undefined || originalData.endDate !== undefined) {
            date_range_widget.setDateRange(
                originalData.startDate || "", 
                originalData.endDate || ""
            );
        }
        
        if (originalData.deadline !== undefined) {
            deadline_text.text = originalData.deadline;
        }
        
        // Restore WorkItemSelector to original selections
        // Helper function to convert null/undefined to -1 for WorkItemSelector
        function normalizeIdForRestore(value) {
            if (value === null || value === undefined) return -1;
            var num = parseInt(value);
            return isNaN(num) ? -1 : num;
        }
        
        if (originalData.accountId !== undefined || originalData.projectId !== undefined) {
            var accountId = normalizeIdForRestore(originalData.accountId);
            var projectId = normalizeIdForRestore(originalData.projectId);
            var subprojectId = normalizeIdForRestore(originalData.subprojectId);
            var taskId = normalizeIdForRestore(originalData.taskId);
            var subtaskId = normalizeIdForRestore(originalData.subtaskId);
            var assigneeId = normalizeIdForRestore(originalData.assigneeId);
            
            if (accountId > 0 || projectId > 0) {
                workItem.deferredLoadExistingRecordSet(accountId, projectId, subprojectId, taskId, subtaskId, assigneeId);
                
                if (workItem.enableMultipleAssignees && originalData.multipleAssignees) {
                    Qt.callLater(function() {
                        workItem.setMultipleAssignees(originalData.multipleAssignees);
                    });
                }
            }
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
        const ids = workItem.getIds();
        
        // NOTE: WorkItemSelector.getIds() returns null for "not selected" (not -1)
        // We keep null values as-is for consistency with WorkItemSelector
        var formData = {
            name: name_text.text,
            description: description_text.getFormattedText ? description_text.getFormattedText() : description_text.text,
            plannedHours: hours_input.text,
            priority: priority,
            startDate: date_range_widget.formattedStartDate ? date_range_widget.formattedStartDate() : "",
            endDate: date_range_widget.formattedEndDate ? date_range_widget.formattedEndDate() : "",
            deadline: deadline_text.text,
            accountId: ids.account_id,        // null or number
            projectId: ids.project_id,         // null or number
            subprojectId: ids.subproject_id,   // null or number
            taskId: ids.task_id,               // null or number
            subtaskId: ids.subtask_id,         // null or number
            selectedStageOdooRecordId: selectedStageOdooRecordId,
            selectedPersonalStageOdooRecordId: selectedPersonalStageOdooRecordId
        };
        
        // Include assignee data based on mode
        if (workItem.enableMultipleAssignees) {
            formData.multipleAssignees = ids.multiple_assignees || [];
            formData.assigneeIds = ids.assignee_ids || [];
        } else {
            formData.assigneeId = ids.assignee_id;  // null or number
        }
        
        return formData;
    }

    function switchToEditMode() {
        // Simply change the current page to edit mode
        if (recordid !== 0) {
            isReadOnly = false;
            
            // Initialize draft handler when switching from read-only to edit mode
            // This ensures drafts are loaded if they exist
            var originalTaskData = getCurrentFormData();
            draftHandler.initialize(originalTaskData);
        }
    }

    function validateHoursInput(text) {
        // Allow formats like: 1, 1.5, 1:30, 01:30
        var timeRegex = /^(\d{1,3}):([0-5]\d)$/; // HH:MM or H:MM format
        var decimalRegex = /^\d+(\.\d+)?$/; // Decimal format like 1.5

        if (timeRegex.test(text)) {
            var match = text.match(timeRegex);
            var hours = parseInt(match[1]);
            var minutes = parseInt(match[2]);
            return hours >= 0 && hours <= 999 && minutes >= 0 && minutes <= 59;
        } else if (decimalRegex.test(text)) {
            var value = parseFloat(text);
            return value >= 0 && value <= 999;
        }
        return false;
    }
    function formatHoursDisplay(text) {
        // Convert various input formats to HH:MM display format
        var timeRegex = /^(\d{1,3}):([0-5]\d)$/;
        var decimalRegex = /^\d+(\.\d+)?$/;

        if (timeRegex.test(text)) {
            // Already in HH:MM format, just pad if needed
            var match = text.match(timeRegex);
            var hours = parseInt(match[1]);
            var minutes = parseInt(match[2]);
            return (hours < 10 ? "0" + hours : hours) + ":" + (minutes < 10 ? "0" + minutes : minutes);
        } else if (decimalRegex.test(text)) {
            // Convert decimal to HH:MM
            return Utils.convertDecimalHoursToHHMM(parseFloat(text));
        }
        return text;
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
        if (hours_input.text !== "" && !validateHoursInput(hours_input.text)) {
            notifPopup.open("Error", "Please enter valid hours (e.g., 1.5, 2:30, or 8:00)", "error");
            return false;
        }

        if (name_text.text != "") {
            const saveData = {
                accountId: ids.account_id < 0 ? 0 : ids.account_id,
                name: name_text.text,
                record_id: recordid,
                projectId: ids.project_id,
                subProjectId: ids.subproject_id,
                parentId: ids.task_id,
                startDate: date_range_widget.formattedStartDate(),
                endDate: date_range_widget.formattedEndDate(),
                deadline: deadline_text.text !== "Not set" ? deadline_text.text : "",
                priority: (priority != null ? priority.toString() : "0"),
                plannedHours: Utils.convertDurationToFloat(hours_input.text),
                description: description_text.text,
                assigneeUserId: ids.assignee_id,
                status: "updated"
            };

            // Add stage for BOTH creation and edit modes
            var stageToAssign = selectedStageOdooRecordId;

            // For creation mode: fallback to first stage if no stage selected
            if (recordid === 0 && stageToAssign <= 0 && stageListModel.count > 0) {
                var firstStage = stageListModel.get(0);
                stageToAssign = firstStage.odoo_record_id;
                console.log("Using fallback stage:", firstStage.name, "with odoo_record_id:", stageToAssign);
            }

            // Include stage in saveData (for both creation and edit)
            if (stageToAssign > 0) {
                saveData.stageOdooRecordId = stageToAssign;
                console.log("Saving task with stage:", stageToAssign, "mode:", recordid === 0 ? "create" : "edit");
            } else if (recordid !== 0) {
                // For edit mode with no valid stage, preserve the existing stage (don't reset to null)
                console.log("Edit mode: No stage change, preserving existing stage");
            }

            // Include personal stage in saveData (for both creation and edit)
            if (selectedPersonalStageOdooRecordId !== undefined && selectedPersonalStageOdooRecordId !== null) {
                if (selectedPersonalStageOdooRecordId > 0) {
                    saveData.personalStageOdooRecordId = selectedPersonalStageOdooRecordId;
                    console.log("Saving task with personal stage:", selectedPersonalStageOdooRecordId, "mode:", recordid === 0 ? "create" : "edit");
                } else {
                    // Explicitly set null for "No Stage" (0 or negative values)
                    saveData.personalStageOdooRecordId = null;
                    console.log("Saving task with no personal stage (null)");
                }
            } else if (recordid !== 0) {
                // For edit mode with undefined personal stage, preserve existing (don't include in saveData)
                console.log("Edit mode: No personal stage change, preserving existing personal stage");
            }

            // Add multiple assignees if enabled
            if (workItem.enableMultipleAssignees && ids.multiple_assignees) {
                saveData.multipleAssignees = ids.multiple_assignees;
            }

            const result = Task.saveOrUpdateTask(saveData);
            if (!result.success) {
                notifPopup.open("Error", "Unable to Save the Task", "error");
                return false;
            } else {
                notifPopup.open("Saved", "Task has been saved successfully", "success");
                
                // Clear draft after successful save
                draftHandler.clearDraft();
                
                // Format the hours display after successful save
                if (hours_input.text !== "") {
                    hours_input.text = formatHoursDisplay(hours_input.text);
                }
                
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

    //  isReadOnly = true; // Switch back to read-only mode after saving
    }

    function incdecHrs(value) {
        var currentText = hours_input.text || "0:00";
        var currentFloat = Utils.convertDurationToFloat(currentText);

        if (value === 1) {
            currentFloat += 1.0;
        } else {
            if (currentFloat >= 1.0) {
                currentFloat -= 1.0;
            }
        }

        hours_input.text = Utils.convertDecimalHoursToHHMM(currentFloat);
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
        console.log("Loading stages for project:", projectOdooRecordId, "account:", accountId);

        if (projectOdooRecordId <= 0 || accountId <= 0) {
            stageListModel.clear();
            stageComboBox.currentIndex = -1;
            selectedStageOdooRecordId = -1;
            return;
        }

        var stages = Task.getTaskStagesForProject(projectOdooRecordId, accountId);
        stageListModel.clear();

        for (var i = 0; i < stages.length; i++) {
            stageListModel.append({
                odoo_record_id: stages[i].odoo_record_id,
                name: stages[i].name,
                sequence: stages[i].sequence,
                fold: stages[i].fold
            });
        }

        // Automatically select first stage as default (user can change it)
        if (stageListModel.count > 0) {
            stageComboBox.currentIndex = 0;
            var firstStage = stageListModel.get(0);
            selectedStageOdooRecordId = firstStage.odoo_record_id;
            console.log("Auto-selected first stage as default:", firstStage.name, "with odoo_record_id:", firstStage.odoo_record_id);
        } else {
            stageComboBox.currentIndex = -1;
            selectedStageOdooRecordId = -1;
            console.warn("No stages available for project", projectOdooRecordId);
        }

        console.log("Loaded", stageListModel.count, "stages for project");
    }

    Flickable {
        id: tasksDetailsPageFlickable
        anchors.topMargin: units.gu(6)
        anchors.fill: parent
        contentHeight: descriptionExpanded ? parent.height + units.gu(150) : parent.height + units.gu(120)
        flickableDirection: Flickable.VerticalFlick

        width: parent.width

        Row {
            id: myRow1a
            anchors.left: parent.left
            topPadding: units.gu(5)
            z: 999
            Column {
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
                    height: units.gu(10)

                    // Handle multi-assignee changes (for enableMultipleAssignees mode)
                    onMultiAssigneesChanged: {
                        
                        
                        if (draftHandler.enabled && draftHandler._initialized) {
                            var idsForDraft = workItem.getIds();
                         
                            draftHandler.markFieldChanged("multipleAssignees", idsForDraft.multiple_assignees);
                            draftHandler.markFieldChanged("assigneeIds", idsForDraft.assignee_ids);
                            
                        } else {
                            console.log("⏸️ Multi-assignee draft tracking skipped - enabled:", draftHandler.enabled, "initialized:", draftHandler._initialized);
                        }
                    }

                    // Monitor project and account changes to reload stages
                    onStateChanged: {
                        console.log("🔔 WorkItemSelector state changed to:", newState, "data:", JSON.stringify(data));

                        // Track changes for draft management (for all modes)
                        if (draftHandler.enabled && draftHandler._initialized) {
                            // Get current IDs - but note that component.selectedId may not be updated yet
                            // So we need to get the REAL current state by querying the properties
                            var idsForDraft = workItem.getIds();
                            
                            // Update the specific field that just changed based on the state
                            // This ensures we track the actual change even if getIds() hasn't updated yet
                            var changedId = data.id || null;
                            
                            console.log("📝 Tracking WorkItemSelector changes:", JSON.stringify({
                                state: newState,
                                changedId: changedId,
                                currentIds: {
                                    account: idsForDraft.account_id,
                                    project: idsForDraft.project_id,
                                    subproject: idsForDraft.subproject_id,
                                    task: idsForDraft.task_id,
                                    subtask: idsForDraft.subtask_id,
                                    assignee: idsForDraft.assignee_id
                                }
                            }));
                            
                            // Track the field that actually changed
                            if (newState === "AccountSelected") {
                                console.log("✅ Tracking accountId:", changedId);
                                draftHandler.markFieldChanged("accountId", changedId);
                            } else if (newState === "ProjectSelected") {
                                console.log("✅ Tracking projectId:", changedId);
                                draftHandler.markFieldChanged("projectId", changedId);
                            } else if (newState === "SubprojectSelected") {
                                console.log("✅ Tracking subprojectId:", changedId);
                                draftHandler.markFieldChanged("subprojectId", changedId);
                            } else if (newState === "TaskSelected") {
                                console.log("✅ Tracking taskId (Parent Task):", changedId);
                                draftHandler.markFieldChanged("taskId", changedId);
                            } else if (newState === "SubtaskSelected") {
                                console.log("✅ Tracking subtaskId:", changedId);
                                draftHandler.markFieldChanged("subtaskId", changedId);
                            } else if (newState === "AssigneeSelected") {
                                // For assignees, also check if using multi-assignee mode
                                if (workItem.enableMultipleAssignees) {
                                    console.log("✅ Tracking multipleAssignees:", idsForDraft.assignee_ids);
                                    draftHandler.markFieldChanged("multipleAssignees", idsForDraft.multiple_assignees);
                                    draftHandler.markFieldChanged("assigneeIds", idsForDraft.assignee_ids);
                                } else {
                                    console.log("✅ Tracking assigneeId:", changedId);
                                    draftHandler.markFieldChanged("assigneeId", changedId);
                                }
                            } else {
                                console.warn("⚠️ Unknown state - not tracking:", newState);
                            }
                            
                            console.log("📊 Draft status - hasUnsavedChanges:", draftHandler.hasUnsavedChanges, "changedFields:", draftHandler.changedFields.length);
                        } else {
                            console.log("⏸️ Draft tracking skipped - enabled:", draftHandler.enabled, "initialized:", draftHandler._initialized);
                        }

                        if (recordid === 0) {
                            // Only in creation mode
                            // Reload stages when account or project is selected
                            if (newState === "ProjectSelected") {
                                // Use getIds() to get the most current IDs
                                var ids = workItem.getIds();
                                var projectId = data.id;
                                var accountId = ids.account_id;

                                console.log("📋 ProjectSelected - projectId:", projectId, "accountId:", accountId, "(from getIds)");

                                if (projectId > 0 && accountId > 0) {
                                    console.log("✅ Loading stages for project:", projectId, "account:", accountId);
                                    loadStagesForProject(projectId, accountId);
                                } else {
                                    console.log("❌ Cannot load stages - invalid IDs (projectId:", projectId, "accountId:", accountId, ")");
                                }
                            } else if (newState === "SubprojectSelected") {
                                // For subproject, we still use the main project to get stages
                                var ids2 = workItem.getIds();
                                console.log("📋 SubprojectSelected - project_id:", ids2.project_id, "account_id:", ids2.account_id);

                                if (ids2.project_id > 0 && ids2.account_id > 0) {
                                    console.log("✅ Loading stages for subproject's parent project:", ids2.project_id, "account:", ids2.account_id);
                                    loadStagesForProject(ids2.project_id, ids2.account_id);
                                } else {
                                    console.log("❌ Cannot load stages - invalid IDs for subproject");
                                }
                            } else if (newState === "AccountSelected") {
                                // When account changes, clear the stage list
                                console.log("🗑️ Account changed - clearing stages");
                                stageListModel.clear();
                                stageComboBox.currentIndex = -1;
                                selectedStageOdooRecordId = -1;
                            }
                        }
                    }
                }
            }
        }
        Row {
            id: myRow1b
            anchors.top: myRow1a.bottom
            anchors.left: parent.left
            topPadding: units.gu(35)
            Column {
                id: myCol88
                leftPadding: units.gu(1)
                LomiriShape {
                    width: units.gu(10)
                    height: units.gu(5)
                    aspect: LomiriShape.Flat
                    Label {
                        id: name_label
                        text: i18n.dtr("ubtms", "Name")
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
            Column {
                id: myCol99
                leftPadding: units.gu(3)
                TextField {
                    id: name_text
                    readOnly: isReadOnly
                    width: tasksDetailsPageFlickable.width < units.gu(361) ? tasksDetailsPageFlickable.width - units.gu(15) : tasksDetailsPageFlickable.width - units.gu(10)
                    anchors.centerIn: parent.centerIn
                    text: ""
                    
                    onTextChanged: {
                        if (draftHandler.enabled) {
                            draftHandler.markFieldChanged("name", text);
                        }
                    }

                    Rectangle {
                        //  visible: !isReadOnly
                        anchors.fill: parent
                        color: "transparent"
                        radius: units.gu(0.5)
                        border.width: parent.activeFocus ? units.gu(0.2) : units.gu(0.1)
                        border.color: parent.activeFocus ? LomiriColors.orange : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#d3d1d1" : "#999")
                        // z: -1
                    }
                }
            }
        }
        Row {
            id: add_timesheet
            anchors.top: myRow1b.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: units.gu(1)
            visible: false
        }
        // Priority Selector Row
        Row {
            id: priorityRow
            anchors.top: (recordid > 0) ? add_timesheet.bottom : myRow1b.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: units.gu(6)
            spacing: units.gu(2)

            Column {
                width: units.gu(15)
                height: parent.height

                LomiriShape {
                    width: units.gu(15)
                    height: units.gu(5)
                    aspect: LomiriShape.Flat
                    Label {
                        text: i18n.dtr("ubtms", "Priority")
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Column {
                leftPadding: units.gu(3)
                height: parent.height

                Row {
                    spacing: units.gu(2)
                    height: units.gu(5)

                    Repeater {
                        model: 3 // For 3 stars (priority 1-3, with 0 = no stars)

                        Image {
                            id: priorityStar
                            property int starIndex: index
                            source: ((index + 1) <= taskCreate.priority) ? "../qml/images/star.png" : "../qml/images/star-inactive.png"
                            width: units.gu(3.5)
                            height: units.gu(3.5)
                            opacity: isReadOnly ? 0.7 : 1.0

                            MouseArea {
                                anchors.fill: parent
                                enabled: !isReadOnly
                                onClicked: {
                                    // 3-star system: clicking star sets that priority level, clicking same level sets to 0
                                    var clickedPriority = index + 1;
                                    var newPriority = (clickedPriority === taskCreate.priority) ? 0 : clickedPriority;
                                    taskCreate.priority = newPriority;
                                }
                            }
                        }
                    }

                    // Show the numeric value
                    Label {
                        text: "(Level: " + taskCreate.priority + ")"
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: units.gu(1.5)
                        visible: taskCreate.priority > 0
                    }
                }
            }
        }

        // Stage Selector Row (for creation mode only) - Auto-assigns first stage as fallback
        Row {
            id: stageRow
            anchors.top: priorityRow.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: units.gu(1)
            anchors.rightMargin: units.gu(1)
            height: units.gu(6)
            spacing: units.gu(2)
            topPadding: units.gu(1)
            visible: recordid === 0 // Only show when creating new task

            TSLabel {
                text: i18n.dtr("ubtms", "Initial Stage")
                width: parent.width * 0.25
                anchors.verticalCenter: parent.verticalCenter
            }

            ComboBox {
                id: stageComboBox
                width: parent.width * 0.65
                height: units.gu(5)
                anchors.verticalCenter: parent.verticalCenter
                enabled: !isReadOnly
                displayText: currentIndex >= 0 ? model.get(currentIndex).name : "Select Stage"

                model: ListModel {
                    id: stageListModel
                }

                delegate: ItemDelegate {
                    width: stageComboBox.width
                    contentItem: Text {
                        text: model.name
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                        font: stageComboBox.font
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }
                    highlighted: stageComboBox.highlightedIndex === index
                }

                onCurrentIndexChanged: {
                    if (currentIndex >= 0) {
                        var stage = stageListModel.get(currentIndex);
                        taskCreate.selectedStageOdooRecordId = stage.odoo_record_id;
                        console.log("User selected stage:", stage.name, "with odoo_record_id:", stage.odoo_record_id);
                    }
                }
            }
        }

        Row {
            id: myRow9
            anchors.top: (recordid === 0) ? stageRow.bottom : priorityRow.bottom
            anchors.left: parent.left
            anchors.right: parent.right
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
                            Global.description_temporary_holder = getFormattedText();
                            apLayout.addPageToNextColumn(taskCreate, Qt.resolvedUrl("ReadMorePage.qml"), {
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
        Grid {
            id: currentStageRow
            visible: recordid !== 0
            anchors.top: myRow9.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: units.gu(1)
            anchors.rightMargin: units.gu(1)
            anchors.topMargin: units.gu(1)
            columns: 3
            rows: 3
            spacing: units.gu(1)
            rowSpacing: units.gu(1)
            columnSpacing: units.gu(1)

            // Row 1: Current Stage
            TSLabel {
                text: i18n.dtr("ubtms", "Current Stage:")
                width: (parent.width - (2 * parent.columnSpacing)) / 3
                height: units.gu(6)
                horizontalAlignment: Text.AlignHLeft
                verticalAlignment: Text.AlignVCenter
                fontBold: true
                color: "#f97316"
            }

            TSLabel {
                text: currentTask && currentTask.state ? Task.getTaskStageName(currentTask.state, currentTask.account_id) : i18n.dtr("ubtms", "Not set")
                width: (parent.width - (2 * parent.columnSpacing)) / 3
                height: units.gu(6)
                fontBold: true
                color: {
                    if (!currentTask || !currentTask.state) {
                        return theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#888" : "#666";
                    }
                    var stageName = Task.getTaskStageName(currentTask.state, currentTask.account_id).toLowerCase();
                    if (stageName === "completed" || stageName === "finished" || stageName === "closed" || stageName === "verified" || stageName === "done") {
                        return "green";
                    }
                    return "#f97316";
                }
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            TSButton {
                visible: recordid !== 0
                bgColor: "#f3f4f6"
                fgColor: "#1f2937"
                hoverColor: '#d1d5db'
                borderColor: "#d1d5db"
                fontBold: true
                iconName: "filters"
                iconColor: "#1f2937"
                width: (parent.width - (2 * parent.columnSpacing)) / 3
                height: units.gu(6)
                text: i18n.dtr("ubtms", "Change")
                onClicked: {
                    if (!currentTask || !currentTask.id) {
                        notifPopup.open("Error", "Task data not available", "error");
                        return;
                    }

                    var dialog = PopupUtils.open(taskStageSelector, taskCreate, {
                        taskId: currentTask.id,
                        projectOdooRecordId: currentTask.project_id,
                        accountId: currentTask.account_id,
                        currentStageOdooRecordId: currentTask.state || -1
                    });
                }
            }

            // Row 2: Activities
            TSLabel {
                text: i18n.dtr("ubtms", "Activities")
                width: (parent.width - (2 * parent.columnSpacing)) / 3
                height: units.gu(6)
                horizontalAlignment: Text.AlignHLeft
                verticalAlignment: Text.AlignVCenter
                fontBold: true
                color: "#f97316"
            }

            TSButton {
                visible: recordid !== 0
                bgColor: "#fef1e7"
                fgColor: "#f97316"
                hoverColor: '#f3e0d1'
                iconName: "add"
                iconColor: "#f97316"
                fontBold: true
                width: (parent.width - (2 * parent.columnSpacing)) / 3
                height: units.gu(6)
                text: i18n.dtr("ubtms", "Create")
                onClicked: {
                    let result = Activity.createActivityFromProjectOrTask(false, currentTask.account_id, currentTask.odoo_record_id);
                    if (result.success) {
                        apLayout.addPageToNextColumn(taskCreate, Qt.resolvedUrl("Activities.qml"), {
                            "recordid": result.record_id,
                            "accountid": currentTask.account_id,
                            "isReadOnly": false
                        });
                    } else {
                        notifPopup.open("Failed", "Unable to create activity", "error");
                    }
                }
            }

              TSButton {
                visible: recordid !== 0
                bgColor: "#f3f4f6"
                fgColor: "#1f2937"
                hoverColor: '#d1d5db'
                borderColor: "#d1d5db"
                fontBold: true
                iconName: "filters"
                iconColor: "#1f2937"
                width: (parent.width - (2 * parent.columnSpacing)) / 3
                height: units.gu(6)
                text: i18n.dtr("ubtms", "View")
                onClicked: {
                    console.log("Viewing activities for task:", currentTask.id, "odoo_record_id:", currentTask.odoo_record_id);
                    apLayout.addPageToNextColumn(taskCreate, Qt.resolvedUrl("Activity_Page.qml"), {
                        "filterByTasks": true,
                        "taskOdooRecordId": currentTask.odoo_record_id,
                        "projectAccountId": currentTask.account_id,
                        "projectName": currentTask.name || "Task"
                    });
                }
            }


               // Row 3: Timesheets
            TSLabel {
                text: i18n.dtr("ubtms", "Timesheets")
                width: (parent.width - (2 * parent.columnSpacing)) / 3
                height: units.gu(6)
                horizontalAlignment: Text.AlignHLeft
                verticalAlignment: Text.AlignVCenter
                fontBold: true
                color: "#f97316"
            }

            TSButton {
                visible: recordid !== 0
                bgColor: "#fef1e7"
                fgColor: "#f97316"
                hoverColor: '#f3e0d1'
                iconName: "add"
                iconColor: "#f97316"
                fontBold: true
                width: (parent.width - (2 * parent.columnSpacing)) / 3
                height: units.gu(6)
                text: i18n.dtr("ubtms", "Create")
                onClicked: {
                    // createTimesheetFromTask expects only the task's odoo_record_id
                    const result = Timesheet.createTimesheetFromTask(currentTask.odoo_record_id);
                    if (result.success) {
                        apLayout.addPageToNextColumn(taskCreate, Qt.resolvedUrl("Timesheet.qml"), {
                            "recordid": result.id,
                            "isReadOnly": false
                        });
                    } else {
                        console.error("Error creating timesheet:", result.error);
                        notifPopup.open("Error", "Unable to create timesheet: " + result.error, "error");
                    }
                }
            }

              TSButton {
                visible: recordid !== 0
                bgColor: "#f3f4f6"
                fgColor: "#1f2937"
                hoverColor: '#d1d5db'
                borderColor: "#d1d5db"
                fontBold: true
                iconName: "filters"
                iconColor: "#1f2937"
                width: (parent.width - (2 * parent.columnSpacing)) / 3
                height: units.gu(6)
                text: i18n.dtr("ubtms", "View")
                onClicked: {
                    console.log("Viewing timesheets for task:", currentTask.id, "odoo_record_id:", currentTask.odoo_record_id);
                    apLayout.addPageToNextColumn(taskCreate, Qt.resolvedUrl("Timesheet_Page.qml"), {
                        "filterByTask": true,
                        "taskOdooRecordId": currentTask.odoo_record_id,
                        "taskAccountId": currentTask.account_id,
                        "taskName": currentTask.name || "Task"
                    });
                }
            }



        }

        // Row {
        //     id: currentPersonalStageRow
        //     visible: recordid !== 0
        //     anchors.top: currentStageRow.bottom
        //     anchors.left: parent.left
        //     anchors.right: parent.right
        //     anchors.leftMargin: units.gu(1)
        //     anchors.rightMargin: units.gu(1)
        //     topPadding: units.gu(1)

        //     TSLabel {
        //         text: "Personal Stage:"
        //         width: parent.width * 0.25
        //         anchors.verticalCenter: parent.verticalCenter
        //     }

        //     Label {
        //         text: {
        //             if (!currentTask || !currentTask.personal_stage || currentTask.personal_stage === -1) {
        //                 return "(Not set)";
        //             }
        //             return Task.getTaskStageName(currentTask.personal_stage);
        //         }
        //         width: parent.width * 0.75
        //         font.pixelSize: units.gu(2)
        //         font.bold: currentTask && currentTask.personal_stage && currentTask.personal_stage !== -1
        //         font.italic: !currentTask || !currentTask.personal_stage || currentTask.personal_stage === -1
        //         color: {
        //             if (!currentTask || !currentTask.personal_stage || currentTask.personal_stage === -1) {
        //                 return theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#888" : "#666";
        //             }
        //             return LomiriColors.blue;
        //         }
        //         anchors.verticalCenter: parent.verticalCenter
        //         wrapMode: Text.WordWrap
        //     }
        // }

        // Row {
        //     id: myRow83
        //     anchors.top: myRow82.bottom
        //     anchors.left: parent.left
        //     anchors.right: parent.right
        //     anchors.leftMargin: units.gu(1)
        //     anchors.rightMargin: units.gu(1)
        //     spacing: units.gu(1)
        //     topPadding: units.gu(1)

        //     TSButton {
        //         visible: recordid !== 0
        //         width: parent.width
        //         text: "Change Personal Stage"
        //         fgColor: LomiriColors.blue
        //         onClicked: {
        //             if (!currentTask || !currentTask.id) {
        //                 notifPopup.open("Error", "Task data not available", "error");
        //                 return;
        //             }

        //             var userId = Accounts.getCurrentUserOdooId(currentTask.account_id);
        //             if (userId <= 0) {
        //                 notifPopup.open("Error", "Unable to determine current user", "error");
        //                 return;
        //             }

        //             // Open the personal stage selector dialog with parameters
        //             var dialog = PopupUtils.open(personalStageSelector, taskCreate, {
        //                 taskId: currentTask.id,
        //                 accountId: currentTask.account_id,
        //                 userId: userId,
        //                 currentPersonalStageOdooRecordId: currentTask.personal_stage || -1
        //             });
        //         }
        //     }
        // }

        Row {
            id: plannedh_row
            anchors.top: currentStageRow.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: units.gu(1)
            anchors.rightMargin: units.gu(1)
            spacing: units.gu(2)
            topPadding: units.gu(1)

            TSLabel {
                id: hours_label
                text: i18n.dtr("ubtms", "Planned Hours")
                width: parent.width * 0.25
                anchors.verticalCenter: parent.verticalCenter
            }

            TextField {
                id: hours_input
                readOnly: isReadOnly
                width: parent.width * 0.3
                height: units.gu(5)
                anchors.verticalCenter: parent.verticalCenter
                text: "01:00"
                placeholderText: i18n.dtr("ubtms", "e.g., 2:30 or 1.5")
                
                onTextChanged: {
                    if (draftHandler.enabled) {
                        draftHandler.markFieldChanged("plannedHours", text);
                    }
                }

                // Input validation
                validator: RegExpValidator {
                    regExp: /^(\d{1,3}(:\d{2})?|\d+(\.\d+)?)$/
                }

                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    radius: units.gu(0.5)
                    border.width: parent.activeFocus ? units.gu(0.2) : units.gu(0.1)
                    border.color: parent.activeFocus ? LomiriColors.orange : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#d3d1d1" : "#999")
                }

                onFocusChanged: {
                    if (!focus && text !== "" && validateHoursInput(text)) {
                        text = formatHoursDisplay(text);
                    }
                }

                Keys.onReturnPressed: {
                    if (text !== "" && validateHoursInput(text)) {
                        text = formatHoursDisplay(text);
                    }
                    focus = false;
                }
            }

            Row {
                spacing: units.gu(1)
                width: parent.width * 0.3
                anchors.verticalCenter: parent.verticalCenter

                visible: !isReadOnly

                TSButton {
                    text: "-"
                    enabled: !isReadOnly
                    fontSize: units.gu(2.5)
                    width: units.gu(4.5)
                    height: units.gu(4.5)
                    onClicked: {
                        incdecHrs(-1);
                    }
                }

                TSButton {
                    text: "+"
                    enabled: !isReadOnly
                    fontSize: units.gu(2.5)
                    width: units.gu(4.5)
                    height: units.gu(4.5)
                    onClicked: {
                        incdecHrs(1);
                    }
                }
            }
        }

        Row {
            id: myRow6
            anchors.top: plannedh_row.bottom
            anchors.left: parent.left
            topPadding: units.gu(1)
            height: units.gu(30)
            Column {
                leftPadding: units.gu(1)
                DateRangeSelector {
                    id: date_range_widget
                    readOnly: isReadOnly
                    width: tasksDetailsPageFlickable.width < units.gu(361) ? tasksDetailsPageFlickable.width - units.gu(35) : tasksDetailsPageFlickable.width - units.gu(30)
                    height: units.gu(4)
                    anchors.centerIn: parent.centerIn
                    
                    onRangeChanged: {
                        if (draftHandler.enabled && draftHandler._initialized) {
                            draftHandler.markFieldChanged("startDate", formattedStartDate());
                            draftHandler.markFieldChanged("endDate", formattedEndDate());
                        }
                    }
                }
            }
        }

        Row {
            id: deadlineRow
            anchors.top: myRow6.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: units.gu(1)
            anchors.rightMargin: units.gu(1)
            spacing: units.gu(2)
            topPadding: units.gu(1)

            TSLabel {
                id: deadline_label
                text: i18n.dtr("ubtms", "Deadline")
                width: parent.width * 0.3
                anchors.verticalCenter: parent.verticalCenter
            }

            TSLabel {
                id: deadline_text
                text: i18n.dtr("ubtms", "Not set")
                enabled: !isReadOnly
                width: parent.width * 0.4
                fontBold: true
                anchors.verticalCenter: parent.verticalCenter
            }

            TSButton {
                text: i18n.dtr("ubtms", "Select")
                objectName: "button_deadline"
                enabled: !isReadOnly
                width: parent.width * 0.2
                height: units.gu(5)
                anchors.verticalCenter: parent.verticalCenter

                onClicked: {
                    deadlinePicker.open();
                }
            }
        }
        Rectangle {
            //color:"yellow"
            id: attachmentRow
            anchors.top: deadlineRow.bottom
            //anchors.top: attachmentuploadRow.bottom
            height: units.gu(50)
            width: parent.width
            anchors.margins: units.gu(0.1)
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
    }
    

    CustomDatePicker {
        id: deadlinePicker
        titleText: i18n.dtr("ubtms", "Select Deadline")

        onDateSelected: {
            deadline_text.text = Qt.formatDate(new Date(date), "yyyy-MM-dd");
            
            // Track deadline change for draft
            if (draftHandler.enabled) {
                draftHandler.markFieldChanged("deadline", deadline_text.text);
            }
        }
    }

    function loadTask() {
        if (recordid != 0) // We are loading a task, depends on readonly value it could be for view/edit
        {
            currentTask = Task.getTaskDetails(recordid);

            let instanceId = (currentTask.account_id !== undefined && currentTask.account_id !== null) ? currentTask.account_id : -1;
            let project_id = (currentTask.project_id !== undefined && currentTask.project_id !== null && currentTask.project_id > 0) ? currentTask.project_id : -1;
            let sub_project_id = (currentTask.sub_project_id !== undefined && currentTask.sub_project_id !== null) ? currentTask.sub_project_id : -1;
            let parent_task_id = (currentTask.parent_id !== undefined && currentTask.parent_id !== null) ? currentTask.parent_id : -1;

            // Handle assignee_id - extract first ID if comma-separated (for single assignee mode)
            let assignee_id = -1;
            if (currentTask.user_id !== undefined && currentTask.user_id !== null && currentTask.user_id !== "") {
                let userIdStr = currentTask.user_id.toString();
                if (userIdStr.indexOf(', ') >= 0) {
                    // Multiple assignees stored as comma-separated - take the first one for single assignee mode
                    let firstId = parseInt(userIdStr.split(', ')[0].trim());
                    assignee_id = isNaN(firstId) ? -1 : firstId;
                } else {
                    // Single assignee
                    let singleId = parseInt(userIdStr);
                    assignee_id = isNaN(singleId) ? -1 : singleId;
                }
            }

            workItem.deferredLoadExistingRecordSet(instanceId, project_id, sub_project_id, parent_task_id, -1, assignee_id); //passing -1 as no subtask feature is needed

            name_text.text = currentTask.name || "";
            description_text.setContent(currentTask.description || "");

            // Handle planned hours more carefully
            if (currentTask.initial_planned_hours !== undefined && currentTask.initial_planned_hours !== null && currentTask.initial_planned_hours > 0) {
                hours_input.text = Utils.convertDecimalHoursToHHMM(parseFloat(currentTask.initial_planned_hours));
            } else {
                hours_input.text = "01:00";  // Default value
            }

            // Set date range more carefully to preserve original dates
            if (currentTask.start_date && currentTask.end_date) {
                date_range_widget.setDateRange(currentTask.start_date, currentTask.end_date);
            } else if (currentTask.start_date) {
                date_range_widget.setDateRange(currentTask.start_date, null);
            } else if (currentTask.end_date) {
                date_range_widget.setDateRange(null, currentTask.end_date);
            }
            // If no dates are set, don't call setDateRange to avoid defaulting to today

            // Set deadline
            if (currentTask.deadline) {
                deadline_text.text = currentTask.deadline;
            } else {
                deadline_text.text = "Not set";
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

            // Load multiple assignees if enabled
            if (workItem.enableMultipleAssignees) {
                var existingAssignees = Task.getTaskAssignees(recordid, instanceId);
                workItem.setMultipleAssignees(existingAssignees);
            }

            attachments_widget.setAttachments(Task.getAttachmentsForTask(currentTask.odoo_record_id, currentTask.account_id));
        } else {
            // We are creating a new task
            workItem.loadAccounts();
            deadline_text.text = "Not set";

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
    //  console.log("currentTask loaded:", JSON.stringify(currentTask));
    
        // Mark form as fully initialized
        formFullyInitialized = true;
        
        // Initialize draft handler AFTER all form fields are populated
        if (!isReadOnly) {
            var originalTaskData = getCurrentFormData();
            draftHandler.initialize(originalTaskData);
        }
    }

    Component.onCompleted: {
        loadTask();
    }

    onVisibleChanged: {
        if (visible) {
            // Update navigation tracking when Tasks detail page becomes visible
            Global.setLastVisitedPage("Tasks");

            if (Global.description_temporary_holder !== "") {
                //Check if you are coming back from the ReadMore page
                description_text.setContent(Global.description_temporary_holder);
                Global.description_temporary_holder = "";
                
                // Track description change for draft
                if (draftHandler.enabled) {
                    draftHandler.markFieldChanged("description", description_text.getFormattedText());
                }
            }
        } else {
            Global.description_temporary_holder = "";
        }
        }
    }
