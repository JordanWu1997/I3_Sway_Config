#!/bin/bash

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
    echo "  [send_capslock_key]"
    echo "  [send_numlock_key]"
    echo "  [speed_up_repeat_key_rate]"
    echo "  [restore_repeat_key_rate]"
    echo "  [map_capslock_to_ctrl]"
    echo "  [swap_capslock_with_ctrl]"
    echo "  [restore_capslock]"
    echo "  [customize_tex_shinobi]"
    echo "  [default]"
    echo
}

# Operation
keyboard_operation () {
    ICON="$HOME/.config/i3/share/64x64/keyboard.png"
    case $1 in
        'send_capslock_key')
            xdotool key Caps_Lock
            notify-send -u low "Keyboard Mode" "Capslock key is pressed" --icon=${ICON}
            ;;
        'send_numlock_key')
            xdotool key Num_Lock
            notify-send -u low "Keyboard Mode" "Numlock key is pressed" --icon=${ICON}
            ;;
        'speed_up_repeat_key_rate')
            xset r rate 250 50
            notify-send -u low "Keyboard Mode" "Speed up repeat key rate (250/50)" --icon=${ICON}
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
        'customize_tex_shinobi')
            DEVICE='USB-HID Keyboard Mouse'
            xinput set-prop "${DEVICE}" 315 0
            xinput set-prop "${DEVICE}" 329 0 1 0
            xinput set-prop "${DEVICE}" 326 0.45
            ;;
        'restore_tex_shinobi')
            DEVICE='USB-HID Keyboard Mouse'
            xinput set-prop "${DEVICE}" 315 0
            xinput set-prop "${DEVICE}" 329 1 0 0
            xinput set-prop "${DEVICE}" 326 0.0
            ;;
        'default')
            xset r rate 250 50
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
keyboard_operation $1
