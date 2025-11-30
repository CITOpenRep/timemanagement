#!/bin/bash
# Setup script to enable daemon autostart on device boot
# Run this ONCE on the device after app installation

set -e

echo "Setting up TimeManagement daemon autostart..."

# Method 1: Enable user lingering (makes user services start at boot)
echo "Enabling user session lingering..."
if command -v loginctl &> /dev/null; then
    loginctl enable-linger phablet 2>/dev/null || echo "Note: loginctl enable-linger may need root"
fi

# Method 2: Create XDG autostart entry (starts when user session begins)
echo "Creating XDG autostart entry..."
AUTOSTART_DIR="$HOME/.config/autostart"
mkdir -p "$AUTOSTART_DIR"

cat > "$AUTOSTART_DIR/ubtms-daemon.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=TimeManagement Daemon
Comment=Background sync daemon for TimeManagement app
Exec=/bin/bash -c "sleep 10 && /home/phablet/.local/share/ubtms/watchdog.sh"
Terminal=false
Hidden=false
X-GNOME-Autostart-enabled=true
X-Ubuntu-Touch=true
EOF

echo "XDG autostart entry created at $AUTOSTART_DIR/ubtms-daemon.desktop"

# Method 3: Create upstart user session job (Ubuntu Touch native)
echo "Creating upstart session job..."
UPSTART_DIR="$HOME/.config/upstart"
mkdir -p "$UPSTART_DIR"

cat > "$UPSTART_DIR/ubtms-daemon.conf" << 'EOF'
# TimeManagement background sync daemon
# Starts automatically when user session begins

description "TimeManagement Background Sync Daemon"
author "CIT-Services"

# Start when the user session is ready
start on started unity8

# Restart if it crashes
respawn
respawn limit 5 60

# Environment setup
env DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/32011/bus

# Pre-start: ensure DBus is available
pre-start script
    # Wait for DBus session to be ready
    for i in $(seq 1 30); do
        if [ -S "/run/user/32011/bus" ]; then
            break
        fi
        sleep 1
    done
end script

# Main daemon execution
exec /bin/bash -c 'cd /opt/click.ubuntu.com/ubtms/current && exec python3 src/daemon.py >> /home/phablet/daemon.log 2>&1'

# Log respawn events
post-stop script
    echo "$(date): Daemon stopped, will respawn" >> /home/phablet/daemon.log
end script
EOF

echo "Upstart job created at $UPSTART_DIR/ubtms-daemon.conf"

# Reload systemd user daemon if available
if command -v systemctl &> /dev/null; then
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
    export XDG_RUNTIME_DIR="/run/user/$(id -u)"
    systemctl --user daemon-reload 2>/dev/null || true
fi

echo ""
echo "============================================"
echo "Setup complete!"
echo ""
echo "The daemon will now start automatically:"
echo "  1. When you unlock the device after boot"
echo "  2. Via upstart when Unity8 session starts"
echo "  3. Via systemd watchdog timer every 2 minutes"
echo ""
echo "To verify, reboot device and check:"
echo "  adb shell 'pgrep -af daemon.py'"
echo "============================================"
