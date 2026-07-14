#!/bin/bash
set -euo pipefail

MANAGED_DIR="/Library/Application Support/ClaudeCode"
MANAGED_FILE="$MANAGED_DIR/managed-settings.json"
BACKUP_FILE="$MANAGED_DIR/managed-settings.json.bak.$(date +%Y%m%d%H%M%S)"

echo "== Claude Code managed settings installer (macOS) =="

if [[ $EUID -eq 0 ]]; then
  echo "Don't run this script itself with sudo — it will call sudo internally when needed."
  exit 1
fi

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This installer targets macOS. Detected OS: $(uname -s)."
  echo "Use install-linux.sh on Linux/WSL2, or install-windows.ps1 on native Windows."
  exit 1
fi

if ! command -v claude >/dev/null 2>&1; then
  echo "Claude Code not found on PATH. Install it first: npm install -g @anthropic-ai/claude-code"
  exit 1
fi

echo "Creating managed settings directory (requires admin password)..."
sudo mkdir -p "$MANAGED_DIR"

if [[ -f "$MANAGED_FILE" ]]; then
  echo "Existing managed-settings.json found — backing it up to:"
  echo "  $BACKUP_FILE"
  sudo cp "$MANAGED_FILE" "$BACKUP_FILE"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Copying managed-settings.json from repository..."
sudo cp "$SCRIPT_DIR/managed-settings.json" "$MANAGED_FILE"


echo "Validating JSON..."
if ! python3 -m json.tool "$MANAGED_FILE" > /dev/null; then
  echo "ERROR: written file is not valid JSON. Restoring previous state if a backup exists."
  if [[ -f "$BACKUP_FILE" ]]; then
    sudo cp "$BACKUP_FILE" "$MANAGED_FILE"
  else
    sudo rm -f "$MANAGED_FILE"
  fi
  exit 1
fi

echo "Locking down file permissions..."
sudo chown root:wheel "$MANAGED_FILE"
sudo chmod 644 "$MANAGED_FILE"

echo ""
echo "Done. Managed settings installed at:"
echo "  $MANAGED_FILE"
echo ""
echo "Next: open a Claude Code session (claude) in any project and run /permissions"
echo "to confirm the managed deny rules are listed, then run /sandbox to confirm"
echo "the sandbox is active."
