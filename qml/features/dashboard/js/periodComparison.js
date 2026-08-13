.pragma library

// Helper to format Date as "yyyy-MM-dd"
function fmt(d) {
    if (!d) return "";
    var yyyy = d.getFullYear();
    var mm = String(d.getMonth() + 1);
    if (mm.length < 2) mm = '0' + mm;
    var dd = String(d.getDate());
    if (dd.length < 2) dd = '0' + dd;
    return yyyy + "-" + mm + "-" + dd;
}

// Parses "yyyy-MM-dd" to a local Date object at midnight
function parseDate(dateString) {
    if (!dateString) return null;
    var parts = dateString.split('-');
    if (parts.length !== 3) return null;
    return new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]));
}

// Get the difference in days between two dates
function getDaysDifference(d1, d2) {
    var diffTime = Math.abs(d2 - d1);
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
}

function calculatePreviousPeriod(startDateStr, endDateStr, presetId) {
    if (!startDateStr || !endDateStr || presetId === -1) return { start: "", end: "" };

    var start = parseDate(startDateStr);
    var end = parseDate(endDateStr);
    if (!start || !end) return { start: "", end: "" };

    var prevStart = new Date(start);
    var prevEnd = new Date(end);

    switch (presetId) {
        case 0: // Today -> Yesterday
            prevStart.setDate(start.getDate() - 1);
            prevEnd = new Date(prevStart);
            break;
        case 1: // This Week -> Previous Week
        case 2: // Last 7 Days -> Previous 7 Days
            prevStart.setDate(start.getDate() - 7);
            prevEnd.setDate(end.getDate() - 7);
            break;
        case 3: // This Month -> Previous Month
            prevStart = new Date(start.getFullYear(), start.getMonth() - 1, 1);
            prevEnd = new Date(start.getFullYear(), start.getMonth(), 0);
            break;
        case 4: // Last 30 Days -> Previous 30 Days
            prevStart.setDate(start.getDate() - 30);
            prevEnd.setDate(end.getDate() - 30);
            break;
        case 5: // This Quarter -> Previous Quarter
            prevStart = new Date(start.getFullYear(), start.getMonth() - 3, 1);
            prevEnd = new Date(start.getFullYear(), start.getMonth(), 0);
            break;
        case 6: // This Year -> Previous Year
            prevStart = new Date(start.getFullYear() - 1, 0, 1);
            prevEnd = new Date(start.getFullYear() - 1, 11, 31);
            break;
        case 7: // Custom Range -> Shift by the span length
        default:
            var days = getDaysDifference(start, end) + 1;
            prevStart.setDate(start.getDate() - days);
            prevEnd.setDate(end.getDate() - days);
            break;
    }

    return {
        start: fmt(prevStart),
        end: fmt(prevEnd)
    };
}

function calculateSamePeriodLastYear(startDateStr, endDateStr, presetId) {
    if (!startDateStr || !endDateStr || presetId === -1 || presetId === 6) {
        return { start: "", end: "" };
    }

    var start = parseDate(startDateStr);
    var end = parseDate(endDateStr);
    if (!start || !end) return { start: "", end: "" };

    var yoyStart = new Date(start);
    var yoyEnd = new Date(end);

    yoyStart.setFullYear(start.getFullYear() - 1);
    yoyEnd.setFullYear(end.getFullYear() - 1);

    // Handle leap years gracefully (Feb 29 -> Feb 28)
    if (start.getMonth() === 1 && start.getDate() === 29) {
        yoyStart.setDate(28);
    }
    if (end.getMonth() === 1 && end.getDate() === 29) {
        yoyEnd.setDate(28);
    }
    
    // For "This Month" or "This Quarter" ensure we get the last day of the month
    if (presetId === 3 || presetId === 5) {
        // Use trick: day 0 of next month is the last day of current month
        yoyEnd = new Date(yoyEnd.getFullYear(), yoyEnd.getMonth() + 1, 0);
    }

    return {
        start: fmt(yoyStart),
        end: fmt(yoyEnd)
    };
}

function formatVariance(currentValue, previousValue) {
    currentValue = Number(currentValue) || 0;
    previousValue = Number(previousValue) || 0;

    if (previousValue === 0) {
        if (currentValue === 0) {
            return { percent: "— 0%", direction: "flat", color: "#888888" };
        }
        return { percent: "▲ 100%", direction: "up", color: "#388E3C" };
    }

    var variance = ((currentValue - previousValue) / previousValue) * 100;
    var absVariance = Math.abs(variance).toFixed(1);

    if (variance > 0) {
        return { percent: "▲ +" + absVariance + "%", direction: "up", color: "#388E3C" };
    } else if (variance < 0) {
        return { percent: "▼ -" + absVariance + "%", direction: "down", color: "#D32F2F" };
    } else {
        return { percent: "— 0%", direction: "flat", color: "#888888" };
    }
}
