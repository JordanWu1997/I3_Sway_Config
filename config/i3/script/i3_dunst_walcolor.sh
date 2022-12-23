#!/usr/bin/env bash

DUNST_CONFIG="$HOME/.config/dunst/dunstrc"
BG_COLOR_COL=$(awk '$0~/background/ {print NR}' $DUNST_CONFIG)
FG_COLOR_COL=$(awk '$0~/foreground/ {print NR}' $DUNST_CONFIG)
FRAME_COLOR_COL=$(awk '$0~/frame_color/ {print NR}' $DUNST_CONFIG)
FRAME_BORDER_WIDTH_COL=$(awk '$0~/frame_width =/ {print NR}' $DUNST_CONFIG)
SEPARATOR_BORDER_WIDTH_COL=$(awk '$0~/separator_height =/ {print NR}' $DUNST_CONFIG)

I3_CONFIG="$HOME/.config/i3/config"
BORDER_WIDTH=$(awk '$0~/default_border_width/ {print $3}' $I3_CONFIG)

WAL_COLOR="$HOME/.cache/wal/colors"
WAL_COLOR3="$(awk 'NR==4' $WAL_COLOR)"
WAL_COLOR12="$(awk 'NR==13' $WAL_COLOR)"
WAL_COLOR15="$(awk 'NR==16' $WAL_COLOR)"

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_dunst_walcolor.sh [options]"
    echo ""
    echo "OPTIONS"
    echo "  [load_wal_color]: Load wal color to dunst"
    echo "  [load_i3_border_width]: Load border width to dunst"
    echo "  [reload]: Reload dunst"
    echo "  [reload_all]: Load wal color and border width to dunst and reload dunst"
}

load_wal_border_width () {
    # Separator border width
    sed -i "$SEPARATOR_BORDER_WIDTH_COL s/.*/    separator_height \= $BORDER_WIDTH/" "$DUNST_CONFIG"
    # Frame border width
    sed -i "$FRAME_BORDER_WIDTH_COL s/.*/    frame_width \= $BORDER_WIDTH/" "$DUNST_CONFIG"
}

load_wal_color () {
    # Background: wal color3 (Yellow)
    for col in $BG_COLOR_COL; do
        sed -i "$col s/.*/    background \= \"$WAL_COLOR3\"/" "$DUNST_CONFIG"
    done
    # Foreground: wal color15 (White)
    for col in $FG_COLOR_COL; do
        sed -i "$col s/.*/    foreground \= \"$WAL_COLOR15\"/" "$DUNST_CONFIG"
    done
    # Frame: wal color12 (Magenta)
    for col in $FRAME_COLOR_COL; do
        sed -i "$col s/.*/    frame_color \= \"$WAL_COLOR12\"/" "$DUNST_CONFIG"
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
        "load_i3_border_width")
            load_wal_border_width
            ;;
        "reload")
            reload_dunst
            ;;
        "reload_all")
            load_wal_color
            load_wal_border_width
            reload_dunst
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main
dunst_operation $1
