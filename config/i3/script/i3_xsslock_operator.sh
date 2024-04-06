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
    echo "  [current_default]: start xsslock with current default wallpaper"
    echo "  [current]: start xsslock with current wallpaper"
}

xsslock_operation () {
    case $1 in
        "default")
            i3-msg exec "xss-lock -v --transfer-sleep-lock -- i3_i3lock_operator.sh current_default"
            ;;
        "current_default")
            i3-msg exec "xss-lock -v --transfer-sleep-lock -- i3_i3lock_operator.sh current_default"
            ;;
        "current")
            i3-msg exec "xss-lock -v --transfer-sleep-lock -- i3_i3lock_operator.sh current"
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
