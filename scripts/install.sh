#!/usr/bin/env bash
set -euo pipefail

REPO="${TUNNELX_REPO:-}"
INSTALL_DIR="${TUNNELX_INSTALL_DIR:-$HOME/.local/bin}"

if [[ -z "$REPO" ]]; then
  echo "Usage:"
  echo "TUNNELX_REPO=username/TunnelX bash install.sh"
  exit 1
fi

if [[ ! "$REPO" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
  echo "Invalid GitHub repository. Use username/repository."
  exit 1
fi

case "$(uname -s)" in
  Linux) ;;
  *) echo "TunnelX installer currently supports Linux only."; exit 1 ;;
esac

case "$(uname -m)" in
  x86_64|amd64) ASSET="tunnelx-linux-amd64" ;;
  aarch64|arm64) ASSET="tunnelx-linux-arm64" ;;
  *) echo "Unsupported CPU architecture: $(uname -m)"; exit 1 ;;
esac

if ! command -v curl >/dev/null 2>&1; then
  echo "Please install curl first."
  exit 1
fi

if ! command -v tar >/dev/null 2>&1; then
  echo "Please install tar first."
  exit 1
fi

API_URL="https://api.github.com/repos/${REPO}/releases/latest"
DOWNLOAD_URL="$(curl -fsSL "$API_URL" | grep -oE '"browser_download_url":[[:space:]]*"[^"]*' | cut -d '"' -f 4 | grep "/${ASSET}$" | head -n 1 || true)"

if [[ -z "$DOWNLOAD_URL" ]]; then
  echo "No published release asset found: $ASSET"
  echo "Publish a GitHub Release containing this binary first."
  exit 1
fi

mkdir -p "$INSTALL_DIR"
TMP_FILE="$(mktemp)"
trap 'rm -f "$TMP_FILE"' EXIT

echo "Downloading $ASSET ..."
curl -fL "$DOWNLOAD_URL" -o "$TMP_FILE"
install -m 0755 "$TMP_FILE" "$INSTALL_DIR/tunnelx"

echo "TunnelX installed to: $INSTALL_DIR/tunnelx"
echo "Check installation with:"
echo "$INSTALL_DIR/tunnelx -h"
