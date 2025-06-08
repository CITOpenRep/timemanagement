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
import "../models/task.js" as Task
import "../models/timesheet.js" as Timesheet
import "../models/utils.js" as Utils
import "components"

Page {
    id: taskDetails
    title: "Task Details"

    property var recordid: 0
    property bool workpersonaSwitchState: true
    property bool isReadOnly: true
    property var tasks: []
    property var taskdata: []
    property var startdatestr: ""
    property var enddatestr: ""
    property var deadlinestr: ""
    /*    property var project: ""
    property var parentname: ""
    property var account: ""
    property var user: "" */
    property int selectedAccountUserId: 0
    property int selectedProjectId: 0
    property int selectedassigneesUserId: 0
    property int selectedparentId: 0
    property int selectedInstanceId: 0
    property int selectedTaskId: 0
    property int favorites: 0
    property var prevproject: ""
    property var prevInstanceId: 0
    property var prevassignee: ""
    property var prevtask: ""

    header: PageHeader {
        StyleHints {
            foregroundColor: LomiriColors.orange
            backgroundColor: LomiriColors.background
            dividerColor: LomiriColors.slate
        }

        title: taskDetails.title
        ActionBar {
            numberOfSlots: 1
            anchors.right: parent.right
            actions: [
                Action {
                    iconSource: "images/save.svg"
                    text: "Save"
                    enabled: !taskDetails.isReadOnly
                    onTriggered: {
                        isReadOnly = !isReadOnly;
                        console.log("Save Task clicked");
                        save_task_data();
                    }
                }
            ]
        }
    }

    function get_id(model, criteria) {
        console.log("get_id criteria: " + criteria + " model.count: " + model.count);
        for (var i = 0; i < model.count; ++i) {
            console.log("get_id criteria: " + criteria + " model.name: " + model.get(i).name.substring(0, model.get(i).name.indexOf("[")));
            if (model.get(i).name.substring(0, model.get(i).name.indexOf("[")) === criteria)
                return i;
        }
        return -1;
    }

    function get_task_list(recordid) {
        console.log("In get_task_list()");
        var tasklist = Task.fetch_tasks_lists(recordid);
        console.log("Tasks: " + tasklist[0].name);
        console.log("Tasks: " + tasklist[0].user_id);
        return tasklist;
    }

    function save_task_data() {
        var instanceid = Utils.getAccountIdByName(tasks[0].accountName); // Its really bad , to get the correct index
        console.log("Account id to sync is " + instanceid);
        var selectedProjectId = tasks[0].project_id;
        var selectedassigneesUserId = tasks[0].user_id;

        const data = {
            accountId: instanceid // unified key name
            ,
            name: task_text.text,
            projectId: projectCombo.selectedProjectId,
            subProjectId: 0,
            parentId: selectedparentId,
            startDate: start_text.text,
            endDate: end_text.text,
            deadline: deadline_text.text,
            favorites: favorites,
            plannedHours: hours_text.text,
            description: description_text.text,
            assigneeUserId: assigneeCombo.selectedUserId,
            status: "updated",
            rowId: tasks[0].id // presence of rowId determines update vs insert
        };

        const result = Task.saveOrUpdateTask(data);
        if (!result.success) {
            notifPopup.open("Error", "Unable to Save the Task", "error");
        } else {
            notifPopup.open("Saved", "Task has been saved successfully", "success");
        }
    }

    function prepare_assignee_list() {
        var assignees = Task.getAssigneeList();
        console.log("In prepare_assignee_list()  ");
        assigneeModel.clear();
        assigneeModel1.clear();
        for (var assignee = 0; assignee < assignees.length; assignee++) {
            assigneeModel1.append({
                'id': assignees[assignee].id,
                'name': assignees[assignee].name
            });
            assigneeModel.append({
                'name': assignees[assignee].name + "[" + assignees[assignee].id + "]"
            });
        }
    /*        for (var assignee = 0; assignee < assigneeModel.count; assignee++) {
            console.log("AssigneeModel1 " + "id: " + assigneeModel1.get(assignee).id + " Assignee: " + assigneeModel1.get(assignee).name)
            console.log("assigneeModel " + " Asignee: " + assigneeModel.get(assignee).name)
        } */
    }

    function prepare_project_list() {
        var projects = Timesheet.fetch_projects(selectedInstanceId, workpersonaSwitchState);
        console.log("In prepare_project_list()  " + selectedInstanceId);
        projectModel.clear();
        projectModel1.clear();
        for (var project = 0; project < projects.length; project++) {
            projectModel1.append({
                'id': projects[project].id,
                'name': projects[project].name,
                'projectHasSubProject': projects[project].projectHasSubProject
            });
            projectModel.append({
                'name': projects[project].name + "[" + projects[project].id + "]"
            });
        }
        for (var project = 0; project < projectModel.count; project++) {
            console.log("ProjectModel1 " + "id: " + projectModel1.get(project).id + " Project: " + projectModel1.get(project).name);
            console.log("ProjectModel " + " Project: " + projectModel.get(project).name);
        }
    }

    function prepare_task_list(project_id) {
        var tasks = Timesheet.fetch_tasks_list(project_id, 0, workpersonaSwitchState);
        taskModel.clear();
        taskModel1.clear();
        selectedTaskId = 0;
        //        console.log("Passed Project ID: " + project_id + " SubProjectID: " + selectedsubProjectId + " Tasks Found: " + tasks.length)
        for (var task = 0; task < tasks.length; task++) {
            taskModel1.append({
                'id': tasks[task].id,
                'name': tasks[task].name,
                'taskHasSubTask': tasks[task].taskHasSubTask
            });
            taskModel.append({
                'name': tasks[task].name + "[" + tasks[task].id + "]"
            });
        }
    }

    function set_assignee_id(assignee_name) {
        for (var assignee = 0; assignee < assigneeModel.count; assignee++) {
            if (assigneeModel1.get(assignee).name === assignee_name) {
                console.log("set_assignee_id " + "id: " + assigneeModel1.get(assignee).id + " Assignee: " + assigneeModel1.get(assignee).name);
                selectedassigneesUserId = assigneeModel1.get(assignee).id;
            }
        }
    }

    function set_project_id(project_name) {
        for (var project = 0; project < project_name.length; ++project) {
            if (project_name.substring(project, project + 1) === "[") {
                selectedProjectId = parseInt(project_name.substring(project + 1, ((project_name.length) - 1)));
                break;
            }
        }
        const name = project_name.split("[");
        for (var project = 0; project < projectModel1.count; project++) {
            var index = prevproject.indexOf("[");
            console.log("Index of [ " + index);
        }
        if (prevproject != name[0]) {
            console.log("prevproject = " + prevproject + " name = " + name[0]);
            task_field.currentIndex = -1;
        }
        prevproject = name[0];
        console.log("Set Project Id: Name = " + name[0]);
        console.log("selectedProjectId = " + selectedProjectId);
    }

    function set_task_id(task_name) {
        console.log("set_task_id called task_name: " + task_name);
        for (var task = 0; task < task_name.length; task++) {
            if (task_name.substring(task, task + 1) === "[") {
                selectedparentId = parseInt(task_name.substring(task + 1, ((task_name.length) - 1)));
            }
        }
        const name = task_name.split("[");

        if (prevtask != name[0]) {
            console.log("prevtask = " + prevtask + " name = " + name[0]);
        }
        prevtask = name[0];

        console.log("Set Task Id: Name = " + name[0] + " selectedparentId: " + selectedparentId);
        console.log("selectedparentId = " + selectedparentId);
    }

    function set_instance_id(instance_name) {
        for (var instance = 0; instance < instanceModel.count; instance++) {
            if (instanceModel1.get(instance).name === instance_name) {
                console.log("set_instance_id " + "id: " + instanceModel1.get(instance).id + " Instance: " + instanceModel1.get(instance).name);
                selectedInstanceId = instanceModel1.get(instance).id;
            }
        }
    }

    ListModel {
        id: taskModel1
    }

    ListModel {
        id: assigneeModel1
    }

    ListModel {
        id: projectModel1
    }

    Flickable {
        id: rect1
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        //radius: "large"
        width: parent.width
        height: parent.height

        Row {
            id: myRow1a
            anchors.left: parent.left
            topPadding: 10
            Column {
                leftPadding: units.gu(2)
                LomiriShape {
                    width: units.gu(10)
                    height: units.gu(5)
                    aspect: LomiriShape.Flat
                    Label {
                        id: instance_label
                        font.bold: true
                        text: "Instance"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        //textSize: Label.Large
                    }
                }
            }
            Column {
                leftPadding: units.gu(3)
                AccountSelector {
                    id: accountCombo
                    editable: true
                    width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                    height: units.gu(6)
                    anchors.centerIn: parent.centerIn
                    enabled: !taskDetails.isReadOnly
                    flat: true
                    onAccountSelected: {
                        //fetch the users from the account
                        assigneeCombo.accountId = id;
                        assigneeCombo.loadUsers();

                        //fetch projects
                        projectCombo.accountId = id;
                        projectCombo.loadProjects();
                    }
                    Component.onCompleted: {
                        accountCombo.selectAccountById(tasks[0].account_id);
                    }
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
                LomiriShape {
                    width: units.gu(10)
                    height: units.gu(5)
                    aspect: LomiriShape.Flat
                    Label {
                        id: task_label
                        font.bold: true
                        text: "Task Name"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        //textSize: Label.Large
                    }
                }
            }
            Column {
                leftPadding: units.gu(3)
                TextField {
                    id: task_text
                    readOnly: isReadOnly
                    width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                    text: tasks[0].name
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
                LomiriShape {
                    width: units.gu(10)
                    height: units.gu(5)
                    aspect: LomiriShape.Flat
                    Label {
                        id: assignee_label
                        font.bold: true
                        text: "Assignee"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        //textSize: Label.Large
                    }
                }
            }
            Column {
                leftPadding: units.gu(3)
                LomiriShape {
                    width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                    height: 60

                    UserSelector {
                        id: assigneeCombo
                        editable: true
                        width: parent.width
                        height: parent.height
                        anchors.centerIn: parent.centerIn
                        flat: true
                        enabled: !taskDetails.isReadOnly
                        Component.onCompleted: {
                            assigneeCombo.accountId = tasks[0].account_id;
                            assigneeCombo.loadUsers();
                            projectCombo.selectProjectById(tasks[0].user);
                        }
                    }
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
                LomiriShape {
                    width: units.gu(10)
                    height: units.gu(5)
                    aspect: LomiriShape.Flat
                    Label {
                        id: description_label
                        font.bold: true
                        text: "Description"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        //textSize: Label.Large
                    }
                }
            }
            Column {
                id: myCol9
                leftPadding: units.gu(3)
                TextArea {
                    id: description_text
                    readOnly: isReadOnly
                    maximumLineCount: 1
                    width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                    anchors.centerIn: parent.centerIn
                    text: Utils.stripHtmlTags(tasks[0].description)
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
                LomiriShape {
                    width: units.gu(10)
                    height: units.gu(5)
                    aspect: LomiriShape.Flat
                    Label {
                        id: project_label
                        font.bold: true
                        text: "Project"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        //textSize: Label.Large
                    }
                }
            }
            Column {
                leftPadding: units.gu(3)
                LomiriShape {
                    width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                    height: 60
                    ProjectSelector {
                        id: projectCombo
                        enabled: !taskDetails.isReadOnly
                        width: parent.width
                        height: parent.height
                        anchors.centerIn: parent.centerIn
                        flat: true
                        onProjectSelected: {
                            selectedProjectId = id;
                            // do follow-up logic, e.g. load tasks
                        }
                        Component.onCompleted: {
                            projectCombo.accountId = tasks[0].account_id;
                            projectCombo.loadProjects();
                            projectCombo.selectProjectById(tasks[0].project_id);
                        }
                    }
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
                LomiriShape {
                    width: units.gu(10)
                    height: units.gu(5)
                    aspect: LomiriShape.Flat
                    Label {
                        id: parent_label
                        text: "Parent Task"
                        font.bold: true
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        //textSize: Label.Large
                    }
                }
            }
            Column {
                id: myCol11
                leftPadding: units.gu(3)
                LomiriShape {
                    width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                    height: 60
                    ComboBox {
                        id: task_field
                        editable: true
                        enabled: !taskDetails.isReadOnly
                        editText: taskdata[0].parentname
                        width: parent.width
                        height: parent.height
                        anchors.centerIn: parent.centerIn
                        flat: true

                        model: ListModel {
                            id: taskModel
                        }

                        onActivated: {
                            console.log("In onActivated");
                            if (prevtask != editText.substring(0, editText.indexOf("["))) {
                                set_task_id(editText);
                                console.log("Task ID: " + selectedTaskId);
                            }
                        }
                        onHighlighted: {}
                        onAccepted: {
                            console.log("In onAccepted");
                            if (find(editText) != -1) {
                                set_task_id(editText);
                                console.log("Task ID: " + selectedTaskId);
                            }
                        }
                    }
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
                LomiriShape {
                    width: units.gu(10)
                    height: units.gu(5)
                    aspect: LomiriShape.Flat
                    Label {
                        id: hours_label
                        text: "Planned Hours"
                        font.bold: true
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        //textSize: Label.Large
                    }
                }
            }
            Column {
                leftPadding: units.gu(3)
                TextField {
                    id: hours_text
                    readOnly: isReadOnly
                    width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                    anchors.centerIn: parent.centerIn
                    text: tasks[0].allocated_hours
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
                LomiriShape {
                    width: units.gu(10)
                    height: units.gu(5)
                    aspect: LomiriShape.Flat
                    Label {
                        id: start_label
                        text: "Start Date"
                        font.bold: true
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        //textSize: Label.Large
                    }
                }
            }
            Column {
                leftPadding: units.gu(3)
                TextField {
                    id: start_text
                    readOnly: isReadOnly
                    width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                    anchors.centerIn: parent.centerIn
                    text: tasks[0].start_date
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (date_field.visible === false) {
                                if (!isReadOnly) {
                                    date_field.visible = !date_field.visible;
                                    start_text.text = "";
                                }
                            } else {
                                date_field.visible = !date_field.visible;
                                start_text.text = Utils.formatOdooDateTime(date_field.date);
                                startdatestr = Utils.formatOdooDateTime(date_field.date);
                            }
                        }
                    }
                }
                DatePicker {
                    id: date_field
                    visible: false
                    z: 1
                    minimum: {
                        var d = new Date();
                        d.setFullYear(d.getFullYear() - 1);
                        return d;
                    }
                    maximum: Date.prototype.getInvalidDate.call()
                }
            }
        }

        Row {
            id: myRow6
            anchors.top: myRow5.bottom
            anchors.left: parent.left
            topPadding: 10
            Column {
                leftPadding: units.gu(2)
                LomiriShape {
                    width: units.gu(10)
                    height: units.gu(5)
                    aspect: LomiriShape.Flat
                    Label {
                        id: end_label
                        text: "End Date"
                        font.bold: true
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        //textSize: Label.Large
                    }
                }
            }
            Column {
                leftPadding: units.gu(3)
                TextField {
                    id: end_text
                    readOnly: isReadOnly
                    width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                    anchors.centerIn: parent.centerIn
                    text: tasks[0].end_date
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (date_field2.visible === false) {
                                if (!isReadOnly) {
                                    date_field2.visible = !date_field2.visible;
                                    end_text.text = "";
                                }
                            } else {
                                date_field2.visible = !date_field2.visible;
                                end_text.text = Utils.formatOdooDateTime(date_field2.date);
                                enddatestr = Utils.formatOdooDateTime(date_field2.date);
                            }
                        }
                    }
                }
                DatePicker {
                    id: date_field2
                    visible: false
                    z: 1
                    minimum: {
                        var d = new Date();
                        d.setFullYear(d.getFullYear() - 1);
                        return d;
                    }
                    maximum: Date.prototype.getInvalidDate.call()
                }
            }
        }

        Row {
            id: myRow7
            anchors.top: myRow6.bottom
            anchors.left: parent.left
            topPadding: 10
            Column {
                leftPadding: units.gu(2)
                LomiriShape {
                    width: units.gu(10)
                    height: units.gu(5)
                    aspect: LomiriShape.Flat
                    Label {
                        id: deadline_label
                        text: "Deadline"
                        font.bold: true
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        //textSize: Label.Large
                    }
                }
            }
            Column {
                leftPadding: units.gu(3)
                TextField {
                    id: deadline_text
                    readOnly: isReadOnly
                    width: Screen.desktopAvailableWidth < units.gu(250) ? units.gu(30) : units.gu(60)
                    anchors.centerIn: parent.centerIn
                    text: tasks[0].deadline
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (date_field3.visible === false) {
                                if (!isReadOnly) {
                                    date_field3.visible = !date_field3.visible;
                                    deadline_text.text = "";
                                }
                            } else {
                                date_field3.visible = !date_field3.visible;
                                deadline_text.text = Utils.formatOdooDateTime(date_field3.date);
                                deadline_text = Utils.formatOdooDateTime(date_field3.date);
                            }
                        }
                    }
                }
                DatePicker {
                    id: date_field3
                    visible: false
                    z: 1
                    minimum: {
                        var d = new Date();
                        d.setFullYear(d.getFullYear() - 1);
                        return d;
                    }
                    maximum: Date.prototype.getInvalidDate.call()
                }
            }
        }

        Row {
            id: myRow8
            anchors.top: myRow7.bottom
            anchors.left: parent.left
            topPadding: 10
            Column {
                leftPadding: units.gu(2)
                LomiriShape {
                    width: units.gu(10)
                    height: units.gu(5)
                    aspect: LomiriShape.Flat
                    Label {
                        id: priority_label
                        text: "Priority"
                        font.bold: true
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        //textSize: Label.Large
                    }
                }
            }
            Column {
                leftPadding: units.gu(3)
                Row {
                    id: img_star
                    width: units.gu(20)
                    height: units.gu(20)
                    spacing: 5
                    property int selectedPriority: 0

                    Repeater {
                        model: 1
                        delegate: Item {
                            width: units.gu(5)
                            height: units.gu(5)

                            Image {
                                id: starImage
                                source: (index < favorites) ? "images/star-active.svg" : "images/starinactive.svg"
                                anchors.fill: parent
                                smooth: true

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (!isReadOnly) {
                                            if (index + 1 === favorites) {
                                                favorites = !favorites;
                                                console.log("Favorites is: " + favorites);
                                            } else {
                                                favorites = !favorites;
                                                console.log("Favorites is: " + favorites);
                                            }
                                        } else {
                                            console.log("Favorites is: " + favorites + " Index is: " + index);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        NotificationPopup {
            id: notifPopup
            width: units.gu(80)
            height: units.gu(80)
            onClosed: console.log("Notification dismissed")
        }

        Component.onCompleted: {
            tasks = get_task_list(recordid);
            //            prepare_project_list();
            console.log("From Task Page " + apLayout.columns);
            console.log("From Task Page ID " + recordid);
            console.log("From Task Page  tasks: " + tasks[0].id);
            console.log("From Task Page  Account ID: " + tasks[0].account_id + " Account Name: " + tasks[0].accountName);
            taskdata = Task.fetch_task_details(tasks);
            console.log("Taskdata: " + taskdata[0].project + " User: " + taskdata[0].user + " Parentname: " + taskdata[0].parentname);
            favorites = tasks[0].favorites;
            console.log("Description is: " + tasks[0].description);
            console.log("OnComplete Favorites is: " + tasks[0].favorites);
            selectedInstanceId = tasks[0].account_id;
            selectedProjectId = tasks[0].project_id;
            selectedparentId = (tasks[0].parent_id === null) ? 0 : tasks[0].parent_id;
            selectedassigneesUserId = tasks[0].account_id;

            tasks[0].description = tasks[0].description.replace(/<[^>]+>/g, " ").replace(/<p>;/g, "").replace(/&nbsp;/g, "").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&amp;/g, "&").replace(/&quot;/g, "\"").replace(/&#39;/g, "'").trim() || "";
        }
    }
}
