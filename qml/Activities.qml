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
import "../models/global.js" as Global
import "components"

// Ensure all required QML types are available
// QtQuick.Controls 2.2 provides RadioButton, TextArea, etc.
// QtQuick.Layouts 1.3 provides Row, Column, etc.

Page {
    id: activityDetailsPage
    title: "Activity"
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

    // Track if the activity has been saved at least once
    property bool hasBeenSaved: false
    // Track if we're navigating to ReadMorePage to avoid showing save dialog
    property bool navigatingToReadMore: false
    // Track if user has modified form fields
    property bool formModified: false
    
    header: PageHeader {
        id: header
        title: activityDetailsPage.title
        StyleHints {
            foregroundColor: "white"
            backgroundColor: LomiriColors.orange
            dividerColor: LomiriColors.slate
        }
        trailingActionBar.actions: [
            Action {
                iconSource: "images/save.svg"
                visible: !isReadOnly
                text: "Save"
                onTriggered: {
                    saveActivityData();
                }
            }
        ]
    }

    NotificationPopup {
        id: notifPopup
        width: units.gu(80)
        height: units.gu(80)
    }
    
    SaveDiscardDialog {
        id: saveDiscardDialog
        onSaveRequested: {
            console.log("💾 Activities.qml: Save requested from dialog");
            saveActivityData();
        }
        onDiscardRequested: {
            console.log("🗑️ Activities.qml: Discard requested from dialog");
            // Delete the unsaved activity and allow navigation
            if (recordid > 0 && !hasBeenSaved && !isReadOnly) {
                if (Activity.isActivityUnsaved(accountid, recordid)) {
                    console.log("🗑️ Discarding unsaved activity with ID:", recordid);
                    Activity.deleteActivity(accountid, recordid);
                }
            }
        }
        onCancelled: {
            console.log("❌ Activities.qml: Cancel requested from dialog");
            // User wants to stay and continue editing
            console.log("User cancelled save/discard dialog - they can navigate back to continue editing");
            notifPopup.open("Navigation", "You can navigate back to the Activity to continue editing", "info");
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
                            // Only reset activity type for new activities, not when loading existing ones
                            if (recordid === 0) {
                                reloadActivityTypeSelector(data.id, -1);
                            }
                        }
                    }
                }
            }
        }

        Row {
            id: row1w
            anchors.top: row1.bottom
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
                        text: "Connected to"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
            Column {
                id: myCol99w
                leftPadding: units.gu(3)
                RadioButton {
                    id: projectRadio
                    text: "Project"
                    checked: false
                    enabled: !isReadOnly
                    contentItem: Text {
                        text: projectRadio.text
                        color: theme.palette.normal.backgroundText
                        leftPadding: projectRadio.indicator.width + projectRadio.spacing
                        verticalAlignment: Text.AlignVCenter
                    }
                    onCheckedChanged: {
                        if (checked) {
                            taskRadio.checked = false;
                        }
                    }
                }

                RadioButton {
                    id: taskRadio
                    text: "Task"
                    checked: true
                    enabled: !isReadOnly
                    contentItem: Text {
                        text: taskRadio.text
                        color: theme.palette.normal.backgroundText
                        leftPadding: taskRadio.indicator.width + taskRadio.spacing
                        verticalAlignment: Text.AlignVCenter
                    }
                    onCheckedChanged: {
                        if (checked) {
                            projectRadio.checked = false;
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
                        text: "Summary"
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
                    textFormat: Text //Do not make this RichText
                    readOnly: isReadOnly
                    width: flickable.width < units.gu(361) ? flickable.width - units.gu(15) : flickable.width - units.gu(10)
                    height: units.gu(5) // Start with collapsed height
                    anchors.centerIn: parent.centerIn
                    text: currentActivity.summary

                    onTextChanged: {
                        if (text !== currentActivity.summary) {
                            formModified = true;
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
                anchors.fill: parent

                Item {
                    id: textAreaContainer
                    anchors.fill: parent
                    RichTextPreview {
                        id: notes
                        anchors.fill: parent
                        title: "Notes"
                        anchors.centerIn: parent.centerIn
                        text: ""
                        is_read_only: isReadOnly
                        onClicked: {
                            //set the data to a global Store and pass the key to the page
                            Global.description_temporary_holder = getFormattedText();
                            Global.description_context = "activity_notes";
                            navigatingToReadMore = true;
                            apLayout.addPageToNextColumn(activityDetailsPage, Qt.resolvedUrl("ReadMorePage.qml"), {
                                isReadOnly: isReadOnly
                                //useRichText: false
                            });
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
                    labelText: "Activity Type"
                    width: flickable.width - units.gu(2)
                    height: units.gu(29)
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
                }
            }
        }
    }

    Component.onCompleted: {
        console.log("🔍 Activities.qml: Component completed - recordid:", recordid, "accountid:", accountid, "isReadOnly:", isReadOnly);
        
        // Initialize form modification tracking
        formModified = false;
        
        if (recordid != 0) {
            currentActivity = Activity.getActivityById(recordid, accountid);
            currentActivity.user_name = Accounts.getUserNameByOdooId(currentActivity.user_id);

            let instanceId = currentActivity.account_id;
            let user_id = currentActivity.user_id;

            // Load the Activity Type
            reloadActivityTypeSelector(instanceId, currentActivity.activity_type_id);

            // Default radio selection
            taskRadio.checked = false;
            projectRadio.checked = false;

            // If project and subproject are the same, treat it as no subproject selected.
            if (currentActivity.project_id && currentActivity.project_id === currentActivity.sub_project_id) {
                currentActivity.sub_project_id = -1;
            }

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
            default:
                workItem.deferredLoadExistingRecordSet(instanceId, -1, -1, -1, -1, user_id);
            }

            // Update fields with loaded data
            summary.text = currentActivity.summary || "";
            notes.setContent(currentActivity.notes || "");

            // Update due date
            date_widget.setSelectedDate(currentActivity.due_date);

            // Check if this is a truly saved activity or a newly created one with default values
            hasBeenSaved = !Activity.isActivityUnsaved(accountid, recordid);
            console.log("🔍 Activity", recordid, "hasBeenSaved:", hasBeenSaved, "isUnsaved:", Activity.isActivityUnsaved(accountid, recordid));
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
            console.log("📝 Activities.qml: New activity creation mode");
        }
    }

    function reloadActivityTypeSelector(accountId, selectedTypeId) {
        //  console.log("->-> Loading Activity Types for account " + accountId);
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

            //   console.log("Checking Type:", id, name);

            if (selectedTypeId !== undefined && selectedTypeId !== null && selectedTypeId === id) {
                selectedText = name;
                selectedFound = true;
                // console.log("Selected Type Found:", selectedText);
            }
        }

        // Push to the model and reload selector
        activityTypeSelector.dataList = flatModel;
        activityTypeSelector.reload();

        // Update selected item
        activityTypeSelector.selectedId = selectedFound ? selectedTypeId : -1;
        activityTypeSelector.currentText = selectedFound ? selectedText : "Select Type";
    }

    function saveActivityData() {
        const ids = workItem.getIds();
        console.log("DEBUG Activities.qml - getIds() returned:", JSON.stringify(ids));

        var linkid = -1;
        var resId = 0;

        if (projectRadio.checked) {
            // Use subproject if selected, otherwise use main project
            linkid = ids.subproject_id || ids.project_id;
            resId = Accounts.getOdooModelId(ids.account_id, "Project");
            //   console.log("Project mode - linking to:", ids.subproject_id ? "subproject " + ids.subproject_id : "project " + ids.project_id);
        }

        if (taskRadio.checked) {
            linkid = ids.subtask_id || ids.task_id;
            resId = Accounts.getOdooModelId(ids.account_id, "Task");
            console.log("DEBUG Activities.qml - Task mode linkid:", linkid, "subtask_id:", ids.subtask_id, "task_id:", ids.task_id);
        }

        const resModel = projectRadio.checked ? "project.project" : taskRadio.checked ? "project.task" : "";

        if (typeof linkid === "undefined" || linkid === null || linkid <= 0 || resId === 0) {
            // console.log(linkid + "is the value of linkid");
            notifPopup.open("Error", "Activity must be connected to a project or task", "error");
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

        console.log("DEBUG Activities.qml - Final activity data before save:", JSON.stringify(data));
        Utils.show_dict_data(data);

        const result = Activity.saveActivityData(data, recordid);
        if (!result.success) {
            notifPopup.open("Error", "Unable to save the Activity", "error");
        } else {
            hasBeenSaved = true;  // Mark that this activity has been properly saved
            formModified = false; // Reset form modification flag after successful save
            notifPopup.open("Saved", "Activity has been saved successfully", "success");
            // No navigation - stay on the same page like Timesheet.qml
            // User can use back button to return to list page
        }
    }
    
    onActiveChanged: {
        console.log("🔍 Activities.qml: Active changed to:", active, "- recordid:", recordid, "hasBeenSaved:", hasBeenSaved, "isReadOnly:", isReadOnly, "formModified:", formModified);
    }
    
    onVisibleChanged: {
        console.log("� VISIBILITY CHANGED EVENT FIRED! visible =", visible);
        console.log("�🔍 Activities.qml: Visibility changed to:", visible, "- recordid:", recordid, "hasBeenSaved:", hasBeenSaved, "isReadOnly:", isReadOnly, "navigatingToReadMore:", navigatingToReadMore, "formModified:", formModified);
        
        if (visible) {
            // Reset the navigation tracking flag when page becomes visible
            navigatingToReadMore = false;
            
            // Reload activity data when page becomes visible
            if (recordid != 0) {
                currentActivity = Activity.getActivityById(recordid, accountid);
                console.log("📅 Activities.qml: Reloaded activity with due_date:", currentActivity.due_date);

                // Update all fields with the latest data
                summary.text = currentActivity.summary || "";
                notes.setContent(currentActivity.notes || "");
                date_widget.setSelectedDate(currentActivity.due_date);
                console.log("📅 Activities.qml: Set date widget to:", currentActivity.due_date);
                
                // Reset form modification flag after loading data
                formModified = false;
            }

            if (Global.description_temporary_holder !== "" && Global.description_context === "activity_notes") {
                //Check if you are coming back from the ReadMore page
                notes.setContent(Global.description_temporary_holder);
                Global.description_temporary_holder = "";
                Global.description_context = "";
            }
        } else {
            // Page is becoming invisible - check if we should show save/discard dialog
            console.log("🔍 Page becoming invisible - checking conditions");
            console.log("🔍 Debug values:");
            console.log("  - recordid:", recordid);
            console.log("  - hasBeenSaved:", hasBeenSaved);
            console.log("  - isReadOnly:", isReadOnly);
            console.log("  - navigatingToReadMore:", navigatingToReadMore);
            console.log("  - Global.description_context:", Global.description_context);
            console.log("  - formModified:", formModified);
            
            // Only show dialog if:
            // 1. We have an unsaved activity (recordid > 0 && !hasBeenSaved)
            // 2. We're not in read-only mode (!isReadOnly)
            // 3. We're NOT navigating to ReadMorePage (!navigatingToReadMore)
            // 4. Global context is not set for activity notes (additional check for ReadMorePage)
            var isNavigatingToReadMore = navigatingToReadMore || (Global.description_context === "activity_notes");
            
            console.log("🔍 Condition checks:");
            console.log("  - recordid > 0:", recordid > 0);
            console.log("  - !hasBeenSaved:", !hasBeenSaved);
            console.log("  - !isReadOnly:", !isReadOnly);
            console.log("  - !isNavigatingToReadMore:", !isNavigatingToReadMore);
            
            if (recordid > 0 && !hasBeenSaved && !isReadOnly && !isNavigatingToReadMore) {
                console.log("🔍 Passed initial conditions, checking unsaved state...");
                
                var isUnsaved = Activity.isActivityUnsaved(accountid, recordid);
                var shouldShowDialog = isUnsaved || formModified;
                
                console.log("🔍 Final check - isUnsaved:", isUnsaved, "formModified:", formModified, "shouldShowDialog:", shouldShowDialog);
                
                if (shouldShowDialog) {
                    console.log("⚠️ SHOWING SAVE/DISCARD DIALOG NOW!");
                    saveDiscardDialog.open();
                } else {
                    console.log("❌ Not showing dialog - shouldShowDialog is false");
                }
            } else {
                console.log("❌ Not showing dialog - initial conditions not met:");
                console.log("    recordid > 0:", recordid > 0);
                console.log("    !hasBeenSaved:", !hasBeenSaved);
                console.log("    !isReadOnly:", !isReadOnly);
                console.log("    !isNavigatingToReadMore:", !isNavigatingToReadMore);
            }
            
            // Clear global holders only if not navigating to ReadMore
            if (!isNavigatingToReadMore) {
                Global.description_temporary_holder = "";
                Global.description_context = "";
            }
        }
    }
    
    Component.onDestruction: {
        console.log("🔍 Activities.qml: Component being destroyed - recordid:", recordid, "hasBeenSaved:", hasBeenSaved, "isReadOnly:", isReadOnly, "formModified:", formModified);
        
        // Final check before page destruction
        if (recordid > 0 && !hasBeenSaved && !isReadOnly) {
            var shouldShowDialog = Activity.isActivityUnsaved(accountid, recordid) || formModified;
            
            if (shouldShowDialog) {
                console.log("⚠️ Component destruction: Activity has unsaved changes, showing save/discard dialog");
                saveDiscardDialog.open();
            }
        }
    }
}
