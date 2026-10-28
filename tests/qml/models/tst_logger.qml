import QtQuick 2.7
import QtTest 1.0
import "../../../models/logger.js" as Logger

Item {
    width: 200
    height: 200

    TestCase {
        name: "LoggerTests"
        when: windowShown

        function initTestCase() {
            compare(Logger.getLogLevel(), Logger.LogLevel.WARN);
        }

        function init() {
            Logger.setLogLevel(Logger.LogLevel.WARN);
        }

        function cleanup() {
            Logger.setLogLevel(Logger.LogLevel.WARN);
        }

        function test_logLevelEnumValues() {
            verify(Logger.LogLevel !== undefined);
            compare(Logger.LogLevel.DEBUG, 0);
            compare(Logger.LogLevel.INFO, 1);
            compare(Logger.LogLevel.WARN, 2);
            compare(Logger.LogLevel.ERROR, 3);
            compare(Logger.LogLevel.NONE, 4);
        }

        function test_setLogLevelValid() {
            Logger.setLogLevel(Logger.LogLevel.DEBUG);
            compare(Logger.getLogLevel(), Logger.LogLevel.DEBUG);

            Logger.setLogLevel(Logger.LogLevel.INFO);
            compare(Logger.getLogLevel(), Logger.LogLevel.INFO);

            Logger.setLogLevel(Logger.LogLevel.ERROR);
            compare(Logger.getLogLevel(), Logger.LogLevel.ERROR);

            Logger.setLogLevel(Logger.LogLevel.NONE);
            compare(Logger.getLogLevel(), Logger.LogLevel.NONE);
        }

        function test_setLogLevelInvalidIgnoresChange() {
            Logger.setLogLevel(Logger.LogLevel.INFO);
            compare(Logger.getLogLevel(), Logger.LogLevel.INFO);

            // Out-of-bounds numbers
            Logger.setLogLevel(-1);
            compare(Logger.getLogLevel(), Logger.LogLevel.INFO);

            Logger.setLogLevel(5);
            compare(Logger.getLogLevel(), Logger.LogLevel.INFO);

            Logger.setLogLevel(100);
            compare(Logger.getLogLevel(), Logger.LogLevel.INFO);

            // Non-number types
            Logger.setLogLevel("DEBUG");
            compare(Logger.getLogLevel(), Logger.LogLevel.INFO);

            Logger.setLogLevel(null);
            compare(Logger.getLogLevel(), Logger.LogLevel.INFO);

            Logger.setLogLevel(undefined);
            compare(Logger.getLogLevel(), Logger.LogLevel.INFO);

            Logger.setLogLevel({});
            compare(Logger.getLogLevel(), Logger.LogLevel.INFO);
        }

        function test_sanitizePIINonStringPassThrough() {
            compare(Logger.sanitizePII(null), null);
            compare(Logger.sanitizePII(undefined), undefined);
            compare(Logger.sanitizePII(12345), 12345);
            compare(Logger.sanitizePII(true), true);
        }

        function test_sanitizePIINoEmail() {
            var plainText = "Task synchronization completed successfully with 42 records.";
            compare(Logger.sanitizePII(plainText), plainText);
        }

        function test_sanitizePIIStandardEmail() {
            var input = "User email is john.doe@example.com for account.";
            var expected = "User email is j***@example.com for account.";
            compare(Logger.sanitizePII(input), expected);
        }

        function test_sanitizePIIShortUsernameEmail() {
            // Username with 2 or fewer characters should mask as **@domain
            var input = "Contact us at me@domain.org or ab@test.co.";
            var expected = "Contact us at **@domain.org or **@test.co.";
            compare(Logger.sanitizePII(input), expected);

            var singleChar = "a@sample.com";
            compare(Logger.sanitizePII(singleChar), "**@sample.com");
        }

        function test_sanitizePIIMultipleEmails() {
            var input = "Assigned from lead@corp.com to analyst@service.org.";
            var expected = "Assigned from l***@corp.com to a***@service.org.";
            compare(Logger.sanitizePII(input), expected);
        }

        function test_loggingExecutionAtAllLevels() {
            // Enable DEBUG to exercise all log branches
            Logger.setLogLevel(Logger.LogLevel.DEBUG);

            // Should execute without errors
            Logger.debug("TestCategory", "Debug message with confidential info user@example.com");
            Logger.debug("TestCategory", "Debug with payload", { id: 101, status: "ok" });

            Logger.info("TestCategory", "Info message with secret@domain.com");
            Logger.info("TestCategory", "Info with payload", [1, 2, 3]);

            Logger.warn("TestCategory", "Warning message with warn@alert.com");
            Logger.warn("TestCategory", "Warning with payload", "details");

            Logger.error("TestCategory", "Error message with admin@system.org");
            Logger.error("TestCategory", "Error with payload", 500);

            // Filter out all logs with NONE
            Logger.setLogLevel(Logger.LogLevel.NONE);
            Logger.debug("TestCategory", "Should be silenced");
            Logger.info("TestCategory", "Should be silenced");
            Logger.warn("TestCategory", "Should be silenced");
            Logger.error("TestCategory", "Should be silenced");

            verify(true);
        }
    }
}
