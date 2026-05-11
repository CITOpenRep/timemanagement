#!/usr/bin/env bash
set -euo pipefail

# Phase-1 migration checks
# Modes:
#   report (default): print findings and warnings only
#   strict: fail on defined gate violations

MODE="${1:-report}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if command -v rg >/dev/null 2>&1; then
    SEARCH_TOOL="rg"
else
    SEARCH_TOOL="grep"
fi

if [[ "$MODE" != "report" && "$MODE" != "strict" ]]; then
    echo "Usage: $0 [report|strict]"
    exit 2
fi

fail_count=0
warn_count=0

say() {
    printf '%s\n' "$*"
}

warn() {
    warn_count=$((warn_count + 1))
    say "[WARN] $*"
}

fail() {
    fail_count=$((fail_count + 1))
    say "[FAIL] $*"
}

pass() {
    say "[PASS] $*"
}

search_count_qml() {
    local pattern="$1"
    if [[ "$SEARCH_TOOL" == "rg" ]]; then
        (rg -n --no-heading "$pattern" "$ROOT_DIR/qml" || true) | wc -l | tr -d ' '
    else
        (grep -R -n -E "$pattern" "$ROOT_DIR/qml" || true) | wc -l | tr -d ' '
    fi
}

search_count_qml_excluding_app() {
    local pattern="$1"
    if [[ "$SEARCH_TOOL" == "rg" ]]; then
        ((rg -n --no-heading "$pattern" "$ROOT_DIR/qml" || true) | (rg -v "/qml/app/" || true)) | wc -l | tr -d ' '
    else
        ((grep -R -n -E "$pattern" "$ROOT_DIR/qml" || true) | (grep -v "/qml/app/" || true)) | wc -l | tr -d ' '
    fi
}

say "Running Phase-1 checks in mode: $MODE"

# 1) Guardrail docs exist
for f in \
    "$ROOT_DIR/docs/refactor/phase-1-architecture-contract.md" \
    "$ROOT_DIR/docs/refactor/phase-1-naming-map.md" \
    "$ROOT_DIR/docs/refactor/phase-1-smoke-checklist.md"; do
    if [[ -f "$f" ]]; then
        pass "Found $(realpath --relative-to="$ROOT_DIR" "$f")"
    else
        fail "Missing $(realpath --relative-to="$ROOT_DIR" "$f")"
    fi
done

# 2) Detect direct AppLayout routing calls outside app shell (report baseline)
route_calls=$(search_count_qml_excluding_app "apLayout\\.(setPageGlobal|addPageToNextColumn|removePages)\\(")

if [[ "$route_calls" -gt 0 ]]; then
    if [[ "$MODE" == "strict" ]]; then
        fail "Found $route_calls direct AppLayout routing calls outside qml/app"
    else
        warn "Found $route_calls direct AppLayout routing calls outside qml/app (expected before extraction)"
    fi
else
    pass "No direct AppLayout routing calls outside qml/app"
fi

# 3) Legacy model imports baseline
legacy_imports=$(search_count_qml 'import[[:space:]]+"[^"]*/models/(task|timesheet|project|activity)\.js"')
if [[ "$legacy_imports" -gt 0 ]]; then
    if [[ "$MODE" == "strict" ]]; then
        fail "Found $legacy_imports legacy flat model imports"
    else
        warn "Found $legacy_imports legacy flat model imports (expected before model split)"
    fi
else
    pass "No legacy flat model imports found"
fi

# 4) Python compatibility entrypoints present
for py in "$ROOT_DIR/src/backend.py" "$ROOT_DIR/src/daemon.py" "$ROOT_DIR/src/cli.py"; do
    if [[ -f "$py" ]]; then
        pass "Found $(realpath --relative-to="$ROOT_DIR" "$py")"
    else
        fail "Missing $(realpath --relative-to="$ROOT_DIR" "$py")"
    fi
done

# 5) Optional import smoke (non-fatal in report mode)
run_import_smoke() {
    local module="$1"
    local strict_fail="${2:-yes}"
    if python3 -c "import sys; sys.path.insert(0, '$ROOT_DIR/src'); import $module" >/dev/null 2>&1; then
        pass "Python import ok: $module"
    else
        if [[ "$MODE" == "strict" && "$strict_fail" == "yes" ]]; then
            fail "Python import failed: $module"
        else
            warn "Python import failed: $module"
        fi
    fi
}

run_import_smoke backend
run_import_smoke daemon
run_import_smoke cli no

say ""
say "Summary: fails=$fail_count warnings=$warn_count"

if [[ "$MODE" == "strict" && "$fail_count" -gt 0 ]]; then
    exit 1
fi

exit 0
