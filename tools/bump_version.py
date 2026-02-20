#!/usr/bin/env python3
"""Bump the app version consistently across source files.

Usage:
  tools/bump_version.py 1.2.4

Edits only source files (not build/ output):
  - VERSION
  - manifest.json.in
  - models/constants.js
  - qml/release_notes.txt
  - src/daemon.py (only if it still contains a hardcoded fallback)
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent


def replace_regex(path: Path, pattern: str, repl: str) -> bool:
    text = path.read_text(encoding="utf-8")
    new_text, n = re.subn(pattern, repl, text, flags=re.MULTILINE)
    if n:
        path.write_text(new_text, encoding="utf-8")
    return n > 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Bump ubtms app version everywhere")
    parser.add_argument("version", help="New version (e.g. 1.2.4)")
    args = parser.parse_args()

    new_version = args.version.strip()
    if not re.fullmatch(r"\d+\.\d+\.\d+", new_version):
        raise SystemExit("Version must look like X.Y.Z (e.g. 1.2.4)")

    changed: list[str] = []

    # 1) VERSION
    (ROOT / "VERSION").write_text(new_version + "\n", encoding="utf-8")
    changed.append("VERSION")

    # 2) manifest.json.in
    if replace_regex(
        ROOT / "manifest.json.in",
        r'(\s*"version"\s*:\s*")([^"]+)("\s*,?)',
        rf"\\1{new_version}\\3",
    ):
        changed.append("manifest.json.in")

    # 3) models/constants.js
    if replace_regex(
        ROOT / "models" / "constants.js",
        r'^(\s*var\s+version\s*=\s*")([^"]+)("\s*)$',
        rf"\\1{new_version}\\3",
    ):
        changed.append("models/constants.js")

    # 4) qml/release_notes.txt (only the visible 'Version X.Y.Z' strings)
    release_notes = ROOT / "qml" / "release_notes.txt"
    rn_text = release_notes.read_text(encoding="utf-8")
    rn_text2, n = re.subn(r"\bVersion\s+\d+\.\d+\.\d+\b", f"Version {new_version}", rn_text)
    if n:
        release_notes.write_text(rn_text2, encoding="utf-8")
        changed.append("qml/release_notes.txt")

    # 5) src/daemon.py: keep it future-proof (avoid baking a specific version)
    daemon = ROOT / "src" / "daemon.py"
    if daemon.exists():
        text = daemon.read_text(encoding="utf-8")
        new_text, n = re.subn(
            r"return\s+(['\"])\d+\.\d+\.\d+\1\s*#\s*Fallback version",
            'return "unknown"  # Fallback version',
            text,
        )
        if n:
            daemon.write_text(new_text, encoding="utf-8")
            changed.append("src/daemon.py")

    print("Updated version to", new_version)
    print("Changed:")
    for p in changed:
        print(" -", p)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
