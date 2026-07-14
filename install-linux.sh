#!/bin/bash
set -euo pipefail

MANAGED_DIR="/etc/claude-code"
MANAGED_FILE="$MANAGED_DIR/managed-settings.json"
BACKUP_FILE="$MANAGED_DIR/managed-settings.json.bak.$(date +%Y%m%d%H%M%S)"

echo "== Claude Code managed settings installer (Linux / WSL2) =="

if [[ $EUID -eq 0 ]]; then
  echo "Don't run this script itself with sudo — it will call sudo internally when needed."
  exit 1
fi

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "This installer targets Linux/WSL2. Detected OS: $(uname -s)."
  echo "Use install-macos.sh on macOS, or install-windows.ps1 on native Windows."
  exit 1
fi

if ! command -v claude >/dev/null 2>&1; then
  echo "Claude Code not found on PATH. Install it first: npm install -g @anthropic-ai/claude-code"
  exit 1
fi

if ! command -v bwrap >/dev/null 2>&1; then
  echo ""
  echo "WARNING: bubblewrap (bwrap) was not found on PATH."
  echo "The sandbox block in this policy depends on bubblewrap for OS-level enforcement."
  echo "Without it, Claude Code's /sandbox will report the sandbox as unavailable and"
  echo "sandboxed Bash commands may fail or fall back to running unsandboxed, depending"
  echo "on allowUnsandboxedCommands."
  echo "Install it first, e.g.:"
  echo "  Debian/Ubuntu: sudo apt-get install bubblewrap"
  echo "  Fedora:        sudo dnf install bubblewrap"
  echo "  Arch:          sudo pacman -S bubblewrap"
  read -p "Continue installing the policy anyway? [y/N] " ans
  if [[ ! "$ans" =~ ^[Yy]$ ]]; then
    echo "Aborted. Install bubblewrap and re-run this script."
    exit 1
  fi
fi

echo "Creating managed settings directory (requires sudo)..."
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
sudo chown root:root "$MANAGED_FILE"
sudo chmod 644 "$MANAGED_FILE"

echo ""
echo "Done. Managed settings installed at:"
echo "  $MANAGED_FILE"
echo ""
echo "Next: open a Claude Code session (claude) in any project and run /permissions"
echo "to confirm the managed deny rules are listed, then run /sandbox to confirm"
echo "the sandbox is active (not just configured)."
