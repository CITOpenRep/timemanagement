import QtQuick 2.7
import QtQuick.Controls 2.2
import "../../models/accounts.js" as Accounts

ComboBox {
    id: instanceCombo
    flat: true
    editable: true
    width: parent.width
    height: parent.height
    anchors.centerIn: parent.centerIn
    textRole: "name"

    background: Rectangle {
        color: "transparent"
        radius: units.gu(0.6)
        border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#d3d1d1" : "#999"
    }

    contentItem: Text {
        text: instanceCombo.displayText
        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        anchors.verticalCenter: parent.verticalCenter
        leftPadding: units.gu(2)
    }

    delegate: ItemDelegate {
        width: instanceCombo.width
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

    property int selectedInstanceId: 0
    property int deferredAccountId: -1
    property bool shouldDeferSelection: false
    property bool suppressSignal: false

    signal accountSelected(int id, string name)

    ListModel {
        id: internalInstanceModel
    }
    model: internalInstanceModel

    function loadAccounts() {
        internalInstanceModel.clear();
        const accounts = Accounts.getAccountsList();

        for (let i = 0; i < accounts.length; i++) {
            // If restrictToLocalOnly is true, only show local account (id === 0)
            if (restrictToLocalOnly && accounts[i].id !== 0) {
                continue;
            }

            internalInstanceModel.append({
                id: accounts[i].id,
                name: accounts[i].name,
                database: accounts[i].database,
                link: accounts[i].link,
                username: accounts[i].username,
                is_default: accounts[i].is_default || 0
            });
        }

        // Handle deferred selection
        if (shouldDeferSelection && deferredAccountId > -1) {
            shouldDeferSelection = false;
            //  console.log('The Id specified is a Defered one , So moving on');
            Qt.callLater(() => {
                selectAccountById(deferredAccountId);
                shouldDeferSelection = false;
                deferredAccountId = -1;
            });
        } else {
            // Auto-select the default account if no deferred selection
            Qt.callLater(() => {
                selectDefaultAccount();
            });
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
            selectedInstanceId = -1;
            editText = "Select an account";
        }
    }

    function selectDefaultAccount() {
       // console.log("[AccountSelector] selectDefaultAccount called");

        // First try to find the default account in the model
        for (let i = 0; i < internalInstanceModel.count; i++) {
            const item = internalInstanceModel.get(i);
            if (item.is_default === 1) {
                console.log("[AccountSelector] Found default account:", item.name);
                suppressSignal = true;
                currentIndex = i;
                editText = item.name;
                selectedInstanceId = item.id;
                Qt.callLater(() => suppressSignal = false);
                accountSelected(item.id, item.name);
                return;
            }
        }

        // If no default found in model, try to get default ID from database
        const defaultId = Accounts.getDefaultAccountId();
        if (defaultId > 0) {
            console.log("[AccountSelector] Found default account ID from DB:", defaultId);
            selectAccountById(defaultId);
            return;
        }

        // If no default account found, select first account
       // console.log("[AccountSelector] No default account found, selecting first account");
        selectFirstAccount();
    }

    function selectAccountById(accountId) {
        //console.log("[AccountSelector] selectAccountById:", accountId, "modelCount:", internalInstanceModel.count);
        if (internalInstanceModel.count === 0) {
            shouldDeferSelection = true;
            deferredAccountId = accountId;
            return;
        }

        for (let i = 0; i < internalInstanceModel.count; i++) {
            const item = internalInstanceModel.get(i);
            if (item.id === accountId) {
                //console.log("[AccountSelector] Matched account:", item.name);
                suppressSignal = true;
                currentIndex = i;
                editText = item.name;
                selectedInstanceId = item.id;
                //console.log("Account selected (programmatically):", item.name);
                Qt.callLater(() => suppressSignal = false);  // ✅ Re-enable after event loop
                if (selectedInstanceId !== item.id) {
                    accountSelected(item.id, item.name);
                }
                return;
            }
        }

        console.warn("⚠️ Account ID not found:", accountId);
    }

    function refreshAndSelectDefault() {
       // console.log("[AccountSelector] refreshAndSelectDefault called");
        loadAccounts();
    // loadAccounts will automatically call selectDefaultAccount
    }

    Component.onCompleted: {
        loadAccounts();
        // The loadAccounts function now handles default account selection
        // No need to call selectFirstAccount here anymore
    }

    onActivated: {
        //console.log("⚡ [AccountSelector] onActivated index =", currentIndex);
        if (suppressSignal)
            return;
        if (currentIndex >= 0) {
            const selected = model.get(currentIndex);
            selectedInstanceId = selected.id;
            accountSelected(selected.id, selected.name);
        }
    }

    onAccepted: {
        if (suppressSignal)
            return;
        const idx = find(editText);
        if (idx !== -1) {
            const selected = model.get(idx);
            selectedInstanceId = selected.id;
            accountSelected(selected.id, selected.name);
        }
    }
}
