#!/bin/sh
set -e

# Ensure data directory exists and has correct ownership
mkdir -p /app/data
if [ -d "/app/data" ]; then
    chown -R appuser:appuser /app/data 2>/dev/null || true
fi

PORT="${PORT:-8000}"

# If no arguments or default uvicorn invocation, start uvicorn with $PORT
if [ $# -eq 0 ] || [ "$1" = "uvicorn" ]; then
    if [ "$(id -u)" = "0" ]; then
        exec gosu appuser uvicorn app:app --host 0.0.0.0 --port "$PORT"
    fi
    exec uvicorn app:app --host 0.0.0.0 --port "$PORT"
fi

# If started as root, drop privileges to appuser
if [ "$(id -u)" = "0" ]; then
    exec gosu appuser "$@"
fi

exec "$@"
