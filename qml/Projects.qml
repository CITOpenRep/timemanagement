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
import "../models/utils.js" as Utils
import "../models/accounts.js" as Accounts
import "../models/activity.js" as Activity
import "../models/project.js" as Project
import "../models/global.js" as Global
import "components"

Page {
    id: projectCreate
    title: i18n.dtr("ubtms", "Project")
    header: PageHeader {
        id: header
        title: projectCreate.title + (draftHandler.hasUnsavedChanges ? " •" : "")
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
                text: i18n.dtr("ubtms", "Save")
                visible: !isReadOnly
                onTriggered: {
                    const ids = workItem.getIds();

                    if (!ids.assignee_id) {
                        notifPopup.open("Error", "Please select the assignee", "error");
                        return;
                    }

                    // Validate hours format before saving
                    if (!hours_text.isValid) {
                        notifPopup.open("Error", "Please enter allocated hours in HH:MM format (e.g., 1000:30 for large projects)", "error");
                        return;
                    }

                    // isReadOnly = !isReadOnly
                    // Preserve existing favorites value when editing, default to 0 for new projects
                    var currentFavorites = (project && project.favorites !== undefined) ? project.favorites : 0;
                    
                    var project_data = {
                        'account_id': ids.account_id >= 0 ? ids.account_id : 0,
                        'name': project_name.text,
                        'planned_start_date': date_range_widget.formattedStartDate(),
                        'planned_end_date': date_range_widget.formattedEndDate(),
                        'parent_id': ids.project_id,
                        'allocated_hours': hours_text.text,
                        'description': description_text.text,
                        'favorites': currentFavorites,
                        'color': project_color,
                        'status': "updated",
                        'user_id': ids.assignee_id
                    };
                    //  console.log(JSON.stringify(project_data, null, 4));

                    // Use the current recordid (0 for new projects, existing ID for updates)
                    var response = Project.createUpdateProject(project_data, recordid);
                    if (response) {
                        if (response.is_success) {
                            notifPopup.open("Saved", response.message, "success");

                            // Update recordid if it was a new project creation
                            if (recordid === 0 && response.record_id) {
                                recordid = response.record_id;
                            }

                            // Reload the project data to reflect the saved state
                            if (recordid !== 0) {
                                loadProjectData(recordid);
                            }
                            
                            // Clear draft after successful save
                            draftHandler.clearDraft();
                            
                            // Switch back to read-only mode after saving
                            isReadOnly = true;
                        } else {
                            notifPopup.open("Failed", response.message, "error");
                        }
                    } else {
                        notifPopup.open("Failed", "Unable to save project", "error");
                    }
                }
            },
            Action {
                iconName: "edit"
                visible: isReadOnly && recordid !== 0
                text: i18n.dtr("ubtms", "Edit")
                onTriggered: {
                    switchToEditMode();
                }
            },
            Action {
                iconName: "close"
                text: i18n.dtr("ubtms", "Close")
                visible: draftHandler.hasUnsavedChanges
                onTriggered: {
                    restoreFormToOriginal();
                    draftHandler.clearDraft();
                    Qt.callLater(navigateBack);
                }
            }
        ]
    }

    property bool isReadOnly: recordid != 0 // Set read-only immediately based on recordid
    property var recordid: 0
    property bool isOdooRecordId: false // If true, recordid is an odoo_record_id, not local id
    property int project_color: 0
    property var project: {}
    property bool descriptionExpanded: false
    property real expandedHeight: units.gu(60)
    
    // Track if we're navigating to ReadMorePage to avoid showing save dialog
    property bool navigatingToReadMore: false
    
    // Track if form is fully initialized (to defer draft restoration)
    property bool formFullyInitialized: false
    
    property bool isRestoringFromDraft: false

    onProject_colorChanged: {
        if (!isRestoringFromDraft) {
            draftHandler.markFieldChanged("color", project_color);
        }
    }

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
        draftType: "project"
        recordId: projectCreate.recordid
        accountId: (project && project.account_id) ? project.account_id : 0
        enabled: !isReadOnly
        autoSaveInterval: 300000 // 5 minutes
        
        onDraftLoaded: {
            // Only restore if form is fully initialized
            if (formFullyInitialized) {
                restoreFormFromDraft(draftData);
                notifPopup.open("📂 Draft Found", 
                    "Unsaved changes restored.", 
                    "info");
            } else {
                // Defer restoration until form is ready
                console.log("⏳ Deferring draft restoration until form is fully initialized...");
                Qt.callLater(function() {
                    if (formFullyInitialized) {
                        restoreFormFromDraft(draftData);
                        notifPopup.open("📂 Draft Restored", 
                            "Unsaved changes restored.", 
                            "info");
                    }
                });
            }
        }
        
        onUnsavedChangesWarning: {
            console.log("⚠️ Unsaved changes detected");
        }
        
        onDraftSaved: {
            console.log("💾 Draft saved successfully (ID: " + draftId + ")");
        }
    }

    SaveDiscardDialog {
        id: saveDiscardDialog
        onSaveRequested: {
            console.log("💾 SaveDiscardDialog: Saving project...");
            saveProjectData();
        }
        onDiscardRequested: {
            console.log("🗑️ SaveDiscardDialog: Discarding changes...");
            restoreFormToOriginal();
            draftHandler.clearDraft();
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
                apLayout.removePages(projectCreate);
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
        
        if (draftData.name) project_name.text = draftData.name;
        if (draftData.description) description_text.setContent(draftData.description);
        if (draftData.allocatedHours) hours_text.text = draftData.allocatedHours;
        if (draftData.color !== undefined) {
            project_color = draftData.color;
            project_color_label.color = colorpicker.getColorByIndex(draftData.color);
        }
        
        if (draftData.startDate || draftData.endDate) {
            date_range_widget.setDateRange(
                draftData.startDate || "", 
                draftData.endDate || ""
            );
        }
        
        // Restore WorkItemSelector selections
        function normalizeIdForRestore(value) {
            if (value === null || value === undefined) return -1;
            var num = parseInt(value);
            return isNaN(num) ? -1 : num;
        }
        
        if (draftData.accountId !== undefined || draftData.parentId !== undefined || draftData.assigneeId !== undefined) {
            var accountId = normalizeIdForRestore(draftData.accountId);
            var parentId = normalizeIdForRestore(draftData.parentId);
            var assigneeId = normalizeIdForRestore(draftData.assigneeId);
            
            workItem.deferredLoadExistingRecordSet(accountId, parentId, -1, -1, -1, assigneeId);
        }
        
        // Clear the restoration flag
        Qt.callLater(function() {
            isRestoringFromDraft = false;
            console.log("✅ Draft restoration complete - tracking re-enabled");
        });
    }
    
    function restoreFormToOriginal() {
        console.log("🔄 Restoring form to original values...");
        
        var originalData = draftHandler.originalData;
        if (originalData.name !== undefined) project_name.text = originalData.name;
        if (originalData.description !== undefined) description_text.setContent(originalData.description);
        if (originalData.allocatedHours !== undefined) hours_text.text = originalData.allocatedHours;
        if (originalData.color !== undefined) {
            project_color = originalData.color;
            project_color_label.color = colorpicker.getColorByIndex(originalData.color);
        }
        
        if (originalData.startDate !== undefined || originalData.endDate !== undefined) {
            date_range_widget.setDateRange(
                originalData.startDate || "", 
                originalData.endDate || ""
            );
        }
        
        // Restore WorkItemSelector to original selections
        function normalizeIdForRestore(value) {
            if (value === null || value === undefined) return -1;
            var num = parseInt(value);
            return isNaN(num) ? -1 : num;
        }
        
        if (originalData.accountId !== undefined || originalData.parentId !== undefined || originalData.assigneeId !== undefined) {
            var accountId = normalizeIdForRestore(originalData.accountId);
            var parentId = normalizeIdForRestore(originalData.parentId);
            var assigneeId = normalizeIdForRestore(originalData.assigneeId);
            
            workItem.deferredLoadExistingRecordSet(accountId, parentId, -1, -1, -1, assigneeId);
        }
    }
    
    function getCurrentFormData() {
        const ids = workItem.getIds();
        
        var formData = {
            name: project_name.text,
            description: description_text.getFormattedText ? description_text.getFormattedText() : description_text.text,
            allocatedHours: hours_text.text,
            color: project_color,
            startDate: date_range_widget.formattedStartDate ? date_range_widget.formattedStartDate() : "",
            endDate: date_range_widget.formattedEndDate ? date_range_widget.formattedEndDate() : "",
            accountId: ids.account_id,
            parentId: ids.project_id,
            assigneeId: ids.assignee_id
        };
        
        return formData;
    }

    function switchToEditMode() {
        // Switch from read-only to edit mode
        if (recordid !== 0) {
            isReadOnly = false;
            
            // Initialize draft handler when switching from read-only to edit mode
            var originalProjectData = getCurrentFormData();
            draftHandler.initialize(originalProjectData);
        }
    }

    function saveProjectData() {
        const ids = workItem.getIds();

        if (!ids.assignee_id) {
            notifPopup.open("Error", "Please select the assignee", "error");
            return false;
        }

        // Validate hours format before saving
        if (!hours_text.isValid) {
            notifPopup.open("Error", "Please enter allocated hours in HH:MM format (e.g., 1000:30 for large projects)", "error");
            return false;
        }

        // Preserve existing favorites value when editing, default to 0 for new projects
        var currentFavorites = (project && project.favorites !== undefined) ? project.favorites : 0;

        var project_data = {
            'account_id': ids.account_id >= 0 ? ids.account_id : 0,
            'name': project_name.text,
            'planned_start_date': date_range_widget.formattedStartDate(),
            'planned_end_date': date_range_widget.formattedEndDate(),
            'parent_id': ids.project_id,
            'allocated_hours': hours_text.text,
            'description': description_text.text,
            'favorites': currentFavorites,
            'color': project_color,
            'status': "updated",
            'user_id': ids.assignee_id
        };

        var response = Project.createUpdateProject(project_data, recordid);
        if (response) {
            if (response.is_success) {
                notifPopup.open("Saved", response.message, "success");

                if (recordid === 0 && response.record_id) {
                    recordid = response.record_id;
                }

                if (recordid !== 0) {
                    loadProjectData(recordid);
                }
                
                draftHandler.clearDraft();
                isReadOnly = true;
                return true;
            } else {
                notifPopup.open("Failed", response.message, "error");
                return false;
            }
        } else {
            notifPopup.open("Failed", "Unable to save project", "error");
            return false;
        }
    }

    // Helper function to load project data
    function loadProjectData(projectId) {
        // Use appropriate lookup based on whether recordid is a local id or odoo_record_id
        if (isOdooRecordId) {
            // projectId is an odoo_record_id (stable, from notification deep link)
            project = Project.getProjectDetailsByOdooId(projectId);
            console.log("Projects: Loaded by odoo_record_id:", projectId, "found local id:", project ? project.id : "null");
            // Update recordid to local id for subsequent operations
            if (project && project.id) {
                recordid = project.id;
                isOdooRecordId = false; // Now we have the local id
            }
        } else {
            // projectId is a local id (from normal navigation)
            project = Project.getProjectDetails(projectId);
        }
        if (project && Object.keys(project).length > 0) {
            // Set all fields with project details
            let instanceId = (project.account_id !== undefined && project.account_id !== null) ? project.account_id : -1;
            let parentId = (project.parent_id !== undefined && project.parent_id !== null) ? project.parent_id : -1;
            let userId = (project.user_id !== undefined && project.user_id !== null) ? project.user_id : -1;

            // Set parent project selection and assignee
            if (workItem.deferredLoadExistingRecordSet) {
                workItem.deferredLoadExistingRecordSet(instanceId, parentId, -1, -1, -1, userId);
            } else if (workItem.applyDeferredSelection) {
                workItem.applyDeferredSelection(instanceId, parentId, userId);
            }

            project_name.text = project.name || "";
            description_text.setContent(project.description || "");

            // Handle color inheritance for subprojects
            let projectColor = project.color_pallet || 0;

            // If this is a subproject (has parentId) and doesn't have its own color, inherit from parent
            if (parentId !== -1 && (!project.color_pallet || parseInt(project.color_pallet) === 0)) {
                let parentProject = Project.getProjectDetails(parentId);
                if (parentProject && parentProject.color_pallet) {
                    projectColor = parentProject.color_pallet;
                }
            }

            project_color = projectColor;
            project_color_label.color = colorpicker.getColorByIndex(projectColor);
            date_range_widget.setDateRange(project.planned_start_date || "", project.planned_end_date || "");
            hours_text.text = project.allocated_hours !== undefined && project.allocated_hours !== null ? String(project.allocated_hours) : "01:00";
            attachments_widget.setAttachments(Project.getAttachmentsForProject(project.odoo_record_id, project.account_id));
            return true;
        }
        return false;
    }

    NotificationPopup {
        id: notifPopup
        width: units.gu(80)
        height: units.gu(80)
    }

    Flickable {
        id: projectDetailsPageFlickable
        anchors.fill: parent
        contentHeight: mainLayout.height + units.gu(5)
        flickableDirection: Flickable.VerticalFlick
        width: parent.width

        Column {
            id: mainLayout
            width: parent.width
            spacing: units.gu(2)
            topPadding: units.gu(2)
            bottomPadding: units.gu(5)

            // Work Item Selector Section
            WorkItemSelector {
                id: workItem
                readOnly: isReadOnly
                restrictAccountToLocalOnly: recordid === 0
                projectLabelText: "Parent Project"
                showTaskSelector: false
                showSubProjectSelector: false
                showAssigneeSelector: true
                showSubTaskSelector: false
                width: parent.width - units.gu(2)
                anchors.horizontalCenter: parent.horizontalCenter

                onSelectedAccountIdChanged: if (!isRestoringFromDraft) draftHandler.markFieldChanged("accountId", selectedAccountId)
                onSelectedProjectIdChanged: if (!isRestoringFromDraft) draftHandler.markFieldChanged("parentId", selectedProjectId)
                onSelectedAssigneeIdChanged: if (!isRestoringFromDraft) draftHandler.markFieldChanged("assigneeId", selectedAssigneeId)
            }

            // Project Name Row
            Row {
                id: myRow1
                width: parent.width
                spacing: units.gu(2)
                leftPadding: units.gu(1)
                rightPadding: units.gu(1)

                TSLabel {
                    text: i18n.dtr("ubtms", "Project Name")
                    width: units.gu(12)
                    height: units.gu(5)
                    verticalAlignment: Text.AlignVCenter
                }

                TextField {
                    id: project_name
                    readOnly: isReadOnly
                    width: parent.width - units.gu(16)
                    text: ""
                    onTextChanged: if (!isRestoringFromDraft) draftHandler.markFieldChanged("name", text)

                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        radius: units.gu(0.5)
                        border.width: parent.activeFocus ? units.gu(0.2) : units.gu(0.1)
                        border.color: parent.activeFocus ? LomiriColors.orange : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#d3d1d1" : "#999")
                    }
                }
            }

            // Description Section
            Item {
                id: textAreaContainer
                width: parent.width
                height: description_text.height

                RichTextPreview {
                    id: description_text
                    width: parent.width - units.gu(2)
                    height: units.gu(20)
                    anchors.centerIn: parent
                    text: ""
                    is_read_only: isReadOnly
                    onContentChanged: if (!isRestoringFromDraft) draftHandler.markFieldChanged("description", content)
                    onClicked: {
                        Global.description_temporary_holder = getFormattedText();
                        Global.description_context = "project_description";
                        navigatingToReadMore = true;
                        apLayout.addPageToNextColumn(projectCreate, Qt.resolvedUrl("ReadMorePage.qml"), {
                            isReadOnly: isReadOnly,
                            parentDraftHandler: draftHandler
                        });
                    }
                }
            }

            // Current Stage Display
            Grid {
                id: currentStageRow
                visible: recordid !== 0
                width: parent.width - units.gu(2)
                anchors.horizontalCenter: parent.horizontalCenter
                columns: 3
                spacing: units.gu(1)

                TSLabel {
                    text: i18n.dtr("ubtms", "Current Stage:")
                    width: (parent.width - (2 * parent.spacing)) / 3
                    height: units.gu(6)
                    horizontalAlignment: Text.AlignHLeft
                    verticalAlignment: Text.AlignVCenter
                    fontBold: true
                    color: "#f97316"
                }

                TSLabel {
                    text: project && project.stage ? Project.getProjectStageName(project.stage) : i18n.dtr("ubtms", "Not set")
                    width: (parent.width - (2 * parent.spacing)) / 3
                    height: units.gu(6)
                    fontBold: true
                    color: {
                        if (!project || !project.stage) {
                            return theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#888" : "#666";
                        }
                        var stageName = Project.getProjectStageName(project.stage).toLowerCase();
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
                    width: (parent.width - (2 * parent.spacing)) / 3
                    height: units.gu(6)
                    text: i18n.dtr("ubtms", "Change")
                    onClicked: {
                        if (!project || !project.id) {
                            notifPopup.open("Error", "Project data not available", "error");
                            return;
                        }

                        var dialog = PopupUtils.open(projectStageSelector, projectCreate, {
                            projectId: project.id,
                            accountId: project.account_id,
                            currentStageOdooRecordId: project.stage || -1
                        });
                    }
                }
            }

            // Action Buttons Grid
            Grid {
                id: myRow82
                width: parent.width - units.gu(2)
                anchors.horizontalCenter: parent.horizontalCenter
                columns: 3
                spacing: units.gu(1)

                // Activities
                TSLabel {
                    visible: isReadOnly
                    text: i18n.dtr("ubtms","Activities")
                    width: (parent.width - (2 * parent.spacing)) / 3
                    height: units.gu(6)
                    horizontalAlignment: Text.AlignHLeft
                    verticalAlignment: Text.AlignVCenter
                    fontBold: true
                    color: "#f97316"
                }

                TSButton {
                    visible: isReadOnly
                    bgColor: "#fef1e7"
                    fgColor: "#f97316"
                    hoverColor: '#f3e0d1'
                    iconName: "add"
                    iconColor: "#f97316"
                    fontBold: true
                    width: (parent.width - (2 * parent.spacing)) / 3
                    text: i18n.dtr("ubtms","Create")
                    onClicked: {
                        let project = Project.getProjectDetails(recordid);
                        let result = Activity.createActivityFromProjectOrTask(true, project.account_id, project.odoo_record_id);
                        if (result.success) {
                            apLayout.addPageToNextColumn(projectCreate, Qt.resolvedUrl("Activities.qml"), {
                                "recordid": result.record_id,
                                "accountid": project.account_id,
                                "isReadOnly": false
                            });
                        } else {
                            notifPopup.open("Failed", "Unable to create activity", "error");
                        }
                    }
                }

                TSButton {
                    visible: isReadOnly && recordid > 0
                    bgColor: "#f3f4f6"
                    fgColor: "#1f2937"
                    hoverColor: '#d1d5db'
                    borderColor: "#d1d5db"
                    fontBold: true
                    iconName: "view-on"
                    iconColor: "#1f2937"
                    width: (parent.width - (2 * parent.spacing)) / 3
                    text: i18n.dtr("ubtms","View")
                    onClicked: {
                        let project = Project.getProjectDetails(recordid);
                        apLayout.addPageToNextColumn(projectCreate, Qt.resolvedUrl("Activity_Page.qml"), {
                            "filterByProject": true,
                            "projectOdooRecordId": project.odoo_record_id,
                            "projectAccountId": project.account_id,
                            "projectName": project.name
                        });
                    }
                }

                // Tasks
                TSLabel {
                    visible: isReadOnly
                    text: i18n.dtr("ubtms","Tasks")
                    width: (parent.width - (2 * parent.spacing)) / 3
                    height: units.gu(6)
                    horizontalAlignment: Text.AlignHLeft
                    verticalAlignment: Text.AlignVCenter
                    fontBold: true
                    color: "#f97316"
                }

                TSButton {
                    visible: isReadOnly
                    bgColor: "#fef1e7"
                    fgColor: "#f97316"
                    hoverColor: '#f3e0d1'
                    iconName: "add"
                    iconColor: "#f97316"
                    fontBold: true
                    width: (parent.width - (2 * parent.spacing)) / 3
                    text: i18n.dtr("ubtms","Create")
                    onClicked: {
                        let project = Project.getProjectDetails(recordid);
                        let isSubProject = project.parent_id && project.parent_id > 0;
                        let parentProjectId = isSubProject ? project.parent_id : -1;

                        apLayout.addPageToNextColumn(projectCreate, Qt.resolvedUrl("Tasks.qml"), {
                            "recordid": 0,
                            "isReadOnly": false,
                            "prefilledAccountId": project.account_id,
                            "prefilledProjectId": isSubProject ? -1 : project.odoo_record_id,
                            "prefilledSubProjectId": isSubProject ? project.odoo_record_id : -1,
                            "prefilledParentProjectId": parentProjectId,
                            "prefilledProjectName": project.name
                        });
                    }
                }

                TSButton {
                    visible: isReadOnly && recordid > 0
                    bgColor: "#f3f4f6"
                    fgColor: "#1f2937"
                    hoverColor: '#d1d5db'
                    borderColor: "#d1d5db"
                    fontBold: true
                    width: (parent.width - (2 * parent.spacing)) / 3
                    iconName: "view-on"
                    iconColor: "#1f2937"
                    text: i18n.dtr("ubtms","View")
                    onClicked: {
                        let project = Project.getProjectDetails(recordid);
                        apLayout.addPageToNextColumn(projectCreate, Qt.resolvedUrl("Task_Page.qml"), {
                            "filterByProject": true,
                            "projectOdooRecordId": project.odoo_record_id,
                            "projectAccountId": project.account_id,
                            "projectName": project.name
                        });
                    }
                }

                // Project Updates
                TSLabel {
                    visible: isReadOnly
                    text: i18n.dtr("ubtms","Project Updates")
                    width: (parent.width - (2 * parent.spacing)) / 3
                    height: units.gu(6)
                    horizontalAlignment: Text.AlignHLeft
                    verticalAlignment: Text.AlignVCenter
                    fontBold: true
                    color: "#f97316"
                }

                TSButton {
                    visible: isReadOnly
                    bgColor: "#fef1e7"
                    fgColor: "#f97316"
                    hoverColor: '#f3e0d1'
                    iconName: "add"
                    iconColor: "#f97316"
                    fontBold: true
                    width: (parent.width - (2 * parent.spacing)) / 3
                    text: i18n.dtr("ubtms","Create")
                    onClicked: {
                        let project = Project.getProjectDetails(recordid);
                        Global.createUpdateCallback = function(updateData) {
                            let result = Project.createUpdateSnapShot(updateData);
                            if (result['is_success'] === false) {
                                notifPopup.open("Failed", result['message'], "error");
                            } else {
                                notifPopup.open("Saved", "Project update has been saved", "success");
                            }
                            Global.createUpdateCallback = null;
                        };
                        apLayout.addPageToNextColumn(projectCreate, Qt.resolvedUrl("components/CreateUpdatePage.qml"), {
                            "projectId": project.odoo_record_id,
                            "accountId": project.account_id
                        });
                    }
                }

                TSButton {
                    visible: isReadOnly && recordid > 0
                    bgColor: "#f3f4f6"
                    fgColor: "#1f2937"
                    hoverColor: '#d1d5db'
                    borderColor: "#d1d5db"
                    fontBold: true
                    iconName: "view-on"
                    iconColor: "#1f2937"
                    width: (parent.width - (2 * parent.spacing)) / 3
                    text: i18n.dtr("ubtms","View")
                    onClicked: {
                        let project = Project.getProjectDetails(recordid);
                        apLayout.addPageToNextColumn(projectCreate, Qt.resolvedUrl("Updates_Page.qml"), {
                            "filterByProject": true,
                            "projectOdooRecordId": project.odoo_record_id,
                            "projectAccountId": project.account_id,
                            "projectName": project.name
                        });
                    }
                }
            }

            // Allocated Hours
            Row {
                id: myRow4
                width: parent.width - units.gu(2)
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: units.gu(2)

                TSLabel {
                    text: i18n.dtr("ubtms","Allocated Hours")
                    width: parent.width * 0.4
                    anchors.verticalCenter: parent.verticalCenter
                }

                TextField {
                    id: hours_text
                    readOnly: isReadOnly
                    width: parent.width * 0.4
                    anchors.verticalCenter: parent.verticalCenter
                    text: "01:00"
                    onTextChanged: if (!isRestoringFromDraft) draftHandler.markFieldChanged("allocatedHours", text)
                    placeholderText: "HH:MM (e.g., 1000:30)"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    property bool isValid: {
                        if (!/^[0-9]{1,4}:[0-5][0-9]$/.test(text)) return false;
                        var parts = text.split(":");
                        var hours = parseInt(parts[0]);
                        var minutes = parseInt(parts[1]);
                        return hours >= 0 && hours <= 9999 && minutes <= 59;
                    }
                    color: isValid ? (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black") : "red"

                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        radius: units.gu(0.5)
                        border.width: parent.activeFocus ? units.gu(0.2) : units.gu(0.1)
                        border.color: parent.activeFocus ? LomiriColors.orange : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#d3d1d1" : "#999")
                    }
                }
            }

            // Color Picker Row
            Row {
                id: colorRow
                width: parent.width - units.gu(2)
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: units.gu(2)

                TSLabel {
                    text: "Color"
                    width: parent.width * 0.4
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    id: project_color_label
                    width: units.gu(4)
                    height: units.gu(4)
                    anchors.verticalCenter: parent.verticalCenter
                    color: "red"
                    radius: units.gu(0.5)
                    border.width: units.gu(0.2)
                    border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#d3d1d1" : "#999"
                    enabled: !isReadOnly
                    
                    MouseArea {
                        anchors.fill: parent
                        enabled: !isReadOnly
                        onClicked: colorpicker.open()
                    }
                }
            }

            // Date Range Section
            Column {
                width: parent.width - units.gu(2)
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: units.gu(1)

                TSLabel {
                    text: i18n.dtr("ubtms", "Planned Dates")
                    fontBold: true
                }

                DateRangeSelector {
                    id: date_range_widget
                    readOnly: isReadOnly
                    width: parent.width
                    height: units.gu(5)
                    onRangeChanged: {
                        if (!isRestoringFromDraft) {
                            draftHandler.markFieldChanged("startDate", formattedStartDate());
                            draftHandler.markFieldChanged("endDate", formattedEndDate());
                        }
                    }
                }
            }

            // Attachments Section
            AttachmentManager {
                id: attachments_widget
                width: parent.width
                height: units.gu(50)
                resource_type: "project.project"
                resource_id: project.odoo_record_id
                account_id: project.account_id
                notifier: infobar
                onUploadCompleted: {
                    attachments_widget.setAttachments(Project.getAttachmentsForProject(project.odoo_record_id, project.account_id));
                }
            }
        }
    }

    ColorPicker {
        id: colorpicker
        width: units.gu(80)
        height: units.gu(80)
        onColorPicked: function (index, value) {
            project_color_label.color = value;
            project_color = index;
        }
    }

    // Project Stage Selector Component
    Component {
        id: projectStageSelector
        ProjectStageSelector {
            onStageSelected: handleStageChange(stageOdooRecordId, stageName)
        }
    }

    // Handle project stage change
    function handleStageChange(stageOdooRecordId, stageName) {
        if (!project || !project.id) {
            notifPopup.open("Error", "Project data not available", "error");
            return;
        }

        var result = Project.updateProjectStage(project.id, stageOdooRecordId, project.account_id);

        if (result.success) {
            // Update local project data to reflect the change
            project.stage = stageOdooRecordId;
            
            // Reload project data to ensure UI is updated
            loadProjectData(recordid);
            
            notifPopup.open("Success", "Project stage changed to: " + stageName, "success");
        } else {
            notifPopup.open("Error", "Failed to update project stage: " + (result.error || "Unknown error"), "error");
        }
    }

    Component.onCompleted: {
        if (recordid !== 0) {
            if (!loadProjectData(recordid)) {
                notifPopup.open("Failed", "Unable to open the project details", "error");
            }
        } else {
            //do nothing as we are creating project
            recordid = 0;
            // For new projects, force local account (id = 0) to respect restrictAccountToLocalOnly
            if (workItem.deferredLoadExistingRecordSet) {
                workItem.deferredLoadExistingRecordSet(0, -1, -1, -1, -1, -1); // Use local account (id = 0)
            } else if (workItem.applyDeferredSelection) {
                workItem.applyDeferredSelection(0, -1, -1); // Use local account (id = 0)
            }
        }
        
        // Mark form as fully initialized
        formFullyInitialized = true;
        
        // Initialize draft handler AFTER all form fields are populated
        if (!isReadOnly) {
            var originalProjectData = getCurrentFormData();
            draftHandler.initialize(originalProjectData);
        }
    }
    
    onVisibleChanged: {
        if (visible) {
            if (Global.description_temporary_holder !== "" && Global.description_context === "project_description") {
                //Check if you are coming back from the ReadMore page for project description
                description_text.setContent(Global.description_temporary_holder);
                Global.description_temporary_holder = "";
                Global.description_context = "";
            }
        }
        // Don't clear context when page becomes invisible as it might be needed
        // for the ReadMore page editing flow
    }
}
