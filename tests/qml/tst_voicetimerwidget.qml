import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components/system"

Item {
    id: testRoot
    width: units.gu(50)
    height: units.gu(40)

    VoiceTimerWidget {
        id: testWidget
    }

    SignalSpy {
        id: stopClickedSpy
        target: testWidget
        signalName: "stopClicked"
    }

    TestCase {
        name: "VoiceTimerWidgetTests"
        when: windowShown

        function init() {
            testWidget.isListening = false;
            testWidget.isProcessing = false;
            testWidget.partialText = "";
            testWidget.voiceStatus = "";
            stopClickedSpy.clear();
        }

        function cleanup() {
            testWidget.isListening = false;
            testWidget.isProcessing = false;
            stopClickedSpy.clear();
        }

        function test_initialProperties() {
            compare(testWidget.isListening, false);
            compare(testWidget.isProcessing, false);
            compare(testWidget.visible, false);
            compare(testWidget.partialText, "");
            compare(testWidget.voiceStatus, "");
        }

        function test_listeningStateMakesWidgetVisible() {
            testWidget.isListening = true;
            testWidget.isProcessing = false;

            compare(testWidget.visible, true);
        }

        function test_processingStateMakesWidgetVisible() {
            testWidget.isListening = false;
            testWidget.isProcessing = true;

            compare(testWidget.visible, true);
        }

        function test_bothActiveMakesWidgetVisible() {
            testWidget.isListening = true;
            testWidget.isProcessing = true;

            compare(testWidget.visible, true);
        }

        function test_idleStateHidesWidget() {
            testWidget.isListening = true;
            compare(testWidget.visible, true);

            testWidget.isListening = false;
            testWidget.isProcessing = false;
            compare(testWidget.visible, false);
        }

        function test_voiceStatusAndPartialTextContent() {
            testWidget.voiceStatus = "Listening";
            testWidget.partialText = "Create project task";

            compare(testWidget.voiceStatus, "Listening");
            compare(testWidget.partialText, "Create project task");
        }

        function test_stopClickedSignalEmission() {
            testWidget.stopClicked();

            compare(stopClickedSpy.count, 1);
        }

        function test_dimensionsAndStyling() {
            compare(testWidget.color, "#2d2d2d");
            verify(testWidget.width > 0);
            verify(testWidget.height > 0);
            verify(testWidget.radius > 0);
        }
    }
}
