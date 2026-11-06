#!/usr/bin/env bash
#
# verify_deployment.sh - Automated deployment verification for Ubuntu Touch push-bridge
#
# Usage:
#   ./verify_deployment.sh [TARGET_URL]
#
# Examples:
#   ./verify_deployment.sh
#   ./verify_deployment.sh http://localhost:8000
#   ./verify_deployment.sh https://push.example.com
#
set -u

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo "Usage: $0 [TARGET_URL]"
    echo ""
    echo "Verify deployment of Ubuntu Touch push-bridge."
    echo ""
    echo "Arguments:"
    echo "  TARGET_URL    Base URL of the push bridge (default: http://localhost)"
    echo ""
    echo "Examples:"
    echo "  $0"
    echo "  $0 http://localhost:8000"
    echo "  $0 https://push.example.com"
    exit 0
fi

# Configuration and CLI arguments
TARGET_URL="${1:-http://localhost}"
TARGET_URL="${TARGET_URL%/}"

# Ensure URL has an explicit scheme
if [[ "$TARGET_URL" != http://* && "$TARGET_URL" != https://* ]]; then
    if [[ "$TARGET_URL" == localhost* || "$TARGET_URL" == 127.0.0.1* ]]; then
        TARGET_URL="http://${TARGET_URL}"
    else
        TARGET_URL="https://${TARGET_URL}"
    fi
fi

# Terminal colors (disabled if not connected to a terminal or if NO_COLOR is set)
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    COLOR_GREEN='\033[1;32m'
    COLOR_RED='\033[1;31m'
    COLOR_YELLOW='\033[1;33m'
    COLOR_CYAN='\033[1;36m'
    COLOR_BOLD='\033[1m'
    COLOR_RESET='\033[0m'
else
    COLOR_GREEN=''
    COLOR_RED=''
    COLOR_YELLOW=''
    COLOR_CYAN=''
    COLOR_BOLD=''
    COLOR_RESET=''
fi

# Accounting
CHECKS_TOTAL=0
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_SKIPPED=0

log_pass() {
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
    echo -e "  ${COLOR_GREEN}[PASS]${COLOR_RESET} $1"
}

log_fail() {
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
    echo -e "  ${COLOR_RED}[FAIL]${COLOR_RESET} $1"
    if [ -n "${2:-}" ]; then
        echo -e "         ${COLOR_RED}Reason:${COLOR_RESET} $2"
    fi
}

log_skip() {
    CHECKS_SKIPPED=$((CHECKS_SKIPPED + 1))
    echo -e "  ${COLOR_YELLOW}[SKIP]${COLOR_RESET} $1"
}

log_info() {
    echo -e "  ${COLOR_CYAN}[INFO]${COLOR_RESET} $1"
}

# Require curl
if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl is required but not installed." >&2
    exit 1
fi

TEST_DEVICE_TOKEN="test_verification_device_token"

echo ""
echo -e "${COLOR_BOLD}============================================================${COLOR_RESET}"
echo -e "${COLOR_BOLD}Push Bridge Deployment Verification${COLOR_RESET}"
echo -e "Target URL: ${COLOR_CYAN}${TARGET_URL}${COLOR_RESET}"
echo -e "${COLOR_BOLD}============================================================${COLOR_RESET}"
echo ""

# ------------------------------------------------------------
# 1. Health check endpoint (/health)
# ------------------------------------------------------------
echo -e "${COLOR_BOLD}1. Health Check Endpoint (/health)${COLOR_RESET}"
CHECKS_TOTAL=$((CHECKS_TOTAL + 1))

health_response=$(curl -sS --max-time 10 -w "\n%{http_code}" "${TARGET_URL}/health" 2>&1)
curl_status=$?

if [ $curl_status -ne 0 ]; then
    err_msg=$(echo "$health_response" | sed '$d')
    log_fail "Connection failed (curl error ${curl_status})" "$err_msg"
else
    http_code=$(echo "$health_response" | tail -n1)
    body=$(echo "$health_response" | sed '$d')

    if [ "$http_code" != "200" ]; then
        log_fail "Endpoint returned HTTP status ${http_code} (expected 200)" "$body"
    else
        is_ok=0
        if command -v python3 >/dev/null 2>&1; then
            status_val=$(python3 -c "import sys, json
try:
    data = json.loads(sys.argv[1])
    print(data.get('status', ''))
except Exception:
    sys.exit(1)
" "$body" 2>/dev/null)
            [ "$status_val" = "ok" ] && is_ok=1
        elif command -v jq >/dev/null 2>&1; then
            status_val=$(echo "$body" | jq -r '.status // empty' 2>/dev/null)
            [ "$status_val" = "ok" ] && is_ok=1
        else
            echo "$body" | grep -q '"status"[[:space:]]*:[[:space:]]*"ok"' && is_ok=1
        fi

        if [ $is_ok -eq 1 ]; then
            log_pass "Health check OK (HTTP 200, status=\"ok\")"
        else
            log_fail "Health check response payload missing 'status: ok'" "Received: $body"
        fi
    fi
fi
echo ""

# ------------------------------------------------------------
# 2. Subscription VAPID key generation endpoint (/v1/subscription/...)
# ------------------------------------------------------------
echo -e "${COLOR_BOLD}2. Subscription VAPID Key Generation Endpoint${COLOR_RESET}"
CHECKS_TOTAL=$((CHECKS_TOTAL + 1))

sub_url="${TARGET_URL}/v1/subscription/${TEST_DEVICE_TOKEN}"
sub_response=$(curl -sS --max-time 10 -w "\n%{http_code}" "$sub_url" 2>&1)
curl_status=$?

if [ $curl_status -ne 0 ]; then
    err_msg=$(echo "$sub_response" | sed '$d')
    log_fail "Connection failed (curl error ${curl_status})" "$err_msg"
else
    http_code=$(echo "$sub_response" | tail -n1)
    body=$(echo "$sub_response" | sed '$d')

    if [ "$http_code" != "200" ]; then
        log_fail "Subscription endpoint returned HTTP status ${http_code} (expected 200)" "$body"
    else
        has_endpoint=0
        has_p256dh=0
        parsed_endpoint=""
        parsed_p256dh=""

        if command -v python3 >/dev/null 2>&1; then
            parse_out=$(python3 -c "import sys, json
try:
    d = json.loads(sys.argv[1])
    ep = d.get('endpoint') or ''
    keys = d.get('keys') or {}
    k = keys.get('p256dh') or ''
    if ep:
        print(f'EP={ep}')
    if k:
        print(f'KEY={k}')
except Exception:
    sys.exit(1)
" "$body" 2>/dev/null)
            if [ $? -eq 0 ]; then
                parsed_endpoint=$(echo "$parse_out" | grep '^EP=' | cut -d= -f2-)
                parsed_p256dh=$(echo "$parse_out" | grep '^KEY=' | cut -d= -f2-)
                [ -n "$parsed_endpoint" ] && has_endpoint=1
                [ -n "$parsed_p256dh" ] && has_p256dh=1
            fi
        elif command -v jq >/dev/null 2>&1; then
            parsed_endpoint=$(echo "$body" | jq -r '.endpoint // empty' 2>/dev/null)
            parsed_p256dh=$(echo "$body" | jq -r '.keys.p256dh // empty' 2>/dev/null)
            [ -n "$parsed_endpoint" ] && has_endpoint=1
            [ -n "$parsed_p256dh" ] && has_p256dh=1
        fi

        if [ $has_endpoint -eq 1 ] && [ $has_p256dh -eq 1 ]; then
            log_pass "Subscription VAPID keys OK (HTTP 200, valid endpoint and keys.p256dh)"
            log_info "Endpoint: ${parsed_endpoint}"
        else
            log_fail "Subscription payload missing required fields" "Missing endpoint ($has_endpoint) or keys.p256dh ($has_p256dh)"
        fi
    fi
fi
echo ""

# ------------------------------------------------------------
# 3. Legacy poll status endpoint (/v1/legacy/subscriptions/...)
# ------------------------------------------------------------
echo -e "${COLOR_BOLD}3. Legacy Poll Status Endpoint${COLOR_RESET}"
CHECKS_TOTAL=$((CHECKS_TOTAL + 1))

legacy_url="${TARGET_URL}/v1/legacy/subscriptions/${TEST_DEVICE_TOKEN}"
legacy_response=$(curl -sS --max-time 10 -w "\n%{http_code}" "$legacy_url" 2>&1)
curl_status=$?

if [ $curl_status -ne 0 ]; then
    err_msg=$(echo "$legacy_response" | sed '$d')
    log_fail "Connection failed (curl error ${curl_status})" "$err_msg"
else
    http_code=$(echo "$legacy_response" | tail -n1)
    body=$(echo "$legacy_response" | sed '$d')

    if [ "$http_code" != "200" ]; then
        log_fail "Legacy subscription endpoint returned HTTP status ${http_code} (expected 200)" "$body"
    else
        has_array=0
        sub_count=0

        if command -v python3 >/dev/null 2>&1; then
            sub_count=$(python3 -c "import sys, json
try:
    d = json.loads(sys.argv[1])
    subs = d.get('subscriptions')
    if isinstance(subs, list):
        print(len(subs))
    else:
        sys.exit(1)
except Exception:
    sys.exit(1)
" "$body" 2>/dev/null)
            [ $? -eq 0 ] && has_array=1
        elif command -v jq >/dev/null 2>&1; then
            sub_count=$(echo "$body" | jq -r 'if .subscriptions | type == "array" then .subscriptions | length else empty end' 2>/dev/null)
            [ -n "$sub_count" ] && has_array=1
        fi

        if [ $has_array -eq 1 ]; then
            log_pass "Legacy status OK (HTTP 200, subscriptions list present, count: ${sub_count})"
        else
            log_fail "Legacy response missing 'subscriptions' array" "Received: $body"
        fi
    fi
fi
echo ""

# ------------------------------------------------------------
# 4. SSL/TLS check when running against https://
# ------------------------------------------------------------
echo -e "${COLOR_BOLD}4. SSL/TLS Certificate & Protocol Verification${COLOR_RESET}"
CHECKS_TOTAL=$((CHECKS_TOTAL + 1))

if [[ "$TARGET_URL" == https://* ]]; then
    # Extract host and port
    if [[ "$TARGET_URL" =~ ^https://([^/:]+)(:([0-9]+))? ]]; then
        SSL_HOST="${BASH_REMATCH[1]}"
        SSL_PORT="${BASH_REMATCH[3]:-443}"
    else
        SSL_HOST=""
        SSL_PORT="443"
    fi

    # Step A: Validate certificate chain and expiration with curl
    cert_valid=0
    cert_err=$(curl -sS --max-time 10 -o /dev/null "${TARGET_URL}/health" 2>&1)
    if [ $? -eq 0 ]; then
        cert_valid=1
    fi

    # Step B: Check TLS protocol version (expect TLS 1.2 or 1.3)
    proto_valid=0
    negotiated_proto=""
    cert_expiry=""

    if command -v openssl >/dev/null 2>&1 && [ -n "$SSL_HOST" ]; then
        openssl_out=$(echo | openssl s_client -connect "${SSL_HOST}:${SSL_PORT}" -servername "${SSL_HOST}" 2>/dev/null)
        negotiated_proto=$(echo "$openssl_out" | grep -E "Protocol\s*:" | awk '{print $NF}')
        cert_expiry=$(echo "$openssl_out" | openssl x509 -noout -enddate 2>/dev/null | sed -e 's/notAfter=//')

        if [[ "$negotiated_proto" == "TLSv1.2" || "$negotiated_proto" == "TLSv1.3" ]]; then
            proto_valid=1
        fi
    else
        # Fallback to curl TLS inspection
        curl_tls=$(curl -v -sS --max-time 10 -o /dev/null "${TARGET_URL}/health" 2>&1 | grep -iE "SSL connection using TLSv1\.[23]|TLSv1\.[23]")
        if [ -n "$curl_tls" ]; then
            proto_valid=1
            negotiated_proto="TLS 1.2/1.3"
        fi
    fi

    if [ $cert_valid -eq 1 ] && [ $proto_valid -eq 1 ]; then
        log_pass "TLS verification passed (valid certificate, negotiated protocol ${negotiated_proto})"
        if [ -n "$cert_expiry" ]; then
            log_info "Certificate expires: ${cert_expiry}"
        fi
    elif [ $cert_valid -ne 1 ]; then
        log_fail "SSL certificate validation failed" "$cert_err"
    else
        log_fail "TLS protocol version mismatch (expected TLS 1.2 or 1.3)" "Negotiated: ${negotiated_proto:-unknown}"
    fi
else
    log_skip "SSL/TLS verification skipped for non-HTTPS URL (scheme is http)"
fi
echo ""

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------
echo -e "${COLOR_BOLD}============================================================${COLOR_RESET}"
echo -e "${COLOR_BOLD}Verification Summary${COLOR_RESET}"
echo -e "Target:   ${TARGET_URL}"
echo -e "Passed:   ${COLOR_GREEN}${CHECKS_PASSED}${COLOR_RESET}"
echo -e "Failed:   ${COLOR_RED}${CHECKS_FAILED}${COLOR_RESET}"
echo -e "Skipped:  ${COLOR_YELLOW}${CHECKS_SKIPPED}${COLOR_RESET}"
echo -e "Total:    ${CHECKS_TOTAL}"
echo -e "${COLOR_BOLD}============================================================${COLOR_RESET}"

if [ $CHECKS_FAILED -eq 0 ]; then
    echo -e "${COLOR_GREEN}Status: ALL CHECKS PASSED${COLOR_RESET}"
    echo ""
    exit 0
else
    echo -e "${COLOR_RED}Status: DEPLOYMENT VERIFICATION FAILED${COLOR_RESET}"
    echo ""
    exit 1
fi
