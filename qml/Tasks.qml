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

    // Visibility control properties (unchanged)
    property bool showAccountSelector: true
    property bool showProjectSelector: false
    property bool showSubProjectSelector: false
    property bool showTaskSelector: false
    property bool showSubTaskSelector: false
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
                accountId, projectId, subProjectId, taskId, subTaskId, assigneeId
            };
            deferredApplyTimer.start();
            return;
        }

        console.log("Loading Deferred Selection:", JSON.stringify({
            accountId, projectId, subProjectId, taskId, subTaskId, assigneeId
        }));

        reloadAllSelectors(accountId, projectId, subProjectId, taskId, subTaskId, assigneeId);
    }

    function reloadSelector(options) {
        let {
            selector,
            records,
            selectedId,
            defaultLabel,
            filterFn = () => true,
            visiblePropertyName
        } = options;

        let filteredRecords = records.filter(filterFn);
        let flatModel = [{ id: -1, name: defaultLabel, parent_id: null }];

        let selectedText = defaultLabel;
        let selectedFound = (selectedId === -1);

        for (let i = 0; i < filteredRecords.length; i++) {
            let record = filteredRecords[i];
            let id = (record.odoo_record_id !== undefined) ? record.odoo_record_id : record.id;
            let name = record.name;
            flatModel.push({ id: id, name: name, parent_id: null });

            if (selectedId === id) {
                selectedText = name;
                selectedFound = true;
            }
        }

        selector.dataList = flatModel;
        selector.reload();
        selector.selectedId = selectedFound ? selectedId : -1;
        selector.currentText = selectedFound ? selectedText : "Select " + defaultLabel;

        if (visiblePropertyName !== undefined) {
            // Always show the selector if it is part of the workflow
            workItemSelector[visiblePropertyName] = true;
        }
    }

    function reloadAllSelectors(accountId, projectId, subProjectId, taskId, subTaskId, assigneeId) {
        let projects = Project.getProjectsForAccount(accountId);
        let tasks = Task.getTasksForAccount(accountId);

        // 1️⃣ Project Selector (top-level projects only)
        reloadSelector({
            selector: projectSelector,
            records: projects,
            selectedId: projectId,
            defaultLabel: "Project",
            filterFn: proj => !proj.parent_id || proj.parent_id === 0,
            visiblePropertyName: "showProjectSelector"
        });

        // 2️⃣ SubProject Selector
        let subprojects = projects.filter(proj => proj.parent_id === projectId);
        if (subprojects.length > 0) {
            reloadSelector({
                selector: subProjectSelector,
                records: projects,
                selectedId: subProjectId,
                defaultLabel: "Subproject",
                filterFn: proj => proj.parent_id === projectId,
                visiblePropertyName: "showSubProjectSelector"
            });
            showTaskSelector = false; // Wait for subproject selection
        } else {
            showSubProjectSelector = false;

            // 3️⃣ Task Selector (since no subprojects)
            reloadSelector({
                selector: taskSelector,
                records: tasks,
                selectedId: taskId,
                defaultLabel: "Task",
                filterFn: task => task.project_id === projectId && (!task.parent_id || task.parent_id === 0),
                visiblePropertyName: "showTaskSelector"
            });
        }

        // 4️⃣ SubTask Selector
        let subtasks = tasks.filter(task => task.parent_id === taskId);
        if (subtasks.length > 0) {
            reloadSelector({
                selector: subTaskSelector,
                records: tasks,
                selectedId: subTaskId,
                defaultLabel: "Subtask",
                filterFn: task => task.parent_id === taskId,
                visiblePropertyName: "showSubTaskSelector"
            });
        } else {
            showSubTaskSelector = false;
        }

        // 5️⃣ Assignee Selector
        let users = Accounts.getUsers(accountId);
        reloadSelector({
            selector: assigneeSelector,
            records: users,
            selectedId: assigneeId,
            defaultLabel: "Unassigned",
            filterFn: () => true,
            visiblePropertyName: "showAssigneeSelector"
        });
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
                        applyDeferredSelection(accountSelector.selectedInstanceId, -1, -1, -1, -1, -1);
                        accountChanged(accountSelector.selectedInstanceId);
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
                    let children = Project.getProjectsForAccount(accountId).filter(proj => proj.parent_id === selectedProjectId);

                    if (children.length > 0) {
                        showSubProjectSelector = true;
                        reloadSelector({
                            selector: subProjectSelector,
                            records: Project.getProjectsForAccount(accountId),
                            selectedId: -1,
                            defaultLabel: "Subproject",
                            filterFn: proj => proj.parent_id === selectedProjectId,
                            visiblePropertyName: "showSubProjectSelector"
                        });
                        showTaskSelector = false;
                    } else {
                        showSubProjectSelector = false;
                        showTaskSelector = true;
                        reloadSelector({
                            selector: taskSelector,
                            records: Task.getTasksForAccount(accountId),
                            selectedId: -1,
                            defaultLabel: "Task",
                            filterFn: task => task.project_id === selectedProjectId && (!task.parent_id || task.parent_id === 0),
                            visiblePropertyName: "showTaskSelector"
                        });
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

                onItemSelected: {
                    let accountId = accountSelector.selectedInstanceId;
                    let selectedSubProjectId = subProjectSelector.selectedId;
                    showTaskSelector = true;
                    reloadSelector({
                        selector: taskSelector,
                        records: Task.getTasksForAccount(accountId),
                        selectedId: -1,
                        defaultLabel: "Task",
                        filterFn: task => task.project_id === selectedSubProjectId && (!task.parent_id || task.parent_id === 0),
                        visiblePropertyName: "showTaskSelector"
                    });
                }
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
                    let children = Task.getTasksForAccount(accountId).filter(task => task.parent_id === selectedTaskId);

                    if (children.length > 0) {
                        showSubTaskSelector = true;
                        reloadSelector({
                            selector: subTaskSelector,
                            records: Task.getTasksForAccount(accountId),
                            selectedId: -1,
                            defaultLabel: "Subtask",
                            filterFn: task => task.parent_id === selectedTaskId,
                            visiblePropertyName: "showSubTaskSelector"
                        });
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
                applyDeferredSelection(p.accountId, p.projectId, p.subProjectId, p.taskId, p.subTaskId, p.assigneeId);
            }
        }
    }
}
