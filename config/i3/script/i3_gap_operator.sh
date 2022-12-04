#!/usr/bin/env bash

GAP_CONFIG="$HOME/.config/i3/config.d/i3_gap.config"
COL_SMART_GAP=$(awk '$1~/smart_gaps/ {print NR}' $GAP_CONFIG)

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_gap_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [smart_gaps_on]: enable smart gaps (i.e. disable gaps if there is only one window)"
    echo "  [smart_gaps_inverse_outer]: enable outer gaps if there is only one window"
    echo "  [smart_gaps_off]: disable smart gaps"
}

gap_operation () {
    case $1 in
        "smart_gaps_on")
            sed -i "$COL_SMART_GAP s/.*/smart_gaps on/" $GAP_CONFIG
            ;;
        "smart_gaps_inverse_outer")
            sed -i "$COL_SMART_GAP s/.*/smart_gaps inverse_outer/" $GAP_CONFIG
            ;;
        "smart_gaps_off")
            sed -i "$COL_SMART_GAP s/.*/\#smart_gaps on/" $GAP_CONFIG
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
    i3-msg reload
}

# Main
gap_operation $1
