import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components/feedback"

Item {
    width: units.gu(40)
    height: units.gu(70)

    InfoBar {
        id: testInfoBar
    }

    SignalSpy {
        id: openedSpy
        target: testInfoBar
        signalName: "opened"
    }

    SignalSpy {
        id: closedSpy
        target: testInfoBar
        signalName: "closed"
    }

    TestCase {
        name: "InfoBarTests"
        when: windowShown

        function init() {
            testInfoBar.close();
            testInfoBar.setText("");
            openedSpy.clear();
            closedSpy.clear();
        }

        function test_initialProperties() {
            compare(testInfoBar.visible, false);
            compare(testInfoBar.text, "");
            compare(testInfoBar.autoCloseEnabled, true);
            compare(testInfoBar.autoCloseMs, 10000);
        }

        function test_openDisplaysMessageAndEmitsSignal() {
            testInfoBar.open("Saved successfully", 3000);
            compare(testInfoBar.visible, true);
            compare(testInfoBar.text, "Saved successfully");
            compare(openedSpy.count, 1);
        }

        function test_closeHidesBannerAndEmitsSignal() {
            testInfoBar.open("Temporary alert", 5000);
            compare(testInfoBar.visible, true);

            testInfoBar.close();
            compare(testInfoBar.visible, false);
            compare(closedSpy.count, 1);
        }

        function test_setTextUpdatesMessage() {
            testInfoBar.setText("Notice message");
            compare(testInfoBar.text, "Notice message");
        }

        function test_autoCloseTimerFires() {
            testInfoBar.open("Quick alert", 100);
            compare(testInfoBar.visible, true);
            tryCompare(testInfoBar, "visible", false, 500);
            compare(closedSpy.count, 1);
        }
    }
}
