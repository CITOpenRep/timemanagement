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
    Flickable {
        id: flickable
        anchors.fill: parent
        anchors.topMargin: units.gu(6)
        contentHeight: descriptionExpanded ? parent.height + 1600 : parent.height + 550
        flickableDirection: Flickable.VerticalFlick

        width: parent.width

        Row {
            id: row1
            anchors.left: parent.left
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
                            reloadActivityTypeSelector(data.id, -1);
                        }
                    }
                }
            }
        }

        Row {
            id: row1w
            anchors.top: row1.bottom
            anchors.left: parent.left
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
                        // font.bold: true
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        //textSize: Label.Large
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
                            console.log("Project radio selected - subproject selector should be visible");
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
                    textFormat: Text.RichText
                    readOnly: isReadOnly
                    width: flickable.width < units.gu(361) ? flickable.width - units.gu(15) : flickable.width - units.gu(10)
                    height: units.gu(5) // Start with collapsed height
                    anchors.centerIn: parent.centerIn
                    text: currentActivity.summary

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
            id: row3
            anchors.top: row2.bottom
            anchors.left: parent.left
            topPadding: units.gu(1)
            Column {
                id: myCol888
                leftPadding: units.gu(1)
                LomiriShape {
                    width: units.gu(10)
                    height: units.gu(5)
                    aspect: LomiriShape.Flat
                    TSLabel {
                        id: notes_label
                        text: "Notes"
                        // font.bold: true
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        //textSize: Label.Large
                    }
                }
            }
            Column {
                id: myCol999
                leftPadding: units.gu(3)

                Item {
                    id: notesContainer
                    width: flickable.width < units.gu(361) ? flickable.width - units.gu(15) : flickable.width - units.gu(10)
                    height: notes.height

                    TextArea {
                        id: notes
                        readOnly: isReadOnly
                        textFormat: Text.RichText
                        autoSize: false
                        width: parent.width
                        height: units.gu(10) // Start with collapsed height
                        anchors.centerIn: parent.centerIn
                        text: currentActivity.notes
                        selectByMouse: true
                        wrapMode: TextArea.Wrap

                        onHeightChanged: {
                            console.log("Notes TextArea height changed to:", height, "Expanded state:", activityDetailsPage.descriptionExpanded);
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

                    // Floating Action Button
                    Item {
                        id: floatingActionButton
                        width: units.gu(3)
                        height: units.gu(3)
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.rightMargin: units.gu(1)
                        anchors.bottomMargin: units.gu(1)
                        z: 10
                      //  visible: !isReadOnly

                        // Circular background
                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: LomiriColors.orange

                            // Shadow effect
                            Rectangle {
                                anchors.fill: parent
                                anchors.topMargin: units.gu(0.15)
                                anchors.leftMargin: units.gu(0.15)
                                radius: parent.radius
                                color: "#30000000"
                                z: -1
                            }
                        }

                        Icon {
                            id: expandIcon
                            anchors.centerIn: parent
                            width: units.gu(1.5)
                            height: units.gu(1.5)
                            name: activityDetailsPage.descriptionExpanded ? "up" : "down"
                            color: "white"
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                console.log("Floating button clicked! Current state:", activityDetailsPage.descriptionExpanded);
                                activityDetailsPage.descriptionExpanded = !activityDetailsPage.descriptionExpanded;
                                console.log("New state:", activityDetailsPage.descriptionExpanded);

                                // Force height update with smooth transition
                                if (activityDetailsPage.descriptionExpanded) {
                                    notes.height = activityDetailsPage.expandedHeight;
                                } else {
                                    notes.height = units.gu(10);
                                }
                            }

                            onPressed: {
                                parent.scale = 0.95;
                            }

                            onReleased: {
                                parent.scale = 1.0;
                            }
                        }
                    }
                }
            }
        }

        Row {
            id: row4
            anchors.top: row3.bottom
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
        if (recordid != 0) {
            console.log("Loading activity local id " + recordid + " Account id is " + accountid);
            currentActivity = Activity.getActivityById(recordid, accountid);
            currentActivity.user_name = Accounts.getUserNameByOdooId(currentActivity.user_id);

            let instanceId = currentActivity.account_id;
            let user_id = currentActivity.user_id;

            console.log("Activity loaded:", JSON.stringify({
                resModel: currentActivity.resModel,
                link_id: currentActivity.link_id,
                instanceId: instanceId,
                user_id: user_id,
                linkedType: currentActivity.linkedType,
                project_id: currentActivity.project_id,
                sub_project_id: currentActivity.sub_project_id,
                task_id: currentActivity.task_id,
                sub_task_id: currentActivity.sub_task_id
            }));

            // Load the Activity Type
            reloadActivityTypeSelector(instanceId, currentActivity.activity_type_id);

            // Default radio selection
            taskRadio.checked = false;
            projectRadio.checked = false;

            // If project and subproject are the same, treat it as no subproject selected.
            if (currentActivity.project_id && currentActivity.project_id === currentActivity.sub_project_id) {
                console.log("Project and Sub-project are the same. Setting sub-project to none.");
                currentActivity.sub_project_id = -1;
            }

            switch (currentActivity.linkedType) {
            case "task":
                // Connected to task: Show project, subproject, and task selectors
                console.log("Setting up task connection");
                taskRadio.checked = true;
                console.log("Using deferredLoadExistingRecordSet with:", "projectId:", currentActivity.project_id, "subProjectId:", currentActivity.sub_project_id, "taskId:", currentActivity.task_id);
                workItem.deferredLoadExistingRecordSet(instanceId, currentActivity.project_id, currentActivity.sub_project_id, currentActivity.task_id, currentActivity.sub_task_id, user_id);
                break;
            case "project":
                // Connected to project/subproject: Show project and subproject selectors
                console.log("Setting up project connection");
                projectRadio.checked = true;
                workItem.deferredLoadExistingRecordSet(instanceId, currentActivity.project_id, currentActivity.sub_project_id, -1, -1, user_id);
                break;
            default:
                workItem.deferredLoadExistingRecordSet(instanceId, -1, -1, -1, -1, user_id);
            }

            // Update due date
            date_widget.setSelectedDate(currentActivity.due_date);
        } else {
            console.log("Creating a new activity");

            let account = Accounts.getAccountsList();
            reloadActivityTypeSelector(account, -1);

            // For new activities, show both selectors with task selected by default
            taskRadio.checked = true;
            projectRadio.checked = false;
            workItem.loadAccounts();
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
    }

    function saveActivityData() {
        const ids = workItem.getIds();
        console.log("getAllSelectedDbRecordIds returned:");
        console.log("   accountDbId: " + ids.account_id);
        console.log("   projectDbId: " + ids.project_id);
        console.log("   subProjectDbId: " + ids.subproject_id);
        console.log("   taskDbId: " + ids.task_id);
        console.log("   subTaskDbId: " + ids.subtask_id);
        console.log("   assigneeDbId: " + ids.assignee_id);

        var linkid = -1;
        var resId = 0;

        if (projectRadio.checked) {
            // Use subproject if selected, otherwise use main project
            linkid = ids.subproject_id || ids.project_id;
            resId = Accounts.getOdooModelId(ids.account_id, "Project");
            console.log("Project mode - linking to:", ids.subproject_id ? "subproject " + ids.subproject_id : "project " + ids.project_id);
        }

        if (taskRadio.checked) {
            linkid = ids.sub_task_id || ids.task_id;
            resId = Accounts.getOdooModelId(ids.account_id, "Task");
        }

        const resModel = projectRadio.checked ? "project.project" : taskRadio.checked ? "project.task" : "";

        if (typeof linkid === "undefined" || linkid === null || linkid <= 0 || resId === 0) {
            console.log(linkid + "is the value of linkid");
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
            updatedSummary: Utils.cleanText(summary.displayText),
            updatedUserId: user,
            updatedDate: date_widget.selectedDate,
            updatedNote: Utils.cleanText(notes.displayText),
            resModel: resModel,
            resId: resId,
            link_id: linkid,
            task_id: null,
            state: "planned",
            project_id: null,
            status: "updated"
        };

        Utils.show_dict_data(data);

        const result = Activity.saveActivityData(data);
        if (!result.success) {
            notifPopup.open("Error", "Unable to save the Activity", "error");
        } else {
            notifPopup.open("Saved", "Activity has been saved successfully", "success");
            // No navigation - stay on the same page like Timesheet.qml
            // User can use back button to return to list page
        }
    }
}
