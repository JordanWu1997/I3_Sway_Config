#!/usr/bin/env bash

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_window_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [floating_fullscreen]: make current window floating and resize to monitor size"
}

window_operation () {
    case $1 in
        'floating_fullscreen')
            # Get workspace width and height
            WIDTH=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused).rect.width')
            HEIGHT=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused).rect.height')
            # Get window border width
            I3_CONFIG="$HOME/.config/i3/config"
            BORDER_WIDTH=$(awk '$0~/default_border_width/ {print $3}' $I3_CONFIG)
            # Floating
            i3-msg "floating enable"
            i3-msg "border pixel ${BORDER_WIDTH}"
            # Fullscreen
            i3-msg "resize set width ${WIDTH} px height ${HEIGHT} px"
            i3-msg "move position center"
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main
window_operation $1
