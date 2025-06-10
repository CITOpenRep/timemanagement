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

    property int selectedInstanceId: 0
    property int deferredAccountId: -1
    property bool shouldDeferSelection: false

    signal accountSelected(int id, string name)

    ListModel {
        id: internalInstanceModel
    }
    model: internalInstanceModel

    function loadAccounts() {
        internalInstanceModel.clear();
        const accounts = Accounts.getAccountsList();

        for (let i = 0; i < accounts.length; i++) {
            internalInstanceModel.append({
                id: accounts[i].id,
                name: accounts[i].name,
                database: accounts[i].database,
                link: accounts[i].link,
                username: accounts[i].username
            });
        }

        // Handle deferred selection
        if (shouldDeferSelection && deferredAccountId > -1) {
            Qt.callLater(() => {
                selectAccountById(deferredAccountId);
                shouldDeferSelection = false;
                deferredAccountId = -1;
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

    function selectAccountById(accountId) {
        if (internalInstanceModel.count === 0) {
            shouldDeferSelection = true;
            deferredAccountId = accountId;
            return;
        }

        for (let i = 0; i < internalInstanceModel.count; i++) {
            const item = internalInstanceModel.get(i);
            if (item.id === accountId) {
                currentIndex = i;
                editText = item.name;
                selectedInstanceId = item.id;
                console.log("✅ Account selected:", item.name);
                if (!shouldDeferSelection)
                    accountSelected(item.id, item.name);
                return;
            }
        }

        console.warn("⚠️ Account ID not found:", accountId);
    }

    Component.onCompleted: {
        loadAccounts();
        if (!shouldDeferSelection) {
            selectFirstAccount();
        }
    }

    onActivated: {
        if (currentIndex >= 0) {
            const selected = model.get(currentIndex);
            selectedInstanceId = selected.id;
            if (!shouldDeferSelection)
                accountSelected(selected.id, selected.name);
        }
    }

    onAccepted: {
        const idx = find(editText);
        if (idx !== -1) {
            const selected = model.get(idx);
            selectedInstanceId = selected.id;
            if (!shouldDeferSelection)
                accountSelected(selected.id, selected.name);
        }
    }
}
