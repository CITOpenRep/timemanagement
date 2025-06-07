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
import "../../models/Utils.js" as Utils

ComboBox {
    id: instanceCombo
    flat: true
    editable: true
    width: parent.width
    height: parent.height
    anchors.centerIn: parent.centerIn
    textRole: "name"

    property int selectedInstanceId: 0
    signal accountSelected(int id, string name)

    ListModel {
        id: internalInstanceModel
    }

    model: internalInstanceModel

    function selectFirstAccount() {
        if (internalInstanceModel.count > 0) {
            currentIndex = 0;
            editText = internalInstanceModel.get(0).name;
            selectedInstanceId = internalInstanceModel.get(0).id;
            accountSelected(selectedInstanceId, editText);
        } else {
            currentIndex = -1;
            editText = "Select an account";
        }
    }

    function selectAccountById(accountId) {
        console.log("Loading account" + accountId);
        for (var i = 0; i < internalInstanceModel.count; i++) {
            if (internalInstanceModel.get(i).id === accountId) {
                currentIndex = i;
                editText = internalInstanceModel.get(i).name;
                selectedInstanceId = internalInstanceModel.get(i).id;
                accountSelected(selectedInstanceId, internalInstanceModel.get(i).name);
                return;
            }
        }
    }

    Component.onCompleted: {
        Utils.updateAccounts(internalInstanceModel);
        selectFirstAccount();
    }

    onActivated: {
        if (currentIndex >= 0) {
            const selected = model.get(currentIndex);
            accountSelected(selected.id, selected.name);
        }
    }

    onAccepted: {
        const idx = find(editText);
        if (idx !== -1) {
            const selected = model.get(idx);
            accountSelected(selected.id, selected.name);
        }
    }
}
