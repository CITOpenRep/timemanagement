// TimerService.js
// A global singleton timer service for Ubuntu Touch apps (QML)

.pragma library

var timerRunning = false;
var startTime = 0;
var intervalId = null;

function start() {
    if (!timerRunning) {
        startTime = Date.now();
        timerRunning = true;
    }
}

function stop() {
    if (timerRunning) {
        var elaspedtime=getElapsedTime();
        timerRunning = false;
        startTime = 0;
        return elaspedtime;
    }
    return "00:00:00";
}

function reset() {
    timerRunning = false;
    startTime = 0;
}

function getElapsedTime() {
    if (!startTime) return "00:00:00";
    var elapsedMs = Date.now() - startTime;
    var totalSeconds = Math.floor(elapsedMs / 1000);
    var hours = Math.floor(totalSeconds / 3600);
    var minutes = Math.floor((totalSeconds % 3600) / 60);
    var seconds = totalSeconds % 60;

    return (
        String(hours).padStart(2, "0") + ":" +
        String(minutes).padStart(2, "0") + ":" +
        String(seconds).padStart(2, "0")
    );
}

function isRunning() {
    return timerRunning;
}

function getStartTime() {
    return startTime;
}
