import QtQuick 2.7
import Lomiri.Components 1.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.11
import "../../models/accounts.js" as Accounts

Rectangle {
    id: accountFilter
    width: parent ? parent.width : 600

    height: accountFilterVisible ? panelHeight + panelMargin * 2 : 0
    color: "transparent"
    border.width: 0
    z: 1000   

    property int selectedAccountId: -1
    property string selectedAccountName: ""

    signal accountChanged(int accountId, string accountName)

    property real panelHeight: units.gu(8)
    property real panelMargin: units.gu(0)

    Item {
        id: overlayPanel
        width: accountFilter.width
        height: panelHeight
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        z: accountFilter.z + 1
        clip: true

        y: accountFilterVisible ? 0 : - (panelHeight + panelMargin)
        Behavior on y {
            NumberAnimation { duration: 260; easing.type: Easing.InOutQuad }
        }

        opacity: accountFilterVisible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180 } }

        Rectangle {
            anchors.fill: parent
            anchors.margins: panelMargin
            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#2D2D2D" : "#F5F5F5"
            border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#555555" : "#CCCCCC"
            border.width: 1
            radius: units.gu(0.4)

            RowLayout {
                anchors.fill: parent
                anchors.margins: units.gu(1)
                spacing: units.gu(2)

                Icon {
                    name: "account"
                    width: units.gu(2.5)
                    height: units.gu(2.5)
                    color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                }

                Label {
                    text: "Account:"
                    font.pixelSize: units.gu(1.8)
                    color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                }

                ComboBox {
                    id: accountCombo
                    Layout.fillWidth: true
                    Layout.preferredHeight: units.gu(4)
                    model: accountModel
                    textRole: "name"

                    background: Rectangle {
                        color: "transparent"
                        radius: units.gu(0.5)
                        border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#d3d1d1" : "#999"
                        border.width: 1
                    }

                    contentItem: Text {
                        text: accountCombo.displayText
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        leftPadding: units.gu(1)
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
                            color: (hovered ? "skyblue" : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#444" : "#e2e0da"))
                            radius: units.gu(0.3)
                            border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#d3d1d1" : "#999"
                        }
                    }

                    onActivated: {
                        if (currentIndex >= 0) {
                            const selected = model.get(currentIndex);
                            selectedAccountId = selected.id;
                            selectedAccountName = selected.name;

                            // Only set default account if it's not "All"
                            if (selected.id !== -1) {
                                Accounts.setDefaultAccount(selected.id);
                            }
                            else {
                                Accounts.clearDefaultAccount(); // You'll create this function
                            }


                            accountChanged(selected.id, selected.name);
                            console.log("Account changed to:", selected.name, "ID:", selected.id);
                        }
                    }
                }

                Label {
                    text: selectedAccountName ? "✓ " + selectedAccountName : "No account selected"
                    font.pixelSize: units.gu(1.5)
                    color: selectedAccountName
                        ? (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#4CAF50" : "#2E7D32")
                        : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#FF6B6B" : "#D32F2F")
                }
            }
        }
    }

    ListModel { id: accountModel }

    Component.onCompleted: loadAccounts()

    function loadAccounts() {
        accountModel.clear();
        
        // Add "All" option first
        accountModel.append({
            id: -1,
            name: "All Accounts",
            database: "",
            link: "",
            username: "",
            is_default: 0
        });

        const accounts = Accounts.getAccountsList();

        for (let i = 0; i < accounts.length; i++) {
            accountModel.append({
                id: accounts[i].id,
                name: accounts[i].name,
                database: accounts[i].database,
                link: accounts[i].link,
                username: accounts[i].username,
                is_default: accounts[i].is_default || 0
            });
        }

        selectDefaultAccount();
    }

    function selectDefaultAccount() {
        const defaultId = Accounts.getDefaultAccountId();
        if (defaultId >= 0) {
            // Look for the default account (skip index 0 which is "All")
            for (let i = 1; i < accountModel.count; i++) {
                const item = accountModel.get(i);
                if (item.id === defaultId) {
                    accountCombo.currentIndex = i;
                    selectedAccountId = item.id;
                    selectedAccountName = item.name;
                    accountChanged(item.id, item.name);
                    break;
                }
            }
        } else if (accountModel.count > 1) {
            // If no default account, select the first real account (index 1)
            const first = accountModel.get(1);
            accountCombo.currentIndex = 1;
            selectedAccountId = first.id;
            selectedAccountName = first.name;
            Accounts.setDefaultAccount(first.id);
            accountChanged(first.id, first.name);
        } else {
            // If only "All" option exists, select it
            accountCombo.currentIndex = 0;
            selectedAccountId = -1;
            selectedAccountName = "All Accounts";
            accountChanged(-1, "All Accounts");
        }
    }

    function refreshAccounts() { loadAccounts(); }
}