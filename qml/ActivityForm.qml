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
import QtQuick.Controls.Material 2.1

Item {
    width: parent.width
    height: parent.height
    property int selectedActivityTypeId: 0
    property int currentRecordId: 0
    property int selectedcontactId: 0
    property bool isactivitySaved: false
    property bool isactivityClicked: false
    property int selectedUserId: 0
    property int selectedlinkUserId: 0
    property int selectedprojectUserId: 0
    property int selectedtaskUserId: 0

    function createActivity(selectedAccountUserId, selectedActivityTypeId, datetimeInput, summaryInput, notesInput, user_id, selectedlinkUserId, selectedprojectUserId, selectedtaskUserId, resModelInput, resIdInput, scheduleInput) {
        var db = LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
        db.transaction(function (tx) {
            if (selectedActivityTypeId && datetimeInput) {
                var result = tx.executeSql('INSERT INTO mail_activity_app (account_id, activity_type_id, summary, due_date, notes, user_id, link_id, project_id, task_id, resId, resModel, state, last_modified)\
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', [selectedAccountUserId, selectedActivityTypeId, summaryInput, datetimeInput, notesInput, user_id, selectedlinkUserId, selectedprojectUserId, selectedtaskUserId, resIdInput, resModelInput, scheduleInput, new Date().toISOString()]);
                isactivitySaved = true;
                isactivityClicked = true;
                dataClear();
            } else {
                isactivitySaved = false;
                isactivityClicked = true;
            }
        });
    }

    function dataClear() {
        selectedAccountUserId = 0;
        selectedUserId = 0;
        accountInput.text = "";
        selectedActivityTypeId = 0;
        activityTypeInput.text = "";
        summaryInput.text = "";
        notesInput.text = "";
        userInput.text = "";
        isactivitySaved = false;
        isactivityClicked = false;
        projectInput.text = "";
        selectedprojectUserId = 0;
        taskInput.text = "";
        selectedtaskUserId = 0;
        linkInput.text = "";
        selectedlinkUserId = 0;
        resModelInput.text = "";
        resIdInput.text = "";
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

    function fetch_current_users(selectedAccountUserId) {
        var db = LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
        var activity_type_list = [];
        db.transaction(function (tx) {
            var instance_users = tx.executeSql('select * from res_users_app where account_id = ?', [selectedAccountUserId]);
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
        id: linkList
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
        id: newActivity
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
            anchors.leftMargin: isDesktop() ? 55 : -10
            anchors.right: parent.right
            anchors.rightMargin: isDesktop() ? 15 : 20

            Rectangle {
                color: "transparent"
                width: parent.width / 3
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height

                Row {
                    anchors.verticalCenter: parent.verticalCenter

                    ToolButton {
                        width: isDesktop() ? 40 : 80
                        height: isDesktop() ? 35 : 80
                        background: Rectangle {
                            color: "transparent"
                        }
                        contentItem: Ubuntu.Icon {
                            name: "back"
                        }
                        onClicked: {
                            stackView.push(activityLists);
                        }
                    }

                    Label {
                        text: "Activities"
                        font.pixelSize: isDesktop() ? 20 : 40
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: ToolButton.right
                        font.bold: true
                        color: "#121944"
                    }
                }
            }

            Rectangle {
                color: "transparent"
                width: parent.width / 3
                height: parent.height
                anchors.horizontalCenter: parent.horizontalCenter

                Text {
                    id: activitySavedMessage
                    text: isactivitySaved ? "Activity is Saved successfully!" : "Activity could not be saved!"
                    color: isactivitySaved ? "green" : "red"
                    visible: isactivityClicked
                    font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                    horizontalAlignment: Text.AlignHCenter
                    anchors.centerIn: parent
                }
            }

            Rectangle {
                color: "transparent"
                width: parent.width / 3
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                anchors.right: parent.right

                Button {
                    id: rightButton
                    width: isDesktop() ? 20 : 50
                    height: isDesktop() ? 20 : 50
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right

                    Image {
                        source: "images/right.svg" // Image source
                        width: isDesktop() ? 20 : 50
                        height: isDesktop() ? 20 : 50
                    }

                    background: Rectangle {
                        color: "transparent"
                        radius: 10
                        border.color: "transparent"
                    }
                    onClicked: {
                        if (selectedActivityTypeId && datetimeInput) {
                            createActivity(selectedAccountUserId, selectedActivityTypeId, datetimeInput.text, summaryInput.text, notesInput.text, selectedUserId, selectedlinkUserId, selectedprojectUserId, selectedtaskUserId, resModelInput.text, resIdInput.text, schedule.text);
                            isactivitySaved = true;
                            isactivityClicked = true;
                            typingTimers.start();
                        } else {
                            isactivitySaved = false;
                            isactivityClicked = true;
                            typingTimers.start();
                        }
                    }
                }
                Timer {
                    id: typingTimers
                    interval: 1500
                    running: false
                    repeat: false
                    onTriggered: {
                        if (isactivitySaved) {
                            selectedAccountUserId = 0;
                            selectedUserId = 0;
                            accountInput.text = "";
                            selectedActivityTypeId = 0;
                            activityTypeInput.text = "";
                            summaryInput.text = "";
                            notesInput.text = "";
                            userInput.text = "";
                            isactivitySaved = false;
                            isactivityClicked = false;
                            projectInput.text = "";
                            selectedprojectUserId = 0;
                            taskInput.text = "";
                            selectedtaskUserId = 0;
                            linkInput.text = "";
                            selectedlinkUserId = 0;
                            resModelInput.text = "";
                            resIdInput.text = "";
                        } else {
                            isTimesheetClicked = false;
                            isactivityClicked = false;
                        }
                    }
                }
            }
        }
    }

    Flickable {
        id: flickableContainer
        width: parent.width
        height: parent.height
        contentHeight: activityForm.childrenRect.height + 350
        anchors.fill: parent
        flickableDirection: Flickable.VerticalFlick
        clip: true

        Rectangle {
            id: activityForm
            anchors.top: parent.top
            anchors.topMargin: isDesktop() ? 200 : phoneLarg() ? 240 : 300
            anchors.left: parent.left
            anchors.leftMargin: isDesktop() ? 70 : 20
            anchors.right: parent.right
            anchors.rightMargin: isDesktop() ? 10 : 20
            color: "#ffffff"
            height: childrenRect.height + 20

            Row {
                spacing: isDesktop() ? 100 : 200
                anchors.verticalCenterOffset: -height * 1.5
                anchors.horizontalCenter: parent.horizontalCenter

                Column {
                    spacing: isDesktop() ? 20 : phoneLarg() ? 30 : 40
                    width: 60
                    Label {
                        text: "Instance"
                        width: 150
                        visible: workpersonaSwitchState
                        height: isDesktop() ? 25 : phoneLarg() ? 45 : 80
                        font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                    }
                    Label {
                        text: "Activity Type"
                        width: 150
                        height: isDesktop() ? 25 : phoneLarg() ? 45 : 80
                        font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                    }
                    Label {
                        text: "Assigned To"
                        width: 150
                        height: isDesktop() ? 25 : phoneLarg() ? 45 : 80
                        font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                    }
                    Label {
                        text: "Summary"
                        width: 150
                        height: isDesktop() ? 25 : phoneLarg() ? 45 : 80
                        font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                    }

                    Label {
                        text: "Due Date"
                        width: 150
                        height: isDesktop() ? 25 : phoneLarg() ? 45 : 80
                        font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                    }
                    Label {
                        text: "Notes"
                        width: 150
                        height: notesInput.height
                        font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                    }
                    Label {
                        text: "Link To"
                        width: 150
                        height: isDesktop() ? 25 : phoneLarg() ? 45 : 80
                        font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                    }
                    Label {
                        text: "Project Id"
                        width: 150
                        height: isDesktop() ? 25 : phoneLarg() ? 45 : 80
                        font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                        visible: selectedlinkUserId === 1
                    }
                    Label {
                        text: "Task Id"
                        width: 150
                        height: isDesktop() ? 25 : phoneLarg() ? 45 : 80
                        font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                        visible: selectedlinkUserId === 2
                    }
                    Label {
                        text: "Res Model"
                        width: 150
                        height: isDesktop() ? 25 : phoneLarg() ? 45 : 80
                        font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                        visible: selectedlinkUserId === 3
                    }
                    Label {
                        text: "Res Id"
                        width: 150
                        height: isDesktop() ? 25 : phoneLarg() ? 45 : 80
                        font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                        visible: selectedlinkUserId === 3
                    }
                }

                Column {
                    spacing: isDesktop() ? 20 : phoneLarg() ? 30 : 40
                    Component.onCompleted: {
                        if (!isDesktop()) {
                            width: 350;
                        }
                    }

                    Rectangle {
                        width: isDesktop() ? 500 : 750
                        visible: workpersonaSwitchState
                        height: isDesktop() ? 25 : phoneLarg() ? 45 : 80
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
                            id: accountList
                        }

                        TextInput {
                            id: accountInput
                            width: parent.width
                            height: parent.height
                            font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                            anchors.fill: parent
                            Text {
                                id: accountplaceholder
                                text: "Instance"
                                font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                                color: "#aaa"
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
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
                                            activityTypeInput.text = '';
                                            selectedActivityTypeId = 0;
                                            projectInput.text = '';
                                            selectedprojectUserId = 0;
                                            taskInput.text = '';
                                            selectedtaskUserId = 0;
                                            accountInput.text = accuntName;
                                            selectedAccountUserId = accountId;
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
                            Component.onCompleted: {
                                var result = accountlistDataGet();
                                if (result) {
                                    accountList.clear();
                                    for (var i = 0; i < result.length; i++) {
                                        accountList.append(result[i]);
                                    }
                                }
                                if (accountList.count > 0 && workpersonaSwitchState) {
                                    // Default selection when component loads and has items
                                    accountInput.text = accountList.get(0).name;
                                    selectedAccountUserId = accountList.get(0).id;
                                }
                                var result = fetch_activity_types(selectedAccountUserId);
                                var filteredList = result.filter(function (item) {
                                    return item.name === "To Do";
                                });
                                if (filteredList.length > 0) {
                                    activityTypeInput.text = filteredList[0].name;
                                    selectedActivityTypeId = filteredList[0].id;
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: isDesktop() ? 500 : 750
                        height: isDesktop() ? 25 : phoneLarg() ? 45 : 80
                        color: "transparent"

                        Rectangle {
                            width: parent.width
                            height: isDesktop() ? 1 : 2
                            color: "black"  // Border color
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
                            font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                            anchors.fill: parent
                            Text {
                                id: activitytypeplaceholder
                                text: "Activity Type"
                                font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                                color: "#aaa"
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    activityTypeListModel.clear();
                                    var result = fetch_activity_types(selectedAccountUserId);
                                    for (var i = 0; i < result.length; i++) {
                                        activityTypeListModel.append({
                                            'id': result[i].id,
                                            'name': result[i].name
                                        });
                                    }
                                    menu.open();
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
                                            selectedActivityTypeId = activityTypeId;
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
                        width: isDesktop() ? 500 : 750
                        height: isDesktop() ? 25 : phoneLarg() ? 45 : 80
                        color: "transparent"

                        Rectangle {
                            width: parent.width
                            height: isDesktop() ? 1 : 2
                            color: "black"  // Border color
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                        }

                        ListModel {
                            id: accountUsersList
                        }

                        TextInput {
                            id: userInput
                            width: parent.width
                            height: parent.height
                            font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                            anchors.fill: parent
                            Text {
                                id: userplaceholder
                                text: "Assignee"
                                font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                                color: "#aaa"
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    accountUsersList.clear();
                                    var result = fetch_current_users(selectedAccountUserId);
                                    for (var i = 0; i < result.length; i++) {
                                        accountUsersList.append({
                                            'id': result[i].id,
                                            'name': result[i].name
                                        });
                                    }
                                    usermenu.open();
                                }
                            }

                            Menu {
                                id: usermenu
                                x: userInput.x
                                y: userInput.y + userInput.height
                                width: userInput.width

                                Repeater {
                                    model: accountUsersList

                                    MenuItem {
                                        width: parent.width
                                        height: isDesktop() ? 40 : phoneLarg() ? 50 : 80
                                        property int userId: model.id
                                        property string userName: model.name || ''
                                        Text {
                                            text: userName
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
                                            selectedUserId = userId;
                                            userInput.text = userName;
                                            usermenu.close();
                                        }
                                    }
                                }
                            }

                            onTextChanged: {
                                if (userInput.text.length > 0) {
                                    userplaceholder.visible = false;
                                } else {
                                    userplaceholder.visible = true;
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: isDesktop() ? 500 : 750
                        height: isDesktop() ? 25 : phoneLarg() ? 45 : 80
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
                            font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                            wrapMode: Text.NoWrap
                            clip: true

                            Text {
                                id: summaryPlaceholder
                                text: "Summary"
                                color: "#aaa"
                                font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                visible: summaryInput.text.length === 0
                            }
                            onFocusChanged: {
                                summaryPlaceholder.visible = !focus && summaryInput.text.length === 0;
                            }
                        }
                    }

                    Rectangle {
                        width: isDesktop() ? 500 : 750
                        height: isDesktop() ? 25 : phoneLarg() ? 45 : 80
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
                            font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 50
                            anchors.fill: parent
                            Text {
                                id: datetimeplaceholder
                                text: "Date"
                                font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 20 : 30
                                color: "#aaa"
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                            }

                            Dialog {
                                id: calendarDialog
                                width: isDesktop() ? 0 : phoneLarg() ? 550 : 700
                                height: isDesktop() ? 0 : phoneLarg() ? 450 : 650
                                padding: 0
                                margins: 0
                                visible: false

                                DatePicker {
                                    id: datePicker
                                    onClicked: {
                                        datetimeInput.text = Qt.formatDate(date, 'M/d/yyyy').toString();
                                    }
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    var now = new Date();
                                    datePicker.selectedDate = now;
                                    datePicker.currentIndex = now.getMonth();
                                    datePicker.selectedYear = now.getFullYear();
                                    calendarDialog.visible = true;
                                }
                            }

                            onTextChanged: {
                                if (datetimeInput.text.length > 0) {
                                    datetimeplaceholder.visible = false;
                                } else {
                                    datetimeplaceholder.visible = true;
                                }
                            }
                            function formatDate(date) {
                                var month = date.getMonth() + 1;
                                var day = date.getDate();
                                var year = date.getFullYear();
                                return month + '/' + day + '/' + year;
                            }

                            Component.onCompleted: {
                                var currentDate = new Date();
                                datetimeInput.text = formatDate(currentDate);
                            }
                        }
                    }

                    Rectangle {
                        width: isDesktop() ? 500 : 750
                        height: notesInput.height
                        color: "transparent"

                        Rectangle {
                            width: parent.width
                            height: isDesktop() ? 1 : 2
                            color: "black"
                            anchors.bottom: parent.bottom
                        }

                        TextArea {
                            id: notesInput
                            background: null
                            padding: 0
                            color: "black"
                            wrapMode: TextArea.Wrap
                            width: parent.width
                            font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                            clip: true
                            anchors.left: parent.left
                            anchors.leftMargin: (!notesPlaceholder.visible && !isDesktop()) ? -30 : 0

                            Text {
                                id: notesPlaceholder
                                text: "Notes"
                                color: "#aaa"
                                font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                visible: notesInput.text.length === 0
                            }

                            onFocusChanged: {
                                notesPlaceholder.visible = !focus && notesInput.text.length === 0;
                            }
                        }
                    }
                    // link
                    Rectangle {
                        width: isDesktop() ? 500 : 750
                        height: isDesktop() ? 25 : phoneLarg() ? 45 : 80
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
                            id: linkInput
                            width: parent.width
                            height: parent.height
                            font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                            anchors.fill: parent

                            Text {
                                id: linkplaceholder
                                text: "Link to project or task"
                                font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                                color: "#aaa"
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    menulink.open();
                                }
                            }

                            Menu {
                                id: menulink
                                x: linkInput.x
                                y: linkInput.y + linkInput.height
                                width: linkInput.width

                                Repeater {
                                    model: linkList

                                    MenuItem {
                                        width: parent.width
                                        height: isDesktop() ? 40 : phoneLarg() ? 50 : 80
                                        property int linkId: model.itemId || 0
                                        property string linkName: model.name || ''

                                        Text {
                                            text: linkName
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
                                            linkInput.text = linkName;
                                            selectedlinkUserId = linkId;

                                            menulink.close();
                                        }
                                    }
                                }
                            }

                            onTextChanged: {
                                linkplaceholder.visible = linkInput.text.length === 0;
                            }
                        }
                    }

                    Rectangle {
                        width: isDesktop() ? 500 : 750
                        height: isDesktop() ? 25 : phoneLarg() ? 45 : 80
                        color: "transparent"
                        visible: selectedlinkUserId === 1

                        Rectangle {
                            width: parent.width
                            height: isDesktop() ? 1 : 2
                            color: "black"
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                        }

                        ListModel {
                            id: projectList
                        }

                        TextInput {
                            id: projectInput
                            width: parent.width
                            height: parent.height
                            font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                            anchors.fill: parent
                            Text {
                                id: projectplaceholder
                                text: "Project"
                                font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                                color: "#aaa"
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    projectList.clear();
                                    if (selectedAccountUserId != 0) {
                                        var result = projects_get(selectedAccountUserId);
                                        if (result) {
                                            for (var i = 0; i < result.length; i++) {
                                                projectList.append(result[i]);
                                            }
                                        }
                                    }
                                    menuproject.open();
                                }
                            }

                            Menu {
                                id: menuproject
                                x: projectInput.x
                                y: projectInput.y + projectInput.height
                                width: projectInput.width

                                Repeater {
                                    model: projectList

                                    MenuItem {
                                        width: parent.width
                                        height: isDesktop() ? 40 : phoneLarg() ? 50 : 80
                                        property int projectId: model.id
                                        property string projectName: model.name || ''
                                        Text {
                                            text: projectName
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
                                            projectInput.text = projectName;
                                            selectedprojectUserId = projectId;
                                            menuproject.close();
                                        }
                                    }
                                }
                            }

                            onTextChanged: {
                                if (projectInput.text.length > 0) {
                                    projectplaceholder.visible = false;
                                } else {
                                    projectplaceholder.visible = true;
                                }
                            }
                        }
                    }
                    // task
                    Rectangle {
                        width: isDesktop() ? 500 : 750
                        height: isDesktop() ? 25 : phoneLarg() ? 45 : 80
                        color: "transparent"
                        visible: selectedlinkUserId === 2

                        Rectangle {
                            width: parent.width
                            height: isDesktop() ? 1 : 2
                            color: "black"
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                        }

                        ListModel {
                            id: taskList
                        }

                        TextInput {
                            id: taskInput
                            width: parent.width
                            height: parent.height
                            font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                            anchors.fill: parent
                            Text {
                                id: taskplaceholder
                                text: "Task"
                                font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                                color: "#aaa"
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    var result = tasks_list_get(selectedAccountUserId);
                                    if (result) {
                                        taskList.clear();
                                        for (var i = 0; i < result.length; i++) {
                                            taskList.append(result[i]);
                                        }
                                        menutask.open();
                                    }
                                }
                            }

                            Menu {
                                id: menutask
                                x: taskInput.x
                                y: taskInput.y + taskInput.height
                                width: taskInput.width

                                Repeater {
                                    model: taskList

                                    MenuItem {
                                        width: parent.width
                                        height: isDesktop() ? 40 : phoneLarg() ? 50 : 80
                                        property int taskId: model.id
                                        property string taskName: model.name || ''
                                        Text {
                                            text: taskName
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
                                            taskInput.text = taskName;
                                            selectedtaskUserId = taskId;
                                            menutask.close();
                                        }
                                    }
                                }
                            }

                            onTextChanged: {
                                if (taskInput.text.length > 0) {
                                    taskplaceholder.visible = false;
                                } else {
                                    taskplaceholder.visible = true;
                                }
                            }
                        }
                    }
                    Rectangle {
                        width: isDesktop() ? 500 : 750
                        height: isDesktop() ? 25 : phoneLarg() ? 45 : 80
                        color: "transparent"
                        visible: selectedlinkUserId === 3

                        Rectangle {
                            width: parent.width
                            height: isDesktop() ? 1 : 2
                            color: "black"
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                        }

                        Flickable {
                            id: flickableresModel
                            width: parent.width
                            height: parent.height
                            contentWidth: resModelInput.width
                            clip: true
                            interactive: true
                            property int previousCursorPosition: 0
                            onContentWidthChanged: {
                                if (resModelInput.cursorPosition > previousCursorPosition) {
                                    contentX = contentWidth - width;
                                } else if (resModelInput.cursorPosition < previousCursorPosition) {
                                    contentX = Math.max(0, resModelInput.cursorRectangle.x - 20);
                                }
                                previousCursorPosition = resModelInput.cursorPosition;
                            }

                            TextInput {
                                id: resModelInput
                                width: Math.max(parent.width, textresModelMetrics.width)
                                height: parent.height
                                font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                                wrapMode: Text.NoWrap
                                anchors.fill: parent

                                Text {
                                    id: resModelplaceholder
                                    text: "Res Model"
                                    color: "#aaa"
                                    font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                                    anchors.fill: parent
                                    verticalAlignment: Text.AlignVCenter
                                    visible: resModelInput.text.length === 0
                                }

                                onFocusChanged: {
                                    resModelplaceholder.visible = !focus && resModelInput.text.length === 0;
                                }
                                property real textWidth: textresModelMetrics.width
                                TextMetrics {
                                    id: textresModelMetrics
                                    font: resModelInput.font
                                    text: resModelInput.text
                                }

                                onTextChanged: {
                                    contentWidth = textresModelMetrics.width;
                                }

                                onCursorPositionChanged: {
                                    flickableresModel.contentX = Math.max(0, resModelInput.cursorRectangle.x - flickableresModel.width + 20);
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: isDesktop() ? 500 : 750
                        height: isDesktop() ? 25 : phoneLarg() ? 45 : 80
                        color: "transparent"
                        visible: selectedlinkUserId === 3

                        Rectangle {
                            width: parent.width
                            height: isDesktop() ? 1 : 2
                            color: "black"
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                        }

                        TextInput {
                            id: resIdInput
                            width: parent.width
                            height: parent.height
                            font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                            anchors.fill: parent
                            Text {
                                id: resIdInputplaceholder
                                text: "Res Id"
                                color: "#aaa"
                                font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                visible: resIdInput.text.length === 0
                            }

                            onTextChanged: {
                                resIdInputplaceholder.visible = resIdInput.text.length === 0;

                                resIdInput.text = resIdInput.text.replace(/[^0-9]/g, "");
                            }
                        }
                    }
                    TextInput {
                        id: schedule
                        width: parent.width
                        height: parent.height
                        font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                        anchors.fill: parent
                        visible: false
                        text: "schedule"
                    }
                }
            }
        }
    }
    Component.onCompleted: {
        dataClear();
        linkInput.text = "Contact";
        selectedlinkUserId = 0;
    }
}
