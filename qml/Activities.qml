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
                    console.log("Activity Save Button clicked");
                }
            }
        ]
    }

    NotificationPopup {
        id: notifPopup
        width: units.gu(80)
        height: units.gu(80)
        onClosed: console.log("Notification dismissed")
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
                    showProjectSelector: false
                    showTaskSelector: false
                    taskLabelText: "Parent Task"
                    width: flickable.width - units.gu(2)

                    onAccountChanged: {
                        console.log("Account id is " + accountId);
                        //reload the activity type for the account
                        reloadActivityTypeSelector(accountId,-1);
                    }
                }
            }
        }

        Row {
            id: row2
            anchors.top: row1.bottom
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

        Row {
            id: row6
            anchors.top: row5.bottom
            anchors.left: parent.left
            topPadding: units.gu(1)
            height: units.gu(5)  // Set a fixed height to align vertically
            anchors.topMargin: units.gu(4)

            Column {
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: units.gu(1)

                LomiriShape {
                    width: units.gu(10)
                    height: units.gu(5)
                    aspect: LomiriShape.Flat

                    TSLabel {
                        text: "State"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

        }
    }

    Component.onCompleted: {
        if (recordid != 0) {
            console.log("Loading activity local id " + recordid + " Account id is " + accountid);
            currentActivity = Activity.getActivityById(recordid, accountid);
            currentActivity.user_name = Accounts.getUserNameByOdooId(currentActivity.user_id);

            let linkid = -1;




            /*
            currentActivity.project_name = currentActivity.project_id ? Utils.getProjectDetails(currentActivity.project_id).name : "No Project";
            currentActivity.task_name = currentActivity.task_id ? Utils.getTaskDetails(currentActivity.task_id).name : "No Task";
            currentActivity.activity_name = Activity.getActivityTypeName(currentActivity.activity_type_id);
            console.log("Activity name is ---------------" + currentActivity.activity_name);


            let parent_project_id = (currentActivity.project_id !== undefined && currentActivity.project_id !== null) ? currentActivity.project_id : -1;
            let parent_task_id = (currentActivity.task_id !== undefined && currentActivity.task_id !== null) ? currentActivity.task_id : -1;


            workItem.applyDeferredSelection(instanceId, parent_project_id, parent_task_id, user_id);*/


            let instanceId = (currentActivity.account_id !== undefined && currentActivity.account_id !== null) ? currentActivity.account_id : -1;
            let user_id = (currentActivity.user_id !== undefined && currentActivity.user_id !== null) ? currentActivity.user_id : -1;

            //Load the Activity Type
            reloadActivityTypeSelector(instanceId,currentActivity.activity_type_id)

            //Now we need to smartly use the workitem , because an activity can have a related item , which can be project or task
            //lets reset the task and project views
            workItem.showTaskSelector=false
            workItem.showProjectSelector=false
            switch (currentActivity.resModel) {
            case "project.task":
                workItem.showTaskSelector=true
                workItem.applyDeferredSelection(instanceId, -1, currentActivity.resId, user_id);
                break;
            case "project.project":
                workItem.showProjectSelector=true
                workItem.applyDeferredSelection(instanceId, currentActivity.resId, -1, user_id);
                break;
            default:
                workItem.applyDeferredSelection(instanceId, -1, -1, user_id);
            }

        } else {
            console.log("Creatign a new activity");
            let account = Accounts.getAccountsList();
            console.log(account[1].name);
            reloadActivityTypeSelector(account,-1)
            workItem.applyDeferredSelection(account, -1, -1, -1);

        }
    }


    function reloadActivityTypeSelector(accountId, selectedTypeId) {
        console.log("->-> Loading Activity Types for account " + accountId);

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


    function saveActivityData(){
        const ids = workItem.getAllSelectedDbRecordIds();
        console.log("Account DB ID:", ids.accountDbId);
        console.log("Project DB ID:", ids.projectDbId);
        console.log("Task DB ID:", ids.taskDbId);
        console.log("Assignee" + ids.assigneeDbId);

        const user = Accounts.getCurrentUserOdooId(ids.accountDbId);
        if (!user) {
            notifPopup.open("Error", "Unable to find the user , can not save", "error");
            return;
        }


        if((ids.projectDbId ==-1) || (ids.taskDbId ==-1) || (ids.assigneeDbId ==-1) )
        {
            notifPopup.open("Error", "Project or task  or assignee not selected", "error");
            return;
        }

        if(typeDropDown.currentIndex ==0){

            notifPopup.open("Error", "Choose a type", "error");
            return;

        }
        if(summary.text ==""){
            notifPopup.open("Error", "type summary", "error");
            return;
        }
        if(notes.text ==""){
            notifPopup.open("Error", "type notes", "error");
            return;
        }
        if(statusDropDown.currentIndex == 0){
            notifPopup.open("Error", "Select shedule", "error");
            return;
        }

        /* console.log("user = ",user)
        console.debug(typeItems.get(typeDropDown.currentIndex).text )
        console.debug(typeItems.get(typeDropDown.currentIndex).odoo_record_id )
        console.log(summary.text)
        console.log(notes.text)
        console.log(date_widget.selectedDate) */

        let data = {
            "updatedAccount":ids.accountDbId,
            "updatedActivity":typeItems.get(typeDropDown.currentIndex).odoo_record_id,
            "updatedSummary":summary.text,
            "updatedUserId":user,
            "updatedDate":date_widget.selectedDate,
            "updatedNote":notes.text,
            "resModel":"",
            "resId":"",
            "task_id":"",
            "project_id":"",
            "link_id":"",
            "status":"updated",
            "editschedule":statusItems.get(statusDropDown.currentIndex).text
        }
        console.log(data)
        

        const result = Activity.saveActivityData(data);
        if (!result.success) {
            notifPopup.open("Error", "Unable to Save the Activity", "error");
        } else {
            notifPopup.open("Saved", "Activity has been saved successfully", "success");
            apLayout.addPageToCurrentColumn(activityDetailsPage, Qt.resolvedUrl("Activity_Page.qml"));
            let page = 2;
            apLayout.setCurrentPage(page);
        }

    }

}
