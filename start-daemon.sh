#!/bin/bash
# Start the TimeManagement background daemon
# This script ensures proper environment setup and true daemonization

CLICK_PATH="/opt/click.ubuntu.com/ubtms/current"
DAEMON_PATH="$CLICK_PATH/src/daemon.py"
LOG_FILE="/home/phablet/daemon.log"
PID_FILE="/home/phablet/.daemon.pid"

echo "$(date): Starting daemon script" >> "$LOG_FILE"

# Check if daemon is already running
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        echo "$(date): Daemon already running with PID $OLD_PID" >> "$LOG_FILE"
        exit 0
    fi
fi

# Also check with pgrep
if pgrep -f "python3.*daemon.py" > /dev/null 2>&1; then
    echo "$(date): Daemon process found running" >> "$LOG_FILE"
    exit 0
fi

# Set up DBus address if not set
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    UID_NUM=$(id -u)
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$UID_NUM/bus"
fi

echo "$(date): DBus address: $DBUS_SESSION_BUS_ADDRESS" >> "$LOG_FILE"

# Change to click directory
cd "$CLICK_PATH"

# Double-fork daemonization pattern
# First fork - run in background
(
    # Second fork - detach from terminal completely
    cd "$CLICK_PATH"
    exec python3 "$DAEMON_PATH" >> "$LOG_FILE" 2>&1
) &

DAEMON_PID=$!
echo "$(date): Started daemon with PID $DAEMON_PID" >> "$LOG_FILE"
echo "$DAEMON_PID" > "$PID_FILE"

# Return immediately
exit 0
