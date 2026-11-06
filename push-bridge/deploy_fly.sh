#!/usr/bin/env bash
set -e

# ubtms push-bridge Fly.io deployment script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

echo "[INFO] Starting Fly.io deployment workflow..."

# 1. Check for flyctl CLI
if ! command -v flyctl >/dev/null 2>&1 && ! command -v fly >/dev/null 2>&1; then
    if [ -f "$HOME/.fly/bin/flyctl" ]; then
        export PATH="$HOME/.fly/bin:$PATH"
    else
        echo "[INFO] flyctl not found. Installing via official install script..."
        curl -L https://fly.io/install.sh | sh
        export PATH="$HOME/.fly/bin:$PATH"
    fi
fi

FLY_BIN="fly"
if ! command -v fly >/dev/null 2>&1; then
    FLY_BIN="flyctl"
fi

if ! command -v "$FLY_BIN" >/dev/null 2>&1; then
    echo "[FAIL] Could not locate or install flyctl. Please install manually: https://fly.io/docs/hands-on/install-flyctl/"
    exit 1
fi

echo "[INFO] Using Fly CLI: $($FLY_BIN version)"

# 2. Check authentication
echo "[INFO] Checking Fly.io authentication..."
if ! "$FLY_BIN" auth whoami >/dev/null 2>&1; then
    echo "[INFO] Not logged in to Fly.io. Launching authentication..."
    "$FLY_BIN" auth login
fi

CURRENT_USER=$("$FLY_BIN" auth whoami 2>/dev/null || echo "authenticated user")
echo "[INFO] Logged in as: ${CURRENT_USER}"

# 3. Determine App Name
APP_NAME="$1"
if [ -z "$APP_NAME" ]; then
    CURRENT_APP=$(grep -E '^app\s*=\s*' fly.toml | head -n 1 | sed -E 's/app\s*=\s*["'"'"']([^"'"'"']+)["'"'"']/\1/')
    if [ -n "$CURRENT_APP" ] && [ "$CURRENT_APP" != "ubtms-push-bridge" ]; then
        DEFAULT_APP="$CURRENT_APP"
    else
        DEFAULT_APP="ubtms-push-$RANDOM"
    fi

    echo ""
    read -r -p "Enter unique Fly.io app name [${DEFAULT_APP}]: " INPUT_APP
    APP_NAME="${INPUT_APP:-$DEFAULT_APP}"
fi

echo "[INFO] Configuring app name: ${APP_NAME}"
# Update fly.toml with the chosen app name
sed -i -E "s/^app\s*=\s*[\"'].*[\"']/app = \"${APP_NAME}\"/" fly.toml

# 4. Check or create the app on Fly.io
echo "[INFO] Ensuring Fly.io app '${APP_NAME}' exists..."
if ! "$FLY_BIN" status -a "${APP_NAME}" >/dev/null 2>&1; then
    echo "[INFO] Creating new app '${APP_NAME}' in region 'ams'..."
    "$FLY_BIN" apps create "${APP_NAME}" || true
fi

# 5. Check or create persistent storage volume
echo "[INFO] Checking persistent volume 'push_data'..."
VOLUMES_COUNT=$("$FLY_BIN" volumes list -a "${APP_NAME}" 2>/dev/null | grep -c "push_data" || true)
if [ "$VOLUMES_COUNT" -eq 0 ]; then
    echo "[INFO] Creating 1GB persistent volume 'push_data' in region 'ams'..."
    "$FLY_BIN" volumes create push_data --size 1 --region ams -a "${APP_NAME}" -y
else
    echo "[INFO] Persistent volume 'push_data' already exists."
fi

# 6. Deploy
echo "[INFO] Deploying container stack to Fly.io..."
"$FLY_BIN" deploy -a "${APP_NAME}"

PUBLIC_URL="https://${APP_NAME}.fly.dev"
echo ""
echo "------------------------------------------------------------"
echo "[SUCCESS] Push bridge deployed to Fly.io!"
echo "Public URL: ${PUBLIC_URL}"
echo "Health URL: ${PUBLIC_URL}/health"
echo "------------------------------------------------------------"
echo ""

# 7. Run smoke verification
if [ -x "./verify_deployment.sh" ]; then
    echo "[INFO] Running post-deployment verification tests..."
    ./verify_deployment.sh "${PUBLIC_URL}" || true
fi
