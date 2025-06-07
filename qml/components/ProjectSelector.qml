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
import "../../models/utils.js" as Utils

ComboBox {
    id: projectCombo
    editable: true
    flat: true
    width: parent.width
    height: parent.height
    anchors.centerIn: parent.centerIn

    textRole: "name"

    property alias exposedModel: internalProjectModel
    property int accountId: -1
    property bool workPersonaState: true
    property int selectedProjectId: -1

    // Deferred selection support
    property int deferredProjectId: -1
    property bool shouldDeferSelection: false

    signal projectSelected(int id, string name)

    ListModel {
        id: internalProjectModel
    }

    model: internalProjectModel

    background: Rectangle {
        color: "transparent"
        border.width: 0
    }

    function loadProjects() {
        if (accountId === -1) {
            console.warn("⚠️ ProjectSelector: accountId not set. Skipping load.");
            return;
        }

        internalProjectModel.clear();

        let projects = Utils.fetch_projects(accountId, workPersonaState);
        for (let i = 0; i < projects.length; i++) {
            let p = projects[i];
            if (p.parent_id && p.parent_id !== 0 && p.parent_id !== "0")
                continue;

            internalProjectModel.append({
                name: p.name,
                id: p.id,
                recordId: p.id,
                projectHasSubProject: p.projectHasSubProject
            });
        }

        if (internalProjectModel.count > 0 && !shouldDeferSelection) {
            currentIndex = 0;
            editText = internalProjectModel.get(0).name;
            var item = internalProjectModel.get(0);
            selectedProjectId = (item.recordId !== undefined) ? item.recordId : item.id;
            projectSelected(selectedProjectId, editText);
        }

        if (shouldDeferSelection && deferredProjectId > 0) {
            Qt.callLater(() => {
                selectProjectById(deferredProjectId);
                shouldDeferSelection = false;
                deferredProjectId = -1;
            });
        }
    }

    function selectProjectById(projectId) {
        console.log("Loading project : " + projectId);
        for (let i = 0; i < internalProjectModel.count; i++) {
            let item = internalProjectModel.get(i);
            if (item.recordId === projectId) {
                console.log("✅ Project matched:", item.name);
                currentIndex = i;
                editText = item.name;
                selectedProjectId = item.recordId;
                projectSelected(selectedProjectId, item.name);
                break;
            }
        }
    }

    onActivated: {
        if (currentIndex >= 0) {
            let selected = model.get(currentIndex);
            selectedProjectId = selected.id;
            projectSelected(selectedProjectId, selected.name);
        }
    }

    onAccepted: {
        let idx = find(editText);
        if (idx !== -1) {
            let selected = model.get(idx);
            selectedProjectId = selected.id;
            projectSelected(selectedProjectId, selected.name);
        }
    }
}
