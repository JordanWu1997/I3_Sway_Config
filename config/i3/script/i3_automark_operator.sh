#!/usr/bin/env bash

# Automark marks
ALL_AUTOMARK_LIST=(\
    1 2 3 4 5 6 7 8 9 0 \
    q w e r t y u i o p \
    a s d f g h j k l \
    z x c v b n m)

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
                    MAX_MARK=${ALL_AUTOMARK_LIST[${MAX_INDEX_IN_ALL}]}
                fi
            done
            # Cycle back when reach the maximal existing marks
            if (( $(( ${MAX_MARK} == ${CURRENT_MARK} )) )); then
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
            if (( $CURRENT_MARK == $MIN_MARK)); then
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
    i3-msg "[con_mark=${NEXT_MARK}] focus"
}

automark_operation () {
    case $1 in
        "enable")
            notify-send -u "low" "i3 Automark" "i3 automark is enabled"
            python3 $I3_SCRIPT/i3_automark.py
            ;;
        "disable")
            notify-send -u "low" "i3 Automark" "i3 automark is disabled"
            kill $(ps -aux | grep "python3 $I3_SCRIPT/i3_automark.py")
            ;;
        "cycle_focus_inc")
            cycle_mark_focus inc
            ;;
        "cycle_focus_dec")
            cycle_mark_focus dec
            ;;
        *)
            echo $0
    esac
}

# Main
automark_operation $1
