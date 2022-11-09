#!/usr/bin/env bash

BORDER_CONFIG="$HOME/.config/i3/config.d/i3_window.config"
COL_EDGE_BORDER=$(awk '$1~/hide_edge_borders/ {print NR}' $BORDER_CONFIG)

border_operation () {
    case $1 in
        "show_both_edge")
            sed -i "$COL_EDGE_BORDER s/.*/hide_edge_borders none/" $BORDER_CONFIG
            ;;
        "hide_both_edge")
            sed -i "$COL_EDGE_BORDER s/.*/hide_edge_borders both/" $BORDER_CONFIG
            ;;
        "hide_both_edge_if_only_one")
            sed -i "$COL_EDGE_BORDER s/.*/hide_edge_borders smart/" $BORDER_CONFIG
            ;;
        "hide_both_edge_if_no_gaps")
            sed -i "$COL_EDGE_BORDER s/.*/hide_edge_borders smart_no_gaps/" $BORDER_CONFIG
            ;;
    esac
}

# Main
border_operation $1
i3-msg reload
