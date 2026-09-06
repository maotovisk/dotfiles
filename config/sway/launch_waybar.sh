#!/usr/bin/env bash
set -euo pipefail

CONFIG="$HOME/.config/waybar/config-sway.jsonc"
STYLE="$HOME/.config/waybar/style.css"

# Restart Waybar cleanly so reloading the config works reliably
pkill -x waybar >/dev/null 2>&1 || true

exec waybar -c "$CONFIG" -s "$STYLE"
