#!/bin/bash
set -euo pipefail

MANAGED_DIR="/Library/Application Support/ClaudeCode"
MANAGED_FILE="$MANAGED_DIR/managed-settings.json"

echo "== Claude Code managed settings rollback (macOS) =="

if [[ $EUID -eq 0 ]]; then
  echo "Don't run this script itself with sudo — it will call sudo internally when needed."
  exit 1
fi

if [[ ! -d "$MANAGED_DIR" ]]; then
  echo "No managed settings directory found. Nothing to roll back."
  exit 0
fi

# Find the most recent backup, if any
LATEST_BACKUP=$(ls -t "$MANAGED_DIR"/managed-settings.json.bak.* 2>/dev/null | head -n 1 || true)

if [[ -n "${LATEST_BACKUP:-}" ]]; then
  echo "Found a prior backup:"
  echo "  $LATEST_BACKUP"
  read -p "Restore this backup instead of just removing the hardened settings? [y/N] " ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    sudo cp "$LATEST_BACKUP" "$MANAGED_FILE"
    echo "Restored previous managed-settings.json."
    exit 0
  fi
fi

if [[ -f "$MANAGED_FILE" ]]; then
  echo "Removing managed-settings.json..."
  sudo rm -f "$MANAGED_FILE"
  echo "Removed. Claude Code will no longer apply the hardened org policy on this machine."
else
  echo "No managed-settings.json found. Nothing to remove."
fi

echo ""
echo "Note: backup files (if any) were left in place at:"
echo "  $MANAGED_DIR"
echo "Delete them manually if you no longer need them."
