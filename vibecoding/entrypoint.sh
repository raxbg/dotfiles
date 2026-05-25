#!/bin/sh

set -eu

HOST_ADDR="${HOST_ADDR:-host.docker.internal}"
PROJECT_DIR="${PWD:-/home/node/project}"
TUNNEL_PIDS=""

start_localhost_tunnels() {
    if ! command -v socat >/dev/null 2>&1; then
        echo "⚠️ socat not found, skipping localhost tunnel setup"
        return 0
    fi

    config_files=$(find "$PROJECT_DIR" -maxdepth 2 \
        \( -name .git -o -name node_modules \) -prune -o \
        -type f \( -name "opencode.json" -o -name ".opencode.json" -o -name "*opencode*.json" \) \
        -print)

    if [ -z "$config_files" ]; then
        return 0
    fi

    ports=$(printf '%s\n' "$config_files" | \
        xargs -r grep -hEo '(localhost|127\.0\.0\.1):[0-9]{1,5}' 2>/dev/null | \
        sed -E 's/.*:([0-9]{1,5})/\1/' | \
        awk '$1 >= 1 && $1 <= 65535' | \
        sort -u)

    if [ -z "$ports" ]; then
        return 0
    fi

    echo "🔌 Starting localhost tunnels via $HOST_ADDR..."
    for port in $ports; do
        socat "TCP-LISTEN:${port},bind=127.0.0.1,reuseaddr,fork" "TCP:${HOST_ADDR}:${port}" >/tmp/opencode-tunnel-"${port}".log 2>&1 &
        pid=$!

        sleep 0.1
        if kill -0 "$pid" 2>/dev/null; then
            TUNNEL_PIDS="$TUNNEL_PIDS $pid"
            echo "  - 127.0.0.1:${port} -> ${HOST_ADDR}:${port}"
        else
            echo "  - failed to create tunnel for port ${port}"
        fi
    done
}

cleanup_tunnels() {
    for pid in $TUNNEL_PIDS; do
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null || true
            wait "$pid" 2>/dev/null || true
        fi
    done
}

trap cleanup_tunnels EXIT INT TERM

start_localhost_tunnels

MODE="${OPENCODE_MODE:-tui}"

if [ "$MODE" = "serve" ]; then
    HOSTNAME_VALUE="${OPENCODE_HOSTNAME:-0.0.0.0}"
    PORT_VALUE="${OPENCODE_PORT:-4096}"
    exec /usr/local/bin/opencode serve --hostname "$HOSTNAME_VALUE" --port "$PORT_VALUE"
fi

exec /usr/local/bin/opencode "$@"
