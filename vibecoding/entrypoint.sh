#!/bin/sh

set -eu

HOST_ADDR="${HOST_ADDR:-host.docker.internal}"
PROJECT_DIR="${PWD:-/home/node/project}"
PORT_VALUE="${OPENCODE_PORT:-4096}"
TUNNEL_PIDS=""
SERVER_PID=""

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/opencode"
mkdir -p "$STATE_DIR"
[ -e "$STATE_DIR/kv.json" ] || printf '{}\n' > "$STATE_DIR/kv.json"

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
        if [ "$port" = "$PORT_VALUE" ]; then
            echo "  - skipped $port (reserved for OpenCode)"
            continue
        fi
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

cleanup() {
    if [ -n "$SERVER_PID" ]; then
        kill "$SERVER_PID" 2>/dev/null || true
        wait "$SERVER_PID" 2>/dev/null || true
    fi
    cleanup_tunnels
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# V1 does not honor the password variable used for the published server.
case "$(/usr/local/bin/opencode --version)" in
    'opencode v2.'*|2.*) ;;
    *) echo "OpenCode v2 is required. Rebuild the runner image with run.sh build." >&2; exit 1 ;;
esac

start_localhost_tunnels

export OPENCODE_PASSWORD=opencode

MODE="${OPENCODE_MODE:-tui}"
HOSTNAME_VALUE="${OPENCODE_HOSTNAME:-0.0.0.0}"

if [ "$MODE" = "serve" ]; then
    exec /usr/local/bin/opencode serve --hostname "$HOSTNAME_VALUE" --port "$PORT_VALUE"
fi

SERVER_URL="http://127.0.0.1:$PORT_VALUE"
/usr/local/bin/opencode serve --hostname "$HOSTNAME_VALUE" --port "$PORT_VALUE" > /tmp/opencode-server.log 2>&1 &
SERVER_PID=$!

attempt=0
until curl -fsS --max-time 1 -u "opencode:$OPENCODE_PASSWORD" "$SERVER_URL/api/info" >/dev/null 2>&1; do
    if ! kill -0 "$SERVER_PID" 2>/dev/null || [ "$attempt" -ge 100 ]; then
        cat /tmp/opencode-server.log >&2
        echo "OpenCode server failed to start." >&2
        exit 1
    fi
    attempt=$((attempt + 1))
    sleep 0.1
done

/usr/local/bin/opencode --server "$SERVER_URL" "$@"
