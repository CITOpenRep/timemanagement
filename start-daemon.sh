#!/bin/bash
# Start the TimeManagement background daemon

CLICK_PATH="/opt/click.ubuntu.com/ubtms/current"
LOG_FILE="/home/phablet/daemon.log"
PID_FILE="/home/phablet/.daemon.pid"

echo "$(date): Starting daemon" >> "$LOG_FILE"

# Check if already running
if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "$(date): Daemon already running" >> "$LOG_FILE"
    exit 0
fi

# Set up DBus if needed
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
fi

cd "$CLICK_PATH"

# Start daemon (systemd will manage restart)
setsid python3 src/daemon_bootstrap.py </dev/null >> "$LOG_FILE" 2>&1 &

sleep 2
if [ -f "$PID_FILE" ]; then
    echo "$(date): Daemon started with PID $(cat $PID_FILE)" >> "$LOG_FILE"
else
    echo "$(date): Warning - PID file not created" >> "$LOG_FILE"
fi
