#!/usr/bin/env bash
set -euo pipefail

# Toggle Discord mute by focusing a Discord window, sending Ctrl+Shift+M, then
# restoring the previously-focused container.

SWAYMSG=${SWAYMSG:-swaymsg}
JQ_BIN=${JQ_BIN:-jq}

if ! command -v "$SWAYMSG" >/dev/null; then
  echo "swaymsg not found" >&2
  exit 1
fi

if ! command -v "$JQ_BIN" >/dev/null; then
  notify-send 'Discord mute toggle' 'jq is required for discord-toggle-mute.sh'
  exit 1
fi

current_id=$($SWAYMSG -r -t get_tree | "$JQ_BIN" '.. | objects | select(.focused? == true).id' | head -n1)
current_id=${current_id:-}

focus_cmds=(
  '[app_id="vesktop"] focus'
  '[class="vesktop"] focus'
  '[app_id="discord"] focus'
  '[class="discord"] focus'
)

focused=false
for cmd in "${focus_cmds[@]}"; do
  if $SWAYMSG -t command "$cmd" | "$JQ_BIN" -e '.[0].success' >/dev/null 2>&1; then
    focused=true
    break
  fi
done

if ! $focused; then
  notify-send 'Discord mute toggle' 'No Discord window to target'
  exit 0
fi

if command -v wtype >/dev/null; then
  wtype -M ctrl -M shift m -m shift -m ctrl
elif command -v ydotool >/dev/null; then
  ydotool key 29:1 42:1 50:1 50:0 42:0 29:0
else
  notify-send 'Discord mute toggle' 'Install wtype or ydotool to send shortcuts'
fi

if [[ -n "$current_id" ]]; then
  $SWAYMSG -t command "[con_id=$current_id] focus" >/dev/null 2>&1 || true
fi
