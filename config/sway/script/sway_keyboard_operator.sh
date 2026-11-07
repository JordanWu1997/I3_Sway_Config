#!/bin/bash
# Ported from i3_keyboard_operator.sh for sway.
# Replaced X11 tools:
#   - xset r rate D R          -> swaymsg input type:keyboard repeat_delay D / repeat_rate R
#   - xdotool key Caps_Lock    -> wtype -k Caps_Lock (Num_Lock likewise)
#   - setxkbmap -option / xmodmap keycode swaps
#                              -> one generated XKB keymap applied with
#                                 swaymsg input type:keyboard xkb_file <file>
#     State of all tweaks (caps/ctrl, Esc/grave, Backspace/backslash, Shift+Esc=~)
#     is kept in ${XDG_RUNTIME_DIR:-/tmp}/sway_keyboard_state so they combine like
#     the cumulative setxkbmap/xmodmap calls did. Keymap: ${XDG_RUNTIME_DIR:-/tmp}/sway_keyboard.xkb
#   - xinput set-prop/enable/disable (TEX Shinobi trackpoint)
#                              -> swaymsg input <identifier> accel_profile/pointer_accel/events
#   - i3_workspace.config + i3-msg reload -> sway_workspace.config + swaymsg reload
# Subcommands are identical to the i3 version.

SWAY_SCRIPT="${SWAY_SCRIPT:-$HOME/.config/sway/script}"

ICON="$HOME/.config/i3/share/64x64/keyboard.png"
STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/sway_keyboard_state"
KEYMAP_FILE="${XDG_RUNTIME_DIR:-/tmp}/sway_keyboard.xkb"
XKB_LAYOUT="${SWAY_XKB_LAYOUT:-us}"
XKB_MODEL="${SWAY_XKB_MODEL:-pc105}"
WORKSPACE_CONFIG="$HOME/.config/sway/config.d/sway_workspace.config"
GESTURES_CONFIG="$HOME/.config/libinput-gestures.conf"
# TEX Shinobi trackpoint (X name 'TEX-BLE-KB-1 Mouse' / 'USB-HID Keyboard Mouse')
TEX_NAME_REGEX='TEX-BLE-KB-[0-9]+ Mouse'

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  sway_keyboard_operator.sh [operations]"
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
    echo "  [enable_tex_shinobi_trackpoint]"
    echo "  [disable_tex_shinobi_trackpoint]"
    echo "  [restore_tex_shinobi]"
    echo "  [swap_backslash_with_backspace]"
    echo "  [restore_backslash_and_backspace]"
    echo "  [swap_escape_with_grave]"
    echo "  [restore_escape_and_grave]"
    echo "  [map_shift_escape_to_tilde]"
    echo "  [swap_escape_keybinding_with_grave_keybinding]"
    echo "  [restore_keyboard_layout]"
    echo "  [default]"
    echo
}

# ---------------------------------------------------------------------------
# XKB state handling
#   CAPS : none | nocaps | swapcaps
#   ESC  : default | grave | shift_tilde
#   TLDE : default | escape
#   BKSP : default | swap
# ---------------------------------------------------------------------------
load_state () {
    CAPS=none; ESC=default; TLDE=default; BKSP=default
    # shellcheck disable=SC1090
    [[ -r "$STATE_FILE" ]] && source "$STATE_FILE"
}

save_state () {
    printf 'CAPS=%s\nESC=%s\nTLDE=%s\nBKSP=%s\n' "$CAPS" "$ESC" "$TLDE" "$BKSP" > "$STATE_FILE"
}

write_keymap () {
    local symbols="pc+${XKB_LAYOUT}+inet(evdev)"
    case $CAPS in
        nocaps) symbols+="+ctrl(nocaps)" ;;
        swapcaps) symbols+="+ctrl(swapcaps)" ;;
    esac
    {
        echo 'xkb_keymap {'
        echo '    xkb_keycodes { include "evdev+aliases(qwerty)" };'
        echo '    xkb_types { include "complete" };'
        echo '    xkb_compat { include "complete" };'
        echo "    xkb_symbols {"
        echo "        include \"${symbols}\""
        case $ESC in
            grave) echo '        key <ESC> { [ grave, asciitilde ] };' ;;
            shift_tilde) echo '        key <ESC> { [ Escape, asciitilde ] };' ;;
        esac
        [[ $TLDE == escape ]] && echo '        key <TLDE> { [ Escape, Escape ] };'
        if [[ $BKSP == swap ]]; then
            echo '        key <BKSP> { [ backslash, bar ] };'
            echo '        key <BKSL> { [ BackSpace, BackSpace ] };'
        fi
        echo '    };'
        echo "    xkb_geometry { include \"pc(${XKB_MODEL})\" };"
        echo '};'
    } > "$KEYMAP_FILE"
}

apply_keymap () {
    save_state
    write_keymap
    if command -v xkbcli > /dev/null && ! xkbcli compile-keymap --keymap < "$KEYMAP_FILE" &> /dev/null; then
        notify-send -u critical "Keyboard Mode" "Generated keymap is invalid: $KEYMAP_FILE" --icon="${ICON}"
        return 1
    fi
    swaymsg "input type:keyboard xkb_file \"$KEYMAP_FILE\"" > /dev/null
}

set_repeat () {
    swaymsg "input type:keyboard repeat_delay $1; input type:keyboard repeat_rate $2" > /dev/null
}

# sway input identifier of the TEX Shinobi pointer
tex_device () {
    swaymsg -t get_inputs -r | jq -r --arg re "$TEX_NAME_REGEX" \
        '[.[] | select(.type == "pointer" and (.name | test($re)))][0].identifier // empty'
}

# X props 329 (Accel Profile adaptive/flat/custom) and 326 (Accel Speed);
# prop 315 was set to 0 in both customize and restore, so it is not changed here.
tex_customize () {
    swaymsg "input \"$1\" accel_profile flat; input \"$1\" pointer_accel 0.80" > /dev/null
}

tex_restore () {
    swaymsg "input \"$1\" accel_profile adaptive; input \"$1\" pointer_accel 0.0" > /dev/null
}

swap_grave_escape_in () {
    local config=$1
    [[ -w "$config" ]] || return 0
    sed -i "s/\+grave/\+tmp/g" "${config}"
    sed -i "s/\+Escape/\+grave/g" "${config}"
    sed -i "s/\+tmp/\+Escape/g" "${config}"
}

# Operation
keyboard_operation () {
    local DEVICE
    load_state
    case $1 in
        # Repeat Key Rate
        'speed_up_repeat_key_rate')
            set_repeat 220 50
            notify-send -u low "Keyboard Mode" "Speed up repeat key rate (220/50)" --icon=${ICON}
            ;;
        'restore_repeat_key_rate')
            set_repeat 660 25
            notify-send -u low "Keyboard Mode" "Restore default repeat key rate (660/25)" --icon=${ICON}
            ;;
        # Caps_Lock/Num_Lock
        'send_capslock_key')
            wtype -k Caps_Lock
            notify-send -u low "Keyboard Mode" "Capslock key is pressed" --icon=${ICON}
            ;;
        'send_numlock_key')
            wtype -k Num_Lock
            notify-send -u low "Keyboard Mode" "Numlock key is pressed" --icon=${ICON}
            ;;
        # For non-HHKB
        'map_capslock_to_ctrl')
            CAPS=nocaps; apply_keymap
            notify-send -u low "Keyboard Mode" "Map Caplock to Ctrl" --icon=${ICON}
            ;;
        'swap_capslock_with_ctrl')
            CAPS=swapcaps; apply_keymap
            notify-send -u low "Keyboard Mode" "Swap Caplock with Ctrl" --icon=${ICON}
            ;;
        'restore_capslock')
            CAPS=none; apply_keymap
            notify-send -u low "Keyboard Mode" "Restore Caplock" --icon=${ICON}
            ;;
        'swap_backslash_with_backspace')
            BKSP=swap; apply_keymap
            notify-send -u low "Keyboard Mode" "Swap Backslash with Baskspace" --icon=${ICON}
            ;;
        'restore_backslash_and_backspace')
            BKSP=default; apply_keymap
            notify-send -u low "Keyboard Mode" "Restore Backslash and Backspace" --icon=${ICON}
            ;;
        # For HHKB
        'swap_escape_with_grave')
            ESC=grave; TLDE=escape; apply_keymap
            notify-send -u low "Keyboard Mode" "Swap Escape with Grave" --icon=${ICON}
            ;;
        'restore_escape_and_grave')
            ESC=default; TLDE=default; apply_keymap
            notify-send -u low "Keyboard Mode" "Restore Escape and Grave" --icon=${ICON}
            ;;
        'map_shift_escape_to_tilde')
            ESC=shift_tilde; apply_keymap
            notify-send -u low "Keyboard Mode" "Map Shift+Escape to Tilde (Shift+Grave)" --icon=${ICON}
            ;;
        'swap_escape_keybinding_with_grave_keybinding')
            # sway workspace keybindings
            swap_grave_escape_in "${WORKSPACE_CONFIG}"
            swaymsg reload > /dev/null
            # libinput-gestures for trackpad
            if [[ -w "${GESTURES_CONFIG}" ]]; then
                swap_grave_escape_in "${GESTURES_CONFIG}"
                swaymsg exec "libinput-gestures-setup restart" > /dev/null
            fi
            notify-send -u low "Keyboard Mode" "Swap Esc-related keybindings w/ Grave-related keybindings" --icon=${ICON}
            ;;
        # For TEX Shinobi
        'customize_tex_shinobi')
            DEVICE=$(tex_device)
            [[ -n ${DEVICE} ]] || { notify-send -u normal "Keyboard Mode" "TEX Shinobi trackpoint not found" --icon=${ICON}; return 1; }
            tex_customize "${DEVICE}"
            notify-send -u low "Keyboard Mode" "Customize TEX Shinobi (Trackpoint)" --icon=${ICON}
            ;;
        'enable_tex_shinobi_trackpoint')
            DEVICE=$(tex_device)
            [[ -n ${DEVICE} ]] && swaymsg "input \"${DEVICE}\" events enabled" > /dev/null
            ;;
        'disable_tex_shinobi_trackpoint')
            DEVICE=$(tex_device)
            [[ -n ${DEVICE} ]] && swaymsg "input \"${DEVICE}\" events disabled" > /dev/null
            ;;
        'restore_tex_shinobi')
            DEVICE=$(tex_device)
            [[ -n ${DEVICE} ]] || { notify-send -u normal "Keyboard Mode" "TEX Shinobi trackpoint not found" --icon=${ICON}; return 1; }
            tex_restore "${DEVICE}"
            notify-send -u low "Keyboard Mode" "Restore TEX Shinobi (Trackpoint)" --icon=${ICON}
            ;;
        'restore_keyboard_layout')
            CAPS=none; ESC=default; TLDE=default; BKSP=default
            apply_keymap
            notify-send -u low "Keyboard Mode" "Restore all (plain ${XKB_LAYOUT} keymap)" --icon=${ICON}
            ;;
        # Default behavior
        'default')
            # Map Capslock to Ctrl + Map Shift+Escape to Tilde (one keymap)
            CAPS=nocaps; ESC=shift_tilde
            apply_keymap
            notify-send -u low "Keyboard Mode" "Map Caplock to Ctrl" --icon=${ICON}
            notify-send -u low "Keyboard Mode" "Map Shift+Escape to Tilde (Shift+Grave)" --icon=${ICON}
            # Speed up Repeat Key Rate
            set_repeat 220 50
            notify-send -u low "Keyboard Mode" "Speed up repeat key rate" --icon=${ICON}
            # Customize TEX Shinobi Trackpoint
            DEVICE=$(tex_device)
            if [[ -n ${DEVICE} ]]; then
                tex_customize "${DEVICE}"
                notify-send -u low "Keyboard Mode" "Customize TEX Shinobi (Trackpoint)" --icon=${ICON}
            fi
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main
keyboard_operation "$1"
