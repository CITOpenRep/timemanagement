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
            var bridgeModule = null;
            var win = root.mockWindow;
            var doc = root.mockDocument;

            // Load and instantiate the bridge using Function constructor with injected window & document
            var bridgeCode = `
                var messageHandlers = {};
                var pendingReplies = {};
                var replyCounter = 0;
                var msgSeq = 0;

                var qtBridge = {
                    addMessageHandler: function (msgId, handler) {
                        if (typeof msgId !== 'string' || typeof handler !== 'function') return;
                        messageHandlers[msgId] = handler;
                    },
                    sendMessage: function (type, payload) {
                        var message = { type: type, payload: payload || {} };
                        var encoded = encodeURIComponent(JSON.stringify(message));
                        var MAX_LEN = 1000;
                        var seq = ++msgSeq;
                        if (encoded.length <= MAX_LEN) {
                            document.title = 'qtevent:' + type + ':' + encoded + ':' + seq;
                        } else {
                            var totalChunks = Math.ceil(encoded.length / MAX_LEN);
                            for (var i = 0; i < totalChunks; i++) {
                                var chunk = encoded.substring(i * MAX_LEN, (i + 1) * MAX_LEN);
                                document.title = 'qteventchunk:' + seq + ':' + i + ':' + totalChunks + ':' + chunk;
                            }
                        }
                    },
                    processMessage: function (msgId, payload) {
                        if (!messageHandlers[msgId]) return;
                        var msg = { payload: payload || {}, reply: function() {} };
                        messageHandlers[msgId](msg);
                    },
                    processMessageWithReply: function (msgId, payload, callId) {
                        if (!messageHandlers[msgId]) {
                            this.sendReply(callId, null, 'NO_HANDLER', 'No handler registered for: ' + msgId);
                            return;
                        }
                        var self = this;
                        var msg = {
                            payload: payload || {},
                            reply: function (data) { self.sendReply(callId, data); }
                        };
                        messageHandlers[msgId](msg);
                    },
                    sendReply: function (callId, data, errorCode, errorMessage) {
                        var reply = { success: !errorCode, data: data };
                        if (errorCode) {
                            reply.error = { code: errorCode, message: errorMessage || 'Unknown error' };
                        }
                        var encoded = encodeURIComponent(JSON.stringify(reply));
                        window.location.hash = '#qtreply:' + callId + ':' + encoded;
                    },
                    getHandlers: function () { return Object.keys(messageHandlers); },
                    clearHandlers: function () { messageHandlers = {}; }
                };

                window.qtBridge = qtBridge;
                window.oxide = {
                    addMessageHandler: qtBridge.addMessageHandler.bind(qtBridge),
                    sendMessage: qtBridge.sendMessage.bind(qtBridge)
                };
            `;

            var factory = new Function("window", "document", bridgeCode);
            factory(win, doc);
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
