#!/usr/bin/env bash

# cron does not set I3_SCRIPT
I3_SCRIPT=${I3_SCRIPT:-$HOME/.config/i3/script}
# for_each_i3_session, i3_session_kill: per-session env for cron (refresh_with_crontab)
source "$(dirname "$(readlink -f "$0")")/i3_session_env.sh"

POINTER_DAEMON=i3_kdeconnect_pointer_daemon.py

# Restart the pointer daemon of the i3 session on $DISPLAY, only if it runs there
# (it is switched on and off by hand with enable_pointer / disable_pointer). It is
# started through that session's i3, so it runs in the session, not under cron.
restart_session_pointer_daemon () {
    [[ -n $(i3_session_python_pids "$POINTER_DAEMON") ]] || return 0
    i3_session_kill i3_session_python_pids "$POINTER_DAEMON"
    i3-msg -- exec --no-startup-id "python3 $I3_SCRIPT/i3_kdeconnect_pointer_daemon.py" >/dev/null
}

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_kdeconnect_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [enable_pointer]: enable pointer daemon"
    echo "  [disable_pointer]: disable pointer daemon"
    echo "  [reload_pointer]: reload pointer daemon"
    echo "  [pointer_invert_on]: invert pointer color"
    echo "  [pointer_invert_off]: restore pointer color"
    echo "  [reload_kdeconnect]: reload kdeconnect daemon"
    echo "  [refresh_with_crontab] [verbose]: reload kdeconnect daemon, and pointer daemon"
    echo "      where it runs, in every i3 session (for cron)"
}

kdeconnect_operation () {
    ICON="$HOME/.config/i3/share/64x64/cursor.png"
    case $1 in
        "reload_kdeconnect")
            notify-send -u "low" "i3 kdeconnect" "Reload Kdeconnect daemon" --icon=${ICON}
            killall kdeconnectd
            kdeconnect-cli --refresh
            ;;
        "enable_pointer")
            notify-send -u "low" "i3 kdeconnect" "Pointer daemon is enabled" --icon=${ICON}
            python3 $I3_SCRIPT/i3_kdeconnect_pointer_daemon.py
            ;;
        "disable_pointer")
            notify-send -u "low" "i3 kdeconnect" "Pointer daemon is disabled" --icon=${ICON}
            ps -aux | grep "python3 ${I3_SCRIPT}/i3_kdeconnect_pointer_daemon.py" | \
                awk 'NR==1 {print $2}' | xargs -I {} kill {}
            ;;
        "reload_pointer")
            notify-send -u "low" "i3 kdeconnect" "Reload pointer daemon" --icon=${ICON}
            ps -aux | grep "python3 $I3_SCRIPT/i3_kdeconnect_pointer_daemon.py" | \
                awk 'NR==1 {print $2}' | xargs -I {} kill {}
            python3 $I3_SCRIPT/i3_kdeconnect_pointer_daemon.py
            ;;
        "pointer_invert_on")
            CONFIGS=( \
                "$HOME/.config/picom/picom.conf" \
                "$HOME/.config/picom/picom_transparency.conf" \
                "$HOME/.config/picom/picom_blur.conf" \
            )
            for CONFIG in ${CONFIGS[@]}; do
                COL_INVERT=$(awk '$0~/invert-color-include/ {print NR}' ${CONFIG} | awk 'NR==1')
                sed -i "$(( ${COL_INVERT} + 1 )) s/.*/  \"class_g \= \'kdeconnect.daemon\'\"/" "${CONFIG}"
            done
            ;;
        "pointer_invert_off")
            #CONFIG="$HOME/.config/picom/picom.conf"
            CONFIGS=( \
                "$HOME/.config/picom/picom.conf" \
                "$HOME/.config/picom/picom_transparency.conf" \
                "$HOME/.config/picom/picom_blur.conf" \
            )
            for CONFIG in ${CONFIGS[@]}; do
                COL_INVERT=$(awk '$0~/invert-color-include/ {print NR}' ${CONFIG} | awk 'NR==1')
                sed -i "$(( ${COL_INVERT} + 1 )) s/.*/  \#\"class_g \= \'kdeconnect.daemon\'\"/" "${CONFIG}"
            done
            ;;
        "refresh_with_crontab")
            # In `crontab -e`, add following line to refresh kdeconnect every hour
            # 0 * * * * /home/jordan/.config/i3/script/i3_kdeconnect_operator.sh refresh_with_crontab
            local status=0 tries=20
            # kdeconnectd: one per D-Bus bus (i3 sessions of one user usually share
            # one), so stop them all and let `kdeconnect-cli --refresh` start it again
            # through D-Bus, once per bus
            pkill -u "$(id -u)" -x kdeconnectd
            while (( tries-- > 0 )) && pgrep -u "$(id -u)" -x kdeconnectd >/dev/null; do
                sleep 0.1
            done
            for_each_i3_session --unique-dbus kdeconnect-cli --refresh >/dev/null || status=1
            # Pointer daemon: per i3 session
            for_each_i3_session restart_session_pointer_daemon || status=1
            if [[ ${2:-} == 'verbose' ]]; then
                for_each_i3_session --unique-dbus notify-send -u low "i3 kdeconnect" \
                    "Kdeconnect restart requested by cron" --icon="${ICON}" || true
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

# Main
kdeconnect_operation "$@"
