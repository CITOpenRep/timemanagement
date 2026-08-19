#!/usr/bin/env python3
"""
QML and JavaScript Import & Symbol Validator.
Validates:
1. Required module imports in .qml files (ensures file is not missing QtQuick/Lomiri).
2. Existence of relative imported files and folders (e.g. import "../../models/foo.js").
3. Usage of common namespace aliases (TimerService, Utils, Logger, etc.) without import.
"""

import sys
import os
import re

KNOWN_SERVICES = [
    "TimerService",
    "Utils",
    "Logger",
    "DraftManager",
    "MainModel",
    "NavigationRoutes"
]

def validate_file(filepath):
    errors = []
    if not os.path.isfile(filepath):
        return [f"File not found: {filepath}"]

    try:
        with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read()
    except Exception as e:
        return [f"Could not read file: {e}"]

    file_dir = os.path.dirname(os.path.abspath(filepath))

    # Check 1: Missing base imports in .qml files
    if filepath.endswith(".qml"):
        import_lines = re.findall(r"^\s*import\s+.+$", content, re.MULTILINE)
        has_root_object = re.search(r"^\s*(?:[A-Z]\w+|Item|Rectangle|Page|Component|QtObject|Column|Row)\s*\{", content, re.MULTILINE)
        if not import_lines and has_root_object:
            errors.append("File contains QML objects but has NO import statements (missing QtQuick/Lomiri imports).")

    # Check 2: Relative file/folder imports in QML
    # Matches: import "path" or import "path" as Alias or import "../path"
    qml_imports = re.findall(r"^\s*import\s+[\"']([^\"']+)[\"'](?:\s+as\s+(\w+))?", content, re.MULTILINE)
    for rel_path, alias in qml_imports:
        target_path = os.path.normpath(os.path.join(file_dir, rel_path))
        if not os.path.exists(target_path):
            errors.append(f"Import path not found: \"{rel_path}\" (resolved to: {target_path})")

    # Check 3: Relative .import in JavaScript files (.pragma library)
    # Matches: .import "path" as Alias
    js_imports = re.findall(r"^\s*\.import\s+[\"']([^\"']+)[\"']\s+as\s+(\w+)", content, re.MULTILINE)
    for rel_path, alias in js_imports:
        target_path = os.path.normpath(os.path.join(file_dir, rel_path))
        if not os.path.exists(target_path):
            errors.append(f"JS pragma import not found: \"{rel_path}\" (resolved to: {target_path})")

    # Check 4: Unimported service aliases
    for service in KNOWN_SERVICES:
        # Check if service is called (e.g. TimerService.start())
        if re.search(r"\b" + service + r"\.", content):
            # Check if imported in QML or JS
            qml_alias = re.search(r"import\s+.*?as\s+" + service + r"\b", content)
            js_alias = re.search(r"\.import\s+.*?as\s+" + service + r"\b", content)
            # Or defined in the file itself (e.g. var TimerService = ...)
            local_decl = re.search(r"\b(?:var|let|const|function|property\s+var)\s+" + service + r"\b", content)
            if not qml_alias and not js_alias and not local_decl:
                # Exclude file if it's the actual implementation file of that service
                base_name = os.path.splitext(os.path.basename(filepath))[0]
                if base_name.lower() not in service.lower():
                    errors.append(f"Identifier \"{service}\" is used, but missing \"import ... as {service}\"")

    return errors

def main():
    if len(sys.argv) < 2:
        print("Usage: check_imports.py <file1> [file2...]")
        sys.exit(1)

    has_errors = False
    for filepath in sys.argv[1:]:
        if not filepath.endswith((".qml", ".js")):
            continue
        errs = validate_file(filepath)
        if errs:
            has_errors = True
            print(f"[FAIL] Import check failed in {filepath}:")
            for err in errs:
                print(f"  - {err}")

    if has_errors:
        sys.exit(1)
    sys.exit(0)

if __name__ == "__main__":
    main()
