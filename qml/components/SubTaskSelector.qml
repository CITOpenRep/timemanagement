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
    id: subTaskCombo
    editable: true
    flat: true
    width: parent.width
    height: parent.height
    anchors.centerIn: parent.centerIn

    textRole: "name"

    property alias exposedModel: internalSubTaskModel
    property int taskId: -1
    property int selectedSubTaskId: -1
    property int accountId: -1

    // Optional deferred selection
    property int deferredSubTaskId: -1
    property bool shouldDeferSelection: false

    signal subTaskSelected(int id, string name)

    ListModel {
        id: internalSubTaskModel
    }

    model: internalSubTaskModel

    background: Rectangle {
        color: "transparent"
        border.width: 0
    }

    function clear() {
        internalSubTaskModel.clear();
        editText = "";
        currentIndex = -1;
        selectedSubTaskId = -1;
        deferredSubTaskId = -1;
        shouldDeferSelection = false;
    }

    function loadSubTasks() {
        console.log("Loading Subtasks for taskId:", taskId, " and accountId:", accountId);

        if (taskId === -1 || accountId === -1) {
            console.warn("SubTaskSelector: taskId or accountId not set. Skipping load.");
            return;
        }

        internalSubTaskModel.clear();

        let tasks = Utils.fetch_subtasks(accountId, taskId);
        console.log("Total subtasks fetched:", tasks.length);
        if (tasks.length === 0) {
            console.log("No Subtasks found");
            subTaskCombo.editText = "No Subtasks Found";
        }

        for (let i = 0; i < tasks.length; i++) {
            let t = tasks[i];
            console.log(" Subtask:", t.name, "parent_id:", t.parent_id, "expected:", taskId);

            internalSubTaskModel.append({
                name: t.name,
                id: t.id,
                recordId: t.id_val || t.id,
                parent_id: t.parent_id
            });
        }

        if (internalSubTaskModel.count > 0 && !shouldDeferSelection) {
            let item = internalSubTaskModel.get(0);
            currentIndex = 0;
            editText = item.name;
            selectedSubTaskId = item.recordId;
            subTaskSelected(selectedSubTaskId, editText);
        }

        if (shouldDeferSelection && deferredSubTaskId > 0) {
            Qt.callLater(() => {
                selectSubTaskById(deferredSubTaskId);
                shouldDeferSelection = false;
                deferredSubTaskId = -1;
            });
        }
    }

    function selectSubTaskById(taskId) {
        for (let i = 0; i < internalSubTaskModel.count; i++) {
            let item = internalSubTaskModel.get(i);
            if (item.recordId === taskId) {
                console.log("Subtask matched:", item.name);
                currentIndex = i;
                editText = item.name;
                selectedSubTaskId = item.recordId;
                subTaskSelected(selectedSubTaskId, item.name);
                break;
            }
        }
    }

    onActivated: {
        if (currentIndex >= 0) {
            let selected = model.get(currentIndex);
            selectedSubTaskId = selected.id;
            subTaskSelected(selectedSubTaskId, selected.name);
        }
    }

    onAccepted: {
        let idx = find(editText);
        if (idx !== -1) {
            let selected = model.get(idx);
            selectedSubTaskId = selected.id;
            subTaskSelected(selectedSubTaskId, selected.name);
        }
    }
}
