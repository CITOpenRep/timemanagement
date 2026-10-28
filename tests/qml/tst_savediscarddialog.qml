import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import "../../qml/components/dialogs"

MainView {
    id: testRoot
    width: units.gu(40)
    height: units.gu(70)

    SaveDiscardDialog {
        id: testDialog
    }

    SignalSpy {
        id: saveSpy
        target: testDialog
        signalName: "saveRequested"
    }

    SignalSpy {
        id: discardSpy
        target: testDialog
        signalName: "discardRequested"
    }

    SignalSpy {
        id: cancelSpy
        target: testDialog
        signalName: "cancelled"
    }

    Item {
        id: dummyPage
        objectName: "testDummyPage"
    }

    TestCase {
        name: "SaveDiscardDialogTests"
        when: windowShown

        function init() {
            testDialog.targetPage = null;
            saveSpy.clear();
            discardSpy.clear();
            cancelSpy.clear();
        }

        function cleanup() {
            testDialog.targetPage = null;
            saveSpy.clear();
            discardSpy.clear();
            cancelSpy.clear();
        }

        function test_initialProperties() {
            compare(testDialog.targetPage, null);
            compare(saveSpy.count, 0);
            compare(discardSpy.count, 0);
            compare(cancelSpy.count, 0);
        }

        function test_targetPageDirectAssignment() {
            testDialog.targetPage = dummyPage;
            compare(testDialog.targetPage, dummyPage);

            testDialog.targetPage = null;
            compare(testDialog.targetPage, null);
        }

        function test_openUpdatesTargetPage() {
            testDialog.open(dummyPage);
            compare(testDialog.targetPage, dummyPage);
        }

        function test_openWithoutPagePreservesExistingTargetPage() {
            testDialog.targetPage = dummyPage;
            testDialog.open();
            compare(testDialog.targetPage, dummyPage);
        }

        function test_saveRequestedSignalEmission() {
            compare(saveSpy.count, 0);
            testDialog.saveRequested();
            compare(saveSpy.count, 1);
            compare(discardSpy.count, 0);
            compare(cancelSpy.count, 0);
        }

        function test_discardRequestedSignalEmission() {
            compare(discardSpy.count, 0);
            testDialog.discardRequested();
            compare(discardSpy.count, 1);
            compare(saveSpy.count, 0);
            compare(cancelSpy.count, 0);
        }

        function test_cancelledSignalEmission() {
            compare(cancelSpy.count, 0);
            testDialog.cancelled();
            compare(cancelSpy.count, 1);
            compare(saveSpy.count, 0);
            compare(discardSpy.count, 0);
        }

        function test_multipleConsecutiveSignalEmissions() {
            testDialog.saveRequested();
            testDialog.saveRequested();
            compare(saveSpy.count, 2);

            testDialog.discardRequested();
            compare(discardSpy.count, 1);

            testDialog.cancelled();
            testDialog.cancelled();
            testDialog.cancelled();
            compare(cancelSpy.count, 3);
        }

        function test_openMethodExecution() {
            // Verify open() executes cleanly with and without arguments
            testDialog.open(dummyPage);
            compare(testDialog.targetPage, dummyPage);

            var secondPage = { name: "customMockPage" };
            testDialog.open(secondPage);
            compare(testDialog.targetPage.name, "customMockPage");
        }
    }
}
