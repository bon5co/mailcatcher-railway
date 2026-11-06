#!/bin/sh
# MailCatcher NG on 127.0.0.1:1080 (never public), Caddy on $PORT in front with basic auth,
# SMTP on 1025 for the private network. Exits if either process dies so Railway restarts it.
set -eu

DATA_DIR="${DATA_DIR:-/data}"
UI_USER="${MAILCATCHER_UI_USER:-admin}"
: "${MAILCATCHER_UI_PASSWORD:?MAILCATCHER_UI_PASSWORD is required}"
LISTEN_PORT="${PORT:-8080}"
MESSAGES_LIMIT="${MAILCATCHER_MESSAGES_LIMIT:-5000}"

mkdir -p "$DATA_DIR"
echo "[boot] data dir owner=$(stat -c %u:%g "$DATA_DIR") web=:$LISTEN_PORT smtp=:1025 limit=$MESSAGES_LIMIT"

# MailCatcher keeps its SQLite file under $HOME/.mailcatcher when --persistence is set.
export HOME="$DATA_DIR"

HASH="$(caddy hash-password --plaintext "$MAILCATCHER_UI_PASSWORD")"
cat > /tmp/Caddyfile <<CADDY
{
	admin off
	auto_https off
}
:${LISTEN_PORT} {
	handle /healthz {
		respond "ok" 200
	}
	handle {
		basic_auth {
			${UI_USER} ${HASH}
		}
		reverse_proxy 127.0.0.1:1080
	}
}
CADDY

mailcatcher --foreground --no-quit --persistence --plugin \
  --smtp-ip 0.0.0.0 --smtp-port 1025 \
  --http-ip 127.0.0.1 --http-port 1080 \
  --messages-limit "$MESSAGES_LIMIT" &
MC_PID=$!

XDG_CONFIG_HOME=/tmp XDG_DATA_HOME=/tmp caddy run --config /tmp/Caddyfile --adapter caddyfile &
CADDY_PID=$!

trap 'kill $MC_PID $CADDY_PID 2>/dev/null || true' TERM INT
while kill -0 $MC_PID 2>/dev/null && kill -0 $CADDY_PID 2>/dev/null; do sleep 2; done
echo "[boot] a child process exited; stopping"
kill $MC_PID $CADDY_PID 2>/dev/null || true
exit 1
