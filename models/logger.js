.pragma library

/**
 * Logger.js - Centralized Logging Architecture
 * Provides log level management, category tagging, PII sanitization, and output control.
 */

var LogLevel = {
    DEBUG: 0,
    INFO: 1,
    WARN: 2,
    ERROR: 3,
    NONE: 4
};

// Default log level: WARN in production/default, DEBUG during development
var currentLogLevel = LogLevel.WARN;

/**
 * Sets global log level.
 * @param {number} level - LogLevel enum value
 */
function setLogLevel(level) {
    if (typeof level === "number" && level >= LogLevel.DEBUG && level <= LogLevel.NONE) {
        currentLogLevel = level;
    }
}

/**
 * Gets current log level.
 * @returns {number}
 */
function getLogLevel() {
    return currentLogLevel;
}

/**
 * Mask potential PII (like email addresses) in log messages.
 * @param {string} text
 * @returns {string}
 */
function sanitizePII(text) {
    if (typeof text !== "string") return text;
    // Mask emails: user@domain.com -> u***@domain.com
    return text.replace(/([a-zA-Z0-9._%+-]+)@([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})/g, function(match, user, domain) {
        if (user.length <= 2) return "**@" + domain;
        return user.charAt(0) + "***@" + domain;
    });
}

/**
 * Log DEBUG level message
 * @param {string} category
 * @param {string} message
 * @param {any} [extra]
 */
function debug(category, message, extra) {
    if (currentLogLevel <= LogLevel.DEBUG) {
        var formatted = "[" + category + "] " + sanitizePII(message);
        if (extra !== undefined) {
            console.debug(formatted, extra);
        } else {
            console.debug(formatted);
        }
    }
}

/**
 * Log INFO level message
 * @param {string} category
 * @param {string} message
 * @param {any} [extra]
 */
function info(category, message, extra) {
    if (currentLogLevel <= LogLevel.INFO) {
        var formatted = "[" + category + "] " + sanitizePII(message);
        if (extra !== undefined) {
            console.log(formatted, extra);
        } else {
            console.log(formatted);
        }
    }
}

/**
 * Log WARN level message
 * @param {string} category
 * @param {string} message
 * @param {any} [extra]
 */
function warn(category, message, extra) {
    if (currentLogLevel <= LogLevel.WARN) {
        var formatted = "[" + category + "] " + sanitizePII(message);
        if (extra !== undefined) {
            console.warn(formatted, extra);
        } else {
            console.warn(formatted);
        }
    }
}

/**
 * Log ERROR level message
 * @param {string} category
 * @param {string} message
 * @param {any} [extra]
 */
function error(category, message, extra) {
    if (currentLogLevel <= LogLevel.ERROR) {
        var formatted = "[" + category + "] " + sanitizePII(message);
        if (extra !== undefined) {
            console.error(formatted, extra);
        } else {
            console.error(formatted);
        }
    }
}
