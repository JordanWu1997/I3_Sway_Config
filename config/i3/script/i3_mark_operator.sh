#!/usr/bin/env bash

# Rofi configuration
ROFI_SELECTOR_CONFIG="$HOME/.config/rofi/config_i3mark.rasi"
# Mark input list for rofi
ROFI_AUTOMARK_INPUT_TEXT="$HOME/.config/rofi/i3_automark_list.txt"
# Automark marks
#ALL_AUTOMARK_LIST=(\
    #1 2 3 4 5 6 7 8 9 0 \
    #q w e r t y u i o p \
    #a s d f g h j k l \
    #z x c v b n m)
readarray -t ALL_AUTOMARK_LIST < "$HOME/.config/i3/share/i3_automark_list.txt"

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_mark_operator.sh [operations] [input/selector] [titlebar]"
    echo ""
    echo "OPERATIONS"
    echo "  [mark]: add mark to window"
    echo "  [unmark]: unmark existing mark"
    echo "  [unmark_all]: unmark all existing marks"
    echo "  [unmark_all_automark]: unmark all automarked marks"
    echo "  [unmark_all_automark_and_remark]: unmark all automarked marks and re-automark"
    echo "  [goto]: go to marked window"
    echo "  [swap]: swap with marked window"
    echo "  [show_then_goto]: show all marks and go to marked window"
    echo "  [show_then_swap]: show all marks and swap with marked window"
    echo ""
    echo "INPUT/SELECTOR"
    echo "  [i3]: use i3-input as input/selector"
    echo "  [rofi]: use rofi as input/selector"
    echo "  [none]: do not use input/selector"
    echo ""
    echo "TITLEBAR"
    echo "  [title_on]: show window title bar when selecting"
    echo "  [title_off]: do not show winow title bar when selecting"
}

# Operation for i3 vim-style mark
mark_operation () {
    case $1 in
        # Show all marked window, modified from
        # -- https://github.com/EllaTheCat/dopamine-2020/blob/master/i3scripts/i3-list-windows
        "show")
            i3-msg -t get_tree | jq '.. | objects | .name,.marks' | \
                command grep -B1 -A1 '[[]' | tr -d \\n\[ | sed 's/--/\n/g' | \
                command grep -v 'null' | awk -F '  ' '{print $2, $1}' | \
                rofi -dmenu -sort -select -p 'Show [Mark]'
            ;;
        # Mark current window
        "mark")
            if [ $2 == "i3" ]; then
                i3-input -F "mark --add %s" -l 1 -P "Mark: "
            elif [ $2 == "rofi" ]; then
                mark_mark=$(rofi -dmenu -config ${ROFI_SELECTOR_CONFIG} -p 'Mark')
                if [[ -z ${mark_mark} ]]; then
                    return
                fi
                i3-msg "mark --add ${mark_mark}"
            else
                i3-input -F "mark --add %s" -l 1 -P "Mark: "
            fi
            ;;
        # Unmark current window
        "unmark")
            if [ $2 == "i3" ]; then
                i3-input -F "unmark %s" -l 1 -P "Mark: "
            elif [ $2 == "rofi" ]; then
                mark_mark=$(rofi -dmenu -config ${ROFI_SELECTOR_CONFIG} -p 'Unmark')
                if [[ ! -z ${mark_mark} ]]; then
                    i3-msg unmark ${mark_mark}
                fi
            else
                i3-input -F "unmark %s" -l 1 -P "Unmark: "
            fi
            ;;
        # Unmark all marks
        "unmark_all")
            i3-msg unmark
            ;;
        # Unmark all automark marks
        "unmark_all_automark")
            for mark in ${ALL_AUTOMARK_LIST[@]}; do
                i3-msg unmark ${mark}
            done
            ;;
        "unmark_all_automark_and_remark")
            for mark in ${ALL_AUTOMARK_LIST[@]}; do
                i3-msg unmark ${mark}
            done
            python3 $I3_SCRIPT/i3_automark.py
            ;;
        # Goto mark window
        "goto")
            if [ $2 == "i3" ]; then
                i3-input -F "[con_mark=%s] focus" -l 1 -P "Goto Window [Mark]: "
            elif [ $2 == "rofi" ]; then
                mark_mark=$(rofi -dmenu -config ${ROFI_SELECTOR_CONFIG} \
                    -select -input ${ROFI_AUTOMARK_INPUT_TEXT} \
                    -p 'Goto Window [Mark]')
                if [[ -z ${mark_mark} ]]; then
                    return
                fi
                i3-msg [con_mark="${mark_mark}"] focus

            fi
            ;;
        "show_then_goto")
            mark_title="$(i3-msg -t get_tree | jq '.. | objects | .name,.marks' | \
                command grep -x '^\[$' -A1 -B1 | command grep -vx '^\[$' | tr -d '\n' | \
                sed 's/\"\,/\"/g' | sed 's/--/\n/g' | awk -F '  ' '{print $2,$1}' | \
                rofi -dmenu -sort -auto-select -p 'Goto Window [Mark]')"
            mark_mark=$(echo $mark_title | awk '{print $1}' | cut -d',' -f1)
            if [[ -z ${mark_mark} ]]; then
                return
            fi
            i3-msg [con_mark="$mark_mark"] focus
            ;;
        # Swap current window to mark window but remain focus
        "swap")
            if [ $2 == "i3" ]; then
                # Keep focus stay in current container
                if [ $3 == "stay" ]; then
                    i3-input -F "swap container with mark %s, [con_mark=%s] focus" -l 1 -P "Swap with Window [Mark]: "
                else
                    i3-input -F "swap container with mark %s" -l 1 -P "Swap with Window [Mark]: "
                fi
            elif [ $2 == "rofi" ]; then
                mark_title="$(rofi -dmenu -config "${ROFI_SELECTOR_CONFIG}" -select \
                    -input "${ROFI_AUTOMARK_INPUT_TEXT}" -p 'Swap with Window [Mark]')"
                mark_mark=$(echo $mark_title | awk '{print $1}' | cut -d',' -f1)
                if [[ -z ${mark_mark} ]]; then
                    return
                fi
                # Keep focus stay in current container
                if [ $3 == "stay" ]; then
                    i3-msg "swap container with mark $mark_mark, [con_mark=$mark_mark] focus"
                else
                    i3-msg "swap container with mark $mark_mark"
                fi
            fi
            ;;
        "show_then_swap")
            mark_title="$(i3-msg -t get_tree | jq '.. | objects | .name,.marks' | \
                command grep -x '^\[$' -A1 -B1 | command grep -vx '^\[$' | tr -d '\n' | \
                sed 's/\"\,/\"/g' | sed 's/--/\n/g' | awk -F '  ' '{print $2,$1}' | \
                rofi -dmenu -sort -auto-select -p 'Swap with Window [Mark]')"
            mark_mark=$(echo $mark_title | awk '{print $1}' | cut -d',' -f1)
            if [[ -z ${mark_mark} ]]; then
                return
            fi
            # Keep focus stay in current container
            if [ $3 == "stay" ]; then
                i3-msg "swap container with mark $mark_mark, [con_mark=$mark_mark] focus"
            else
                i3-msg "swap container with mark $mark_mark"
            fi
            ;;
        # Print usage
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main
if [ $4 == 'title_on' ]; then
    # Get current titlebar/border setup
    DEFAULT_WIDTH=$(awk '$0~/default_border_width/ {print $3}' $HOME/.config/i3/config | awk 'NR==1')
    DEFAULT_STYLE=$(awk '$0~/default_titlebar_style/ {print $3}' $HOME/.config/i3/config | awk 'NR==1')
    DEFAULT_FLOATING_STYLE=$(awk '$0~/default_floating_titlebar_style/ {print $3}' $HOME/.config/i3/config | awk 'NR==1')
    # Show titlebar
    i3-msg [con_mark="^.*"] border normal $DEFAULT_WIDTH
    # Operation with mark
    mark_operation $1 $2 $3
    # Restore defaults
    i3-msg "[all] border $DEFAULT_STYLE $DEFAULT_WIDTH"
    i3-msg "[floating] border $DEFAULT_FLOATING_STYLE $DEFAULT_WIDTH"
    #i3-msg "[tiling_from='user'] border $DEFAULT_STYLE $DEFAULT_WIDTH"
else
    # Do not show titlebar for all windows
    mark_operation $1 $2 $3
fi
