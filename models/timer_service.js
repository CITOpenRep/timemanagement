// timer_service.js
// A global singleton timer service for Ubuntu Touch Timesheet App
// MIT License

.pragma library

.import "../models/timesheet.js" as Model

var timerRunning = false;
var startTime = 0; // Epoch milliseconds
var activeTimesheetId = null;
var activeSheetname = ""
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
        var durationHours = getElapsedHours();
        Model.updateTimesheetWithDuration(activeTimesheetId, durationHours);
        startTime = 0;
        activeTimesheetId = null;
        previouslyTrackedHours = 0;
        timerRunning = false;
    }

    // Fetch previous tracked hours
    previouslyTrackedHours = Model.getTimesheetUnitAmount(timesheetId); // new function in timesheet.js

    startTime = Date.now();
    activeTimesheetId = timesheetId;
    timerRunning = true;
    activeSheetname=Model.getTimesheetNameById(activeTimesheetId)

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
        var durationHours = getElapsedHours();

        if (activeTimesheetId !== null) {
            Model.updateTimesheetWithDuration(activeTimesheetId, durationHours);
            console.log("Timer stopped for timesheet ID:", activeTimesheetId, " Duration(hours):", durationHours);
        }

        // Reset state
        timerRunning = false;
        startTime = 0;
        activeTimesheetId = null;
        previouslyTrackedHours = 0;
        activeSheetname=""
        return elapsedTime;
    }
    return "00:00:00";
}

/**
 * Reset the timer without updating the database.
 */
function reset() {
    timerRunning = false;
    startTime = 0;
    activeTimesheetId = null;
    console.log("🔄 Timer reset without saving.");
}

/**
 * Get the elapsed tracked time in HH:MM:SS format.
 */
function getElapsedTime() {
    if (!startTime) {
        // Convert previouslyTrackedHours to HH:MM:SS
        return Utils.convertFloatToTime(previouslyTrackedHours);
    }

    var elapsedMs = Date.now() - startTime;
    var totalSeconds = Math.floor(elapsedMs / 1000);
    var hours = Math.floor(totalSeconds / 3600);
    var minutes = Math.floor((totalSeconds % 3600) / 60);
    var seconds = totalSeconds % 60;

    // Convert previouslyTrackedHours to seconds for adding
    var prevTotalSeconds = Math.floor(previouslyTrackedHours * 3600);
    var combinedSeconds = totalSeconds + prevTotalSeconds;

    var dispHours = Math.floor(combinedSeconds / 3600);
    var dispMinutes = Math.floor((combinedSeconds % 3600) / 60);
    var dispSeconds = combinedSeconds % 60;

    return (
                String(dispHours).padStart(2, "0") + ":" +
                String(dispMinutes).padStart(2, "0") + ":" +
                String(dispSeconds).padStart(2, "0")
                );
}


/**
 * Get the elapsed tracked time in decimal hours, rounded to 2 decimals.
 */
function getElapsedHours() {
    if (!startTime) return previouslyTrackedHours;

    var elapsedMs = Date.now() - startTime;
    var totalHours = elapsedMs / (1000 * 60 * 60);
    var combinedHours = previouslyTrackedHours + totalHours;
    return parseFloat(combinedHours.toFixed(2)); // e.g., 1.25 for 1 hr 15 min
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

function getActiveTimesheetName() {
    return activeSheetname;
}
