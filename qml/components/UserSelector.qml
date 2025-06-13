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
import "../../models/accounts.js" as Accounts

ComboBox {
    id: userCombo
    editable: false
    flat: true
    width: parent.width
    height: parent.height
    anchors.centerIn: parent.centerIn
    textRole: "name"

    background: Rectangle {
        color: "transparent"
        radius: units.gu(0.6)
        border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#d3d1d1" : "#999"
        border.width: 1
    }

    contentItem: Label {
        text: userCombo.displayText
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
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
            color: (hovered ? "skyblue" : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#444" : "#e2e0da"))
            radius: units.gu(0.5)
            border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#d3d1d1" : "#999"
        }
    }

    property int accountId: -1
    property int selectedUserId: -1
    property int deferredUserId: -1
    property bool shouldDeferUserSelection: false

    signal userSelected(int remoteid, string name)

    ListModel {
        id: internalUserModel
    }

    model: internalUserModel

    function selectFirstUser() {
        if (internalUserModel.count > 0) {
            const first = internalUserModel.get(0);
            currentIndex = 0;
            selectedUserId = first.remoteid;
            if (!shouldDeferUserSelection)
                userSelected(selectedUserId, first.name);
        } else {
            currentIndex = -1;
            selectedUserId = -1;
        }
    }

    function selectUserById(remoteid) {
        if (internalUserModel.count === 0) {
            shouldDeferUserSelection = true;
            deferredUserId = remoteid;
            return;
        }

        for (let i = 0; i < internalUserModel.count; i++) {
            const user = internalUserModel.get(i);
            if (user.id === remoteid) {
                // 👈 use id, not remoteid
                Qt.callLater(() => {
                    currentIndex = i;
                    selectedUserId = user.id;
                    //console.log("(Deferred) User selected:", user.name);
                    if (!shouldDeferUserSelection)
                        userSelected(user.id, user.name);
                });
                //console.log("User selected:", user.name);
                if (!shouldDeferUserSelection)
                    userSelected(user.id, user.name);
                return;
            }
        }

        console.warn("⚠️ User ID not found:", remoteid);
        if (!shouldDeferUserSelection) {
            selectFirstUser();
        }
    }

    function loadUsers() {
        internalUserModel.clear();
        if (accountId === -1) {
            console.warn("UsersCombo: accountId not set. Skipping user load.");
            return;
        }

        const users = Accounts.getUsers(accountId);
        for (let i = 0; i < users.length; i++) {
            internalUserModel.append({
                id: users[i].odoo_record_id,
                name: users[i].name,
                remoteid: users[i].odoo_record_id
            });
        }

        //console.log('About to check shouldDeferUserSelection: ' + shouldDeferUserSelection + " " + deferredUserId);
        if (shouldDeferUserSelection && deferredUserId > -1) {
            Qt.callLater(() => {
                selectUserById(deferredUserId);
                shouldDeferUserSelection = false;
                deferredUserId = -1;
            });
        } else {
            selectFirstUser();
        }
    }

    onActivated: {
        if (currentIndex >= 0) {
            const selected = model.get(currentIndex);
            selectedUserId = selected.remoteid;
            if (!shouldDeferUserSelection)
                userSelected(selectedUserId, selected.name);
        }
    }

    onAccepted: {
        const idx = find(editText);
        if (idx !== -1) {
            const selected = model.get(idx);
            selectedUserId = selected.remoteid;
            if (!shouldDeferUserSelection)
                userSelected(selected.remoteid, selected.name);
        }
    }
}
