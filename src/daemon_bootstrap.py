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


def get_service_target_path():
    """Get stable click path for systemd service across app updates."""
    current_symlink = Path("/opt/click.ubuntu.com/ubtms/current")
    if current_symlink.exists():
        return current_symlink
    return CLICK_PATH


def setup_systemd_service():
    """Create systemd user service for auto-restart."""
    systemd_dir = HOME / ".config" / "systemd" / "user"
    systemd_dir.mkdir(parents=True, exist_ok=True)
    
    # Ensure log directory exists
    log_dir = HOME / ".local" / "share" / "ubtms"
    log_dir.mkdir(parents=True, exist_ok=True)
    log_file = log_dir / "daemon.log"
    
    target_path = get_service_target_path()
    service_file = systemd_dir / "ubtms-daemon.service"
    service_content = f"""[Unit]
Description=TimeManagement Background Sync Daemon
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 {target_path}/src/daemon.py
WorkingDirectory={target_path}
Environment="DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/%U/bus"
Restart=always
RestartSec=10
TimeoutStopSec=15
KillMode=mixed
KillSignal=SIGTERM
StartLimitIntervalSec=300
StartLimitBurst=10
StandardOutput=journal
StandardError=journal

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
    
    # Set up or update systemd service if missing or pointing to outdated path
    target_path = get_service_target_path()
    service_file = HOME / ".config" / "systemd" / "user" / "ubtms-daemon.service"
    need_setup = True
    if service_file.exists():
        try:
            content = service_file.read_text()
            if f"WorkingDirectory={target_path}" in content:
                need_setup = False
        except Exception:
            need_setup = True

    if need_setup:
        setup_systemd_service()
    
    # Run daemon
    log("Starting daemon...")
    run_path = target_path if (target_path / "src" / "daemon.py").exists() else CLICK_PATH
    os.chdir(str(run_path))
    os.execv(sys.executable, [sys.executable, str(run_path / "src" / "daemon.py")] + sys.argv[1:])


if __name__ == "__main__":
    main()
