/*
 * MIT License
 * Copyright (c) 2025 CIT-Services
 */

import QtQuick 2.7
import QtQuick.Controls 2.2
import "../../models/project.js" as Project

ComboBox {
    id: projectCombo
    editable: true
    flat: true
    width: parent.width
    height: parent.height
    anchors.centerIn: parent.centerIn

    textRole: "name"

    Component.onCompleted: {
        if (accountId === -1)
            editText = (mode === "subproject") ? "No Subproject" : "No Project";
    }

    property alias exposedModel: internalProjectModel
    property int accountId: -1
    property int selectedProjectId: -1
    property string mode: "project"    // or "subproject"
    property bool autoSelectFirst: true

    signal projectSelected(int id, string name)

    ListModel {
        id: internalProjectModel
    }

    model: internalProjectModel

    background: Rectangle {
        color: "transparent"
        border.width: 0
    }

    function getSelectedDbRecordId() {
        if (selectedProjectId < 0 || accountId === -1)
            return null;

        for (let i = 0; i < internalProjectModel.count; i++) {
            let item = internalProjectModel.get(i);
            if (item.recordId === selectedProjectId) {
                return (accountId === 0)
                    ? item.id
                    : (item.odoo_record_id && item.odoo_record_id !== 0) ? item.odoo_record_id : null;
            }
        }
        return null;
    }

    function clear() {
        internalProjectModel.clear();
        currentIndex = -1;
        selectedProjectId = -1;
        editText = "";
    }

    function load(accountIdVal, projectIdVal) {
        _loadInternal(accountIdVal, projectIdVal, false)
    }

    function loadDeferred(accountIdVal, projectIdVal) {
        _loadInternal(accountIdVal, projectIdVal, true)
    }

    function _loadInternal(accountIdVal, projectIdVal, suppressSignal) {
        clear();
        accountId = accountIdVal;

        const noneLabel = (mode === "subproject") ? "No Subproject" : "No Project";
        internalProjectModel.append({ name: noneLabel, id: -1, recordId: -1 });
        currentIndex = 0;
        selectedProjectId = -1;
        editText = noneLabel;

        if (accountId === -1)
            return;

        const allProjects = Project.getProjectsForAccount(accountId);

        for (let i = 0; i < allProjects.length; i++) {
            const p = allProjects[i];

            if (mode === "project" && p.parent_id && parseInt(p.parent_id) !== 0)
                continue;

            if (mode === "subproject" && (!p.parent_id || parseInt(p.parent_id) === 0))
                continue;

            internalProjectModel.append({
                name: p.name,
                id: p.id,
                recordId: p.id,
                odoo_record_id: p.odoo_record_id,
                parent_id: p.parent_id
            });
        }

        if (projectIdVal === -1)
            return;

        let found = false;
        for (let i = 0; i < internalProjectModel.count; i++) {
            const item = internalProjectModel.get(i);
            const isMatch = (accountId === 0)
                ? item.recordId === projectIdVal
                : item.odoo_record_id === projectIdVal;

            if (isMatch) {
                currentIndex = i;
                selectedProjectId = item.recordId;
                editText = item.name;
                found = true;
                if (!suppressSignal)
                    projectSelected(selectedProjectId, editText);
                break;
            }
        }

        if (!found && autoSelectFirst && internalProjectModel.count > 1) {
            const item = internalProjectModel.get(1);
            currentIndex = 1;
            selectedProjectId = item.recordId;
            editText = item.name;
            if (!suppressSignal)
                projectSelected(selectedProjectId, item.name);
        }
    }

    onActivated: {
        if (currentIndex >= 0) {
            const selected = model.get(currentIndex);
            selectedProjectId = selected.recordId;
            projectSelected(selected.recordId, selected.name);
        }
    }

    onAccepted: {
        const idx = find(editText);
        if (idx !== -1) {
            const selected = model.get(idx);
            selectedProjectId = selected.recordId;
            projectSelected(selected.recordId, selected.name);
        }
    }
}
