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
    property bool showSubProjectSelector: true
    property bool showTaskSelector: true
    property bool showSubTaskSelector: true
    property bool showAssigneeSelector: true

    property bool readOnly: false

    // Watch for readOnly property changes and update all selectors
    onReadOnlyChanged: {
        console.log("[WorkItemSelector] readOnly changed to:", readOnly);
        updateAllSelectorStates();
    }

    function updateAllSelectorStates() {
        console.log("[WorkItemSelector] Updating all selector states, readOnly:", readOnly);
        if (account_component) {
            account_component.setEnabled(!readOnly && account_component.modelData.length > 1);
        }
        if (project_component) {
            project_component.setEnabled(!readOnly && project_component.modelData.length > 1);
        }
        if (subproject_compoent) {
            subproject_compoent.setEnabled(!readOnly && subproject_compoent.modelData.length > 1);
        }
        if (task_component) {
            task_component.setEnabled(!readOnly && task_component.modelData.length > 1);
        }
        if (subtask_component) {
            subtask_component.setEnabled(!readOnly && subtask_component.modelData.length > 1);
        }
        if (assignee_component) {
            assignee_component.setEnabled(!readOnly && assignee_component.modelData.length > 1);
        }
    }
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
        let payload = {
            id: id,
            name: name
        };
        if (selectorType === "Account") {
            selectedAccountId = id;
            transitionTo("AccountSelected", payload);
        } else if (selectorType === "Project") {
            selectedProjectId = id;
            transitionTo("ProjectSelected", payload);
        } else if (selectorType === "Subproject") {
            if (id !== -1) //user selected an active subproject
            {
                selectedSubProjectId = id;
                transitionTo("SubprojectSelected", payload);
            } else //we assume that user want the project
            {
                selectedSubProjectId = project_component.selectedId;
                transitionTo("ProjectSelected", payload);
            }
        } else if (selectorType === "Task") {
            selectedTaskId = id;
            transitionTo("TaskSelected", payload);
        } else if (selectorType === "Subtask") {
            if (id !== -1) //user selected an active subproject
            {
                selectedSubProjectId = id;
                transitionTo("SubtaskSelected", payload);
            } else //we assume that user want the project
            {
                selectedSubProjectId = project_component.selectedId;
                transitionTo("TaskSelected", payload);
            }
        } else if (selectorType === "Assignee") {
            selectedAssigneeId = id;
            transitionTo("AssigneeSelected", payload);
        }
    }

    //Functiosn to populate the models starts here
    function finalizeLoading(selectorType, component, list, default_id, default_name, selectedId, transitionState) {
        selectorModelMap[selectorType] = list;
        component.modelData = list;

        // Only enable if not in read-only mode AND has data
        if (!readOnly && list.length > 1) {
            component.setEnabled(true);
        } else {
            component.setEnabled(false);
        }

        if (selectedId !== -1 && list.length > 1) {
            component.applyDeferredSelection(default_id);
        }

    /*if (selectedId !== -1 && list.length > 1 && transitionState) {
            transitionTo(transitionState, {
                id: default_id,
                name: default_name
            });
        }*/
    }

    function deferredLoadExistingRecordSet(accountId, projectId, subProjectId, taskId, subTaskId, assigneeId) {
        console.log("[Deferred Load] Loading existing record set:");
        console.log("   Account ID:     ", accountId);
        console.log("   Project ID:     ", projectId);
        console.log("   Subproject ID:  ", subProjectId);
        console.log("   Task ID:        ", taskId);
        console.log("   Subtask ID:     ", subTaskId);
        console.log("   Assignee ID:    ", assigneeId);

        if (accountId !== -1) {
            loadAccounts(accountId);
        }

        // Load Projects under account with selected projectId
        if (accountId !== -1) {
            loadProjects(accountId, projectId);
        }

        // Load Subprojects under project with selected subProjectId
        if (accountId !== -1 && projectId !== -1) {
            loadSubProjects(accountId, projectId, subProjectId);
        }

        // Load Tasks under project/subproject with selected taskId
        if (accountId !== -1 && (projectId !== -1 || subProjectId !== -1)) {
            loadTasks(accountId, projectId, taskId);
        }

        // Load Subtasks under task with selected subTaskId
        if (accountId !== -1 && taskId !== -1) {
            loadSubTasks(accountId, taskId, subTaskId);
        }

        // Load Assignees with selected assigneeId
        if (accountId !== -1) {
            loadAssignees(accountId, assigneeId);
        }

        // Force update selector states after loading data to respect read-only mode
        Qt.callLater(updateAllSelectorStates);
    }

    function getIds() {
        function normalize(id) {
            return id === -1 ? null : id;
        }

        return {
            account_id: normalize(account_component.selectedId),
            project_id: normalize(project_component.selectedId),
            subproject_id: normalize(subproject_compoent.selectedId),
            task_id: normalize(task_component.selectedId),
            subtask_id: normalize(subtask_component.selectedId),
            assignee_id: normalize(assignee_component.selectedId)
        };
    }

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

        // Immediately simulate state transition (Special case for an entry point for the user)
        if (selectedId === -1) {
            transitionTo("AccountSelected", {
                id: default_id,
                name: default_name
            });
        }
    }

    //load projects
    function loadProjects(accountId, selectedId = -1) {
        console.log("Loading projects for account:", accountId);

        const rawProjects = Project.getProjectsForAccount(accountId);
        let projectList = [];

        let default_id = -1;
        let default_name = "Select";

        // Always add default "Select"
        projectList.push({
            id: default_id,
            name: default_name,
            parent_id: null
        });

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

        finalizeLoading("Project", project_component, projectList, default_id, default_name, selectedId, "ProjectSelected");
    }

    // Load subprojects for a given account and parent project
    function loadSubProjects(accountId, parentProjectId, selectedId = -1) {
        console.log("Loading subprojects for account:", accountId, "parentProjectId:", parentProjectId);

        const rawProjects = Project.getProjectsForAccount(accountId);
        let subProjectList = [];

        // Always add default "No Subproject"
        subProjectList.push({
            id: -1,
            name: "Select",
            parent_id: null
        });

        let default_id = -1;
        let default_name = "Select";

        for (let i = 0; i < rawProjects.length; i++) {
            let id = (accountId === 0) ? rawProjects[i].id : rawProjects[i].odoo_record_id;
            let name = rawProjects[i].name;
            let parentId = rawProjects[i].parent_id;

            // Add only if this project is a child of the parentProjectId
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

        finalizeLoading("Subproject", subproject_compoent, subProjectList, default_id, default_name, selectedId, "SubprojectSelected");
    }

    function loadTasks(accountId, projectIdOrSubprojectId, selectedId = -1) {
        console.log("Loading tasks for account:", accountId, "parentId (project/subproject):", projectIdOrSubprojectId, "selectedId:", selectedId);

        const rawTasks = Task.getTasksForAccount(accountId);
        let taskList = [];

        // Always add "No Task" entry
        taskList.push({
            id: -1,
            name: "Select",
            parent_id: null
        });

        let default_id = -1;
        let default_name = "Select";
        let filteredCount = 0;

        for (let i = 0; i < rawTasks.length; i++) {
            let id = rawTasks[i].odoo_record_id;
            let name = rawTasks[i].name;
            let projectParentId = rawTasks[i].project_id;
            let subProjectParentId = rawTasks[i].sub_project_id;
            let parentId = rawTasks[i].parent_id;

            // Apply filtering regardless of selectedId to ensure only relevant tasks are shown
            if ((projectParentId === projectIdOrSubprojectId || subProjectParentId === projectIdOrSubprojectId) && (parentId === null || parentId === 0)) {
                taskList.push({
                    id: id,
                    name: name,
                    parent_id: projectParentId || subProjectParentId
                });
                filteredCount++;

                if (selectedId === id) {
                    default_id = id;
                    default_name = name;
                }
            } else if (selectedId !== -1 && selectedId === id) {
                // Special case: if this task matches selectedId but doesn't match current filter,
                // still add it so it can be displayed, but log a warning
                console.log("Warning: Selected task", id, "doesn't belong to current project/subproject", projectIdOrSubprojectId);
                taskList.push({
                    id: id,
                    name: name + " (from different project)",
                    parent_id: projectParentId || subProjectParentId
                });
                default_id = id;
                default_name = name;//+ " (from different project)";
            }
        }

        console.log("Task filtering complete: found", filteredCount, "tasks for project/subproject", projectIdOrSubprojectId);

        finalizeLoading("Task", task_component, taskList, default_id, default_name, selectedId, "TaskSelected");
    }

    function loadSubTasks(accountId, parentTaskId, selectedId = -1) {
        console.log("Loading subtasks for account:", accountId, "parentTaskId:", parentTaskId);

        const rawTasks = Task.getTasksForAccount(accountId);
        let subTaskList = [];

        // Always add "No Subtask" entry
        subTaskList.push({
            id: -1,
            name: "Select",
            parent_id: null
        });

        let default_id = -1;
        let default_name = "Select";

        for (let i = 0; i < rawTasks.length; i++) {
            let id = rawTasks[i].odoo_record_id;   // always use remote_id
            let name = rawTasks[i].name;
            let parentId = rawTasks[i].parent_id;  // Subtasks link via parent_id to their parent task

            if (selectedId !== -1) {
                // Skip filtering if we are doing deferred loading
                subTaskList.push({
                    id: id,
                    name: name,
                    parent_id: parentId
                });

                if (selectedId === id) {
                    default_id = id;
                    default_name = name;
                }
            } else {
                // Normal workflow filtering
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
        }

        finalizeLoading("Subtask", subtask_component, subTaskList, default_id, default_name, selectedId, "SubtaskSelected");
    }

    function loadAssignees(accountId, selectedId = -1) {
        console.log("Loading assignees for account:", accountId);

        const rawAssignees = Accounts.getUsers(accountId);
        let assigneeList = [];

        // Always add "Unassigned"
        assigneeList.push({
            id: -1,
            name: "Select Assignee",
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

        finalizeLoading("Assignee", assignee_component, assigneeList, default_id, default_name, selectedId, "AssigneeSelected");
        //disbale the subprojects, tasks,subtasks buttons
        if (selectedId === -1) {
            subproject_compoent.setEnabled(false);
            subtask_component.setEnabled(false);
            task_component.setEnabled(false);
        }
    }

    //End functions (Quiet a long one :D )

    Column {
        id: contentColumn
        width: parent.width
        spacing: units.gu(1)

        // Account Selector
        SelectionButton {
            id: account_component
            selectorType: accountLabelText
            labelText: accountLabelText
            enabledState: !readOnly
            readOnly: readOnly
            onSelectionMade: handleSelection(id, name, selectorType)
            Component.onCompleted: {
                account_component.setData(selectorModelMap["Account"]);
                if (!readOnly)
                    account_component.setEnabled(true);
            }
        }

        // Project Selector
        SelectionButton {
            id: project_component
            selectorType: projectLabelText
            labelText: projectLabelText
            enabledState: !readOnly
            readOnly: readOnly
            visible: showProjectSelector
            onSelectionMade: handleSelection(id, name, selectorType)

            Connections {
                target: workItemSelector
                onStateChanged: {
                    if (newState === "AccountSelected") {
                        project_component.update_label("Select");
                        console.log("project_component Payload ID:", data.id);
                        console.log("project_component Payload Name:", data.name);
                        loadProjects(data.id, -1); //load projects of the selected account
                    }
                }
            }
            Component.onCompleted: {
                if (!readOnly)
                    project_component.setEnabled(true);
            }
        }

        // Subproject Selector
        SelectionButton {
            id: subproject_compoent
            selectorType: subProjectLabelText
            labelText: subProjectLabelText
            enabledState: !readOnly
            readOnly: readOnly
            onSelectionMade: handleSelection(id, name, selectorType)
            visible: showSubProjectSelector
            Connections {
                target: workItemSelector
                onStateChanged: {
                    if (newState === "ProjectSelected") {
                        subproject_compoent.update_label("Select");
                        console.log("Payload ID:", data.id);
                        console.log("Payload Name:", data.name);
                        loadSubProjects(account_component.selectedId, data.id, -1);
                    }
                }
            }
            Component.onCompleted: {
                if (!readOnly)
                    subproject_compoent.setEnabled(true);
            }
        }

        // Task Selector
        SelectionButton {
            id: task_component
            selectorType: taskLabelText
            labelText: taskLabelText
            enabledState: !readOnly
            readOnly: readOnly
            visible: showTaskSelector
            onSelectionMade: handleSelection(id, name, selectorType)

            Connections {
                target: workItemSelector
                onStateChanged: {
                    if (newState === "ProjectSelected" || newState === "SubprojectSelected") {
                        task_component.update_label("Select");
                        console.log("task_component Payload ID:", data.id);
                        console.log("task_component Payload Name:", data.name);
                        loadTasks(account_component.selectedId, data.id, -1);
                    }
                }
            }
            Component.onCompleted: {
                if (!readOnly)
                    task_component.setEnabled(true);
            }
        }

        // Subtask Selector
        SelectionButton {
            id: subtask_component
            selectorType: subTaskLabelText
            labelText: subTaskLabelText
            enabledState: !readOnly
            readOnly: readOnly
            visible: showSubTaskSelector
            onSelectionMade: handleSelection(id, name, selectorType)

            Connections {
                target: workItemSelector
                onStateChanged: {
                    if (newState === "TaskSelected") {
                        subtask_component.update_label("Select");
                        console.log("subtask_component Payload ID:", data.id);
                        console.log("subtask_component Payload Name:", data.name);
                        loadSubTasks(account_component.selectedId, data.id, -1);
                    }
                }
            }
            Component.onCompleted: {
                if (!readOnly)
                    subtask_component.setEnabled(true);
            }
        }

        // Assignee Selector
        SelectionButton {
            id: assignee_component
            visible: showAssigneeSelector
            selectorType: "Assignee"
            labelText: assigneeLabelText
            enabledState: !readOnly
            readOnly: readOnly
            onSelectionMade: handleSelection(id, name, selectorType)

            Connections {
                target: workItemSelector
                onStateChanged: {
                    if (newState === "AccountSelected") {
                        console.log("subtask_component Payload ID:", data.id);
                        console.log("subtask_component Payload Name:", data.name);
                        loadAssignees(data.id, -1);
                    }
                }
            }
            Component.onCompleted: {
                if (!readOnly)
                    assignee_component.setEnabled(true);
            }
        }
    }
}

/*
---------------------------------------------------------------
WorkItemSelector.qml – Detailed Workflow and Architecture Notes
---------------------------------------------------------------

Purpose:
-------------
This QML component provides a *stateful cascading selector UI* for:
- Account
- Project
- Subproject
- Task
- Subtask
- Assignee

It enables *dynamic loading* of related entities from Odoo (via local DB sync)
using **state transitions** without requiring external state management.

Core Concepts:
--------------------
*  Uses a **state machine**:
    - `currentState` tracks the selector state.
    - `stateChanged(newState, data)` is emitted for each transition.
    - Each `SelectionButton` listens to relevant states and triggers data loading.

*  Uses **selectorModelMap**:
    Holds the current data for each selector type, making updates traceable.

*  Uses **deferredLoadExistingRecordSet**:
    Allows loading an existing timesheet (or related record) into the selector stack
    without state propagation.

*  Uses **finalizeLoading(...)**:
    Centralized helper to:
      • Assign models to selectors
      • Enable/disable based on data length
      • Apply deferred selection if needed.

*  Uses **SelectionButton.qml**:
    Encapsulates label+button with popover list selection, reducing repetitive UI code.

Workflow:
--------------
- User starts with Account selection:
    → Loads Accounts using `loadAccounts()`.
    → On selection, triggers `"AccountSelected"`, loading Projects.

- Project selection:
    → Loads Projects for selected Account using `loadProjects()`.
    → On selection, triggers `"ProjectSelected"`, loading Subprojects and Tasks.

- Subproject selection:
    → Loads Subprojects for Project using `loadSubProjects()`.
    → On selection, triggers `"SubprojectSelected"`, loading Tasks for Subproject.

- Task selection:
    → Loads Tasks for selected Project or Subproject using `loadTasks()`.
    → On selection, triggers `"TaskSelected"`, loading Subtasks.

- Subtask selection:
    → Loads Subtasks for Task using `loadSubTasks()`.

- Assignee selection:
    → Loads Assignees for Account using `loadAssignees()`.

Advantages:
----------------
*  Highly modular and testable.
*  Minimal coupling between selectors.
*  State transitions remain visible and traceable.
*  Future extensibility (e.g., auto-sync, role-based filtering) is straightforward.
*  Clear separation of UI and data logic.

---------------------------------
This documentation ensures any developer maintaining
or extending this component will understand its design,
responsibilities, and how data flows between the selectors.

Last updated: [2025-07-01]
---------------------------------
*/

