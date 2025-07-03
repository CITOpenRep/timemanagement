import QtQuick 2.7
import QtQuick.Controls 2.2
import Lomiri.Components 1.3
import "../../models/accounts.js" as Accounts
import "../../models/project.js" as Project
import "../../models/task.js" as Task

Rectangle {
    id: workItemSelector
    width: parent ? parent.width : Screen.width
    height: contentColumn.implicitHeight
    color: "transparent"

    // External API remains unchanged
    property bool showAccountSelector: true
    property bool showProjectSelector: true
    property bool showTaskSelector: true
    property bool showAssigneeSelector: true

    property bool readOnly: false
    property string accountLabelText: "Account"
    property string projectLabelText: "Project"
    property string subProjectLabelText: "Subproject"
    property string taskLabelText: "Task"
    property string subTaskLabelText: "Subtask"
    property string assigneeLabelText: "Assignee"

    signal stateChanged(string newState, var data)

    // Selected IDs
    property int selectedAccountId: -1
    property int selectedProjectId: -1
    property int selectedSubProjectId: -1
    property int selectedTaskId: -1
    property int selectedSubTaskId: -1
    property int selectedAssigneeId: -1

    property string currentState: "Init"

    //The model for each selector
    property var selectorModelMap: {
        "Account": [],
        "Project": [],
        "Subproject": [],
        "Task": [],
        "Subtask": [],
        "Assignee": []
    }


    function transitionTo(newState, data) {
        console.log("[WorkItemSelector] Transition:", currentState, "→", newState, JSON.stringify(data));
        currentState = newState;
        stateChanged(newState, data);
    }

    function handleSelection(id, name, selectorType) {
        console.log("[WorkItemSelector] Selection made:", id, name, selectorType);
        let payload = { id: id, name: name };
        if (selectorType === "Account") {
            selectedAccountId = id;
            transitionTo("AccountSelected", payload);
        } else if (selectorType === "Project") {
            selectedProjectId = id;
            transitionTo("ProjectSelected", payload);
        } else if (selectorType === "Subproject") {
            selectedSubProjectId = id;
            transitionTo("SubprojectSelected", payload);
        } else if (selectorType === "Task") {
            selectedTaskId = id;
            transitionTo("TaskSelected", payload);
        } else if (selectorType === "Subtask") {
            selectedSubTaskId = id;
            transitionTo("SubtaskSelected", payload);
        } else if (selectorType === "Assignee") {
            selectedAssigneeId = id;
            transitionTo("AssigneeSelected", payload);
        }
    }

    //Functiosn to populate the models starts here

    //load accounts
    function loadAccounts(selectedId = -1) {
        console.log("Loading accounts");

        let default_id;
        if (selectedId === -1) {
            default_id = Accounts.getDefaultAccountId();
        } else {
            default_id = selectedId;
        }

        let default_name = "";
        const accounts = Accounts.getAccountsList();
        let accountList = [];

        for (let i = 0; i < accounts.length; i++) {
            if (accounts[i].id === default_id) {
                default_name = accounts[i].name;
            }
            accountList.push({
                                 id: accounts[i].id,
                                 name: accounts[i].name,
                                 database: accounts[i].database,
                                 link: accounts[i].link,
                                 username: accounts[i].username,
                                 is_default: accounts[i].is_default || 0
                             });
        }

        selectorModelMap["Account"] = accountList;
        account_component.modelData = accountList;
        account_component.applyDeferredSelection(default_id);

        // Immediately simulate state transition
        if(selectedId===-1)
        {
            transitionTo("AccountSelected", { id: default_id, name: default_name });
        }
    }

    //load projects
    function loadProjects(accountId, selectedId = -1) {
        console.log("Loading projects for account:", accountId);

        const rawProjects = Project.getProjectsForAccount(accountId);
        let projectList = [];

        // Always add default "No Project"
        projectList.push({
                             id: -1,
                             name: "No Project",
                             parent_id: null
                         });

        let default_id = -1;
        let default_name = "No Project";

        for (let i = 0; i < rawProjects.length; i++) {
            let id = (accountId === 0) ? rawProjects[i].id : rawProjects[i].odoo_record_id;
            let name = rawProjects[i].name;
            let parentId = rawProjects[i].parent_id;

            if (parentId === null || parentId === 0) {
                projectList.push({
                                     id: id,
                                     name: name,
                                     parent_id: parentId
                                 });

                if (selectedId === id) {
                    default_id = id;
                    default_name = name;
                }
            }
        }

        selectorModelMap["Project"] = projectList;
        project_component.modelData = projectList;

        // Enable only if there are real projects (besides "No Project")
        if (projectList.length > 1) {
            project_component.setEnabled(true);
        } else {
            project_component.setEnabled(false);
        }

        if (selectedId !== -1 &&  projectList.length > 1)
        {
           project_component.applyDeferredSelection(default_id);
        }

    }

    // Load subprojects for a given account and parent project
    function loadSubProjects(accountId, parentProjectId, selectedId = -1) {
        console.log("Loading subprojects for account:", accountId, "parentProjectId:", parentProjectId);

        const rawProjects = Project.getProjectsForAccount(accountId);
        let subProjectList = [];

        // Always add default "No Subproject"
        subProjectList.push({
            id: -1,
            name: "No Subproject",
            parent_id: null
        });

        let default_id = -1;
        let default_name = "No Subproject";

        for (let i = 0; i < rawProjects.length; i++) {
            let id = (accountId === 0) ? rawProjects[i].id : rawProjects[i].odoo_record_id;
            let name = rawProjects[i].name;
            let parentId = rawProjects[i].parent_id;

            // Only add if this project is a child of parentProjectId
            if (parentId === parentProjectId) {
                subProjectList.push({
                    id: id,
                    name: name,
                    parent_id: parentId
                });

                if (selectedId === id) {
                    default_id = id;
                    default_name = name;
                }
            }
        }

        selectorModelMap["Subproject"] = subProjectList;
        subproject_compoent.modelData = subProjectList;

        // Enable only if there are real subprojects besides "No Subproject"
        if (subProjectList.length > 1) {
            subproject_compoent.setEnabled(true);
        } else {
            subproject_compoent.setEnabled(false);
        }

        if (selectedId !== -1 && subProjectList.length > 1) {
            subproject_compoent.applyDeferredSelection(default_id);
        }
    }

    function loadTasks(accountId, projectIdOrSubprojectId, selectedId = -1) {
        console.log("Loading tasks for account:", accountId, "parentId (project/subproject):", projectIdOrSubprojectId);

        const rawTasks = Task.getTasksForAccount(accountId);
        let taskList = [];

        // Always add "No Task" entry
        taskList.push({
            id: -1,
            name: "No Task",
            parent_id: null
        });

        let default_id = -1;
        let default_name = "No Task";

        for (let i = 0; i < rawTasks.length; i++) {
            let id = rawTasks[i].odoo_record_id; // always use remote_id
            let name = rawTasks[i].name;
            let projectParentId = rawTasks[i].project_id;
            let subProjectParentId = rawTasks[i].sub_project_id;
            let parentId = rawTasks[i].parent_id;

            // ✅ Include only top-level tasks for the selected project/subproject
            if ((projectParentId === projectIdOrSubprojectId || subProjectParentId === projectIdOrSubprojectId) &&
                (parentId === null || parentId === 0)) {

                taskList.push({
                    id: id,
                    name: name,
                    parent_id: projectParentId || subProjectParentId // for reference
                });

                if (selectedId === id) {
                    default_id = id;
                    default_name = name;
                }
            }
        }

        selectorModelMap["Task"] = taskList;
        task_component.modelData = taskList;

        task_component.setEnabled(taskList.length > 1);

        if (selectedId !== -1 && taskList.length > 1) {
            task_component.applyDeferredSelection(default_id);
        }
    }



    function loadSubTasks(accountId, parentTaskId, selectedId = -1) {
        console.log("Loading subtasks for account:", accountId, "parentTaskId:", parentTaskId);

        const rawTasks = Task.getTasksForAccount(accountId);
        let subTaskList = [];

        // Always add "No Subtask" entry
        subTaskList.push({
            id: -1,
            name: "No Subtask",
            parent_id: null
        });

        let default_id = -1;
        let default_name = "No Subtask";

        for (let i = 0; i < rawTasks.length; i++) {
            let id = rawTasks[i].odoo_record_id;   // ✅ always use remote_id
            let name = rawTasks[i].name;
            let parentId = rawTasks[i].parent_id;  // Subtasks link via parent_id to their parent task

            // Only include subtasks whose parent_id matches the given parentTaskId
            if (parentId === parentTaskId) {
                subTaskList.push({
                    id: id,
                    name: name,
                    parent_id: parentId
                });

                if (selectedId === id) {
                    default_id = id;
                    default_name = name;
                }
            }
        }

        selectorModelMap["Subtask"] = subTaskList;
        subtask_component.modelData = subTaskList;

        subtask_component.setEnabled(subTaskList.length > 1);

        if (selectedId !== -1 && subTaskList.length > 1) {
             subtask_component.applyDeferredSelection(default_id);
        }
    }


    function loadAssignees(accountId, selectedId = -1) {
        console.log("Loading assignees for account:", accountId);

        const rawAssignees = Accounts.getUsers(accountId);
        let assigneeList = [];

        // Always add "Unassigned"
        assigneeList.push({
            id: -1,
            name: "Unassigned",
            parent_id: null
        });

        let default_id = -1;
        let default_name = "Unassigned";

        for (let i = 0; i < rawAssignees.length; i++) {
            let id = (accountId === 0) ? rawAssignees[i].id : rawAssignees[i].odoo_record_id;
            let name = rawAssignees[i].name;

            assigneeList.push({
                id: id,
                name: name,
                parent_id: null // no hierarchy for assignees
            });

            if (selectedId === id) {
                default_id = id;
                default_name = name;
            }
        }

        selectorModelMap["Assignee"] = assigneeList;
        assignee_component.modelData = assigneeList;

        assignee_component.setEnabled(assigneeList.length > 1);

        if (selectedId !== -1 && assigneeList.length > 1) {
            assignee_component.applyDeferredSelection(default_id);
        }
    }



  //End functions
    Component.onCompleted:
    {
        //We load accounts (if not deffered)
        loadAccounts()
    }



    Column {
        id: contentColumn
        width: parent.width
        spacing: units.gu(1)

        // Account Selector
        SelectionButton {
            selectorType: "Account"
            labelText: accountLabelText
            id:account_component
            onSelectionMade: handleSelection(id, name, selectorType)
            Component.onCompleted: {
                account_component.setData(selectorModelMap["Account"]);
                account_component.setEnabled(true);
            }
        }

        // Project Selector
        SelectionButton {
            selectorType: "Project"
            labelText: projectLabelText
            id:project_component
            onSelectionMade: handleSelection(id, name, selectorType)

            Connections {
                target: workItemSelector
                onStateChanged: {
                    if (newState === "AccountSelected") {
                        console.log("project_component Payload ID:", data.id);
                        console.log("project_component Payload Name:", data.name);
                        loadProjects(data.id,-1) //load projects of the selected account
                    }
                }
            }
        }

        // Subproject Selector
        SelectionButton {
            selectorType: "Subproject"
            labelText: subProjectLabelText
            id:subproject_compoent
            onSelectionMade: handleSelection(id, name, selectorType)

            Connections {
                target: workItemSelector
                onStateChanged: {
                    if (newState === "ProjectSelected") {
                        console.log("Payload ID:", data.id);
                        console.log("Payload Name:", data.name);
                        loadSubProjects(account_component.selectedId,data.id,-1)
                    }
                }
            }
        }

        // Task Selector
        SelectionButton {
            selectorType: "Task"
            labelText: taskLabelText
            id:task_component
            onSelectionMade: handleSelection(id, name, selectorType)

            Connections {
                target: workItemSelector
                onStateChanged: {
                    if (newState === "ProjectSelected" || newState === "SubprojectSelected") {
                        console.log("task_component Payload ID:", data.id);
                        console.log("task_component Payload Name:", data.name);
                        loadTasks(account_component.selectedId,data.id,-1)
                    }
                }
            }
        }

        // Subtask Selector
        SelectionButton {
            selectorType: "Subtask"
            labelText: subTaskLabelText
            id:subtask_component
            onSelectionMade: handleSelection(id, name, selectorType)

            Connections {
                target: workItemSelector
                onStateChanged: {
                    if (newState === "TaskSelected") {
                        console.log("subtask_component Payload ID:", data.id);
                        console.log("subtask_component Payload Name:", data.name);
                        loadSubTasks(account_component.selectedId,data.id,-1)
                    }
                }
            }
        }

        // Assignee Selector
        SelectionButton {
            selectorType: "Assignee"
            labelText: assigneeLabelText
            id:assignee_component
            onSelectionMade: handleSelection(id, name, selectorType)

            Connections {
                target: workItemSelector
                onStateChanged: {
                    if (newState === "AccountSelected") {
                        console.log("subtask_component Payload ID:", data.id);
                        console.log("subtask_component Payload Name:", data.name);
                        loadAssignees(data.id,-1)
                    }
                }
            }
        }
    }
}
