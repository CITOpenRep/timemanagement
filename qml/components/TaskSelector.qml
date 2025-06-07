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
import "../../models/database.js" as Database

ComboBox {
    id: taskCombo
    editable: true
    flat: true
    width: parent.width
    height: parent.height
    anchors.centerIn: parent.centerIn

    textRole: "name"

    property alias exposedModel: internalTaskModel
    property int projectId: -1
    property int accountId: -1
    property int selectedTaskId: -1

    // Deferred selection support
    property int deferredTaskId: -1
    property bool shouldDeferSelection: false

    signal taskSelected(int id, string name)

    ListModel {
        id: internalTaskModel
    }

    model: internalTaskModel

    background: Rectangle {
        color: "transparent"
        border.width: 0
    }

    function clear() {
        internalTaskModel.clear();
        editText = "";
        currentIndex = -1;
        selectedTaskId = -1;
        deferredTaskId = -1;
        shouldDeferSelection = false;
    }

    function loadTasks() {
        console.log("Loading Tasks for projectId:", projectId, " and accountId:", accountId);

        if (projectId === -1 || accountId === -1) {
            console.warn("TaskSelector: projectId or accountId not set. Skipping load.");
            return;
        }

        internalTaskModel.clear();

        var tasks = Database.getTasksForAccountAndProject(accountId, projectId);
        console.log("📋 Tasks = " + JSON.stringify(tasks, null, 2));

        for (var i = 0; i < tasks.length; i++) {
            var t = tasks[i];
            internalTaskModel.append({
                name: t.name,
                id: t.remote_id,
                recordId: t.remote_id,
                project_id: t.project_id
            });
        }

        if (internalTaskModel.count > 0 && !shouldDeferSelection) {
            let item = internalTaskModel.get(0);
            if (item && item.recordId !== undefined) {
                currentIndex = 0;
                editText = item.name;
                selectedTaskId = item.recordId;
                taskSelected(selectedTaskId, item.name);
            }
        }

        if (shouldDeferSelection && deferredTaskId > 0) {
            Qt.callLater(() => {
                selectTaskById(deferredTaskId);
                shouldDeferSelection = false;
                deferredTaskId = -1;
            });
        }
    }

    function selectTaskById(taskId) {
        for (var i = 0; i < internalTaskModel.count; i++) {
            let item = internalTaskModel.get(i);
            if (item.recordId === taskId) {
                if (item && item.recordId === taskId) {
                    console.log("Task matched:", item.name);
                    currentIndex = i;
                    editText = item.name;
                    selectedTaskId = item.recordId;
                    taskSelected(selectedTaskId, item.name);
                    break;
                }
            }
        }
    }

    onActivated: {
        if (currentIndex >= 0) {
            let selected = model.get(currentIndex);
            selectedTaskId = selected.id;
            taskSelected(selectedTaskId, selected.name);
        }
    }

    onAccepted: {
        let idx = find(editText);
        if (idx !== -1) {
            let selected = model.get(idx);
            selectedTaskId = selected.id;
            taskSelected(selectedTaskId, selected.name);
        }
    }
}
