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
import QtQuick.Window 2.2
import io.thp.pyotherside 1.4
import QtGraphicalEffects 1.7
import QtQuick.LocalStorage 2.7
import Ubuntu.Components 1.3 as Ubuntu
import "Utils.js" as Utils

ApplicationWindow {
    visible: true
    width: Screen.width
    height: Screen.height
    title: "Timesheets"

    property var optionList: []
    property var tasksList: []
    property var taskssmartBtn: null
    property int elapsedTime: 0
    property int selectedquadrantId: 4
    property int selectededitquadrantId: 0
    property int selectedProjectId: 0
    property int editselectedProjectId: 0
    property int selectedSubProjectId: 0
    property int selectededitSubProjectId: 0
    property int selectedTaskId: 0
    property int editselectedTaskId: 0
    property int selectedSubTaskId: 0
    property int selectededitSubTaskId: 0
    property int selectedAccountUserId: 0
    property bool running: false
    property bool hasSubProject: false
    property bool edithasSubProject: false
    property bool hasSubTask: false
    property bool edithasSubTask: false
    property string selected_username: ""
    property bool isTimesheetSaved: false
    property bool isTimesheetClicked: false
    property bool isManualTime: false
    property var currentTime: false
    property int storedElapsedTime: 0
    property var timesheetList: []
    property int currentUserId: 0
    property var timesheetListobject: []
    property bool workpersonaSwitchState: true
    property bool penalOpen: true
    property bool headermainOpen: true
    property int selectedId: -1
    property bool isTimesheetEdit: false
    property bool isEditTimesheetClicked: false
    property bool issearchHeadermain: false
    property bool timestart: false
    property int idstarttime: 0

    property string selectedQuadrantText: ""
    property string accountInputText: ""
    property string projectInputText: ""
    property string subProjectInputText: ""
    property string taskInputText: ""
    property string subTaskInputText: ""
    property string descriptionInputText: ""
    property string datesmartBtnStart: ""

    onActiveChanged: {
        if (active) {
            if (currentTime) {
                if (running) {
                    elapsedTime = parseInt((new Date() - currentTime) / 1000) + storedElapsedTime;
                }
            }
        }
    }

    Python {
        id: python

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('../src/'));
            importModule_sync("backend");
        }

        onError: {}
    }

    Timer {
        id: stopwatchTimer
        interval: 1000
        repeat: true
        onTriggered: {
            elapsedTime += 1;
        }
    }

    function formatTime(seconds) {
        var hours = Math.floor(seconds / 3600);
        var minutes = Math.floor((seconds % 3600) / 60);
        var secs = seconds % 60;

        return (hours < 10 ? "0" + hours : hours) + ":" + (minutes < 10 ? "0" + minutes : minutes) + ":" + (secs < 10 ? "0" + secs : secs);
    }

    function isDesktop() {
        if (Screen.width > 1300) {
            if (Screen.width > 2000 && Screen.height < 1300) {
                return false;
            } else {
                return true;
            }
        } else {
            return false;
        }
    }
    function phoneLarg() {
        if (!isDesktop()) {
            if (Screen.width > 1300) {
                return true;
            } else {
                return false;
            }
        }
        return false;
    }
    ListModel {
        id: treeModel
    }

    function convTimeFloat(value) {
        var vals = value.split(':');
        var hours = parseInt(vals[0], 10);
        var minutes = parseInt(vals[1], 10);

        hours += Math.floor(minutes / 60);
        minutes = minutes % 60;

        return hours.toString().padStart(2, '0') + ':' + minutes.toString().padStart(2, '0');
    }

    function reverseConvTimeFloat(value) {
        var totalHours = Math.floor(value);
        var totalMinutes = Math.round((value - totalHours) * 60);

        var hours = totalHours % 24;
        var days = Math.floor(totalHours / 24);

        var formattedHours = String(hours).padStart(2, '0');
        var formattedMinutes = String(totalMinutes).padStart(2, '0');

        return `${formattedHours}:${formattedMinutes}`;
    }

    ListModel {
        id: quadrantsListModel
        ListElement {
            itemId: 1
            name: "Urgent and important tasks"
        }
        ListElement {
            itemId: 2
            name: "Not urgent, yet important tasks"
        }
        ListElement {
            itemId: 3
            name: "Important but not urgent tasks"
        }
        ListElement {
            itemId: 4
            name: "Not urgent and not important tasks"
        }
    }

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: listPage

        Rectangle {
            id: header_main
            width: parent.width
            height: isDesktop() ? 60 : 120
            color: "#121944"
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            z: 1

            Row {
                anchors.verticalCenter: parent.verticalCenter
                anchors.fill: parent
                height: parent.height
                spacing: 20

                Rectangle {
                    color: "transparent"
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width / 2
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    height: parent.height

                    Row {

                        anchors.verticalCenter: parent.verticalCenter
                        height: parent.height + 20
                        spacing: 10

                        Image {
                            id: img_id
                            source: "images/timemanagementapp_logo_only_white.png"
                            width: isDesktop() ? 65 : 110
                            height: isDesktop() ? 50 : 90
                            anchors.verticalCenter: parent.verticalCenter

                            anchors.left: parent.left
                            anchors.leftMargin: isDesktop() ? 7 : 10
                        }

                        Label {
                            id: time_id
                            text: "Time Management"
                            color: "white"
                            font.pixelSize: isDesktop() ? 20 : 40

                            anchors.left: parent.left
                            anchors.leftMargin: img_id.width - (isDesktop() ? 0 : 5)

                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
                Rectangle {
                    color: "transparent"
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.fill: parent
                    height: parent.height

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        spacing: 10
                        height: parent.height

                        Text {
                            id: personalId
                            text: workpersonaSwitchState ? "Work" : "Personal"
                            color: "white"
                            font.pixelSize: isDesktop() ? 20 : 40
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Rectangle {
                            id: switchBackground
                            width: isDesktop() ? 50 : 150
                            height: isDesktop() ? 20 : 60
                            radius: isDesktop() ? 2 : 4
                            color: workpersonaSwitchState ? "#CCCCCC" : "#008000"
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                id: switchHandle
                                width: isDesktop() ? 22 : 45
                                height: isDesktop() ? 22 : 52
                                radius: isDesktop() ? 2 : 4
                                color: "#FFFFFF"
                                anchors.verticalCenter: parent.verticalCenter
                                visible: !mySwitch.checked
                                anchors.left: parent.left
                            }

                            Rectangle {
                                id: switchHandleright
                                width: isDesktop() ? 22 : 45
                                height: isDesktop() ? 22 : 52
                                radius: isDesktop() ? 2 : 4
                                color: "#FFFFFF"
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                                visible: mySwitch.checked
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    mySwitch.checked = !mySwitch.checked;
                                }
                            }
                        }

                        Switch {
                            id: mySwitch
                            visible: false
                            checked: false
                            onCheckedChanged: {
                                workpersonaSwitchState = !mySwitch.checked;
                                stackView.push(listPage);
                            }
                        }

                        Button {
                            id: hamburgerButton
                            width: isDesktop() ? 60 : 120
                            height: isDesktop() ? 60 : 120
                            anchors.verticalCenter: parent.verticalCenter

                            background: Rectangle {
                                color: "#121944"
                                border.color: "#121944"
                            }

                            Label {
                                text: "☰"
                                font.pixelSize: isDesktop() ? 20 : 40
                                color: "#fff"
                                anchors.centerIn: parent
                            }

                            onClicked: hamburgerButtonmenu.open()
                        }

                        Menu {
                            id: hamburgerButtonmenu
                            x: parent.width - 100
                            y: hamburgerButton.y + hamburgerButton.height
                            width: isDesktop() ? 250 : Screen.width - 100

                            height: isDesktop() ? 200 : Screen.height

                            background: Rectangle {
                                color: "#121944"
                                radius: 4
                                border.color: "#121944"
                                width: Screen.width + 10
                                anchors.top: parent.top
                                anchors.topMargin: isDesktop() ? 0 : -70
                            }

                            Rectangle {
                                id: closeButton
                                visible: isDesktop() ? false : true
                                width: isDesktop() ? 0 : 150
                                height: isDesktop() ? 0 : 150
                                color: "transparent"
                                anchors.left: parent.left
                                anchors.top: parent.top
                                radius: 5
                                border.color: "#121944"
                                Image {
                                    source: "images/cross_wait.svg"
                                    anchors.centerIn: parent
                                    width: isDesktop() ? 0 : 100
                                    height: isDesktop() ? 0 : 100
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        hamburgerButtonmenu.visible = false;
                                    }
                                }
                            }
                            MenuItem {
                                width: parent.width
                                height: isDesktop() ? 37 : 100

                                background: Rectangle {
                                    color: "#121944"
                                    radius: 4

                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.leftMargin: 20
                                    width: parent.width
                                    Rectangle {
                                        visible: isDesktop() ? false : true
                                        anchors.top: parent.top
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        height: 2
                                        color: "#ffffff"
                                    }
                                    Rectangle {
                                        visible: isDesktop() ? false : true
                                        anchors.bottom: parent.bottom
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        height: 2
                                        color: "#ffffff"
                                    }
                                }

                                Text {
                                    text: "Projects"
                                    font.pixelSize: isDesktop() ? 18 : 40
                                    anchors.centerIn: parent
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    color: "#fff"
                                }

                                onClicked: {
                                    stackView.push(projectList);
                                }
                            }

                            MenuItem {
                                width: parent.width
                                height: isDesktop() ? 35 : 100

                                background: Rectangle {
                                    color: "#121944"
                                    radius: 4
                                    anchors.left: parent.left
                                    anchors.leftMargin: 20
                                    width: parent.width

                                    Rectangle {
                                        visible: isDesktop() ? false : true
                                        anchors.bottom: parent.bottom
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        height: 2
                                        color: "#ffffff"
                                    }
                                }

                                Text {
                                    text: "Tasks"
                                    font.pixelSize: isDesktop() ? 18 : 40
                                    anchors.centerIn: parent
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    color: "#fff"
                                }

                                onClicked: {
                                    stackView.push(taskList);
                                }
                            }

                            MenuItem {
                                width: parent.width
                                height: isDesktop() ? 35 : 100

                                background: Rectangle {
                                    color: "#121944"
                                    radius: 4
                                    anchors.left: parent.left
                                    anchors.leftMargin: 20
                                    width: parent.width

                                    Rectangle {
                                        visible: isDesktop() ? false : true
                                        anchors.bottom: parent.bottom
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        height: 2
                                        color: "#ffffff"
                                    }
                                }

                                Text {
                                    text: "Timesheets"
                                    font.pixelSize: isDesktop() ? 18 : 40
                                    anchors.centerIn: parent
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    color: "#fff"
                                }

                                onClicked: {
                                    stackView.push(storedTimesheets);
                                }
                            }
                        }
                    }
                }
            }
        }

        Component {
            id: loginPage
            Item {

                Login {
                    anchors.centerIn: parent
                    onLoggedIn: {
                        currentUserId = currentUserId;
                        selected_username = username;
                        currentTime = false;
                        stopwatchTimer.stop();
                        elapsedTime = 0;
                        storedElapsedTime = 0;
                        running = false;
                        stackView.push(manageAccounts);
                        horizontalPanel.activeImageIndex = 1;
                        verticalPanel.activeImageIndex = 1;
                        penalOpen = true;
                        headermainOpen = true;
                    }
                }
            }
        }

        Component {
            id: activityLists
            Item {
                objectName: "activityLists"
                ActivityList {
                    anchors.centerIn: parent
                    onNewRecordActivity: {
                        stackView.push(activityForm);
                    }
                }
            }
        }

        Component {
            id: activityForm
            Item {
                objectName: "activityForm"
                ActivityForm {
                    anchors.centerIn: parent
                }
            }
        }

        Component {
            id: manageAccounts
            Item {
                ManageAccounts {
                    anchors.top: parent.top
                    anchors.topMargin: 100
                    anchors.centerIn: parent
                    onLogInPage: {
                        stackView.push(loginPage, {
                            'user_name': username,
                            'account_name': name,
                            'selected_database': db,
                            'selected_link': link
                        });

                        penalOpen = true;
                        headermainOpen = false;
                    }
                    onBackPage: {
                        currentTime = false;
                        stopwatchTimer.stop();
                        storedElapsedTime = 0;
                        elapsedTime = 0;
                        running = false;
                        stackView.push(listPage);
                    }
                    onGoToLogin: {
                        stackView.push(loginPage);
                        penalOpen = true;
                        headermainOpen = false;
                    }
                }
            }
        }

        Component {
            id: settingAccounts
            Item {
                Setting {
                    anchors.centerIn: parent
                    onLogInPage: {
                        stackView.push(loginPage, {
                            'user_name': username,
                            'account_name': name,
                            'selected_database': db,
                            'selected_link': link
                        });

                        penalOpen = true;
                        headermainOpen = false;
                    }
                    onBackPage: {
                        currentTime = false;
                        stopwatchTimer.stop();
                        storedElapsedTime = 0;
                        elapsedTime = 0;
                        running = false;
                        stackView.push(listPage);
                    }
                    onGoToLogin: {
                        stackView.push(loginPage);
                        penalOpen = true;
                        headermainOpen = false;
                    }
                }
            }
        }

        Component {
            id: wipmanageAccounts
            Rectangle {
                width: parent.width
                height: parent.height

                Column {
                    spacing: 0
                    anchors.fill: parent
                    Rectangle {
                        width: parent.width
                        height: 100
                        color: "#121944"
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        Rectangle {
                            width: parent.width
                            height: 100
                            color: "#121944"
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 20
                            Image {
                                id: logo
                                source: "images/timeManagemetLogo.png"
                                width: 100
                                height: 100
                                anchors.top: parent.top
                            }
                        }
                        Text {
                            text: "Manage Accounts"
                            anchors.centerIn: parent
                            font.pixelSize: 40
                            color: "#ffffff"
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 80
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.topMargin: 130
                    anchors.leftMargin: 20
                    anchors.right: parent.right
                    Label {
                        font.bold: true
                        font.pixelSize: 50
                        text: "This page is under development"
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 80
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.topMargin: 200
                    anchors.leftMargin: 20
                    anchors.right: parent.right
                    Label {
                        font.pixelSize: 40
                        text: "Agenda of this page is to work with multiple accounts \nwithout logging out, and provide facility to switching \naccounts."
                    }
                }
                Rectangle {
                    width: parent.width
                    height: 80
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.topMargin: 400
                    anchors.leftMargin: 20
                    anchors.right: parent.right
                    Button {
                        id: backButton
                        width: 150
                        height: 130
                        anchors.verticalCenter: parent.verticalCenter

                        background: Rectangle {
                            color: "#121944"
                            border.color: "#121944"
                        }

                        Label {
                            text: "Back"
                            font.pixelSize: 40
                            color: "#fff"
                            anchors.centerIn: parent
                        }

                        onClicked: {
                            currentTime = false;
                            stopwatchTimer.stop();
                            storedElapsedTime = 0;
                            elapsedTime = 0;
                            running = false;
                            stackView.push(listPage);
                        }
                    }
                }
            }
        }

        Component {
            id: storedTimesheets
            Item {
                objectName: "storedTimesheets"
                Timesheetlist {
                    anchors.top: parent.top
                    anchors.topMargin: 100
                    anchors.centerIn: parent
                }
            }
        }

        Component {
            id: projectList
            Item {
                objectName: "projectList"
                Projectlist {
                    anchors.top: parent.top
                    anchors.topMargin: 100
                    anchors.centerIn: parent
                }
            }
        }
        Component {
            id: projectForm
            Item {
                objectName: "projectForm"
                ProjectForm {}
            }
        }

        Component {
            id: taskList
            Item {
                objectName: "taskList"
                TaskList {}
            }
        }

        Component {
            id: taskForm
            Item {
                objectName: "taskForm"
                Taskform {}
            }
        }

        Component {
            id: listPage
            Item {
                Rectangle {
                    id: timesheet_id
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
                        anchors.leftMargin: isDesktop() ? 70 : 10
                        anchors.right: parent.right
                        anchors.rightMargin: isDesktop() ? 15 : 20

                        Rectangle {
                            color: "transparent"
                            width: parent.width / 3
                            anchors.verticalCenter: parent.verticalCenter
                            height: parent.height

                            Row {

                                anchors.verticalCenter: parent.verticalCenter
                                Label {
                                    text: "Time Sheet"
                                    font.pixelSize: isDesktop() ? 20 : 40
                                    anchors.verticalCenter: parent.verticalCenter

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
                                id: timesheedSavedMessage
                                text: isTimesheetSaved ? "Timesheet is Saved successfully!" : "Timesheet could not be saved!"
                                color: isTimesheetSaved ? "green" : "red"
                                visible: isTimesheetClicked
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
                                    var dataArray = [];

                                    var dataObject = {
                                        dateTime: datetimeInput.text,
                                        project: selectedProjectId,
                                        task: selectedTaskId,
                                        subTask: selectedSubTaskId,
                                        isManualTimeRecord: isManualTime,
                                        manualSpentHours: spenthoursManualInput.text,
                                        description: descriptionInput.text,
                                        spenthours: spenthoursInput.text,
                                        projecName: projectInput.text,
                                        instance_id: selectedAccountUserId,
                                        quadrant: selectedquadrantId,
                                        taskName: taskInput.text,
                                        subprojectId: selectedSubProjectId
                                    };
                                    dataArray.push(dataObject);

                                    currentTime = false;
                                    if (running) {
                                        stopwatchTimer.stop();
                                        running = !running;
                                    }
                                    if (workpersonaSwitchState ? accountInput.text : true && (spenthoursManualInput.text || spenthoursInput.text)) {
                                        isTimesheetClicked = true;
                                        isTimesheetSaved = true;
                                        Utils.timesheetData(dataObject);
                                        typingTimer.start();
                                        idstarttime = 0;
                                        timestart = false;
                                    } else {
                                        isTimesheetClicked = true;
                                        isTimesheetSaved = false;
                                        typingTimer.start();
                                    }
                                }
                            }
                            Timer {
                                id: typingTimer
                                interval: 1500
                                running: false
                                repeat: false
                                onTriggered: {
                                    if (isTimesheetSaved) {
                                        elapsedTime = 0;
                                        storedElapsedTime = 0;
                                        isTimesheetClicked = false;
                                        isTimesheetSaved = false;
                                        isManualTime = false;
                                        projectInput.text = "";
                                        selectedProjectId = 0;
                                        selectedSubProjectId = 0;
                                        selectedTaskId = 0;
                                        hasSubTask = false;
                                        selectedSubTaskId = 0;
                                        taskInput.text = "";
                                        hasSubProject = false;
                                        subProjectInput.text = "";
                                        spenthoursManualInput.text = "";
                                        descriptionInput.text = "";
                                        selectedAccountUserId = 0;
                                        accountInput.text = "";
                                        selectedquadrantId = 4;

                                        selectedQuadrantText = "";
                                        accountInputText = "";
                                        projectInputText = "";
                                        subProjectInputText = "";
                                        taskInputText = "";
                                        subTaskInputText = "";
                                        descriptionInputText = "";
                                        taskssmartBtn = null;
                                    } else {
                                        isTimesheetClicked = false;
                                        isTimesheetSaved = false;
                                    }
                                }
                            }
                        }
                    }
                }
                Flickable {
                    id: flickablelistpage
                    width: parent.width

                    height: parent.height
                    contentHeight: fastrow.childrenRect.height + (isDesktop() ? 250 : 500)
                    anchors.fill: parent
                    flickableDirection: Flickable.VerticalFlick
                    clip: true

                    Rectangle {
                        id: list_id
                        width: parent.width
                        height: parent.height
                        anchors.top: parent.top
                        anchors.topMargin: 100
                        color: "#ffffff"
                        Column {
                            spacing: 0
                            anchors.fill: parent

                            Rectangle {
                                id: main_title
                                anchors.top: parent.top
                                width: parent.width
                                height: isDesktop() ? 60 : phoneLarg() ? 45 : phoneLarg() ? 50 : 80

                                anchors.topMargin: isDesktop() ? 15 : 150
                                anchors.left: parent.left
                                anchors.right: parent.right
                                Text {
                                    text: "Hello," + selected_username
                                    anchors.centerIn: parent
                                    font.pixelSize: isDesktop() ? 20 : phoneLarg() ? 30 : 40
                                    color: "#000"
                                }
                            }

                            Item {
                                id: fastrow
                                height: parent.height
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.topMargin: isDesktop() ? 25 : phoneLarg() ? 50 : 80
                                anchors.top: main_title.bottom

                                Row {
                                    id: field_all
                                    spacing: isDesktop() ? 100 : phoneLarg() ? 150 : 200
                                    anchors.verticalCenterOffset: -height * 1.5
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    Column {
                                        spacing: isDesktop() ? 20 : phoneLarg() ? 30 : 40
                                        width: 60
                                        Label {
                                            text: "Instance"
                                            visible: workpersonaSwitchState
                                            width: 150
                                            height: isDesktop() ? 25 : phoneLarg() ? 45 : 80
                                            font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                                        }
                                        Label {
                                            text: "Date"
                                            width: 150
                                            height: isDesktop() ? 25 : phoneLarg() ? 45 : 80
                                            font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                                        }
                                        Label {
                                            text: "Project"
                                            width: 150
                                            height: isDesktop() ? 25 : phoneLarg() ? 45 : 80
                                            font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                                        }

                                        Label {
                                            text: "Sub Project"
                                            width: 150
                                            height: isDesktop() ? 25 : phoneLarg() ? 45 : 80
                                            font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40

                                            visible: hasSubProject
                                        }
                                        Label {
                                            text: "Task"
                                            width: 150
                                            height: isDesktop() ? 25 : phoneLarg() ? 45 : 80
                                            font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                                        }
                                        Label {
                                            text: "Sub Task"
                                            width: 150
                                            height: isDesktop() ? 25 : phoneLarg() ? 45 : 80
                                            font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                                            visible: hasSubTask
                                        }
                                        Label {
                                            text: "Description"
                                            width: 150
                                            height: descriptionInput.height
                                            font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                                        }

                                        Label {
                                            text: "Spent Hours"
                                            width: 150
                                            height: isDesktop() ? 25 : phoneLarg() ? 45 : 80
                                            font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                                        }
                                    }

                                    Column {
                                        id: field_id
                                        spacing: isDesktop() ? 20 : phoneLarg() ? 30 : 40
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
                                                        var result = Utils.accountlistDataGet();
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
                                                            height: isDesktop() ? 40 : phoneLarg() ? 45 : 80
                                                            property int accountId: model.id
                                                            property string accuntName: model.name || ''
                                                            Text {
                                                                text: accuntName
                                                                font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
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
                                                                taskInput.text = '';
                                                                selectedTaskId = 0;
                                                                subTaskInput.text = '';
                                                                selectedSubTaskId = 0;
                                                                hasSubTask = false;
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
                                                    var result = Utils.accountlistDataGet();
                                                    if (result) {
                                                        accountList.clear();
                                                        for (var i = 0; i < result.length; i++) {
                                                            accountList.append(result[i]);
                                                        }
                                                    }
                                                    if (accountList.count > 0) {
                                                        accountInput.text = accountList.get(0).name;
                                                        selectedAccountUserId = accountList.get(0).id;
                                                    }
                                                    if (taskssmartBtn != null && taskssmartBtn.id != null) {
                                                        var db = LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);

                                                        db.transaction(function (tx) {
                                                            if (workpersonaSwitchState) {
                                                                var result = tx.executeSql('SELECT * FROM project_task_app WHERE id = ?', [taskssmartBtn.id]);
                                                            } else {
                                                                var result = tx.executeSql('SELECT * FROM project_task_app where account_id IS NULL AND id = ?', [taskssmartBtn.id]);
                                                            }
                                                            if (result.rows.length > 0) {
                                                                var rowData = result.rows.item(0);
                                                                var projectId = rowData.project_id || "";
                                                                var parentId = rowData.parent_id != null ? rowData.parent_id || "" : "";
                                                                var sub_pro_Id = rowData.sub_project_id != null ? rowData.sub_project_id || "" : "";
                                                                var sub_task_Id = rowData.parent_id != null ? rowData.parent_id || "" : "";
                                                                var accountId = rowData.account_id || "";
                                                                var userId = rowData.user_id || "";

                                                                if (sub_pro_Id != 0) {
                                                                    hasSubProject = true;
                                                                    var sub_project = tx.executeSql('SELECT name FROM project_project_app WHERE id = ?', [sub_pro_Id]);
                                                                    subProjectInput.text = sub_project.rows.length > 0 ? sub_project.rows.item(0).name || "" : "";
                                                                    selectedSubProjectId = sub_pro_Id;
                                                                } else {
                                                                    hasSubProject = false;
                                                                }

                                                                taskInput.text = rowData.name;
                                                                selectedTaskId = taskssmartBtn.id;
                                                                if (sub_task_Id != 0) {
                                                                    hasSubTask = true;
                                                                    var sub_task = tx.executeSql('SELECT name FROM project_task_app WHERE id = ?', [sub_task_Id]);
                                                                    subTaskInput.text = sub_task.rows.length > 0 ? sub_task.rows.item(0).name || "" : "";
                                                                    selectedSubTaskId = sub_task_Id;
                                                                } else {
                                                                    hasSubTask = false;
                                                                }

                                                                var project = tx.executeSql('SELECT name FROM project_project_app WHERE id = ?', [projectId]);
                                                                if (workpersonaSwitchState) {
                                                                    var account = tx.executeSql('SELECT name FROM users WHERE id = ?', [accountId]);
                                                                }

                                                                projectInput.text = project.rows.length > 0 ? project.rows.item(0).name || "" : "";
                                                                selectedProjectId = projectId;

                                                                if (workpersonaSwitchState) {
                                                                    accountInput.text = account.rows.length > 0 ? account.rows.item(0).name || "" : "";
                                                                    selectedAccountUserId = accountId;
                                                                }
                                                                descriptionInput.text = "";
                                                                selectedquadrantId = 4;
                                                                datetimeInput.text = datesmartBtnStart;
                                                            }
                                                        });
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
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                            }
                                            TextInput {
                                                id: datetimeInput
                                                width: parent.width
                                                height: parent.height
                                                font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 35 : 50
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
                                                            calendarDialog.visible = false;
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
                                                id: projectsListModel
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
                                                        projectsListModel.clear();
                                                        var result = Utils.fetch_projects(selectedAccountUserId);
                                                        for (var i = 0; i < result.length; i++) {
                                                            projectsListModel.append({
                                                                'id': result[i].id,
                                                                'name': result[i].name,
                                                                'projectkHasSubProject': result[i].projectkHasSubProject
                                                            });
                                                        }
                                                        menu.open();
                                                    }
                                                }

                                                Menu {
                                                    id: menu
                                                    x: projectInput.x
                                                    y: projectInput.y + projectInput.height
                                                    width: projectInput.width

                                                    Repeater {
                                                        model: projectsListModel

                                                        MenuItem {
                                                            width: parent.width
                                                            height: isDesktop() ? 40 : phoneLarg() ? 45 : 80
                                                            property int projectId: model.id
                                                            property string projectName: model.name || ''
                                                            Text {
                                                                text: projectName
                                                                font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
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
                                                                taskInput.text = '';
                                                                selectedTaskId = 0;
                                                                subTaskInput.text = '';
                                                                selectedSubTaskId = 0;
                                                                hasSubTask = false;
                                                                projectInput.text = projectName;
                                                                subProjectInputText = "";
                                                                selectedProjectId = projectId;
                                                                selectedSubProjectId = 0;
                                                                hasSubProject = model.projectkHasSubProject;
                                                                subProjectInput.text = '';
                                                                menu.close();
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

                                        Rectangle {
                                            width: isDesktop() ? 500 : 750
                                            height: isDesktop() ? 25 : phoneLarg() ? 45 : 80
                                            visible: hasSubProject
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
                                                id: subProjectsListModel
                                            }

                                            TextInput {
                                                //anchors.margins: 5
                                                id: subProjectInput
                                                width: parent.width
                                                height: parent.height
                                                font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                                                anchors.fill: parent
                                                Text {
                                                    id: subProjectplaceholder
                                                    text: "Sub Project"
                                                    font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                                                    color: "#aaa"
                                                    anchors.fill: parent
                                                    verticalAlignment: Text.AlignVCenter
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: {
                                                        var sub_project_list = Utils.fetch_sub_project(selectedProjectId);
                                                        subProjectsListModel.clear();
                                                        for (var i = 0; i < sub_project_list.length; i++) {
                                                            subProjectsListModel.append({
                                                                'id': sub_project_list[i].id,
                                                                'name': sub_project_list[i].name
                                                            });
                                                        }
                                                        subProjectmenu.open();
                                                    }
                                                }

                                                Menu {
                                                    id: subProjectmenu
                                                    x: subProjectInput.x
                                                    y: subProjectInput.y + subProjectInput.height
                                                    width: subProjectInput.width

                                                    Repeater {
                                                        model: subProjectsListModel

                                                        MenuItem {
                                                            width: parent.width
                                                            height: isDesktop() ? 40 : phoneLarg() ? 45 : 80
                                                            property int projectId: model.id
                                                            property string projectName: model.name || ''
                                                            Text {
                                                                text: projectName
                                                                font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
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
                                                                taskInput.text = '';
                                                                selectedTaskId = 0;
                                                                subTaskInput.text = '';
                                                                selectedSubTaskId = 0;
                                                                hasSubTask = false;
                                                                subProjectInput.text = projectName;
                                                                selectedSubProjectId = projectId;
                                                                subProjectmenu.close();
                                                            }
                                                        }
                                                    }
                                                }

                                                onTextChanged: {
                                                    if (subProjectInput.text.length > 0) {
                                                        subProjectplaceholder.visible = false;
                                                    } else {
                                                        subProjectplaceholder.visible = true;
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
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                            }

                                            ListModel {
                                                id: tasksListModel
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
                                                    color: "#aaa"
                                                    font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                                                    anchors.fill: parent
                                                    verticalAlignment: Text.AlignVCenter
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: {
                                                        tasksListModel.clear();
                                                        var tasks_list = Utils.fetch_tasks_list(selectedProjectId, selectedSubProjectId);
                                                        for (var i = 0; i < tasks_list.length; i++) {
                                                            if (tasks_list[i].parent_id == 0) {
                                                                tasksListModel.append({
                                                                    'id': tasks_list[i].id,
                                                                    'name': tasks_list[i].name,
                                                                    'taskHasSubTask': tasks_list[i].taskHasSubTask
                                                                });
                                                            }
                                                        }
                                                        menuTasks.open();
                                                    }
                                                }

                                                Menu {
                                                    id: menuTasks
                                                    x: taskInput.x
                                                    y: taskInput.y + taskInput.height
                                                    width: taskInput.width

                                                    Repeater {
                                                        model: tasksListModel

                                                        MenuItem {
                                                            width: parent.width
                                                            height: isDesktop() ? 40 : phoneLarg() ? 45 : 80
                                                            property int taskId: model.id
                                                            property string taskName: model.name || ''

                                                            Text {
                                                                text: taskName
                                                                font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
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
                                                                selectedTaskId = taskId;
                                                                subTaskInput.text = '';
                                                                selectedSubTaskId = 0;
                                                                hasSubTask = model.taskHasSubTask;
                                                                menu.close();
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
                                            visible: hasSubTask

                                            Rectangle {
                                                width: parent.width
                                                height: isDesktop() ? 1 : 2
                                                color: "black"
                                                anchors.bottom: parent.bottom
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                            }

                                            ListModel {
                                                id: subTasksListModel
                                            }

                                            TextInput {
                                                id: subTaskInput
                                                width: parent.width
                                                height: parent.height
                                                font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                                                anchors.fill: parent
                                                visible: hasSubTask

                                                Text {
                                                    id: subtaskplaceholder
                                                    text: "Sub Task"
                                                    color: "#aaa"
                                                    font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                                                    anchors.fill: parent
                                                    verticalAlignment: Text.AlignVCenter
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: {
                                                        subTasksListModel.clear();
                                                        var sub_tasks_list = Utils.fetch_sub_tasks(selectedTaskId);
                                                        for (var i = 0; i < sub_tasks_list.length; i++) {
                                                            subTasksListModel.append({
                                                                'id': sub_tasks_list[i].id,
                                                                'name': sub_tasks_list[i].name
                                                            });
                                                        }
                                                        menuSubTasks.open();
                                                    }
                                                }

                                                Menu {
                                                    id: menuSubTasks
                                                    x: subTaskInput.x
                                                    y: subTaskInput.y + subTaskInput.height
                                                    width: subTaskInput.width

                                                    Repeater {
                                                        model: subTasksListModel

                                                        MenuItem {
                                                            width: parent.width
                                                            height: isDesktop() ? 40 : phoneLarg() ? 45 : 80
                                                            property int subTaskId: model.id
                                                            property string subTaskName: model.name || ''
                                                            Text {
                                                                text: subTaskName
                                                                font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
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
                                                                subTaskInput.text = subTaskName;
                                                                selectedSubTaskId = subTaskId;
                                                                menu.close();
                                                            }
                                                        }
                                                    }
                                                }

                                                onTextChanged: {
                                                    if (subTaskInput.text.length > 0) {
                                                        subtaskplaceholder.visible = false;
                                                    } else {
                                                        subtaskplaceholder.visible = true;
                                                    }
                                                }
                                            }
                                        }

                                        Rectangle {
                                            width: isDesktop() ? 500 : 750
                                            height: descriptionInput.height
                                            color: "transparent"

                                            Rectangle {
                                                width: parent.width
                                                height: isDesktop() ? 1 : 2
                                                color: "black"
                                                anchors.bottom: parent.bottom
                                            }

                                            TextArea {
                                                id: descriptionInput
                                                width: parent.width
                                                font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                                                wrapMode: TextArea.Wrap
                                                background: null
                                                padding: 0
                                                anchors.left: parent.left
                                                anchors.leftMargin: (!descriptionPlaceholder.visible && !isDesktop()) ? -30 : 0

                                                Text {
                                                    id: descriptionPlaceholder
                                                    text: "Description"
                                                    color: "#aaa"
                                                    font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                                                    anchors.fill: parent
                                                    verticalAlignment: Text.AlignVCenter
                                                    visible: descriptionInput.text.length === 0
                                                }

                                                onFocusChanged: {
                                                    descriptionPlaceholder.visible = !focus && descriptionInput.text.length === 0;
                                                }
                                            }
                                        }

                                        TextInput {
                                            id: spenthoursInput
                                            width: 300
                                            height: 50
                                            font.pixelSize: isDesktop() ? 30 : phoneLarg() ? 35 : 50
                                            text: formatTime(elapsedTime)
                                            validator: RegExpValidator {
                                                regExp: /^([01]?[0-9]|2[0-3]):[0-5][0-9]$/
                                            }
                                            visible: !isManualTime
                                        }

                                        Rectangle {
                                            width: isDesktop() ? 500 : 750
                                            height: isDesktop() ? 25 : phoneLarg() ? 45 : 80

                                            color: "transparent"
                                            visible: isManualTime

                                            Rectangle {
                                                width: parent.width
                                                height: isDesktop() ? 1 : 2
                                                color: "black"
                                                anchors.bottom: parent.bottom
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                            }
                                            TextInput {
                                                id: spenthoursManualInput
                                                width: parent.width
                                                height: parent.height
                                                font.pixelSize: isDesktop() ? 20 : phoneLarg() ? 30 : 40
                                                anchors.fill: parent

                                                Text {
                                                    id: spenthoursManualInputPlaceholder
                                                    text: "00:00"
                                                    color: "#aaa"
                                                    font.pixelSize: isDesktop() ? 20 : phoneLarg() ? 35 : 50
                                                    anchors.fill: parent
                                                    verticalAlignment: Text.AlignVCenter
                                                }

                                                onTextChanged: {
                                                    if (spenthoursManualInput.text.length > 0) {
                                                        spenthoursManualInputPlaceholder.visible = false;
                                                    } else {
                                                        spenthoursManualInputPlaceholder.visible = true;
                                                    }
                                                }
                                            }
                                        }

                                        Row {
                                            spacing: 10
                                            Button {
                                                id: start_stop_id
                                                background: Rectangle {
                                                    color: running ? "lightcoral" : "lightgreen"
                                                    radius: isDesktop() ? 5 : 10
                                                    border.color: running ? "red" : "green"
                                                    border.width: 2
                                                }

                                                contentItem: Text {
                                                    text: running ? "Stop" : "Start"
                                                    color: running ? "darkred" : "darkgreen"
                                                    font.pixelSize: isDesktop() ? 20 : phoneLarg() ? 20 : 30
                                                }
                                                visible: isManualTime ? false : true

                                                onClicked: {
                                                    if (running) {
                                                        currentTime = false;
                                                        storedElapsedTime = elapsedTime;
                                                        stopwatchTimer.stop();
                                                    } else {
                                                        currentTime = new Date();

                                                        stopwatchTimer.start();
                                                    }
                                                    running = !running;
                                                    if (taskssmartBtn != null) {
                                                        timestart = true;
                                                        idstarttime = selectedTaskId;
                                                    }
                                                }
                                            }

                                            Button {

                                                background: Rectangle {
                                                    color: "#121944"
                                                    radius: isDesktop() ? 5 : 10
                                                    border.color: "#87ceeb"
                                                    border.width: 2
                                                }

                                                contentItem: Text {
                                                    text: "Reset"
                                                    color: "#ffffff"
                                                    font.pixelSize: isDesktop() ? 20 : phoneLarg() ? 20 : 30
                                                }
                                                visible: isManualTime ? false : true

                                                text: "Reset"
                                                onClicked: {
                                                    currentTime = false;
                                                    stopwatchTimer.stop();
                                                    elapsedTime = 0;
                                                    storedElapsedTime = 0;
                                                    running = false;
                                                    if (timestart) {
                                                        timestart = false;
                                                        idstarttime = 0;
                                                    }
                                                }
                                            }
                                            Button {

                                                background: Rectangle {
                                                    color: "#121944"
                                                    radius: isDesktop() ? 5 : 10
                                                    border.color: "#87ceeb"
                                                    border.width: 2
                                                }

                                                contentItem: Text {
                                                    text: isManualTime ? "Auto" : "Manual"
                                                    color: "#ffffff"
                                                    font.pixelSize: isDesktop() ? 20 : phoneLarg() ? 20 : 30
                                                }

                                                text: "Reset"
                                                onClicked: {
                                                    stopwatchTimer.stop();
                                                    elapsedTime = 0;
                                                    running = false;
                                                    storedElapsedTime = 0;
                                                    spenthoursManualInput.text = "";
                                                    isManualTime = !isManualTime;
                                                    if (timestart) {
                                                        timestart = false;
                                                        idstarttime = 0;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                Column {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.top: field_all.bottom
                                    anchors.topMargin: isDesktop() ? 20 : phoneLarg() ? 30 : 40
                                    spacing: isDesktop() ? 10 : phoneLarg() ? 15 : 20
                                    width: phoneLarg() ? field_all.width + 40 : field_all.width

                                    Label {
                                        text: "Select Priority Quadrant"
                                        font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 40
                                    }

                                    Row {
                                        spacing: isDesktop() ? 50 : phoneLarg() ? 5 : 10
                                        width: parent.width

                                        Column {
                                            width: parent.width * 0.46
                                            Row {
                                                spacing: 2
                                                RadioButton {
                                                    checked: selectedquadrantId === 1
                                                    onClicked: selectedquadrantId = 1
                                                }
                                                Text {
                                                    text: "Important, Urgent (1)"
                                                    font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 30
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }
                                            }
                                        }

                                        Column {
                                            width: parent.width * 0.5
                                            Row {
                                                spacing: 2
                                                RadioButton {
                                                    checked: selectedquadrantId === 2
                                                    onClicked: selectedquadrantId = 2
                                                }
                                                Text {
                                                    text: "Important, Not Urgent (2)"
                                                    font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 30
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }
                                            }
                                        }
                                    }

                                    Row {
                                        spacing: isDesktop() ? 50 : phoneLarg() ? 5 : 10
                                        width: parent.width

                                        Column {
                                            width: parent.width * 0.46
                                            Row {
                                                spacing: 2
                                                RadioButton {
                                                    checked: selectedquadrantId === 3
                                                    onClicked: selectedquadrantId = 3
                                                }
                                                Text {
                                                    text: "Not Important, Urgent (3)"
                                                    font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 30
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }
                                            }
                                        }

                                        Column {
                                            width: parent.width * 0.5
                                            Row {
                                                spacing: 2
                                                RadioButton {
                                                    checked: selectedquadrantId === 4
                                                    onClicked: selectedquadrantId = 4
                                                }
                                                Text {
                                                    text: "Not Important, Not Urgent (4)"
                                                    font.pixelSize: isDesktop() ? 18 : phoneLarg() ? 30 : 30
                                                    anchors.verticalCenter: parent.verticalCenter
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

        Rectangle {
            id: horizontalPanel
            visible: (penalOpen && !isDesktop()) ? true : false
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 100
            color: "#121944"
            z: 1

            property int activeImageIndex: 1
            property int imageCount: 4
            property real totalImageHeight: imageCount * (isDesktop() ? 40 : 80)
            property real dynamicSpacing: (parent.width - totalImageHeight) / (imageCount)
            Row {
                anchors.fill: parent
                anchors.margins: 10
                spacing: horizontalPanel.dynamicSpacing
                anchors.left: parent.left
                anchors.leftMargin: horizontalPanel.dynamicSpacing / 2

                Image {
                    id: image1
                    source: "images/home.svg"
                    width: 80
                    height: 80
                    opacity: horizontalPanel.activeImageIndex === 1 ? 1 : 0.5

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            stackView.push(listPage);
                            horizontalPanel.activeImageIndex = 1;
                            headermainOpen = true;
                        }
                    }
                }

                Image {
                    id: image2
                    source: "images/refresh.svg"
                    width: 80
                    height: 80
                    opacity: horizontalPanel.activeImageIndex === 2 ? 1 : 0.5

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            stackView.push(manageAccounts);
                            horizontalPanel.activeImageIndex = 2;
                            headermainOpen = true;
                        }
                    }
                }

                Image {
                    id: image3
                    source: "images/activity.svg"
                    width: 80
                    height: 80
                    opacity: horizontalPanel.activeImageIndex === 3 ? 1 : 0.5

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            horizontalPanel.activeImageIndex = 3;
                            stackView.push(activityLists);
                            headermainOpen = true;
                        }
                    }
                }

                Image {
                    id: image4
                    source: "images/setting.svg"
                    anchors.rightMargin: 20
                    width: 80
                    height: 80
                    opacity: horizontalPanel.activeImageIndex === 4 ? 1 : 0.5

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            horizontalPanel.activeImageIndex = 4;

                            stackView.push(settingAccounts);
                            headermainOpen = true;
                        }
                    }
                }
            }
        }

        Rectangle {
            id: verticalPanel
            visible: (penalOpen && isDesktop()) ? true : false
            anchors.top: header_main.bottom
            width: isDesktop() ? 60 : 100
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            color: "#121944"
            z: 1

            property int activeImageIndex: 1

            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 30

                Image {
                    id: verticalHome
                    source: "images/home.svg"
                    width: isDesktop() ? 40 : 80
                    height: isDesktop() ? 40 : 80
                    anchors.horizontalCenter: parent.horizontalCenter
                    opacity: verticalPanel.activeImageIndex === 1 ? 1 : 0.5

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            verticalPanel.activeImageIndex = 1;
                            stackView.push(listPage);
                            headermainOpen = true;
                        }
                    }
                }

                Image {
                    id: verticalRefresh
                    source: "images/refresh.svg"
                    width: isDesktop() ? 40 : 80
                    height: isDesktop() ? 40 : 80
                    anchors.horizontalCenter: parent.horizontalCenter
                    opacity: verticalPanel.activeImageIndex === 2 ? 1 : 0.5

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            verticalPanel.activeImageIndex = 2;
                            stackView.push(manageAccounts);
                            headermainOpen = true;
                        }
                    }
                }

                Image {
                    id: verticalActivity
                    source: "images/activity.svg"
                    width: isDesktop() ? 40 : 80
                    height: isDesktop() ? 40 : 80
                    anchors.horizontalCenter: parent.horizontalCenter
                    opacity: verticalPanel.activeImageIndex === 3 ? 1 : 0.5

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            verticalPanel.activeImageIndex = 3;

                            stackView.push(activityLists);
                            headermainOpen = true;
                        }
                    }
                }

                Image {
                    id: verticalSetting
                    source: "images/setting.svg"
                    width: isDesktop() ? 40 : 80
                    height: isDesktop() ? 40 : 80
                    anchors.horizontalCenter: parent.horizontalCenter
                    opacity: verticalPanel.activeImageIndex === 4 ? 1 : 0.5

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            verticalPanel.activeImageIndex = 4;
                            stackView.push(settingAccounts);
                            headermainOpen = true;
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        Utils.prepare_database();
        issearchHeadermain = false;
    }
}
