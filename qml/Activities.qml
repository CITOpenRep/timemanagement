import QtQuick 2.7
import QtQuick.Controls 2.2
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

Page {
    id: activityDetailsPage
    title: "Activity"
    property var recordid: 0
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
        contentHeight: parent.height + 500
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
                    showProjectSelector: projectRadio.checked
                    showTaskSelector: taskRadio.checked
                    taskLabelText: "Parent Task"
                    width: flickable.width - units.gu(2)

                    onAccountChanged: {
                        //reload the activity type for the account
                        reloadActivityTypeSelector(accountId, -1);
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
                    contentItem: Text {
                        text: projectRadio.text
                        color: theme.palette.normal.backgroundText
                        leftPadding: projectRadio.indicator.width + projectRadio.spacing
                        verticalAlignment: Text.AlignVCenter
                    }
                    onCheckedChanged: {
                        if (checked) {
                            console.log("Project radio selected");
                            workItem.showProjectSelector = true;
                            workItem.showTaskSelector = false;
                            taskRadio.checked = false;
                        }
                    }
                }

                RadioButton {
                    id: taskRadio
                    text: "Task"
                    checked: true
                    contentItem: Text {
                        text: taskRadio.text
                        color: theme.palette.normal.backgroundText
                        leftPadding: taskRadio.indicator.width + taskRadio.spacing
                        verticalAlignment: Text.AlignVCenter
                    }
                    onCheckedChanged: {
                        if (checked) {
                            console.log("Task radio selected");
                            workItem.showProjectSelector = true;
                            workItem.showTaskSelector = true;
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
                    anchors.centerIn: parent.centerIn
                    text: currentActivity.summary
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
                TextArea {
                    id: notes
                    readOnly: isReadOnly
                    textFormat: Text.RichText
                    width: flickable.width < units.gu(361) ? flickable.width - units.gu(15) : flickable.width - units.gu(10)
                    anchors.centerIn: parent.centerIn
                    text: currentActivity.notes
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
            let instanceId = (currentActivity.account_id !== undefined && currentActivity.account_id !== null) ? currentActivity.account_id : -1;
            let user_id = (currentActivity.user_id !== undefined && currentActivity.user_id !== null) ? currentActivity.user_id : -1;

            console.log("Activity loaded:", JSON.stringify({
                resModel: currentActivity.resModel,
                link_id: currentActivity.link_id,
                instanceId: instanceId,
                user_id: user_id
            }));

            //Load the Activity Type
            reloadActivityTypeSelector(instanceId, currentActivity.activity_type_id);

            //Now we need to smartly use the workitem , because an activity can have a related item , which can be project or task
            //lets reset the task and project views
            workItem.showTaskSelector = false;
            workItem.showProjectSelector = false;
            
            switch (currentActivity.resModel) {
            case "project.task":
                // Connected to task: Show project, subproject, AND task selectors (full hierarchy)
                // First get the task details to find which project it belongs to
                console.log("Activity connected to task, fetching task details for link_id:", currentActivity.link_id);
                let taskDetails = Task.getTaskDetails(currentActivity.link_id);
                console.log("Task details:", JSON.stringify(taskDetails));
                
                let projectId = taskDetails.project_id || -1;
                let subProjectId = taskDetails.sub_project_id || -1;
                
                workItem.showProjectSelector = true;
                workItem.showTaskSelector = true;
                taskRadio.checked = true;
                projectRadio.checked = false;
                
                console.log("Setting up task connection with projectId:", projectId, "subProjectId:", subProjectId, "taskId:", currentActivity.link_id);
                
                // Apply selection with both project and task information
                // Use subProjectId if available, otherwise use projectId
                workItem.applyDeferredSelection(instanceId, projectId, subProjectId, currentActivity.link_id, -1, user_id);
                break;
                
            case "project.project":
                // Connected to project: Show project and subproject selectors only
                console.log("Activity connected to project, link_id:", currentActivity.link_id);
                workItem.showProjectSelector = true;
                workItem.showTaskSelector = false;
                projectRadio.checked = true;
                taskRadio.checked = false;
                
                workItem.applyDeferredSelection(instanceId, currentActivity.link_id, -1, -1, -1, user_id);
                break;
                
            default:
                console.log("Activity not connected to project or task");
                // Show both selectors but no selection
                workItem.showProjectSelector = true;
                workItem.showTaskSelector = true;
                taskRadio.checked = true;
                projectRadio.checked = false;
                workItem.applyDeferredSelection(instanceId, -1, -1, -1, -1, user_id);
            }
            
            //update due date
            date_widget.setSelectedDate(currentActivity.due_date);
        } else {
            console.log("Creating a new activity");
            let account = Accounts.getAccountsList();
            reloadActivityTypeSelector(account, -1);
            
            // For new activities, show both selectors with task selected by default
            workItem.showProjectSelector = true;
            workItem.showTaskSelector = true;
            taskRadio.checked = true;
            projectRadio.checked = false;
            
            workItem.applyDeferredSelection(account, -1, -1, -1, -1, -1);
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
        const ids = workItem.getAllSelectedDbRecordIds();
        Utils.show_dict_data(ids);
        var linkid = 0;
        var resId = 0;

        if (projectRadio.checked) {
            linkid = ids.projectDbId;
            resId = Accounts.getOdooModelId(ids.accountDbId, "Project");
        }

        if (taskRadio.checked) {
            linkid = ids.taskDbId;
            resId = Accounts.getOdooModelId(ids.accountDbId, "Task");
        }

        const resModel = projectRadio.checked ? "project.project" : taskRadio.checked ? "project.task" : "";

        if (linkid === 0 || resId === 0) {
            notifPopup.open("Error", "Activity must be connected to a project or task", "error");
            return;
        }
        //console.log("LINK ID is ->>>>>>>>>>> " + linkid);

        const user = Accounts.getCurrentUserOdooId(ids.accountDbId);
        if (!user) {
            notifPopup.open("Error", "The specified user does not exist. Unable to save.", "error");
            return;
        }

        if (activityTypeSelector.selectedId === -1 || summary.text === "" || notes.text === "") {
            let message = activityTypeSelector.selectedId === -1 ? "You must specify the Activity type" : summary.text === "" ? "Please enter a summary" : "Please enter notes";
            notifPopup.open("Error", message, "error");
            return;
        }

        const data = {
            updatedAccount: ids.accountDbId,
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
            apLayout.addPageToNextColumn(activityDetailsPage, Qt.resolvedUrl("Activity_Page.qml"));
        }
    }
}
