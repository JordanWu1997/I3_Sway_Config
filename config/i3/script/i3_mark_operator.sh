#!/usr/bin/env bash

# Rofi configuration
ROFI_SELECTOR_CONFIG="$HOME/.config/rofi/config_i3mark.rasi"
# Mark input list for rofi
ROFI_AUTOMARK_INPUT_TEXT="$HOME/.config/rofi/i3_automark_list.txt"
# Automark marks
ALL_AUTOMARK_LIST=(\
    1 2 3 4 5 6 7 8 9 0 \
    q w e r t y u i o p \
    a s d f g h j k l \
    z x c v b n m)

# Operation for i3 vim-style mark
mark_operation () {
    case $1 in
        # Show all marked window, modified from
        # -- https://github.com/EllaTheCat/dopamine-2020/blob/master/i3scripts/i3-list-windows
        "show")
            i3-msg -t get_tree | jq '.. | objects | .name,.marks' | \
                /usr/bin/grep -B1 -A1 '[[]' | tr -d \\n\[ | sed 's/--/\n/g' | \
                /usr/bin/grep -v 'null' | awk -F '  ' '{print $2, $1}' | \
                rofi -dmenu -sort -select -p 'Show [Mark]'
            ;;
        # Mark current window
        "mark")
            if [ $2 == "i3" ]; then
                i3-input -F "mark --add %s" -l 1 -P "Mark: "
            elif [ $2 == "rofi" ]; then
                i3-msg "mark --add $(rofi -dmenu -config ${ROFI_SELECTOR_CONFIG} -p 'Mark')"
            else
                i3-input -F "mark --add %s" -l 1 -P "Mark: "
            fi
            ;;
        # Unmark current window
        "unmark")
            if [ $2 == "i3" ]; then
                i3-input -F "unmark %s" -l 1 -P "Mark: "
            elif [ $2 == "rofi" ]; then
                i3-msg unmark $(rofi -dmenu -config ${ROFI_SELECTOR_CONFIG} -p 'Unmark')
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
                i3-msg [con_mark="$(rofi -dmenu -config ${ROFI_SELECTOR_CONFIG} \
                    -select -input ${ROFI_AUTOMARK_INPUT_TEXT} \
                    -p 'Goto Window [Mark]')"] focus
            fi
            ;;
        "show_then_goto")
            mark_title="$(i3-msg -t get_tree | jq '.. | objects | .name,.marks' | \
                /usr/bin/grep -B1 -A1 '[[]' | tr -d \\n\[ | sed 's/--/\n/g' | \
                /usr/bin/grep -v 'null' | awk -F '  ' '{print $2, $1}' | \
                rofi -dmenu -sort -auto-select -p 'Goto Window [Mark]')"
            mark_mark=$(echo $mark_title | awk '{print $1}' | cut -d',' -f1)
            i3-msg [con_mark="$mark_mark"] focus
            ;;
        # Swap current window to mark window but remain focus
        "swap")
            if [ $2 == "i3" ]; then
                # Keep focus stay in current container
                if [ $3 == "stay" ]; then
                    i3-input -F "swap container with mark %s, [con_mark=%s] focus" -l 1 -P "Swapto [Mark]: "
                else
                    i3-input -F "swap container with mark %s" -l 1 -P "Swapto [Mark]: "
                fi
            elif [ $2 == "rofi" ]; then
                mark_title="$(rofi -dmenu -config "${ROFI_SELECTOR_CONFIG}" -select \
                    -input "${ROFI_AUTOMARK_INPUT_TEXT}" -p 'Swapto [Mark]')"
                mark_mark=$(echo $mark_title | awk '{print $1}' | cut -d',' -f1)
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
                /usr/bin/grep -B1 -A1 '[[]' | tr -d \\n\[ | sed 's/--/\n/g' | \
                /usr/bin/grep -v 'null' | awk -F '  ' '{print $2, $1}' | \
                rofi -dmenu -sort -auto-select --only-match -p 'Swapto [Mark]')"
            mark_mark=$(echo $mark_title | awk '{print $1}' | cut -d',' -f1)
            # Keep focus stay in current container
            if [ $3 == "stay" ]; then
                i3-msg "swap container with mark $mark_mark, [con_mark=$mark_mark] focus"
            else
                i3-msg "swap container with mark $mark_mark"
            fi
            ;;
        # Print usage
        *)
            echo
            echo "Wrong Input: $0"
            echo
            echo "Usage:"
            echo "  i3_mark_operator.sh [mark_operation] [input] [titlebar_option]"
            echo ""
            echo "OPTIONS"
            echo "  [mark_operation]: mark, unmark, unmark_all, unmark_all_automark,"
            echo "                    unmark_all_automark_and_reomark,"
            echo "                    goto, swap, show_then_goto, show_then_swap"
            echo "  [input]": i3, rofi, none
            echo "  [titlebar_option]": title_on, title_off
            ;;
    esac
}

# Main
if [ $4 == 'title_on' ]; then
    # Get current titlebar/border setup
    DEFAULT_WIDTH=$(awk '$0~/default_border_width/ {print $3}' $HOME/.config/i3/config | awk 'NR==1')
    DEFAULT_STYLE=$(awk '$0~/default_titlebar_style/ {print $3}' $HOME/.config/i3/config | awk 'NR==1')
    DEFAULT_FLOATING_STYLE=$(awk '$0~/default_floating_titlebar_style/ {print $3}' $HOME/.config/i3/config | awk 'NR==1')
    echo $DEFAULT_STYLE $DEFAULT_WIDTH
    # Show titlebar
    i3-msg [con_mark="^.*"] border normal $DEFAULT_WIDTH
    # Operation with mark
    mark_operation $1 $2 $3
    # Restore defaults
    i3-msg "[all] border $DEFAULT_STYLE $DEFAULT_WIDTH; \
            [floating] border $DEFAULT_FLOATING_STYLE $DEFAULT_WIDTH; \
            [tiling_from='user'] border $DEFAULT_STYLE $DEFAULT_WIDTH"
else
    # Do not show titlebar for all windows
    mark_operation $1 $2 $3
fi
