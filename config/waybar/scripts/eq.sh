#!/usr/bin/env bash
# Animated now-playing indicator for Waybar.
# Streams JSON lines while a player is active; idle when nothing plays.
# Frames are block glyphs so they render in CaskaydiaCove Nerd Font Mono.

set -u

frames=(
    "▁▃▂" "▃▂▄" "▂▄▅" "▄▅▃"
    "▅▃▆" "▃▆▄" "▆▄▂" "▄▂▃"
)

i=0
while :; do
    status=$(playerctl status 2>/dev/null)

    if [ "$status" = "Playing" ]; then
        printf '{"text":"%s","class":"playing"}\n' "${frames[i % ${#frames[@]}]}"
        i=$((i + 1))
        sleep 0.16
    elif [ -n "$status" ]; then
        printf '{"text":"󰏤","class":"paused"}\n'
        sleep 0.5
    else
        printf '{"text":"","class":"idle"}\n'
        sleep 1
    fi
done
