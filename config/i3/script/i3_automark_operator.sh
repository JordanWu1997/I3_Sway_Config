#!/usr/bin/env bash

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
    echo "  i3_automark_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [enable]: enable automark"
    echo "  [disable]: disable automark"
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
    MARKS=($(i3-msg -t get_marks | tr " ',\[\]" "_ \n  " | sed '/" "/d' | sed 's/\"/ /g'))
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
    # Source Code: https://github.com/i3/i3/issues/2971
    WINDOW=$(xdotool getwindowfocus)
    # This brings in variables WIDTH and HEIGHT
    eval `xdotool getwindowgeometry --shell $WINDOW`
    TX=`expr $WIDTH / 2`
    TY=`expr $HEIGHT / 2`
    xdotool mousemove -window $WINDOW $TX $TY
}

automark_operation () {
    ICON="$HOME/.config/i3/share/32x32/abc.png"
    case $1 in
        "enable")
            notify-send -u "low" "i3 Automark" "i3 automark is enabled" --icon="${ICON}"
            python3 $I3_SCRIPT/i3_automark_daemon.py
            ;;
        "disable")
            notify-send -u "low" "i3 Automark" "i3 automark is disabled" --icon="${ICON}"
            ps -aux | grep "python3 ${I3_SCRIPT}/i3_automark_daemon.py" | \
                awk 'NR==1 {print $2}' | xargs -I {} kill {}
            ;;
        "reload")
            notify-send -u "low" "i3 Automark" "Reload i3 automark" --icon="${ICON}"
            ps -aux | grep "python3 $I3_SCRIPT/i3_automark_daemon.py" | \
                awk 'NR==1 {print $2}' | xargs -I {} kill {}
            python3 $I3_SCRIPT/i3_automark_daemon.py
            ;;
        "cycle_focus_inc")
            cycle_mark_focus inc
            i3-msg "[con_mark=${NEXT_MARK}] focus"
            cursor_follow_focus
            ;;
        "cycle_focus_dec")
            cycle_mark_focus dec
            i3-msg "[con_mark=${NEXT_MARK}] focus"
            cursor_follow_focus
            ;;
        "cycle_swap_inc")
            cycle_mark_focus inc
            i3-msg "swap container with mark ${NEXT_MARK}"
            $I3_SCRIPT/i3_automark.py
            cursor_follow_focus
            ;;
        "cycle_swap_dec")
            cycle_mark_focus dec
            i3-msg "swap container with mark ${NEXT_MARK}"
            $I3_SCRIPT/i3_automark.py
            cursor_follow_focus
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main
automark_operation $1
