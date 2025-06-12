/*
 * MIT License
 * Copyright (c) 2025 CIT-Services
 */

import QtQuick 2.7
import QtQuick.Controls 2.2
import "../../models/project.js" as Project

ComboBox {
    id: projectCombo
    editable: false
    flat: true
    width: parent.width
    height: parent.height
    anchors.centerIn: parent.centerIn

    background: Rectangle {
        color: "transparent"
        radius: units.gu(0.6)
        border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#d3d1d1" : "#999"
        border.width: 1
    }

    contentItem: Text {
        text: projectCombo.displayText
        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        anchors.verticalCenter: parent.verticalCenter
        leftPadding: units.gu(2)
    }

    delegate: ItemDelegate {
        width: projectCombo.width
        hoverEnabled: true
        contentItem: Text {
            text: model.name
            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
            leftPadding: units.gu(1)
            elide: Text.ElideRight
        }
        background: Rectangle {
            color: hovered ? (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#444" : "#e0e0e0") : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#222" : "white")
            radius: 4
        }
    }

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
    property bool isDeferredSelection: false

    function getSelectedDbRecordId() {
        if (selectedProjectId < 0 || accountId === -1)
            return null;

        for (let i = 0; i < internalProjectModel.count; i++) {
            let item = internalProjectModel.get(i);
            if (item.recordId === selectedProjectId) {
                return (accountId === 0) ? item.id : (item.odoo_record_id && item.odoo_record_id !== 0) ? item.odoo_record_id : null;
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

    function load(accountIdVal, parentOdooIdVal) {
        isDeferredSelection = false;
        _loadInternal(accountIdVal, parentOdooIdVal, false, true);  // useParentFilter = true
    }

    function loadDeferred(accountIdVal, projectOdooIdVal) {
        isDeferredSelection = true;
        _loadInternal(accountIdVal, projectOdooIdVal, true, false); // useParentFilter = false
    }

    function _loadInternal(accountIdVal, secondVal, suppressSignal, useParentFilter) {
        //console.log(" _loadInternal → accountId:", accountIdVal, "secondVal:", secondVal, "suppressSignal:", suppressSignal, "useParentFilter:", useParentFilter);
        clear();
        accountId = accountIdVal;

        const noneLabel = (mode === "subproject") ? "No Subproject" : "No Project";
        internalProjectModel.append({
            name: noneLabel,
            id: -1,
            recordId: -1
        });
        currentIndex = 0;
        selectedProjectId = -1;
        editText = noneLabel;

        if (accountId === -1)
            return;

        const allProjects = Project.getProjectsForAccount(accountId);
        let resolvedParentId = secondVal;
        if (accountId > 0) {
            if (useParentFilter && secondVal !== 0) {
                for (let i = 0; i < allProjects.length; i++) {
                    const p = allProjects[i];
                    console.log("accountId is " + accountId + " p.odoo_record_id is " + p.odoo_record_id + " and p.id is " + p.id);

                    if (secondVal === p.id) {
                        console.log("got the record");
                        resolvedParentId = p.odoo_record_id;
                        break;
                    }
                }
            }
        }
        console.log("Resolved parent id is " + resolvedParentId);

        for (let i = 0; i < allProjects.length; i++) {
            const p = allProjects[i];
            const pid = parseInt(p.parent_id) || 0;

            const parentMatch = useParentFilter ? ((secondVal === 0 && pid === 0) || (secondVal !== 0 && pid === resolvedParentId)) : (mode === "project" && pid === 0) || (mode === "subproject" && pid !== 0);

            if (!parentMatch)
                continue;

            internalProjectModel.append({
                name: p.name,
                id: p.id,
                recordId: p.id,
                odoo_record_id: p.odoo_record_id,
                parent_id: p.parent_id
            });
        }

        if (useParentFilter)
            return;

        if (secondVal === -1)
            return;

        let found = false;
        for (let i = 0; i < internalProjectModel.count; i++) {
            const item = internalProjectModel.get(i);
            const isMatch = (accountId === 0) ? item.recordId === secondVal : item.odoo_record_id === secondVal;

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

    function selectProjectById(accountId) {
        if (internalProjectModel.count === 0) {
            console.log("✅ Empty Projects");
            return;
        }

        for (let i = 0; i < internalProjectModel.count; i++) {
            const item = internalProjectModel.get(i);
            if (item.id === accountId) {
                currentIndex = i;
                editText = item.name;
                selectedInstanceId = item.id;
                console.log("✅ Project selected:", item.name);
                return;
            }
        }

        console.warn("⚠️ Account ID not found:", accountId);
    }

    onActivated: {
        isDeferredSelection = false;
        if (currentIndex >= 0) {
            const selected = model.get(currentIndex);
            selectedProjectId = selected.recordId;
            projectSelected(selected.recordId, selected.name);
        }
    }

    onAccepted: {
        isDeferredSelection = false;
        const idx = find(editText);
        if (idx !== -1) {
            const selected = model.get(idx);
            selectedProjectId = selected.recordId;
            projectSelected(selected.recordId, selected.name);
        }
    }
}
