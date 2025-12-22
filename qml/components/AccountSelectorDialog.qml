/*
 * MIT License
 * Copyright (c) 2025
 */

import QtQuick 2.7
import QtQuick.Controls 2.2
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import "../../models/accounts.js" as Accounts

Item {
    id: root
    width: 0
    height: 0

    // ---------- Public API ----------
    property string titleText: i18n.dtr("ubtms","Select Account")   
    property bool restrictToLocalOnly: false
    /** Persist last accepted choice (set when user presses OK) */
    property int selectedAccountId: Accounts.getDefaultAccountId()
    property string selectedAccountName:  Accounts.getAccountName(Accounts.getDefaultAccountId())

    signal accepted(int accountId, string accountName)
    signal canceled()

    // carry initial request until dialog is visible
    property int _initialAccountId: -2  // -2 means no initial selection, -1 is valid "All" option

    /** Show dialog; optionally preselect an account id */
    function open(initialAccountId) {
        _initialAccountId = (typeof initialAccountId === "number") ? initialAccountId : -2
        PopupUtils.open(dialogComponent)
    }

    // ---------- Private ----------
    Component {
        id: dialogComponent

        Dialog {
            id: dlg
            title: root.titleText
            modal: true

            implicitWidth: units.gu(42)
            implicitHeight: column.implicitHeight + units.gu(4)

            StyleHints {
                backgroundColor: theme.palette.normal.background
                foregroundColor: theme.palette.normal.backgroundText
            }

            Column {
                id: column
                spacing: units.gu(1.5)
                width: parent.width

                Label {
                    text:  i18n.dtr("ubtms", "Choose an account to use")
                    color: theme.palette.normal.backgroundText
                    wrapMode: Text.WordWrap
                }

                ComboBox {
                    id: accountCombo
                    flat: true
                    editable: true
                    width: parent.width - units.gu(2)
                    anchors.horizontalCenter: parent.horizontalCenter
                    textRole: "name"

                    // allow wrapper to restrict
                    property bool restrictToLocalOnly: root.restrictToLocalOnly

                    background: Rectangle {
                        color: "transparent"
                        radius: units.gu(0.6)
                        border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#d3d1d1" : "#999"
                    }

                    contentItem: Text {
                        text: accountCombo.displayText
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        anchors.verticalCenter: parent.verticalCenter
                        leftPadding: units.gu(2)
                    }

                    delegate: ItemDelegate {
                        width: accountCombo.width
                        hoverEnabled: true
                        contentItem: Text {
                            text: model.name
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                            leftPadding: units.gu(1)
                            elide: Text.ElideRight
                        }
                        background: Rectangle {
                            color: hovered ? "skyblue"
                                           : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#444" : "#e2e0da")
                            radius: units.gu(0.5)
                            border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#d3d1d1" : "#999"
                        }
                    }

                    // ---- State & signals ----
                    property int selectedInstanceId: -2  // -2 means no selection, -1 is valid "All" option
                    property int deferredAccountId: -2  // -2 means no deferred selection, -1 is valid "All" option
                    property bool shouldDeferSelection: false
                    property bool suppressSignal: false
                    signal accountSelected(int id, string name)

                    ListModel { id: internalInstanceModel }
                    model: internalInstanceModel

                    function loadAccounts() {
                        internalInstanceModel.clear();

                        // Add "All" option first (ID = -1)
                        if (!restrictToLocalOnly) {
                            internalInstanceModel.append({
                                id: -1,
                                name: i18n.dtr("ubtms", "All Accounts"),
                                database: "",
                                link: "",
                                username: "",
                                is_default: 0
                            });
                        }

                        const accounts = Accounts.getAccountsList();
                        for (let i = 0; i < accounts.length; i++) {
                            if (restrictToLocalOnly && accounts[i].id !== 0) continue;
                            internalInstanceModel.append({
                                id: accounts[i].id,
                                name: accounts[i].name,
                                database: accounts[i].database,
                                link: accounts[i].link,
                                username: accounts[i].username,
                                is_default: accounts[i].is_default || 0
                            });
                        }
                        if (shouldDeferSelection && deferredAccountId >= -1) {
                            shouldDeferSelection = false;
                            Qt.callLater(() => {
                                selectAccountById(deferredAccountId);
                                deferredAccountId = -2;  // Use -2 as "no deferred selection" marker
                            });
                        } else {
                            Qt.callLater(() => selectDefaultAccount());
                        }
                    }

                    function selectFirstAccount() {
                        if (internalInstanceModel.count > 0) {
                            currentIndex = 0;
                            const first = internalInstanceModel.get(0);
                            editText = first.name;
                            selectedInstanceId = first.id;
                            if (!shouldDeferSelection)
                                accountSelected(selectedInstanceId, first.name);
                        } else {
                            currentIndex = -1;
                            selectedInstanceId = -2;  // -2 means no selection, -1 is valid "All Accounts"
                            editText = i18n.dtr("ubtms","Select an account");
                        }
                    }

                    function selectDefaultAccount() {
                        for (let i = 0; i < internalInstanceModel.count; i++) {
                            const item = internalInstanceModel.get(i);
                            if (item.is_default === 1) {
                                suppressSignal = true;
                                currentIndex = i;
                                editText = item.name;
                                selectedInstanceId = item.id;
                                Qt.callLater(() => suppressSignal = false);
                                accountSelected(item.id, item.name);
                                return;
                            }
                        }
                        const defaultId = Accounts.getDefaultAccountId();
                        if (defaultId > 0) {
                            selectAccountById(defaultId);
                            return;
                        }
                        selectFirstAccount();
                    }

                    function selectAccountById(accountId) {
                        if (internalInstanceModel.count === 0) {
                            shouldDeferSelection = true;
                            deferredAccountId = accountId;
                            return;
                        }
                        for (let i = 0; i < internalInstanceModel.count; i++) {
                            const item = internalInstanceModel.get(i);
                            if (item.id === accountId) {
                                suppressSignal = true;
                                currentIndex = i;
                                editText = item.name;
                                selectedInstanceId = item.id;
                                Qt.callLater(() => suppressSignal = false);
                                if (selectedInstanceId !== item.id) {
                                    accountSelected(item.id, item.name);
                                }
                                return;
                            }
                        }
                        console.warn("⚠️ Account ID not found:", accountId);
                    }

                    function refreshAndSelectDefault() { loadAccounts(); }

                    Component.onCompleted: loadAccounts()

                    onActivated: {
                        if (suppressSignal) return;
                        if (currentIndex >= 0) {
                            const selected = model.get(currentIndex);
                            selectedInstanceId = selected.id;
                            accountSelected(selected.id, selected.name);
                        }
                    }

                    onAccepted: {
                        if (suppressSignal) return;
                        const idx = find(editText);
                        if (idx !== -1) {
                            const selected = model.get(idx);
                            selectedInstanceId = selected.id;
                            accountSelected(selected.id, selected.name);
                        }
                    }
                }

                Row {
                    spacing: units.gu(1)
                    width: parent.width
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.margins: units.gu(1)

                    Button {
                        text: i18n.dtr("ubtms","Cancel")
                        onClicked: {
                            PopupUtils.close(dlg)
                            root.canceled()
                        }
                    }

                    Button {
                        text: i18n.dtr("ubtms","OK")
                        enabled: accountCombo.selectedInstanceId >= -1  // -1 is "All Accounts", which is valid
                        onClicked: {
                            // persist on root and emit
                            root.selectedAccountId = accountCombo.selectedInstanceId
                            root.selectedAccountName = accountCombo.displayText
                            PopupUtils.close(dlg)
                            root.accepted(root.selectedAccountId, root.selectedAccountName)
                        }
                        StyleHints { backgroundColor: LomiriColors.orange; foregroundColor: "white" }
                    }
                }
            }

            onVisibleChanged: {
                if (visible) {
                    // refresh list
                    accountCombo.refreshAndSelectDefault()
                    // apply deferred initial id from root.open()
                    if (root._initialAccountId >= -1) {
                        accountCombo.shouldDeferSelection = true
                        accountCombo.deferredAccountId = root._initialAccountId
                        root._initialAccountId = -2
                    }
                }
            }
        }
    }
}
