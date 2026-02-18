#!/bin/bash
set -euo pipefail

CONFIG_DIR="/config"
SETTINGS_FILE="$CONFIG_DIR/settings.json"

# Default environment variables
: "${RPC_USER:=transmission}"
: "${RPC_PASS:=transmission}"
: "${DOWNLOAD_DIR:=/downloads}"
: "${DHT_ENABLED:=true}"
: "${PEER_PORT:=51413}"
: "${CACHE_SIZE_MB:=64}"
: "${WATCH_DIR_ENABLED:=false}"
: "${WATCH_DIR:=/watch}"
: "${RENAME_PARTIAL_FILES:=false}"
: "${PEX_ENABLED:=true}"
: "${RATIO_LIMIT:=0}"
: "${RATIO_LIMIT_ENABLED:=false}"
: "${PEER_LIMIT_GLOBAL:=300}"
: "${PEER_LIMIT_PER_TORRENT:=35}"
: "${SPEED_LIMIT_UP:=1024}"
: "${SPEED_LIMIT_UP_ENABLED:=false}"
: "${START_ADDED_TORRENTS:=false}"
: "${UTP_ENABLED:=true}"

# Normalize booleans to real JSON booleans
normalize_bool() {
    case "${1,,}" in
        true|1|yes) echo "true" ;;
        *) echo "false" ;;
    esac
}

DHT_ENABLED=$(normalize_bool "$DHT_ENABLED")
WATCH_DIR_ENABLED=$(normalize_bool "$WATCH_DIR_ENABLED")
RENAME_PARTIAL_FILES=$(normalize_bool "$RENAME_PARTIAL_FILES")
PEX_ENABLED=$(normalize_bool "$PEX_ENABLED")
RATIO_LIMIT_ENABLED=$(normalize_bool "$RATIO_LIMIT_ENABLED")
SPEED_LIMIT_UP_ENABLED=$(normalize_bool "$SPEED_LIMIT_UP_ENABLED")
START_ADDED_TORRENTS=$(normalize_bool "$START_ADDED_TORRENTS")
UTP_ENABLED=$(normalize_bool "$UTP_ENABLED")

# Generate settings.json if missing
if [ ! -f "$SETTINGS_FILE" ]; then
    echo "Generating default settings.json..."
    transmission-daemon --foreground --config-dir "$CONFIG_DIR" --log-level=error &
    DAEMON_PID=$!
    sleep 3
    kill "$DAEMON_PID" || true
    wait "$DAEMON_PID" 2>/dev/null || true
fi

echo "Updating settings.json with jq..."

tmp=$(mktemp)

jq \
  --arg download "$DOWNLOAD_DIR" \
  --arg user "$RPC_USER" \
  --arg pass "$RPC_PASS" \
  --arg watch "$WATCH_DIR" \
  --argjson dht "$DHT_ENABLED" \
  --argjson peer_port "$PEER_PORT" \
  --argjson cache "$CACHE_SIZE_MB" \
  --argjson watch_enabled "$WATCH_DIR_ENABLED" \
  --argjson rename_partial "$RENAME_PARTIAL_FILES" \
  --argjson pex "$PEX_ENABLED" \
  --argjson ratio "$RATIO_LIMIT" \
  --argjson ratio_enabled "$RATIO_LIMIT_ENABLED" \
  --argjson peer_global "$PEER_LIMIT_GLOBAL" \
  --argjson peer_torrent "$PEER_LIMIT_PER_TORRENT" \
  --argjson speed_up "$SPEED_LIMIT_UP" \
  --argjson speed_enabled "$SPEED_LIMIT_UP_ENABLED" \
  --argjson start_added_torrents "$START_ADDED_TORRENTS" \
  --argjson utp_enabled "$UTP_ENABLED" \
  '
  .["download-dir"] = $download |
  .["rpc-username"] = $user |
  .["rpc-password"] = $pass |
  .["dht-enabled"] = $dht |
  .["peer-port"] = $peer_port |
  .["cache-size-mb"] = $cache |
  .["watch-dir-enabled"] = $watch_enabled |
  .["watch-dir"] = $watch |
  .["rename-partial-files"] = $rename_partial |
  .["pex-enabled"] = $pex |
  .["ratio-limit"] = $ratio |
  .["ratio-limit-enabled"] = $ratio_enabled |
  .["peer-limit-global"] = $peer_global |
  .["peer-limit-per-torrent"] = $peer_torrent |
  .["speed-limit-up"] = $speed_up |
  .["speed-limit-up-enabled"] = $speed_enabled |
  .["trash-original-torrent-files"] = true |
  .["download-queue-enabled"] = false |
  .["port-forwarding-enabled"] = false |
  .["utp-enabled"] = $utp_enabled |
  .["encryption"] = 2 |
  .["rpc-whitelist-enabled"] = false |
  .["rpc-host-whitelist-enabled"] = false |
  .["message-level"] = 1 |
  .["start-added-torrents"] = $start_added_torrents
  ' \
  "$SETTINGS_FILE" > "$tmp"

mv "$tmp" "$SETTINGS_FILE"

echo "Starting Transmission..."

exec transmission-daemon \
  --foreground \
  --config-dir "$CONFIG_DIR"
