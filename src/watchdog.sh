#!/bin/bash
# Watchdog script for UBTMS Background Sync Daemon
# This script checks if the daemon is running and restarts it if not
# Can be run via cron, systemd timer, or upstart

PID_FILE="$HOME/.daemon.pid"
HEARTBEAT_FILE="$HOME/.daemon_heartbeat"
LOG_FILE="$HOME/daemon.log"
DAEMON_PATH="/opt/click.ubuntu.com/ubtms/current/src/daemon.py"
MAX_HEARTBEAT_AGE=300  # 5 minutes

log_msg() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [WATCHDOG] $1" >> "$LOG_FILE"
}

# Wait for DBus session to be available (important after boot)
wait_for_dbus() {
    local uid=$(id -u)
    local bus_path="/run/user/$uid/bus"
    local max_wait=60
    local waited=0
    
    while [ ! -S "$bus_path" ] && [ $waited -lt $max_wait ]; do
        sleep 2
        waited=$((waited + 2))
    done
    
    if [ -S "$bus_path" ]; then
        export DBUS_SESSION_BUS_ADDRESS="unix:path=$bus_path"
        return 0
    else
        log_msg "DBus session not available after ${max_wait}s"
        return 1
    fi
}

# Check if daemon is healthy
check_daemon_health() {
    # Check if PID file exists
    if [ ! -f "$PID_FILE" ]; then
        log_msg "No PID file found"
        return 1
    fi
    
    PID=$(cat "$PID_FILE")
    
    # Check if process is running
    if ! kill -0 "$PID" 2>/dev/null; then
        log_msg "Process $PID not running"
        return 1
    fi
    
    # Check heartbeat age
    if [ -f "$HEARTBEAT_FILE" ]; then
        HEARTBEAT_TIME=$(stat -c %Y "$HEARTBEAT_FILE" 2>/dev/null || echo 0)
        CURRENT_TIME=$(date +%s)
        HEARTBEAT_AGE=$((CURRENT_TIME - HEARTBEAT_TIME))
        
        if [ $HEARTBEAT_AGE -gt $MAX_HEARTBEAT_AGE ]; then
            log_msg "Heartbeat stale ($HEARTBEAT_AGE seconds old)"
            return 1
        fi
    fi
    
    return 0
}

# Restart daemon
restart_daemon() {
    log_msg "Restarting daemon..."
    
    # Wait for DBus to be available
    if ! wait_for_dbus; then
        log_msg "Cannot start daemon - DBus not available"
        return 1
    fi
    
    # Kill any zombie processes
    pkill -9 -f "python3.*daemon.py" 2>/dev/null
    sleep 1
    
    # Clean up stale files
    rm -f "$PID_FILE" 2>/dev/null
    
    # Start daemon with setsid for proper daemonization
    cd /opt/click.ubuntu.com/ubtms/current
    setsid python3 "$DAEMON_PATH" </dev/null >> "$LOG_FILE" 2>&1 &
    
    sleep 3
    
    # Verify it started
    if [ -f "$PID_FILE" ]; then
        NEW_PID=$(cat "$PID_FILE")
        if kill -0 "$NEW_PID" 2>/dev/null; then
            log_msg "Daemon restarted with PID $NEW_PID"
            return 0
        fi
    fi
    
    log_msg "Failed to restart daemon"
    return 1
}

# Main logic
if ! check_daemon_health; then
    restart_daemon
else
    # Daemon is healthy - just touch heartbeat check timestamp
    touch "$HOME/.watchdog_last_check"
fi
