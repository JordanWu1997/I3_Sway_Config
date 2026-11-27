#!/usr/bin/env bash

# Automark marks
#ALL_AUTOMARK_LIST=(\
    #1 2 3 4 5 6 7 8 9 0 \
    #q w e r t y u i o p \
    #a s d f g h j k l \
    #z x c v b n m)
readarray -t ALL_AUTOMARK_LIST < "$HOME/.config/i3/share/i3_automark_list.txt"

# cron does not set I3_SCRIPT
I3_SCRIPT=${I3_SCRIPT:-$HOME/.config/i3/script}
# for_each_i3_session, i3_session_kill: per-session env for cron (refresh_with_crontab)
source "$(dirname "$(readlink -f "$0")")/i3_session_env.sh"

# Restart the automark daemon of the i3 session on $DISPLAY. It is started through
# that session's i3, so it runs in the session (not as a child of cron) and connects
# to the right i3.
restart_session_automark_daemon () {
    i3_session_kill i3_session_python_pids i3_automark_daemon.py
    i3-msg -- exec --no-startup-id "$I3_SCRIPT/i3_automark_daemon.py" >/dev/null
}

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
    echo "  [reload]: reload automark"
    echo "  [cycle_focus_inc]: change focus to next increasingly-automarked window"
    echo "  [cycle_focus_dec]: change focus to next decreasingly-automarked window"
    echo "  [cycle_swap_inc]: swap window with next increasingly-automarked window"
    echo "  [cycle_swap_dec]: swap window with next decreasingly-automarked window"
    echo "  [refresh_with_crontab] [verbose]: restart automark daemon in every i3 session (for cron)"
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
    ICON="$HOME/.config/i3/share/64x64/abc.png"
    case $1 in
        "enable")
            notify-send -u "low" "i3 Automark" "i3 automark is enabled" --icon="${ICON}"
            python3 $I3_SCRIPT/i3_automark_daemon.py
            ;;
        "disable")
            notify-send -u "low" "i3 Automark" "i3 automark is disabled" --icon="${ICON}"
            ps -aux | grep "python3 ${I3_SCRIPT}/i3_automark_daemon.py" | grep -v 'grep' | \
                awk 'NR==1 {print $2}' | xargs -I {} kill {}
            ;;
        "reload")
            notify-send -u "low" "i3 Automark" "Reload i3 automark" --icon="${ICON}"
            ps -aux | grep "python3 $I3_SCRIPT/i3_automark_daemon.py" | grep -v 'grep' | \
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
        "refresh_with_crontab")
            # In `crontab -e`, add following line to refresh automark every hour
            # 0 * * * * /home/jordan/.config/i3/script/i3_automark_operator.sh refresh_with_crontab
            # Every i3 session of this user gets its own daemon (see i3_session_env.sh)
            local status=0
            for_each_i3_session restart_session_automark_daemon || status=1
            if [[ ${2:-} == 'verbose' ]]; then
                for_each_i3_session --unique-dbus notify-send -u low "i3 Automark" \
                    "Automark restart requested by cron" --icon="${ICON}" || true
            fi
            return "$status"
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Auto reload daemon if it is not running
# (not for refresh_with_crontab: it restarts the daemons itself, and a daemon started
# here would run in the foreground and block the cron job)
if [[ ! $1 == 'disable' ]] && [[ ! $1 == 'reload' ]] && [[ ! $1 == 'refresh_with_crontab' ]]; then
    ps -aux | grep "python3 $I3_SCRIPT/i3_automark_daemon.py" | grep -q -v 'grep' || python3 $I3_SCRIPT/i3_automark_daemon.py
fi

# Main
automark_operation "$@"
