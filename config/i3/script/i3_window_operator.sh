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
    echo "  [float_then_fullscreen]: make current window floating and resize to monitor size"
    echo "  [center_current]: make current window floating and move to center of monitor"
    echo "  [toggle_sticky_current]: toggle current window stickiness"
    echo "  [float_all]: make all windows in current workspace floating"
    echo "  [tile_all]: make all windows in current workspace tiled"
    echo "  [hide_all]: send all windows to scratchpad"
    echo "  [show_all_scratchpad]: show all windows in scratchpad"
    echo "  [hide_all_floating]: send all floating windows to scratchpad"
}

window_operation () {
    case $1 in
        "float_then_fullscreen")
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
        "center_current")
            # Floating
            i3-msg "floating enable"
            # Center window
            i3-msg "move position center"
            ;;
        "toggle_sticky_current")
            # Get current window ID
            CURRENT_WINDOW_ID=$(xdotool getwindowfocus)
            # Get current window sticky status
            CURRENT_STICKY_STATUS=$(i3-msg -t get_tree | tr \} "\n" | grep ${CURRENT_WINDOW_ID} -A1 | tr \, "\n" | grep "\"sticky\"\:" | cut -d: -f2)
            if [[ ${CURRENT_STICKY_STATUS} == "true" ]]; then
                i3-msg "sticky disable"
                i3-msg 'title_format "%title"'
                notify-send -u low "i3 Window Manager" "Focused window is NO LONGER sticky"
            elif [[ ${CURRENT_STICKY_STATUS} == "false" ]]; then
                i3-msg "sticky enable"
                i3-msg 'title_format "%title [STICKY]"'
                notify-send -u low "i3 Window Manager" "Focused window is NOW sticky"
            else
                notify-send -u low "i3 Window Manger" "Focused window has UNKNOWN sticky status: ${CURRENT_STICKY_STATUS}"
            fi
            ;;
        "float_all")
            i3-msg [workspace='__focused__'] floating enable
            ;;
        "tile_all")
            i3-msg [workspace='__focused__'] floating disable
            ;;
        "hide_all")
            i3-msg [workspace='__focused__'] floating enable
            i3-msg [floating] move scratchpad
            ;;
        "show_all_scratchpad")
            i3-msg [all] scratchpad show
            ;;
        "hide_all_floating")
            i3-msg [floating] move scratchpad
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
