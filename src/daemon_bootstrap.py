#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Daemon Bootstrap - Sets up systemd service and starts daemon.
"""

import sys
import os
import subprocess
from pathlib import Path

HOME = Path.home()
# Dynamically determine CLICK_PATH from this script's location or APP_DIR
CLICK_PATH = Path(os.environ.get("APP_DIR", Path(__file__).resolve().parent.parent))
DAEMON_PATH = CLICK_PATH / "src" / "daemon.py"
LOG_FILE = HOME / "daemon.log"


def log(message):
    """Log to daemon.log."""
    try:
        timestamp = subprocess.check_output(["date", "+%Y-%m-%d %H:%M:%S"]).decode().strip()
        with open(LOG_FILE, 'a') as f:
            f.write(f"{timestamp} [BOOTSTRAP] {message}\n")
    except:
        pass


def setup_systemd_service():
    """Create systemd user service for auto-restart."""
    systemd_dir = HOME / ".config" / "systemd" / "user"
    systemd_dir.mkdir(parents=True, exist_ok=True)
    
    # Ensure log directory exists
    log_dir = HOME / ".local" / "share" / "ubtms"
    log_dir.mkdir(parents=True, exist_ok=True)
    log_file = log_dir / "daemon.log"
    
    service_file = systemd_dir / "ubtms-daemon.service"
    service_content = f"""[Unit]
Description=TimeManagement Background Sync Daemon
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 {CLICK_PATH}/src/daemon.py
WorkingDirectory={CLICK_PATH}
Environment="DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/%U/bus"
Restart=always
RestartSec=10
TimeoutStopSec=15
KillMode=mixed
KillSignal=SIGTERM
StartLimitIntervalSec=300
StartLimitBurst=10
StandardOutput=append:{log_file}
StandardError=append:{log_file}

[Install]
WantedBy=graphical-session.target
"""
    service_file.write_text(service_content)
    
    # Enable via symlink
    wants_dir = systemd_dir / "graphical-session.target.wants"
    wants_dir.mkdir(parents=True, exist_ok=True)
    symlink = wants_dir / "ubtms-daemon.service"
    if symlink.exists() or symlink.is_symlink():
        symlink.unlink()
    symlink.symlink_to(service_file)
    
    log("Systemd service configured")
    
    # Try to activate systemd
    try:
        uid = os.getuid()
        env = os.environ.copy()
        env["DBUS_SESSION_BUS_ADDRESS"] = f"unix:path=/run/user/{uid}/bus"
        subprocess.run(["systemctl", "--user", "daemon-reload"], env=env, timeout=5, capture_output=True)
        log("Systemd reloaded")
    except Exception as e:
        log(f"Could not reload systemd: {e}")


def main():
    log("Bootstrap starting...")
    
    # Set up systemd service if not exists
    service_file = HOME / ".config" / "systemd" / "user" / "ubtms-daemon.service"
    if not service_file.exists():
        setup_systemd_service()
    
    # Run daemon
    log("Starting daemon...")
    os.chdir(CLICK_PATH)
    os.execv(sys.executable, [sys.executable, str(DAEMON_PATH)] + sys.argv[1:])


if __name__ == "__main__":
    main()
