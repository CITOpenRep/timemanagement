import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components/system"

Item {
    id: testRoot
    width: units.gu(40)
    height: units.gu(40)

    BackendBridge {
        id: testBridge
    }

    SignalSpy {
        id: messageReceivedSpy
        target: testBridge
        signalName: "messageReceived"
    }

    SignalSpy {
        id: pythonErrorSpy
        target: testBridge
        signalName: "pythonError"
    }

    TestCase {
        name: "BackendBridgeTests"
        when: windowShown

        function init() {
            messageReceivedSpy.clear();
            pythonErrorSpy.clear();
        }

        function cleanup() {
            messageReceivedSpy.clear();
            pythonErrorSpy.clear();
        }

        function test_initialProperties() {
            compare(testBridge.module, "backend");
            verify(testBridge.pythonImportPath !== "");
        }

        function test_messageReceivedSingleObject() {
            var evt = {
                event: "sync_progress",
                payload: 75
            };

            testBridge.messageReceived(evt);

            compare(messageReceivedSpy.count, 1);
            var received = messageReceivedSpy.signalArguments[0][0];
            compare(received.event, "sync_progress");
            compare(received.payload, 75);
        }

        function test_messageReceivedSequentialEvents() {
            testBridge.messageReceived({ event: "event_1", payload: "A" });
            testBridge.messageReceived({ event: "event_2", payload: "B" });
            testBridge.messageReceived({ event: "event_3", payload: "C" });

            compare(messageReceivedSpy.count, 3);
            compare(messageReceivedSpy.signalArguments[0][0].payload, "A");
            compare(messageReceivedSpy.signalArguments[1][0].payload, "B");
            compare(messageReceivedSpy.signalArguments[2][0].payload, "C");
        }

        function test_pythonErrorSignalEmission() {
            var sampleTrace = "Traceback (most recent call last):\n  File 'test.py', line 10, in <module>\nValueError: invalid input";

            testBridge.pythonError(sampleTrace);

            compare(pythonErrorSpy.count, 1);
            compare(pythonErrorSpy.signalArguments[0][0], sampleTrace);
        }

        function test_callMethodWhenNotReady() {
            // When bridge is not ready, call() exits without crashing or throwing
            var callbackInvoked = false;
            testBridge.call("nonexistent_module.some_fn", [], function (res) {
                callbackInvoked = true;
            });

            // Callback should not be invoked synchronously when not ready
            compare(callbackInvoked, false);
        }
    }
}
