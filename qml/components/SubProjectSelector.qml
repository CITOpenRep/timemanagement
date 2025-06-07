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
    id: subProjectCombo
    editable: true
    flat: true
    width: parent.width
    height: parent.height
    anchors.centerIn: parent.centerIn

    textRole: "name"

    property alias exposedModel: internalSubProjectModel
    property int projectId: -1
    property int selectedSubProjectId: -1
    property int accountId: -1

    // Optional deferred selection
    property int deferredSubProjectId: -1
    property bool shouldDeferSelection: false

    signal subProjectSelected(int id, string name)

    ListModel {
        id: internalSubProjectModel
    }

    model: internalSubProjectModel

    background: Rectangle {
        color: "transparent"
        border.width: 0
    }

    function clear() {
        internalSubProjectModel.clear();
        editText = "";
        currentIndex = -1;
        selectedSubProjectId = -1;
        deferredSubProjectId = -1;
        shouldDeferSelection = false;
    }

    function loadSubProjects() {
        console.log("Loading Subprojects for projectId:", projectId, " and accountId:", accountId);

        if (!accountId || !projectId) {
            console.warn("SubProjectSelector: projectId not set. Skipping load.");
            return;
        }

        internalSubProjectModel.clear();

        let projects = Utils.fetch_subprojects(accountId, projectId);
        console.log("Total projects fetched:", projects.length);

        if (projects.length === 0) {
            console.log("No Subprojects found");
            subProjectCombo.editText = "No Subprojects Found";
        }

        for (let i = 0; i < projects.length; i++) {
            let p = projects[i];
            console.log(" Project:", p.name, "parent_id:", p.parent_id, "expected:", projectId);

            internalSubProjectModel.append({
                name: p.name,
                id: p.id,
                recordId: p.id_val || p.id,
                parent_id: p.parent_id
            });
        }

        if (internalSubProjectModel.count > 0 && !shouldDeferSelection) {
            let item = internalSubProjectModel.get(0);
            currentIndex = 0;
            editText = item.name;
            selectedSubProjectId = item.recordId;
            subProjectSelected(selectedSubProjectId, editText);
        }

        if (shouldDeferSelection && deferredSubProjectId > 0) {
            Qt.callLater(() => {
                selectSubProjectById(deferredSubProjectId);
                shouldDeferSelection = false;
                deferredSubProjectId = -1;
            });
        }
    }

    function selectSubProjectById(projectId) {
        for (let i = 0; i < internalSubProjectModel.count; i++) {
            let item = internalSubProjectModel.get(i);
            if (item.recordId === projectId) {
                console.log("Subproject matched:", item.name);
                currentIndex = i;
                editText = item.name;
                selectedSubProjectId = item.recordId;
                subProjectSelected(selectedSubProjectId, item.name);
                break;
            }
        }
    }

    onActivated: {
        if (currentIndex >= 0) {
            let selected = model.get(currentIndex);
            selectedSubProjectId = selected.id;
            subProjectSelected(selectedSubProjectId, selected.name);
        }
    }

    onAccepted: {
        let idx = find(editText);
        if (idx !== -1) {
            let selected = model.get(idx);
            selectedSubProjectId = selected.id;
            subProjectSelected(selectedSubProjectId, selected.name);
        }
    }
}
