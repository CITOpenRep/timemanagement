// timer_service.js
// A global singleton timer service for Ubuntu Touch Timesheet App
// MIT License

.pragma library

.import "../models/timesheet.js" as Model
.import "../models/utils.js" as Utils

var timerRunning = false;
var startTime = 0; // Epoch milliseconds
var activeTimesheetId = null;
var activeSheetname = "";
var previouslyTrackedHours = 0;

/**
 * Start the timer for a specific timesheet.
 * If another timer is already running, it will automatically stop it,
 * update its unit_amount, and then start the new timer.
 *
 * @param {number} timesheetId - The ID of the timesheet to start tracking.
 */
function start(timesheetId) {
    if (timerRunning && activeTimesheetId !== null) {
        var durationHours = getElapsedDuration();
        console.log("Stopping previous timer before starting new one, durationHours:", durationHours);
        Model.updateTimesheetWithDuration(activeTimesheetId, durationHours);
        resetInternal();
    }

    // Fetch previous tracked hours in HH.MM format
    previouslyTrackedHours = Model.getTimesheetUnitAmount(timesheetId);

    startTime = Date.now();
    activeTimesheetId = timesheetId;
    timerRunning = true;
    activeSheetname = Model.getTimesheetNameById(activeTimesheetId);
    //Lets mark as done
    Model.markTimesheetAsDraftById(activeTimesheetId)

    console.log("Timer started for timesheet ID:", activeTimesheetId, "Previously tracked:", previouslyTrackedHours);
}

/**
 * Stop the currently running timer, calculate tracked duration,
 * update unit_amount, but keep status as 'draft' for later finalization.
 *
 * @returns {string} - The tracked time in HH:MM:SS format.
 */
function stop() {
    if (timerRunning) {
        var elapsedTime = getElapsedTime();
        var durationHours = getElapsedDuration();
        console.log("Stopping timer. durationHours:", durationHours);

        if (activeTimesheetId !== null) {
            Model.updateTimesheetWithDuration(activeTimesheetId, durationHours);
            console.log("Timer stopped for timesheet ID:", activeTimesheetId, " Duration(hours HH.MM):", durationHours);
        }

        resetInternal();
        return elapsedTime;
    }
    return "00:00:00";
}

/**
 * Reset the timer internal state without DB updates.
 */
function resetInternal() {
    timerRunning = false;
    startTime = 0;
    activeTimesheetId = null;
    previouslyTrackedHours = 0;
    activeSheetname = "";
}

/**
 * Reset the timer without updating the database.
 */
function reset() {
    resetInternal();
    console.log("Timer reset without saving.");
}

/**
 * Get the elapsed tracked time as HH:MM:SS or HH.MM string for UI display.
 * @param {string} format - "hhmm" for "HH.MM", "hhmmss" for "HH:MM:SS"
 */
function getElapsedTime(format = "hhmmss") {
    var totalSeconds = 0;

    if (startTime) {
        var elapsedMs = Date.now() - startTime;
        totalSeconds = Math.floor(elapsedMs / 1000);
    }

    var prevHours = Math.floor(previouslyTrackedHours);
    var prevMinutes = Math.round((previouslyTrackedHours - prevHours) * 60); // FIXED HERE
    var prevTotalSeconds = prevHours * 3600 + prevMinutes * 60;

    var combinedSeconds = totalSeconds + prevTotalSeconds;

    var hours = Math.floor(combinedSeconds / 3600);
    var minutes = Math.floor((combinedSeconds % 3600) / 60);
    var seconds = combinedSeconds % 60;

    if (format === "hhmm") {
        return hours + "." + String(minutes).padStart(2, "0");
    } else {
        return (
            String(hours).padStart(2, "0") + ":" +
            String(minutes).padStart(2, "0") + ":" +
            String(seconds).padStart(2, "0")
        );
    }
}


/**
 * Get the elapsed tracked time in HH.MM format for database saving,
 * preserving previously tracked fractional minutes correctly.
 *
 * Example:
 * - 20 minutes => "0:20"
 * - 1 hour 20 minutes => "1:20"
 */
function getElapsedDuration() {
    var totalSeconds = 0;

    if (startTime) {
        var elapsedMs = Date.now() - startTime;
        totalSeconds = Math.floor(elapsedMs / 1000);
    }

    var prevHours = Math.floor(previouslyTrackedHours);
    var prevMinutes = Math.round((previouslyTrackedHours - prevHours) * 60);
    var prevSeconds = prevHours * 3600 + prevMinutes * 60;

    var combinedSeconds = totalSeconds + prevSeconds;

    var hours = Math.floor(combinedSeconds / 3600);
    var minutes = Math.floor((combinedSeconds % 3600) / 60);

    // Return as "HH:MM" string for Model.updateTimesheetWithDuration
    return hours + ":" + String(minutes).padStart(2, "0");
}

/**
 * Return the current running state of the timer.
 */
function isRunning() {
    return timerRunning;
}

/**
 * Return the active timesheet ID if a timer is running.
 */
function getActiveTimesheetId() {
    return activeTimesheetId;
}

/**
 * Return the raw epoch start time.
 */
function getStartTime() {
    return startTime;
}

/**
 * Return the active timesheet name.
 */
function getActiveTimesheetName() {
    return activeSheetname;
}
