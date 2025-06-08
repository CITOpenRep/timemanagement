/*
 * MIT License
 * Copyright (c) 2025 CIT-Services
 */

import QtQuick 2.7
import QtQuick.Controls 2.2
import "../../models/project.js" as Project

// This component represents a project selector combo box that can act in two modes:
// 1. "project" mode → shows only top-level projects (no parent)
// 2. "subproject" mode → shows children of a given parent project
//
// The component supports both local accounts (id-based) and remote/Odoo accounts (odoo_record_id-based).

ComboBox {
    id: projectCombo
    editable: true
    flat: true
    width: parent.width
    height: parent.height
    anchors.centerIn: parent.centerIn

    textRole: "name"

    Component.onCompleted: {
        // Display placeholder before account is selected
        if (accountId === -1) {
            editText = (mode === "subproject") ? "No Subproject" : "No Project";
        }
    }

    property alias exposedModel: internalProjectModel
    property int accountId: -1                      // Required to scope projects
    property int selectedProjectId: -1              // Output: selected project ID
    property string mode: "project"                 // "project" or "subproject"
    property int parentProjectId: -1                // Only needed in subproject mode

    property int deferredProjectId: -1              // Optional: preselect after data loads
    property bool shouldDeferSelection: false

    signal projectSelected(int id, string name)     // Emits whenever a valid project is chosen

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
                // Local account (accountId == 0): return local DB ID
                if (accountId === 0) return item.id;

                // Remote account: return Odoo ID if valid
                return (item.odoo_record_id && item.odoo_record_id !== 0) ? item.odoo_record_id : null;
            }
        }

        return null;
    }


    function clear() {
        console.log("clear() called");
        internalProjectModel.clear();
        currentIndex = -1;
        selectedProjectId = -1;
        editText = "";
        deferredProjectId = -1;
        shouldDeferSelection = false;
    }

    function loadProjects() {
        console.log("loadProjects() called - mode:", mode, "accountId:", accountId, "parentProjectId:", parentProjectId);
        clear();

        // Always offer "No Project" or "No Subproject" option
        const noneLabel = (mode === "subproject") ? "No Subproject" : "No Project";
        internalProjectModel.append({
            name: noneLabel,
            id: -1,
            recordId: -1
        });
        console.log("Added default option:", noneLabel);

        // Skip loading if account is invalid
        if (accountId === -1) {
            console.warn("ProjectSelector: accountId not set. Skipping load.");
            editText = noneLabel;
            return;
        }

        // Subproject mode requires a parent to be defined
        if (mode === "subproject" && parentProjectId === -1) {
            console.warn("ProjectSelector: parentProjectId not set for subproject mode.");
            return;
        }

        // Fetch all available projects for this account
        const allProjects = Project.getProjectsForAccount(accountId);
        console.log("Total projects fetched:", allProjects.length);

        for (let i = 0; i < allProjects.length; i++) {
            const p = allProjects[i];

            if (mode === "project") {
                // Filter out subprojects
                if (p.parent_id && parseInt(p.parent_id) !== 0)
                    continue;
            } else if (mode === "subproject") {
                // Resolve correct parent ID based on account type
                let effectiveParentId = parentProjectId;

                if (accountId !== 0) {
                    // For remote/Odoo accounts, parent_id stores odoo_record_id of parent
                    for (let j = 0; j < allProjects.length; j++) {
                        const candidate = allProjects[j];
                        if (candidate.id === parentProjectId) {
                            effectiveParentId = candidate.odoo_record_id;
                            console.log("Translated parentProjectId", parentProjectId, "→ odoo_record_id", effectiveParentId);
                            break;
                        }
                    }
                }

                // Skip projects that aren't children of the selected parent
                if (p.parent_id !== effectiveParentId)
                    continue;
            }

            // Append project to model
            console.log("Adding project:", p.name, "| ID:", p.id, "| Parent:", p.parent_id);
            internalProjectModel.append({
                name: p.name,
                id: p.id,
                recordId: p.id,
                odoo_record_id: p.odoo_record_id,
                parent_id: p.parent_id
            });
        }

        // Handle default selection
        if (!shouldDeferSelection) {
            currentIndex = 0;
            let item = internalProjectModel.get(0);
            selectedProjectId = item.recordId;
            editText = item.name;
            console.log("Auto-selected:", item.name, "| ID:", item.recordId);
            projectSelected(selectedProjectId, item.name);
        }

        // Handle deferred selection if needed
        if (shouldDeferSelection && deferredProjectId > -1) {
            console.log("Deferring project selection:", deferredProjectId);
            Qt.callLater(() => {
                selectProjectById(deferredProjectId);
                shouldDeferSelection = false;
                deferredProjectId = -1;
            });
        }
    }

    function selectProjectById(projectId) {
        console.log("selectProjectById() -> Looking for:", projectId);
        for (let i = 0; i < internalProjectModel.count; i++) {
            const item = internalProjectModel.get(i);
            if (item.recordId === projectId) {
                currentIndex = i;
                editText = item.name;
                selectedProjectId = item.recordId;

                console.log("Project matched:");
                console.log(JSON.stringify(item, null, 2));

                projectSelected(selectedProjectId, item.name);
                return;
            }
        }
        console.warn("No matching project found for ID:", projectId);
    }

    onActivated: {
        if (currentIndex >= 0) {
            const selected = model.get(currentIndex);
            selectedProjectId = selected.recordId;
            console.log("onActivated: Selected:", selected.name, "| ID:", selected.recordId);
            projectSelected(selected.recordId, selected.name);
        }
    }

    onAccepted: {
        const idx = find(editText);
        if (idx !== -1) {
            const selected = model.get(idx);
            selectedProjectId = selected.recordId;
            console.log("onAccepted: Selected:", selected.name, "| ID:", selected.recordId);
            projectSelected(selected.recordId, selected.name);
        }
    }
}
