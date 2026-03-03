/*
 * MIT License
 * Copyright (c) 2025
 *
 * AccountSelectorDialog — Lomiri-native account picker.
 * Shows a scrollable list of accounts; tap to select & close.
 */

import QtQuick 2.7
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import "../../models/accounts.js" as Accounts

Item {
    id: root
    width: 0
    height: 0

    // ---------- Public API ----------
    property string titleText: i18n.dtr("ubtms", "Select Account")
    property bool restrictToLocalOnly: false

    /** Persist last accepted choice (set when user taps an account) */
    property int selectedAccountId: Accounts.getDefaultAccountId()
    property string selectedAccountName: Accounts.getAccountName(Accounts.getDefaultAccountId())

    signal accepted(int accountId, string accountName)
    signal canceled()

    // carry initial request until dialog is visible
    property int _initialAccountId: -2   // -2 = none, -1 = "All"

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

            StyleHints {
                backgroundColor: theme.palette.normal.background
                foregroundColor: theme.palette.normal.backgroundText
            }

            property bool isLoadingAccounts: false
            property int preselectedId: -2

            ListModel { id: accountListModel }

            // ---- data helpers ----
            function loadAccounts() {
                isLoadingAccounts = true
                accountListModel.clear()

                // Determine which id to highlight
                var highlightId = preselectedId
                if (highlightId < -1) highlightId = root.selectedAccountId

                // "All Accounts" synthetic entry
                if (!root.restrictToLocalOnly) {
                    accountListModel.append({
                        accountId: -1,
                        name:      i18n.dtr("ubtms", "All Accounts"),
                        subtitle:  "",
                        isCurrent: (highlightId === -1)
                    })
                }

                var accounts = Accounts.getAccountsList()
                for (var i = 0; i < accounts.length; i++) {
                    if (root.restrictToLocalOnly && accounts[i].id !== 0) continue
                    var sub = accounts[i].link
                              ? accounts[i].link
                              : (accounts[i].database || "")
                    accountListModel.append({
                        accountId: accounts[i].id,
                        name:      accounts[i].name,
                        subtitle:  sub,
                        isCurrent: (accounts[i].id === highlightId)
                    })
                }

                isLoadingAccounts = false
            }

            // ---- layout ----
            Column {
                id: column
                spacing: units.gu(1.5)
                width: parent.width

                Label {
                    text: i18n.dtr("ubtms", "Choose an account to use")
                    textSize: Label.Small
                    color: theme.palette.normal.backgroundSecondaryText
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                // account list container
                Rectangle {
                    width: parent.width
                    height: Math.min(units.gu(48),
                                     accountListView.contentHeight + units.gu(2))
                    color: theme.palette.normal.background
                    radius: units.gu(1)
                    border.color: theme.palette.normal.base
                    border.width: units.dp(1)

                    ListView {
                        id: accountListView
                        anchors.fill: parent
                        anchors.margins: units.gu(0.5)
                        clip: true
                        spacing: units.dp(2)

                        model: accountListModel

                        delegate: ListItem {
                            id: accountDelegate
                            height: units.gu(6)
                            color: model.isCurrent
                                   ? Qt.rgba(LomiriColors.orange.r,
                                             LomiriColors.orange.g,
                                             LomiriColors.orange.b, 0.08)
                                   : "transparent"
                            highlightColor: Qt.rgba(LomiriColors.orange.r,
                                                    LomiriColors.orange.g,
                                                    LomiriColors.orange.b, 0.15)
                            divider.visible: true

                            ListItemLayout {
                                anchors.centerIn: parent

                                title.text: model.name
                                title.font.bold: model.isCurrent
                                title.color: model.isCurrent
                                             ? LomiriColors.orange
                                             : theme.palette.normal.backgroundText

                                subtitle.text: model.subtitle || ""
                                subtitle.color: theme.palette.normal.backgroundSecondaryText
                                subtitle.visible: model.subtitle !== ""
                                subtitle.maximumLineCount: 1
                                subtitle.elide: Text.ElideMiddle

                                // leading accent bar
                                Rectangle {
                                    SlotsLayout.position: SlotsLayout.Leading
                                    width: units.dp(3)
                                    height: units.gu(3.5)
                                    radius: units.dp(2)
                                    color: model.isCurrent
                                           ? LomiriColors.orange
                                           : "transparent"
                                }

                                // trailing check icon
                                Icon {
                                    SlotsLayout.position: SlotsLayout.Trailing
                                    width: units.gu(2.5)
                                    height: units.gu(2.5)
                                    name: "tick"
                                    color: LomiriColors.orange
                                    visible: model.isCurrent
                                }
                            }

                            onClicked: {
                                root.selectedAccountId   = model.accountId
                                root.selectedAccountName = model.name
                                PopupUtils.close(dlg)
                                root.accepted(model.accountId, model.name)
                            }
                        }

                        // empty state
                        Label {
                            anchors.centerIn: parent
                            visible: accountListModel.count === 0
                                     && !dlg.isLoadingAccounts
                            text: i18n.dtr("ubtms", "No accounts available")
                            textSize: Label.Medium
                            color: theme.palette.normal.backgroundSecondaryText
                        }
                    }

                    // custom scrollbar
                    Rectangle {
                        visible: accountListView.contentHeight
                                 > accountListView.height
                        anchors {
                            right: parent.right
                            top: parent.top; bottom: parent.bottom
                            margins: units.dp(3)
                        }
                        width: units.dp(3)
                        radius: units.dp(2)
                        color: theme.palette.normal.base

                        Rectangle {
                            width: parent.width
                            height: Math.max(units.gu(2),
                                (accountListView.height
                                 / accountListView.contentHeight)
                                * parent.height)
                            y: (accountListView.contentY
                                / accountListView.contentHeight)
                               * parent.height
                            radius: parent.radius
                            color: LomiriColors.orange
                        }
                    }
                }

                // cancel button
                Button {
                    text: i18n.dtr("ubtms", "Cancel")
                    width: parent.width
                    onClicked: {
                        PopupUtils.close(dlg)
                        root.canceled()
                    }
                }
            }

            // loading spinner
            ActivityIndicator {
                anchors.centerIn: parent
                running: dlg.isLoadingAccounts
                visible: running
            }

            onVisibleChanged: {
                if (visible) {
                    // Determine preferred selection
                    if (root._initialAccountId >= -1) {
                        preselectedId = root._initialAccountId
                        root._initialAccountId = -2
                    } else if (root.selectedAccountId >= -1) {
                        preselectedId = root.selectedAccountId
                    } else {
                        preselectedId = -2
                    }
                    loadAccounts()
                }
            }
        }
    }
}
