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
    property bool showTaskSelector: true
    property bool readOnly: false
    property string accountLabelText: "Account"
    property string projectLabelText: "Project"
    property string taskLabelText: "Task"
    property bool showAssigneeSelector: false
    property string assigneeLabelText: "Assignee"

    signal accountChanged(int accountId)

    /**
     * Applies a deferred selection state for the account, project, and task selectors.
     *
     * This function is typically used to restore a previous selection after loading,
     * or to initialize a known selection when opening a form. It triggers:
     *   1. Account selection via `selectAccountById`
     *   2. Project list reload and pre-selection via `reloadProjectSelector`
     *   3. Task list reload and pre-selection via `reloadTaskSelector`
     *
     * Each reload function will also set the display label and handle missing selections gracefully.
     *
     * @param {int} accountId   - The ID of the account to preselect (0 for local, others for Odoo).
     * @param {int} projectid   - The ID (local or Odoo) of the project to preselect in the project tree.
     * @param {int} taskId      - The ID (local or Odoo) of the task to preselect in the task tree.
     */
    function applyDeferredSelection(accountId, projectId, taskId, assigneeId) {
        if (accountSelector.model.count === 0) {
            // console.log("⏳ Deferring apply until account model is ready");
            deferredApplyTimer.deferredPayload = {
                accountId: accountId,
                projectId: projectId,
                taskId: taskId
            };
            deferredApplyTimer.start();
            return;
        }

        accountSelector.selectAccountById(accountId);
        reloadProjectSelector(accountId, projectId);
        reloadTaskSelector(accountId, taskId);
        reloadAssigneeSelector(accountId, assigneeId);
    }

    /**
     * Reloads the Assignee TreeSelector with a user list and includes a default "Unassigned" option.
     *
     * This function fetches user records from the local database (res_users_app) for a given account ID.
     * It formats them into a flat list compatible with TreeSelector, where each user is treated as a top-level node.
     * A default "Unassigned" entry is always shown at the top of the list.
     *
     * @param {int} accountId - The ID of the account (0 = local account, >0 = Odoo instance).
     * @param {int} [selectedAssigneeId] - Optional assignee ID (local or Odoo) to preselect.
     */
    function reloadAssigneeSelector(accountId, selectedAssigneeId) {
        //  console.log("Loading Assignees for account " + accountId);

        let rawAssignees = Accounts.getUsers(accountId);  // expects: [{id, name, odoo_record_id}]
        let flatModel = [];

        // ✅ Default "Unassigned" entry
        flatModel.push({
            id: -1,
            name: "Unassigned",
            parent_id: null
        });

        let selectedText = "Unassigned";
        let selectedFound = (selectedAssigneeId === -1);

        for (let i = 0; i < rawAssignees.length; i++) {
            let id = accountId === 0 ? rawAssignees[i].id : rawAssignees[i].odoo_record_id;
            let name = rawAssignees[i].name;

            flatModel.push({
                id: id,
                name: name,
                parent_id: null  // or 0, as needed by TreeSelector (no hierarchy)
            });

            if (selectedAssigneeId !== undefined && selectedAssigneeId !== null && selectedAssigneeId === id) {
                selectedText = name;
                selectedFound = true;
            }
        }

        // Push to selector
        assigneeSelector.dataList = flatModel;
        assigneeSelector.reload();

        // Update selection
        assigneeSelector.selectedId = selectedFound ? selectedAssigneeId : -1;
        assigneeSelector.currentText = selectedFound ? selectedText : "Select Assignee";
    }

    /**
     * Reloads the Project TreeSelector with project data and includes a default "No Project" option.
     *
     * This version prepends a special default entry (id: -1) labeled "No Project",
     * allowing the user to explicitly deselect a project.
     *
     * @param {int} accountId - ID of the account (0 = local).
     * @param {int} [selectedProjectId] - Optional project ID (local or Odoo) to preselect.
     */
    function reloadProjectSelector(accountId, selectedProjectId) {
        // console.log("->-> Loading Projects for account " + accountId);

        let rawProjects = Project.getProjectsForAccount(accountId);
        let flatModel = [];

        // Add default "No Project" entry
        flatModel.push({
            id: -1,
            name: "No Project",
            parent_id: null
        });

        let selectedText = "No Project";
        let selectedFound = (selectedProjectId === -1);

        for (let i = 0; i < rawProjects.length; i++) {
            let id = accountId === 0 ? rawProjects[i].id : rawProjects[i].odoo_record_id;
            let name = rawProjects[i].name;
            let parentId = rawProjects[i].parent_id;

            flatModel.push({
                id: id,
                name: name,
                parent_id: parentId
            });

            if (selectedProjectId !== undefined && selectedProjectId !== null && selectedProjectId === id) {
                selectedText = name;
                selectedFound = true;
            }
        }

        // Push to the model and reload
        projectSelector.dataList = flatModel;
        projectSelector.reload();

        // Update UI label
        projectSelector.selectedId = selectedFound ? selectedProjectId : -1;
        projectSelector.currentText = selectedFound ? selectedText : "Select Project";
    }

    /**
     * Reloads the Task TreeSelector with a task list and includes a default "No Task" option.
     *
     * This function loads tasks for a given account, formats them into a flat tree-compatible model,
     * prepends a "No Task" option with `id: -1`, and optionally preselects a given task.
     *
     * @param {int} accountId - The ID of the account (0 = local).
     * @param {int} [selectedTaskId] - Optional task ID (local or Odoo) to preselect.
     */
    function reloadTaskSelector(accountId, selectedTaskId) {
        // console.log("Loading Tasks for account " + accountId);

        let rawTasks = Task.getTasksForAccount(accountId);
        let flatModel = [];

        // ✅ Add default "No Task" entry
        flatModel.push({
            id: -1,
            name: "No Task",
            parent_id: null
        });

        let selectedText = "No Task";
        let selectedFound = (selectedTaskId === -1);

        for (let i = 0; i < rawTasks.length; i++) {
            let id = accountId === 0 ? rawTasks[i].id : rawTasks[i].odoo_record_id;
            let name = rawTasks[i].name;
            let parentId = rawTasks[i].parent_id;

            flatModel.push({
                id: id,
                name: name,
                parent_id: parentId
            });

            if (selectedTaskId !== undefined && selectedTaskId !== null && selectedTaskId === id) {
                selectedText = name;
                selectedFound = true;
            }
        }

        taskSelector.dataList = flatModel;
        taskSelector.reload();

        taskSelector.selectedId = selectedFound ? selectedTaskId : -1;
        taskSelector.currentText = selectedFound ? selectedText : "Select Task";
    }

    function getAllSelectedDbRecordIds() {
        return {
            accountDbId: accountSelector.selectedInstanceId,
            projectDbId: projectSelector.selectedId,
            taskDbId: taskSelector.selectedId,
            assigneeDbId: assigneeSelector.selectedId
        };
    }

    Column {
        id: contentColumn
        width: parent.width
        spacing: units.gu(1)

        // Account Row
        Row {
            width: parent.width
            //spacing: units.gu(1)
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
                // color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "grey" : "transparent"
                anchors.verticalCenter: parent.verticalCenter
                AccountSelector {
                    id: accountSelector
                    anchors.centerIn: parent
                    anchors.verticalCenter: parent.verticalCenter
                    enabled: !readOnly
                    editable: false
                    onAccountSelected: {
                        // console.log("[WorkItemSelector] Account selected:", accountSelector.selectedInstanceId);
                        reloadProjectSelector(accountSelector.selectedInstanceId);
                        reloadTaskSelector(accountSelector.selectedInstanceId);
                        accountChanged(accountSelector.selectedInstanceId);
                        reloadAssigneeSelector(accountSelector.selectedInstanceId);
                    }
                }
            }
        }

        // 🔹 Parent Project Row
        Row {
            width: parent.width
            // spacing: units.gu(1)
            visible: showProjectSelector
            height: units.gu(5)
            TreeSelector {
                id: projectSelector
                enabled: !readOnly
                labelText: "Parent Project"
                width: parent.width
                height: units.gu(29)
            }
        }

        // 🔹 Parent Task Row
        Row {
            width: parent.width
            // spacing: units.gu(1)
            visible: showTaskSelector
            height: units.gu(5)
            TreeSelector {
                id: taskSelector
                enabled: !readOnly
                labelText: "Parent Task"
                width: parent.width
                height: units.gu(29)
            }
        }

        // 🔹 Assignee Row
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
                    //console.log("Timer: Waiting for accountSelector model to load...");
                    return;
                }

                // console.log("Timer: Retrying account selection and applying deferred project/task IDs");
                deferredApplyTimer.stop();

                let p = deferredApplyTimer.deferredPayload;
                deferredApplyTimer.deferredPayload = null;

                accountSelector.selectAccountById(p.accountId);
                reloadProjectSelector(p.accountId, p.projectId);
                reloadTaskSelector(p.accountId, p.taskId);
                reloadAssigneeSelector(p.accountId, p.assigneeId);
            }
        }
    }
}
