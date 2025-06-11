/*
 * MIT License
 * Copyright (c) 2025 CIT-Services
 */

import QtQuick 2.7
import QtQuick.Controls 2.2
import "../../models/task.js" as Task
import "../../models/project.js" as Project

ComboBox {
    id: taskCombo
    editable: false
    flat: true
    width: parent.width
    height: parent.height
    anchors.centerIn: parent.centerIn
    property var fullTaskList: []

    background: Rectangle {
        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "grey" : "transparent"
        radius: units.gu(0.6)
    }

    textRole: "name"

    property alias exposedModel: internalTaskModel
    property int accountId: -1
    property int selectedTaskId: -1
    property int projectId: -1
    property string mode: "task"      // or "subtask"
    property bool autoSelectFirst: true

    signal taskSelected(int id, string name)

    ListModel {
        id: internalTaskModel
    }

    model: internalTaskModel
    property bool isDeferredSelection: false

    

    Component.onCompleted: {
        if (accountId === -1)
            editText = (mode === "subtask") ? "No Subtask" : "No Task";
    }

    function getSelectedDbRecordId() {
        if (selectedTaskId < 0 || accountId === -1)
            return null;

        for (let i = 0; i < internalTaskModel.count; i++) {
            let item = internalTaskModel.get(i);
            if (item.recordId === selectedTaskId) {
                return (accountId === 0) ? item.id : (item.odoo_record_id || null);
            }
        }

        return null;
    }

    function clear() {
        internalTaskModel.clear();
        currentIndex = -1;
        selectedTaskId = -1;
        editText = "";
    }

    function load(accountIdVal, taskIdVal, projectIdVal) {
        isDeferredSelection = false;
        _loadFromProject(accountIdVal, taskIdVal, projectIdVal, false);
    }

    function loadDeferred(accountIdVal, taskIdVal) {
        isDeferredSelection = true;
        _loadFromTask(accountIdVal, taskIdVal, true);
    }

    function _loadFromProject(accountIdVal, taskIdVal, projectIdVal, suppressSignal) {
        console.log("[load] project-based → accountId:", accountIdVal, "projectId:", projectIdVal);
        clear();
        accountId = accountIdVal;
        projectId = projectIdVal;

        const noneLabel = (mode === "subtask") ? "No Subtask" : "No Task";
        internalTaskModel.append({
            name: noneLabel,
            id: -1,
            recordId: -1
        });
        currentIndex = 0;
        selectedTaskId = -1;
        editText = noneLabel;

        if (accountId === -1 || projectId === -1)
            return;

        fullTaskList = Task.getTasksForAccount(accountId);
        const resolvedProjectId = _resolveRemoteProjectId(projectId);

        let filtered = fullTaskList.filter(t => {
            if (!t.name)
                return false;
            if (t.project_id !== resolvedProjectId)
                return false;

            if (mode === "task")
                return !t.parent_id || parseInt(t.parent_id) === 0;
            else if (mode === "subtask")
                return t.parent_id && parseInt(t.parent_id) !== 0;

            return true;
        });

        _populateAndSelect(filtered, taskIdVal, suppressSignal);
    }

    function _loadFromTask(accountIdVal, taskIdVal, suppressSignal) {
        console.log("[loadDeferred] task-based → accountId:", accountIdVal, "taskId:", taskIdVal);
        clear();
        accountId = accountIdVal;

        const noneLabel = (mode === "subtask") ? "No Subtask" : "No Task";
        internalTaskModel.append({
            name: noneLabel,
            id: -1,
            recordId: -1
        });
        currentIndex = 0;
        selectedTaskId = -1;
        editText = noneLabel;

        if (accountId === -1 || taskIdVal === -1)
            return;

        fullTaskList = Task.getTasksForAccount(accountId);

        let matchedTask = fullTaskList.find(t => {
            return (accountId === 0) ? t.id === taskIdVal : t.odoo_record_id === taskIdVal;
        });

        if (!matchedTask)
            return;

        const resolvedProjectId = matchedTask.project_id;

        let filtered = fullTaskList.filter(t => {
            if (!t.name)
                return false;
            if (t.project_id !== resolvedProjectId)
                return false;

            if (mode === "task")
                return !t.parent_id || parseInt(t.parent_id) === 0;
            else if (mode === "subtask")
                return t.parent_id && parseInt(t.parent_id) !== 0;

            return true;
        });

        _populateAndSelect(filtered, taskIdVal, suppressSignal);
    }

    function _populateAndSelect(taskList, taskIdVal, suppressSignal) {
        for (let t of taskList) {
            internalTaskModel.append({
                name: t.name || "(Unnamed Task)",
                id: t.id,
                recordId: t.id,
                odoo_record_id: t.odoo_record_id,
                parent_id: t.parent_id,
                project_id: t.project_id
            });
        }

        let found = false;
        for (let i = 0; i < internalTaskModel.count; i++) {
            const item = internalTaskModel.get(i);
            const match = (accountId === 0) ? item.recordId === taskIdVal : item.odoo_record_id === taskIdVal;
            if (match) {
                currentIndex = i;
                selectedTaskId = item.recordId;
                editText = item.name;
                found = true;
                if (!suppressSignal)
                    taskSelected(selectedTaskId, editText);
                break;
            }
        }

        if (!found && autoSelectFirst && internalTaskModel.count > 1) {
            const item = internalTaskModel.get(1);
            currentIndex = 1;
            selectedTaskId = item.recordId;
            editText = item.name;
            if (!suppressSignal)
                taskSelected(selectedTaskId, item.name);
        }
    }

    function _resolveRemoteProjectId(localId) {
        if (accountId === 0)
            return localId;
        const projects = Project.getProjectsForAccount(accountId) || [];
        for (let p of projects)
            if (p.id === localId && p.odoo_record_id)
                return p.odoo_record_id;
        return localId;
    }

    onActivated: {
        isDeferredSelection = false;
        if (currentIndex >= 0) {
            const selected = model.get(currentIndex);
            selectedTaskId = selected.recordId;
            taskSelected(selected.recordId, selected.name);
            isDeferredSelection = false;
        }
    }

    onAccepted: {
        isDeferredSelection = false;
        const idx = find(editText);
        if (idx !== -1) {
            const selected = model.get(idx);
            selectedTaskId = selected.recordId;
            taskSelected(selected.recordId, selected.name);
        }
    }
}
