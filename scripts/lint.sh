#!/usr/bin/env bash
# ==============================================================================
# Local Linting & Syntax Verification Script
# Read-only verification for QML, JavaScript, and Python files.
# Never modifies files or causes merge conflicts.
# ==============================================================================

set -o pipefail

# Text formatting
if [ -t 1 ]; then
    BOLD="\033[1m"
    GREEN="\033[32m"
    RED="\033[31m"
    YELLOW="\033[33m"
    BLUE="\033[34m"
    RESET="\033[0m"
else
    BOLD=""
    GREEN=""
    RED=""
    YELLOW=""
    BLUE=""
    RESET=""
fi

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

ERRORS=0
CHECKED=0
FAILED_FILES=()

# Check for qmllint
if ! command -v qmllint &> /dev/null; then
    echo -e "${RED}[ERROR] 'qmllint' is not installed or not in PATH.${RESET}"
    echo "Install it via your Qt/Ubuntu development packages (e.g. qtdeclarative5-dev-tools or qml-tools)."
    exit 1
fi

IMPORT_CHECKER="$PROJECT_ROOT/scripts/check_imports.py"

lint_qml_js() {
    local file="$1"
    ((CHECKED++))
    local file_failed=0

    # 1. Grammar & Bracket Syntax check via qmllint
    local qml_out
    qml_out=$(qmllint -I qml -I models -I qml/components/system "$file" 2>&1)
    local qml_status=$?
    if [ $qml_status -ne 0 ] || [ -n "$qml_out" ]; then
        echo -e "${RED}[FAIL] Syntax Error:${RESET} $file"
        if [ -n "$qml_out" ]; then
            echo "$qml_out" | sed 's/^/  /'
        fi
        file_failed=1
    fi

    # 2. Deep Import & Symbol validation via check_imports.py
    if [ -x "$IMPORT_CHECKER" ]; then
        local imp_out
        imp_out=$("$IMPORT_CHECKER" "$file" 2>&1)
        local imp_status=$?
        if [ $imp_status -ne 0 ]; then
            echo -e "${RED}[FAIL] Import Error:${RESET} $file"
            if [ -n "$imp_out" ]; then
                echo "$imp_out" | sed 's/^/  /'
            fi
            file_failed=1
        fi
    fi

    if [ $file_failed -eq 1 ]; then
        ((ERRORS++))
        FAILED_FILES+=("$file")
    fi
}

lint_python() {
    local file="$1"
    ((CHECKED++))
    local output
    output=$(python3 -m py_compile "$file" 2>&1)
    local status=$?
    if [ $status -ne 0 ]; then
        echo -e "${RED}[FAIL] Python Syntax Error:${RESET} $file"
        if [ -n "$output" ]; then
            echo "$output" | sed 's/^/  /'
        fi
        ((ERRORS++))
        FAILED_FILES+=("$file")
    fi
}

echo -e "${BOLD}${BLUE}[INFO] Starting codebase linting...${RESET}\n"

# If specific files were passed as arguments, check only those
if [ "$#" -gt 0 ]; then
    for file in "$@"; do
        if [ ! -f "$file" ]; then
            echo -e "${YELLOW}[WARN] Skipping non-existent file: $file${RESET}"
            continue
        fi

        case "$file" in
            *.qml|*.js)
                lint_qml_js "$file"
                ;;
            *.py)
                lint_python "$file"
                ;;
            *)
                # Non-lintable file, skip silently
                ;;
        esac
    done
else
    # Full codebase scan (excluding build, .git, .clickable, .agent)
    while IFS= read -r -d '' file; do
        lint_qml_js "$file"
    done < <(find qml models -type f \( -name "*.qml" -o -name "*.js" \) -not -path "*/build/*" -print0)

    while IFS= read -r -d '' file; do
        lint_python "$file"
    done < <(find . -maxdepth 2 -type f -name "*.py" -not -path "*/build/*" -not -path "*/.git/*" -not -path "*/.clickable/*" -not -path "*/.agent/*" -print0)
    
    if [ -d "src" ]; then
        while IFS= read -r -d '' file; do
            lint_python "$file"
        done < <(find src -type f -name "*.py" -not -path "*/__pycache__/*" -print0)
    fi
fi

echo ""
echo "------------------------------------------------------------"
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}${BOLD}[SUCCESS] All $CHECKED files passed syntax and import validation.${RESET}"
    exit 0
else
    echo -e "${RED}${BOLD}[ERROR] Linting failed: $ERRORS error(s) found across $CHECKED checked files.${RESET}"
    echo -e "${RED}Failed files:${RESET}"
    for failed in "${FAILED_FILES[@]}"; do
        echo -e "  - $failed"
    done
    exit 1
fi
