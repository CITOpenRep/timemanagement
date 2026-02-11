/**
 * QtWebEngine Bridge for Squire.js
 * Bridges Squire.js to QtWebEngine's communication mechanisms.
 * Adapted from Dekko email client for timemanagement project.
 */

(function (window) {
    'use strict';

    // Message handler registry
    var messageHandlers = {};

    // Callback tracking for replies
    var pendingReplies = {};
    var replyCounter = 0;

    /**
     * QtWebEngine Bridge Object
     */
    var qtBridge = {
        /**
         * Register a message handler
         */
        addMessageHandler: function (msgId, handler) {
            if (typeof msgId !== 'string') {
                console.error('[QtBridge] Invalid msgId:', msgId);
                return;
            }
            if (typeof handler !== 'function') {
                console.error('[QtBridge] Invalid handler for msgId:', msgId);
                return;
            }

            messageHandlers[msgId] = handler;
            console.log('[QtBridge] Registered handler:', msgId);
        },

        /**
         * Send a message to QML
         */
        sendMessage: function (type, payload) {
            try {
                var message = {
                    type: type,
                    payload: payload || {}
                };

                var encoded = encodeURIComponent(JSON.stringify(message));
                window.location.hash = '#qtevent:' + type + ':' + encoded;

                setTimeout(function () {
                    if (window.location.hash.indexOf('#qtevent:' + type) === 0) {
                        window.location.hash = '';
                    }
                }, 10);
            } catch (e) {
                console.error('[QtBridge] sendMessage failed:', e);
            }
        },

        /**
         * Process a message from QML (no reply expected)
         */
        processMessage: function (msgId, payload) {
            console.log('[QtBridge] processMessage called:', msgId, 'payload:', JSON.stringify(payload));
            if (!messageHandlers[msgId]) {
                console.warn('[QtBridge] No handler for message:', msgId);
                return;
            }

            try {
                var msg = {
                    payload: payload || {},
                    reply: function (data) {
                        console.warn('[QtBridge] Reply called on no-reply message:', msgId);
                    }
                };
                console.log('[QtBridge] Executing handler for:', msgId);
                messageHandlers[msgId](msg);
                console.log('[QtBridge] Handler executed successfully for:', msgId);
            } catch (e) {
                console.error('[QtBridge] Error processing message', msgId, ':', e);
            }
        },

        /**
         * Process a message from QML with reply capability
         */
        processMessageWithReply: function (msgId, payload, callId) {
            if (!messageHandlers[msgId]) {
                console.warn('[QtBridge] No handler for message:', msgId);
                this.sendReply(callId, null, 'NO_HANDLER', 'No handler registered for: ' + msgId);
                return;
            }

            try {
                var msg = {
                    payload: payload || {},
                    reply: function (data) {
                        qtBridge.sendReply(callId, data);
                    }
                };
                messageHandlers[msgId](msg);
            } catch (e) {
                console.error('[QtBridge] Error processing message', msgId, ':', e);
                this.sendReply(callId, null, 'HANDLER_ERROR', e.toString());
            }
        },

        /**
         * Send a reply back to QML
         */
        sendReply: function (callId, data, errorCode, errorMessage) {
            try {
                var reply = {
                    success: !errorCode,
                    data: data
                };

                if (errorCode) {
                    reply.error = {
                        code: errorCode,
                        message: errorMessage || 'Unknown error'
                    };
                }

                var encoded = encodeURIComponent(JSON.stringify(reply));
                window.location.hash = '#qtreply:' + callId + ':' + encoded;

                setTimeout(function () {
                    if (window.location.hash.indexOf('#qtreply:' + callId) === 0) {
                        window.location.hash = '';
                    }
                }, 10);
            } catch (e) {
                console.error('[QtBridge] sendReply failed:', e);
            }
        },

        getHandlers: function () {
            return Object.keys(messageHandlers);
        },

        clearHandlers: function () {
            messageHandlers = {};
            console.log('[QtBridge] All handlers cleared');
        }
    };

    // Export to global scope
    window.qtBridge = qtBridge;

    // Create Oxide compatibility alias
    // This allows existing code to use oxide.addMessageHandler() unchanged
    window.oxide = {
        addMessageHandler: qtBridge.addMessageHandler.bind(qtBridge),
        sendMessage: qtBridge.sendMessage.bind(qtBridge)
    };

    console.log('[QtBridge] Initialized successfully');
    console.log('[QtBridge] Oxide compatibility layer active');

})(window);
