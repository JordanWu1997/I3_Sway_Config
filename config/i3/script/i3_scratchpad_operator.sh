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
    echo "  [select]: select scratchpad window"
}

scrachpad_operation () {
    case $1 in
        'select')
            SCRATCHPAD_WD_NUM=$(wmctrl -l | awk '$2<0' | wc -l)
            if [[ ${SCRATCHPAD_WD_NUM} -gt "0" ]]; then
                WINDOW_ID=$(wmctrl -l | awk '$2<0' | \
                    rofi -dmenu -config "$HOME/.config/rofi/config_singlecol.rasi" \
                    -p "scrachpad" -i -auto-select | cut -d' ' -f1)
                i3-msg "[id="${WINDOW_ID}"] focus"
            else
                notify-send -u "low" "i3 Scratchpad" "No windows in scratchpad"
            fi
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

scrachpad_operation $1