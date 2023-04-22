#!/usr/bin/env bash

BORDER_CONFIG="$HOME/.config/i3/config.d/i3_window.config"
COL_EDGE_BORDER=$(awk '$1~/hide_edge_borders/ {print NR}' $BORDER_CONFIG)

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_border_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [show_both_edge]: show both top/bottom and left/right borders"
    echo "  [hide_both_edge]: hide both top/bottom and left/right borders"
    echo "  [hide_both_edge_if_only_one]: if there is only one window, hide both borders"
    echo "  [hide_both_edge_if_no_outer_gaps]: if there is no outer gap, hide both borders"
}

border_operation () {
    case $1 in
        "show_both_edge")
            sed -i "$COL_EDGE_BORDER s/.*/hide_edge_borders none/" $BORDER_CONFIG
            ;;
        "hide_both_edge")
            sed -i "$COL_EDGE_BORDER s/.*/hide_edge_borders both/" $BORDER_CONFIG
            ;;
        "hide_vertical_edge")
            sed -i "$COL_EDGE_BORDER s/.*/hide_edge_borders vertical/" $BORDER_CONFIG
            ;;
        "hide_horizontal_edge")
            sed -i "$COL_EDGE_BORDER s/.*/hide_edge_borders horizontal/" $BORDER_CONFIG
            ;;
        "hide_both_edge_if_only_one")
            sed -i "$COL_EDGE_BORDER s/.*/hide_edge_borders smart/" $BORDER_CONFIG
            ;;
        "hide_both_edge_if_no_gaps")
            sed -i "$COL_EDGE_BORDER s/.*/hide_edge_borders smart_no_gaps/" $BORDER_CONFIG
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
    # Send notification
    notify-send -u low "i3 Border Operator" "Default border_option is set to $1"
    # Reload
    i3-msg reload
}

# Main
border_operation $1
