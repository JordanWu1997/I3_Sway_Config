#!/usr/bin/env bash
# ~/.config/sway/script/sway_window_switcher.sh
# Replacement for `rofi -show window` / `rofi -show windowcd` on sway.
# rofi's X11 window modi enumerate X windows, so under sway they only list XWayland
# clients. This builds the list from the sway tree (native Wayland + XWayland windows).
#
# Usage: sway_window_switcher.sh all       # every window on every workspace
#        sway_window_switcher.sh same_app  # windows sharing the focused window's app_id/class
set -euo pipefail

MODE="${1:-all}"
ROFI_CONFIG="$HOME/.config/rofi/config_singlecol.rasi"

TREE=$(swaymsg -t get_tree -r)
FOCUSED_APP=$(jq -r '.. | select(.focused? == true) | (.app_id // .window_properties.class // "")' <<<"$TREE")

# One line per window: "<con_id>\t<workspace>  <app>  <title>"
LIST=$(jq -r --arg mode "$MODE" --arg app "$FOCUSED_APP" '
    def windows: recurse(.nodes[]?, .floating_nodes[]?) | select(.pid? and (.type == "con" or .type == "floating_con"));
    .nodes[] | .nodes[] | select(.type == "workspace") as $ws
    | ($ws | windows)
    | (.app_id // .window_properties.class // "?") as $a
    | select($mode != "same_app" or $a == $app)
    | "\(.id)\t\($ws.name | sub("^[0-9]+:"; ""))  \($a)  \(.name // "")"
' <<<"$TREE")

[ -n "$LIST" ] || { notify-send -u low "Window switcher" "No window to switch to"; exit 0; }

ROFI_ARGS=(-dmenu -i -p "window" -format i)
[ -f "$ROFI_CONFIG" ] && ROFI_ARGS+=(-config "$ROFI_CONFIG")
INDEX=$(cut -f2- <<<"$LIST" | rofi "${ROFI_ARGS[@]}") || exit 0
CON_ID=$(sed -n "$((INDEX + 1))p" <<<"$LIST" | cut -f1)
[ -n "$CON_ID" ] && swaymsg "[con_id=$CON_ID] focus" >/dev/null
