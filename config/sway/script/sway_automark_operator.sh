#!/usr/bin/env bash
# Ported from i3_automark_operator.sh for sway.
# Replaced X11/i3-only tools:
#   - xdotool getwindowfocus/getwindowgeometry/mousemove -> swaymsg -t get_tree (.rect of the
#                                                          focused node) + swaymsg seat - cursor set X Y
#   - i3_automark_daemon.py / i3_automark.py             -> sway_automark_daemon.py / sway_automark.py
#   - swaymsg                                             -> swaymsg
# Subcommands are identical to the i3 version.

SWAY_SCRIPT="${SWAY_SCRIPT:-$HOME/.config/sway/script}"
AUTOMARK_DAEMON="$SWAY_SCRIPT/sway_automark_daemon.py"

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
    echo "  sway_automark_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [enable]: enable automark"
    echo "  [disable]: disable automark"
    echo "  [reload]: reload automark"
    echo "  [cycle_focus_inc]: change focus to next increasingly-automarked window"
    echo "  [cycle_focus_dec]: change focus to next decreasingly-automarked window"
    echo "  [cycle_swap_inc]: swap window with next increasingly-automarked window"
    echo "  [cycle_swap_dec]: swap window with next decreasingly-automarked window"
}

cycle_mark_focus () {
    # Set automark index dictionary
    declare -A AUTOMARK_INDEX_DICT
    for i in ${!ALL_AUTOMARK_LIST[@]}; do
        AUTOMARK_INDEX_DICT[${ALL_AUTOMARK_LIST[$i]}]=${i}
    done
    # Find corresponding indice for existing marks
    MARKS=($(swaymsg -t get_marks -r | jq -c . | tr " ',\[\]" "_ \n  " | sed '/" "/d' | sed 's/\"/ /g'))
    for i in ${!MARKS[@]}; do
        if [ "${MARKS[${i}]}" == "_" ]; then
            CURRENT_MARK=${MARKS[$(( ${i} - 1 ))]}
            CURRENT_MARK_INDEX_IN_ALL=${AUTOMARK_INDEX_DICT[${CURRENT_MARK}]}
        else
            MARK_INDEX_IN_ALL+=(${AUTOMARK_INDEX_DICT[${MARKS[${i}]}]})
        fi
    done
    # Cycle mark increasingly or decreasingly
    case $1 in
        "inc")
            # Find maximal index among existing marks
            MAX_INDEX_IN_ALL=0
            for MARK_INDEX in ${MARK_INDEX_IN_ALL[@]}; do
                if (( ${MARK_INDEX} > ${MAX_INDEX_IN_ALL} )); then
                    MAX_INDEX_IN_ALL=${MARK_INDEX}
                fi
            done
            MAX_MARK=${ALL_AUTOMARK_LIST[${MAX_INDEX_IN_ALL}]}
            # Cycle back when reach the maximal existing marks
            if [[ ${MAX_MARK} = ${CURRENT_MARK} ]]; then
                NEXT_MARK_INDEX=0
            else
                NEXT_MARK_INDEX=$(( ${CURRENT_MARK_INDEX_IN_ALL} + 1 ))
            fi
            ;;
        "dec")
            # Find maximal index among existing marks
            MAX_INDEX_IN_ALL=0
            for MARK_INDEX in ${MARK_INDEX_IN_ALL[@]}; do
                if (( ${MARK_INDEX} > ${MAX_INDEX_IN_ALL} )); then
                    MAX_INDEX_IN_ALL=${MARK_INDEX}
                    MAX_MARK=${ALL_AUTOMARK_LIST[${MAX_INDEX_IN_ALL}]}
                fi
            done
            # Find minimal index among existing marks
            MIN_INDEX_IN_ALL=${MAX_INDEX_IN_ALL}
            for MARK_INDEX in ${MARK_INDEX_IN_ALL[@]}; do
                if (( ${MARK_INDEX} < ${MIN_INDEX_IN_ALL} )); then
                    MIN_INDEX_IN_ALL=${MARK_INDEX}
                    MIN_MARK=${ALL_AUTOMARK_LIST[${MIN_INDEX_IN_ALL}]}
                fi
            done
            # Cycle back when reach the minimal existing marks
            if [[ ${CURRENT_MARK} = ${MIN_MARK} ]]; then
                NEXT_MARK_INDEX=${MAX_INDEX_IN_ALL}
            else
                NEXT_MARK_INDEX=$(( ${CURRENT_MARK_INDEX_IN_ALL} - 1 ))
            fi
            ;;
        *)
            echo "inc" or "dec"
    esac
    # Focus next mark window
    NEXT_MARK=${ALL_AUTOMARK_LIST[${NEXT_MARK_INDEX}]}
}

cursor_follow_focus () {
    # Move the cursor to the centre of the focused window (absolute layout coords)
    local TX TY
    read -r TX TY < <(swaymsg -t get_tree -r | jq -r '
        first(.. | objects | select(.focused? == true and (.type == "con" or .type == "floating_con"))
            | .rect | [(.x + .width / 2 | floor), (.y + .height / 2 | floor)] | @tsv) // empty')
    [[ -n $TX && -n $TY ]] && swaymsg seat - cursor set "$TX" "$TY" >/dev/null
}

automark_operation () {
    ICON="$HOME/.config/i3/share/64x64/abc.png"
    case $1 in
        "enable")
            notify-send -u "low" "Sway Automark" "sway automark is enabled" --icon="${ICON}"
            pgrep -u "$USER" -f "sway_automark_daemon.py" >/dev/null || \
                setsid -f python3 "$AUTOMARK_DAEMON" >/dev/null 2>&1 </dev/null
            ;;
        "disable")
            notify-send -u "low" "Sway Automark" "sway automark is disabled" --icon="${ICON}"
            pkill -u "$USER" -f "sway_automark_daemon.py"
            ;;
        "reload")
            notify-send -u "low" "Sway Automark" "Reload sway automark" --icon="${ICON}"
            pkill -u "$USER" -f "sway_automark_daemon.py"
            setsid -f python3 "$AUTOMARK_DAEMON" >/dev/null 2>&1 </dev/null
            ;;
        "cycle_focus_inc")
            cycle_mark_focus inc
            swaymsg "[con_mark=${NEXT_MARK}] focus"
            cursor_follow_focus
            ;;
        "cycle_focus_dec")
            cycle_mark_focus dec
            swaymsg "[con_mark=${NEXT_MARK}] focus"
            cursor_follow_focus
            ;;
        "cycle_swap_inc")
            cycle_mark_focus inc
            swaymsg "swap container with mark ${NEXT_MARK}"
            python3 "$SWAY_SCRIPT/sway_automark.py"
            cursor_follow_focus
            ;;
        "cycle_swap_dec")
            cycle_mark_focus dec
            swaymsg "swap container with mark ${NEXT_MARK}"
            python3 "$SWAY_SCRIPT/sway_automark.py"
            cursor_follow_focus
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Auto reload daemon if it is not running
if [[ ! $1 == 'disable' ]] && [[ ! $1 == 'reload' ]]; then
    pgrep -u "$USER" -f "sway_automark_daemon.py" >/dev/null || \
        setsid -f python3 "$AUTOMARK_DAEMON" >/dev/null 2>&1 </dev/null
fi

# Main
automark_operation "$1"
