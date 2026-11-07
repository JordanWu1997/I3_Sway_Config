#!/usr/bin/env bash
# ~/.config/sway/script/sway_idle_operator.sh
# Ported from i3_xsslock_operator.sh for sway.
# Replaced X11 tools:
#   - xss-lock --transfer-sleep-lock -- i3lock ... -> swayidle -w with
#       timeout <LOCK>  -> lock         (X screensaver timeout, was xset s 600)
#       timeout <DPMS>  -> output * power off / resume power on (was xset dpms 600)
#       before-sleep    -> lock         (logind sleep, was --transfer-sleep-lock)
#       lock            -> lock         (`loginctl lock-session` keeps working)
#       unlock          -> pkill -USR1 swaylock (`loginctl unlock-session`)
#   - xset s off / -dpms ("caffeine") -> swayidle restarted WITHOUT the timeouts
#     (lock/before-sleep still work, like xss-lock kept running under caffeine).
#     Caffeine state: ${XDG_RUNTIME_DIR}/sway_caffeine ("on"|"off"), written by
#     sway_toolkit_operator.sh enable_caffeine/disable_caffeine.
# Lock style (default|current_default_wallpaper|current_wallpaper|current_desktop) is
# remembered in ${XDG_RUNTIME_DIR}/sway_idle_mode so start/restart reuse it.
#
# Idempotent: every start first stops the swayidle started by this script, so it is
# safe for `exec_always` (sway reload) and for concurrent callers (flock).

SWAY_SCRIPT="${SWAY_SCRIPT:-$HOME/.config/sway/script}"

RUNTIME="${XDG_RUNTIME_DIR:-/tmp}"
MODE_FILE="$RUNTIME/sway_idle_mode"
CAFFEINE_FILE="$RUNTIME/sway_caffeine"
LOCK_FILE="$RUNTIME/sway_idle_operator.lock"
LOCK_TIMEOUT="${SWAY_IDLE_LOCK_TIMEOUT:-600}"
DPMS_TIMEOUT="${SWAY_IDLE_DPMS_TIMEOUT:-610}"
# Marker used to find "our" swayidle (the one-shot swayidle of the Shift+l binding is not ours)
MARKER="sway_lock_operator.sh"

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  sway_idle_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [default]: start swayidle, lock with default wallpaper"
    echo "  [current_default_wallpaper]: start swayidle, lock with current default wallpaper"
    echo "  [current_wallpaper]: start swayidle, lock with current wallpaper"
    echo "  [current_desktop]: start swayidle, lock with current desktop screenshot"
    echo "  [start]: (re)start swayidle with the last used lock style"
    echo "  [restart]: same as start"
    echo "  [stop]: stop swayidle (no auto-lock, no lock on suspend)"
    echo "  [status]: print swayidle / caffeine state"
    echo ""
    echo "ENVIRONMENT"
    echo "  SWAY_IDLE_LOCK_TIMEOUT (default 600 s), SWAY_IDLE_DPMS_TIMEOUT (default 610 s)"
}

caffeine_on () {
    [[ $(cat "$CAFFEINE_FILE" 2> /dev/null) == on ]]
}

our_pids () {
    pgrep -u "$(id -u)" -f "^swayidle .*${MARKER//./\\.}"
}

stop_swayidle () {
    local i
    pkill -u "$(id -u)" -f "^swayidle .*${MARKER//./\\.}" 2> /dev/null || return 0
    for i in 1 2 3 4 5 6 7 8 9 10; do
        our_pids > /dev/null || return 0
        sleep 0.1
    done
    pkill -KILL -u "$(id -u)" -f "^swayidle .*${MARKER//./\\.}" 2> /dev/null
    return 0
}

start_swayidle () {
    local mode=$1 lock_cmd
    local -a args
    printf '%s\n' "$mode" > "$MODE_FILE"
    lock_cmd="$SWAY_SCRIPT/$MARKER $mode"
    args=(-w)
    if ! caffeine_on; then
        args+=(timeout "$LOCK_TIMEOUT" "$lock_cmd"
               timeout "$DPMS_TIMEOUT" 'swaymsg "output * power off"'
               resume 'swaymsg "output * power on"')
    fi
    args+=(before-sleep "$lock_cmd"
           lock "$lock_cmd"
           unlock "pkill -u $(id -u) -USR1 -x swaylock")
    stop_swayidle
    setsid -f swayidle "${args[@]}" > /dev/null 2>&1 < /dev/null 9>&-
}

show_status () {
    local mode
    mode=$(cat "$MODE_FILE" 2> /dev/null)
    if our_pids > /dev/null; then
        printf 'swayidle | running (lock style: %s)\n' "${mode:-unknown}"
        if caffeine_on; then
            printf 'Auto-lock on idle | off while caffeine is on\n'
        else
            printf 'Auto-lock on idle | after %ss, screen off after %ss\n' "$LOCK_TIMEOUT" "$DPMS_TIMEOUT"
        fi
        caffeine_on && printf 'Caffeine | on\n' || printf 'Caffeine | off\n'
        return 0
    fi
    printf 'swayidle | stopped\n'
    caffeine_on && printf 'Caffeine | on\n' || printf 'Caffeine | off\n'
    return 1
}

idle_operation () {
    case $1 in
        "default"|"current_default_wallpaper"|"current_wallpaper"|"current_desktop")
            start_swayidle "$1"
            ;;
        "start"|"restart")
            start_swayidle "$(cat "$MODE_FILE" 2> /dev/null || echo current_desktop)"
            ;;
        "stop")
            stop_swayidle
            ;;
        "status")
            show_status
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit 1
    esac
}

# Main
if ! command -v swayidle > /dev/null; then
    notify-send -u normal "sway_idle_operator.sh" "swayidle is not installed: no auto-lock / lock on suspend" 2> /dev/null
    exit 1
fi

case $1 in
    status) idle_operation status; exit $? ;;
esac

# Serialize concurrent callers (startup caffeine + exec_always idle operator)
exec 9> "$LOCK_FILE"
flock -w 5 9
idle_operation "$@"
