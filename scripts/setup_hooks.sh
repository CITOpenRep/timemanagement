#!/usr/bin/env bash
# ==============================================================================
# Git Pre-commit Hook Setup Script
# Installs local pre-commit hook to lint only staged files before committing.
# ==============================================================================

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK_DEST="$PROJECT_ROOT/.git/hooks/pre-commit"

if [ ! -d "$PROJECT_ROOT/.git" ]; then
    echo "[ERROR] Not a git repository."
    exit 1
fi

cat << 'EOF' > "$HOOK_DEST"
#!/usr/bin/env bash
# ==============================================================================
# Git Pre-commit Hook: Lint Staged Files Only (Read-Only)
# Blocks commit if syntax or import errors are detected in staged files.
# ==============================================================================

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
LINT_SCRIPT="$PROJECT_ROOT/scripts/lint.sh"

if [ ! -x "$LINT_SCRIPT" ]; then
    echo "[WARN] $LINT_SCRIPT not found or not executable. Skipping pre-commit lint."
    exit 0
fi

# Get staged QML, JS, and Python files that were added/copied/modified
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(qml|js|py)$' || true)

if [ -z "$STAGED_FILES" ]; then
    # No relevant files staged
    exit 0
fi

echo "[INFO] Running pre-commit syntax and import checks on staged files..."
if ! "$LINT_SCRIPT" $STAGED_FILES; then
    echo ""
    echo "[ERROR] Commit aborted: Linting errors detected in staged files."
    echo "[HINT] Fix the issues above, stage your changes, and commit again."
    echo "[HINT] Emergency bypass if required: git commit --no-verify"
    exit 1
fi
EOF

chmod +x "$HOOK_DEST"
echo "[SUCCESS] Git pre-commit hook successfully installed at: $HOOK_DEST"
