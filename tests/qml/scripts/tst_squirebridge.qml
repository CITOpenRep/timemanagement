import QtQuick 2.7
import QtTest 1.0

Item {
    id: root
    width: 200
    height: 200

    property var mockWindow: null
    property var mockDocument: null

    TestCase {
        name: "SquireBridgeTests"
        when: windowShown

        function init() {
            root.mockDocument = {
                title: ""
            };
            root.mockWindow = {
                location: { hash: "", pathname: "/editor", search: "" },
                history: {
                    replaceState: function(state, title, url) {
                        root.mockWindow.location.pathname = url;
                    }
                }
            };
        }

        function createBridge() {
            var win = root.mockWindow;
            var doc = root.mockDocument;

            var xhr = new XMLHttpRequest();
            xhr.open("GET", Qt.resolvedUrl("../../../qml/components/richtext/js/squire-qtwebengine-bridge.js"), false);
            xhr.send();
            var bridgeCode = xhr.responseText;

            var factory = new Function("window", "document", "setTimeout", bridgeCode);
            factory(win, doc, function(cb, delay) {});
            return win.qtBridge;
        }

        function test_handlerRegistration() {
            var bridge = createBridge();
            compare(bridge.getHandlers().length, 0);

            bridge.addMessageHandler("contentChanged", function(msg) {});
            bridge.addMessageHandler("formatUpdate", function(msg) {});
            compare(bridge.getHandlers().length, 2);
            verify(bridge.getHandlers().indexOf("contentChanged") !== -1);
            verify(bridge.getHandlers().indexOf("formatUpdate") !== -1);

            // Invalid arguments should be ignored
            bridge.addMessageHandler(123, function() {});
            bridge.addMessageHandler("invalid", "not-a-func");
            compare(bridge.getHandlers().length, 2);

            bridge.clearHandlers();
            compare(bridge.getHandlers().length, 0);
        }

        function test_sendMessage_singleChunk() {
            var bridge = createBridge();
            bridge.sendMessage("ready", { initialized: true });

            verify(root.mockDocument.title.startsWith("qtevent:ready:"));
            var parts = root.mockDocument.title.split(":");
            compare(parts[0], "qtevent");
            compare(parts[1], "ready");
            var decoded = JSON.parse(decodeURIComponent(parts[2]));
            compare(decoded.type, "ready");
            compare(decoded.payload.initialized, true);
        }

        function test_sendMessage_chunked() {
            var bridge = createBridge();
            var longText = "";
            for (var i = 0; i < 300; i++) {
                longText += "abcdefghij"; // 3000 chars
            }

            bridge.sendMessage("largeData", { text: longText });
            verify(root.mockDocument.title.startsWith("qteventchunk:"));
        }

        function test_processMessage() {
            var bridge = createBridge();
            var receivedPayload = null;

            bridge.addMessageHandler("setContent", function(msg) {
                receivedPayload = msg.payload;
            });

            bridge.processMessage("setContent", { html: "<p>Hello</p>" });
            verify(receivedPayload !== null);
            compare(receivedPayload.html, "<p>Hello</p>");

            // Calling unregistered handler should not throw
            bridge.processMessage("unregistered", {});
        }

        function test_processMessageWithReply_success() {
            var bridge = createBridge();

            bridge.addMessageHandler("getWordCount", function(msg) {
                msg.reply({ count: 42 });
            });

            bridge.processMessageWithReply("getWordCount", {}, "call_123");

            verify(root.mockWindow.location.hash.startsWith("#qtreply:call_123:"));
            var encoded = root.mockWindow.location.hash.replace("#qtreply:call_123:", "");
            var reply = JSON.parse(decodeURIComponent(encoded));
            verify(reply.success);
            compare(reply.data.count, 42);
        }

        function test_processMessageWithReply_noHandler() {
            var bridge = createBridge();
            bridge.processMessageWithReply("missingFunc", {}, "call_999");

            verify(root.mockWindow.location.hash.startsWith("#qtreply:call_999:"));
            var encoded = root.mockWindow.location.hash.replace("#qtreply:call_999:", "");
            var reply = JSON.parse(decodeURIComponent(encoded));
            compare(reply.success, false);
            compare(reply.error.code, "NO_HANDLER");
        }

        function test_oxideCompatibilityAlias() {
            createBridge();
            verify(root.mockWindow.oxide !== undefined);
            verify(typeof root.mockWindow.oxide.addMessageHandler === "function");
            verify(typeof root.mockWindow.oxide.sendMessage === "function");
        }
    }
}
