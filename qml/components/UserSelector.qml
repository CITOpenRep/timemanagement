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
    id: userCombo
    editable: true
    flat: true
    width: parent.width
    height: parent.height
    anchors.centerIn: parent.centerIn
    textRole: "name"

    background: Rectangle {
        color: "transparent"
        radius: units.gu(0.6)
        border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#d3d1d1" : "transparent"
        border.width: 1
    }

    contentItem: Text {
        text: userCombo.displayText
        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        anchors.verticalCenter: parent.verticalCenter
        leftPadding: units.gu(2)
    }

    delegate: ItemDelegate {
        width: userCombo.width
        hoverEnabled: true
        contentItem: Text {
            text: model.name
            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
            leftPadding: units.gu(1)
            elide: Text.ElideRight
        }
        background: Rectangle {
            color: hovered
                ? (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#444" : "#e0e0e0")
                : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#222" : "white")
            radius: 4
        }
    }

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
