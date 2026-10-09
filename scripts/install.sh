#!/usr/bin/env bash
set -euo pipefail

REPO="${TUNNELX_REPO:-}"
INSTALL_DIR="${TUNNELX_INSTALL_DIR:-$HOME/.local/bin}"
SHARE_DIR="${TUNNELX_SHARE_DIR:-$HOME/.local/share/tunnelx}"

if [[ -z "$REPO" || ! "$REPO" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
  echo "Usage: TUNNELX_REPO=username/repository bash install.sh"
  exit 1
fi

case "$(uname -s)" in
  Linux) ;;
  *) echo "Linux only."; exit 1 ;;
esac

case "$(uname -m)" in
  x86_64|amd64) ASSET="tunnelx-linux-amd64" ;;
  aarch64|arm64) ASSET="tunnelx-linux-arm64" ;;
  *) echo "Unsupported architecture: $(uname -m)"; exit 1 ;;
esac

command -v curl >/dev/null || { echo "Install curl first."; exit 1; }

API_URL="https://api.github.com/repos/${REPO}/releases/latest"
DOWNLOAD_URL="$(curl -fsSL "$API_URL" |
  grep -oE '"browser_download_url":[[:space:]]*"[^"]*' |
  cut -d '"' -f 4 | grep "/${ASSET}$" | head -n 1 || true)"

if [[ -z "$DOWNLOAD_URL" ]]; then
  echo "No published release asset found: $ASSET"
  echo "Publish a GitHub Release containing this binary first."
  exit 1
fi

mkdir -p "$INSTALL_DIR" "$SHARE_DIR"
TMP_FILE="$(mktemp)"
trap 'rm -f "$TMP_FILE"' EXIT

echo "Downloading $ASSET ..."
curl -fL "$DOWNLOAD_URL" -o "$TMP_FILE"
install -m 0755 "$TMP_FILE" "$INSTALL_DIR/tunnelx"

MENU_URL="https://raw.githubusercontent.com/${REPO}/main/scripts/tunnelx-menu.sh"
curl -fsSL "$MENU_URL" -o "$SHARE_DIR/tunnelx-menu.sh"
chmod 0755 "$SHARE_DIR/tunnelx-menu.sh"

cat > "$INSTALL_DIR/tunnelx-menu" <<LAUNCHER
#!/usr/bin/env bash
TUNNELX_BIN="$INSTALL_DIR/tunnelx" exec bash "$SHARE_DIR/tunnelx-menu.sh"
LAUNCHER
chmod 0755 "$INSTALL_DIR/tunnelx-menu"

echo
echo "TunnelX installed."
echo "Run the setup menu with:"
echo "$INSTALL_DIR/tunnelx-menu"
echo
echo "If needed, add $INSTALL_DIR to your PATH."
