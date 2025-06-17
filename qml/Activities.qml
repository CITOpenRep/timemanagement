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
    property var currentActivity: {}
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
                Label {
                    id: type_text
                    textFormat: Text.RichText
                    width: flickable.width < units.gu(361) ? flickable.width - units.gu(15) : flickable.width - units.gu(10)
                    anchors.centerIn: parent.centerIn
                    text: Activity.getActivityTypeName(currentActivity.activity_type_id)
                }
            }
        }

        Row {
            id: row5
            anchors.top: row4.bottom
            anchors.left: parent.left
            topPadding: units.gu(1)
            Column {
                leftPadding: units.gu(1)
                LomiriShape {
                    width: units.gu(10)
                    height: units.gu(5)
                    aspect: LomiriShape.Flat
                    TSLabel {
                        text: "Date"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
            Column {
                leftPadding: units.gu(3)
                Label {
                    id: date_text
                    textFormat: Text.RichText
                    width: flickable.width < units.gu(361) ? flickable.width - units.gu(15) : flickable.width - units.gu(10)
                    anchors.centerIn: parent.centerIn
                    text: Utils.formatDate(new Date(currentActivity.due_date))
                }
            }
        }

        Row {
            id: row6
            anchors.top: row5.bottom
            anchors.left: parent.left
            topPadding: units.gu(1)
            Column {
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
                leftPadding: units.gu(3)
                Label {
                    id: status_text
                    textFormat: Text.RichText
                    width: flickable.width < units.gu(361) ? flickable.width - units.gu(15) : flickable.width - units.gu(10)
                    anchors.centerIn: parent.centerIn
                    text: currentActivity.state || "Unknown"
                }
            }
        }
    }

    Component.onCompleted: {
        if (recordid != 0) {
            console.log("Loading activity id " + recordid + " Account id is " + accountid);
            currentActivity = Activity.getActivityByOdooId(recordid, accountid);
            currentActivity.user_name = Accounts.getUserNameByOdooId(currentActivity.user_id);
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
        }
    }
}
