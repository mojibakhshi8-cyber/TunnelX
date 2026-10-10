#!/usr/bin/env bash
set -euo pipefail

REPO="mojibakhshi8-cyber/TunnelX"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
SHARE_DIR="${SHARE_DIR:-$HOME/.local/share/tunnelx}"

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "Error: TunnelX supports Linux only." >&2
  exit 1
fi

case "$(uname -m)" in
  x86_64|amd64) ASSET="tunnelx-linux-amd64" ;;
  aarch64|arm64) ASSET="tunnelx-linux-arm64" ;;
  *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

command -v curl >/dev/null || { echo "Please install curl first." >&2; exit 1; }

API="https://api.github.com/repos/${REPO}/releases/latest"
RELEASE="$(curl -fsSL "$API")"

URL="$(printf '%s\n' "$RELEASE" |
  grep -oE '"browser_download_url":[[:space:]]*"[^"]*' |
  cut -d '"' -f 4 | grep "/${ASSET}$" | head -n 1 || true)"

if [[ -z "$URL" ]]; then
  echo "No release asset found: $ASSET" >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Downloading $ASSET..."
curl -fL --retry 3 "$URL" -o "$TMP/tunnelx"
chmod 0755 "$TMP/tunnelx"

mkdir -p "$BIN_DIR" "$SHARE_DIR"
install -m 0755 "$TMP/tunnelx" "$BIN_DIR/tunnelx"

# Download the setup menu from the same repository branch.
curl -fsSL \
  "https://raw.githubusercontent.com/${REPO}/main/scripts/tunnelx-menu.sh" \
  -o "$TMP/tunnelx-menu.sh"
install -m 0755 "$TMP/tunnelx-menu.sh" "$BIN_DIR/tunnelx-menu"

echo
echo "TunnelX installed."
echo "Binary: $BIN_DIR/tunnelx"
echo "Setup menu: $BIN_DIR/tunnelx-menu"
echo "Run the menu with: $BIN_DIR/tunnelx-menu"
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
  echo "Add to PATH: export PATH=\"$BIN_DIR:\$PATH\""
fi
