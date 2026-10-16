import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/features/settings/components"

MainView {
    id: testRoot
    width: units.gu(40)
    height: units.gu(30)

    SettingsListItem {
        id: testItem
        width: testRoot.width
    }

    SignalSpy {
        id: clickedSpy
        target: testItem
        signalName: "clicked"
    }

    TestCase {
        name: "SettingsListItemTests"
        when: windowShown

        function init() {
            testItem.text = "";
            testItem.iconName = "";
            testItem.iconColor = "#666";
            testItem.showProgression = true;
            testItem.showDivider = true;
            testItem.active = false;
            testItem.collapsed = false;
            clickedSpy.clear();
        }

        function cleanup() {
            clickedSpy.clear();
        }

        function test_initialProperties() {
            compare(testItem.text, "");
            compare(testItem.iconName, "");
            compare(testItem.showProgression, true);
            compare(testItem.showDivider, true);
            compare(testItem.active, false);
            compare(testItem.collapsed, false);
            compare(testItem.height, units.gu(7));
            compare(clickedSpy.count, 0);
        }

        function test_propertyAssignments() {
            testItem.text = "Connected Accounts";
            testItem.iconName = "account-multiple";
            testItem.iconColor = "#0078d4";
            testItem.active = true;

            compare(testItem.text, "Connected Accounts");
            compare(testItem.iconName, "account-multiple");
            compare(testItem.iconColor, "#0078d4");
            compare(testItem.active, true);
        }

        function test_collapsedMode() {
            testItem.collapsed = true;
            compare(testItem.collapsed, true);

            testItem.collapsed = false;
            compare(testItem.collapsed, false);
        }

        function test_showProgressionAndDivider() {
            testItem.showProgression = false;
            testItem.showDivider = false;

            compare(testItem.showProgression, false);
            compare(testItem.showDivider, false);
        }

        function test_clickedSignalEmission() {
            compare(clickedSpy.count, 0);
            mouseClick(testItem);
            compare(clickedSpy.count, 1);
        }
    }
}
