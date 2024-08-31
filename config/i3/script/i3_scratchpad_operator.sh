#!/usr/bin/env bash

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_scratchpad_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [select]: select window in scratchpad"
    echo "  [select_and_send_focus_if_no_one_to_select]: select window in scratchpad and if there is no window to select, send focus one"
}

scratchpad_operation () {
    ICON="$HOME/.config/i3/share/64x64/window.png"
    case $1 in
        'select')
            SCRATCHPAD_WD_NUM=$(wmctrl -l | awk '$2<0' | wc -l)
            if [[ ${SCRATCHPAD_WD_NUM} -gt "0" ]]; then
                WINDOW_ID=$(wmctrl -l | awk '$2<0' | \
                    rofi -dmenu -config "$HOME/.config/rofi/config_singlecol.rasi" \
                    -p "scrachpad" -i | cut -d' ' -f1)
                    #-p "scrachpad" -i -auto-select | cut -d' ' -f1)
                i3-msg "[id="${WINDOW_ID}"] focus"
            else
                notify-send -u "low" "i3 Scratchpad" "There are NO windows in scratchpad" --icon=${ICON}
            fi
            ;;
        'select_and_send_focus_if_no_one_to_select')
            SCRATCHPAD_WD_NUM=$(wmctrl -l | awk '$2<0' | wc -l)
            if [[ ${SCRATCHPAD_WD_NUM} -gt "0" ]]; then
                WINDOW_ID=$(wmctrl -l | awk '$2<0' | \
                    rofi -dmenu -config "$HOME/.config/rofi/config_singlecol.rasi" \
                    -p "scrachpad" -i | cut -d' ' -f1)
                    #-p "scrachpad" -i -auto-select | cut -d' ' -f1)
                i3-msg "[id="${WINDOW_ID}"] focus"
            else
                notify-send -u "low" "i3 Scratchpad" "There are NO more windows in scratchpad\nLast focus window is sent to scratchpad"
                i3-msg "floating focus"
                i3-msg "move scratchpad"
            fi
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

scratchpad_operation $1
