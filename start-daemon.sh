#!/bin/bash
# Start the TimeManagement background daemon
# This script ensures proper environment setup and robust daemonization

CLICK_PATH="/opt/click.ubuntu.com/ubtms/current"
DAEMON_PATH="$CLICK_PATH/src/daemon.py"
LOG_FILE="/home/phablet/daemon.log"
PID_FILE="/home/phablet/.daemon.pid"
HEARTBEAT_FILE="/home/phablet/.daemon_heartbeat"
MAX_HEARTBEAT_AGE=120  # seconds

echo "$(date): Starting daemon script" >> "$LOG_FILE"

# Function to check if daemon is alive via heartbeat
check_daemon_health() {
    if [ -f "$HEARTBEAT_FILE" ]; then
        # Get heartbeat age
        HEARTBEAT_TIME=$(stat -c %Y "$HEARTBEAT_FILE" 2>/dev/null)
        CURRENT_TIME=$(date +%s)
        if [ -n "$HEARTBEAT_TIME" ]; then
            AGE=$((CURRENT_TIME - HEARTBEAT_TIME))
            if [ $AGE -lt $MAX_HEARTBEAT_AGE ]; then
                return 0  # Healthy
            else
                echo "$(date): Daemon heartbeat stale ($AGE seconds old)" >> "$LOG_FILE"
                return 1  # Unhealthy
            fi
        fi
    fi
    return 1  # No heartbeat file
}

# Check if daemon is already running and healthy
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        if check_daemon_health; then
            echo "$(date): Daemon already running and healthy with PID $OLD_PID" >> "$LOG_FILE"
            exit 0
        else
            echo "$(date): Daemon running but unhealthy, killing PID $OLD_PID" >> "$LOG_FILE"
            kill -9 "$OLD_PID" 2>/dev/null
            rm -f "$PID_FILE"
        fi
    else
        echo "$(date): Stale PID file found, cleaning up" >> "$LOG_FILE"
        rm -f "$PID_FILE"
    fi
fi

# Also check with pgrep
EXISTING_PID=$(pgrep -f "python3.*daemon.py" 2>/dev/null | head -1)
if [ -n "$EXISTING_PID" ]; then
    if check_daemon_health; then
        echo "$(date): Daemon process found running (PID $EXISTING_PID) and healthy" >> "$LOG_FILE"
        exit 0
    else
        echo "$(date): Daemon process unhealthy, killing PID $EXISTING_PID" >> "$LOG_FILE"
        kill -9 "$EXISTING_PID" 2>/dev/null
    fi
fi

# Set up DBus address if not set
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    UID_NUM=$(id -u)
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$UID_NUM/bus"
fi

echo "$(date): DBus address: $DBUS_SESSION_BUS_ADDRESS" >> "$LOG_FILE"

# Change to click directory
cd "$CLICK_PATH"

# Clean up old heartbeat file
rm -f "$HEARTBEAT_FILE"

# TRUE DAEMONIZATION using setsid to create new session
# This ensures the daemon survives:
# 1. App closing
# 2. USB disconnection
# 3. ADB session termination
# 4. Parent process termination

# Use setsid to create a new session (fully detached from terminal)
# Close stdin, stdout, stderr and redirect to log file
setsid python3 "$DAEMON_PATH" </dev/null >> "$LOG_FILE" 2>&1 &
DAEMON_PID=$!

# Give it a moment to start and write PID file
sleep 1

echo "$(date): Started daemon with setsid, launcher PID $DAEMON_PID" >> "$LOG_FILE"

# Verify daemon started by checking for python process
ACTUAL_PID=$(pgrep -f "python3.*daemon.py" 2>/dev/null | head -1)
if [ -n "$ACTUAL_PID" ]; then
    echo "$(date): Daemon confirmed running with PID $ACTUAL_PID" >> "$LOG_FILE"
else
    echo "$(date): WARNING - Daemon may not have started properly" >> "$LOG_FILE"
fi

# Return immediately
exit 0
