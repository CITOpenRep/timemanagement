import QtQuick 2.7
import QtQuick.Controls 2.2
import Lomiri.Components 1.3
import "../../models/constants.js" as AppConst
import "../../models/project.js" as Project
import "../../models/accounts.js" as Accounts
import "../../models/task.js" as Task

Rectangle {
    id: workItemSelector
    width: parent ? parent.width : Screen.width
    height: contentColumn.implicitHeight
    color: "transparent"

    // Visibility control properties
    property bool showAccountSelector: true
    property bool showProjectSelector: true
    property bool showSubProjectSelector: true
    property bool showTaskSelector: true
    property bool showSubTaskSelector: true
    property bool readOnly: false
    property string accountLabelText: "Account"
    property string projectLabelText: "Project"
    property string subProjectLabelText: "Subproject"
    property string taskLabelText: "Task"
    property string subTaskLabelText: "Subtask"
    property bool showAssigneeSelector: false
    property string assigneeLabelText: "Assignee"

    signal accountChanged(int accountId)

    function applyDeferredSelection(accountId, projectId, subProjectId, taskId, subTaskId, assigneeId) {
        if (accountSelector.model.count === 0) {
            deferredApplyTimer.deferredPayload = {
                accountId: accountId,
                projectId: projectId,
                subProjectId: subProjectId,
                taskId: taskId,
                subTaskId: subTaskId,
                assigneeId: assigneeId
            };
            deferredApplyTimer.start();
            return;
        }

        accountSelector.selectAccountById(accountId);
        reloadProjectSelector(accountId, projectId);
        reloadSubProjectSelector(accountId, projectId, subProjectId);
        reloadTaskSelector(accountId, taskId);
        reloadSubTaskSelector(accountId, taskId, subTaskId);
        reloadAssigneeSelector(accountId, assigneeId);
    }

    function reloadAssigneeSelector(accountId, selectedAssigneeId) {
        let rawAssignees = Accounts.getUsers(accountId);
        let flatModel = [];

        flatModel.push({ id: -1, name: "Unassigned", parent_id: null });

        let selectedText = "Unassigned";
        let selectedFound = (selectedAssigneeId === -1);

        for (let i = 0; i < rawAssignees.length; i++) {
            let id = accountId === 0 ? rawAssignees[i].id : rawAssignees[i].odoo_record_id;
            let name = rawAssignees[i].name;

            flatModel.push({ id: id, name: name, parent_id: null });

            if (selectedAssigneeId === id) {
                selectedText = name;
                selectedFound = true;
            }
        }

        assigneeSelector.dataList = flatModel;
        assigneeSelector.reload();

        assigneeSelector.selectedId = selectedFound ? selectedAssigneeId : -1;
        assigneeSelector.currentText = selectedFound ? selectedText : "Select Assignee";
    }

    function reloadProjectSelector(accountId, selectedProjectId) {
        let rawProjects = Project.getProjectsForAccount(accountId);
        let flatModel = [];

        flatModel.push({ id: -1, name: "No Project", parent_id: null });

        let selectedText = "No Project";
        let selectedFound = (selectedProjectId === -1);

        for (let i = 0; i < rawProjects.length; i++) {
            let id = accountId === 0 ? rawProjects[i].id : rawProjects[i].odoo_record_id;
            let name = rawProjects[i].name;
            let parentId = rawProjects[i].parent_id;

            // ✅ Only add top-level projects
            if (parentId === null || parentId === 0) {
                flatModel.push({ id: id, name: name, parent_id: null });

                if (selectedProjectId === id) {
                    selectedText = name;
                    selectedFound = true;
                }
            }
        }

        projectSelector.dataList = flatModel;
        projectSelector.reload();

        projectSelector.selectedId = selectedFound ? selectedProjectId : -1;
        projectSelector.currentText = selectedFound ? selectedText : "Select Project";
    }


    function reloadSubProjectSelector(accountId, parentProjectId, selectedSubProjectId) {
        let rawProjects = Project.getProjectsForAccount(accountId);
        let flatModel = [];

        flatModel.push({ id: -1, name: "No SubProject", parent_id: null });

        let selectedText = "No Project";
        let selectedFound = (selectedSubProjectId === -1);


        for (let i = 0; i < rawProjects.length; i++) {
            let id = accountId === 0 ? rawProjects[i].id : rawProjects[i].odoo_record_id;
            let name = rawProjects[i].name;
            let parentId = rawProjects[i].parent_id;

            if (parentId === parentProjectId) {
                flatModel.push({ id: id, name: name, parent_id: null });

                if (selectedSubProjectId === id) {
                    selectedText = name;
                    selectedFound = true;
                }
            }
        }

        console.log("Below is data fromr reloadSubProjectSelector")
        console.log("SubProject Model: " + JSON.stringify(flatModel));

        subProjectSelector.dataList = flatModel;
        subProjectSelector.reload();

        subProjectSelector.selectedId = selectedFound ? selectedSubProjectId : -1;
        subProjectSelector.currentText = selectedFound ? selectedText : "Select Subproject";
    }


    function reloadTaskSelector(accountId, selectedTaskId) {
        let rawTasks = Task.getTasksForAccount(accountId);
        let flatModel = [];

        flatModel.push({ id: -1, name: "No Task", parent_id: null });

        let selectedText = "No Task";
        let selectedFound = (selectedTaskId === -1);

        for (let i = 0; i < rawTasks.length; i++) {
            let id = accountId === 0 ? rawTasks[i].id : rawTasks[i].odoo_record_id;
            let name = rawTasks[i].name;
            let parentId = rawTasks[i].parent_id;

            // ✅ Only add top-level tasks (no parent or parent = 0)
            if (parentId === null || parentId === 0) {
                flatModel.push({ id: id, name: name, parent_id: null });

                if (selectedTaskId === id) {
                    selectedText = name;
                    selectedFound = true;
                }
            }
        }

        taskSelector.dataList = flatModel;
        taskSelector.reload();

        taskSelector.selectedId = selectedFound ? selectedTaskId : -1;
        taskSelector.currentText = selectedFound ? selectedText : "Select Task";
    }


    function reloadSubTaskSelector(accountId, parentTaskId, selectedSubTaskId) {
        let rawTasks = Task.getTasksForAccount(accountId);
        let flatModel = [];

        let selectedText = "No Subtask";
        let selectedFound = (selectedSubTaskId === -1);

        for (let i = 0; i < rawTasks.length; i++) {
            let id = accountId === 0 ? rawTasks[i].id : rawTasks[i].odoo_record_id;
            let name = rawTasks[i].name;
            let parentId = rawTasks[i].parent_id;

            if (parentId === parentTaskId) {
                // ✅ Insert as top-level for SubTaskSelector
                flatModel.push({ id: id, name: name, parent_id: null });

                if (selectedSubTaskId === id) {
                    selectedText = name;
                    selectedFound = true;
                }
            }
        }

        console.log("Below is data from reloadSubTaskSelector");
        console.log("SubTask Model: " + JSON.stringify(flatModel));

        subTaskSelector.dataList = flatModel;
        subTaskSelector.reload();

        subTaskSelector.selectedId = selectedFound ? selectedSubTaskId : -1;
        subTaskSelector.currentText = selectedFound ? selectedText : "Select Subtask";
    }

    function getAllSelectedDbRecordIds() {
        return {
            accountDbId: accountSelector.selectedInstanceId,
            projectDbId: projectSelector.selectedId,
            subProjectDbId: subProjectSelector.selectedId,
            taskDbId: taskSelector.selectedId,
            subTaskDbId: subTaskSelector.selectedId,
            assigneeDbId: assigneeSelector.selectedId
        };
    }

    Column {
        id: contentColumn
        width: parent.width
        spacing: units.gu(1)

        Row {
            width: parent.width
            visible: showAccountSelector
            height: units.gu(5)
            TSLabel {
                width: parent.width * 0.25
                anchors.verticalCenter: parent.verticalCenter
                text: accountLabelText
                verticalAlignment: Text.AlignVCenter
            }
            Item {
                width: parent.width * 0.75
                height: units.gu(5)
                anchors.verticalCenter: parent.verticalCenter
                AccountSelector {
                    id: accountSelector
                    anchors.centerIn: parent
                    anchors.verticalCenter: parent.verticalCenter
                    enabled: !readOnly
                    editable: false
                    onAccountSelected: {
                        reloadProjectSelector(accountSelector.selectedInstanceId);
                        reloadSubProjectSelector(accountSelector.selectedInstanceId, -1, -1);
                        reloadTaskSelector(accountSelector.selectedInstanceId);
                        reloadSubTaskSelector(accountSelector.selectedInstanceId, -1, -1);
                        accountChanged(accountSelector.selectedInstanceId);
                        reloadAssigneeSelector(accountSelector.selectedInstanceId);
                    }
                }
            }
        }

        Row {
            width: parent.width
            visible: showProjectSelector
            height: units.gu(5)
            TreeSelector {
                id: projectSelector
                enabled: !readOnly
                labelText: projectLabelText
                width: parent.width
                height: units.gu(29)

                onItemSelected: {
                    let accountId = accountSelector.selectedInstanceId;
                    let selectedProjectId = projectSelector.selectedId;

                    let children = Project.getProjectsForAccount(accountId)
                    .filter(function(proj) {
                        return proj.parent_id === selectedProjectId;
                    });

                    console.log("Project Selected ID: " + selectedProjectId);
                    console.log("Children count: " + children.length);
                    console.log("Children JSON: " + JSON.stringify(children));

                    if (children.length > 0) {
                        showSubProjectSelector = true;
                        reloadSubProjectSelector(accountId, selectedProjectId, -1);
                    } else {
                        showSubProjectSelector = false;
                    }
                }

            }
        }


        Row {
            width: parent.width
            visible: showSubProjectSelector
            height: units.gu(5)
            TreeSelector {
                id: subProjectSelector
                enabled: !readOnly
                labelText: subProjectLabelText
                width: parent.width
                height: units.gu(29)
            }
        }

        Row {
            width: parent.width
            visible: showTaskSelector
            height: units.gu(5)
            TreeSelector {
                id: taskSelector
                enabled: !readOnly
                labelText: taskLabelText
                width: parent.width
                height: units.gu(29)
                onItemSelected: {
                    let accountId = accountSelector.selectedInstanceId;
                    let selectedTaskId = taskSelector.selectedId;

                    let children = Task.getTasksForAccount(accountId)
                    .filter(function(task) {
                        return task.parent_id === selectedTaskId;
                    });

                    console.log("Task Selected ID: " + selectedTaskId);
                    console.log("Subtask children count: " + children.length);
                    console.log("Subtask children JSON: " + JSON.stringify(children));

                    if (children.length > 0) {
                        showSubTaskSelector = true;
                        reloadSubTaskSelector(accountId, selectedTaskId, -1);
                    } else {
                        showSubTaskSelector = false;
                    }
                }

            }
        }

        Row {
            width: parent.width
            visible: showSubTaskSelector
            height: units.gu(5)
            TreeSelector {
                id: subTaskSelector
                enabled: !readOnly
                labelText: subTaskLabelText
                width: parent.width
                height: units.gu(29)
            }
        }

        Row {
            width: parent.width
            visible: showAssigneeSelector
            height: units.gu(5)
            TreeSelector {
                id: assigneeSelector
                enabled: !readOnly
                labelText: assigneeLabelText
                width: parent.width
                height: units.gu(29)
            }
        }

        Timer {
            id: deferredApplyTimer
            interval: 100
            repeat: true
            running: false
            property var deferredPayload: null

            onTriggered: {
                if (!deferredPayload || accountSelector.model.count === 0) {
                    return;
                }
                deferredApplyTimer.stop();
                let p = deferredApplyTimer.deferredPayload;
                deferredApplyTimer.deferredPayload = null;
                applyDeferredSelection(
                            p.accountId, p.projectId, p.subProjectId,
                            p.taskId, p.subTaskId, p.assigneeId
                            );
            }
        }
    }
}
