import QtQuick 2.7
import Lomiri.Components 1.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.11
import "../../models/accounts.js" as Accounts

Rectangle {
    id: accountFilter
    width: parent.width
    height: units.gu(6)
    color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#2D2D2D" : "#F5F5F5"
    border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#555555" : "#CCCCCC"
    border.width: 1
    
    property int selectedAccountId: -1
    property string selectedAccountName: ""
    
    signal accountChanged(int accountId, string accountName)
    
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
                    
                    // Set as default account
                    Accounts.setDefaultAccount(selected.id);
                    
                    // Emit signal for data refresh
                    accountChanged(selected.id, selected.name);
                    
                    console.log("Account changed to:", selected.name, "ID:", selected.id);
                }
            }
        }
        
        Label {
            text: selectedAccountName ? "✓ " + selectedAccountName : "No account selected"
            font.pixelSize: units.gu(1.5)
            color: selectedAccountName ? (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#4CAF50" : "#2E7D32") : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#FF6B6B" : "#D32F2F")
        }
    }
    
    ListModel {
        id: accountModel
    }
    
    Component.onCompleted: {
        loadAccounts();
    }
    
    function loadAccounts() {
        accountModel.clear();
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
        
        // Select default account
        selectDefaultAccount();
    }
    
    function selectDefaultAccount() {
        const defaultId = Accounts.getDefaultAccountId();
        if (defaultId >= 0) {
            for (let i = 0; i < accountModel.count; i++) {
                const item = accountModel.get(i);
                if (item.id === defaultId) {
                    accountCombo.currentIndex = i;
                    selectedAccountId = item.id;
                    selectedAccountName = item.name;
                    accountChanged(item.id, item.name);
                    break;
                }
            }
        } else if (accountModel.count > 0) {
            // If no default, select first account
            const first = accountModel.get(0);
            accountCombo.currentIndex = 0;
            selectedAccountId = first.id;
            selectedAccountName = first.name;
            Accounts.setDefaultAccount(first.id);
            accountChanged(first.id, first.name);
        }
    }
    
    function refreshAccounts() {
        loadAccounts();
    }
}
