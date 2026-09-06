#!/usr/bin/env bash
set -euo pipefail

HYPR_SOCK="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
GSL_SOCK="$XDG_RUNTIME_DIR/gslapper.sock"

STATIC_WALL="$HOME/.wallpapers/wpp3.jpg"
VIDEO_FILE="$HOME/.wallpapers/cat1080.mp4"

gaming=0

pause_video() {
    echo "pause" | nc -U "$GSL_SOCK" 2>/dev/null || true
}

resume_video() {
    echo "resume" | nc -U "$GSL_SOCK" 2>/dev/null || true
}

set_static_wall() {
    hyprctl hyprpaper preload "$STATIC_WALL" >/dev/null 2>&1
    hyprctl hyprpaper wallpaper DP-2,"$STATIC_WALL" >/dev/null 2>&1
}

restore_video_layer() {
    # gSlapper renders via layer-shell, so just resume it
    resume_video
}

any_fullscreen_on_dp2() {
  hyprctl clients -j | jq -e '
    .[] | select(
      (.fullscreen == true)
      and (.monitor == "DP-2")
    )
  ' >/dev/null
}

reconcile() {
    if any_fullscreen_on_dp2; then
        if [ "$gaming" -eq 0 ]; then
            gaming=1
            pause_video
            set_static_wall
        fi
    else
        if [ "$gaming" -eq 1 ]; then
            gaming=0
            restore_video_layer
        fi
    fi
}

reconcile

socat -U - UNIX-CONNECT:"$HYPR_SOCK" | while read -r line; do
  case "$line" in
    openwindow*|closewindow*|workspace*|activewindow*|windowtitle*)
      reconcile
      ;;
  esac
done

