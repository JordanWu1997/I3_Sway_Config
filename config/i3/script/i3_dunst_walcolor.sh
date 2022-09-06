#!/usr/bin/env bash

DUNST_CONFIG="$HOME/.config/dunst/dunstrc"
WAL_COLOR="$HOME/.cache/wal/colors"

BG_COLOR_COL=$(awk '$0~/background/ {print NR}' $DUNST_CONFIG)
FG_COLOR_COL=$(awk '$0~/foreground/ {print NR}' $DUNST_CONFIG)
FRAME_COLOR_COL=$(awk '$0~/frame_color/ {print NR}' $DUNST_CONFIG)

WAL_COLOR3="$(awk 'NR==4' $WAL_COLOR)"
WAL_COLOR12="$(awk 'NR==13' $WAL_COLOR)"
WAL_COLOR15="$(awk 'NR==16' $WAL_COLOR)"

load_wal_color () {
    # Background: wal color3 (Yellow)
    for col in $BG_COLOR_COL; do
        sed -i "$col s/.*/\tbackground \= \"$WAL_COLOR3\"/" "$DUNST_CONFIG"
    done
    # Foreground: wal color15 (White)
    for col in $FG_COLOR_COL; do
        sed -i "$col s/.*/\tforeground \= \"$WAL_COLOR15\"/" "$DUNST_CONFIG"
    done
    # Frame: wal color12 (Magenta)
    for col in $FRAME_COLOR_COL; do
        sed -i "$col s/.*/\tframe_color \= \"$WAL_COLOR12\"/" "$DUNST_CONFIG"
    done
}

reload_dunst () {
    # Reload dunst
    pidof dunst && killall dunst
    dunst > /dev/null 2>&1 &
    sleep 1
    notify-send -u low "Dunst" "Dunst is up and running"
}

dunst_operation () {
    case $1 in
        "load_wal_color")
            load_wal_color
            ;;
        "reload")
            reload_dunst
            ;;
        "both")
            load_wal_color
            reload_dunst
            ;;
        *)
            echo Available option: load_wal_color/reload/both
            ;;
    esac
}

# Main
dunst_operation $1
