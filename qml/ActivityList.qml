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
import QtQuick.Window 2.2
import QtQuick.Controls 2.2
import QtQuick.LocalStorage 2.7
import Ubuntu.Components 1.3 as Ubuntu

Item {
    width: parent.width
    height: parent.height

    property int currentRecordId: 0
    property int editselectedAccountUserId: 0
    property int editselectedActivityTypeId: 0
    property int eidtselectedUserId: 0
    property bool isActivityEdit: false
    property bool isEditActivityClicked: false
    property bool issearchHeader: false
    property var filterActivityListData: []
    property int selectededitlinkUserId: 0
    property int selectededitprojectUserId: 0
    property int selectededittaskUserId: 0
    property bool readOnlys: true
    function queryData(type) {
        var db = LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
        db.transaction(function (tx) {
            filterActivityListData = [];
            activityListModel.clear();
            if (workpersonaSwitchState) {
                var existing_activities = tx.executeSql('select * from mail_activity_app where account_id is not NULL order by last_modified desc');
                if (type == 'pending') {
                    existing_activities = tx.executeSql('select * from mail_activity_app where account_id is not NULL AND state != "done" order by last_modified desc');
                } else if (type == 'done') {
                    existing_activities = tx.executeSql('select * from mail_activity_app where account_id is not NULL AND state = "done" order by last_modified desc');
                }
            } else {
                var existing_activities = tx.executeSql('SELECT * FROM mail_activity_app where account_id IS NULL');
            }

            for (var activity = 0; activity < existing_activities.rows.length; activity++) {
                activityListModel.append({
                    'summary': existing_activities.rows.item(activity).summary,
                    'due_date': existing_activities.rows.item(activity).due_date,
                    'id': existing_activities.rows.item(activity).id
                });
                filterActivityListData.push({
                    'summary': existing_activities.rows.item(activity).summary,
                    'due_date': existing_activities.rows.item(activity).due_date,
                    'id': existing_activities.rows.item(activity).id
                });
            }
        });
    }
    function filterActivityList(query) {
        activityListModel.clear();

        for (var i = 0; i < filterActivityListData.length; i++) {
            var entry = filterActivityListData[i];
            if (entry.summary.toLowerCase().includes(query.toLowerCase()) || entry.due_date.toLowerCase().includes(query.toLowerCase())) {
                activityListModel.append(entry);
            }
        }
    }
    function fetch_activity_types(selectedAccountUserId) {
        var db = LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
        var activity_type_list = [];
        db.transaction(function (tx) {
            var activity_types = tx.executeSql('select * from mail_activity_type_app where account_id = ?', [selectedAccountUserId]);
            for (var type = 0; type < activity_types.rows.length; type++) {
                activity_type_list.push({
                    'id': activity_types.rows.item(type).id,
                    'name': activity_types.rows.item(type).name
                });
            }
        });
        return activity_type_list;
    }

    ListModel {
        id: activityListModel
    }

    function editActivityData(data) {
        var db = LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);

        db.transaction(function (tx) {
            // Update the record in the database
            tx.executeSql('UPDATE mail_activity_app SET \
            account_id = ?, activity_type_id = ?, summary = ?, user_id = ?, due_date = ?, \
            notes = ?, resModel = ?, resId = ?, task_id = ?, project_id = ?, link_id = ?, state = ?, last_modified = ? \
            WHERE id = ?', [data.updatedAccount, data.updatedActivity, data.updatedSummary, data.updatedUserId, data.updatedDate, data.updatedNote, data.resModel, data.resId, data.task_id, data.project_id, data.link_id, data.editschedule, new Date().toISOString(), data.rowId]);
            queryData('pending');
        });
    }

    function fetch_current_users(selectedAccountUserId) {
        var db = LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
        var activity_type_list = [];
        db.transaction(function (tx) {
            var instance_users = tx.executeSql('select * from res_users_app where account_id = ?', [selectedAccountUserId]);
            var all_users = tx.executeSql('select * from res_users_app');
            for (var instance_user = 0; instance_user < instance_users.rows.length; instance_user++) {
                activity_type_list.push({
                    'id': instance_users.rows.item(instance_user).id,
                    'name': instance_users.rows.item(instance_user).name
                });
            }
        });
        return activity_type_list;
    }

    ListModel {
        id: editlinkList
        ListElement {
            itemId: 0
            name: "Contact"
        }
        ListElement {
            itemId: 1
            name: "Project"
        }
        ListElement {
            itemId: 2
            name: "Task"
        }
        ListElement {
            itemId: 3
            name: "Other"
        }
    }
    function projects_get(selectedAccountUserId) {
        var db = LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
        var projectList = [];
        db.transaction(function (tx) {
            if (workpersonaSwitchState) {
                var result = tx.executeSql('SELECT * FROM project_project_app where account_id = ?', [selectedAccountUserId]);
            } else {
                var result = tx.executeSql('SELECT * FROM project_project_app WHERE account_id IS NULL');
            }
            for (var i = 0; i < result.rows.length; i++) {
                var child_projects = tx.executeSql('SELECT count(*) FROM project_project_app where account_id = ?', [result.rows.item(i).id]);
                projectList.push({
                    'id': result.rows.item(i).id,
                    'name': result.rows.item(i).name,
                    'projectkHasSubProject': true ? child_projects.rows.item(0).count > 0 : false
                });
            }
        });
        return projectList;
    }
    function tasks_list_get(selectedAccountUserId) {
        var db = LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
        var tasks_list = [];
        db.transaction(function (tx) {
            if (workpersonaSwitchState) {
                var result = tx.executeSql('SELECT * FROM project_task_app where account_id = ?', [selectedAccountUserId]);
            } else {
                var result = tx.executeSql('SELECT * FROM project_task_app where account_id IS NULL AND account_id = ?', [selectedAccountUserId]);
            }
            for (var i = 0; i < result.rows.length; i++) {
                var child_tasks = tx.executeSql('SELECT count(*) FROM project_task_app where parent_id = ?', [result.rows.item(i).id]);
                tasks_list.push({
                    'id': result.rows.item(i).id,
                    'name': result.rows.item(i).name,
                    'taskHasSubTask': true ? child_tasks.rows.item(0).count > 0 : false
                });
            }
        });
        return tasks_list;
    }

    Rectangle {
        id: activities_list
        width: parent.width
        height: isDesktop() ? 60 : 120
        anchors.top: parent.top
        anchors.topMargin: isDesktop() ? 60 : 120
        color: "#FFFFFF"
        z: 1

        Rectangle {
            width: parent.width
            height: 2
            color: "#DDDDDD"
            anchors.bottom: parent.bottom
        }

        Row {
            id: row_id
            width: parent.width
            anchors.verticalCenter: parent.verticalCenter
            anchors.fill: parent
            spacing: isDesktop() ? 20 : 40
            anchors.left: parent.left
            anchors.leftMargin: isDesktop() ? issearchHeader ? 55 : 70 : issearchHeader ? -10 : 15
            anchors.right: parent.right
            anchors.rightMargin: isDesktop() ? 10 : 20

            Rectangle {
                id: header_tital
                visible: !issearchHeader
                color: "transparent"
                width: parent.width / 5
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height

                Row {
                    anchors.verticalCenter: parent.verticalCenter

                    Label {
                        text: "Activities"
                        font.pixelSize: isDesktop() ? 20 : 40
                        anchors.verticalCenter: parent.verticalCenter
                        font.bold: true
                        color: "#121944"
                    }
                }
            }

            // Right section with Button
            Rectangle {
                id: header_btnADD
                visible: !issearchHeader
                color: "transparent"
                width: parent.width / 8
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                anchors.right: parent.right

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: isDesktop() ? 10 : 20
                    anchors.right: parent.right

                    ToolButton {
                        width: isDesktop() ? 40 : 80
                        height: isDesktop() ? 35 : 80
                        background: Rectangle {
                            color: "transparent"
                        }
                        contentItem: Ubuntu.Icon {
                            name: "add"
                        }
                        onClicked: {
                            newRecordActivity();
                        }
                    }
                    ToolButton {
                        id: search_id
                        width: isDesktop() ? 40 : 80
                        height: isDesktop() ? 35 : 80
                        background: Rectangle {
                            color: "transparent"
                        }
                        contentItem: Ubuntu.Icon {
                            name: "search"
                        }
                        onClicked: {
                            issearchHeader = true;
                        }
                    }
                }
            }
            Rectangle {
                id: search_header
                visible: issearchHeader
                width: parent.width
                anchors.verticalCenter: parent.verticalCenter
                ToolButton {
                    id: back_idn
                    width: isDesktop() ? 35 : 80
                    height: isDesktop() ? 35 : 80
                    anchors.verticalCenter: parent.verticalCenter
                    background: Rectangle {
                        color: "transparent"
                    }
                    contentItem: Ubuntu.Icon {
                        name: "back"
                    }
                    onClicked: {
                        issearchHeader = false;
                        searchField.text = "";
                    }
                }

                TextField {
                    id: searchField
                    placeholderText: "Search..."
                    anchors.left: back_idn.right
                    anchors.leftMargin: isDesktop() ? 0 : 5
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    onTextChanged: {
                        filterActivityList(searchField.text);
                    }
                }
            }
        }
        // Rectangle {
        TabBar {
            id: tabBar
            anchors.topMargin: isDesktop() ? 65 : 110
            spacing: isDesktop() ? 20 : 40
            width: parent.width
            anchors.verticalCenter: parent.verticalCenter
            anchors.fill: parent
            anchors.left: parent.left
            anchors.leftMargin: isDesktop() ? 70 : 20
            anchors.right: parent.right
            anchors.rightMargin: isDesktop() ? 10 : 20

            TabButton {
                text: "Open"
                onClicked: {
                    queryData('pending');
                    filterActivityList(searchField.text);
                }
            }
            TabButton {
                text: "Done"
                onClicked: {
                    queryData('done');
                    filterActivityList(searchField.text);
                }
            }
            TabButton {
                text: "All"
                onClicked: {
                    queryData('all');
                    filterActivityList(searchField.text);
                }
            }
        }
        // }
    }

    Rectangle {
        width: parent.width
        height: parent.height
        anchors.top: parent.top
        anchors.topMargin: isDesktop() ? 110 : 200
        anchors.left: parent.left
        anchors.leftMargin: isDesktop() ? 70 : 20
        anchors.right: parent.right
        anchors.rightMargin: isDesktop() ? 10 : 20
        anchors.bottom: parent.bottom
        anchors.bottomMargin: isDesktop() ? 0 : 100
        color: "#ffffff"

        Rectangle {
            // spacing: 0
            anchors.fill: parent
            anchors.topMargin: isDesktop() ? 65 : 170
            border.color: "#CCCCCC"
            border.width: isDesktop() ? 1 : 2
            Column {
                spacing: 0
                anchors.fill: parent
                anchors.topMargin: isDesktop() ? 1 : 2
                Flickable {
                    id: editActivity
                    anchors.fill: parent
                    width: rightPanel.visible ? parent.width / 2 : parent.width
                    contentHeight: column.height
                    clip: true
                    property string edit_id: ""
                    visible: isDesktop() ? true : phoneLarg() ? true : rightPanel.visible ? false : true

                    Column {
                        id: column
                        width: rightPanel.visible ? parent.width / 2 : parent.width
                        spacing: 0

                        Repeater {
                            model: activityListModel
                            delegate: Rectangle {
                                width: parent.width
                                height: isDesktop() ? 80 : 100
                                color: currentRecordId === model.id ? "#F5F5F5" : "#FFFFFF"
                                border.color: "#CCCCCC"
                                border.width: isDesktop() ? 1 : 2

                                Column {
                                    spacing: 0
                                    anchors.fill: parent

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                          //  console.log("Column clicked!", model.id);
                                            currentRecordId = model.id;
                                            rightPanel.visible = true;
                                            editActivity.edit_id = model.id;
                                            rightPanel.loadActivityData();
                                            isEditActivityClicked = false;
                                            isActivityEdit = false;
                                        }
                                    }

                                    Row {
                                        width: parent.width
                                        height: isDesktop() ? 40 : 50
                                        spacing: 20
                                        anchors.topMargin: 20

                                        Text {
                                            text: model.summary
                                            font.pixelSize: isDesktop() ? 20 : 40
                                            color: "#000000"
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left
                                            anchors.leftMargin: 10
                                            anchors.top: isDesktop() ? 0 : parent.top
                                            anchors.topMargin: 10
                                        }
                                    }

                                    Row {
                                        width: parent.width
                                        height: isDesktop() ? 40 : 50
                                        spacing: 20
                                        anchors.bottom: parent.bottom
                                        Text {
                                            text: model.due_date
                                            font.pixelSize: isDesktop() ? 18 : 26
                                            color: "#000000"
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left
                                            anchors.bottom: parent.bottom
                                            anchors.bottomMargin: 10
                                            anchors.leftMargin: 10
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                Rectangle {
                    id: rightPanel
                    z: 1
                    visible: false
                    width: isDesktop() ? parent.width / 2 : phoneLarg() ? parent.width / 2 : parent.width
                    height: parent.height
                    anchors.top: parent.top
                    anchors.topMargin: phoneLarg() ? 0 : 0
                    color: "#EFEFEF"
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    function loadActivityData() {
                        var db = LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
                        var rowId = editActivity.edit_id;

                        db.transaction(function (tx) {
                            var result = tx.executeSql('SELECT * FROM mail_activity_app WHERE id = ?', [rowId]);
                            if (result.rows.length > 0) {
                                var rowData = result.rows.item(0);
                              //  console.log(JSON.stringify(rowData, null, 2));

                                var activityId = rowData.activity_type_id || 0;
                                var accountId = rowData.account_id || 0;
                                var usermenuId = rowData.user_id || 0;
                                var projectId = rowData.project_id || 0;
                                var taskId = rowData.task_id || 0;
                                var account = tx.executeSql('SELECT name FROM users WHERE id = ?', [accountId]);
                                var activity = tx.executeSql('SELECT name FROM mail_activity_type_app WHERE id = ?', [activityId]);
                                var usermenu = tx.executeSql('SELECT name FROM res_users_app WHERE id = ?', [usermenuId]);
                                var project = tx.executeSql('SELECT name FROM project_project_app WHERE id = ?', [projectId]);
                                var task = tx.executeSql('SELECT name FROM project_task_app WHERE id = ?', [taskId]);
                                accountInput.text = account.rows.length > 0 ? account.rows.item(0).name || "" : "";
                                editselectedAccountUserId = accountId;

                                activityTypeInput.text = activity.rows.length > 0 ? activity.rows.item(0).name || "" : "";
                                editselectedActivityTypeId = activityId;

                                edituserInput.text = usermenu.rows.length > 0 ? usermenu.rows.item(0).name || "" : "";
                                eidtselectedUserId = usermenuId;

                                summaryInput.text = rowData.summary || "";
                                selectededitlinkUserId = rowData.link_id;
                                if (selectededitlinkUserId === 0) {
                                    editlinkInput.text = "Contact";
                                }
                                if (selectededitlinkUserId === 1) {
                                    editlinkInput.text = "Project";
                                }
                                if (selectededitlinkUserId === 2) {
                                    editlinkInput.text = "Task";
                                }
                                if (selectededitlinkUserId === 3) {
                                    editlinkInput.text = "Other";
                                }
                                if (project.rows.length > 0) {
                                    editprojectInput.text = project.rows.item(0).name;
                                    selectededitprojectUserId = rowData.project_id;
                                }
                                if (task.rows.length > 0) {
                                    edittaskInput.text = task.rows.item(0).name;
                                    selectededittaskUserId = rowData.task_id;
                                }

                                editresModelInput.text = rowData.resModel;
                                editresIdInput.text = rowData.resId;
                                if (rowData.state == "done") {
                                    readOnlys = true;
                                } else {
                                    readOnlys = false;
                                }
                                editschedule.text = rowData.state;

                                var dueDate = rowData.due_date ? new Date(rowData.due_date) : null;
                                datetimeInput.text = dueDate ? formatDate(dueDate) : "";
                                notesInput.text = rowData.notes.replace(/<[^>]+>/g, " ").replace(/&nbsp;/g, "").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&amp;/g, "&").replace(/&quot;/g, "\"").replace(/&#39;/g, "'").trim() || "";
                            }
                        });
                        function formatDate(date) {
                            var month = date.getMonth() + 1;
                            var day = date.getDate();
                            var year = date.getFullYear();
                            return month + '/' + day + '/' + year;
                        }
                    }
                    Column {
                        anchors.fill: parent
                        spacing: 20
                        Rectangle {
                            width: parent.width
                            height: implicitHeight
                            anchors.top: parent.top
                            anchors.topMargin: 5
                            z: 1
                            color: "#ccc"

                            Row {
                                width: parent.width
                                anchors.top: parent.top
                                anchors.topMargin: 5
                                spacing: 20

                                Button {
                                    id: crossButton
                                    width: isDesktop() ? 24 : 65
                                    height: isDesktop() ? 24 : 65
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10

                                    Image {
                                        source: "images/cross.svg"
                                        width: isDesktop() ? 24 : 65
                                        height: isDesktop() ? 24 : 65
                                    }

                                    background: Rectangle {
                                        color: "transparent"
                                        radius: 10
                                        border.color: "transparent"
                                    }

                                    onClicked: {
                                        rightPanel.visible = false;
                                        currentRecordId = -1;
                                    }
                                }

                                Button {
                                    id: centerBtn
                                    visible: !readOnlys
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    enabled: !readOnlys
                                    contentItem: Text {
                                        text: "Done"
                                        font.pixelSize: isDesktop() ? 20 : phoneLarg() ? 30 : 40
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    onClicked: {
                                        editschedule.text = "done";
                                        readOnlys = true;
                                        var rowId = editActivity.edit_id;
                                        const editData = {
                                            updatedAccount: editselectedAccountUserId,
                                            updatedActivity: editselectedActivityTypeId,
                                            updatedUserId: eidtselectedUserId,
                                            updatedSummary: summaryInput.text,
                                            updatedDate: datetimeInput.text,
                                            updatedNote: notesInput.text,
                                            rowId: rowId,
                                            project_id: selectededitprojectUserId,
                                            task_id: selectededittaskUserId,
                                            link_id: selectededitlinkUserId,
                                            resModel: editresModelInput.text,
                                            resId: editresIdInput.text,
                                            editschedule: editschedule.text
                                        };
                                        editActivityData(editData);
                                        isEditActivityClicked = true;
                                        isActivityEdit = true;
                                        activityEditTimer.start();
                                        filterActivityList(searchField.text);
                                    }
                                }

                                Timer {
                                    id: activityEditTimer
                                    interval: 2000
                                    repeat: false
                                    onTriggered: {
                                        isActivityEdit = false;
                                        isEditActivityClicked = false;
                                    }
                                }

                                Button {
                                    id: rightButton
                                    visible: !readOnlys
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.topMargin: 10
                                    width: isDesktop() ? 20 : 50
                                    height: isDesktop() ? 20 : 50
                                    anchors.rightMargin: isDesktop() ? 15 : 20

                                    Image {
                                        source: "images/right.svg"
                                        width: isDesktop() ? 20 : 50
                                        height: isDesktop() ? 20 : 50
                                    }

                                    background: Rectangle {
                                        color: "transparent"
                                        radius: 10
                                        border.color: "transparent"
                                    }

                                    onClicked: {
                                        var rowId = editActivity.edit_id;
                                        const editData = {
                                            updatedAccount: editselectedAccountUserId,
                                            updatedActivity: editselectedActivityTypeId,
                                            updatedUserId: eidtselectedUserId,
                                            updatedSummary: summaryInput.text,
                                            updatedDate: datetimeInput.text,
                                            updatedNote: notesInput.text,
                                            rowId: rowId,
                                            project_id: selectededitprojectUserId,
                                            task_id: selectededittaskUserId,
                                            link_id: selectededitlinkUserId,
                                            resModel: editresModelInput.text,
                                            resId: editresIdInput.text,
                                            editschedule: editschedule.text
                                        };
                                        editActivityData(editData);
                                        isEditActivityClicked = true;
                                        isActivityEdit = true;
                                        activityEditTimer.start();
                                        filterActivityList(searchField.text);
                                    }
                                }
                            }
                        }
                        Flickable {
                            id: flickableContainer
                            width: parent.width
                            height: parent.height
                            contentHeight: activityItemedit.childrenRect.height + (isDesktop() ? 0 : 100)
                            anchors.fill: parent
                            flickableDirection: Flickable.VerticalFlick
                            anchors.top: parent.top
                            anchors.topMargin: isDesktop() ? 85 : phoneLarg() ? 100 : 120

                            clip: true
                            Item {
                                id: activityItemedit
                                height: activityItemedit.childrenRect.height + 100
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.leftMargin: phoneLarg() ? 20 : 0
                                anchors.topMargin: isDesktop() ? 0 : phoneLarg() ? 0 : 120
                                Row {
                                    spacing: isDesktop() ? 100 : phoneLarg() ? 260 : 220
                                    anchors.verticalCenterOffset: -height * 1.5
                                    anchors.left: parent.left
                                    anchors.leftMargin: 20
                                    Component.onCompleted: {
                                        if (isDesktop() || phoneLarg()) {
                                            anchors.horizontalCenter = parent.horizontalCenter;
                                        }
                                    }
                                    Column {
                                        spacing: isDesktop() ? 20 : 40
                                        width: isDesktop() ? 40 : 80
                                        Label {
                                            text: "Instance"
                                            width: 150
                                            height: isDesktop() ? 25 : phoneLarg() ? 50 : 80
                                            visible: workpersonaSwitchState
                                            font.pixelSize: isDesktop() ? 18 : 40
                                        }
                                        Label {
                                            text: "Activity Type"
                                            width: 150
                                            height: isDesktop() ? 25 : phoneLarg() ? 50 : 80
                                            font.pixelSize: isDesktop() ? 18 : 40
                                        }
                                        Label {
                                            text: "Assigned To"
                                            width: 150
                                            height: isDesktop() ? 25 : phoneLarg() ? 50 : 80
                                            font.pixelSize: isDesktop() ? 18 : 40
                                        }
                                        Label {
                                            text: "Summary"
                                            width: 150
                                            height: isDesktop() ? 25 : phoneLarg() ? 50 : 80
                                            font.pixelSize: isDesktop() ? 18 : 40
                                        }

                                        Label {
                                            text: "Due Date"
                                            width: 150
                                            height: isDesktop() ? 25 : phoneLarg() ? 50 : 80
                                            font.pixelSize: isDesktop() ? 18 : 40
                                        }
                                        Label {
                                            text: "Notes"
                                            width: 150
                                            height: notesInput.height
                                            font.pixelSize: isDesktop() ? 18 : 40
                                        }
                                        Label {
                                            text: "Link To"
                                            width: 150
                                            height: isDesktop() ? 25 : phoneLarg() ? 50 : 80
                                            font.pixelSize: isDesktop() ? 18 : 40
                                        }
                                        Label {
                                            text: "Project Id"
                                            width: 150
                                            height: isDesktop() ? 25 : phoneLarg() ? 50 : 80
                                            font.pixelSize: isDesktop() ? 18 : 40
                                            visible: selectededitlinkUserId === 1
                                        }
                                        Label {
                                            text: "Task Id"
                                            width: 150
                                            height: isDesktop() ? 25 : phoneLarg() ? 50 : 80
                                            font.pixelSize: isDesktop() ? 18 : 40
                                            visible: selectededitlinkUserId === 2
                                        }
                                        Label {
                                            text: "Res Model"
                                            width: 150
                                            height: isDesktop() ? 25 : phoneLarg() ? 50 : 80
                                            font.pixelSize: isDesktop() ? 18 : 40
                                            visible: selectededitlinkUserId === 3
                                        }
                                        Label {
                                            text: "Res Id"
                                            width: 150
                                            height: isDesktop() ? 25 : phoneLarg() ? 50 : 80
                                            font.pixelSize: isDesktop() ? 18 : 40
                                            visible: selectededitlinkUserId === 3
                                        }
                                    }

                                    Column {
                                        spacing: isDesktop() ? 20 : 40
                                        Component.onCompleted: {
                                            if (!isDesktop()) {
                                                width: 350;
                                            }
                                        }

                                        Rectangle {
                                            width: isDesktop() ? 430 : 700
                                            visible: workpersonaSwitchState
                                            height: isDesktop() ? 25 : phoneLarg() ? 50 : 80
                                            color: "transparent"

                                            // Border at the bottom
                                            Rectangle {
                                                width: parent.width
                                                height: isDesktop() ? 1 : 2
                                                color: "black"  // Border color
                                                anchors.bottom: parent.bottom
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                            }

                                            ListModel {
                                                id: accountList
                                            }

                                            TextInput {
                                                id: accountInput
                                                width: parent.width
                                                height: parent.height
                                                font.pixelSize: isDesktop() ? 18 : 40
                                                anchors.fill: parent
                                                Text {
                                                    id: accountplaceholder
                                                    text: "Instance"
                                                    font.pixelSize: isDesktop() ? 18 : 40
                                                    color: "#aaa"
                                                    anchors.fill: parent
                                                    verticalAlignment: Text.AlignVCenter
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: {
                                                        if (!readOnlys) {
                                                            var result = accountlistDataGet();
                                                            if (result) {
                                                                accountList.clear();
                                                                for (var i = 0; i < result.length; i++) {
                                                                    accountList.append(result[i]);
                                                                }
                                                                menuAccount.open();
                                                            }
                                                        }
                                                    }
                                                }

                                                Menu {
                                                    id: menuAccount
                                                    x: accountInput.x
                                                    y: accountInput.y + accountInput.height
                                                    width: accountInput.width

                                                    Repeater {
                                                        model: accountList

                                                        MenuItem {
                                                            width: parent.width
                                                            height: isDesktop() ? 40 : phoneLarg() ? 50 : 80
                                                            property int accountId: model.id
                                                            property string accuntName: model.name || ''
                                                            Text {
                                                                text: accuntName
                                                                font.pixelSize: isDesktop() ? 18 : 40
                                                                bottomPadding: 5
                                                                topPadding: 5
                                                                color: "#000"
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                anchors.left: parent.left
                                                                anchors.leftMargin: 10
                                                                wrapMode: Text.WordWrap
                                                                elide: Text.ElideRight
                                                                maximumLineCount: 2
                                                            }

                                                            onClicked: {
                                                                activityTypeInput.text = "";
                                                                editselectedActivityTypeId = 0;
                                                                accountInput.text = accuntName;
                                                                editselectedAccountUserId = accountId;
                                                                menuAccount.close();
                                                            }
                                                        }
                                                    }
                                                }

                                                onTextChanged: {
                                                    if (accountInput.text.length > 0) {
                                                        accountplaceholder.visible = false;
                                                    } else {
                                                        accountplaceholder.visible = true;
                                                    }
                                                }
                                            }
                                        }

                                        Rectangle {
                                            width: isDesktop() ? 430 : 700
                                            height: isDesktop() ? 25 : phoneLarg() ? 50 : 80
                                            color: "transparent"

                                            Rectangle {
                                                width: parent.width
                                                height: isDesktop() ? 1 : 2
                                                color: "black"
                                                anchors.bottom: parent.bottom
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                            }

                                            ListModel {
                                                id: activityTypeListModel
                                            }

                                            TextInput {
                                                id: activityTypeInput
                                                width: parent.width
                                                height: parent.height
                                                font.pixelSize: isDesktop() ? 18 : 40
                                                anchors.fill: parent
                                                Text {
                                                    id: activitytypeplaceholder
                                                    text: "Activity Type"
                                                    font.pixelSize: isDesktop() ? 18 : 40
                                                    color: "#aaa"
                                                    anchors.fill: parent
                                                    verticalAlignment: Text.AlignVCenter
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: {
                                                        if (!readOnlys) {
                                                            activityTypeListModel.clear();
                                                            var result = fetch_activity_types(editselectedAccountUserId);
                                                            for (var i = 0; i < result.length; i++) {
                                                                activityTypeListModel.append({
                                                                    'id': result[i].id,
                                                                    'name': result[i].name
                                                                });
                                                            }
                                                            menu.open();
                                                        }
                                                    }
                                                }

                                                Menu {
                                                    id: menu
                                                    x: activityTypeInput.x
                                                    y: activityTypeInput.y + activityTypeInput.height
                                                    width: activityTypeInput.width

                                                    Repeater {
                                                        model: activityTypeListModel

                                                        MenuItem {
                                                            width: parent.width
                                                            height: isDesktop() ? 40 : phoneLarg() ? 50 : 80
                                                            property int activityTypeId: model.id
                                                            property string activityTypeName: model.name || ''
                                                            Text {
                                                                text: activityTypeName
                                                                font.pixelSize: isDesktop() ? 18 : 40
                                                                bottomPadding: 5
                                                                topPadding: 5
                                                                color: "#000"
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                anchors.left: parent.left
                                                                anchors.leftMargin: 10
                                                                wrapMode: Text.WordWrap
                                                                elide: Text.ElideRight
                                                                maximumLineCount: 2
                                                            }

                                                            onClicked: {
                                                                editselectedActivityTypeId = activityTypeId;
                                                                activityTypeInput.text = activityTypeName;
                                                                menu.close();
                                                            }
                                                        }
                                                    }
                                                }

                                                onTextChanged: {
                                                    if (activityTypeInput.text.length > 0) {
                                                        activitytypeplaceholder.visible = false;
                                                    } else {
                                                        activitytypeplaceholder.visible = true;
                                                    }
                                                }
                                            }
                                        }

                                        Rectangle {
                                            width: isDesktop() ? 430 : 700
                                            height: isDesktop() ? 25 : phoneLarg() ? 50 : 80
                                            color: "transparent"

                                            // Border at the bottom
                                            Rectangle {
                                                width: parent.width
                                                height: isDesktop() ? 1 : 2
                                                color: "black"
                                                anchors.bottom: parent.bottom
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                            }

                                            ListModel {
                                                id: editaccountUsersList
                                            }

                                            TextInput {
                                                id: edituserInput
                                                width: parent.width
                                                height: parent.height
                                                font.pixelSize: isDesktop() ? 18 : 40
                                                anchors.fill: parent
                                                Text {
                                                    id: edituserplaceholder
                                                    text: "Assignee"
                                                    font.pixelSize: isDesktop() ? 18 : 40
                                                    color: "#aaa"
                                                    anchors.fill: parent
                                                    verticalAlignment: Text.AlignVCenter
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: {
                                                        if (!readOnlys) {
                                                            editaccountUsersList.clear();
                                                            var result = fetch_current_users(editselectedAccountUserId);
                                                            for (var i = 0; i < result.length; i++) {
                                                                editaccountUsersList.append({
                                                                    'id': result[i].id,
                                                                    'name': result[i].name
                                                                });
                                                            }
                                                            usermenu.open();
                                                        }
                                                    }
                                                }

                                                Menu {
                                                    id: usermenu
                                                    x: edituserInput.x
                                                    y: edituserInput.y + edituserInput.height
                                                    width: edituserInput.width

                                                    Repeater {
                                                        model: editaccountUsersList

                                                        MenuItem {
                                                            width: parent.width
                                                            height: isDesktop() ? 40 : phoneLarg() ? 45 : 80
                                                            property int edituserId: model.id
                                                            property string edituserName: model.name || ''
                                                            Text {
                                                                text: edituserName
                                                                font.pixelSize: isDesktop() ? 18 : 40
                                                                bottomPadding: 5
                                                                topPadding: 5
                                                                color: "#000"
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                anchors.left: parent.left
                                                                anchors.leftMargin: 10
                                                                wrapMode: Text.WordWrap
                                                                elide: Text.ElideRight
                                                                maximumLineCount: 2
                                                            }

                                                            onClicked: {
                                                                eidtselectedUserId = edituserId;
                                                                edituserInput.text = edituserName;
                                                                usermenu.close();
                                                            }
                                                        }
                                                    }
                                                }

                                                onTextChanged: {
                                                    if (edituserInput.text.length > 0) {
                                                        edituserplaceholder.visible = false;
                                                    } else {
                                                        edituserplaceholder.visible = true;
                                                    }
                                                }
                                            }
                                        }

                                        Rectangle {
                                            width: isDesktop() ? 430 : 700
                                            height: isDesktop() ? 25 : phoneLarg() ? 50 : 80
                                            color: "transparent"

                                            Rectangle {
                                                width: parent.width
                                                height: isDesktop() ? 1 : 2
                                                color: "black"
                                                anchors.bottom: parent.bottom
                                            }

                                            TextInput {
                                                id: summaryInput
                                                width: parent.width
                                                height: parent.height
                                                font.pixelSize: isDesktop() ? 18 : 40
                                                wrapMode: Text.NoWrap
                                                clip: true
                                                readOnly: readOnlys

                                                Text {
                                                    id: summaryplaceholder
                                                    text: "Summary"
                                                    color: "#aaa"
                                                    font.pixelSize: isDesktop() ? 18 : 40
                                                    anchors.fill: parent
                                                    verticalAlignment: Text.AlignVCenter
                                                    visible: summaryInput.text.length === 0
                                                }

                                                onFocusChanged: {
                                                    summaryplaceholder.visible = !focus && summaryInput.text.length === 0;
                                                }
                                                onTextChanged: {
                                                    summaryplaceholder.visible = !focus && summaryInput.text.length === 0;
                                                }
                                            }
                                        }

                                        Rectangle {
                                            width: isDesktop() ? 430 : 700
                                            height: isDesktop() ? 25 : phoneLarg() ? 50 : 80
                                            color: "transparent"

                                            Rectangle {
                                                width: parent.width
                                                height: isDesktop() ? 1 : 2
                                                color: "black"
                                                anchors.bottom: parent.bottom
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                            }

                                            TextInput {
                                                id: datetimeInput
                                                width: parent.width
                                                height: parent.height
                                                font.pixelSize: isDesktop() ? 18 : 50
                                                anchors.fill: parent

                                                Text {
                                                    id: datetimeplaceholder
                                                    text: "Date"
                                                    font.pixelSize: isDesktop() ? 18 : 30
                                                    color: "#aaa"
                                                    anchors.fill: parent
                                                    verticalAlignment: Text.AlignVCenter
                                                }

                                                Dialog {
                                                    id: calendarDialog
                                                    width: isDesktop() ? 0 : 700
                                                    height: isDesktop() ? 0 : 650
                                                    bottomMargin: 500
                                                    padding: 0
                                                    margins: 0
                                                    visible: false

                                                    DatePicker {
                                                        id: datePicker
                                                        onClicked: {
                                                            datetimeInput.text = Qt.formatDate(datePicker.selectedDate, 'M/d/yyyy');
                                                            calendarDialog.visible = false;
                                                        }
                                                    }
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: {
                                                        if (!readOnlys) {
                                                            var now = new Date();
                                                            datePicker.selectedDate = now;
                                                            calendarDialog.visible = true;
                                                        }
                                                    }
                                                }

                                                onTextChanged: {
                                                    datetimeplaceholder.visible = datetimeInput.text.length === 0;
                                                }

                                                // Set the current date on completion
                                                Component.onCompleted: {
                                                    var currentDate = new Date();
                                                    datetimeInput.text = formatDate(currentDate);
                                                }

                                                function formatDate(date) {
                                                    var month = date.getMonth() + 1; // Months are 0-based
                                                    var day = date.getDate();
                                                    var year = date.getFullYear();
                                                    return month + '/' + day + '/' + year;
                                                }
                                            }
                                        }

                                        Rectangle {
                                            width: isDesktop() ? 430 : 700
                                            height: notesInput.height
                                            color: "transparent"

                                            Rectangle {
                                                width: parent.width
                                                height: isDesktop() ? 1 : 2
                                                color: "black"
                                                anchors.bottom: parent.bottom
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                            }

                                            TextArea {
                                                id: notesInput
                                                background: null
                                                padding: 0
                                                color: "black"
                                                wrapMode: TextArea.Wrap
                                                width: parent.width
                                                font.pixelSize: isDesktop() ? 18 : 40
                                                readOnly: readOnlys
                                                clip: true
                                                anchors.left: parent.left
                                                anchors.leftMargin: (!notesPlaceholder.visible && !isDesktop()) ? -30 : 0                // Clips text within TextInput bounds

                                                Text {
                                                    id: notesplaceholder
                                                    text: "Notes"
                                                    color: "#aaa"
                                                    font.pixelSize: isDesktop() ? 18 : 40
                                                    anchors.fill: parent
                                                    verticalAlignment: Text.AlignVCenter
                                                    visible: notesInput.text.length === 0
                                                }

                                                onFocusChanged: {
                                                    notesplaceholder.visible = !focus && notesInput.text.length === 0;
                                                }

                                                onTextChanged: {
                                                    notesplaceholder.visible = !focus && notesInput.text.length === 0;
                                                }
                                            }
                                        }

                                        Rectangle {
                                            width: isDesktop() ? 430 : 700
                                            height: isDesktop() ? 25 : phoneLarg() ? 50 : 80
                                            color: "transparent"

                                            Rectangle {
                                                width: parent.width
                                                height: isDesktop() ? 1 : 2
                                                color: "black"
                                                anchors.bottom: parent.bottom
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                            }

                                            TextInput {
                                                id: editlinkInput
                                                width: parent.width
                                                height: parent.height
                                                font.pixelSize: isDesktop() ? 18 : 40
                                                anchors.fill: parent

                                                Text {
                                                    id: editlinkplaceholder
                                                    text: "Link to project or task"
                                                    font.pixelSize: isDesktop() ? 18 : 40
                                                    color: "#aaa"
                                                    anchors.fill: parent
                                                    verticalAlignment: Text.AlignVCenter
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: {
                                                        if (!readOnlys) {
                                                            menueditlink.open();
                                                        }
                                                    }
                                                }

                                                Menu {
                                                    id: menueditlink
                                                    x: editlinkInput.x
                                                    y: editlinkInput.y + editlinkInput.height
                                                    width: editlinkInput.width

                                                    Repeater {
                                                        model: editlinkList

                                                        MenuItem {
                                                            width: parent.width
                                                            height: isDesktop() ? 40 : phoneLarg() ? 50 : 80
                                                            property int editlinkId: model.itemId || 0
                                                            property string editlinkName: model.name || ''

                                                            Text {
                                                                text: editlinkName
                                                                font.pixelSize: isDesktop() ? 18 : 40
                                                                color: "#000"
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                anchors.left: parent.left
                                                                anchors.leftMargin: 10
                                                                wrapMode: Text.WordWrap
                                                                elide: Text.ElideRight
                                                                maximumLineCount: 2
                                                            }

                                                            onClicked: {
                                                                editlinkInput.text = editlinkName;
                                                                selectededitlinkUserId = editlinkId;
                                                                menueditlink.close();
                                                            }
                                                        }
                                                    }
                                                }

                                                onTextChanged: {
                                                    editlinkplaceholder.visible = editlinkInput.text.length === 0;
                                                }
                                            }
                                        }

                                        Rectangle {
                                            width: isDesktop() ? 430 : 700
                                            height: isDesktop() ? 25 : phoneLarg() ? 50 : 80
                                            color: "transparent"
                                            visible: selectededitlinkUserId === 1

                                            Rectangle {
                                                width: parent.width
                                                height: isDesktop() ? 1 : 2
                                                color: "black"
                                                anchors.bottom: parent.bottom
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                            }

                                            ListModel {
                                                id: editprojectList
                                            }

                                            TextInput {
                                                id: editprojectInput
                                                width: parent.width
                                                height: parent.height
                                                font.pixelSize: isDesktop() ? 18 : 40
                                                anchors.fill: parent
                                                Text {
                                                    id: editprojectplaceholder
                                                    text: "Project"
                                                    font.pixelSize: isDesktop() ? 18 : 40
                                                    color: "#aaa"
                                                    anchors.fill: parent
                                                    verticalAlignment: Text.AlignVCenter
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: {
                                                        if (!readOnlys) {
                                                            editprojectList.clear();
                                                            if (editselectedAccountUserId != 0) {
                                                                var result = projects_get(editselectedAccountUserId);
                                                                if (result) {
                                                                    for (var i = 0; i < result.length; i++) {
                                                                        editprojectList.append(result[i]);
                                                                    }
                                                                }
                                                            }
                                                            menueditproject.open();
                                                        }
                                                    }
                                                }

                                                Menu {
                                                    id: menueditproject
                                                    x: editprojectInput.x
                                                    y: editprojectInput.y + editprojectInput.height
                                                    width: editprojectInput.width

                                                    Repeater {
                                                        model: editprojectList

                                                        MenuItem {
                                                            width: parent.width
                                                            height: isDesktop() ? 40 : phoneLarg() ? 50 : 80
                                                            property int editprojectId: model.id
                                                            property string editprojectName: model.name || ''
                                                            Text {
                                                                text: editprojectName
                                                                font.pixelSize: isDesktop() ? 18 : 40
                                                                bottomPadding: 5
                                                                topPadding: 5
                                                                color: "#000"
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                anchors.left: parent.left
                                                                anchors.leftMargin: 10
                                                                wrapMode: Text.WordWrap
                                                                elide: Text.ElideRight
                                                                maximumLineCount: 2
                                                            }

                                                            onClicked: {
                                                                editprojectInput.text = editprojectName;
                                                                selectededitprojectUserId = editprojectId;
                                                                menueditproject.close();
                                                            }
                                                        }
                                                    }
                                                }

                                                onTextChanged: {
                                                    if (editprojectInput.text.length > 0) {
                                                        editprojectplaceholder.visible = false;
                                                    } else {
                                                        editprojectplaceholder.visible = true;
                                                    }
                                                }
                                            }
                                        }
                                        // task
                                        Rectangle {
                                            width: isDesktop() ? 430 : 700
                                            height: isDesktop() ? 25 : phoneLarg() ? 50 : 80
                                            color: "transparent"
                                            visible: selectededitlinkUserId === 2

                                            // Border at the bottom
                                            Rectangle {
                                                width: parent.width
                                                height: isDesktop() ? 1 : 2
                                                color: "black"  // Border color
                                                anchors.bottom: parent.bottom
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                            }

                                            ListModel {
                                                id: edittaskList
                                            }

                                            TextInput {
                                                id: edittaskInput
                                                width: parent.width
                                                height: parent.height
                                                font.pixelSize: isDesktop() ? 18 : 40
                                                anchors.fill: parent
                                                readOnly: readOnlys
                                                Text {
                                                    id: edittaskplaceholder
                                                    text: "editTask"
                                                    font.pixelSize: isDesktop() ? 18 : 40
                                                    color: "#aaa"
                                                    anchors.fill: parent
                                                    verticalAlignment: Text.AlignVCenter
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: {
                                                        if (!readOnlys) {
                                                            var result = tasks_list_get(editselectedAccountUserId);
                                                            if (result) {
                                                                edittaskList.clear();
                                                                for (var i = 0; i < result.length; i++) {
                                                                    edittaskList.append(result[i]);
                                                                }
                                                                menuedittask.open();
                                                            }
                                                        }
                                                    }
                                                }

                                                Menu {
                                                    id: menuedittask
                                                    x: edittaskInput.x
                                                    y: edittaskInput.y + edittaskInput.height
                                                    width: edittaskInput.width

                                                    Repeater {
                                                        model: edittaskList

                                                        MenuItem {
                                                            width: parent.width
                                                            height: isDesktop() ? 40 : phoneLarg() ? 50 : 80
                                                            property int edittaskId: model.id
                                                            property string edittaskName: model.name || ''
                                                            Text {
                                                                text: edittaskName
                                                                font.pixelSize: isDesktop() ? 18 : 40
                                                                bottomPadding: 5
                                                                topPadding: 5
                                                                //anchors.centerIn: parent
                                                                color: "#000"
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                anchors.left: parent.left
                                                                anchors.leftMargin: 10
                                                                wrapMode: Text.WordWrap
                                                                elide: Text.ElideRight
                                                                maximumLineCount: 2
                                                            }

                                                            onClicked: {
                                                                edittaskInput.text = edittaskName;
                                                                selectededittaskUserId = edittaskId;
                                                                menuedittask.close();
                                                            }
                                                        }
                                                    }
                                                }

                                                onTextChanged: {
                                                    if (edittaskInput.text.length > 0) {
                                                        edittaskplaceholder.visible = false;
                                                    } else {
                                                        edittaskplaceholder.visible = true;
                                                    }
                                                }
                                            }
                                        }
                                        Rectangle {
                                            width: isDesktop() ? 430 : 700
                                            height: isDesktop() ? 25 : phoneLarg() ? 45 : 80
                                            color: "transparent"
                                            visible: selectededitlinkUserId === 3

                                            Rectangle {
                                                width: parent.width
                                                height: isDesktop() ? 1 : 2
                                                color: "black"
                                                anchors.bottom: parent.bottom
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                            }

                                            Flickable {
                                                id: flickableeditresModel
                                                width: parent.width
                                                height: parent.height
                                                contentWidth: editresModelInput.width
                                                clip: true
                                                interactive: true
                                                property int previousCursorPosition: 0
                                                onContentWidthChanged: {
                                                    if (editresModelInput.cursorPosition > previousCursorPosition) {
                                                        contentX = contentWidth - width;
                                                    } else if (editresModelInput.cursorPosition < previousCursorPosition) {
                                                        contentX = Math.max(0, editresModelInput.cursorRectangle.x - 20);
                                                    }
                                                    previousCursorPosition = editresModelInput.cursorPosition;
                                                }

                                                TextInput {
                                                    id: editresModelInput
                                                    width: Math.max(parent.width, texteditresModelMetrics.width)
                                                    height: parent.height
                                                    font.pixelSize: isDesktop() ? 18 : 40
                                                    wrapMode: Text.NoWrap
                                                    anchors.fill: parent
                                                    readOnly: readOnlys

                                                    Text {
                                                        id: editresModelplaceholder
                                                        text: "Res Model"
                                                        color: "#aaa"
                                                        font.pixelSize: isDesktop() ? 18 : 40
                                                        anchors.fill: parent
                                                        verticalAlignment: Text.AlignVCenter
                                                        visible: editresModelInput.text.length === 0
                                                    }

                                                    onFocusChanged: {
                                                        editresModelplaceholder.visible = !focus && editresModelInput.text.length === 0;
                                                    }
                                                    property real textWidth: texteditresModelMetrics.width
                                                    TextMetrics {
                                                        id: texteditresModelMetrics
                                                        font: editresModelInput.font
                                                        text: editresModelInput.text
                                                    }

                                                    onTextChanged: {
                                                        contentWidth = texteditresModelMetrics.width;
                                                    }

                                                    onCursorPositionChanged: {
                                                        flickableeditresModel.contentX = Math.max(0, editresModelInput.cursorRectangle.x - flickableeditresModel.width + 20);
                                                    }
                                                }
                                            }
                                        }
                                        // res ID
                                        Rectangle {
                                            width: isDesktop() ? 430 : 700
                                            height: isDesktop() ? 25 : phoneLarg() ? 50 : 80
                                            color: "transparent"
                                            visible: selectededitlinkUserId === 3

                                            Rectangle {
                                                width: parent.width
                                                height: isDesktop() ? 1 : 2
                                                color: "black"
                                                anchors.bottom: parent.bottom
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                            }

                                            TextInput {
                                                id: editresIdInput
                                                width: parent.width
                                                height: parent.height
                                                font.pixelSize: isDesktop() ? 18 : 40
                                                anchors.fill: parent
                                                readOnly: readOnlys
                                                Text {
                                                    id: editresIdInputplaceholder
                                                    text: "Res Id"
                                                    color: "#aaa"
                                                    font.pixelSize: isDesktop() ? 18 : 40
                                                    anchors.fill: parent
                                                    verticalAlignment: Text.AlignVCenter
                                                    visible: editresIdInput.text.length === 0
                                                }

                                                onTextChanged: {
                                                    editresIdInputplaceholder.visible = editresIdInput.text.length === 0;
                                                    editresIdInput.text = editresIdInput.text.replace(/[^0-9]/g, "");
                                                }
                                            }
                                        }
                                        TextInput {
                                            id: editschedule
                                            width: parent.width
                                            height: parent.height
                                            font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                                            anchors.fill: parent
                                            visible: false
                                        }
                                        Rectangle {
                                            width: parent.width
                                            height: 50
                                            anchors.left: parent.left
                                            anchors.topMargin: 20
                                            color: "#EFEFEF"

                                            Text {
                                                id: activitySavedMessage
                                                text: isActivityEdit ? "Activity is Edit successfully!" : "Activity could not be Edit!"
                                                color: isActivityEdit ? "green" : "red"
                                                visible: isEditActivityClicked
                                                font.pixelSize: isDesktop() ? 18 : 40
                                                horizontalAlignment: Text.AlignHCenter
                                                anchors.centerIn: parent
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        queryData('pending');
        issearchHeader = false;
    }

    signal newRecordActivity
}
