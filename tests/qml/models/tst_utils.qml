import QtQuick 2.7
import QtTest 1.0
import "../../../models/utils.js" as Utils

Item {
    width: 200
    height: 200

    TestCase {
        name: "UtilsTests"
        when: windowShown

        // --- URL Validation and Cleaning ---
        function test_validateAndCleanOdooURL_invalid() {
            var emptyRes = Utils.validateAndCleanOdooURL("");
            compare(emptyRes.isValid, false);
            compare(emptyRes.cleanedUrl, "");

            var nullRes = Utils.validateAndCleanOdooURL(null);
            compare(nullRes.isValid, false);

            var undefinedRes = Utils.validateAndCleanOdooURL(undefined);
            compare(undefinedRes.isValid, false);

            var protoOnly = Utils.validateAndCleanOdooURL("https://");
            compare(protoOnly.isValid, false);

            var spaces = Utils.validateAndCleanOdooURL("not a valid url");
            compare(spaces.isValid, false);
        }

        function test_validateAndCleanOdooURL_valid() {
            var standard = Utils.validateAndCleanOdooURL("example.odoo.com");
            compare(standard.isValid, true);
            compare(standard.cleanedUrl, "https://example.odoo.com");

            var withHttp = Utils.validateAndCleanOdooURL("http://myerp.local/");
            compare(withHttp.isValid, true);
            compare(withHttp.cleanedUrl, "http://myerp.local");

            var localhostWithPort = Utils.validateAndCleanOdooURL("localhost:8069///");
            compare(localhostWithPort.isValid, true);
            compare(localhostWithPort.cleanedUrl, "https://localhost:8069");

            var ipAddr = Utils.validateAndCleanOdooURL("http://192.168.1.50:8069");
            compare(ipAddr.isValid, true);
            compare(ipAddr.cleanedUrl, "http://192.168.1.50:8069");
        }

        // --- Text Manipulation Utilities ---
        function test_stripHtmlTags() {
            compare(Utils.stripHtmlTags(""), "");
            compare(Utils.stripHtmlTags(null), "");
            compare(Utils.stripHtmlTags(undefined), "");
            compare(Utils.stripHtmlTags("Plain text content"), "Plain text content");
            compare(Utils.stripHtmlTags("<p>Paragraph with <b>bold</b> and <i>italic</i></p>"), "Paragraph with bold and italic");
            compare(Utils.stripHtmlTags("<div class=\"main\"><a href=\"#\">Link</a></div>"), "Link");
        }

        function test_cleanText() {
            compare(Utils.cleanText(null), "");
            compare(Utils.cleanText(undefined), "");
            compare(Utils.cleanText(12345), "");
            compare(Utils.cleanText("   Hello   World   "), "Hello World");
            compare(Utils.cleanText("Special&nbsp;space&nbsp;test"), "Special space test");
            // Control characters stripping
            var withControlChars = "Clean\u0000ed\u0007 text\u200B";
            compare(Utils.cleanText(withControlChars), "Cleaned text");
        }

        function test_truncateText() {
            compare(Utils.truncateText(null, 10), "");
            compare(Utils.truncateText("Short", 10), "Short");
            compare(Utils.truncateText("Exact length", 12), "Exact length");
            compare(Utils.truncateText("This is a much longer description text", 10), "This is a...");
            // HTML within truncated text
            var htmlInput = "<p>Description with <b>formatting</b> that needs truncation</p>";
            var truncated = Utils.truncateText(htmlInput, 15);
            verify(truncated.indexOf("<") === -1);
            verify(truncated.indexOf("...") !== -1);
        }

        function test_getColorFromOdooIndex() {
            compare(Utils.getColorFromOdooIndex(0), "transparent");
            compare(Utils.getColorFromOdooIndex(1), "#EB6E67");
            compare(Utils.getColorFromOdooIndex(2), "#F39C5A");
            compare(Utils.getColorFromOdooIndex(11), "#9B6CC3");
            // Modulo wrapping
            compare(Utils.getColorFromOdooIndex(12), "transparent");
            compare(Utils.getColorFromOdooIndex(13), "#EB6E67");
        }

        // --- Time and Duration Conversions ---
        function test_convertHHMMtoDecimalHours() {
            // Number pass-through
            compare(Utils.convertHHMMtoDecimalHours(3.5), 3.5);

            // Invalid or empty inputs
            compare(Utils.convertHHMMtoDecimalHours(""), 0);
            compare(Utils.convertHHMMtoDecimalHours(null), 0);
            compare(Utils.convertHHMMtoDecimalHours("invalid"), 0);

            // Numeric string without colon
            compare(Utils.convertHHMMtoDecimalHours("4.25"), 4.25);

            // HH:MM format
            compare(Utils.convertHHMMtoDecimalHours("1:30"), 1.5);
            compare(Utils.convertHHMMtoDecimalHours("0:45"), 0.75);
            compare(Utils.convertHHMMtoDecimalHours("2:15"), 2.25);
            compare(Utils.convertHHMMtoDecimalHours("0:00"), 0);

            // HH:MM:SS format
            compare(Utils.convertHHMMtoDecimalHours("1:30:00"), 1.5);
            compare(Utils.convertHHMMtoDecimalHours("0:30:36"), 0.51);

            // Malformed colon strings
            compare(Utils.convertHHMMtoDecimalHours("foo:bar"), 0);
            compare(Utils.convertHHMMtoDecimalHours("1:2:3:4"), 0);
        }

        function test_convertDecimalHoursToHHMM() {
            compare(Utils.convertDecimalHoursToHHMM(0), "0:00");
            compare(Utils.convertDecimalHoursToHHMM(1.5), "1:30");
            compare(Utils.convertDecimalHoursToHHMM(2.25), "2:15");
            compare(Utils.convertDecimalHoursToHHMM(11.8333), "11:50");
            compare(Utils.convertDecimalHoursToHHMM(0.0833), "0:05");
        }

        function test_convertDurationToFloat() {
            compare(Utils.convertDurationToFloat(2.5), 2.5);
            compare(Utils.convertDurationToFloat(""), 0);
            compare(Utils.convertDurationToFloat(null), 0);
            compare(Utils.convertDurationToFloat("2:30"), 2.5);
            compare(Utils.convertDurationToFloat("1:15"), 1.25);
            compare(Utils.convertDurationToFloat("1:30:36"), 1.51);
        }

        // --- Date Formatting and Conversions ---
        function test_formatDate() {
            var date = new Date(2026, 8, 25); // Month is 0-indexed: 8 = September
            compare(Utils.formatDate(date), "9/25/2026");

            var newYears = new Date(2027, 0, 1);
            compare(Utils.formatDate(newYears), "1/1/2027");
        }

        function test_convertToISODate() {
            compare(Utils.convertToISODate(""), "");
            compare(Utils.convertToISODate(null), "");
            compare(Utils.convertToISODate("9/24/2025"), "2025-09-24");
            compare(Utils.convertToISODate("12/5/2026"), "2026-12-05");
            compare(Utils.convertToISODate("01/02/2025"), "2025-01-02");
            compare(Utils.convertToISODate("invalid-format"), "invalid-format");
        }

        function test_extractDate() {
            compare(Utils.extractDate("2025-06-23T13:53:42.834Z"), "2025-06-23");
            compare(Utils.extractDate("2026-12-31T00:00:00.000"), "2026-12-31");
        }

        function test_getTodayAndTomorrowFormat() {
            var today = Utils.getToday();
            compare(typeof today, "string");
            compare(today.length, 10);
            verify(today.match(/^\d{4}-\d{2}-\d{2}$/) !== null);

            var tomorrow = Utils.getTomorrow();
            compare(typeof tomorrow, "string");
            compare(tomorrow.length, 10);
            verify(tomorrow.match(/^\d{4}-\d{2}-\d{2}$/) !== null);

            var diffDays = (new Date(tomorrow) - new Date(today)) / (1000 * 60 * 60 * 24);
            compare(Math.round(diffDays), 1);
        }

        function test_getYesterday() {
            var yesterday = Utils.getYesterday();
            compare(typeof yesterday, "string");
            verify(yesterday.indexOf("T") !== -1);
            verify(new Date(yesterday).getTime() < Date.now());
        }

        function test_getNextWeekRange() {
            var range = Utils.getNextWeekRange();
            verify(range.start !== undefined);
            verify(range.end !== undefined);
            compare(range.start.length, 10);
            compare(range.end.length, 10);

            var startParts = range.start.split("-");
            var localStartDate = new Date(parseInt(startParts[0]), parseInt(startParts[1]) - 1, parseInt(startParts[2]));
            var endParts = range.end.split("-");
            var localEndDate = new Date(parseInt(endParts[0]), parseInt(endParts[1]) - 1, parseInt(endParts[2]));

            verify(localStartDate <= localEndDate);
            compare(localStartDate.getDay(), 1);
        }

        function test_getNextWeekSameDay() {
            var nextWeek = Utils.getNextWeekSameDay("2026-09-10");
            compare(nextWeek, "2026-09-17");

            var leapYear = Utils.getNextWeekSameDay("2024-02-25");
            compare(leapYear, "2024-03-03");
        }

        function test_getNextMonthRange() {
            var range = Utils.getNextMonthRange();
            verify(range.start !== undefined);
            verify(range.end !== undefined);
            compare(range.start.slice(8, 10), "01");
            verify(new Date(range.start) <= new Date(range.end));
        }

        function test_getNextMonthSameDay() {
            var nextMonth = Utils.getNextMonthSameDay("2026-01-15");
            compare(nextMonth, "2026-02-15");

            // January 31 -> February end clamping
            var clamped = Utils.getNextMonthSameDay("2026-01-31");
            compare(clamped, "2026-02-28");

            // December to January year rollover
            var yearRoll = Utils.getNextMonthSameDay("2026-12-10");
            compare(yearRoll, "2027-01-10");
        }

        function test_getFormattedTimestampUTC() {
            var timestamp = Utils.getFormattedTimestampUTC();
            compare(typeof timestamp, "string");
            verify(timestamp.match(/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/) !== null);
        }

        function test_getTimeStatusInText() {
            compare(Utils.getTimeStatusInText(null), "N/A");
            compare(Utils.getTimeStatusInText(""), "N/A");
            compare(Utils.getTimeStatusInText("not-a-date"), "Invalid");

            // Today
            var todayStr = new Date().toISOString();
            compare(Utils.getTimeStatusInText(todayStr), "Due today");

            // Tomorrow
            var tomorrow = new Date();
            tomorrow.setDate(tomorrow.getDate() + 1);
            compare(Utils.getTimeStatusInText(tomorrow.toISOString()), "1 day remaining");

            // Future 5 days
            var future = new Date();
            future.setDate(future.getDate() + 5);
            compare(Utils.getTimeStatusInText(future.toISOString()), "5 days remaining");

            // Past 3 days overdue
            var past = new Date();
            past.setDate(past.getDate() - 3);
            compare(Utils.getTimeStatusInText(past.toISOString()), "3 days overdue");
        }
    }
}
