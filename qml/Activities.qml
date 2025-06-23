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
    ListModel {
        id: typeItems
        ListElement {
            text: "Select Type"
            color: "Yellow"
        }
        // ListElement { text: "Apple"; color: "Green" }
        // ListElement { text: "Coconut"; color: "Brown" }
    }
    ListModel {
        id: statusItems
        ListElement {
            text: "Select Status"
            color: "Yellow"
        }
        ListElement {
            text: "Scheduled"
            color: "Green"
        }
        ListElement {
            text: "Done"
            color: "Brown"
        }
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
                    taskLabelText: "Parent Task"
                    width: flickable.width - units.gu(2)
                    showAssigneeSelector: true
                    onAccountChanged: {
                        console.log("Account id is " + accountId);
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
                    // textFormat: Text.RichText
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
                    // textFormat: Text.RichText
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
            Column {
                leftPadding: units.gu(1)
                LomiriShape {
                    width: units.gu(10)
                    height: units.gu(5)
                    aspect: LomiriShape.Flat
                    TSLabel {
                        text: "Type"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
            Column {
                leftPadding: units.gu(3)
                // Label {
                //     id: type_text
                //     textFormat: Text.RichText
                //     width: flickable.width < units.gu(361) ? flickable.width - units.gu(15) : flickable.width - units.gu(10)
                //     anchors.centerIn: parent.centerIn
                //     text: Activity.getActivityTypeName(currentActivity.activity_type_id)
                // }

                anchors.verticalCenter: parent.verticalCenter

                ComboBox {
                    id: typeDropDown
                    currentIndex: 0
                    width: units.gu(20)
                    height: units.gu(5)  // Match height to shape for vertical alignment

                    model: typeItems

                    contentItem: Text {
                        text: typeItems.get(typeDropDown.currentIndex).text
                        color: "black"
                        leftPadding: units.gu(1)
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    background: Rectangle {
                        color: "white"
                        radius: 4
                        border.color: "#ccc"
                    }

                    delegate: ItemDelegate {
                        width: parent.width
                        contentItem: Text {
                            text: model.text
                            color: "black"
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    onCurrentIndexChanged: {
                        console.debug(typeItems.get(currentIndex).text);
                        console.debug(typeItems.get(currentIndex).odoo_record_id);
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

            Column {
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: units.gu(3)

                ComboBox {
                    id: statusDropDown
                    currentIndex: 0
                    width: units.gu(20)
                    height: units.gu(5)  // Match height to shape for vertical alignment

                    model: statusItems

                    contentItem: Text {
                        text: statusItems.get(statusDropDown.currentIndex).text
                        color: "black"
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: units.gu(1)
                        elide: Text.ElideRight
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    background: Rectangle {
                        color: "white"
                        radius: 4
                        border.color: "#ccc"
                    }

                    delegate: ItemDelegate {
                        width: parent.width
                        contentItem: Text {
                            text: model.text
                            color: "black"
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    onCurrentIndexChanged: console.debug(statusItems.get(currentIndex).text)
                }
            }
        }
    }

    Component.onCompleted: {
        if (recordid != 0) {
            console.log("Loading activity id " + recordid + " Account id is " + accountid);
            currentActivity = Activity.getActivityByOdooId(recordid, accountid);
            currentActivity.user_name = Accounts.getUserNameByOdooId(currentActivity.user_id);

            let linkid = -1;

            switch (currentActivity.resModel) {
            case "project.task":
                // handle task todo
                break;
            case "project.project":
                // handle project
                break;
            default:
            // handle others
            }

            currentActivity.project_name = currentActivity.project_id ? Utils.getProjectDetails(currentActivity.project_id).name : "No Project";
            currentActivity.task_name = currentActivity.task_id ? Utils.getTaskDetails(currentActivity.task_id).name : "No Task";
            currentActivity.activity_name = Activity.getActivityTypeName(currentActivity.activity_type_id);
            console.log("Activity name is ---------------" + currentActivity.activity_name);

            let instanceId = (currentActivity.account_id !== undefined && currentActivity.account_id !== null) ? currentActivity.account_id : -1;
            let parent_project_id = (currentActivity.project_id !== undefined && currentActivity.project_id !== null) ? currentActivity.project_id : -1;
            let parent_task_id = (currentActivity.task_id !== undefined && currentActivity.task_id !== null) ? currentActivity.task_id : -1;
            let user_id = (currentActivity.user_id !== undefined && currentActivity.user_id !== null) ? currentActivity.user_id : -1;

            workItem.applyDeferredSelection(instanceId, parent_project_id, parent_task_id, user_id);
        } else {
            console.log("Creatign a new activity");

            let account = Accounts.getAccountsList();
            console.log(account[1].name);
            loadTypes();
            // console.log(summary.text);

        }
    }

    function loadTypes() {
        let activityTypes = Activity.getAllActivityType();
        console.log(activityTypes[0].name);

        //typeItems.clear();
        for (var i = 0; i < activityTypes.length; i++) {
            typeItems.append({
                text: activityTypes[i].name,
                odoo_record_id: activityTypes[i].odoo_record_id
            });
        }
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
    


        console.log("user = ",user)
        console.debug(typeItems.get(typeDropDown.currentIndex).text )
        console.debug(typeItems.get(typeDropDown.currentIndex).odoo_record_id )
        console.log(summary.text)
        console.log(notes.text)
        console.log(date_widget.selectedDate)



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
            "editschedule":statusItems.get(statusDropDown.currentIndex).text
        }
        console.log(data)
        

        const result = Activity.saveActivityData(data);
            if (!result.success) {
                notifPopup.open("Error", "Unable to Save the Task", "error");
            } else {
                notifPopup.open("Saved", "Activity has been saved successfully", "success");
                 apLayout.addPageToCurrentColumn(activityDetailsPage, Qt.resolvedUrl("Activity_Page.qml"));
                    let page = 2;
                    apLayout.setCurrentPage(page);
            }

    }


}