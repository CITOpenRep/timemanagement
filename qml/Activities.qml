import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Window 2.2
import Qt.labs.settings 1.0
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.Components.Pickers 1.3
import "../models/utils.js" as Utils
import "../models/activity.js" as Activity
import "../models/accounts.js" as Accounts
import "../models/task.js" as Task
import "../models/project.js" as Project
import "../models/global.js" as Global
import "components"

Page {
    id: activityDetailsPage
    title: i18n.dtr("ubtms", "Activity")
    property var recordid: 0
    property bool descriptionExpanded: false
    property real expandedHeight: units.gu(60)
    property var currentActivity: {
        "summary": "",
        "notes": "",
        "activity_type_id": "",
        "due_date": "",
        "state": ""
    }
    property bool isReadOnly: true
    property var accountid: 0
    
    // Watch for isReadOnly changes and save draft when switching from edit to read-only
    onIsReadOnlyChanged: {
        // If switching from edit mode to read-only mode, save any pending draft
        if (isReadOnly && draftHandler.hasUnsavedChanges && draftHandler.changedFields.length > 0) {
            var result = draftHandler.saveDraft();
        }
    }

    // Track if the activity has been saved at least once
    property bool hasBeenSaved: false
    // Track if we're navigating to ReadMorePage to avoid showing save dialog
    property bool navigatingToReadMore: false
    // Track if user has modified form fields (deprecated - now using draftHandler)
    property bool formModified: false
    // Flag to prevent tracking changes during initialization
    property bool isInitializing: true
    // Flag to track when we're restoring from draft (to allow tracking during restoration)
    property bool isRestoringFromDraft: false
    // Track if form is fully initialized (to defer draft restoration)
    property bool formFullyInitialized: false

    // Handle hardware back button presses
    Keys.onReleased: {
        if (event.key === Qt.Key_Back || event.key === Qt.Key_Escape) {
            event.accepted = true;
            handleBackNavigation();
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

    header: PageHeader {
        id: header
        title: activityDetailsPage.title + (draftHandler.hasUnsavedChanges ? " •" : "")
        StyleHints {
            foregroundColor: "white"
            backgroundColor: LomiriColors.orange
            dividerColor: LomiriColors.slate
        }
        trailingActionBar.actions: [
            Action {
                iconSource: "images/save.svg"
                visible: !isReadOnly
                text: i18n.dtr("ubtms", "Save")
                onTriggered: {
                    saveActivityData();
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

        // Add back button with save/discard logic
        leadingActionBar.actions: [
            Action {
                iconName: "back"
                text: i18n.dtr("ubtms", "Back")
                onTriggered: {
                    handleBackNavigation();
                }
            }
        ]
    }

    NotificationPopup {
        id: notifPopup
        width: units.gu(80)
        height: units.gu(80)
    }

    // Draft Handler for auto-save and crash recovery
    FormDraftHandler {
        id: draftHandler
        draftType: "activity"
        recordId: recordid
        accountId: accountid
        enabled: !isReadOnly
        autoSaveInterval: 30000 // 30 seconds
        
        onDraftLoaded: function(draftData, changedFields) {
            
            // Only restore draft if we're in edit mode (not read-only)
            if (isReadOnly) {
                draftHandler.clearDraft();
                return;
            }
            
            // Only restore if form is fully initialized
            if (!formFullyInitialized) {
                Qt.callLater(function() {
                    if (formFullyInitialized && !isReadOnly) {
                        restoreDraftData(draftData);
                        notifPopup.open("Draft Restored", "Your unsaved changes have been restored", "info");
                    }
                });
                return;
            }
            
            // Set flag to indicate we're restoring from draft
            isRestoringFromDraft = true;
            restoreDraftData(draftData);
            
            // Show notification about draft
            notifPopup.open("Draft Restored", "Your unsaved changes have been restored", "info");
            
            // Clear the restoration flag
            isRestoringFromDraft = false;
        }
        
        onDraftSaved: function(draftId) {
        }
        
        onDraftCleared: function() {
        }
    }

    SaveDiscardDialog {
        id: saveDiscardDialog
        onSaveRequested: {
            saveActivityData();
            // After successful save, navigate back
            if (hasBeenSaved) {
                navigateBack();
            }
        }
        onDiscardRequested: {
            // Clear draft first when discarding
            draftHandler.clearDraft();
            
            // For new activities that haven't been saved, delete them
            if (recordid > 0 && !hasBeenSaved && !isReadOnly) {
                if (Activity.isActivityUnsaved(accountid, recordid)) {
                    Activity.deleteActivity(accountid, recordid);
                }
                navigateBack();
                return;
            }
            
            // For edit mode on existing saved activities, restore and stay in read-only
            if (recordid > 0 && hasBeenSaved) {
                isInitializing = true;  // Prevent draft tracking during restoration
                restoreFormToOriginal();
                isReadOnly = true;
                isInitializing = false;
                // Don't navigate back - stay on the page in read-only mode
                return;
            }
            
            // For all other cases (shouldn't happen normally), just navigate back
            navigateBack();
        }
        onCancelled: {
            // User wants to stay and continue editing
        }
    }

    function restoreDraftData(draftData) {
        
        // Set flag to indicate we're restoring from draft
        isRestoringFromDraft = true;
        
        // Restore form fields from draft
        if (draftData.summary !== undefined) {
            summary.text = draftData.summary;
        }
        if (draftData.notes !== undefined) {
            notes.setContent(draftData.notes);
        }
        if (draftData.activity_type_id !== undefined && draftData.account_id !== undefined) {
            // Reload activity type selector with the account from draft
            reloadActivityTypeSelector(draftData.account_id, draftData.activity_type_id);
        }
        if (draftData.due_date !== undefined && draftData.due_date !== "") {
            date_widget.setSelectedDate(draftData.due_date);
        }
        
        // Restore radio button selection first
        if (draftData.linkedType !== undefined) {
            taskRadio.checked = false;
            projectRadio.checked = false;
            updateRadio.checked = false;
            otherRadio.checked = false;
            
            if (draftData.linkedType === "task") {
                taskRadio.checked = true;
            } else if (draftData.linkedType === "project") {
                projectRadio.checked = true;
            } else if (draftData.linkedType === "update") {
                updateRadio.checked = true;
            } else if (draftData.linkedType === "other") {
                otherRadio.checked = true;
            }
        }
        
        // Restore WorkItemSelector using deferredLoadExistingRecordSet
        if (draftData.account_id !== undefined) {
            var accountId = draftData.account_id || 0;
            var projectId = draftData.project_id || -1;
            var subProjectId = draftData.sub_project_id || -1;
            var taskId = draftData.task_id || -1;
            var subTaskId = draftData.sub_task_id || -1;
            var userId = draftData.user_id || -1;
            
            workItem.deferredLoadExistingRecordSet(accountId, projectId, subProjectId, taskId, subTaskId, userId);
        }
        
        // Clear the restoration flag
        isRestoringFromDraft = false;
    }

    function restoreFormToOriginal() {
        
        var originalData = draftHandler.originalData;
        
        // Restore basic fields
        if (originalData.summary !== undefined) summary.text = originalData.summary;
        if (originalData.notes !== undefined) notes.setContent(originalData.notes);
        if (originalData.activity_type_id !== undefined && originalData.account_id !== undefined) {
            reloadActivityTypeSelector(originalData.account_id, originalData.activity_type_id);
        }
        if (originalData.due_date !== undefined && originalData.due_date !== "") {
            date_widget.setSelectedDate(originalData.due_date);
        }
        
        // Restore radio button selection
        if (originalData.linkedType !== undefined) {
            taskRadio.checked = false;
            projectRadio.checked = false;
            updateRadio.checked = false;
            otherRadio.checked = false;
            
            if (originalData.linkedType === "task") {
                taskRadio.checked = true;
            } else if (originalData.linkedType === "project") {
                projectRadio.checked = true;
            } else if (originalData.linkedType === "update") {
                updateRadio.checked = true;
            } else if (originalData.linkedType === "other") {
                otherRadio.checked = true;
            }
        }
        
        // Restore WorkItemSelector
        if (originalData.account_id !== undefined) {
            var accountId = originalData.account_id || 0;
            var projectId = originalData.project_id || -1;
            var subProjectId = originalData.sub_project_id || -1;
            var taskId = originalData.task_id || -1;
            var subTaskId = originalData.sub_task_id || -1;
            var userId = originalData.user_id || -1;
            
            workItem.deferredLoadExistingRecordSet(accountId, projectId, subProjectId, taskId, subTaskId, userId);
        }
        
    }

    function navigateToConnectedItem() {
        if (!currentActivity || !currentActivity.linkedType) {
            notifPopup.open("Error", "Activity connection information not available", "error");
            return;
        }

        if (currentActivity.linkedType === "task") {
            // Navigate to Task - use sub_task_id if available, otherwise task_id
            var taskOdooRecordId = -1;
            if (currentActivity.sub_task_id && currentActivity.sub_task_id > 0) {
                taskOdooRecordId = currentActivity.sub_task_id;
            } else if (currentActivity.task_id && currentActivity.task_id > 0) {
                taskOdooRecordId = currentActivity.task_id;
            }

            if (taskOdooRecordId > 0) {
                // Get the local task id from odoo_record_id
                var taskLocalId = Task.getLocalIdFromOdooId(taskOdooRecordId, currentActivity.account_id);
                if (taskLocalId > 0) {
                    apLayout.addPageToNextColumn(activityDetailsPage, Qt.resolvedUrl("Tasks.qml"), {
                        "recordid": taskLocalId,
                        "isReadOnly": true,
                        "editVisible": false
                    });
                } else {
                    notifPopup.open("Error", "Connected task not found in local database", "error");
                }
            } else {
                notifPopup.open("Error", "No valid task connection found", "error");
            }
        } else if (currentActivity.linkedType === "project") {
            // Navigate to Project - use sub_project_id if available, otherwise project_id
            var projectOdooRecordId = -1;
            if (currentActivity.sub_project_id && currentActivity.sub_project_id > 0) {
                projectOdooRecordId = currentActivity.sub_project_id;
            } else if (currentActivity.project_id && currentActivity.project_id > 0) {
                projectOdooRecordId = currentActivity.project_id;
            }

            if (projectOdooRecordId > 0) {
                // Get the local project id from odoo_record_id
                var projectLocalId = Project.getLocalIdFromOdooId(projectOdooRecordId, currentActivity.account_id);
                if (projectLocalId > 0) {
                    apLayout.addPageToNextColumn(activityDetailsPage, Qt.resolvedUrl("Projects.qml"), {
                        "recordid": projectLocalId,
                        "isReadOnly": true
                    });
                } else {
                    notifPopup.open("Error", "Connected project not found in local database", "error");
                }
            } else {
                notifPopup.open("Error", "No valid project connection found", "error");
            }
        } else if (currentActivity.linkedType === "update") {
            // Navigate to Project Update
            var updateOdooRecordId = currentActivity.update_id || -1;

            if (updateOdooRecordId > 0) {
                // Get the local update id from odoo_record_id
                var updateLocalId = Project.getUpdateLocalIdFromOdooId(updateOdooRecordId, currentActivity.account_id);
                if (updateLocalId > 0) {
                    apLayout.addPageToNextColumn(activityDetailsPage, Qt.resolvedUrl("Updates.qml"), {
                        "recordid": updateLocalId,
                        "accountid": currentActivity.account_id,
                        "isReadOnly": true
                    });
                } else {
                    notifPopup.open("Error", "Connected project update not found in local database", "error");
                }
            } else {
                notifPopup.open("Error", "No valid project update connection found", "error");
            }
        } else {
            notifPopup.open("Info", "This activity is not connected to a task, project, or update", "info");
        }
    }

    Flickable {
        id: flickable
        anchors.fill: parent
        anchors.topMargin: units.gu(6)
        contentHeight: descriptionExpanded ? parent.height + 1900 : parent.height + 850
        flickableDirection: Flickable.VerticalFlick

        width: parent.width

        Row {
            id: row1
            topPadding: units.gu(5)

            Column {
                leftPadding: units.gu(1)

                WorkItemSelector {
                    id: workItem
                    readOnly: isReadOnly
                    showAccountSelector: true
                    showAssigneeSelector: true
                    showProjectSelector: projectRadio.checked || taskRadio.checked
                    showSubProjectSelector: projectRadio.checked || taskRadio.checked
                    showSubTaskSelector: taskRadio.checked
                    showTaskSelector: taskRadio.checked
                    width: flickable.width - units.gu(2)
                    onStateChanged: {
                        if (newState === "AccountSelected") {
                            // Only reset activity type if we are NOT in deferred loading mode
                            // This prevents resetting the type when restoring drafts or loading existing records
                            if (!workItem.deferredLoadingPlanned) {
                                let acctId = workItem.getIds().account_id;
                                reloadActivityTypeSelector(acctId, -1);
                            }
                        }
                        
                        // Track changes in draft handler (only after initialization and when not read-only)
                        // Exception: allow tracking during draft restoration to preserve changes
                        if ((!isInitializing || isRestoringFromDraft) && !isReadOnly) {
                            var ids = workItem.getIds();
                            
                            // Track all IDs whenever state changes
                            // Note: account_id of 0 is valid (local account). null means -1 (no selection)
                            // We MUST track null values to ensure fields are cleared in the draft when unselected
                            
                            if (ids.account_id !== undefined) {
                                var accId = ids.account_id === null ? -1 : ids.account_id;
                                draftHandler.markFieldChanged("account_id", accId);
                            }
                            
                            // For project/task/subtask/user fields, track all values including null (cleared)
                            if (ids.project_id !== undefined) {
                                var projId = ids.project_id === null ? -1 : ids.project_id;
                                draftHandler.markFieldChanged("project_id", projId);
                            }
                            if (ids.subproject_id !== undefined) {
                                var subProjId = ids.subproject_id === null ? -1 : ids.subproject_id;
                                draftHandler.markFieldChanged("sub_project_id", subProjId);
                            }
                            if (ids.task_id !== undefined) {
                                var taskId = ids.task_id === null ? -1 : ids.task_id;
                                draftHandler.markFieldChanged("task_id", taskId);
                            }
                            if (ids.subtask_id !== undefined) {
                                var subTaskId = ids.subtask_id === null ? -1 : ids.subtask_id;
                                draftHandler.markFieldChanged("sub_task_id", subTaskId);
                            }
                            if (ids.assignee_id !== undefined) {
                                var userId = ids.assignee_id === null ? -1 : ids.assignee_id;
                                draftHandler.markFieldChanged("user_id", userId);
                            }
                        }
                    }
                }
            }
        }

        // Navigation button to view connected task or project
        Item {
            id: rowNavigate
            width: parent.width
            height: units.gu(6)
            anchors.top: row1.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: units.gu(1)
            anchors.rightMargin: units.gu(1)
            anchors.topMargin: units.gu(2)
            
            visible: recordid !== 0 && currentActivity && (currentActivity.linkedType === "task" || currentActivity.linkedType === "project" || currentActivity.linkedType === "update")

            TSButton {
           anchors.horizontalCenter: parent.horizontalCenter
         
                width: parent.width/3
                height: units.gu(6)
                
             
              //  borderColor: "#f97316"

                   bgColor: "#fef1e7"
                fgColor: "#f97316"
                hoverColor: '#f3e0d1'
               
                iconColor: "#f97316"
                iconName: {
                    if (!currentActivity) return "";
                    if (currentActivity.linkedType === "task") return "stock_application";
                    if (currentActivity.linkedType === "project") return "folder-symbolic";
                    if (currentActivity.linkedType === "update") return "history";
                    return "";
                }
             //   iconColor: "#2563eb"
                fontBold: true
                text: {
                    if (!currentActivity) return "";
                    if (currentActivity.linkedType === "task") {
                        return i18n.dtr("ubtms", "View Task");
                    } else if (currentActivity.linkedType === "project") {
                        return i18n.dtr("ubtms", "View Project");
                    } else if (currentActivity.linkedType === "update") {
                        return i18n.dtr("ubtms", "View Update");
                    }
                    return "";
                }
                onClicked: {
                    navigateToConnectedItem();
                }
            }
        }

        Row {
            id: row1w
            anchors.top: rowNavigate.bottom
            topPadding: units.gu(1)
            Column {
                id: myCol88w
                leftPadding: units.gu(1)
                LomiriShape {
                    width: units.gu(10)
                    height: units.gu(5)
                    aspect: LomiriShape.Flat
                    TSLabel {
                        id: resource_label
                        text:  i18n.dtr("ubtms", "Connected to")
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
            Column {
                id: myCol99w
                leftPadding: units.gu(3)
                
                Grid {
                    columns: 2
                    spacing: units.gu(1)
                    
                    RadioButton {
                        id: projectRadio
                        text: i18n.dtr("ubtms","Project")
                        checked: false
                         enabled: recordid === 0 
                        contentItem: Text {
                            text: projectRadio.text
                            color: theme.palette.normal.backgroundText
                            leftPadding: projectRadio.indicator.width + projectRadio.spacing
                            verticalAlignment: Text.AlignVCenter
                        }
                        onCheckedChanged: {
                            if (checked) {
                                taskRadio.checked = false;
                                updateRadio.checked = false;
                                otherRadio.checked = false;
                                // Track changes in draft handler (only after initialization and when not read-only)
                                // Exception: allow tracking during draft restoration to preserve changes
                                if ((!isInitializing || isRestoringFromDraft) && !isReadOnly) {
                                    draftHandler.markFieldChanged("linkedType", "project");
                                    // Also mark current project/subproject IDs as changed to ensure they're saved in draft
                                    var ids = workItem.getIds();
                                    if (ids.project_id !== undefined && ids.project_id !== null && ids.project_id !== -1) {
                                        draftHandler.markFieldChanged("project_id", ids.project_id);
                                    }
                                    if (ids.subproject_id !== undefined && ids.subproject_id !== null && ids.subproject_id !== -1) {
                                        draftHandler.markFieldChanged("sub_project_id", ids.subproject_id);
                                    }
                                }
                            }
                        }
                    }

                    RadioButton {
                        id: taskRadio
                        text: i18n.dtr("ubtms","Task")
                        checked: true
                        enabled: recordid === 0 
                        contentItem: Text {
                            text: taskRadio.text
                            color: theme.palette.normal.backgroundText
                            leftPadding: taskRadio.indicator.width + taskRadio.spacing
                            verticalAlignment: Text.AlignVCenter
                        }
                        onCheckedChanged: {
                            if (checked) {
                                projectRadio.checked = false;
                                updateRadio.checked = false;
                                otherRadio.checked = false;
                                // Track changes in draft handler (only after initialization and when not read-only)
                                // Exception: allow tracking during draft restoration to preserve changes
                                if ((!isInitializing || isRestoringFromDraft) && !isReadOnly) {
                                    draftHandler.markFieldChanged("linkedType", "task");
                                    // Also mark current project/subproject/task/subtask IDs as changed to ensure they're saved in draft
                                    var ids = workItem.getIds();
                                    if (ids.project_id !== undefined && ids.project_id !== null && ids.project_id !== -1) {
                                        draftHandler.markFieldChanged("project_id", ids.project_id);
                                    }
                                    if (ids.subproject_id !== undefined && ids.subproject_id !== null && ids.subproject_id !== -1) {
                                        draftHandler.markFieldChanged("sub_project_id", ids.subproject_id);
                                    }
                                    if (ids.task_id !== undefined && ids.task_id !== null && ids.task_id !== -1) {
                                        draftHandler.markFieldChanged("task_id", ids.task_id);
                                    }
                                    if (ids.subtask_id !== undefined && ids.subtask_id !== null && ids.subtask_id !== -1) {
                                        draftHandler.markFieldChanged("sub_task_id", ids.subtask_id);
                                    }
                                }
                            }
                        }
                    }
                    
                    RadioButton {
                        id: updateRadio
                        text: i18n.dtr("ubtms","Update")
                        checked: false
                        enabled: recordid === 0 
                        visible: recordid !== 0  // Only show when editing existing activity
                        contentItem: Text {
                            text: updateRadio.text
                            color: theme.palette.normal.backgroundText
                            leftPadding: updateRadio.indicator.width + updateRadio.spacing
                            verticalAlignment: Text.AlignVCenter
                        }
                        onCheckedChanged: {
                            if (checked) {
                                projectRadio.checked = false;
                                taskRadio.checked = false;
                                otherRadio.checked = false;
                                // Track changes in draft handler (only after initialization and when not read-only)
                                // Exception: allow tracking during draft restoration to preserve changes
                                if ((!isInitializing || isRestoringFromDraft) && !isReadOnly) {
                                    draftHandler.markFieldChanged("linkedType", "update");
                                }
                            }
                        }
                    }
                    
                    RadioButton {
                        id: otherRadio
                        text: i18n.dtr("ubtms","Other")
                        checked: false
                        enabled: recordid === 0 
                        visible: recordid !== 0  // Only show when editing existing activity
                        contentItem: Text {
                            text: otherRadio.text
                            color: theme.palette.normal.backgroundText
                            leftPadding: otherRadio.indicator.width + otherRadio.spacing
                            verticalAlignment: Text.AlignVCenter
                        }
                        onCheckedChanged: {
                            if (checked) {
                                projectRadio.checked = false;
                                taskRadio.checked = false;
                                updateRadio.checked = false;
                                // Track changes in draft handler (only after initialization and when not read-only)
                                // Exception: allow tracking during draft restoration to preserve changes
                                if ((!isInitializing || isRestoringFromDraft) && !isReadOnly) {
                                    draftHandler.markFieldChanged("linkedType", "other");
                                }
                            }
                        }
                    }
                }
            }
        }

        Row {
            id: row2
            anchors.top: row1w.bottom
            anchors.left: parent.left
            topPadding: units.gu(1)
            Column {
                id: myCol88
                leftPadding: units.gu(1)
                LomiriShape {
                    width: units.gu(10)
                    height: units.gu(5)
                    aspect: LomiriShape.Flat
                    TSLabel {
                        id: name_label
                        text: i18n.dtr("ubtms","Summary")
                        // font.bold: true
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        //textSize: Label.Large
                    }
                }
            }
            Column {
                id: myCol99
                leftPadding: units.gu(3)
                TextArea {
                    id: summary
                    textFormat: Text.PlainText //Do not make this RichText
                    readOnly: isReadOnly
                    width: flickable.width < units.gu(361) ? flickable.width - units.gu(15) : flickable.width - units.gu(10)
                    height: units.gu(5) // Start with collapsed height
                    text: currentActivity.summary

                    onTextChanged: {
                        // Track changes in draft handler (only after initialization and when not read-only)
                        // Exception: allow tracking during draft restoration to preserve changes
                        if ((!isInitializing || isRestoringFromDraft) && !isReadOnly) {
                            draftHandler.markFieldChanged("summary", text);
                        }
                    }

                    // Custom styling for border highlighting
                    Rectangle {
                        // visible: !isReadOnly
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
            id: myRow9
            anchors.top: row2.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            topPadding: units.gu(1)
            height: units.gu(20)

            Column {
                id: myCol9
                width: parent.width
                height: parent.height

                Item {
                    id: textAreaContainer
                    width: parent.width
                    height: parent.height
                    RichTextPreview {
                        id: notes
                        anchors.fill: parent
                        title: "Notes"
                        text: ""
                        is_read_only: isReadOnly
                        onClicked: {
                            //set the data to a global Store and pass the key to the page
                            Global.description_temporary_holder = notes.getFormattedText();
                            Global.description_context = "activity_notes";
                            navigatingToReadMore = true;
                            apLayout.addPageToNextColumn(activityDetailsPage, Qt.resolvedUrl("ReadMorePage.qml"), {
                                isReadOnly: isReadOnly
                                //useRichText: false
                            });
                        }
                        onContentChanged: function(content) {
                            // Track changes in draft handler (only after initialization and when not read-only)
                            // Exception: allow tracking during draft restoration to preserve changes
                            if ((!isInitializing || isRestoringFromDraft) && !isReadOnly) {
                                draftHandler.markFieldChanged("notes", content);
                            }
                        }
                    }
                }
            }
        }

        Row {
            id: row4
            anchors.top: myRow9.bottom
            anchors.left: parent.left
            topPadding: units.gu(1)
            height: units.gu(5)
            anchors.topMargin: units.gu(3)
            Item {
                width: parent.width * 0.75
                height: units.gu(5)
                TreeSelector {
                    id: activityTypeSelector
                    enabled: !isReadOnly
                    labelText: i18n.dtr("ubtms","Activity Type")
                    width: flickable.width - units.gu(2)
                    height: units.gu(29)
                    onItemSelected: function(id, name) {
                        // Track changes in draft handler (only after initialization and when not read-only)
                        // Exception: allow tracking during draft restoration to preserve changes
                        if ((!isInitializing || isRestoringFromDraft) && !isReadOnly) {
                            draftHandler.markFieldChanged("activity_type_id", id);
                        }
                    }
                }
            }
        }

        Row {
            id: row5
            anchors.top: row4.bottom
            anchors.left: parent.left
            Column {
                leftPadding: units.gu(1)
                DaySelector {
                    id: date_widget
                    readOnly: isReadOnly
                    width: flickable.width - units.gu(2)
                    height: units.gu(5)
                    anchors.centerIn: parent.centerIn
                    onDateChanged: function(selectedDate) {
                        // Track changes in draft handler (only after initialization and when not read-only)
                        // Exception: allow tracking during draft restoration to preserve changes
                        if ((!isInitializing || isRestoringFromDraft) && !isReadOnly) {
                            draftHandler.markFieldChanged("due_date", Qt.formatDate(selectedDate, "yyyy-MM-dd"));
                        }
                    }
                }
            }
        }
    }

    // Timer to end initialization phase
    Timer {
        id: initializationTimer
        interval: 500  // 500ms should be enough for all components to settle
        repeat: false
        onTriggered: {
            isInitializing = false;
        }
    }

    Component.onCompleted: {
        // Initialize form modification tracking
        formModified = false;
        isInitializing = true;

        if (recordid != 0) {
            currentActivity = Activity.getActivityById(recordid, accountid);
            currentActivity.user_name = Accounts.getUserNameByOdooId(currentActivity.user_id);

            let instanceId = currentActivity.account_id;
            let user_id = currentActivity.user_id;

            // Default radio selection
            taskRadio.checked = false;
            projectRadio.checked = false;
            updateRadio.checked = false;
            otherRadio.checked = false;

            // If project and subproject are the same, treat it as no subproject selected.
            if (currentActivity.project_id && currentActivity.project_id === currentActivity.sub_project_id) {
                currentActivity.sub_project_id = -1;
            }

            // Check if this is a truly saved activity or a newly created one with default values
            hasBeenSaved = !Activity.isActivityUnsaved(accountid, recordid);
            
            // DON'T initialize draft handler yet - wait until form is fully loaded
            
            // Load the Activity Type
            reloadActivityTypeSelector(instanceId, currentActivity.activity_type_id);

            switch (currentActivity.linkedType) {
            case "task":
                // Connected to task: Show project, subproject, and task selectors
                taskRadio.checked = true;
                workItem.deferredLoadExistingRecordSet(instanceId, currentActivity.project_id, currentActivity.sub_project_id, currentActivity.task_id, currentActivity.sub_task_id, user_id);
                break;
            case "project":
                // Connected to project/subproject: Show project and subproject selectors
                projectRadio.checked = true;
                workItem.deferredLoadExistingRecordSet(instanceId, currentActivity.project_id, currentActivity.sub_project_id, -1, -1, user_id);
                break;
            case "update":
                // Connected to project update
                updateRadio.checked = true;
                workItem.deferredLoadExistingRecordSet(instanceId, -1, -1, -1, -1, user_id);
                break;
            case "other":
                // Not connected to anything specific
                otherRadio.checked = true;
                workItem.deferredLoadExistingRecordSet(instanceId, -1, -1, -1, -1, user_id);
                break;
            default:
                workItem.deferredLoadExistingRecordSet(instanceId, -1, -1, -1, -1, user_id);
            }

            // Update fields with loaded data
            summary.text = currentActivity.summary || "";
            notes.setContent(currentActivity.notes || "");

            // Update due date
            date_widget.setSelectedDate(currentActivity.due_date);
        } else {
            // For new activities
            let account = Accounts.getAccountsList();
            reloadActivityTypeSelector(account, -1);

            // For new activities, show both selectors with task selected by default
            taskRadio.checked = true;
            projectRadio.checked = false;
            workItem.loadAccounts();

            // New activities start as unsaved
            hasBeenSaved = false;
        }
        
        // Mark form as fully initialized
        formFullyInitialized = true;
        
        // Initialize draft handler AFTER all form fields are populated
        if (!isReadOnly) {
            var originalActivityData = getCurrentFormData();
            draftHandler.initialize(originalActivityData);
        }
        
        // Start timer to end initialization phase
        initializationTimer.start();
    }

    function switchToEditMode() {
        // Switch from read-only to edit mode
        if (recordid !== 0) {
            isReadOnly = false;
            
            // Initialize draft handler when switching from read-only to edit mode
            // This ensures drafts are loaded if they exist
            var originalActivityData = getCurrentFormData();
            draftHandler.initialize(originalActivityData);
        }
    }

    function getCurrentFormData() {
        const ids = workItem.getIds();
        
        // Determine linkedType based on which radio button is checked
        var linkedType = "";
        if (taskRadio.checked) {
            linkedType = "task";
        } else if (projectRadio.checked) {
            linkedType = "project";
        } else if (updateRadio.checked) {
            linkedType = "update";
        } else if (otherRadio.checked) {
            linkedType = "other";
        }
        
        var formData = {
            summary: summary.text || "",
            notes: notes.getFormattedText() || "",
            activity_type_id: activityTypeSelector.selectedId || -1,
            due_date: date_widget.formattedDate() || "",
            account_id: ids.account_id || 0,
            project_id: ids.project_id || -1,
            sub_project_id: ids.subproject_id || -1,
            task_id: ids.task_id || -1,
            sub_task_id: ids.subtask_id || -1,
            user_id: ids.assignee_id || -1,
            linkedType: linkedType
        };
        
        return formData;
    }

    // Robust navigation function with multiple fallback methods
    function navigateBack() {
        
        // Method 1: AdaptivePageLayout (primary method for this app)
        try {
            if (typeof apLayout !== "undefined" && apLayout !== null) {
                apLayout.removePages(activityDetailsPage);
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
        }

        // Method 3: Stack view
        try {
            if (typeof Stack !== "undefined" && Stack.view && Stack.view.pop) {
                Stack.view.pop();
                return;
            }
        } catch (e) {
        }

        // Method 4: pageStack removePages
        try {
            if (typeof pageStack !== "undefined" && pageStack && pageStack.removePages) {
                pageStack.removePages(activityDetailsPage);
                return;
            }
        } catch (e) {
        }

        // Method 5: Parent pop
        try {
            if (parent && parent.pop) {
                parent.pop();
                return;
            }
        } catch (e) {
        }
    }
    function reloadActivityTypeSelector(accountId, selectedTypeId) {
        let rawTypes = Activity.getActivityTypesForAccount(accountId);
        let flatModel = [];

        // Add default "No Type" entry
        flatModel.push({
            id: -1,
            name: "No Type",
            parent_id: null
        });

        let selectedText = "No Type";
        let selectedFound = (selectedTypeId === -1);

        for (let i = 0; i < rawTypes.length; i++) {
            let id = accountId === 0 ? rawTypes[i].id : rawTypes[i].odoo_record_id;
            let name = rawTypes[i].name;

            flatModel.push({
                id: id,
                name: name,
                parent_id: null  // no hierarchy assumed
            });

            if (selectedTypeId !== undefined && selectedTypeId !== null && selectedTypeId === id) {
                selectedText = name;
                selectedFound = true;
            }
        }

        // Push to the model and reload selector
        activityTypeSelector.dataList = flatModel;
        activityTypeSelector.reload();

        // Update selected item
        activityTypeSelector.selectedId = selectedFound ? selectedTypeId : -1;
        activityTypeSelector.currentText = selectedFound ? selectedText : "Select Type";
        
        // Track the activity type change in draft handler (only when not initializing and not read-only)
        // Exception: allow tracking during draft restoration to preserve changes
        // This is needed because setting selectedId programmatically doesn't trigger onItemSelected
        // We MUST track -1 (cleared) values too, especially when account changes
        if ((!isInitializing || isRestoringFromDraft) && !isReadOnly) {
            // Only track if we actually found the selected type OR if we are explicitly clearing it (selectedTypeId == -1)
            if (selectedFound || selectedTypeId === -1) {
                draftHandler.markFieldChanged("activity_type_id", selectedTypeId);
            }
        }
    }

    function saveActivityData() {
        const ids = workItem.getIds();

        var linkid = -1;
        var resId = 0;
        var resModel = "";

        if (projectRadio.checked) {
            // Use subproject if it's valid and not -1/null, otherwise use main project
            // Check if subproject_id is a valid value (not -1, not null, not undefined)
            if (ids.subproject_id && ids.subproject_id !== -1 && ids.subproject_id !== null) {
                linkid = ids.subproject_id;
            } else if (ids.project_id && ids.project_id !== -1 && ids.project_id !== null) {
                linkid = ids.project_id;
            }
            resId = Accounts.getOdooModelId(ids.account_id, "Project");
            resModel = "project.project";
            
            // Validate that project connection is valid
            if (typeof linkid === "undefined" || linkid === null || linkid <= 0 || resId === 0) {
                notifPopup.open("Error", "Activity must be connected to a valid project", "error");
                return;
            }
        } else if (taskRadio.checked) {
            // Use subtask if it's valid and not -1/null, otherwise use main task
            if (ids.subtask_id && ids.subtask_id !== -1 && ids.subtask_id !== null) {
                linkid = ids.subtask_id;
            } else if (ids.task_id && ids.task_id !== -1 && ids.task_id !== null) {
                linkid = ids.task_id;
            }
            resId = Accounts.getOdooModelId(ids.account_id, "Task");
            resModel = "project.task";
            
            // Validate that task connection is valid
            if (typeof linkid === "undefined" || linkid === null || linkid <= 0 || resId === 0) {
                notifPopup.open("Error", "Activity must be connected to a valid task", "error");
                return;
            }
        } else if (updateRadio.checked || otherRadio.checked) {
            // For "update" or "other" types, preserve the original activity's resModel and link_id
            // These types are only visible for existing activities that were synced from Odoo
            // and may be linked to models like sale.order, crm.lead, project.update, etc.
            if (currentActivity && currentActivity.resModel) {
                resModel = currentActivity.resModel;
                linkid = currentActivity.link_id || -1;
                resId = currentActivity.resId || 0;
                
                // Validate that we have valid linkage data
                if (!resModel || linkid <= 0) {
                    notifPopup.open("Error", "Cannot save activity: missing document connection. Please select Task or Project type.", "error");
                    return;
                }
            } else {
                notifPopup.open("Error", "Cannot save activity without a document connection. Please select Task or Project type.", "error");
                return;
            }
        } else {
            // No type selected - should not happen but handle gracefully
            notifPopup.open("Error", "Please select how this activity is connected (Task, Project, etc.)", "error");
            return;
        }

        // Use the selected assignee, or fall back to current user if no assignee selected
        const user = ids.assignee_id || Accounts.getCurrentUserOdooId(ids.account_id);
        if (!user) {
            notifPopup.open("Error", "Please select an assignee for this activity.", "error");
            return;
        }

        if (activityTypeSelector.selectedId === -1 || summary.text === "" || notes.text === "") {
            let message = activityTypeSelector.selectedId === -1 ? "You must specify the Activity type" : summary.text === "" ? "Please enter a summary" : "Please enter notes";
            notifPopup.open("Error", message, "error");
            return;
        }

        const data = {
            updatedAccount: ids.account_id,
            updatedActivity: activityTypeSelector.selectedId,
            updatedSummary: Utils.cleanText(summary.text),
            updatedUserId: user,
            updatedDate: date_widget.formattedDate(),
            updatedNote: Utils.cleanText(notes.text),
            resModel: resModel,
            resId: resId,
            link_id: linkid,
            task_id: null,
            state: "planned",
            project_id: null,
            status: "updated"
        };

        Utils.show_dict_data(data);

        const result = Activity.saveActivityData(data, recordid);
        if (!result.success) {
            notifPopup.open("Error", "Unable to save the Activity", "error");
        } else {
            hasBeenSaved = true;  // Mark that this activity has been properly saved
            formModified = false; // Reset form modification flag after successful save
            
            // Clear draft after successful save
            draftHandler.clearDraft();
            
            // Update original data in draft handler to reset baseline
            draftHandler.updateOriginalData();
            
            notifPopup.open("Saved", "Activity has been saved successfully", "success");
            // No navigation - stay on the same page like Timesheet.qml
            // User can use back button to return to list page
        }
    }

    onActiveChanged: {
    }

    onVisibleChanged: {

        if (visible) {
            // Update navigation tracking when Activities detail page becomes visible
            Global.setLastVisitedPage("Activities");

            // Reset the navigation tracking flag when page becomes visible
            navigatingToReadMore = false;

            // Reload activity data when page becomes visible
            // Skip if initializing (handled in Component.onCompleted) to prevent overwriting draft restoration
            // Also skip if we have unsaved changes/draft to prevent overwriting user work
            if (recordid != 0 && !isInitializing && !draftHandler.hasUnsavedChanges) {
                currentActivity = Activity.getActivityById(recordid, accountid);

                // Update all fields with the latest data
                summary.text = currentActivity.summary || "";
                notes.setContent(currentActivity.notes || "");
                date_widget.setSelectedDate(currentActivity.due_date);
                
                // Reload Activity Type selector with the saved value
                reloadActivityTypeSelector(currentActivity.account_id, currentActivity.activity_type_id);

                // Reset form modification flag after loading data
                formModified = false;
            } else {
            }

            if (Global.description_temporary_holder !== "" && Global.description_context === "activity_notes") {
                //Check if you are coming back from the ReadMore page
                
                // Temporarily set isInitializing to avoid triggering during setContent
                var wasInitializing = isInitializing;
                isInitializing = true;
                notes.setContent(Global.description_temporary_holder);
                isInitializing = wasInitializing;
                
                // Mark field as changed in draft handler (force this one, only if not read-only)
                if (!isReadOnly) {
                    draftHandler.markFieldChanged("notes", Global.description_temporary_holder);
                }
                
                Global.description_temporary_holder = "";
                Global.description_context = "";
            }
        } else {
            // Page becoming invisible - save draft if we have unsaved changes
            if (!isReadOnly && draftHandler.hasUnsavedChanges) {
                var result = draftHandler.saveDraft();
            } else {
            }

            // Page becoming invisible - only handle ReadMore cleanup
            var isNavigatingToReadMore = navigatingToReadMore || (Global.description_context === "activity_notes");

            // Clear global holders only if not navigating to ReadMore
            if (!isNavigatingToReadMore) {
                Global.description_temporary_holder = "";
                Global.description_context = "";
            }
        }
    }

    // Check for unsaved changes when page is being destroyed
    Component.onDestruction: {
        if (recordid > 0 && !hasBeenSaved && !isReadOnly) {
            var isUnsaved = Activity.isActivityUnsaved(accountid, recordid);
            if (isUnsaved)
            // Could potentially auto-save here or mark for recovery
            {}
        }
    }
}
