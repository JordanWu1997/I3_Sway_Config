#!/usr/bin/env bash
# Ported from i3_gap_operator.sh for sway.
# Replaced i3-isms:
#   ~/.config/i3/config.d/i3_gap.config -> ~/.config/sway/config.d/sway_gap.config
#   i3-msg reload                       -> swaymsg reload
# sway supports smart_gaps on|off|inverse_outer, so all operations are kept.
# Edited line: the first line whose first field contains "smart_gaps"
# (i.e. ^smart_gaps ... or ^#smart_gaps ...).

GAP_CONFIG="$HOME/.config/sway/config.d/sway_gap.config"
COL_SMART_GAP=$(awk '$1~/smart_gaps/ {print NR; exit}' "$GAP_CONFIG")
ICON="$HOME/.config/i3/share/64x64/window.png"

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  sway_gap_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [smart_gaps_on]: enable smart gaps (i.e. disable gaps if there is only one window)"
    echo "  [smart_gaps_inverse_outer]: enable outer gaps if there is only one window"
    echo "  [smart_gaps_off]: disable smart gaps"
}

gap_operation () {
    case $1 in
        "smart_gaps_on"|"smart_gaps_inverse_outer"|"smart_gaps_off")
            if [[ ! $COL_SMART_GAP =~ ^[0-9]+$ ]]; then
                notify-send -u critical "Sway Gap Operator" "No smart_gaps line in $GAP_CONFIG" --icon="${ICON}"
                exit 1
            fi
            ;;
    esac
    case $1 in
        "smart_gaps_on")
            sed -i "$COL_SMART_GAP s/.*/smart_gaps on/" "$GAP_CONFIG"
            ;;
        "smart_gaps_inverse_outer")
            sed -i "$COL_SMART_GAP s/.*/smart_gaps inverse_outer/" "$GAP_CONFIG"
            ;;
        "smart_gaps_off")
            sed -i "$COL_SMART_GAP s/.*/\#smart_gaps on/" "$GAP_CONFIG"
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
    # Send notification
    notify-send -u low "Sway Gap Operator" "Default gap_option is set to $1" --icon="${ICON}"
    # Reload
    swaymsg reload
}

# Main
gap_operation "$1"
