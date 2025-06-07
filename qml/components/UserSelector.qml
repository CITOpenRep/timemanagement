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
    id: userCombo
    editable: true
    flat: true
    width: parent.width
    height: parent.height
    anchors.centerIn: parent.centerIn
    textRole: "name"

    property int accountId: -1
    property int selectedUserId: -1
    signal userSelected(int remoteid, string name)

    ListModel {
        id: internalUserModel
    }

    model: internalUserModel

    function selectFirstUser() {
        if (internalUserModel.count > 0) {
            currentIndex = 0;
            editText = internalUserModel.get(0).name;
            selectedUserId = internalUserModel.get(0).remoteid;
            userSelected(selectedUserId, editText);
        }
    }

    function loadUsers() {
        if (accountId === -1) {
            console.warn("UsersCombo: accountId not set. Skipping user load.");
            return;
        }

        internalUserModel.clear();

        let users = Utils.getOdooUsers(accountId);
        for (let i = 0; i < users.length; i++) {
            internalUserModel.append({
                name: users[i].name,
                remoteid: users[i].remoteid
            });
        }

        selectFirstUser();
    }

    function selectUserById(remoteid) {
        for (let i = 0; i < internalUserModel.count; i++) {
            if (internalUserModel.get(i).remoteid === remoteid) {
                currentIndex = i;
                editText = internalUserModel.get(i).name;
                selectedUserId = remoteid;
                userSelected(selectedUserId, internalUserModel.get(i).name);
                return;
            }
        }

        selectFirstUser();
    }

    onActivated: {
        if (currentIndex >= 0) {
            let selected = model.get(currentIndex);
            selectedUserId = selected.remoteid;
            userSelected(selectedUserId, selected.name);
        }
    }

    onAccepted: {
        let idx = find(editText);
        if (idx !== -1) {
            let selected = model.get(idx);
            selectedUserId = selected.remoteid;
            userSelected(selectedUserId, selected.name);
        }
    }
}
