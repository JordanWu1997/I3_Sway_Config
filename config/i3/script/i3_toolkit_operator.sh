#!/usr/bin/env bash

ICON="$HOME/.config/i3/share/64x64/wrench.png"

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_toolkit_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [enable_caffeine]: disable X screensaver"
    echo "  [disable_caffeine]: enable X screensaver"
    echo "  [kill_window]: click window on screen to kill (X window)"
    echo "  [pickup_color]: pick up color on screen (X window)"
    echo "  [get_screenshot_text]: screenshot, apply OCR to it and copy context to clipboard"
    echo "  [collect_all_instances]: collect all window instances"
    echo "  [connection_up]: set connection up"
    echo "  [connection_down]: set connection down"
    echo "  [toggle_oneko]: toggle oneko on/off"
    echo "  [reload_parcellite]: reload parcellite (clipboard manager)"
}

toolkit_operation () {
    case $1 in
        'kill_window')
            notify-send -t 1500 -u low "Toolkit Mode" "Click Window to kill" --icon="${ICON}"
            xkill
            ;;
        'pickup_color')
            notify-send -t 1500 -u low "Toolkit Mode" "Select Color on Screen" --icon="${ICON}"
            COLOR=$(xcolor --format 'HEX' -S 3)
            echo "${COLOR}" | xsel -i
            notify-send -u low "Toolkit Mode" "Pickup Color: ${COLOR}" --icon="${ICON}"
            ;;
        'get_screenshot_text')
            # Source: https://new.reddit.com/r/archlinux/comments/1bwq3au/what_is_your_linux_customization_that_makes_you/
            CONTEXT=$(flameshot gui --raw | tesseract -l eng+chi_tra stdin stdout)
            echo "${CONTEXT}" | xclip -in -selection clipboard
            notify-send -u low "Toolkit Mode" "${CONTEXT}" --icon="${ICON}"
            ;;
        'collect_all_instances')
            INSTANCE=$(wmctrl -l -x | rofi -dmenu -p 'Collect all' | cut -d' ' -f4 | cut -d. -f1)
            [[ -n "${INSTANCE}" ]] && $I3_SCRIPT/i3_collect_all_instances.py ${INSTANCE}
            ;;
        'enable_caffeine')
            xset s 0 0 dpms 0 0 0
            notify-send -u low "Toolkit Mode" "Caffeine On (Disable X Screensaver)" --icon="${ICON}"
            ;;
        'disable_caffeine')
            xset s 600 600 dpms 600 600 600
            notify-send -u low "Toolkit Mode" "Caffeine Off (Enable X Screensaver)" --icon="${ICON}"
            ;;
        'connection_up')
            ROFI_CONFIG="$HOME/.config/rofi/config_singlecol.rasi"
            SELECTED_NETWORK=$(nmcli connection show | awk 'NR>1' | rofi -dmenu -i -config ${ROFI_CONFIG} -p "[UP] Connection" | cut -c -30 | rev | cut -d' ' -f2- | rev)
            [[ -n ${SELECTED_NETWORK} ]] && nmcli connection up "$(echo ${SELECTED_NETWORK} | awk 'NR==1')" # Here uses awk to remove trailing white spaces
            ;;
        'connection_down')
            ROFI_CONFIG="$HOME/.config/rofi/config_singlecol.rasi"
            SELECTED_NETWORK=$(nmcli connection show | awk 'NR>1' | rofi -dmenu -i -config ${ROFI_CONFIG} -p "[DOWN] Connection" | cut -c -30 | rev | cut -d' ' -f2- | rev)
            [[ -n ${SELECTED_NETWORK} ]] && nmcli connection down "$(echo ${SELECTED_NETWORK} | awk 'NR==1')" # Here uses awk to remove trailing white spaces
            ;;
        'toggle_oneko')
            if $(killall oneko); then
                notify-send -u low "Toolkit Mode" "Oneko is killed" --icon="${ICON}"
            else
                oneko -fg black -bg white -neko -speed 50
            fi
            ;;
        'reload_parcellite')
            PARCELLITE_PID=$(pgrep -l 'parcellite' | cut -d' ' -f1)
            if [[ -n ${PARCELLITE_PID} ]]; then
                kill ${PARCELLITE_PID}
            fi
            # Send stderr to null to prevent "Error converting selection from UTF8_STRING" log spamming
            i3-msg exec 'parcellite 2> /dev/null'
            notify-send -u low "Toolkit Mode" "Parcellite is reloaded" --icon="${ICON}"
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main
toolkit_operation "$@"
