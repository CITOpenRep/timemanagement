import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/features/settings/components"

MainView {
    id: testRoot
    width: units.gu(50)
    height: units.gu(70)

    Rectangle {
        id: dummyHeader
        width: parent.width
        height: units.gu(6)
        color: LomiriColors.orange
    }

    SettingsPageLayout {
        id: testLayout
        headerItem: dummyHeader

        Label {
            id: innerLabel
            text: "Settings Content Item"
        }
    }

    TestCase {
        name: "SettingsPageLayoutTests"
        when: windowShown

        function test_initialStructure() {
            verify(testLayout !== null);
            compare(testLayout.headerItem, dummyHeader);
            compare(testLayout.anchors.top, dummyHeader.bottom);
        }

        function test_contentChildrenHosting() {
            verify(innerLabel !== null);
            compare(innerLabel.text, "Settings Content Item");
            verify(innerLabel.parent !== null);
        }

        function test_nullHeaderFallback() {
            testLayout.headerItem = null;
            compare(testLayout.headerItem, null);
            compare(testLayout.anchors.top, testRoot.top);

            testLayout.headerItem = dummyHeader;
            compare(testLayout.anchors.top, dummyHeader.bottom);
        }
    }
}
