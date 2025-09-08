/*
 * BackendBridge.qml
 *
 * A lightweight, non-visual QML component that provides a bridge
 * between QML and Python using pyotherside.
 *
 * Responsibilities:
 *  - Import Python modules at runtime
 *  - Expose a simple `call()` function to invoke Python functions
 *  - Relay messages/events from Python back into QML
 *  - Normalize messages so QML always gets single event objects
 *
 * Usage:
 *   BackendBridge {
 *       id: backend
 *       onMessageReceived: function(evt) {
 *           console.log("Event:", evt.event, "Payload:", evt.payload)
 *       }
 *   }
 *
 *   // later in QML
 *   backend.call("example.speak", ["Hello"], function(ret) {
 *       console.log("Python returned:", ret)
 *   })
 */

import QtQuick 2.7
import io.thp.pyotherside 1.4

Item {
    id: bridge

    // --- Configuration ---
    // Path where Python modules live. Default points to ../../src/
    property url pythonImportPath: Qt.resolvedUrl("../../src/")

    // True once the Python module is imported and ready
    property bool ready: false

    property string module: "backend"

    // --- Signals ---
    // Emitted when a JSON-like object (dict) is sent from Python
    signal messageReceived(var data)

    // Emitted when Python code throws an error
    signal pythonError(string traceback)

    // --- Public API ---
    /**
     * Call a Python function.
     * @param functionName: string, full Python function name (e.g. "example.speak")
     * @param args: array of arguments to pass
     * @param callback: optional function to receive the return value
     */
    function call(functionName, args, callback) {
        if (!ready) {
            console.warn("BackendBridge not ready yet");
            return;
        }
        _py.call(functionName, args || [], function (ret) {
            if (callback)
                callback(ret);
        });
    }

    // --- Internal Python integration ---
    Python {
        id: _py

        // Called whenever Python uses pyotherside.send(...)
        onReceived: function (data) {
            // Normalize: if Python sends a list of objects, emit each separately.
            if (Array.isArray(data)) {
                for (var i = 0; i < data.length; i++) {
                    bridge.messageReceived(data[i]);
                }
            } else {
                bridge.messageReceived(data);
            }
        }

        // Forward Python errors to QML
        onError: function (traceback) {
            bridge.pythonError(traceback);
        }

        // Initialization: add import path and import the Python module
        Component.onCompleted: {
            addImportPath(bridge.pythonImportPath);
            importModule(module, function () {
                bridge.ready = true;
                console.log("BackendBridge ready: Python module loaded");
            });
        }
    }
}
