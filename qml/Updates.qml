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
import QtQuick.Layouts 1.3
import QtQuick.Window 2.2
import Qt.labs.settings 1.0
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.Components.Pickers 1.3
import "../models/utils.js" as Utils
import "../models/project.js" as Project
import "../models/accounts.js" as Accounts
import "../models/global.js" as Global
import "components"

Page {
    id: updateDetailsPage
    title: i18n.dtr("ubtms", "Project Update")
    
    property var recordid: 0
    property var accountid: 0
    property bool isReadOnly: true
    property var currentUpdate: {
        "name": "",
        "description": "",
        "project_status": "",
        "progress": 0,
        "project_id": -1,
        "user_id": -1,
        "date": ""
    }
    
    // Track if the update has been saved at least once
    property bool hasBeenSaved: false
    // Track if we're navigating to ReadMorePage
    property bool navigatingToReadMore: false
    // Flag to prevent tracking changes during initialization
    property bool isInitializing: true
    
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
        title: updateDetailsPage.title + (draftHandler.hasUnsavedChanges ? " •" : "")
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
                    saveUpdateData();
                }
            },
            Action {
                iconName: "edit"
                visible: isReadOnly && recordid !== 0
                text: i18n.dtr("ubtms", "Edit")
                onTriggered: {
                    switchToEditMode();
                }
            }
        ]
        
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
        draftType: "project_update"
        recordId: recordid
        accountId: accountid
        enabled: !isReadOnly
        autoSaveInterval: 30000 // 30 seconds
        
        onDraftLoaded: function(draftData, changedFields) {
            console.log("📝 Updates.qml: Draft loaded with", changedFields.length, "changed fields");
            
            // Restore form fields from draft (project and account are fixed, not editable)
            if (draftData.name !== undefined) {
                name_text.text = draftData.name;
            }
            if (draftData.description !== undefined) {
                description_text.setContent(draftData.description);
            }
            if (draftData.project_status !== undefined) {
                statusSelector.selectedStatus = draftData.project_status;
            }
            if (draftData.progress !== undefined) {
                progressSlider.value = draftData.progress;
            }
            
            // Show notification about draft
            notifPopup.open("Draft Restored", "Your unsaved changes have been restored", "info");
        }
        
        onDraftSaved: function(draftId) {
            console.log("💾 Updates.qml: Draft saved with ID:", draftId);
        }
        
        onDraftCleared: function() {
            console.log("🗑️ Updates.qml: Draft cleared");
        }
    }
    
    SaveDiscardDialog {
        id: saveDiscardDialog
        onSaveRequested: {
            saveUpdateData();
            // After successful save, navigate back
            if (hasBeenSaved) {
                navigateBack();
            }
        }
        onDiscardRequested: {
            // For new updates that haven't been saved, delete them
            if (recordid > 0 && !hasBeenSaved && !isReadOnly) {
                Project.markProjectUpdateAsDeleted(recordid);
            }
            
            // For edit mode, restore to original read-only state
            if (recordid > 0 && hasBeenSaved) {
                restoreFormToOriginal();
                isReadOnly = true;
            }
            
            // Clear draft when discarding
            draftHandler.clearDraft();
            navigateBack();
        }
        onCancelled: {
            // User wants to stay and continue editing
        }
    }
    
    function restoreFormToOriginal() {
        console.log("🔄 Restoring form to original values...");
        
        var originalData = draftHandler.originalData;
        if (originalData.name !== undefined) name_text.text = originalData.name;
        if (originalData.description !== undefined) description_text.setContent(originalData.description);
        if (originalData.project_status !== undefined) statusSelector.selectedStatus = originalData.project_status;
        if (originalData.progress !== undefined) progressSlider.value = originalData.progress;
    }
    
    Flickable {
        id: flickable
        anchors.fill: parent
        anchors.topMargin: units.gu(6)
        contentHeight: parent.height + units.gu(100)
        flickableDirection: Flickable.VerticalFlick
        
        width: parent.width
        
        Column {
            width: parent.width
            spacing: units.gu(2)
            topPadding: units.gu(2)
            
            // Project Info (Read-only display)
            Row {
                width: parent.width
                leftPadding: units.gu(1)
                
                Column {
                    width: parent.width - units.gu(2)
                    spacing: units.gu(1)
                    
                    // Account Display
                    Row {
                        width: parent.width
                        spacing: units.gu(1)
                        
                        TSLabel {
                            text: i18n.dtr("ubtms", "Account:")
                            width: units.gu(12)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Text {
                            text: Accounts.getAccountName(currentUpdate.account_id) || i18n.dtr("ubtms", "Unknown Account")
                            font.pixelSize: units.gu(2)
                            width: parent.width - units.gu(13)
                            anchors.verticalCenter: parent.verticalCenter
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                        }
                    }
                    
                    // Project Display
                    Row {
                        width: parent.width
                        spacing: units.gu(1)
                        
                        TSLabel {
                            text: i18n.dtr("ubtms", "Project:")
                            width: units.gu(12)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Text {
                            text: Project.getProjectName(currentUpdate.project_id, currentUpdate.account_id) || i18n.dtr("ubtms", "Unknown Project")
                            font.pixelSize: units.gu(2)
                            width: parent.width - units.gu(13)
                            anchors.verticalCenter: parent.verticalCenter
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
            
            // Update Name
            Row {
                width: parent.width
                leftPadding: units.gu(1)
                
                Column {
                    width: parent.width - units.gu(2)
                    
                    TSLabel {
                        text: i18n.dtr("ubtms", "Update Title")
                        width: parent.width
                    }
                    
                    TextArea {
                        id: name_text
                        textFormat: Text.PlainText
                        readOnly: isReadOnly
                        width: parent.width
                        height: units.gu(5)
                        text: currentUpdate.name
                        
                        onTextChanged: {
                            if (!isInitializing) {
                                draftHandler.markFieldChanged("name", text);
                            }
                        }
                        
                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            radius: units.gu(0.5)
                            border.width: parent.activeFocus ? units.gu(0.2) : units.gu(0.1)
                            border.color: parent.activeFocus ? LomiriColors.orange : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#d3d1d1" : "#999")
                        }
                    }
                }
            }
            
            // Status Selector
            Row {
                width: parent.width
                leftPadding: units.gu(1)
                
                Column {
                    width: parent.width - units.gu(2)
                    
                    TSLabel {
                        text: i18n.dtr("ubtms", "Project Status")
                        width: parent.width
                    }
                    
                    StatusSelector {
                        id: statusSelector
                        readOnly: isReadOnly
                        width: parent.width
                        onStatusChanged: {
                            if (!isInitializing) {
                                draftHandler.markFieldChanged("project_status", selectedStatus);
                            }
                        }
                    }
                }
            }
            
            // Progress Slider
            Row {
                width: parent.width
                leftPadding: units.gu(1)
                
                Column {
                    width: parent.width - units.gu(2)
                    
                    Row {
                        width: parent.width
                        
                        TSLabel {
                            text: i18n.dtr("ubtms", "Progress")
                            width: parent.width * 0.7
                        }
                        
                        Text {
                            text: progressSlider.value + "%"
                            font.pixelSize: units.gu(2)
                            width: parent.width * 0.3
                            horizontalAlignment: Text.AlignRight
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                        }
                    }
                    
                    Slider {
                        id: progressSlider
                        width: parent.width
                        minimumValue: 0
                        maximumValue: 100
                        stepSize: 5
                        value: currentUpdate.progress
                        enabled: !isReadOnly
                        live: true
                        
                        onValueChanged: {
                            if (!isInitializing) {
                                draftHandler.markFieldChanged("progress", value);
                            }
                        }
                    }
                }
            }
            
            // Description
            Row {
                width: parent.width
                leftPadding: units.gu(1)
                height: units.gu(30)
                
                Column {
                    width: parent.width - units.gu(2)
                    height: parent.height
                    
                    Item {
                        width: parent.width
                        height: parent.height
                        
                        RichTextPreview {
                            id: description_text
                            anchors.fill: parent
                            title: i18n.dtr("ubtms", "Description")
                            text: ""
                            is_read_only: isReadOnly
                            onClicked: {
                                Global.description_temporary_holder = description_text.getFormattedText();
                                Global.description_context = "update_description";
                                navigatingToReadMore = true;
                                apLayout.addPageToNextColumn(updateDetailsPage, Qt.resolvedUrl("ReadMorePage.qml"), {
                                    isReadOnly: isReadOnly
                                });
                            }
                            onContentChanged: function(content) {
                                if (!isInitializing) {
                                    draftHandler.markFieldChanged("description", content);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Timer to end initialization phase
    Timer {
        id: initializationTimer
        interval: 500
        repeat: false
        onTriggered: {
            isInitializing = false;
            console.log("🎯 Updates.qml: Initialization complete, draft tracking now active");
        }
    }
    
    function switchToEditMode() {
        if (recordid !== 0) {
            console.log("🔄 Updates.qml: Switching to edit mode");
            isReadOnly = false;
            
            var originalUpdateData = getCurrentFormData();
            draftHandler.initialize(originalUpdateData);
        }
    }
    
    function getCurrentFormData() {
        var formData = {
            name: name_text.text || "",
            description: description_text.getFormattedText() || "",
            project_status: statusSelector.selectedStatus || "",
            progress: progressSlider.value || 0,
            account_id: currentUpdate.account_id || 0,
            project_id: currentUpdate.project_id || -1,
            user_id: currentUpdate.user_id || -1
        };
        
        return formData;
    }
    
    function navigateBack() {
        console.log("🔙 Attempting to navigate back...");
        
        try {
            if (typeof apLayout !== "undefined" && apLayout !== null) {
                apLayout.removePages(updateDetailsPage);
                console.log("✅ Navigated back using apLayout.removePages");
                return;
            }
        } catch (e) {
            console.warn("⚠️ apLayout.removePages failed:", e);
        }
        
        try {
            if (typeof pageStack !== "undefined" && pageStack && pageStack.pop) {
                pageStack.pop();
                console.log("✅ Navigated back using pageStack.pop");
                return;
            }
        } catch (e) {
            console.warn("⚠️ pageStack.pop failed:", e);
        }
        
        console.warn("⚠️ No navigation method found!");
    }
    
    function saveUpdateData() {
        if (!currentUpdate.project_id || currentUpdate.project_id <= 0) {
            notifPopup.open("Error", "Project is required", "error");
            return;
        }
        
        if (name_text.text.trim() === "") {
            notifPopup.open("Error", "Please enter an update title", "error");
            return;
        }
        
        if (!statusSelector.selectedStatus) {
            notifPopup.open("Error", "Please select a project status", "error");
            return;
        }
        
        const updateData = {
            account_id: currentUpdate.account_id,
            project_id: currentUpdate.project_id,
            name: Utils.cleanText(name_text.text),
            project_status: statusSelector.selectedStatus,
            progress: progressSlider.value,
            description: Utils.cleanText(description_text.getFormattedText()),
            user_id: currentUpdate.user_id || Accounts.getCurrentUserOdooId(currentUpdate.account_id)
        };
        
        console.log("💾 Saving update data:", JSON.stringify(updateData));
        
        const result = Project.createUpdateSnapShot(updateData);
        if (!result.is_success) {
            notifPopup.open("Error", "Unable to save the Project Update", "error");
        } else {
            hasBeenSaved = true;
            
            // Clear draft after successful save
            draftHandler.clearDraft();
            
            // Update original data in draft handler
            draftHandler.updateOriginalData();
            
            notifPopup.open("Saved", "Project Update has been saved successfully", "success");
        }
    }
    
    Component.onCompleted: {
        isInitializing = true;
        
        if (recordid != 0) {
            // Load existing update
            currentUpdate = Project.getProjectUpdateById(recordid, accountid);
            hasBeenSaved = true;
            
            // Initialize draft handler with original data
            draftHandler.initialize({
                name: currentUpdate.name || "",
                description: currentUpdate.description || "",
                project_status: currentUpdate.project_status || "",
                progress: currentUpdate.progress || 0,
                account_id: currentUpdate.account_id || 0,
                project_id: currentUpdate.project_id || -1,
                user_id: currentUpdate.user_id || -1
            });
            
            // If no draft was loaded, load the update data normally
            if (!draftHandler.hasUnsavedChanges) {
                name_text.text = currentUpdate.name || "";
                description_text.setContent(currentUpdate.description || "");
                statusSelector.selectedStatus = currentUpdate.project_status || "";
                progressSlider.value = currentUpdate.progress || 0;
            }
        } else {
            // New update - currentUpdate should be pre-populated with project context
            hasBeenSaved = false;
            
            // Ensure we have valid project context for new updates
            if (!currentUpdate.project_id || currentUpdate.project_id <= 0) {
                console.warn("⚠️ Creating update without project context!");
            }
            
            draftHandler.initialize({
                name: currentUpdate.name || "",
                description: currentUpdate.description || "",
                project_status: currentUpdate.project_status || "on_track",
                progress: currentUpdate.progress || 0,
                account_id: currentUpdate.account_id || 0,
                project_id: currentUpdate.project_id || -1,
                user_id: currentUpdate.user_id || -1
            });
            
            // Set initial values
            name_text.text = "";
            description_text.setContent("");
            statusSelector.selectedStatus = "on_track";
            progressSlider.value = 0;
        }
        
        // Start timer to end initialization phase
        initializationTimer.start();
    }
    
    onVisibleChanged: {
        if (visible) {
            Global.setLastVisitedPage("Updates");
            navigatingToReadMore = false;
            
            if (recordid != 0) {
                currentUpdate = Project.getProjectUpdateById(recordid, accountid);
            }
            
            if (Global.description_temporary_holder !== "" && Global.description_context === "update_description") {
                var wasInitializing = isInitializing;
                isInitializing = true;
                description_text.setContent(Global.description_temporary_holder);
                isInitializing = wasInitializing;
                
                draftHandler.markFieldChanged("description", Global.description_temporary_holder);
                
                Global.description_temporary_holder = "";
                Global.description_context = "";
            }
        } else {
            var isNavigatingToReadMore = navigatingToReadMore || (Global.description_context === "update_description");
            
            if (!isNavigatingToReadMore) {
                Global.description_temporary_holder = "";
                Global.description_context = "";
            }
        }
    }
}
