#!/bin/sh
set -e

# Ensure mounted volume has correct ownership for appuser
if [ -d "/app/data" ]; then
    chown -R appuser:appuser /app/data 2>/dev/null || true
fi

# If started as root, drop privileges to appuser
if [ "$(id -u)" = "0" ]; then
    exec gosu appuser "$@"
fi

exec "$@"
