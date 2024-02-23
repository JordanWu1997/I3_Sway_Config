#!/bin/bash

ICON="$HOME/.config/i3/share/32x32/keyboard.png"

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_keyboard_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [speed_up_repeat_key_rate]"
    echo "  [restore_repeat_key_rate]"
    echo "  [map_capslock_to_ctrl]"
    echo "  [swap_capslock_with_ctrl]"
    echo "  [restore_capslock]"
    echo "  [default]"
    echo
}

# Operation
RF_device_operation () {
    case $1 in
        'speed_up_repeat_key_rate')
            xset r rate 300 40
            notify-send -u low "Keyboard Mode" "Speed up repeat key rate (300/40)" --icon=${ICON}
            ;;
        'restore_repeat_key_rate')
            xset r rate 660 25
            notify-send -u low "Keyboard Mode" "Reset repeat key rate (600/25)" --icon=${ICON}
            ;;
        'map_capslock_to_ctrl')
            setxkbmap -option "ctrl:nocaps"
            notify-send -u low "Keyboard Mode" "Map Caplock to Ctrl" --icon=${ICON}
            ;;
        'swap_capslock_with_ctrl')
            setxkbmap -option "ctrl:swapcaps"
            notify-send -u low "Keyboard Mode" "Swap Caplock with Ctrl" --icon=${ICON}
            ;;
        'restore_capslock')
            setxkbmap -option "ctrl:aa_ctrl"
            notify-send -u low "Keyboard Mode" "Restore Caplock" --icon=${ICON}
            ;;
        'default')
            xset r rate 300 40
            setxkbmap -option "ctrl:nocaps"
            notify-send -u low "Keyboard Mode" "Speed up repeat key rate and map Caplock to Ctrl" --icon=${ICON}
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main
RF_device_operation $1
