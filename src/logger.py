# -*- coding: utf-8 -*-
# MIT License
#
# Copyright (c) 2025 CIT-Services
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# logger.py
import logging
import sys
from logging import Handler, Formatter
from logging.handlers import RotatingFileHandler
from datetime import datetime
from pathlib import Path
import json
import os


class FlushingStreamHandler(logging.StreamHandler):
    """StreamHandler that flushes after every emit for immediate log visibility."""
    def emit(self, record):
        super().emit(record)
        self.flush()


class FlushingFileHandler(RotatingFileHandler):
    """RotatingFileHandler that flushes after every emit for immediate log visibility."""
    def emit(self, record):
        super().emit(record)
        self.flush()


class JsonMemoryHandler(Handler):
    def __init__(self):
        super().__init__()
        # Set a formatter with both message and time format
        self.formatter = Formatter(fmt="%(message)s", datefmt="%Y-%m-%d %H:%M:%S")
        self.logs = []

    def emit(self, record):
        timestamp = self.formatter.formatTime(record, self.formatter.datefmt)
        self.logs.append({
            "timestamp": timestamp,
            "level": record.levelname,
            "name": record.name,
            "filename": record.filename,
            "lineno": record.lineno,
            "message": record.getMessage(),
        })

    def get_json_string(self):
        return json.dumps(self.logs, indent=2)


def get_log_file_path():
    """Get the path for the daemon log file in a writable location."""
    # Use ~/.local/share/ubtms/ which is always writable
    log_dir = Path.home() / ".local" / "share" / "ubtms"
    log_dir.mkdir(parents=True, exist_ok=True)
    return str(log_dir / "daemon.log")


def _is_running_under_systemd():
    """Detect if the process is running under systemd.
    
    When systemd manages the process, it redirects stdout/stderr to the log file
    via StandardOutput/StandardError directives. In that case, we should NOT add
    our own file handler (to avoid duplicate log lines), and the stderr handler
    is sufficient since systemd captures it.
    """
    # INVOCATION_ID is set by systemd for all services
    if os.environ.get('INVOCATION_ID'):
        return True
    # JOURNAL_STREAM is set when stdout/stderr are connected to the journal
    if os.environ.get('JOURNAL_STREAM'):
        return True
    return False


def setup_logger(name="odoo_sync", log_file=None, level=logging.INFO):
    """
    Sets up a system-wide logger that logs to both console and file.
    
    When running under systemd, skips the file handler since systemd
    already captures stderr to the log file (avoids duplicate log lines).

    Args:
        name (str): Logger name.
        log_file (str): Path to the log file. If None, uses default location.
        level (int): Logging level.

    Returns:
        logging.Logger: Configured logger instance.
    """
    logger = logging.getLogger(name)
    logger.setLevel(level)
    
    # Prevent propagation to root logger to avoid any extra duplicate output
    logger.propagate = False

    if not logger.handlers:  # Avoid duplicate handlers

        # Formatter
        formatter = logging.Formatter(
            "%(asctime)s [%(levelname)s] %(name)s (%(filename)s:%(lineno)d) - %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S",
        )

        under_systemd = _is_running_under_systemd()
        file_logging_ok = False
        
        # File handler with rotation (5 files x 1MB each)
        # Skip when running under systemd - it already redirects stderr to the log file
        if not under_systemd:
            try:
                if log_file is None:
                    log_file = get_log_file_path()
                
                # Ensure parent directory exists
                log_path = Path(log_file)
                log_path.parent.mkdir(parents=True, exist_ok=True)
                
                fh = FlushingFileHandler(
                    log_file,
                    maxBytes=1024*1024,  # 1MB per file
                    backupCount=5,       # Keep 5 backup files
                    encoding='utf-8'
                )
                fh.setLevel(level)
                fh.setFormatter(formatter)
                logger.addHandler(fh)
                file_logging_ok = True
            except Exception as e:
                # Print to stderr immediately so it's visible even without file logging
                print(f"[LOGGER] CRITICAL: Could not set up file logging to {log_file}: {e}", file=sys.stderr)
                sys.stderr.flush()
        else:
            file_logging_ok = True  # systemd handles file logging

        # Console/stderr handler with immediate flushing
        # Under systemd, this is the primary output (captured to log file by systemd)
        ch = FlushingStreamHandler(sys.stderr)
        ch.setLevel(level)
        ch.setFormatter(formatter)
        logger.addHandler(ch)

        # JSON memory handler for in-app log viewing
        json_handler = JsonMemoryHandler()
        json_handler.setLevel(level)
        json_handler.setFormatter(formatter)
        logger.addHandler(json_handler)
        logger.json_handler = json_handler
        
        # Log startup confirmation
        if under_systemd:
            logger.info(f"[LOGGER] Initialized (systemd mode, stderr only). Log file managed by systemd.")
        elif file_logging_ok:
            logger.info(f"[LOGGER] Initialized successfully. Log file: {log_file}")
        else:
            logger.warning(f"[LOGGER] Initialized without file logging (console only)")

    return logger

