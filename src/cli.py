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

import os
import glob
from backend import sync


def find_settings_db(app_id):
    # Construct the base path
    home_dir = os.path.expanduser("~")
    db_path_pattern = os.path.join(
        home_dir,
        ".clickable",
        "home",
        ".local",
        "share",
        app_id,
        "Databases",
        "*.sqlite",
    )

    # Find matching database files
    db_files = glob.glob(db_path_pattern)

    if not db_files:
        raise FileNotFoundError(f"No SQLite database found for app '{app_id}'")

    # If multiple, return the first or select based on logic
    return db_files[0]


# Usage
app_id = "ubtms"
settings_db = find_settings_db(app_id)
choice = 0
sync(settings_db, choice)
