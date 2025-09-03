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
from logging import Handler, Formatter
from datetime import datetime
import json

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


def setup_logger(name="odoo_sync", log_file="sync.log", level=logging.INFO):
    """
    Sets up a system-wide logger that logs to both console and file.

    Args:
        name (str): Logger name.
        log_file (str): Path to the log file.
        level (int): Logging level.

    Returns:
        logging.Logger: Configured logger instance.
    """
    logger = logging.getLogger(name)
    logger.setLevel(level)

    if not logger.handlers:  # Avoid duplicate handlers

        # File handler (May not work on device because of the issues on permission
        # fh = logging.FileHandler(log_file)
        # fh.setLevel(level)

        # Console handler
        ch = logging.StreamHandler()
        ch.setLevel(level)

        # Formatter
        formatter = logging.Formatter(
            "%(asctime)s [%(levelname)s] %(name)s (%(filename)s:%(lineno)d) - %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S",
        )
        # fh.setFormatter(formatter)
        ch.setFormatter(formatter)

        # Add handlers
        # logger.addHandler(fh)
        logger.addHandler(ch)


        json_handler = JsonMemoryHandler()
        json_handler.setLevel(level)
        json_handler.setFormatter(formatter)  # Use the same formatter if you want consistent timestamps
        logger.addHandler(json_handler)
        logger.json_handler = json_handler

    return logger
