#!/usr/bin/env bash
# Ported from i3_scratchpad_operator.sh for sway.
# Replaced X11 tools:
#   - wmctrl -l (desktop -1 = scratchpad) -> swaymsg -t get_tree (__i3_scratch workspace);
#                                            wmctrl only sees XWayland windows on sway
#   - i3-msg "[id=X] focus"               -> swaymsg "[con_id=N] scratchpad show"
# Subcommands are identical to the i3 version.

SWAY_SCRIPT="${SWAY_SCRIPT:-$HOME/.config/sway/script}"

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  sway_scratchpad_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [select]: select window in scratchpad"
    echo "  [select_and_send_focus_if_no_one_to_select]: select window in scratchpad and if there is no window to select, send focus one"
}

# Hidden scratchpad windows, one per line: "<con_id> <app_id|class> <title>"
list_scratchpad_windows () {
    swaymsg -t get_tree -r | jq -r '
        .. | objects | select(.type? == "workspace" and .name == "__i3_scratch")
        | .floating_nodes[]? | .. | objects
        | select((.type? == "con" or .type? == "floating_con") and ((.nodes? // []) | length) == 0)
        | "\(.id) \(.app_id // .window_properties.class // "-") \(.name // "")"'
}

select_scratchpad_window () {
    local window_id
    window_id=$(list_scratchpad_windows | \
        rofi -dmenu -config "$HOME/.config/rofi/config_singlecol.rasi" \
        -p "scratchpad" -i | cut -d' ' -f1)
    if [[ ! ${window_id} =~ ^[0-9]+$ ]]; then
        return
    fi
    swaymsg "[con_id=${window_id}] scratchpad show"
}

scratchpad_operation () {
    ICON="$HOME/.config/i3/share/64x64/window.png"
    case $1 in
        'select')
            SCRATCHPAD_WD_NUM=$(list_scratchpad_windows | wc -l)
            if [[ ${SCRATCHPAD_WD_NUM} -gt "0" ]]; then
                select_scratchpad_window
            else
                notify-send -u "low" "Sway Scratchpad" "There are NO windows in scratchpad" --icon=${ICON}
            fi
            ;;
        'select_and_send_focus_if_no_one_to_select')
            SCRATCHPAD_WD_NUM=$(list_scratchpad_windows | wc -l)
            if [[ ${SCRATCHPAD_WD_NUM} -gt "0" ]]; then
                select_scratchpad_window
            else
                notify-send -u "low" "Sway Scratchpad" "There are NO more windows in scratchpad\nLast focus window is sent to scratchpad" --icon="$ICON"
                swaymsg "focus floating"
                swaymsg "move scratchpad"
            fi
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

scratchpad_operation "$1"
