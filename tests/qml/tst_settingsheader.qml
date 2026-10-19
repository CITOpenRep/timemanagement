import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/features/settings/components"

MainView {
    id: testRoot
    width: units.gu(50)
    height: units.gu(70)

    Page {
        id: testPage
        anchors.fill: parent

        header: SettingsHeader {
            id: testHeader
            title: "Settings Overview"
        }
    }

    Page {
        id: testPageWithAction
        visible: false

        header: SettingsHeader {
            id: testHeaderWithAction
            title: "Header With Action"
            trailingActions: [
                Action {
                    id: saveAction
                    text: "Save"
                    iconName: "save"
                }
            ]
        }
    }

    TestCase {
        name: "SettingsHeaderTests"
        when: windowShown

        function test_initialProperties() {
            compare(testHeader.title, "Settings Overview");
            verify(testHeader.visible, true);
        }

        function test_titlePropertyUpdate() {
            testHeader.title = "Connected Accounts";
            compare(testHeader.title, "Connected Accounts");

            testHeader.title = "Voice Model Settings";
            compare(testHeader.title, "Voice Model Settings");
        }

        function test_trailingActionsBinding() {
            compare(testHeader.trailingActions.length, 0);
            verify(testHeader.trailingActionBar !== null);

            // Verify trailingActions binding to trailingActionBar.actions
            compare(testHeaderWithAction.trailingActions.length, 1);
            compare(testHeaderWithAction.trailingActionBar.actions.length, 1);
            compare(testHeaderWithAction.trailingActionBar.actions[0].text, "Save");
            compare(testHeaderWithAction.trailingActionBar.actions[0].iconName, "save");
        }
    }
}
