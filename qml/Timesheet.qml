/*
 * MIT License
 *
 * Copyright (c) 2025 CIT-Services
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, publish, distribute, sublicense, and/or sell
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
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.Components.Pickers 1.3
import QtCharts 2.0
import QtQuick.Window 2.2
import Qt.labs.settings 1.0
import "../models/timesheet.js" as Model
import "../models/accounts.js" as Accounts
import "../models/timer_service.js" as TimerService
import "../models/utils.js" as Utils
import "../models/global.js" as Global
import "components"

Page {
    id: timeSheet
    title: i18n.dtr("ubtms", "Timesheet")
    
    // Handle hardware back button
    Keys.onReleased: {
        if (event.key === Qt.Key_Escape || event.key === Qt.Key_Back) {
            handleBackNavigation();
            event.accepted = true;
        }
    }
    
    header: PageHeader {
        id: tsHeader
        StyleHints {
            foregroundColor: "white"

            backgroundColor: LomiriColors.orange
            dividerColor: LomiriColors.slate
        }

        title: timeSheet.title + (draftHandler.hasUnsavedChanges ? " •" : "")

        // Custom back button with unsaved changes check
        leadingActionBar.actions: [
            Action {
                iconName: "back"
                text: "Back"
                onTriggered: {
                    handleBackNavigation();
                }
            }
        ]

        trailingActionBar.actions: [
            Action {
                iconSource: "images/save.svg"
                visible: !isReadOnly
                text: "Save"
                onTriggered: {
                    save_timesheet();
                }
            },
            Action {
                iconName: "edit"
                visible: isReadOnly && recordid !== 0
                text: "Edit"
                onTriggered: {
                    switchToEditMode();
                }
            }
        ]
    }

    function save_timesheet(skipNavigation) {
        let time = time_sheet_widget.elapsedTime;

        const currentStatus = getCurrentTimesheetStatus();

        if (currentStatus === "updated") {
            const savedTime = Model.getTimesheetUnitAmount(recordid);
            time = Utils.convertDecimalHoursToHHMM(savedTime);
            console.log("Using finalized time from database:", time);
        } else if (recordid === TimerService.getActiveTimesheetId() && TimerService.isRunning()) {
            time = TimerService.stop();
            console.log("Timer stopped during save, final time:", time);
        }

        const ids = workItem.getIds();
        const user = Accounts.getCurrentUserOdooId(ids.account_id);

        if (!user) {
            notifPopup.open("Error", "Unable to find the user, cannot save", "error");
            return false;
        }

        if (ids.project_id === null) {
            notifPopup.open("Error", "You need to select a project to save timesheet", "error");
            return false;
        }

        if (ids.task_id === null) {
            notifPopup.open("Error", "You need to select a task to save timesheet", "error");
            return false;
        }

        let correctTaskId;
        let correctSubTaskId = null;

        if (ids.subtask_id !== null && ids.subtask_id !== undefined && ids.subtask_id !== -1 && ids.subtask_id > 0) {
            correctTaskId = ids.subtask_id;
            correctSubTaskId = null;
        } else {
            correctTaskId = ids.task_id;
            correctSubTaskId = ids.subtask_id;
        }

        var timesheet_data = {
            'record_date': date_widget.formattedDate(),
            'instance_id': ids.account_id < 0 ? 0 : ids.account_id,
            'project': ids.project_id,
            'task': correctTaskId,
            'subTask': correctSubTaskId,
            'subprojectId': ids.subproject_id,
            'description': description_text.text,
            'unit_amount': Utils.convertHHMMtoDecimalHours(time),
            'quadrant': priorityGrid.currentIndex + 1,
            'user_id': user,
            'status': "draft"
        };
        if (recordid && recordid !== 0) {
            timesheet_data.id = recordid;
        }

        const result = Model.saveTimesheet(timesheet_data);
        if (!result.success) {
            notifPopup.open("Error", "Unable to Save the Timesheet: " + result.error, "error");
            return false;
        } else {
            notifPopup.open("Saved", "Timesheet has been saved successfully", "success");
            
            // Clear draft after successful save
            draftHandler.clearDraft();
            
            time_sheet_widget.elapsedTime = time;
            
            // Navigate back to list view after successful save (unless skipNavigation is true)
            if (!skipNavigation) {
                navigateBack();
            }
            
            return true;
        }
    }

    function getCurrentTimesheetStatus() {
        if (recordid <= 0)
            return "new";

        try {
            const details = Model.getTimeSheetDetails(recordid);
            return details.status || "draft";
        } catch (e) {
            console.error("Failed to get timesheet status:", e);
            return "draft";
        }
    }

    function switchToEditMode() {
        if (recordid !== 0) {
            isReadOnly = false;
            
            // Initialize draft handler when switching from read-only to edit mode
            // This ensures drafts are loaded if they exist
            var originalTimesheetData = getCurrentFormData();
            draftHandler.initialize(originalTimesheetData);
        }
    }

    property bool isManualTime: false
    property bool running: false
    property int selectedSubTaskId: 0
    property var recordid: 0 //0 means creation mode
    property bool isReadOnly: false // Can be overridden when page is opened
    property var currentTimesheet: {}

    // ==================== DRAFT HANDLER ====================
    FormDraftHandler {
        id: draftHandler
        draftType: "timesheet"
        recordId: timeSheet.recordid
        accountId: (currentTimesheet && currentTimesheet.account_id) ? currentTimesheet.account_id : 0
        enabled: !isReadOnly
        autoSaveInterval: 3000
        
        Component.onCompleted: {
            console.log("🔧 Timesheet DraftHandler created - enabled:", enabled, "recordId:", recordId, "accountId:", accountId, "isReadOnly:", isReadOnly);
        }
        
        onEnabledChanged: {
            console.log("🔧 DraftHandler enabled changed to:", enabled, "isReadOnly:", isReadOnly);
        }
        
        onDraftLoaded: {
            restoreFormFromDraft(draftData);
            notifPopup.open("📂 Draft Restored", 
                "Unsaved changes restored: " + getChangesSummary(), 
                "info");
        }
        
        onUnsavedChangesWarning: {
            PopupUtils.open(unsavedChangesDialog);
        }
        
        onDraftSaved: {
            console.log("💾 Timesheet draft saved successfully (ID: " + draftId + ")");
        }
    }

    // Save/Discard dialog for back navigation
    SaveDiscardDialog {
        id: unsavedChangesDialog
        
        onSaveRequested: {
            console.log("💾 SaveDiscardDialog: Saving timesheet...");
            var success = save_timesheet(true); // true = skip automatic navigation
            // Only navigate back if save was successful
            if (success) {
                Qt.callLater(navigateBack);
            }
        }
        
        onDiscardRequested: {
            console.log("🗑️ SaveDiscardDialog: Discarding changes...");
            draftHandler.clearDraft();
            Qt.callLater(navigateBack);
        }
        
        onCancelled: {
            console.log("❌ User cancelled navigation");
        }
    }

    // Handle back navigation with unsaved changes check
    function handleBackNavigation() {
        if (draftHandler.hasUnsavedChanges) {
            unsavedChangesDialog.open("timesheet");
        } else {
            navigateBack();
        }
    }

    // Helper function to navigate back
    function navigateBack() {
        console.log("🔙 Attempting to navigate back...");
        
        // Method 1: AdaptivePageLayout (primary method for this app)
        try {
            if (typeof apLayout !== "undefined" && apLayout && apLayout.removePages) {
                console.log("✅ Navigating via apLayout.removePages()");
                apLayout.removePages(timeSheet);
                return;
            }
        } catch (e) {
            console.error("❌ apLayout navigation error:", e);
        }
        
        // Method 2: Standard pageStack
        try {
            if (pageStack && typeof pageStack.pop === 'function') {
                console.log("✅ Navigating via pageStack.pop()");
                pageStack.pop();
                return;
            }
        } catch (e) {
            console.error("❌ Navigation error with pageStack:", e);
        }
        
        // Method 3: Parent pop
        try {
            if (parent && typeof parent.pop === 'function') {
                console.log("✅ Navigating via parent.pop()");
                parent.pop();
                return;
            }
        } catch (e) {
            console.error("❌ Parent navigation error:", e);
        }
        
        console.warn("⚠️ No navigation method found!");
    }

    // Track navigation to ReadMore page
    property bool navigatingToReadMore: false

    function restoreFormFromDraft(draftData) {
        console.log("🔄 Restoring timesheet from draft data...");
        
        if (draftData.description) description_text.setContent(draftData.description);
        if (draftData.date) date_widget.setDate(draftData.date);
        if (draftData.quadrant !== undefined) priorityGrid.currentIndex = draftData.quadrant;
        if (draftData.elapsedTime) time_sheet_widget.elapsedTime = draftData.elapsedTime;
    }
    
    function getCurrentFormData() {
        const ids = workItem.getIds();
        return {
            description: description_text.getFormattedText ? description_text.getFormattedText() : description_text.text,
            date: date_widget.formattedDate ? date_widget.formattedDate() : "",
            quadrant: priorityGrid.currentIndex,
            elapsedTime: time_sheet_widget.elapsedTime,
            projectId: ids.project_id,
            taskId: ids.task_id
        };
    }

    NotificationPopup {
        id: notifPopup
        width: units.gu(80)
        height: units.gu(80)
    }

    Flickable {
        id: timesheetsDetailsPageFlickable
        anchors.topMargin: units.gu(6)
        anchors.fill: parent
        contentHeight: parent.height + units.gu(50)
        flickableDirection: Flickable.VerticalFlick

        width: parent.width

        Row {
            id: myRow1a
            anchors.left: parent.left
            topPadding: units.gu(5)

            Column {
                leftPadding: units.gu(1)

                WorkItemSelector {
                    id: workItem
                    readOnly: isReadOnly
                    showAssigneeSelector: false
                    showAccountSelector: true
                    showProjectSelector: true
                    showSubProjectSelector: true
                    showTaskSelector: true
                    showSubTaskSelector: true
                    width: timesheetsDetailsPageFlickable.width - units.gu(2)
                    // height: units.gu(29) // Uncomment if you need fixed height
                    
                    // Track changes for draft management
                    onStateChanged: {
                        if (draftHandler.enabled && draftHandler._initialized) {
                            var ids = workItem.getIds();
                            draftHandler.markFieldChanged("projectId", ids.project_id);
                            draftHandler.markFieldChanged("taskId", ids.task_id);
                            console.log("📝 WorkItemSelector changed - tracking for draft");
                        }
                    }
                }
            }
        }

        Column {
            id: myRow7
            anchors.top: myRow1a.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: units.gu(1)
            anchors.rightMargin: units.gu(1)
            spacing: units.gu(1)
            topPadding: units.gu(2)

            Row {
                spacing: units.gu(1.5)

                Label {
                    id: priority_label
                    text: "Priority"
                    width: units.gu(7)
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                }

                Icon {
                    id: helpIcon
                    name: "help"
                    width: units.gu(2.5)
                    height: units.gu(2.5)
                    color: theme.palette.normal.backgroundText
                    anchors.verticalCenter: priority_label.verticalCenter
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            notifPopup.open("Priority Help", "What Is Important Is Seldom Urgent, and What Is Urgent Is Seldom Important.<br><br><b>1. Important & Urgent:</b><br>Here you write down important activities, which also have to be done immediately. These are urgent problems or projects with a hard deadline. I.e. If you manage a restaurant and an employee has not shown up, it is a rather urgent and acute problem. All signals are on red, so this is a typical activity for the first quadrant.<br><br><b>2. Important & Not Urgent:</b><br>If you leave the activities in this quadrant for the coming week, nothing will immediately go wrong. But be careful: These are activities and projects that will help you in the long term. Think of thinking about a strategy, improving work processes in your team, investing in relationships and investing in yourself. i.e. You are a team leader who has just been told during his performance review that more creative input is expected. Such an outcome of a performance review is an assignment that will never feel urgent, but is very important. You can quickly recognize the important & non-urgent activities by answering the question: if I don't do this, will it get me into trouble in the long run? If the answer is yes, then you have an important & non-urgent activity. If the answer is no, then it is a non-important & non-urgent activity.<br><br><b>3. Urgent & Not Important:</b><br>This quadrant concerns activities that do not help you in the long run, but that are screaming for your attention this week. An adjustment in a presentation that has to be done for a colleague on the spur of the moment or the milk that is almost empty. With tasks in this quadrant it is very important to check whether they are actually urgent. Requests from others in particular often seem very urgent, while they can sometimes wait a day or a week. It is usually fine to postpone this work to a more suitable moment, provided that I communicate well about this. If you have the opportunity to delegate or outsource these tasks in this quadrant, do so. If you work for yourself, this is not always possible. In that case, I advise you to organize your working day in such a way that you are guided as little as possible by these urgent tasks, if necessary by reserving a fixed time block each day for these types of emergencies. That way you keep control over your agenda.<br><br><b>4. Not Important & Not Urgent:</b><br>This type of work that you want to have on your plate as little as possible, because it does not help you in any way. Constantly refreshing your mailbox, for example. But meetings without a clear goal also fall into this category. You can undoubtedly point out more of these types of 'busy work' examples yourself: things that you do, but that do not really benefit anyone. Sometimes these activities are a great short break from your work, but usually they are a great excuse to postpone your important work for a while.", "info");
                        }
                    }
                }
            }

            Grid {
                id: priorityGrid
                columns: 2
                spacing: units.gu(0.5)
                width: parent.width - units.gu(2)

                property int currentIndex: 0
                
                onCurrentIndexChanged: {
                    console.log("📝 Quadrant changed to:", currentIndex, "enabled:", draftHandler.enabled, "initialized:", draftHandler._initialized);
                    if (draftHandler.enabled && draftHandler._initialized) {
                        draftHandler.markFieldChanged("quadrant", currentIndex);
                        console.log("✅ Tracked quadrant change");
                    }
                }

                RadioButton {
                    id: priority1
                    text: "Important, Urgent (1)"
                    enabled: !isReadOnly
                    checked: priorityGrid.currentIndex === 0
                    contentItem: Text {
                        text: priority1.text
                        font.pixelSize: units.gu(1.5)
                        color: theme.palette.normal.backgroundText
                        leftPadding: priority1.indicator.width + priority1.spacing
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.WordWrap
                    }
                    onCheckedChanged: {
                        if (checked)
                            priorityGrid.currentIndex = 0;
                    }
                }

                RadioButton {
                    id: priority2
                    text: "Important, Not Urgent (2)"
                    enabled: !isReadOnly
                    checked: priorityGrid.currentIndex === 1
                    contentItem: Text {
                        text: priority2.text
                        font.pixelSize: units.gu(1.5)
                        color: theme.palette.normal.backgroundText
                        leftPadding: priority2.indicator.width + priority2.spacing
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.WordWrap
                    }
                    onCheckedChanged: {
                        if (checked)
                            priorityGrid.currentIndex = 1;
                    }
                }

                RadioButton {
                    id: priority3
                    text: "Urgent, Not Important (3)"
                    enabled: !isReadOnly
                    checked: priorityGrid.currentIndex === 2
                    contentItem: Text {
                        font.pixelSize: units.gu(1.5)
                        text: priority3.text
                        color: theme.palette.normal.backgroundText
                        leftPadding: priority3.indicator.width + priority3.spacing
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.WordWrap
                    }
                    onCheckedChanged: {
                        if (checked)
                            priorityGrid.currentIndex = 2;
                    }
                }

                RadioButton {
                    id: priority4
                    text: "Not Urgent, Not Important (4)"
                    enabled: !isReadOnly
                    checked: priorityGrid.currentIndex === 3
                    contentItem: Text {
                        text: priority4.text
                        font.pixelSize: units.gu(1.5)
                        color: theme.palette.normal.backgroundText
                        leftPadding: priority4.indicator.width + priority4.spacing
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.WordWrap
                    }
                    onCheckedChanged: {
                        if (checked)
                            priorityGrid.currentIndex = 3;
                    }
                }
            }
        }

        Row {
            id: time_sheet_row
            anchors.top: myRow7.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: units.gu(1)
            anchors.rightMargin: units.gu(1)
            spacing: units.gu(2)
            topPadding: units.gu(1)
            height: recordid ? units.gu(20) : units.gu(5)
            TimeRecorderWidget {
                id: time_sheet_widget
                enabled: !isReadOnly
                anchors.fill: time_sheet_row
                timesheetId: recordid
                visible: recordid
                onInvalidtimesheet: {
                    notifPopup.open("Error", "Save the time sheet first", "error");
                }
                
                // Track elapsed time changes for draft management
                onElapsedTimeChanged: {
                    if (draftHandler.enabled && draftHandler._initialized) {
                        draftHandler.markFieldChanged("elapsedTime", elapsedTime);
                    }
                }
            }
            Label {
                anchors.fill: parent
                anchors.margins: units.gu(1)
                anchors.horizontalCenter: parent.horizontalCenter
                visible: !recordid
                text: "Please save the timesheet before recording your working hours."
                color: "red"
                font.italic: true
            }
        }
        Row {
            id: myRow1
            anchors.top: time_sheet_row.bottom
            anchors.left: parent.left
            Column {
                leftPadding: units.gu(1)
                DaySelector {
                    id: date_widget
                    readOnly: isReadOnly
                    width: timesheetsDetailsPageFlickable.width - units.gu(2)
                    height: units.gu(5)
                    anchors.centerIn: parent.centerIn
                    
                    onDateChanged: {
                        console.log("📅 Date changed, enabled:", draftHandler.enabled, "initialized:", draftHandler._initialized);
                        if (draftHandler.enabled && draftHandler._initialized) {
                            draftHandler.markFieldChanged("date", formattedDate());
                            console.log("✅ Tracked date change to:", formattedDate());
                        }
                    }
                }
            }
        }

        /**********************************************************/

        Row {
            id: myRow9
            anchors.top: myRow1.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            topPadding: units.gu(5)

            Column {
                id: myCol9

                Item {
                    id: textAreaContainer
                    width: timesheetsDetailsPageFlickable.width
                    height: description_text.height

                    RichTextPreview {
                        id: description_text
                        width: parent.width
                        height: units.gu(20) // Start with collapsed height
                        anchors.centerIn: parent.centerIn
                        text: ""
                        is_read_only: isReadOnly
                        useRichText: false
                        onClicked: {
                            //set the data to a global store and pass the key to the page
                            Global.description_temporary_holder = getFormattedText();
                            apLayout.addPageToNextColumn(timeSheet, Qt.resolvedUrl("ReadMorePage.qml"), {
                                isReadOnly: isReadOnly,
                                useRichText: false
                            });
                        }
                        
                        // Track inline text changes for draft management
                        onTextChanged: {
                            console.log("📝 Description text changed (inline), enabled:", draftHandler.enabled, "initialized:", draftHandler._initialized);
                            if (draftHandler.enabled && draftHandler._initialized) {
                                draftHandler.markFieldChanged("description", getFormattedText());
                                console.log("✅ Tracked description change");
                            }
                        }
                    }
                }
            }
        }

        Component.onCompleted: {
            // console.log("Timesheet onCompleted - recordid:", recordid, "isReadOnly:", isReadOnly);

            if (recordid != 0) {
                // Set flag before loading to prevent auto-initialization
                workItem.deferredLoadingPlanned = true;

                currentTimesheet = Model.getTimeSheetDetails(recordid);
                let instanceId = (currentTimesheet.instance_id !== undefined && currentTimesheet.instance_id !== null) ? currentTimesheet.instance_id : -1;
                let projectId = (currentTimesheet.project_id !== undefined && currentTimesheet.project_id !== null) ? currentTimesheet.project_id : -1;
                let taskId = (currentTimesheet.task_id !== undefined && currentTimesheet.task_id !== null) ? currentTimesheet.task_id : -1;
                let subProjectId = (currentTimesheet.sub_project_id !== undefined && currentTimesheet.sub_project_id !== null) ? currentTimesheet.sub_project_id : -1;
                let subTaskId = (currentTimesheet.sub_task_id !== undefined && currentTimesheet.sub_task_id !== null) ? currentTimesheet.sub_task_id : -1;

                //    console.log("Timesheet data - instanceId:", instanceId, "projectId:", projectId, "taskId:", taskId);

                // Check if this is a newly created timesheet (has recordid but no project/task data)
                if (projectId === -1 && taskId === -1) {
                    // console.log("NEW timesheet - loading with account only");
                    // For new timesheets, load with account but no project/task data
                    workItem.deferredLoadExistingRecordSet(instanceId, -1, -1, -1, -1, -1);
                } else {
                    //  console.log("EXISTING timesheet - loading with full data");
                    workItem.deferredLoadExistingRecordSet(instanceId, projectId, subProjectId, taskId, subTaskId, -1);
                    console.log("Loaded existing timesheet with recordid:", recordid, "instanceId:", instanceId, "projectId:", projectId, "taskId:", taskId, "subProjectId:", subProjectId, "subTaskId:", subTaskId);
                }

                date_widget.setSelectedDate(currentTimesheet.record_date);
                description_text.setContent(currentTimesheet.name);
                if (currentTimesheet.spentHours && currentTimesheet.spentHours !== "") {
                    time_sheet_widget.elapsedTime = currentTimesheet.spentHours;
                }
                if (currentTimesheet.quadrant_id && currentTimesheet.quadrant_id !== "") {
                    priorityGrid.currentIndex = parseInt(currentTimesheet.quadrant_id) - 1;
                }
                if (currentTimesheet.timer_type && currentTimesheet.timer_type !== "") {
                    time_sheet_widget.autoMode = (currentTimesheet.timer_type === "automatic");
                }
            } else {
                //  console.log("NO recordid - calling loadAccounts()");
                workItem.loadAccounts();
                console.log("New timesheet - loading accounts for creation mode");
            }
            
            // Initialize draft handler AFTER all form fields are populated
            console.log("🔍 Timesheet Component.onCompleted - isReadOnly:", isReadOnly, "draftHandler.enabled:", draftHandler.enabled);
            if (!isReadOnly) {
                var originalTimesheetData = getCurrentFormData();
                console.log("🎯 Calling draftHandler.initialize() with data:", JSON.stringify(originalTimesheetData));
                draftHandler.initialize(originalTimesheetData);
            } else {
                console.log("⚠️ Skipping draft initialization - form is read-only");
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            if (Global.description_temporary_holder !== "") {
                //Check if you are coming back from the ReadMore page
                description_text.setContent(Global.description_temporary_holder);
                Global.description_temporary_holder = "";
                
                // Track description change for draft
                if (draftHandler.enabled) {
                    draftHandler.markFieldChanged("description", description_text.getFormattedText());
                }
            }
        }
        // Don't clear Global.description_temporary_holder when page becomes invisible
        // as it might be needed by the ReadMore page
    }
}
