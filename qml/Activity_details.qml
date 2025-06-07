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
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.Components.Pickers 1.3
import QtCharts 2.0
import QtQuick.Window 2.2
import Qt.labs.settings 1.0
import "../models/Activity.js" as Activity

Page {
    id: activityDetails
    title: "Activity Details"
    header: PageHeader {
        title: activityDetails.title
        ActionBar {
            numberOfSlots: 2
            anchors.right: parent.right
            //    enable: true
            actions: [
                Action {
                    iconName: "edit"
                    text: "Edit"
                    onTriggered: {
                        console.log("Edit Activity clicked");
                        console.log("Account ID: " + activities[0].account_id);
                        isReadOnly = !isReadOnly;
                    }
                },
                Action {
                    iconName: "save"
                    text: "Save"
                    onTriggered: {
                        isReadOnly = !isReadOnly;
                        console.log("Save Activity clicked");
                        save_activity_data();
                    }
                }
            ]
        }
    }

    property var recordid: 0
    property bool workpersonaSwitchState: true
    property bool isReadOnly: true
    property var activities: []
    property var duedatestr: ""
    property var activityType: ""
    property var activityTypeList: []
    property var project: ""
    property var parentname: ""
    property var account: ""
    property var user: ""
    property int selectedAccountUserId: 0
    property int selectedProjectId: 0
    property int selectedparentId: 0
    property int favorites: 0

    function get_activity_list(recordid) {
        console.log("In get_activity_list()");
        activities = Activity.fetch_activity_lists(recordid);
    }

    function get_activity_type(activityid) {
        for (var i = 0; i < activityTypeList.length; i++) {
            if (activityTypeList[i].id === activityid) {
                activityType = activityTypeList[i].name;
            }
        }
        console.log("Activity Type: " + activityType);
    }

    function get_task_details() {
        project = tx.executeSql('SELECT name FROM project_project_app WHERE id = ?', tasks[0].project_id);
        parentname = tx.executeSql('SELECT name FROM project_task_app WHERE id = ?', tasks[0].parent_id);
        if (workpersonaSwitchState) {
            account = tx.executeSql('SELECT name FROM users WHERE id = ?', tasks[0].account_id);
            user = tx.executeSql('SELECT name FROM res_users_app WHERE id = ?', tasks[0].userId);
        }
    }

    function save_activity_data() {
        var selectedProjectId = activities[0].project_id;
        var selectedAccountUserId = activities[0].account_id;
        var selectedassigneesUserId = activities[0].userId;
        console.log("Account ID: " + selectedAccountUserId);
        const editData = {
            selectedAccountUserId: selectedAccountUserId,
            nameInput: task_text.text,
            selectedProjectId: selectedProjectId,
            editselectedSubProjectId: 0,
            selectedparentId: tasks[0].parent_Id,
            startdateInput: start_text.text,
            enddateInput: end_text.text,
            deadlineInput: deadline_text.text,
            img_star: favorites,
            initialInput: hours_text.text,
            editdescription: description_text.text,
            selectedassigneesUserId: selectedassigneesUserId,
            'rowId': tasks[0].id
        };
        Activity.edittaskData(editData);
        PopupUtils.open(savepopover);
    }

    ListModel {
        id: activityListModel
    }

    LomiriShape {
        id: rect1
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        radius: "large"
        width: parent.width
        height: parent.height

        Row {
            id: myRow1a
            anchors.left: parent.left
            topPadding: 10
            Column {
                leftPadding: units.gu(2)
                Rectangle {
                    width: units.gu(10)
                    height: units.gu(5)
                    Label {
                        id: instance_label
                        text: "Instance"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        //textSize: Label.Large
                    }
                }
            }
            Column {
                leftPadding: units.gu(3)
                TextField {
                    id: instance_text
                    readOnly: isReadOnly
                    width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                    text: activities[0].accountName
                }
            }
        }

        Row {
            id: myRow1
            anchors.top: myRow1a.bottom
            anchors.left: parent.left
            topPadding: 10
            Column {
                leftPadding: units.gu(2)
                Rectangle {
                    width: units.gu(10)
                    height: units.gu(5)
                    Label {
                        id: activity_label
                        text: "Activity Type"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        //textSize: Label.Large
                    }
                }
            }
            Column {
                leftPadding: units.gu(3)
                TextField {
                    id: activity_text
                    readOnly: isReadOnly
                    width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                    text: activities[0].name
                }
            }
        }

        Row {
            id: myRow2
            anchors.top: myRow1.bottom
            anchors.left: parent.left
            topPadding: 10
            Column {
                leftPadding: units.gu(2)
                Rectangle {
                    width: units.gu(10)
                    height: units.gu(5)
                    Label {
                        id: assignee_label
                        text: "Assigned To"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        //textSize: Label.Large
                    }
                }
            }
            Column {
                leftPadding: units.gu(3)
                TextField {
                    id: assignee_text
                    readOnly: isReadOnly
                    width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                    text: user
                }
            }
        }

        Row {
            id: myRow9
            anchors.top: myRow2.bottom
            anchors.left: parent.left
            topPadding: 10
            Column {
                id: myCol8
                leftPadding: units.gu(2)
                Rectangle {
                    width: units.gu(10)
                    height: units.gu(5)
                    Label {
                        id: summary_label
                        text: "Summary"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        //textSize: Label.Large
                    }
                }
            }
            Column {
                id: myCol9
                leftPadding: units.gu(3)
                TextField {
                    id: description_text
                    readOnly: isReadOnly
                    width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                    anchors.centerIn: parent.centerIn
                    text: activities[0].summary
                }
            }
        }

        Row {
            id: myRow3
            anchors.top: myRow9.bottom
            anchors.left: parent.left
            topPadding: 10
            Column {
                leftPadding: units.gu(2)
                Rectangle {
                    width: units.gu(10)
                    height: units.gu(5)
                    Label {
                        id: duedate_label
                        text: "Due Date"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        //textSize: Label.Large
                    }
                }
            }
            Column {
                leftPadding: units.gu(3)
                TextField {
                    id: due_date
                    readOnly: isReadOnly
                    width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                    text: activities[0].due_date
                }
            }
        }

        Row {
            id: myRow10
            anchors.top: myRow3.bottom
            anchors.left: parent.left
            topPadding: 10
            Column {
                id: myCol10
                leftPadding: units.gu(2)
                Rectangle {
                    width: units.gu(10)
                    height: units.gu(5)
                    Label {
                        id: notes_label
                        text: "Notes"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        //textSize: Label.Large
                    }
                }
            }
            Column {
                id: myCol11
                leftPadding: units.gu(3)
                width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                height: 40
                TextField {
                    id: notes_text
                    readOnly: isReadOnly
                    width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                    anchors.centerIn: parent.centerIn
                    text: activities[0].notes
                }
            }
        }

        Row {
            id: myRow4
            anchors.top: myRow10.bottom
            anchors.left: parent.left
            topPadding: 10
            Column {
                leftPadding: units.gu(2)
                Rectangle {
                    width: units.gu(10)
                    height: units.gu(5)
                    Label {
                        id: link_label
                        text: "Link To"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        //textSize: Label.Large
                    }
                }
            }
            Column {
                leftPadding: units.gu(3)
                TextField {
                    id: link_text
                    readOnly: isReadOnly
                    width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                    anchors.centerIn: parent.centerIn
                    text: activityType
                }
            }
        }

        Row {
            id: myRow5
            anchors.top: myRow4.bottom
            anchors.left: parent.left
            topPadding: 10
            Column {
                leftPadding: units.gu(2)
                Rectangle {
                    width: units.gu(10)
                    height: units.gu(5)
                    Label {
                        id: projid_label
                        text: "Project Id"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        //textSize: Label.Large
                    }
                }
            }
            Column {
                leftPadding: units.gu(3)
                TextField {
                    id: projid_text
                    readOnly: isReadOnly
                    width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                    anchors.centerIn: parent.centerIn
                    text: activities[0].summary
                }
            }
        }

        /***************************************************************/

        Rectangle {
            id: popuprect
            width: units.gu(20)
            height: units.gu(20)
            border.color: "black"
            border.width: 2
            radius: 10
            anchors.centerIn: parent
            visible: false
            /***************************************************************/

            Component {
                id: savepopover

                Popover {
                    id: popover
                    autoClose: true
                    anchors.centerIn: parent

                    Label {
                        id: save_label
                        anchors.centerIn: parent
                        text: "Activity Saved!"
                        font.bold: true
                        color: LomiriColors.green
                    }
                }
            }
            /**************************************************************/

        }

        Component.onCompleted: {
            console.log("From Activity Page " + apLayout.columns);
            console.log("From Activity Page ID " + recordid);
            activities = Activity.queryActivityData("", recordid);
            activityTypeList = Activity.fetch_activity_types(activities[0].account_id);
            get_activity_type(activities[0].activity_type_id);
            console.log("From Activity Page Activity Name " + activities[0].name);
            console.log("From Activity Page Activity Type " + activityType);
        }
    }
}
