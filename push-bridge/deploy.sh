#!/usr/bin/env bash
set -euo pipefail

# Determine privilege elevation capability
CAN_SUDO=false
SUDO=""
if [ "$(id -u)" -eq 0 ]; then
    CAN_SUDO=true
elif command -v sudo >/dev/null 2>&1; then
    if sudo -n true 2>/dev/null; then
        CAN_SUDO=true
        SUDO="sudo"
    fi
fi

# Fix Oracle Cloud Infrastructure Ubuntu default iptables reject rules.
# OCI Ubuntu images include default REJECT rules on INPUT that block ports 80/443.
if [ "$CAN_SUDO" = true ] && command -v iptables >/dev/null 2>&1; then
    echo "Checking firewall rules for ports 80 and 443..."
    if ! $SUDO iptables -C INPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null; then
        echo "Adding iptables accept rule for port 80..."
        $SUDO iptables -I INPUT 1 -p tcp --dport 80 -j ACCEPT
    fi
    if ! $SUDO iptables -C INPUT -p tcp --dport 443 -j ACCEPT 2>/dev/null; then
        echo "Adding iptables accept rule for port 443..."
        $SUDO iptables -I INPUT 1 -p tcp --dport 443 -j ACCEPT
    fi

    if command -v ip6tables >/dev/null 2>&1; then
        if ! $SUDO ip6tables -C INPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null; then
            $SUDO ip6tables -I INPUT 1 -p tcp --dport 80 -j ACCEPT 2>/dev/null || true
        fi
        if ! $SUDO ip6tables -C INPUT -p tcp --dport 443 -j ACCEPT 2>/dev/null; then
            $SUDO ip6tables -I INPUT 1 -p tcp --dport 443 -j ACCEPT 2>/dev/null || true
        fi
    fi

    if command -v netfilter-persistent >/dev/null 2>&1; then
        echo "Persisting iptables rules with netfilter-persistent..."
        $SUDO netfilter-persistent save
    elif [ -d /etc/iptables ]; then
        echo "Saving iptables rules to /etc/iptables..."
        $SUDO sh -c 'iptables-save > /etc/iptables/rules.v4'
        $SUDO sh -c 'ip6tables-save > /etc/iptables/rules.v6 2>/dev/null || true'
    fi

    if command -v ufw >/dev/null 2>&1 && $SUDO ufw status 2>/dev/null | grep -qw "active"; then
        echo "Opening ports 80 and 443 in UFW..."
        $SUDO ufw allow 80/tcp
        $SUDO ufw allow 443/tcp
    fi
elif [ "$CAN_SUDO" != true ]; then
    echo "Note: Skipping iptables rules check (requires root or passwordless sudo)."
fi

install_docker() {
    if [ "$CAN_SUDO" != true ]; then
        echo "Error: Root or sudo access is required to install Docker." >&2
        exit 1
    fi

    echo "Installing Docker via convenience script..."
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    $SUDO sh /tmp/get-docker.sh
    rm -f /tmp/get-docker.sh

    TARGET_USER="${SUDO_USER:-$USER}"
    if [ -n "$TARGET_USER" ] && [ "$TARGET_USER" != "root" ]; then
        $SUDO usermod -aG docker "$TARGET_USER"
        echo "Added $TARGET_USER to docker group."
    fi

    $SUDO systemctl enable --now docker
}

# Verify Docker installation
if ! command -v docker >/dev/null 2>&1; then
    if [ -t 0 ]; then
        read -r -p "Docker is not installed. Install Docker now? [Y/n] " response
        case "$response" in
            [nN][oO]|[nN])
                echo "Aborting: Docker is required for deployment." >&2
                exit 1
                ;;
            *)
                install_docker
                ;;
        esac
    else
        echo "Docker is not installed. Installing automatically..."
        install_docker
    fi
fi

# Verify Docker Compose plugin
if ! docker compose version >/dev/null 2>&1; then
    if [ "$CAN_SUDO" != true ]; then
        echo "Error: Docker Compose plugin is missing and sudo is unavailable." >&2
        exit 1
    fi
    echo "Docker Compose plugin missing. Installing via apt..."
    $SUDO apt-get update -qq && $SUDO apt-get install -y -qq docker-compose-plugin
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Ensure SQLite volume directory exists with correct ownership and permissions.
# The container runs as unprivileged appuser (UID 10001).
mkdir -p ./data

# If an unmigrated database exists in the repository directory, copy it into ./data
if [ -f ./subscriptions.db ] && [ ! -f ./data/subscriptions.db ]; then
    echo "Migrating existing subscriptions.db into ./data..."
    cp -p ./subscriptions.db ./data/subscriptions.db
fi

# Ensure appuser (UID 10001) has read/write ownership and file permissions are restricted
if [ "$CAN_SUDO" = true ]; then
    $SUDO chown -R 10001:10001 ./data
    $SUDO chmod 750 ./data
    if [ -f ./data/subscriptions.db ]; then
        $SUDO chmod 600 ./data/subscriptions.db
    fi
else
    chmod 770 ./data 2>/dev/null || chmod 777 ./data
    if [ -f ./data/subscriptions.db ]; then
        chmod 660 ./data/subscriptions.db 2>/dev/null || chmod 666 ./data/subscriptions.db
    fi
fi

# Resolve domain name from argument, existing .env, or interactive prompt
DOMAIN="${1:-}"

if [ -z "$DOMAIN" ]; then
    PREV_DOMAIN=""
    if [ -f .env ]; then
        PREV_DOMAIN=$(grep -E '^DOMAIN=' .env 2>/dev/null | cut -d '=' -f2- | tr -d ' "' || true)
    fi

    if [ -t 0 ]; then
        DEFAULT_DOMAIN="${PREV_DOMAIN:-localhost}"
        read -r -p "Enter domain for push bridge (e.g. push.mydomain.com) [$DEFAULT_DOMAIN]: " input_domain
        DOMAIN="${input_domain:-$DEFAULT_DOMAIN}"
    else
        DOMAIN="${PREV_DOMAIN:-localhost}"
    fi
fi

if [ "$DOMAIN" = "localhost" ]; then
    PUBLIC_URL="http://localhost"
else
    PUBLIC_URL="https://${DOMAIN}"
fi

cat > .env << EOF
DOMAIN=$DOMAIN
BRIDGE_PUBLIC_URL=$PUBLIC_URL
BRIDGE_DB_PATH=/app/data/subscriptions.db
UBPORTS_PUSH_URL=https://push.ubports.com/notify
UBPORTS_APP_ID=ubtms_ubtms
EOF
chmod 600 .env

echo "Configured .env for domain: $DOMAIN ($PUBLIC_URL)"

DOCKER_BIN="docker"
if ! docker info >/dev/null 2>&1; then
    if [ "$CAN_SUDO" = true ]; then
        DOCKER_BIN="$SUDO docker"
    else
        echo "Error: Cannot communicate with Docker daemon and sudo is unavailable." >&2
        exit 1
    fi
fi

echo "Building and starting containers with Docker Compose..."
$DOCKER_BIN compose up -d --build

echo "Verifying health check on http://localhost/health..."
MAX_ATTEMPTS=20
ATTEMPT=0
HEALTH_OK=false

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    ATTEMPT=$((ATTEMPT + 1))
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/health 2>/dev/null || true)
    if [ "$HTTP_STATUS" = "200" ]; then
        HEALTH_OK=true
        break
    fi
    sleep 1
done

if [ "$HEALTH_OK" = true ]; then
    echo "Push bridge is healthy (HTTP 200)."
    echo "Public URL: $PUBLIC_URL"
    echo "Deployment completed successfully."
else
    echo "Health check failed or timed out (HTTP status: ${HTTP_STATUS:-unreachable})." >&2
    echo "Check container logs with: $DOCKER_BIN compose logs" >&2
    exit 1
fi
