#!/usr/bin/env bash

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_xsslock_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [default]: start xsslock with default wallpaper"
    echo "  [current_default_wallpaper]: start xsslock with current default wallpaper"
    echo "  [current_wallpaper]: start xsslock with current wallpaper"
    echo "  [current_desktop]: start xsslock with current desktop screenshot"
}

xsslock_operation () {
    case $1 in
        "default")
            i3-msg exec "xss-lock -v --transfer-sleep-lock -- i3_i3lock_operator.sh current_default"
            ;;
        "current_default_wallpaper")
            i3-msg exec "xss-lock -v --transfer-sleep-lock -- i3_i3lock_operator.sh current_default_wallpaper"
            ;;
        "current_wallpaper")
            i3-msg exec "xss-lock -v --transfer-sleep-lock -- i3_i3lock_operator.sh current_wallpaper"
            ;;
        "current_desktop")
            i3-msg exec "xss-lock -v --transfer-sleep-lock -- i3_i3lock_operator.sh current_desktop"
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main
killall xss-lock
xsslock_operation "$@"
