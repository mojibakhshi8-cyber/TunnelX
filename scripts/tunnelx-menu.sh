#!/usr/bin/env bash
set -euo pipefail

BIN="${TUNNELX_BIN:-$HOME/.local/bin/tunnelx}"
CONFIG_DIR="${TUNNELX_CONFIG_DIR:-$HOME/.config/tunnelx}"
CONFIG="$CONFIG_DIR/config"

mkdir -p "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"

pause() {
  read -r -p "Press Enter to continue..." _
}

ask() {
  local prompt="$1" value
  read -r -p "$prompt" value
  printf '%s' "$value"
}

while true; do
  clear 2>/dev/null || true
  echo "================================"
  echo "        TunnelX Setup"
  echo "       TCP Tunnel Manager"
  echo "================================"
  echo "1) Configure and start Server"
  echo "2) Configure and start Client"
  echo "3) Check binary"
  echo "4) Show saved configuration"
  echo "5) Exit"
  echo

  read -r -p "Select an option: " choice

  case "$choice" in
    1)
      [[ -x "$BIN" ]] || {
        echo "TunnelX binary not found: $BIN"
        pause
        continue
      }

      listen="$(ask 'Server listen address (e.g. :443): ')"
      target="$(ask 'Target address on server (e.g. 127.0.0.1:8080): ')"
      token="$(ask 'Shared token: ')"
      cert="$(ask 'TLS certificate file path: ')"
      key="$(ask 'TLS private key file path: ')"

      if [[ -z "$listen" || -z "$target" || -z "$token" || -z "$cert" || -z "$key" ]]; then
        echo "All fields are required."
        pause
        continue
      fi

      chmod 600 "$key" 2>/dev/null || true
      printf 'mode=server\nlisten=%s\ntarget=%s\n' "$listen" "$target" > "$CONFIG"
      chmod 600 "$CONFIG"

      echo "Starting TunnelX server..."
      "$BIN" -mode server -listen "$listen" -target "$target" \
        -token "$token" -cert "$cert" -key "$key"
      pause
      ;;
    2)
      [[ -x "$BIN" ]] || {
        echo "TunnelX binary not found: $BIN"
        pause
        continue
      }

      listen="$(ask 'Local listen address (e.g. 127.0.0.1:9000): ')"
      remote="$(ask 'Remote server address (e.g. example.com:443): ')"
      token="$(ask 'Shared token: ')"
      ca="$(ask 'Trusted CA/certificate PEM path: ')"
      server_name="$(ask 'TLS server name: ')"

      if [[ -z "$listen" || -z "$remote" || -z "$token" || -z "$ca" || -z "$server_name" ]]; then
        echo "All fields are required."
        pause
        continue
      fi

      printf 'mode=client\nlisten=%s\nremote=%s\n' "$listen" "$remote" > "$CONFIG"
      chmod 600 "$CONFIG"

      echo "Starting TunnelX client..."
      "$BIN" -mode client -listen "$listen" -remote "$remote" \
        -token "$token" -ca "$ca" -server-name "$server_name"
      pause
      ;;
    3)
      if [[ -x "$BIN" ]]; then
        "$BIN" -h || true
      else
        echo "TunnelX binary not found: $BIN"
      fi
      pause
      ;;
    4)
      if [[ -f "$CONFIG" ]]; then
        cat "$CONFIG"
      else
        echo "No saved configuration yet."
      fi
      echo "Note: the shared token is not saved in this file."
      pause
      ;;
    5)
      exit 0
      ;;
    *)
      echo "Invalid option."
      pause
      ;;
  esac
done
