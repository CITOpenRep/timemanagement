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

            var actionComp = Qt.createComponent("", Qt.resolvedUrl("."));
            // Verify trailingActionBar is configured
            verify(testHeader.trailingActionBar !== null);
        }
    }
}
