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
import QtQuick.Layouts 1.1
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.Components.ListItems 1.3 as Old_ListItem
import QtQuick.LocalStorage 2.7 as Sql

Item {
    id: instanceSelectorRoot
    anchors.fill: parent

    property int currentIndex: 0
    property var model: []
    property alias selectedText: instanceButton.text

    signal instanceChanged(int index, string text)

    ListModel {
        id: accountsmodel
    }

    Component.onCompleted: {
        var list = get_accounts_list();
        for (var i = 0; i < list.length; i++) {
            accountsmodel.append(list[i]);
        }
    }

    TSButton {
        id: instanceButton
        Layout.fillWidth: true
        text: accountsmodel.length > 0 ? accountsmodel[currentIndex].name : "Odoo"
        onClicked: PopupUtils.open(popoverComponent, instanceButton)
    }

    Component {
        id: popoverComponent

        Popover {
            id: popover

            Column {
                width: units.gu(30)
                spacing: units.gu(1)
                padding: units.gu(1)

                Old_ListItem.Header {
                    text: ""
                }

                Repeater {
                    model: accountsmodel
                    delegate: ListItem {
                        height: layout.height + (divider.visible ? divider.height : 0)

                        ListItemLayout {
                            id: layout
                            title.text: model.name
                        }

                        onClicked: {
                            instanceSelectorRoot.currentIndex = index;
                            instanceButton.text = model.name;
                            PopupUtils.close(popover);
                            instanceSelectorRoot.instanceChanged(index, model.name);
                            console.log("Switched to:", model.name);
                        }
                    }
                }
            }
        }
    }

    function get_accounts_list() {
        var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);

        var accountsList = [];
        db.transaction(function (tx) {
            var accounts = tx.executeSql('SELECT * FROM users');
            for (var i = 0; i < accounts.rows.length; i++) {
                var row = accounts.rows.item(i);
                console.log("instance id is -------------", row.id);
                accountsList.push({
                    id: row.id,
                    name: row.name,
                    link: row.link,
                    database: row.database,
                    username: row.username,
                    connect_with: row.connectwith_id || 0,
                    api_key: row.api_key
                });
            }
        });
        return accountsList;
    }
}
