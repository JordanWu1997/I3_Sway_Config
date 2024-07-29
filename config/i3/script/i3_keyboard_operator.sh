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
    echo "  [restore_tex_shinobi]"
    echo "  [swap_backslash_with_backspace]"
    echo "  [restore_backslash_and_backspace]"
    echo "  [swap_escape_with_grave]"
    echo "  [restore_escape_and_grave]"
    echo "  [map_shift_escape_to_tilde]"
    echo "  [swap_escape_keybinding_with_grave_keybinding]"
    echo "  [default]"
    echo
}

# Operation
keyboard_operation () {
    ICON="$HOME/.config/i3/share/64x64/keyboard.png"
    case $1 in
        # Caps_Lock/Num_Lock
        'send_capslock_key')
            xdotool key Caps_Lock
            notify-send -u low "Keyboard Mode" "Capslock key is pressed" --icon=${ICON}
            ;;
        'send_numlock_key')
            xdotool key Num_Lock
            notify-send -u low "Keyboard Mode" "Numlock key is pressed" --icon=${ICON}
            ;;
        # For non-HHKB
        'map_capslock_to_ctrl')
            #setxkbmap -option "ctrl:nocaps"
            xmodmap -e 'keycode 66 = Control_L'
            notify-send -u low "Keyboard Mode" "Map Caplock to Ctrl" --icon=${ICON}
            ;;
        'swap_capslock_with_ctrl')
            #setxkbmap -option "ctrl:swapcaps"
            xmodmap -e 'keycode 66 = Control_L'; xmodmap -e 'keycode 37 = Caps_Lock'
            notify-send -u low "Keyboard Mode" "Swap Caplock with Ctrl" --icon=${ICON}
            ;;
        'restore_capslock')
            #setxkbmap -option "ctrl:aa_ctrl"
            xmodmap -e 'keycode 66 = Caps_Lock'; xmodmap -e 'keycode 37 = Control_L'
            notify-send -u low "Keyboard Mode" "Restore Caplock" --icon=${ICON}
            ;;
        'swap_backslash_with_backspace')
            xmodmap -e 'keycode 22 = backslash bar'; xmodmap -e 'keycode 51 = BackSpace'
            notify-send -u low "Keyboard Mode" "Swap Backslash with Baskspace" --icon=${ICON}
            ;;
        'restore_backslash_and_backspace')
            xmodmap -e 'keycode 22 = BackSpace'; xmodmap -e 'keycode 51 = backslash bar'
            notify-send -u low "Keyboard Mode" "Restore Backslash and Backspace" --icon=${ICON}
            ;;
        # For HHKB
        'swap_escape_with_grave')
            xmodmap -e 'keycode 9 = grave asciitilde'; xmodmap -e 'keycode 49 = Escape'
            notify-send -u low "Keyboard Mode" "Swap Escape with Grave" --icon=${ICON}
            ;;
        'restore_escape_and_grave')
            xmodmap -e 'keycode 9 = Escape'; xmodmap -e 'keycode 49 = grave asciitilde'
            notify-send -u low "Keyboard Mode" "Restore Escape and Grave" --icon=${ICON}
            ;;
        'map_shift_escape_to_tilde')
            xmodmap -e 'keycode 9 = Escape asciitilde'
            notify-send -u low "Keyboard Mode" "Map Shift+Escape to Tilde (Shift+Grave)" --icon=${ICON}
            ;;
        'swap_escape_keybinding_with_grave_keybinding')
            CONFIG="$HOME/.config/i3/config.d/i3_workspace.config"
            sed -i "s/\+grave/\+tmp/g" ${CONFIG}
            sed -i "s/\+Escape/\+grave/g" ${CONFIG}
            sed -i "s/\+tmp/\+Escape/g" ${CONFIG}
            notify-send -u low "Keyboard Mode" "Swap Esc-related keybindings w/ Grave-related keybindings" --icon=${ICON}
            i3-msg reload
            ;;
        # For TEX Shinobi
        'customize_tex_shinobi')
            DEVICE='USB-HID Keyboard Mouse'
            xinput set-prop "${DEVICE}" 315 0
            xinput set-prop "${DEVICE}" 329 0 1 0
            xinput set-prop "${DEVICE}" 326 0.45
            notify-send -u low "Keyboard Mode" "Customize TEX Shinobi (Trackpoint)" --icon=${ICON}
            ;;
        'restore_tex_shinobi')
            DEVICE='USB-HID Keyboard Mouse'
            xinput set-prop "${DEVICE}" 315 0
            xinput set-prop "${DEVICE}" 329 1 0 0
            xinput set-prop "${DEVICE}" 326 0.0
            notify-send -u low "Keyboard Mode" "Restore TEX Shinobi (Trackpoint)" --icon=${ICON}
            ;;
        # Default behavior
        'default')
            # Speed up Repeat Key Rate
            xset r rate 250 50
            notify-send -u low "Keyboard Mode" "Speed up repeat key rate" --icon=${ICON}
            # Map Capslock to Ctrl
            xmodmap -e 'keycode 66 = Control_L'
            notify-send -u low "Keyboard Mode" "Map Caplock to Ctrl" --icon=${ICON}
            # Map Shift+Escape to Tilde
            xmodmap -e 'keycode 9 = Escape asciitilde'
            notify-send -u low "Keyboard Mode" "Map Shift+Escape to Tilde (Shift+Grave)" --icon=${ICON}
            # Customize TEX Shinobi Trackpoint
            DEVICE='USB-HID Keyboard Mouse'
            xinput set-prop "${DEVICE}" 315 0
            xinput set-prop "${DEVICE}" 329 0 1 0
            xinput set-prop "${DEVICE}" 326 0.45
            notify-send -u low "Keyboard Mode" "Customize TEX Shinobi (Trackpoint)" --icon=${ICON}
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
