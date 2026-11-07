#!/usr/bin/env bash
# Ported from i3_border_operator.sh for sway.
# Replaced i3-isms:
#   ~/.config/i3/config.d/i3_window.config -> ~/.config/sway/config.d/sway_window.config
#   i3-msg reload                          -> swaymsg reload
# sway supports hide_edge_borders none|vertical|horizontal|both|smart|smart_no_gaps,
# so all operations are kept. Edited line: the first line whose first field
# contains "hide_edge_borders" (^hide_edge_borders <value>).

BORDER_CONFIG="$HOME/.config/sway/config.d/sway_window.config"
COL_EDGE_BORDER=$(awk '$1~/hide_edge_borders/ {print NR; exit}' "$BORDER_CONFIG")
ICON="$HOME/.config/i3/share/64x64/window.png"

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  sway_border_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [show_both_edge]: show both top/bottom and left/right borders"
    echo "  [hide_both_edge]: hide both top/bottom and left/right borders"
    echo "  [hide_vertical_edge]: hide left/right borders"
    echo "  [hide_horizontal_edge]: hide top/bottom borders"
    echo "  [hide_both_edge_if_only_one]: if there is only one window, hide both borders"
    echo "  [hide_both_edge_if_no_outer_gaps]: if there are no outer gaps, hide both borders"
}

border_operation () {
    local value
    case $1 in
        "show_both_edge") value=none ;;
        "hide_both_edge") value=both ;;
        "hide_vertical_edge") value=vertical ;;
        "hide_horizontal_edge") value=horizontal ;;
        "hide_both_edge_if_only_one") value=smart ;;
        "hide_both_edge_if_no_outer_gaps") value=smart_no_gaps ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
    if [[ ! $COL_EDGE_BORDER =~ ^[0-9]+$ ]]; then
        notify-send -u critical "Sway Border Operator" "No hide_edge_borders line in $BORDER_CONFIG" --icon="${ICON}"
        exit 1
    fi
    sed -i "$COL_EDGE_BORDER s/.*/hide_edge_borders $value/" "$BORDER_CONFIG"
    # Send notification
    notify-send -u low "Sway Border Operator" "Default border_option is set to $1" --icon="${ICON}"
    # Reload
    swaymsg reload
}

# Main
border_operation "$1"
